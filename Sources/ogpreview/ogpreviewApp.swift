import AppKit
import SwiftUI

/// Launched without a real .app bundle (plain `swift run`), macOS treats the
/// process as an accessory and never shows the window — force a regular policy.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updater: UpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Sparkle starts only once the app is up. Starting it from the App
        // struct — while SwiftUI is still building the scene — leaves the
        // window unbuilt, and the app runs on with no UI at all.
        updater = UpdaterController()
    }

    func checkForUpdates() {
        updater?.checkForUpdates()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct ogpreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("ogpreview") {
            ContentView()
        }
        .defaultSize(width: 1180, height: 820)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appDelegate.checkForUpdates()
                }
            }
        }
    }
}
