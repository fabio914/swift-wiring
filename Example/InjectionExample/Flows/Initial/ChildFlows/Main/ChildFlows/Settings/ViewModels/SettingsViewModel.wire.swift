import Foundation

protocol SettingsCoordinatorProtocol: AnyObject {
}

@Inject
final class SettingsViewModel: SettingsViewModelProtocol {

    private let coordinator: SettingsCoordinatorProtocol
    private let session: Session
    private let logger: LoggerProtocol
    private let sessionManager: SessionManagerProtocol

    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    var sessionTime: String {
        dateFormatter.string(from: session.time)
    }

    init(
        @Dependency session: Session,
        @Dependency sessionManager: SessionManagerProtocol,
        @Dependency logger: LoggerProtocol,
        coordinator: SettingsCoordinatorProtocol
    ) {
        self.session = session
        self.sessionManager = sessionManager
        self.logger = logger
        self.coordinator = coordinator
    }

    func logOut() {
        logger.log("Logging out")
        sessionManager.clearSession()
    }
}
