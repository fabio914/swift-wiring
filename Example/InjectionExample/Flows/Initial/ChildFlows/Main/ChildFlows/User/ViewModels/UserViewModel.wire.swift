import Foundation

protocol UserCoordinatorProtocol: AnyObject {
}

/* wiring:inject */
final class UserViewModel: UserViewModelProtocol {

    private let coordinator: UserCoordinatorProtocol
    private let user: User
    private let logger: LoggerProtocol

    init(/* wiring:dependency */ user: User, /* wiring:dependency */ logger: LoggerProtocol, coordinator: UserCoordinatorProtocol) {
        self.user = user
        self.logger = logger
        self.coordinator = coordinator
    }

    var userName: String {
        logger.log("Accessing User Name")
        return user.userName
    }
}
