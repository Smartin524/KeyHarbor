import AppKit

enum AppIconRenderer {
    private static let cache = NSCache<NSString, NSImage>()
    private static let renderedSize = NSSize(width: 64, height: 64)

    static func icon(forAppAtPath path: String, appearanceName: NSAppearance.Name) -> NSImage {
        let cacheKey = "\(path)|\(appearanceName.rawValue)" as NSString
        if let cachedIcon = cache.object(forKey: cacheKey) {
            return cachedIcon
        }

        guard let appearance = NSAppearance(named: appearanceName) else {
            return sourceIcon(forAppAtPath: path)
        }

        let renderedIcon = NSImage(size: renderedSize)
        appearance.performAsCurrentDrawingAppearance {
            let sourceIcon = sourceIcon(forAppAtPath: path)
            renderedIcon.lockFocus()
            defer { renderedIcon.unlockFocus() }

            NSGraphicsContext.current?.imageInterpolation = .high
            sourceIcon.draw(
                in: NSRect(origin: .zero, size: renderedSize),
                from: .zero,
                operation: .copy,
                fraction: 1
            )
        }

        renderedIcon.isTemplate = false
        cache.setObject(renderedIcon, forKey: cacheKey)
        return renderedIcon
    }

    private static func sourceIcon(forAppAtPath path: String) -> NSImage {
        guard FileManager.default.fileExists(atPath: path) else {
            return NSWorkspace.shared.icon(for: .applicationBundle)
        }
        return NSWorkspace.shared.icon(forFile: path)
    }
}
