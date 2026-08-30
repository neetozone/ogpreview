import Foundation

enum TagKind: String, CaseIterable {
    case openGraph = "Open Graph"
    case twitter = "Twitter"
    case standard = "Standard"
    case link = "Link"
}

struct MetaTag: Identifiable, Hashable {
    var id: String { "\(kind.rawValue)|\(key)|\(value)" }
    let kind: TagKind
    let key: String
    let value: String
}

/// Everything a crawler learns about a page in one fetch.
struct PageMetadata {
    var requestedURL: URL
    var finalURL: URL
    var statusCode: Int
    var contentType: String?
    var byteCount: Int
    var elapsed: TimeInterval
    var redirects: [String]
    var htmlTitle: String?
    var tags: [MetaTag]

    /// First non-empty value for any of the given keys, in priority order.
    func value(_ keys: String...) -> String? {
        for key in keys {
            let hit = tags.first {
                $0.key.caseInsensitiveCompare(key) == .orderedSame && !$0.value.isEmpty
            }
            if let hit { return hit.value }
        }
        return nil
    }

    func has(_ key: String) -> Bool { value(key) != nil }

    var domain: String {
        let host = finalURL.host ?? ""
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    /// Resolves an image reference against the page URL, the way a crawler does.
    func imageURL(_ raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        return URL(string: raw, relativeTo: finalURL)?.absoluteURL
    }
}

/// What one platform actually renders, after its own fallback chain.
struct Unfurl {
    var title: String
    var description: String
    var imageURL: URL?
    var siteName: String
    var displayURL: String
    var largeImage: Bool
}

extension PageMetadata {
    func unfurl(for platform: Platform) -> Unfurl {
        let site = value("og:site_name") ?? domain
        switch platform {
        case .google:
            return Unfurl(title: htmlTitle ?? value("og:title") ?? "",
                          description: value("description", "og:description") ?? "",
                          imageURL: nil, siteName: site,
                          displayURL: finalURL.absoluteString, largeImage: false)
        case .x:
            let card = value("twitter:card") ?? "summary"
            return Unfurl(title: value("twitter:title", "og:title") ?? htmlTitle ?? "",
                          description: value("twitter:description", "og:description", "description") ?? "",
                          imageURL: imageURL(value("twitter:image", "twitter:image:src", "og:image")),
                          siteName: site, displayURL: domain,
                          largeImage: card.lowercased() == "summary_large_image")
        case .facebook, .linkedin, .imessage, .whatsapp, .slack, .discord:
            return Unfurl(title: value("og:title") ?? htmlTitle ?? "",
                          description: value("og:description", "description") ?? "",
                          imageURL: imageURL(value("og:image", "og:image:url", "twitter:image")),
                          siteName: site, displayURL: domain, largeImage: true)
        }
    }
}

/// Result of downloading the og:image itself — crawlers reject images that are
/// too small or too heavy, so the app checks them.
struct ImageProbe {
    var url: URL
    var pixelSize: CGSize?
    var byteCount: Int
    var contentType: String?
    var statusCode: Int
    var error: String?
}
