import AppKit
import Carbon
import Foundation

enum HotKeyAction: Equatable {
    case appBinding(UUID)
    case toggleDesktop
    case showPanel
}

struct HotKeyShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32
}

final class HotKeyManager {
    typealias Handler = (HotKeyAction) -> Void

    private struct RegisteredHotKey {
        let action: HotKeyAction
        let reference: EventHotKeyRef
    }

    private var registeredHotKeys: [UInt32: RegisteredHotKey] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextHotKeyID: UInt32 = 1
    private let signature = HotKeyManager.fourCharacterCode("KHBR")
    private let handler: Handler
    private var panelChordMonitor: ModifierChordMonitor?

    init(handler: @escaping Handler) {
        self.handler = handler
        installEventHandler()
    }

    deinit {
        unregisterAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(
        bindings: [AppBinding],
        enabled: Bool,
        panelChord: ModifierChord?,
        desktopShortcut: HotKeyShortcut?
    ) {
        unregisterAll()

        if let panelChord {
            let monitor = ModifierChordMonitor(chord: panelChord) { [weak self] in
                self?.handler(.showPanel)
            }
            monitor.start()
            panelChordMonitor = monitor
        }

        guard enabled else { return }

        if let desktopShortcut {
            register(
                keyCode: desktopShortcut.keyCode,
                modifiers: desktopShortcut.modifiers,
                action: .toggleDesktop
            )
        }

        for binding in bindings {
            if let desktopShortcut,
               binding.keyCode == desktopShortcut.keyCode,
               binding.modifiers == desktopShortcut.modifiers {
                continue
            }
            register(
                keyCode: binding.keyCode,
                modifiers: binding.modifiers,
                action: .appBinding(binding.id)
            )
        }
    }

    func unregisterAll() {
        for hotKey in registeredHotKeys.values {
            UnregisterEventHotKey(hotKey.reference)
        }
        panelChordMonitor?.stop()
        panelChordMonitor = nil
        registeredHotKeys.removeAll()
        nextHotKeyID = 1
    }

    private func register(keyCode: UInt32, modifiers: UInt32, action: HotKeyAction) {
        let hotKeyIDValue = nextHotKeyID
        nextHotKeyID += 1

        var hotKeyReference: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: signature, id: hotKeyIDValue)
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard status == noErr, let hotKeyReference else {
            NSLog("KeyHarbor failed to register hotkey action=%@ keyCode=%u modifiers=%u status=%d", String(describing: action), keyCode, modifiers, status)
            return
        }

        registeredHotKeys[hotKeyIDValue] = RegisteredHotKey(
            action: action,
            reference: hotKeyReference
        )
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotKeyEvent(event)
                return noErr
            },
            1,
            &eventType,
            pointer,
            &eventHandler
        )
    }

    private func handleHotKeyEvent(_ event: EventRef?) {
        guard let event else { return }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr,
              hotKeyID.signature == signature,
              let hotKey = registeredHotKeys[hotKeyID.id] else {
            return
        }

        handler(hotKey.action)
    }

    private static func fourCharacterCode(_ string: String) -> OSType {
        var result: UInt32 = 0
        for scalar in string.utf16.prefix(4) {
            result = (result << 8) + UInt32(scalar)
        }
        return result
    }
}
