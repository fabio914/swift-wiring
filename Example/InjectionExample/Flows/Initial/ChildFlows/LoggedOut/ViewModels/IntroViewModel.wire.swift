import Foundation
import Combine

protocol IntroCoordinatorProtocol: AnyObject {
    @MainActor
    func introToLogin()
}

/* wiring:inject */
final class IntroViewModel: IntroViewModelProtocol {

    private let coordinator: IntroCoordinatorProtocol
    private let logger: LoggerProtocol

    init(
        /* wiring:dependency */ logger: LoggerProtocol,
        coordinator: IntroCoordinatorProtocol
    ) {
        self.logger = logger
        self.coordinator = coordinator
    }

    func navigateToLogin() {
        coordinator.introToLogin()
    }
}
