import SwiftUI

struct InspectorView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case tests = "Tests", tags = "Tags", response = "Response"
        var id: String { rawValue }
    }

    @ObservedObject var model: PreviewModel
    let page: PageMetadata
    @State private var tab: Tab = .tests

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { tab in
                    Text(label(for: tab)).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    switch tab {
                    case .tests: tests
                    case .tags: tags
                    case .response: response
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func label(for tab: Tab) -> String {
        guard tab == .tests, model.failureCount > 0 else { return tab.rawValue }
        return "Tests (\(model.failureCount))"
    }

    private var tests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tests").font(.system(size: 24, weight: .bold))
                .padding(.bottom, 2)
            ForEach(model.checks) { check in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Image(systemName: check.passed ? "checkmark.circle" : "xmark.circle")
                            .font(.system(size: 15))
                            .foregroundStyle(check.passed ? Check.passColor : Check.failColor)
                        Text(check.text)
                            .font(.system(size: 15, weight: check.passed ? .regular : .semibold))
                            .foregroundStyle(check.passed ? Color.primary : Check.failColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // How to fix it, sitting directly under the failing test.
                    if let fix = check.fix {
                        Text((try? AttributedString(markdown: fix)) ?? AttributedString(fix))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 25)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tags: some View {
        HStack {
            Text("\(page.tags.count) tags").font(.system(size: 12)).foregroundStyle(.secondary)
            Spacer()
            Button("Copy all") { model.copyAllTags() }.controlSize(.small)
        }
        ForEach(TagKind.allCases, id: \.self) { kind in
            let group = page.tags.filter { $0.kind == kind }
            if !group.isEmpty {
                Text(kind.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                    .padding(.top, 4)
                ForEach(group) { tag in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tag.key).font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                        Text(tag.value).font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary).textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        if let title = page.htmlTitle {
            Text("HTML").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 1) {
                Text("<title>").font(.system(size: 12, weight: .medium, design: .monospaced))
                Text(title).font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var response: some View {
        row("Status", "\(page.statusCode)")
        row("Final URL", page.finalURL.absoluteString)
        row("Content-Type", page.contentType ?? "—")
        row("Size", Audit.byteString(page.byteCount))
        row("Time", String(format: "%.0f ms", page.elapsed * 1000))
        row("User-Agent", MetadataFetcher.userAgent)
        if !page.redirects.isEmpty {
            row("Redirects", page.redirects.joined(separator: "\n"))
        }
        if let probe = model.probe {
            Text("OG IMAGE").font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
                .padding(.top, 6)
            row("URL", probe.url.absoluteString)
            if let size = probe.pixelSize {
                row("Dimensions", "\(Int(size.width)) × \(Int(size.height))")
            }
            row("Size", Audit.byteString(probe.byteCount))
            row("Type", probe.contentType ?? "—")
            if let error = probe.error { row("Error", error) }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            Text(value).font(.system(size: 12, design: .monospaced))
                .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
