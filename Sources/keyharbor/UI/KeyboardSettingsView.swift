import AppKit
import Carbon
import SwiftUI
import UniformTypeIdentifiers

struct KeyboardSettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            KeyboardView(appState: appState)

            GeometryReader { geometry in
                CompactActionBar(appState: appState)
                    .frame(width: KeyboardSizing.contentWidth(for: geometry.size.width))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 48)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .foregroundStyle(.primary)
        .background(Color.clear)
    }
}

private enum KeyboardSizing {
    static func unit(for width: CGFloat) -> CGFloat {
        let available = max(width, 320)
        return min(50, floor(available / CGFloat(KeyboardLayout.totalEffectiveWidth)))
    }

    static func spacing(for unit: CGFloat) -> CGFloat {
        unit * CGFloat(KeyboardLayout.gapUnit)
    }

    static func contentWidth(for availableWidth: CGFloat) -> CGFloat {
        unit(for: availableWidth) * CGFloat(KeyboardLayout.totalEffectiveWidth)
    }
}

private struct KeyboardView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        GeometryReader { geometry in
            let unit = KeyboardSizing.unit(for: geometry.size.width)
            let spacing = KeyboardSizing.spacing(for: unit)

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
            .frame(width: KeyboardSizing.contentWidth(for: geometry.size.width))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(minHeight: 340)
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
                      !appState.isReservedShortcutKey(keyCode) else {
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
                AppIconView(binding: binding)
                    .frame(width: iconSize, height: iconSize)
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
    let binding: AppBinding
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .accessibilityLabel(binding.displayName)
    }

    private var icon: NSImage {
        AppIconRenderer.icon(
            forAppAtPath: binding.appPath,
            appearanceName: colorScheme == .dark ? .darkAqua : .aqua
        )
    }
}

private struct CompactActionBar: View {
    @ObservedObject var appState: AppState
    @ObservedObject private var deleteButtonHoverState = DeleteButtonHoverState()

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
                    .font(.system(size: 13, weight: .medium))
                    .frame(width: 30, height: 28)
                    .contentShape(Circle())
            }
            .buttonStyle(
                DeleteIconButtonStyle(
                    isEnabled: selectedBinding != nil,
                    isHovering: deleteButtonHoverState.isHovering
                )
            )
            .onHover { deleteButtonHoverState.isHovering = $0 }
            .help("清除当前按键绑定")
            .disabled(selectedBinding == nil)
        }
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

            if appState.isPanelShortcutKey(appState.selectedKeyCode) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)

                Text("打开面板")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if appState.isDesktopShortcutKey(appState.selectedKeyCode) {
                Image(systemName: "desktopcomputer")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.accentColor)

                Text("显示/返回")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            } else if let selectedBinding {
                AppIconView(binding: selectedBinding)
                    .frame(width: 28, height: 28)

                Text(selectedBinding.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
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
        return ModifierFormatter.shortcutLabel(
            keyCode: keyCode,
            modifiers: appState.shortcutModifiers(for: keyCode)
        )
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

private final class DeleteButtonHoverState: ObservableObject {
    @Published var isHovering = false
}

private struct DeleteIconButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .background(
                Circle()
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.94 : 1)
            .animation(.easeOut(duration: 0.10), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: isHovering)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return .clear }
        if isPressed { return Color.red.opacity(0.10) }
        return isHovering ? Color.primary.opacity(0.08) : .clear
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        guard isEnabled else {
            return Color.secondary.opacity(0.28)
        }
        return isPressed ? .red : Color.secondary.opacity(0.72)
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
