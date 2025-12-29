import UIKit
import SafariServices

open class Coordinator: NSObject {

    // MARK: - Hierarchy

    open weak var viewController: UIViewController!

    /// Child coordinators.
    public private(set) var childCoordinators = [WeakRef<Coordinator>]()


    /// Parent coordinator.
    public private(set) weak var parentCoordinator: Coordinator?

    private var safariCompletionHandler: (() -> Void)?

    // MARK: - Lifecycle

    // override in subclasses
    open func start(animated: Bool = true) {
        // override
    }

    // override in subclasses
    open func end() {
        // override
    }

    // MARK: - Coordinator tree

    public func addChildCoordinator(_ coordinator: Coordinator) {
        coordinator.parentCoordinator = self
        childCoordinators.append(WeakRef(object: coordinator))
    }

    public func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0.object === coordinator }
        coordinator.parentCoordinator = nil
    }

    // MARK: - Safari

    public func openSafari(url: URL, completionHandler: (() -> Void)? = nil) {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = true

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.modalPresentationStyle = .overFullScreen
        controller.modalPresentationCapturesStatusBarAppearance = true
        controller.delegate = self

        viewController.present(controller, animated: true, completion: nil)
        safariCompletionHandler = completionHandler
    }
}

extension Coordinator: SFSafariViewControllerDelegate {
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        safariCompletionHandler?()
        safariCompletionHandler = nil
    }
}
