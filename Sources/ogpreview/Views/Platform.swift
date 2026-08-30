import SwiftUI

enum Platform: String, CaseIterable, Identifiable {
    case google, x, facebook, linkedin, slack, discord, imessage, whatsapp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .google: return "Google"
        case .x: return "X"
        case .facebook: return "Facebook"
        case .linkedin: return "LinkedIn"
        case .slack: return "Slack"
        case .discord: return "Discord"
        case .imessage: return "iMessage"
        case .whatsapp: return "WhatsApp"
        }
    }

    var symbol: String {
        switch self {
        case .google: return "magnifyingglass"
        case .x: return "xmark"
        case .facebook: return "f.square"
        case .linkedin: return "in.circle"
        case .slack: return "number.square"
        case .discord: return "gamecontroller"
        case .imessage: return "message.fill"
        case .whatsapp: return "phone.bubble.fill"
        }
    }
}

/// Hex helper so cards can use each platform's own published colours.
extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}
