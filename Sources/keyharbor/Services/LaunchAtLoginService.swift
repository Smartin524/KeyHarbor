import Foundation
import ServiceManagement

final class LaunchAtLoginService {
    private let appURL: URL

    init(appURL: URL = Bundle.main.bundleURL) {
        self.appURL = appURL
    }

    var canRegisterCurrentApp: Bool {
        let standardizedAppURL = appURL.standardizedFileURL
        guard standardizedAppURL.pathExtension == "app" else { return false }

        let applicationsPath = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .standardizedFileURL
            .path
        return standardizedAppURL.path.hasPrefix(applicationsPath + "/")
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    var needsApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
            try SMAppService.mainApp.unregister()
        }
    }
}
