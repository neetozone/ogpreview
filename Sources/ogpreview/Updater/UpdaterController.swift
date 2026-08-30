import Combine
import Foundation
import Sparkle

/// Drives Sparkle's background update checks and the "Check for Updates…" menu item.
final class UpdaterController: ObservableObject {
    private let controller: SPUStandardUpdaterController

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
