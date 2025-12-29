import UIKit

final class ArchExampleCoordinator: Coordinator {

    private let navigationController: UINavigationController
    private let network: NetworkService

    init(navigationController: UINavigationController, network: NetworkService) {
        self.navigationController = navigationController
        self.network = network
        super.init()
    }

    override func start(animated: Bool = true) {
        let service = ArchExampleService(network: network)
        let viewModel = ArchExampleViewModel(service: service)
        let vc = ArchExampleViewController(viewModel: viewModel)

        self.viewController = vc
        navigationController.pushViewController(vc, animated: animated)
    }

    override func end() {
        navigationController.popViewController(animated: true)
    }
}
