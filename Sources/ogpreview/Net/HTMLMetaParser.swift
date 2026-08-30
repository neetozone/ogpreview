import Foundation

/// Pulls <title>, <meta> and <link> out of raw HTML. A crawler never runs the
/// page's JavaScript, so a regex pass over the served markup sees exactly what
/// Facebook, X and Slack see.
enum HTMLMetaParser {
    static func parse(_ html: String) -> (title: String?, tags: [MetaTag]) {
        var tags: [MetaTag] = []

        for match in html.regexMatches(#"<meta\s+([^>]*?)/?>"#) {
            let attrs = attributes(match[1])
            let name = attrs["property"] ?? attrs["name"] ?? attrs["itemprop"] ?? attrs["http-equiv"]
            guard let key = name?.trimmed, !key.isEmpty,
                  let content = attrs["content"]?.decodingHTMLEntities() else { continue }
            tags.append(MetaTag(kind: kind(for: key), key: key, value: content.trimmed))
        }

        for match in html.regexMatches(#"<link\s+([^>]*?)/?>"#) {
            let attrs = attributes(match[1])
            guard let rel = attrs["rel"]?.lowercased(), let href = attrs["href"],
                  ["canonical", "icon", "shortcut icon", "apple-touch-icon", "manifest"].contains(rel)
            else { continue }
            tags.append(MetaTag(kind: .link, key: "link:\(rel)", value: href.decodingHTMLEntities().trimmed))
        }

        let title = html.regexMatches(#"<title[^>]*>(.*?)</title>"#)
            .first?[1].decodingHTMLEntities().trimmed

        return (title?.isEmpty == false ? title : nil, tags)
    }

    private static func kind(for key: String) -> TagKind {
        let lower = key.lowercased()
        if lower.hasPrefix("og:") || lower.hasPrefix("fb:") || lower.hasPrefix("article:")
            || lower.hasPrefix("product:") || lower.hasPrefix("profile:") || lower.hasPrefix("music:")
            || lower.hasPrefix("video:") { return .openGraph }
        if lower.hasPrefix("twitter:") { return .twitter }
        return .standard
    }

    private static func attributes(_ source: String) -> [String: String] {
        var result: [String: String] = [:]
        for match in source.regexMatches(#"([\w:.\-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))"#) {
            let value = [match[2], match[3], match[4]].first { !$0.isEmpty } ?? ""
            result[match[1].lowercased()] = value
        }
        return result
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// All matches, each as its list of capture groups (index 0 = whole match).
    func regexMatches(_ pattern: String) -> [[String]] {
        let options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let text = self as NSString
        return regex.matches(in: self, range: NSRange(location: 0, length: text.length)).map { match in
            (0..<match.numberOfRanges).map { index in
                let range = match.range(at: index)
                return range.location == NSNotFound ? "" : text.substring(with: range)
            }
        }
    }

    func decodingHTMLEntities() -> String {
        guard contains("&") else { return self }
        var result = self
        let named = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'",
                     "&nbsp;": " ", "&mdash;": "—", "&ndash;": "–", "&hellip;": "…",
                     "&rsquo;": "’", "&lsquo;": "‘", "&ldquo;": "“", "&rdquo;": "”", "&#39;": "'"]
        for (entity, replacement) in named {
            result = result.replacingOccurrences(of: entity, with: replacement, options: .caseInsensitive)
        }
        for match in result.regexMatches(#"&#(x?)([0-9a-f]+);"#) {
            let radix = match[1].isEmpty ? 10 : 16
            if let code = UInt32(match[2], radix: radix), let scalar = Unicode.Scalar(code) {
                result = result.replacingOccurrences(of: match[0], with: String(Character(scalar)))
            }
        }
        return result
    }
}
