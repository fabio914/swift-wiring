import Foundation

protocol UserCoordinatorProtocol: AnyObject {
}

@Inject
final class UserViewModel: UserViewModelProtocol {

    private let coordinator: UserCoordinatorProtocol
    private let user: User
    private let logger: LoggerProtocol

    init(
        @Dependency user: User,
        @Dependency logger: LoggerProtocol,
        coordinator: UserCoordinatorProtocol
    ) {
        self.user = user
        self.logger = logger
        self.coordinator = coordinator
    }

    var userName: String {
        logger.log("Accessing User Name")
        return user.userName
    }
}
