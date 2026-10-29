// "Used one" from the home-screen widget (iOS 17+). Runs the app's Dart callback
// (lib/services/widget_actions.dart) through home_widget's background worker.
//
// Compiled into both the Runner and PantryWidgetExtension targets, as home_widget requires.

import AppIntents
import Flutter
import Foundation
import home_widget

@available(iOS 17, *)
public struct UseOneIntent: AppIntent {
    public static var title: LocalizedStringResource = "Used one"

    @Parameter(title: "Item")
    var itemId: Int?

    public init() {}

    public init(itemId: Int) {
        self.itemId = itemId
    }

    public func perform() async throws -> some IntentResult {
        guard let id = itemId else { return .result() }
        // From Info.plist (set in ios/Flutter/Identity.xcconfig); matches HomeWidgetService.appGroupId.
        let appGroup = Bundle.main.object(forInfoDictionaryKey: "PantryPalAppGroup") as? String ?? "group.app.pantrypal"
        await HomeWidgetBackgroundWorker.run(
            url: URL(string: "pantrypal://used?id=\(id)&homeWidget"),
            appGroup: appGroup
        )
        return .result()
    }
}

// Lets the intent wake the app if it isn't running (home_widget docs, step 5). The app's
// main() then runs in the background; PantryPal's startup is safe to run that way.
@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension UseOneIntent: ForegroundContinuableIntent {}
