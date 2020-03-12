import UIKit
import Telemetry

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let background = "background"
    public static let foreground = "foreground"
}

class TelemetryEventObject {
    public static let app = "app"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "AppInfo.displayName"
        telemetryConfig.userDefaultsSuiteName = "AppInfo.sharedContainerIdentifier"
        telemetryConfig.dataDirectory = .documentDirectory

        Telemetry.default.beforeSerializePing(pingType: CorePingBuilder.PingType) { (inputDict) -> [String : Any?] in
            var outputDict = inputDict // make a mutable copy
            outputDict["some added prop"] = 1
            return outputDict
        }

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)

        NotificationCenter.default.addObserver(self, selector: #selector(uploadError(notification:)), name: Telemetry.notificationReportError, object: nil)

        return true
    }

    @objc func uploadError(notification: NSNotification) {
        guard let error = notification.userInfo?["error"] as? NSError else { return }
        print("Upload error notification: \(error.localizedDescription)")
    }

    // Example of how to record a UI event for the app foregrounding/becoming active.
    func applicationDidBecomeActive(_ application: UIApplication) {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.foreground, object: TelemetryEventObject.app)
    }
}
