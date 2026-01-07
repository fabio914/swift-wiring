import Foundation
import Combine

protocol LoginCoordinatorProtocol: AnyObject {
    @MainActor
    func completedLoginWith(session: Session, user: User)
}

enum LoginViewModelError: Error {
    case loginApiError(Error)
}

/* wiring:inject */
final class LoginViewModel: LoginViewModelProtocol {
    private let coordinator: LoginCoordinatorProtocol
    private let apiClient: LoginApiClientProtocol
    private let logger: LoggerProtocol

    init(
        /* wiring:dependency */ logger: LoggerProtocol,
        /* wiring:dependency */ apiClient: LoginApiClientProtocol,
        coordinator: LoginCoordinatorProtocol
    ) {
        self.logger = logger
        self.apiClient = apiClient
        self.coordinator = coordinator
    }

    @MainActor
    private var loginTask: Task<Void, Never>?

    @MainActor @Published var state: LoginState = .ready

    @MainActor
    func login(userName: String) {
        logger.log("Attempting Login")
        loginTask?.cancel()
        state = .loading

        loginTask = Task { @MainActor [weak self, apiClient] in
            do {
                let (user, session) = try await apiClient.login(userName: userName)
                self?.coordinator.completedLoginWith(session: session, user: user)
            } catch {
                self?.logger.logError(LoginViewModelError.loginApiError(error))
                self?.state = .failed
            }
        }
    }

    @MainActor
    func retry() {
        if case.failed = state {
            state = .ready
        }
    }

    @MainActor
    func onDisappear() {
        loginTask?.cancel()
    }
}
