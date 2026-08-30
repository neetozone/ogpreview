import Foundation
import SwiftUI

/// One test over the fetched page: it either passed or it did not, and when it
/// did not it carries the one thing to change to make it pass.
struct Check: Identifiable {
    let id = UUID()
    let passed: Bool
    let text: String
    let fix: String?

    static let passColor = Color(hex: 0x3FBF79)
    static let failColor = Color(hex: 0xE85B50)
}

/// The rules crawlers actually apply, run as a checklist so the passes are
/// visible too — not just what went wrong.
enum Audit {
    static func run(_ page: PageMetadata, image: ImageProbe?) -> [Check] {
        var checks: [Check] = []

        func check(_ passed: Bool, pass: String, fail: String, fix: String) {
            checks.append(Check(passed: passed,
                                text: passed ? pass : fail,
                                fix: passed ? nil : fix))
        }

        func present(_ key: String, fix: String) {
            check(page.value(key) != nil,
                  pass: "`\(key)` is present and has value",
                  fail: "`\(key)` is not present or is empty",
                  fix: fix)
        }

        let titleGuess = page.value("og:title") ?? "Your page title"
        let canonical = page.value("og:url") ?? page.finalURL.absoluteString

        check(page.htmlTitle?.isEmpty == false,
              pass: "<title /> is set and is not empty",
              fail: "<title /> is not set or is empty",
              fix: "Add `<title>\(titleGuess)</title>` inside `<head>`. Browser tabs and Google's result headline both come from it.")

        check(page.value("description") != nil,
              pass: "meta description tag is set and is not empty",
              fail: "meta description tag is not set or is empty",
              fix: "Add `<meta name=\"description\" content=\"One sentence about the page\">`. Google shows it as the search snippet.")

        present("og:url",
                fix: "Add `<meta property=\"og:url\" content=\"\(canonical)\">` so every share is attributed to one canonical URL.")
        present("og:type",
                fix: "Add `<meta property=\"og:type\" content=\"website\">`. Use `article` for blog posts and news pages.")
        present("og:title",
                fix: "Add `<meta property=\"og:title\" content=\"\(page.htmlTitle ?? "Your page title")\">`. It is the headline on every card.")
        present("og:description",
                fix: "Add `<meta property=\"og:description\" content=\"One sentence, under 200 characters\">`. It is the body text of the card.")
        present("og:image",
                fix: "Add `<meta property=\"og:image\" content=\"https://\(page.domain)/og.png\">` pointing at a 1200×630 image on an absolute https URL.")
        present("og:locale",
                fix: "Add `<meta property=\"og:locale\" content=\"en_US\">`. Platforms assume US English when it is missing.")
        present("og:site_name",
                fix: "Add `<meta property=\"og:site_name\" content=\"Your product name\">`. Slack and Discord print it above the title, instead of the bare domain.")
        present("og:image:alt",
                fix: "Add `<meta property=\"og:image:alt\" content=\"What the image shows\">` so screen readers can describe the card image.")
        present("twitter:card",
                fix: "Add `<meta name=\"twitter:card\" content=\"summary_large_image\">`. Without it X falls back to a small square thumbnail.")
        present("twitter:site",
                fix: "Add `<meta name=\"twitter:site\" content=\"@yourhandle\">` so X credits your account on the card.")
        present("twitter:title",
                fix: "Optional — X falls back to `og:title`. Add `<meta name=\"twitter:title\" content=\"…\">` only to show different wording on X.")
        present("twitter:description",
                fix: "Optional — X falls back to `og:description`. Add `<meta name=\"twitter:description\" content=\"…\">` only to show different wording on X.")
        present("twitter:image",
                fix: "Optional — X falls back to `og:image`. Add `<meta name=\"twitter:image\" content=\"…\">` only to show a different image on X.")

        let imageWidth = Int(image?.pixelSize?.width ?? 1200)
        let imageHeight = Int(image?.pixelSize?.height ?? 630)
        check(page.value("og:image:width") != nil && page.value("og:image:height") != nil,
              pass: "`og:image:width` and `og:image:height` are declared",
              fail: "`og:image:width` and `og:image:height` are not declared, so the first share renders without the image",
              fix: "Add `<meta property=\"og:image:width\" content=\"\(imageWidth)\">` and `<meta property=\"og:image:height\" content=\"\(imageHeight)\">`. Without them the first person to share the link sees an empty card while the crawler measures the image.")

        if let card = page.value("twitter:card") {
            check(card.lowercased() == "summary_large_image",
                  pass: "`twitter:card` is summary_large_image, so X renders the image full width",
                  fail: "`twitter:card` is \(card), so X renders a small square image",
                  fix: "Change it to `<meta name=\"twitter:card\" content=\"summary_large_image\">` for a full-width image on X.")
        }

        check(page.statusCode == 200,
              pass: "the page responds with HTTP 200",
              fail: "the page responds with HTTP \(page.statusCode)",
              fix: "Crawlers drop the preview for anything but 200. Make the URL publicly reachable without a login, and resolve redirects to their final target.")

        if let title = page.value("og:title") {
            check(title.count <= 60,
                  pass: "`og:title` fits in the 60 characters platforms show",
                  fail: "`og:title` is \(title.count) characters, past the 60 platforms show",
                  fix: "Cut `og:title` to 60 characters or fewer, and put the words that matter first — the tail is what gets truncated.")
        }
        if let description = page.value("og:description") {
            check(description.count <= 200,
                  pass: "`og:description` fits in the 200 characters platforms show",
                  fail: "`og:description` is \(description.count) characters, past the 200 platforms show",
                  fix: "Cut `og:description` to 200 characters or fewer. Facebook and LinkedIn clip whatever runs past that.")
        }
        if let description = page.value("description") {
            check(description.count <= 160,
                  pass: "meta description fits in the 160 characters search results show",
                  fail: "meta description is \(description.count) characters, past the 160 search results show",
                  fix: "Cut the meta description to 160 characters or fewer so Google shows the whole snippet.")
        }
        if let ogURL = page.value("og:url") {
            check(URL(string: ogURL)?.host == page.finalURL.host,
                  pass: "`og:url` points at the host that served the page",
                  fail: "`og:url` points at a different host than the one that served the page",
                  fix: "Point `og:url` at `\(page.finalURL.absoluteString)`. Shares are currently credited to \(URL(string: ogURL)?.host ?? "another host").")
        }
        if let raw = page.value("og:image", "og:image:url") {
            check(raw.lowercased().hasPrefix("http"),
                  pass: "`og:image` is an absolute URL",
                  fail: "`og:image` is not an absolute URL",
                  fix: "Replace `\(raw)` with a full `https://…` URL. Crawlers do not resolve relative image paths.")
        }

        if let image {
            check(image.error == nil && image.statusCode < 400,
                  pass: "`og:image` downloads successfully",
                  fail: "`og:image` does not download (\(image.error ?? "HTTP \(image.statusCode)"))",
                  fix: "Make the image reachable at that URL with no login and no hotlink protection — crawlers fetch it anonymously.")
            if let size = image.pixelSize {
                let width = Int(size.width), height = Int(size.height)
                check(width >= 1200 && height >= 630,
                      pass: "`og:image` is at least the recommended 1200×630",
                      fail: "`og:image` is \(width)×\(height), under the recommended 1200×630",
                      fix: "Re-export the image at 1200×630 or larger. At \(width)×\(height) it will look soft on retina screens.")
                let ratio = size.width / max(size.height, 1)
                check(ratio >= 1.7 && ratio <= 2.1,
                      pass: "`og:image` is close to the 1.91:1 aspect ratio",
                      fail: "`og:image` is \(String(format: "%.2f", ratio)):1, not the 1.91:1 cards expect",
                      fix: "Reshape the image to 1.91:1 — 1200×630 is the standard. Cards centre-crop anything else, so edges get cut off.")
            }
            check(image.byteCount <= 5_000_000,
                  pass: "`og:image` is under the 5 MB limit",
                  fail: "`og:image` is \(byteString(image.byteCount)), over the 5 MB limit",
                  fix: "Compress the image below 5 MB — X skips heavier ones. A 1200×630 PNG should land well under 1 MB.")
        }

        // Failures first, passes below, each keeping the order they run in.
        return checks.filter { !$0.passed } + checks.filter(\.passed)
    }

    static func byteString(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }
}
