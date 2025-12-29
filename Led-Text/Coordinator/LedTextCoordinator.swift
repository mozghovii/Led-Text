import UIKit

final class LedTextCoordinator: Coordinator {

    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    override func start(animated: Bool = true) {
        let viewModel = LedSettingsViewModel()
        let vc = LedSettingsViewController(viewModel: viewModel)

        self.viewController = vc
        navigationController.pushViewController(vc, animated: animated)
    }

    override func end() {
        navigationController.popViewController(animated: true)
    }
}
