import Foundation

struct KeyboardKey: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let keyCode: UInt32?
    let width: Double

    init(_ label: String, keyCode: UInt32? = nil, width: Double = 1) {
        self.label = label
        self.keyCode = keyCode
        self.width = width
    }
}

enum KeyCodes {
    static let a: UInt32 = 0
    static let s: UInt32 = 1
    static let d: UInt32 = 2
    static let f: UInt32 = 3
    static let h: UInt32 = 4
    static let g: UInt32 = 5
    static let z: UInt32 = 6
    static let x: UInt32 = 7
    static let c: UInt32 = 8
    static let v: UInt32 = 9
    static let b: UInt32 = 11
    static let q: UInt32 = 12
    static let w: UInt32 = 13
    static let e: UInt32 = 14
    static let r: UInt32 = 15
    static let y: UInt32 = 16
    static let t: UInt32 = 17
    static let one: UInt32 = 18
    static let two: UInt32 = 19
    static let three: UInt32 = 20
    static let four: UInt32 = 21
    static let six: UInt32 = 22
    static let five: UInt32 = 23
    static let equal: UInt32 = 24
    static let nine: UInt32 = 25
    static let seven: UInt32 = 26
    static let minus: UInt32 = 27
    static let eight: UInt32 = 28
    static let zero: UInt32 = 29
    static let rightBracket: UInt32 = 30
    static let o: UInt32 = 31
    static let u: UInt32 = 32
    static let leftBracket: UInt32 = 33
    static let i: UInt32 = 34
    static let p: UInt32 = 35
    static let returnKey: UInt32 = 36
    static let l: UInt32 = 37
    static let j: UInt32 = 38
    static let quote: UInt32 = 39
    static let k: UInt32 = 40
    static let semicolon: UInt32 = 41
    static let backslash: UInt32 = 42
    static let comma: UInt32 = 43
    static let slash: UInt32 = 44
    static let n: UInt32 = 45
    static let m: UInt32 = 46
    static let period: UInt32 = 47
    static let tab: UInt32 = 48
    static let space: UInt32 = 49
    static let grave: UInt32 = 50
    static let delete: UInt32 = 51
    static let escape: UInt32 = 53
    static let f1: UInt32 = 122
    static let f2: UInt32 = 120
    static let f3: UInt32 = 99
    static let f4: UInt32 = 118
    static let f5: UInt32 = 96
    static let f6: UInt32 = 97
    static let f7: UInt32 = 98
    static let f8: UInt32 = 100
    static let f9: UInt32 = 101
    static let f10: UInt32 = 109
    static let f11: UInt32 = 103
    static let f12: UInt32 = 111
    static let leftArrow: UInt32 = 123
    static let rightArrow: UInt32 = 124
    static let downArrow: UInt32 = 125
    static let upArrow: UInt32 = 126
}

enum KeyboardLayout {
    static let gapUnit: Double = 0.14
    static let totalEffectiveWidth: Double = 16.82

