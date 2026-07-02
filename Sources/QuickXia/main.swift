import AppKit

private let appDelegate = AppDelegate()
let application = NSApplication.shared
application.delegate = appDelegate
application.setActivationPolicy(.accessory)
appDelegate.startIfNeeded()
application.run()
