import CoreGraphics
import Foundation

// Exits 0 as soon as ogpreview has a real window on screen, 1 if none appears in
// time. A build that compiles can still come up with no UI at all — Sparkle,
// started from the App struct, did exactly that — and only this catches it.
let timeout = Double(CommandLine.arguments.dropFirst().first ?? "45") ?? 45
let deadline = Date().addingTimeInterval(timeout)

while Date() < deadline {
    let windows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] ?? []
    for window in windows {
        let owner = (window[kCGWindowOwnerName as String] as? String ?? "").lowercased()
        let bounds = window[kCGWindowBounds as String] as? [String: Any] ?? [:]
        let width = (bounds["Width"] as? Double) ?? 0
        let height = (bounds["Height"] as? Double) ?? 0
        if owner.contains("ogpreview"), width > 900, height > 400 {
            print("window \(Int(width))x\(Int(height))")
            exit(0)
        }
    }
    Thread.sleep(forTimeInterval: 1)
}

FileHandle.standardError.write(Data("no ogpreview window appeared within \(Int(timeout))s\n".utf8))
exit(1)
