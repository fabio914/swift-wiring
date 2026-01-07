import UIKit

protocol LoggedOutCoordinatorDelegate: AnyObject {
    @MainActor
    func didCompleteLoginWith(session: Session, user: User)
}

/* wiring:inject */
final class LoggedOutCoordinator: NSObject, CoordinatorProtocol {

    weak var delegate: LoggedOutCoordinatorDelegate?

    let appContainer: AppContainer

    weak var navigationController: UINavigationController?

    init(
        /* wiring:dependency */ appContainer: AppContainer,
        delegate: LoggedOutCoordinatorDelegate
    ) {
        self.appContainer = appContainer
        self.delegate = delegate
        super.init()
    }

    func instantiateRoot() -> UIViewController? {
        let viewModel = appContainer.buildIntroViewModel(coordinator: self)
        let rootViewController = IntroScreen.makeViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.delegate = self
        self.navigationController = navigationController
        return navigationController
    }
}

extension LoggedOutCoordinator: UINavigationControllerDelegate {

}

extension LoggedOutCoordinator: IntroCoordinatorProtocol {

    func introToLogin() {
        let viewModel = appContainer.buildLoginViewModel(coordinator: self)
        let viewController = LoginScreen.makeViewController(viewModel: viewModel)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension LoggedOutCoordinator: LoginCoordinatorProtocol {

    func completedLoginWith(session: Session, user: User) {
        delegate?.didCompleteLoginWith(session: session, user: user)
    }
}
