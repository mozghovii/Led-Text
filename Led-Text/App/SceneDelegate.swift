import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var coordinator: Coordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let navigationController = UINavigationController()

        let rootCoordinator = LedTextCoordinator(navigationController: navigationController)
        rootCoordinator.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.window = window
        self.coordinator = rootCoordinator
    }
}
