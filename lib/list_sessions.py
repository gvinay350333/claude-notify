#!/usr/bin/env python3
import os
import sys
import json
import glob
import subprocess
import time
import curses

def is_pid_running(pid):
    if not pid:
        return False
    try:
        os.kill(int(pid), 0)
        return True
    except (OSError, ValueError):
        return False

def relative_time(epoch_ms):
    if not epoch_ms:
        return ""
    if epoch_ms > 1e11:
        epoch = epoch_ms / 1000.0
    else:
        epoch = float(epoch_ms)
    diff = time.time() - epoch
    if diff < 0:
        return "just now"
    if diff < 60:
        return "just now"
    elif diff < 3600:
        return f"{int(diff // 60)}m ago"
    elif diff < 86400:
        return f"{int(diff // 3600)}h ago"
    else:
        return f"{int(diff // 86400)}d ago"

def focus_terminal(app, tty_val):
    if not app and not tty_val:
        return
    app_name = "iTerm" if app == "iTerm2" else app
    
    script = ""
    if not app_name or app_name == "Electron":
        script += """
        set targetApp to ""
        tell application "System Events"
            if exists process "iTerm2" then
                set targetApp to "iTerm2"
            else if exists process "Terminal" then
                set targetApp to "Terminal"
            else if exists process "WezTerm" then
                set targetApp to "WezTerm"
            else if exists process "Ghostty" then
                set targetApp to "Ghostty"
            else if exists process "Alacritty" then
                set targetApp to "Alacritty"
            end if
        end tell
        """
    else:
        script += f'set targetApp to "{app}"\n'
        
    script += f"""
    if targetApp is not "" then
        set appName to targetApp
        if appName is "iTerm2" then
            set appName to "iTerm"
        end if
        
        set ttyFound to false
        set targetTty to "{tty_val}"
        if targetTty is not "" then
            if targetApp is "Terminal" then
                try
                    tell application "Terminal"
                        repeat with w in windows
                            set tabList to (tabs of w whose tty is targetTty)
                            if tabList is not {{}} then
                                set selected of (first item of tabList) to true
                                set index of w to 1
                                set ttyFound to true
                                exit repeat
                            end if
                        end repeat
                        activate
                    end tell
                end try
            else if targetApp is "iTerm" or targetApp is "iTerm2" then
                try
                    set itermApp to "iTerm"
                    tell application itermApp
                        repeat with w in windows
                            repeat with t in tabs of w
                                set sessionList to (sessions of t whose tty is targetTty)
                                if sessionList is not {{}} then
                                    select (first item of sessionList)
                                    set index of w to 1
                                    set ttyFound to true
                                    exit repeat
                                end if
                            end repeat
                            if ttyFound then exit repeat
                        end repeat
                        activate
                    end tell
                end try
            end if
        end if
        
        if not ttyFound then
            try
                tell application appName
                    reopen
                    activate
                end tell
            end try
        end if
        
        set targetProcess to targetApp
        if targetProcess is "iTerm" then
            set targetProcess to "iTerm2"
        end if
        tell application "System Events"
            if exists process targetProcess then
                try
                    set frontmost of process targetProcess to true
                end try
            end if
        end tell
    end if
    """
    res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True)
    if res.returncode != 0:
        with open("/tmp/clist_error.log", "a") as f:
            f.write(f"Focus Error: {res.stderr}\n")

