import AppKit
import Foundation

enum FetchError: LocalizedError {
    case badURL
    case notHTML(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "That doesn't look like a URL."
        case .notHTML(let type): return "The server returned \(type), not HTML."
        }
    }
}

/// Fetches a page the way a social crawler does: a crawler user-agent, no
/// cookies, no JavaScript — plus the redirect chain and timing along the way.
enum MetadataFetcher {
    static let userAgent = "facebookexternalhit/1.1 (+https://github.com/neerajsingh0101/ogpreview)"

    static func normalize(_ text: String) -> URL? {
        var input = text.trimmed
        guard !input.isEmpty else { return nil }
        if !input.contains("://") { input = "https://" + input }
        guard let url = URL(string: input), let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()), url.host != nil else { return nil }
        return url
    }

    static func fetch(_ text: String) async throws -> PageMetadata {
        guard let url = normalize(text) else { throw FetchError.badURL }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let recorder = RedirectRecorder()
        let start = Date()
        let (data, response) = try await URLSession.shared.data(for: request, delegate: recorder)
        let elapsed = Date().timeIntervalSince(start)

        let http = response as? HTTPURLResponse
        let contentType = http?.value(forHTTPHeaderField: "Content-Type")
        let html = decode(data, contentType: contentType)
        let parsed = HTMLMetaParser.parse(html)

        if parsed.tags.isEmpty && parsed.title == nil, let contentType,
           !contentType.lowercased().contains("html") {
            throw FetchError.notHTML(contentType)
        }

        return PageMetadata(requestedURL: url,
                            finalURL: response.url ?? url,
                            statusCode: http?.statusCode ?? 0,
                            contentType: contentType,
                            byteCount: data.count,
                            elapsed: elapsed,
                            redirects: recorder.hops,
                            htmlTitle: parsed.title,
                            tags: parsed.tags)
    }

    static func probe(_ url: URL) async -> ImageProbe {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let http = response as? HTTPURLResponse
            let image = NSImage(data: data)
            let pixels = image?.representations.first.map {
                CGSize(width: $0.pixelsWide, height: $0.pixelsHigh)
            }
            return ImageProbe(url: url,
                              pixelSize: pixels ?? image?.size,
                              byteCount: data.count,
                              contentType: http?.value(forHTTPHeaderField: "Content-Type"),
                              statusCode: http?.statusCode ?? 0,
                              error: image == nil ? "Not a decodable image" : nil)
        } catch {
            return ImageProbe(url: url, pixelSize: nil, byteCount: 0, contentType: nil,
                              statusCode: 0, error: error.localizedDescription)
        }
    }

    /// Honours the charset the server declared, falling back to Latin-1 so a
    /// mislabelled page still parses instead of coming back empty.
    private static func decode(_ data: Data, contentType: String?) -> String {
        if let charset = contentType?.regexMatches(#"charset=([\w\-]+)"#).first?[1].lowercased(),
           !charset.contains("utf-8"),
           let encoding = CFStringConvertEncodingToNSStringEncoding(
               CFStringConvertIANACharSetNameToEncoding(charset as CFString)
           ) as NSNumber?,
           encoding.uintValue != kCFStringEncodingInvalidId,
           let text = String(data: data, encoding: String.Encoding(rawValue: encoding.uintValue)) {
            return text
        }
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }
}

private final class RedirectRecorder: NSObject, URLSessionTaskDelegate {
    var hops: [String] = []

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url {
            hops.append("\(response.statusCode) → \(url.absoluteString)")
        }
        completionHandler(request)
    }
}
