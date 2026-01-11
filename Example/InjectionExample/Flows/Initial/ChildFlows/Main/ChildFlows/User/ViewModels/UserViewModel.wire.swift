import Foundation

protocol UserCoordinatorProtocol: AnyObject {
}

/* wiring:inject */
final class UserViewModel: UserViewModelProtocol {
    private let coordinator: UserCoordinatorProtocol
    private let logger: LoggerProtocol
    private let name: String

    init(
        /* wiring:dependency(UserName) */ name: String,
        /* wiring:dependency */ logger: LoggerProtocol,
        coordinator: UserCoordinatorProtocol
    ) {
        self.name = name
        self.logger = logger
        self.coordinator = coordinator
    }

    var userName: String {
        logger.log("Accessing User Name")
        return name
    }
}