def close_claude_session(app, tty_val, pid):
    if tty_val and tty_val != "/dev/":
        app_name = "iTerm" if app == "iTerm2" else app
        script = ""
        if not app_name or app_name == "Electron":
            script += """
            set targetApp to ""
            tell application "System Events"
                if exists process "iTerm2" then
                    set targetApp to "iTerm2"
                else if exists process "Terminal" then
                    set targetApp to "Terminal"
                else if exists process "WezTerm" then
                    set targetApp to "WezTerm"
                else if exists process "Ghostty" then
                    set targetApp to "Ghostty"
                else if exists process "Alacritty" then
                    set targetApp to "Alacritty"
                end if
            end tell
            """
        else:
            script += f'set targetApp to "{app}"\n'
            
        script += f"""
        if targetApp is not "" then
            set appName to targetApp
            if appName is "iTerm2" then
                set appName to "iTerm"
            end if
            
            set targetTty to "{tty_val}"
            if targetTty is not "" then
                if targetApp is "Terminal" then
                    try
                        tell application "Terminal"
                            repeat with w in windows
                                set tabList to (tabs of w whose tty is targetTty)
                                if tabList is not {{}} then
                                    do script "/exit" in (first item of tabList)
                                    exit repeat
                                end if
                            end repeat
                        end tell
                    end try
                else if targetApp is "iTerm" or targetApp is "iTerm2" then
                    try
                        set itermApp to "iTerm"
                        tell application itermApp
                            repeat with w in windows
                                repeat with t in tabs of w
                                    set sessionList to (sessions of t whose tty is targetTty)
                                    if sessionList is not {{}} then
                                        tell (first item of sessionList) to write text "/exit"
                                        exit repeat
                                    end if
                                end repeat
                            end repeat
                        end tell
                    end try
                end if
            end if
        end if
        """
        subprocess.run(["osascript", "-e", script], capture_output=True)

    if pid:
        try:
            os.kill(int(pid), 15) # SIGTERM
        except Exception as e:
            with open("/tmp/clist_error.log", "a") as f:
                f.write(f"Kill PID {pid} Error: {e}\n")

def truncate_string(s, length):
    if len(s) <= length:
        return s.ljust(length)
    return s[:length-3] + "..."

