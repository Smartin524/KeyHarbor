import Carbon
import Foundation

enum ModifierFormatter {
    static let option = UInt32(optionKey)
    static let command = UInt32(cmdKey)
    static let control = UInt32(controlKey)
    static let shift = UInt32(shiftKey)

    static func label(for modifiers: UInt32) -> String {
        var parts: [String] = []
        if modifiers & control != 0 { parts.append("⌃") }
        if modifiers & option != 0 { parts.append("⌥") }
        if modifiers & shift != 0 { parts.append("⇧") }
        if modifiers & command != 0 { parts.append("⌘") }
        return parts.joined()
    }

    static func shortcutLabel(keyCode: UInt32, modifiers: UInt32) -> String {
        "\(label(for: modifiers))\(KeyboardLayout.label(for: keyCode).uppercased())"
    }
}
