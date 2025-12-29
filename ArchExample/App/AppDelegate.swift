import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    // Window setup is handled in SceneDelegate.

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Perform any app-wide initialization here. Avoid creating a UIWindow; use SceneDelegate.
        return true
    }
}
