import Foundation

protocol SettingsCoordinatorProtocol: AnyObject {
}

/* sw:inject */
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
        /* sw:dependency */ session: Session,
        /* sw:dependency */ sessionManager: SessionManagerProtocol,
        /* sw:dependency */ logger: LoggerProtocol,
        /* sw:dependency(Short) */ dateFormatter: DateFormatter,
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
