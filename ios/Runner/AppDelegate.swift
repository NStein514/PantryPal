import Flutter
import UIKit
import UserNotifications
import home_widget

// Classic FlutterAppDelegate (no UIScene): works across current Flutter versions and is what
// flutter_local_notifications' and home_widget's setup instructions are written for.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Expiry reminders: let flutter_local_notifications receive taps and foreground presentation.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    // Home-screen widget buttons (iOS 17+) run Dart in a background engine that needs plugins too.
    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
