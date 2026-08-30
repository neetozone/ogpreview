import SwiftUI

struct ContentView: View {
    @StateObject private var model = PreviewModel()
    @FocusState private var urlFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            addressBar
            Divider()
            content
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            urlFocused = true
            // `ogpreview https://example.com` opens straight onto that page.
            if let argument = CommandLine.arguments.dropFirst().first,
               MetadataFetcher.normalize(argument) != nil {
                Task { await model.load(argument) }
            }
        }
    }

    private var addressBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                TextField("Paste a URL to preview", text: $model.urlText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .focused($urlFocused)
                    .onSubmit { Task { await model.load() } }
                if !model.urlText.isEmpty {
                    Button {
                        model.urlText = ""
                        urlFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
                if !model.recents.isEmpty {
                    Menu {
                        ForEach(model.recents, id: \.self) { url in
                            Button(url) { Task { await model.load(url) } }
                        }
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 15))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .frame(width: 20)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.25)))

            Button("Preview") { Task { await model.load() } }
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(model.urlText.trimmed.isEmpty || model.isLoading)

            if model.isLoading { ProgressView().controlSize(.small) }

            // A hidden filter would silently look like missing cards — say so.
            if platforms.count < Platform.allCases.count {
                Text("Filtered: \(platforms.map(\.title).joined(separator: ", "))")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
                    .help("OGPREVIEW_PLATFORMS is set in the environment.")
            }
        }
        .padding(14)
    }

    /// OGPREVIEW_PLATFORMS=slack,discord narrows the column to a few cards.
    private var platforms: [Platform] {
        guard let only = ProcessInfo.processInfo.environment["OGPREVIEW_PLATFORMS"] else {
            return Platform.allCases
        }
        let wanted = Set(only.lowercased().split(separator: ",").map { String($0).trimmed })
        let filtered = Platform.allCases.filter { wanted.contains($0.rawValue) }
        return filtered.isEmpty ? Platform.allCases : filtered
    }

    @ViewBuilder
    private var content: some View {
        if let page = model.page {
            HSplitView {
                ScrollView {
                    VStack(alignment: .center, spacing: 26) {
                        ForEach(platforms) { platform in
                            PreviewCard(platform: platform, page: page)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .frame(minWidth: 560)
                .background(Color(nsColor: .windowBackgroundColor))

                InspectorView(model: model, page: page)
                    .frame(minWidth: 330, idealWidth: 400)
            }
        } else if let message = model.errorMessage {
            placeholder(symbol: "exclamationmark.triangle", title: "Couldn't load that page", detail: message)
        } else {
            placeholder(symbol: "rectangle.on.rectangle.angled",
                        title: "Preview how a link unfurls",
                        detail: "Enter a URL to see its Google, X, Facebook, LinkedIn, Slack, Discord, iMessage and WhatsApp cards.")
        }
    }

    private func placeholder(symbol: String, title: String, detail: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 34)).foregroundStyle(.tertiary)
            Text(title).font(.title3.weight(.medium))
            Text(detail).font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
