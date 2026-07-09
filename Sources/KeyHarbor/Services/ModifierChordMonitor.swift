import AppKit
import Foundation

struct ModifierChord: Equatable {
    let flags: NSEvent.ModifierFlags
}

final class ModifierChordMonitor {
    typealias Handler = () -> Void

    private let chord: ModifierChord
    private let handler: Handler
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isChordDown = false

    private let relevantFlags: NSEvent.ModifierFlags = [
        .command,
        .control,
        .option,
        .shift
    ]

    init(chord: ModifierChord, handler: @escaping Handler) {
        self.chord = chord
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        stop()
        _ = AccessibilityPermission.isTrusted(promptIfNeeded: true)

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(flags: event.modifierFlags)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(flags: event.modifierFlags)
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }

        globalMonitor = nil
        localMonitor = nil
        isChordDown = false
    }

    private func handle(flags: NSEvent.ModifierFlags) {
        let pressedFlags = flags.intersection(relevantFlags)
        let targetFlags = chord.flags.intersection(relevantFlags)
        let targetIsDown = targetFlags.isSubset(of: pressedFlags)

        guard targetIsDown else {
            isChordDown = false
            return
        }

        guard pressedFlags == targetFlags, !isChordDown else {
            isChordDown = true
            return
        }

        isChordDown = true
        handler()
    }
}
