import AppKit
import Carbon
import SwiftUI
import UniformTypeIdentifiers

struct KeyboardSettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            KeyboardView(appState: appState)
            CompactActionBar(appState: appState)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .foregroundStyle(.primary)
        .background(Color.clear)
    }
}

private struct KeyboardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            let unit = keyUnit(for: geometry.size.width)
            let spacing = keySpacing(for: unit)

            VStack(spacing: spacing) {
                ForEach(Array(KeyboardLayout.rows.enumerated()), id: \.offset) { _, row in
                    KeyboardRowView(
                        keys: row,
                        unit: unit,
                        spacing: spacing,
                        appState: appState
                    )
                }

                MacBookBottomRowView(
                    unit: unit,
                    spacing: spacing,
                    appState: appState
                )
            }
            .frame(width: unit * KeyboardLayout.totalEffectiveWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(minHeight: 340)
    }

    private func keyUnit(for width: CGFloat) -> CGFloat {
        let available = max(width, 320)
        return min(50, floor(available / CGFloat(KeyboardLayout.totalEffectiveWidth)))
    }

    private func keySpacing(for unit: CGFloat) -> CGFloat {
        unit * CGFloat(KeyboardLayout.gapUnit)
    }
}

private struct KeyboardRowView: View {
    let keys: [KeyboardKey]
    let unit: CGFloat
    let spacing: CGFloat
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(keys) { key in
                KeyCapButton(
                    key: key,
                    unit: unit,
                    appState: appState
                )
            }
        }
    }
}

private struct MacBookBottomRowView: View {
    let unit: CGFloat
    let spacing: CGFloat
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(KeyboardLayout.bottomLeadingKeys) { key in
                KeyCapButton(
                    key: key,
                    unit: unit,
                    appState: appState
                )
            }

            KeyCapButton(
                key: KeyboardLayout.leftArrow,
                unit: unit,
                appState: appState
            )

            VStack(spacing: max(2, spacing * 0.45)) {
                KeyCapButton(
                    key: KeyboardLayout.upArrow,
                    unit: unit,
                    height: arrowHalfHeight,
                    appState: appState
                )
                KeyCapButton(
                    key: KeyboardLayout.downArrow,
                    unit: unit,
                    height: arrowHalfHeight,
                    appState: appState
                )
            }

            KeyCapButton(
                key: KeyboardLayout.rightArrow,
                unit: unit,
                appState: appState
            )
        }
    }

    private var arrowHalfHeight: CGFloat {
        (unit - max(2, spacing * 0.45)) / 2
    }
}

private struct KeyCapButton: View {
    let key: KeyboardKey
    let unit: CGFloat
    var height: CGFloat?
    @ObservedObject var appState: AppState

