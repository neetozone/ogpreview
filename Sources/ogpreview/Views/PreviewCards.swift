import SwiftUI

/// One platform's rendering of the page. Each case below mirrors the real
/// card's colours, order and typography closely enough to judge a change.
struct PreviewCard: View {
    let platform: Platform
    let page: PageMetadata

    private var unfurl: Unfurl { page.unfurl(for: platform) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(platform.title, systemImage: platform.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            switch platform {
            case .google: GoogleCard(unfurl: unfurl, page: page)
            case .facebook: FacebookCard(unfurl: unfurl)
            case .linkedin: LinkedInCard(unfurl: unfurl)
            case .x: XCard(unfurl: unfurl)
            case .imessage: MessagesCard(unfurl: unfurl)
            case .whatsapp: WhatsAppCard(unfurl: unfurl, page: page)
            case .slack: SlackCard(unfurl: unfurl, accent: page.value("theme-color") ?? "#E8912D")
            case .discord: DiscordCard(unfurl: unfurl, accent: page.value("theme-color") ?? "#5865F2")
            }
        }
        .frame(width: cardWidth, alignment: .leading)
    }
}

// MARK: - Shared pieces

/// Card width every full-bleed preview is drawn at.
let cardWidth: CGFloat = 512

private struct CardImage: View {
    let url: URL?
    var width: CGFloat = cardWidth
    var aspect: CGFloat = 1.91
    var corners: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color(hex: 0xE4E6EB))
            .frame(width: width, height: (width / aspect).rounded())
            .overlay {
                if let url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: placeholder("photo.badge.exclamationmark", "Image failed to load")
                        default: ProgressView().controlSize(.small)
                        }
                    }
                } else {
                    placeholder("photo", "No og:image")
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: corners))
    }

    private func placeholder(_ symbol: String, _ text: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 22))
            Text(text).font(.system(size: 11))
        }
        .foregroundStyle(Color(hex: 0x8A8D91))
    }
}

private func fallback(_ text: String, _ placeholder: String) -> String {
    text.isEmpty ? placeholder : text
}

// MARK: - Cards

private struct GoogleCard: View {
    let unfurl: Unfurl
    let page: PageMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle().fill(Color(hex: 0xE8EAED)).frame(width: 26, height: 26)
                    .overlay(Image(systemName: "globe").font(.system(size: 12))
                        .foregroundStyle(Color(hex: 0x5F6368)))
                VStack(alignment: .leading, spacing: 0) {
                    Text(fallback(unfurl.siteName, page.domain))
                        .font(.system(size: 13)).foregroundStyle(Color(hex: 0x202124))
                    Text(unfurl.displayURL).font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0x4D5156)).lineLimit(1)
                }
            }
            Text(fallback(unfurl.title, "Untitled page"))
                .font(.system(size: 19)).foregroundStyle(Color(hex: 0x1A0DAB))
                .lineLimit(1)
            Text(fallback(unfurl.description, "No description available."))
                .font(.system(size: 13)).foregroundStyle(Color(hex: 0x4D5156))
                .lineLimit(2)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
    }
}

private struct FacebookCard: View {
    let unfurl: Unfurl

    var body: some View {
        VStack(spacing: 0) {
            CardImage(url: unfurl.imageURL)
            VStack(alignment: .leading, spacing: 3) {
                Text(unfurl.displayURL.uppercased())
                    .font(.system(size: 12)).foregroundStyle(Color(hex: 0x606770)).lineLimit(1)
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 16, weight: .bold)).foregroundStyle(Color(hex: 0x1D2129))
                    .lineLimit(2)
                if !unfurl.description.isEmpty {
                    Text(unfurl.description)
                        .font(.system(size: 14)).foregroundStyle(Color(hex: 0x606770)).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color(hex: 0xF2F3F5))
        }
        .overlay(Rectangle().stroke(Color(hex: 0xDADDE1), lineWidth: 1))
    }
}

private struct LinkedInCard: View {
    let unfurl: Unfurl

    var body: some View {
        VStack(spacing: 0) {
            CardImage(url: unfurl.imageURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x000000)).lineLimit(2)
                Text(unfurl.displayURL)
                    .font(.system(size: 12)).foregroundStyle(Color(hex: 0x666666))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(hex: 0xF9FAFB))
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(hex: 0xE0E0E0), lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
    }
}

