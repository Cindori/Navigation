//
//  AppDelegate.swift
//  TestApp
//
//  Created by Oskar Groth on 2024-09-11.
//

import AppKit
import SwiftUI
import Navigation

@main
@MainActor class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    private var window: NSWindow?
    
    static func main() {
        _ = NSApplication.shared // Create NSApplication before accessing delegate
        AppDelegate.shared = AppDelegate()
        NSApp.delegate = AppDelegate.shared
        NSApp.run()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create a ContentView (SwiftUI View)
        let contentView = AppView()
        
        // Create a hosting controller to wrap the SwiftUI view
        let hostingController = NSHostingController(rootView: contentView)
        
        // Create a window
        let window = ToolbarWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Configure the window
        window.title = "TestApp"
        window.center()
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
