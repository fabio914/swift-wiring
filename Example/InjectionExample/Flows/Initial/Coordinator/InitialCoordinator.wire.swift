import UIKit

/* wiring:inject */
public final class InitialCoordinator: CoordinatorProtocol {

    // Our Initial Coordinator is retaining the App Container
    let appContainer: AppContainer

    weak var rootViewController: InitialContainerViewController?

    init(/* wiring:dependency */ appContainer: AppContainer) {
        self.appContainer = appContainer
    }

    func instantiateRoot() -> UIViewController? {
        appContainer.singletonSessionManagerProtocol.delegate = self

        // Our InitialContainerViewController is retaining the Initial Coordinator
        let viewController = InitialContainerViewController(coordinator: self)
        rootViewController = viewController
        return viewController
    }

    @MainActor
    private func didStart() {
        let sessionManager = appContainer.singletonSessionManagerProtocol

        if let session = sessionManager.session, let user = sessionManager.user {
            didStartWithSession(session: session, user: user)
        } else {
            didStartWithoutSession()
        }
    }

    @MainActor
    private func didStartWithSession(session: Session, user: User) {
        let appContainer = self.appContainer

        // TODO: Create a way to make one container extend another (or take dependencies from another)
        // So we don't need to pass dependencies individually.
        let mainContainer = MainContainer(
            loggerProtocol: appContainer.singletonLoggerProtocol,
            session: session,
            sessionManagerProtocol: appContainer.singletonSessionManagerProtocol,
            user: user
        )

        let viewController = mainContainer.buildMainCoordinator().instantiateRoot()
        rootViewController?.present(childViewController: viewController)
    }

    @MainActor
    private func didStartWithoutSession() {
        let viewController = appContainer.buildLoggedOutCoordinator(delegate: self).instantiateRoot()
        rootViewController?.present(childViewController: viewController)
    }
}

extension InitialCoordinator: InitialContainerCoordinatorProtocol {

    func didAppearForTheFirstTime() {
        didStart()
    }
}

extension InitialCoordinator: SessionManagerDelegate {

    func sessionDidStart(_ sessionManager: SessionManagerProtocol, session: Session, user: User) {
        didStartWithSession(session: session, user: user)
    }

    func sessionDidEnd(_ sessionManager: SessionManagerProtocol) {
        didStart()
    }
}

extension InitialCoordinator: LoggedOutCoordinatorDelegate {

    func didCompleteLoginWith(session: Session, user: User) {
        let sessionManager = appContainer.singletonSessionManagerProtocol
        sessionManager.setSession(session: session, user: user)
    }
}
