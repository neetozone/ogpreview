import AppKit
import SwiftUI

@MainActor
final class PreviewModel: ObservableObject {
    @Published var urlText = ""
    @Published var page: PageMetadata?
    @Published var probe: ImageProbe?
    @Published var checks: [Check] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var recents: [String] = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []

    private static let recentsKey = "recentURLs"
    private var recentsKey: String { Self.recentsKey }

    func load(_ text: String? = nil) async {
        if let text { urlText = text }
        let input = urlText.trimmed
        guard !input.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let page = try await MetadataFetcher.fetch(input)
            self.page = page
            self.urlText = page.finalURL.absoluteString
            self.probe = nil
            self.checks = Audit.run(page, image: nil)
            remember(page.finalURL.absoluteString)

            if let imageURL = page.imageURL(page.value("og:image", "og:image:url", "twitter:image")) {
                let probe = await MetadataFetcher.probe(imageURL)
                self.probe = probe
                self.checks = Audit.run(page, image: probe)
            }
        } catch {
            self.page = nil
            self.probe = nil
            self.checks = []
            self.errorMessage = error.localizedDescription
        }
    }

    var failureCount: Int { checks.filter { !$0.passed }.count }

    func copyAllTags() {
        guard let page else { return }
        let text = page.tags.map { "<meta property=\"\($0.key)\" content=\"\($0.value)\">" }
            .joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func remember(_ url: String) {
        recents.removeAll { $0 == url }
        recents.insert(url, at: 0)
        recents = Array(recents.prefix(8))
        UserDefaults.standard.set(recents, forKey: recentsKey)
    }
}