def load_active_sessions():
    # Load History for Titles
    history = {}
    history_file = os.path.expanduser("~/.claude/history.jsonl")
    if os.path.exists(history_file):
        with open(history_file, "r", encoding="utf-8", errors="ignore") as f:
            for line in f:
                try:
                    data = json.loads(line)
                    sid = data.get("sessionId")
                    disp = data.get("display")
                    if sid and disp:
                        disp = disp.replace("\n", " ").strip()
                        if sid not in history:
                            history[sid] = disp
                except Exception:
                    continue

    # Load Claude Notify Sessions
    notify_sessions = {}
    notify_files = glob.glob(os.path.expanduser("~/.claude-notify/data/sessions/*.json"))
    for nf in notify_files:
        try:
            with open(nf, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
                sid = data.get("session_id")
                if sid:
                    notify_sessions[sid] = data
        except Exception:
            continue

    # Load Claude Daemon Sessions
    sessions = []
    daemon_files = glob.glob(os.path.expanduser("~/.claude/sessions/*.json"))
    for df in daemon_files:
        try:
            with open(df, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
                sid = data.get("sessionId")
                pid = data.get("pid")
                if not sid:
                    continue
                
                # Filter to only active ones
                if not is_pid_running(pid):
                    continue
                
                ns = notify_sessions.get(sid, {})
                project = ns.get("project") or data.get("cwd") or "Unknown Project"
                project_short = project.replace(os.path.expanduser("~"), "~")
                project_name = os.path.basename(project)
                tty_val = ns.get("tty", "")
                app = ns.get("terminal_app", "")
                
                title = history.get(sid) or ns.get("last_prompt") or ""
                updated_at = data.get("updatedAt") or data.get("startedAt") or 0
                
                sessions.append({
                    "session_id": sid,
                    "pid": pid,
                    "project_name": project_name,
                    "project_path": project_short,
                    "tty": tty_val.replace("/dev/", ""),
                    "app": app,
                    "title": title,
                    "updated_at": updated_at
                })
        except Exception:
            continue

    sessions.sort(key=lambda s: s["updated_at"], reverse=True)
    return sessions

def draw_mascot(stdscr, start_y, width):
    # Standard character retro mascot (immune to terminal font line-height issues)
    mascot = [
        "   |/|   |\\|   ",
        "  .---------.  ",
        "  |  O   O  |  ",
        "  |    -    |  ",
        "  '---------'  ",
        "   /       \\   "
    ]
    for i, line in enumerate(mascot):
        start_x = max(0, (width - len(line)) // 2)
        stdscr.addstr(start_y + i, start_x, line, curses.A_BOLD)
    return len(mascot)

def draw_menu(stdscr):
    curses.curs_set(0)
    curses.use_default_colors()
    
    try:
        curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_CYAN)
    except Exception:
        pass
        
    selected_idx = 0
    current_action = 0
    
    # Initial load
    sessions = load_active_sessions()
    
    while True:
        if not sessions:
            stdscr.erase()
            height, width = stdscr.getmaxyx()
            stdscr.addstr(height // 2, (width - 34) // 2, "No active Claude Code sessions left.")
            stdscr.refresh()
            time.sleep(1.0)
            return None, None
            
        stdscr.erase()
        height, width = stdscr.getmaxyx()
        
        # 1. Draw static mascot
        mascot_height = draw_mascot(stdscr, 1, width)
        
        # Clamp selection if size changed after close
        selected_idx = max(0, min(selected_idx, len(sessions) - 1))
        
        # Header configurations
        col_proj_w = max(12, min(20, width // 5))
        col_tty_w = 8
        col_age_w = 10
        col_action_w = 14
        col_title_w = max(15, width - col_proj_w - col_tty_w - col_age_w - col_action_w - 8)
        
        # Draw Header row below mascot
        header_y = mascot_height + 2
        header = f"{'PROJECT'.ljust(col_proj_w)}  {'CONVERSATION'.ljust(col_title_w)}  {'TTY'.ljust(col_tty_w)}  {'ACTIVE'.ljust(col_age_w)}  {'ACTION'.ljust(col_action_w)}"
        stdscr.addstr(header_y, 0, header[:width-1], curses.A_BOLD)
        stdscr.addstr(header_y + 1, 0, ("─" * width)[:width-1])
        
        # List data starting after header separator
        data_start_y = header_y + 2
        max_visible = height - data_start_y - 2
        
        for idx, s in enumerate(sessions[:max_visible]):
            proj_disp = truncate_string(s["project_name"], col_proj_w)
            title_disp = truncate_string(s["title"] if s["title"] else "(new conversation)", col_title_w)
            tty_disp = truncate_string(s["tty"] if s["tty"] else "N/A", col_tty_w)
            age_disp = truncate_string(relative_time(s["updated_at"]), col_age_w)
            
            if idx == selected_idx:
                action_text = "◀ FOCUS ▶".center(col_action_w) if current_action == 0 else "◀ EXIT ▶".center(col_action_w)
                line = f"{proj_disp.ljust(col_proj_w)}  {title_disp.ljust(col_title_w)}  {tty_disp.ljust(col_tty_w)}  {age_disp.ljust(col_age_w)}  {action_text}"
                stdscr.addstr(data_start_y + idx, 0, line[:width-1], curses.color_pair(1) | curses.A_BOLD)
            else:
                action_text = "  Focus".ljust(col_action_w)
                line = f"{proj_disp.ljust(col_proj_w)}  {title_disp.ljust(col_title_w)}  {tty_disp.ljust(col_tty_w)}  {age_disp.ljust(col_age_w)}  {action_text}"
                stdscr.addstr(data_start_y + idx, 0, line[:width-1])
        
        # Footer
        footer = "(Navigate: ↑/↓/←/→, Select Action: ←/→, Execute: Enter, Cancel: Ctrl+C)"
        stdscr.addstr(height - 1, 0, footer[:width-1], curses.A_DIM)
        
        stdscr.refresh()
        
        key = stdscr.getch()
        
        # Handle keypresses
        if key in (curses.KEY_UP, ord('k')):
            selected_idx = (selected_idx - 1) % len(sessions)
            current_action = 0 
        elif key in (curses.KEY_DOWN, ord('j')):
            selected_idx = (selected_idx + 1) % len(sessions)
            current_action = 0 
        elif key in (curses.KEY_LEFT, ord('h')):
            current_action = 0
        elif key in (curses.KEY_RIGHT, ord('l')):
            current_action = 1
        elif key in (10, 13, curses.KEY_ENTER):
            selected_session = sessions[selected_idx]
            if current_action == 0:
                return selected_session, 0
            else:
                stdscr.addstr(height - 2, 0, f"Exiting session: {selected_session['project_name']}...".ljust(width-1), curses.A_REVERSE)
                stdscr.refresh()
                close_claude_session(selected_session["app"], "/dev/" + selected_session["tty"], selected_session["pid"])
                time.sleep(0.3)
                sessions = load_active_sessions()
                current_action = 0
        elif key in (3, 27, ord('q'), ord('Q')):
            return None, None

def main():
    selected, action = curses.wrapper(draw_menu)
    
    if selected and action == 0:
        display_name = selected["title"] or selected["project_name"]
        if selected["tty"]:
            print(f"\nFocusing session: {display_name} (TTY: {selected['tty']})...")
            focus_terminal(selected["app"], "/dev/" + selected["tty"])
        else:
            print(f"\nSession '{display_name}' has no active terminal context.")
    else:
        print("\nExit.")

if __name__ == "__main__":
    main()