    static let rows: [[KeyboardKey]] = [
        [
            KeyboardKey("esc", keyCode: KeyCodes.escape, width: 1.14),
            KeyboardKey("F1", keyCode: KeyCodes.f1, width: 1.1667),
            KeyboardKey("F2", keyCode: KeyCodes.f2, width: 1.1667),
            KeyboardKey("F3", keyCode: KeyCodes.f3, width: 1.1667),
            KeyboardKey("F4", keyCode: KeyCodes.f4, width: 1.1667),
            KeyboardKey("F5", keyCode: KeyCodes.f5, width: 1.1667),
            KeyboardKey("F6", keyCode: KeyCodes.f6, width: 1.1667),
            KeyboardKey("F7", keyCode: KeyCodes.f7, width: 1.1667),
            KeyboardKey("F8", keyCode: KeyCodes.f8, width: 1.1667),
            KeyboardKey("F9", keyCode: KeyCodes.f9, width: 1.1667),
            KeyboardKey("F10", keyCode: KeyCodes.f10, width: 1.1667),
            KeyboardKey("F11", keyCode: KeyCodes.f11, width: 1.1667),
            KeyboardKey("F12", keyCode: KeyCodes.f12, width: 1.1667)
        ],
        [
            KeyboardKey("`", keyCode: KeyCodes.grave), KeyboardKey("1", keyCode: KeyCodes.one),
            KeyboardKey("2", keyCode: KeyCodes.two), KeyboardKey("3", keyCode: KeyCodes.three),
            KeyboardKey("4", keyCode: KeyCodes.four), KeyboardKey("5", keyCode: KeyCodes.five),
            KeyboardKey("6", keyCode: KeyCodes.six), KeyboardKey("7", keyCode: KeyCodes.seven),
            KeyboardKey("8", keyCode: KeyCodes.eight), KeyboardKey("9", keyCode: KeyCodes.nine),
            KeyboardKey("0", keyCode: KeyCodes.zero), KeyboardKey("-", keyCode: KeyCodes.minus),
            KeyboardKey("=", keyCode: KeyCodes.equal), KeyboardKey("⌫", keyCode: KeyCodes.delete, width: 2.0)
        ],
        [
            KeyboardKey("⇥", keyCode: KeyCodes.tab, width: 1.5),
            KeyboardKey("Q", keyCode: KeyCodes.q), KeyboardKey("W", keyCode: KeyCodes.w),
            KeyboardKey("E", keyCode: KeyCodes.e), KeyboardKey("R", keyCode: KeyCodes.r),
            KeyboardKey("T", keyCode: KeyCodes.t), KeyboardKey("Y", keyCode: KeyCodes.y),
            KeyboardKey("U", keyCode: KeyCodes.u), KeyboardKey("I", keyCode: KeyCodes.i),
            KeyboardKey("O", keyCode: KeyCodes.o), KeyboardKey("P", keyCode: KeyCodes.p),
            KeyboardKey("[", keyCode: KeyCodes.leftBracket), KeyboardKey("]", keyCode: KeyCodes.rightBracket),
            KeyboardKey("\\", keyCode: KeyCodes.backslash, width: 1.5)
        ],
        [
            KeyboardKey("⇪", width: 1.75),
            KeyboardKey("A", keyCode: KeyCodes.a), KeyboardKey("S", keyCode: KeyCodes.s),
            KeyboardKey("D", keyCode: KeyCodes.d), KeyboardKey("F", keyCode: KeyCodes.f),
            KeyboardKey("G", keyCode: KeyCodes.g), KeyboardKey("H", keyCode: KeyCodes.h),
            KeyboardKey("J", keyCode: KeyCodes.j), KeyboardKey("K", keyCode: KeyCodes.k),
            KeyboardKey("L", keyCode: KeyCodes.l), KeyboardKey(";", keyCode: KeyCodes.semicolon),
            KeyboardKey("'", keyCode: KeyCodes.quote), KeyboardKey("↩", keyCode: KeyCodes.returnKey, width: 2.39)
        ],
        [
            KeyboardKey("⇧", width: 2.25),
            KeyboardKey("Z", keyCode: KeyCodes.z), KeyboardKey("X", keyCode: KeyCodes.x),
            KeyboardKey("C", keyCode: KeyCodes.c), KeyboardKey("V", keyCode: KeyCodes.v),
            KeyboardKey("B", keyCode: KeyCodes.b), KeyboardKey("N", keyCode: KeyCodes.n),
            KeyboardKey("M", keyCode: KeyCodes.m), KeyboardKey(",", keyCode: KeyCodes.comma),
            KeyboardKey(".", keyCode: KeyCodes.period), KeyboardKey("/", keyCode: KeyCodes.slash),
            KeyboardKey("⇧", width: 3.03)
        ]
    ]

    static let bottomLeadingKeys: [KeyboardKey] = [
        KeyboardKey("fn", width: 1.0),
        KeyboardKey("⌃", width: 1.15),
        KeyboardKey("⌥", width: 1.15),
        KeyboardKey("⌘", width: 1.35),
        KeyboardKey("", keyCode: KeyCodes.space, width: 5.71),
        KeyboardKey("⌘", width: 1.35),
        KeyboardKey("⌥", width: 1.15)
    ]

    static let leftArrow = KeyboardKey("←", keyCode: KeyCodes.leftArrow, width: 0.9)
    static let upArrow = KeyboardKey("↑", keyCode: KeyCodes.upArrow, width: 0.9)
    static let downArrow = KeyboardKey("↓", keyCode: KeyCodes.downArrow, width: 0.9)
    static let rightArrow = KeyboardKey("→", keyCode: KeyCodes.rightArrow, width: 0.9)

    static func label(for keyCode: UInt32) -> String {
        for row in rows {
            if let key = row.first(where: { $0.keyCode == keyCode }) {
                return key.label
            }
        }
        if let key = bottomLeadingKeys.first(where: { $0.keyCode == keyCode }) {
            return key.label
        }
        if leftArrow.keyCode == keyCode { return leftArrow.label }
        if upArrow.keyCode == keyCode { return upArrow.label }
        if downArrow.keyCode == keyCode { return downArrow.label }
        if rightArrow.keyCode == keyCode { return rightArrow.label }
        return "key \(keyCode)"
    }
}
