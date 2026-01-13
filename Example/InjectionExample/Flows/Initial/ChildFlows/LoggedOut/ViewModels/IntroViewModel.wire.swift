import Foundation
import Combine

protocol IntroCoordinatorProtocol: AnyObject {
    @MainActor
    func introToLogin()
}

/* sw:inject */
final class IntroViewModel: IntroViewModelProtocol {

    private let coordinator: IntroCoordinatorProtocol
    private let logger: LoggerProtocol

    init(
        /* sw:dependency */ logger: LoggerProtocol,
        coordinator: IntroCoordinatorProtocol
    ) {
        self.logger = logger
        self.coordinator = coordinator
    }

    func navigateToLogin() {
        coordinator.introToLogin()
    }
}