    var body: some View {
        KeyCapView(
            key: key,
            binding: key.keyCode.flatMap { appState.binding(for: $0) },
            isSelected: key.keyCode == appState.selectedKeyCode,
            unit: unit,
            height: height ?? unit
        )
        .overlay(
            KeyClickOverlay { clickCount in
                guard let keyCode = key.keyCode else { return }
                appState.select(keyCode: keyCode)

                guard clickCount == 2,
                      !appState.isDesktopShortcutKey(keyCode) else {
                    return
                }

                DispatchQueue.main.async {
                    AppPicker.chooseApplication { url in
                        appState.bindApplication(at: url, to: keyCode)
                    }
                }
            }
        )
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

private struct KeyClickOverlay: NSViewRepresentable {
    let onMouseDown: (Int) -> Void

    func makeNSView(context: Context) -> ClickCaptureView {
        let view = ClickCaptureView()
        view.onMouseDown = onMouseDown
        return view
    }

    func updateNSView(_ nsView: ClickCaptureView, context: Context) {
        nsView.onMouseDown = onMouseDown
    }

    final class ClickCaptureView: NSView {
        var onMouseDown: ((Int) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            true
        }

        override func mouseDown(with event: NSEvent) {
            onMouseDown?(event.clickCount)
        }
    }
}

private struct KeyCapView: View {
    let key: KeyboardKey
    let binding: AppBinding?
    let isSelected: Bool
    let unit: CGFloat
    let height: CGFloat

    private var isBindable: Bool {
        key.keyCode != nil
    }

    var body: some View {
        VStack(spacing: 2) {
            if let binding {
                AppIconView(path: binding.appPath)
                    .frame(width: iconSize, height: iconSize)
                    .opacity(binding.isEnabled ? 1 : 0.45)
            } else {
                Text(key.label)
                    .font(.system(size: keyLabelSize, weight: .medium, design: .rounded))
                    .foregroundStyle(isBindable ? Color.primary.opacity(0.82) : Color.secondary.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(width: unit * key.width, height: height)
        .background(background)
        .overlay(border)
        .opacity(isBindable ? 1 : 0.42)
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var keyLabelSize: CGFloat {
        if isSymbolLabel {
            return 17
        }
        return key.width > 1.7 ? 11 : 13
    }

    private var isSymbolLabel: Bool {
        ["⌫", "⇥", "⇪", "↩", "⇧", "⌃", "⌥", "⌘", "←", "↑", "↓", "→"].contains(key.label)
    }

    private var iconSize: CGFloat {
        key.width > 1.3 ? 36 : 34
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 5, y: 3)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(nsColor: .selectedContentBackgroundColor).opacity(0.30)
        }
        if binding != nil {
            return Color(nsColor: .controlBackgroundColor).opacity(0.78)
        }
        return Color(nsColor: .controlBackgroundColor).opacity(0.34)
    }

    private var shadowOpacity: Double {
        if isSelected { return 0.20 }
        return binding == nil ? 0.06 : 0.12
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(borderColor, lineWidth: 1.5)
    }

    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.85)
        }
        if binding != nil {
            return Color.white.opacity(0.32)
        }
        return Color.white.opacity(0.16)
    }
}

private struct AppIconView: View {
    let path: String

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var icon: NSImage {
        guard FileManager.default.fileExists(atPath: path) else {
            return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: "Missing app")
                ?? NSWorkspace.shared.icon(for: .applicationBundle)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}

private struct CompactActionBar: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            selectedKeySummary
                .frame(width: 230, alignment: .leading)
                .frame(height: 34)

            Spacer(minLength: 12)

            Text(appState.statusMessage ?? "")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 180, alignment: .trailing)

            Button(role: .destructive) {
                clearSelectedBinding()
            } label: {
                Image(systemName: "trash")
            }
            .help("清除当前按键绑定")
            .disabled(selectedBinding == nil)
            .controlSize(.regular)
            .frame(width: 42, height: 30)
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.42))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var selectedKeySummary: some View {
        HStack(spacing: 10) {
            Text(shortcutLabel)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(minWidth: 48, alignment: .leading)

            if appState.isDesktopShortcutKey(appState.selectedKeyCode) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)

                Text("显示/返回")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if let selectedBinding {
                AppIconView(path: selectedBinding.appPath)
                    .frame(width: 28, height: 28)

                Text("已绑定")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            } else {
                Text("未绑定")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 34, alignment: .center)
    }

    private var shortcutLabel: String {
        guard let keyCode = appState.selectedKeyCode else {
            return "未选"
        }
        return ModifierFormatter.shortcutLabel(keyCode: keyCode, modifiers: UInt32(optionKey))
    }

    private var selectedBinding: AppBinding? {
        guard let keyCode = appState.selectedKeyCode else { return nil }
        return appState.binding(for: keyCode)
    }

    private func clearSelectedBinding() {
        guard let keyCode = appState.selectedKeyCode else { return }
        appState.clearBinding(for: keyCode)
    }
}

private enum AppPicker {
    static func chooseApplication(onSelect: (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "选择要绑定的 App"
        panel.prompt = "绑定"
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        guard panel.runModal() == .OK, let url = panel.url else { return }
        onSelect(url)
    }
}
