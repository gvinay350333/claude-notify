import Foundation
import Cocoa
import ObjectiveC

// Dynamic Swizzling to override main bundle identifier
// This allows the binary to masquerade as Terminal so macOS displays the notification center banner natively
extension Bundle {
    static let swizzleBundleIdentifier: Void = {
        let originalSelector = #selector(getter: Bundle.bundleIdentifier)
        let swizzledSelector = #selector(getter: Bundle.myCustomBundleIdentifier)
        
        guard let originalMethod = class_getInstanceMethod(Bundle.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(Bundle.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
    
    @objc var myCustomBundleIdentifier: String? {
        return "com.apple.Terminal"
    }
}

// Helper to focus terminal app window and tab
func focusTerminal(app: String, tty: String) {
    let appName = app == "iTerm2" ? "iTerm" : app
    var script = ""
    
    if appName.isEmpty || appName == "Electron" {
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
    } else {
        script += "set targetApp to \"\(app)\"\n"
    }
    
    script += """
    if targetApp is not "" then
        set appName to targetApp
        if appName is "iTerm2" then
            set appName to "iTerm"
        end if
        
        set ttyFound to false
        set targetTty to "\(tty)"
        if targetTty is not "" then
            if targetApp is "Terminal" then
                try
                    tell application "Terminal"
                        repeat with w in windows
                            repeat with t in tabs of w
                                if tty of t is targetTty then
                                    set selected of t to true
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
            else if targetApp is "iTerm" or targetApp is "iTerm2" then
                try
                    set itermApp to "iTerm"
                    tell application itermApp
                        repeat with w in windows
                            repeat with t in tabs of w
                                repeat with s in sessions of t
                                    if tty of s is targetTty then
                                        select s
                                        set index of w to 1
                                        set ttyFound to true
                                        exit repeat
                                    end if
                                end repeat
                                if ttyFound then exit repeat
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
        
        tell application "System Events"
            if exists process targetApp then
                try
                    set frontmost of process targetApp to true
                end try
            end if
        end tell
    end if
    """
    
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
}

// Helper to write "y" + Enter to the specific terminal tab matching TTY
func sendApproval(app: String, tty: String) {
    let appName = app == "iTerm2" ? "iTerm" : app
    var script = ""
    
    if appName.isEmpty || appName == "Electron" {
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
    } else {
        script += "set targetApp to \"\(app)\"\n"
    }
    
    script += """
    if targetApp is not "" then
        set appName to targetApp
        if appName is "iTerm2" then
            set appName to "iTerm"
        end if
        
        set targetTty to "\(tty)"
        if targetTty is not "" then
            if targetApp is "Terminal" then
                try
                    tell application "Terminal"
                        repeat with w in windows
                            repeat with t in tabs of w
                                if tty of t is targetTty then
                                    do script "y" in t
                                    exit repeat
                                end if
                            end repeat
                        end repeat
                    end tell
                end try
            else if targetApp is "iTerm" or targetApp is "iTerm2" then
                try
                    set itermApp to "iTerm"
                    tell application itermApp
                        repeat with w in windows
                            repeat with t in tabs of w
                                repeat with s in sessions of t
                                    if tty of s is targetTty then
                                        tell s to write text "y"
                                        exit repeat
                                    end if
                                end repeat
                            end repeat
                        end repeat
                    end tell
                end try
            end if
        end if
    end if
    """
    
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
}

class NotificationDelegate: NSObject, NSUserNotificationCenterDelegate {
    let terminalApp: String
    let terminalTty: String
    
    init(app: String, tty: String) {
        self.terminalApp = app
        self.terminalTty = tty
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        // Check how it was activated
        if notification.activationType == .actionButtonClicked {
            // User clicked the Action button ("Allow")
            sendApproval(app: terminalApp, tty: terminalTty)
        } else {
            // User clicked the main banner body or "Show" button
            focusTerminal(app: terminalApp, tty: terminalTty)
        }
        exit(0)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true // Ensure it displays even if we are focused
    }
}

func main() {
    // Activate bundle identifier swizzling
    _ = Bundle.swizzleBundleIdentifier
    
    let args = CommandLine.arguments
    guard args.count >= 3 else {
        print("Usage: notifier <title> <message> [terminal_app] [terminal_tty] [last_prompt]")
        exit(1)
    }
    
    let title = args[1]
    let message = args[2]
    let app = args.count >= 4 ? args[3] : ""
    let tty = args.count >= 5 ? args[4] : ""
    let lastPrompt = args.count >= 6 ? args[5] : ""
    
    let notification = NSUserNotification()
    notification.title = title
    
    if !lastPrompt.isEmpty {
        notification.subtitle = lastPrompt
    }
    notification.informativeText = message
    notification.soundName = NSUserNotificationDefaultSoundName
    
    notification.hasActionButton = true
    notification.actionButtonTitle = "Allow"
    notification.otherButtonTitle = "Show"
    
    // Force Alert style programmatically (value 2) so it stays on screen until dismissed, bypassing global banner settings
    notification.setValue(2, forKey: "_presentationStyle")
    
    let delegate = NotificationDelegate(app: app, tty: tty)
    NSUserNotificationCenter.default.delegate = delegate
    NSUserNotificationCenter.default.deliver(notification)
    
    // Auto-dismiss and remove notification after 60 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
        NSUserNotificationCenter.default.removeDeliveredNotification(notification)
        exit(0)
    }
    
    // Start run loop
    let runLoop = CFRunLoopGetCurrent()
    CFRunLoopRun()
}

main()
