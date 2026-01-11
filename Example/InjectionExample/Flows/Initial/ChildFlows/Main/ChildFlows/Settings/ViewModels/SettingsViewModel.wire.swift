import Foundation

protocol SettingsCoordinatorProtocol: AnyObject {
}

/* wiring:inject */
final class SettingsViewModel: SettingsViewModelProtocol {

    private let coordinator: SettingsCoordinatorProtocol
    private let session: Session
    private let logger: LoggerProtocol
    private let sessionManager: SessionManagerProtocol
    private let dateFormatter: DateFormatter

    var sessionTime: String {
        dateFormatter.string(from: session.time)
    }

    init(
        /* wiring:dependency */ session: Session,
        /* wiring:dependency */ sessionManager: SessionManagerProtocol,
        /* wiring:dependency */ logger: LoggerProtocol,
        /* wiring:dependency(Short) */ dateFormatter: DateFormatter,
        coordinator: SettingsCoordinatorProtocol
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.logger = logger
        self.dateFormatter = dateFormatter
        self.coordinator = coordinator
    }

    func logOut() {
        logger.log("Logging out")
        sessionManager.clearSession()
    }
}