private struct XCard: View {
    let unfurl: Unfurl

    var body: some View {
        VStack(spacing: 0) {
            if unfurl.largeImage {
                CardImage(url: unfurl.imageURL)
                footer
            } else {
                HStack(spacing: 0) {
                    CardImage(url: unfurl.imageURL, width: 130, aspect: 1)
                    footer
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: 0xCFD9DE), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(unfurl.displayURL).font(.system(size: 13)).foregroundStyle(Color(hex: 0x536471))
            Text(fallback(unfurl.title, "Untitled page"))
                .font(.system(size: 15)).foregroundStyle(Color(hex: 0x0F1419)).lineLimit(1)
            if !unfurl.description.isEmpty {
                Text(unfurl.description)
                    .font(.system(size: 15)).foregroundStyle(Color(hex: 0x536471)).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 10)
    }
}

private struct MessagesCard: View {
    let unfurl: Unfurl

    var body: some View {
        VStack(spacing: 0) {
            CardImage(url: unfurl.imageURL, width: 320)
            VStack(alignment: .leading, spacing: 1) {
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x1C1C1E)).lineLimit(2)
                Text(unfurl.displayURL)
                    .font(.system(size: 12)).foregroundStyle(Color(hex: 0x8E8E93)).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Color(hex: 0xF2F2F7))
        }
        .frame(width: 320)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct WhatsAppCard: View {
    let unfurl: Unfurl
    let page: PageMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            CardImage(url: unfurl.imageURL, width: 318, corners: 6)
            VStack(alignment: .leading, spacing: 2) {
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x111B21)).lineLimit(2)
                if !unfurl.description.isEmpty {
                    Text(unfurl.description)
                        .font(.system(size: 12)).foregroundStyle(Color(hex: 0x667781)).lineLimit(2)
                }
                Text(page.finalURL.absoluteString)
                    .font(.system(size: 12)).foregroundStyle(Color(hex: 0x667781)).lineLimit(1)
            }
        }
        .padding(6)
        .frame(width: 330)
        .background(Color(hex: 0xD9FDD3))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SlackCard: View {
    let unfurl: Unfurl
    let accent: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(barColor).frame(width: 4)
            VStack(alignment: .leading, spacing: 5) {
                Text(unfurl.siteName)
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Color(hex: 0x1D1C1D))
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(Color(hex: 0x1264A3))
                    .lineLimit(2)
                if !unfurl.description.isEmpty {
                    Text(unfurl.description)
                        .font(.system(size: 15)).foregroundStyle(Color(hex: 0x1D1C1D)).lineLimit(3)
                }
                CardImage(url: unfurl.imageURL, width: 360, corners: 8)
                    .padding(.top, 2)
            }
            .padding(.leading, 12).padding(.vertical, 4)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.10), radius: 3, y: 1)
    }

    private var barColor: Color {
        Color(hexString: accent) ?? Color(hex: 0xE8912D)
    }
}

private struct DiscordCard: View {
    let unfurl: Unfurl
    let accent: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle().fill(Color(hexString: accent) ?? Color(hex: 0x5865F2)).frame(width: 4)
            VStack(alignment: .leading, spacing: 8) {
                Text(unfurl.siteName)
                    .font(.system(size: 12)).foregroundStyle(Color(hex: 0xDBDEE1))
                Text(fallback(unfurl.title, "Untitled page"))
                    .font(.system(size: 16, weight: .semibold)).foregroundStyle(Color(hex: 0x00A8FC))
                    .lineLimit(2)
                if !unfurl.description.isEmpty {
                    Text(unfurl.description)
                        .font(.system(size: 14)).foregroundStyle(Color(hex: 0xDBDEE1)).lineLimit(3)
                }
                CardImage(url: unfurl.imageURL, width: 380, corners: 4)
            }
            .padding(12)
            Spacer(minLength: 0)
        }
        .background(Color(hex: 0x2B2D31))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

extension Color {
    /// Parses a `theme-color` meta value like `#5865F2`.
    init?(hexString: String) {
        var text = hexString.trimmed
        guard text.hasPrefix("#") else { return nil }
        text.removeFirst()
        if text.count == 3 { text = text.map { "\($0)\($0)" }.joined() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        self.init(hex: value)
    }
}
