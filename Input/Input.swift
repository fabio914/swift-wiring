import Foundation

// sw: container(MyContainer) {
//   access(public)
//
//   singleton(SessionManager)
//   singleton(UserManager) { access(public) }
//
//   singleton(UserDataPersistence, PersistenceProtocol) { name(User) }
//   singleton(SessionDataPersistence, PersistenceProtocol) { name(Session) }
//
//   build(NetworkManager, NetworkManagerProtocol)
//   build(AuthNetworkManager, NetworkManagerProtocol) { name(Authenticated) }
//
//   build(LoggedOutApi) { access(public) }
//   build(OtherApi, ApiClient) { access(public) name(Other) }
//   build(UserInfoApi, ApiClient) { name(User) }
//
//   build(providesUserName) { name(UserName) }
//   build(providesUserEmail, String) { name(UserEmail) }
//   build(UserViewModel)
// }
protocol MyContainerProtocol {
}

public protocol ApiClient {}

protocol SomethingExternal {}

// sw: inject
final class LoggedOutApi: ApiClient {
    let networkManager: NetworkManagerProtocol
    let something: SomethingExternal
    let parameter: String

    init(
        // sw: dependency
        networkManager: NetworkManagerProtocol,
        // sw: dependency
        something: SomethingExternal,
        parameter: String
    ) {
        self.networkManager = networkManager
        self.something = something
        self.parameter = parameter
    }
}

// sw: inject
final class OtherApi: ApiClient {
    let networkManager: NetworkManagerProtocol

    init(
        // sw: dependency
        networkManager: NetworkManagerProtocol
    ) {
        self.networkManager = networkManager
    }
}

// sw: inject
final class UserInfoApi: ApiClient {
    let authNetworkManager: NetworkManagerProtocol
    
    init(
        // sw: dependency(Authenticated)
        authNetworkManager: NetworkManagerProtocol
    ) {
        self.authNetworkManager = authNetworkManager
    }
}

protocol NetworkManagerProtocol {
    func perform(request: URLRequest) async throws -> Data
}

// sw: inject
final class NetworkManager: NetworkManagerProtocol {
    init() {}

    func perform(request: URLRequest) async throws -> Data {
        Data()
    }
}

// sw: inject
final class AuthNetworkManager: NetworkManagerProtocol {
    let sessionManager: SessionManager

    init(/* sw: dependency */ sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func perform(request: URLRequest) async throws -> Data {
        Data()
    }
}

// sw: inject
public final class UserManager {
    let persistence: PersistenceProtocol
    let apiClient: ApiClient
    let sessionManager: SessionManager
    let userName: String
    let userEmail: String

    init(
        /* sw: dependency(User) */ persistence: PersistenceProtocol,
        /* sw: dependency(User) */ apiClient: ApiClient,
        /* sw: dependency */ sessionManager: SessionManager
    ) {
        self.persistence = persistence
        self.apiClient = apiClient
        self.sessionManager = sessionManager
        self.userName = "Some name"
        self.userEmail = "email@email.com"
    }
}

// sw: inject
final class SessionManager {
    let persistence: PersistenceProtocol

    init(/* sw: dependency(Session) */ persistence: PersistenceProtocol) {
        self.persistence = persistence
    }
}

protocol PersistenceProtocol {
}

// sw: inject
final class SessionDataPersistence: PersistenceProtocol {
    init() {}
}

// sw: inject
final class UserDataPersistence: PersistenceProtocol {
    init() {}
}

// sw: inject
func providesUserName(
    /* sw: dependency */ userManager: UserManager
) -> String {
    userManager.userName
}

// sw: inject
func providesUserEmail(
    /* sw: dependency */ userManager: UserManager
) -> String {
    userManager.userEmail
}

// sw: inject
final class UserViewModel {
    let userName: String
    let userEmail: String

    init(
        /* sw: dependency(UserName) */ userName: String,
        /* sw: dependency(UserEmail) */ userEmail: String
    ) {
        self.userName = userName
        self.userEmail = userEmail
    }
}
