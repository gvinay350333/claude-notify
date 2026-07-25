import Foundation
import Cocoa
import ObjectiveC
import UserNotifications

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
                            set tabList to (tabs of w whose tty is targetTty)
                            if tabList is not {} then
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
                                if sessionList is not {} then
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

// Helper to write return key to the specific terminal tab matching TTY
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
                            set tabList to (tabs of w whose tty is targetTty)
                            if tabList is not {} then
                                do script "" in (first item of tabList)
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
                                if sessionList is not {} then
                                    tell (first item of sessionList) to write text ""
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
    
    let appleScript = NSAppleScript(source: script)
    var error: NSDictionary?
    appleScript?.executeAndReturnError(&error)
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    let terminalApp: String
    let terminalTty: String
    
    init(app: String, tty: String) {
        self.terminalApp = app
        self.terminalTty = tty
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "allow" {
            sendApproval(app: terminalApp, tty: terminalTty)
        } else if response.actionIdentifier == "show" {
            focusTerminal(app: terminalApp, tty: terminalTty)
        } else if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            // Clicked notification body
            focusTerminal(app: terminalApp, tty: terminalTty)
        }
        completionHandler()
        exit(0)
    }
}

func main() {
    // Activate bundle identifier swizzling
    _ = Bundle.swizzleBundleIdentifier
    
    let args = CommandLine.arguments
    guard args.count >= 3 else {
        print("Usage: notifier <title> <message> [terminal_app] [terminal_tty] [last_prompt] [show_allow]")
        exit(1)
    }
    
    let title = args[1]
    let message = args[2]
    let app = args.count >= 4 ? args[3] : ""
    let tty = args.count >= 5 ? args[4] : ""
    let lastPrompt = args.count >= 6 ? args[5] : ""
    let showAllow = args.count >= 7 ? args[6] == "true" : false
    
    let center = UNUserNotificationCenter.current()
    let delegate = NotificationDelegate(app: app, tty: tty)
    center.delegate = delegate
    
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
        // Configure actions
        var actions: [UNNotificationAction] = []
        if showAllow {
            let allowAction = UNNotificationAction(identifier: "allow", title: "Allow", options: [.foreground])
            let showAction = UNNotificationAction(identifier: "show", title: "Show", options: [.foreground])
            actions = [allowAction, showAction]
        } else {
            let showAction = UNNotificationAction(identifier: "show", title: "Show", options: [.foreground])
            actions = [showAction]
        }
        
        let category = UNNotificationCategory(
            identifier: "claude-notify-category",
            actions: actions,
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        
        // Configure content
        let content = UNMutableNotificationContent()
        content.title = title
        if !lastPrompt.isEmpty {
            content.subtitle = lastPrompt
        }
        content.body = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "claude-notify-category"
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            if let error = error {
                print("Error delivering notification: \(error)")
                exit(1)
            }
        }
    }
    
    // Auto-dismiss and remove notification after 60 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 60.0) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        exit(0)
    }
    
    // Start run loop
    let runLoop = CFRunLoopGetCurrent()
    CFRunLoopRun()
}

main()
