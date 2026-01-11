import Foundation

// wiring: container(MyContainer) {
//   access(public)
//
//   singleton(SessionManager)
//   singleton(UserManager) { access(public) }
//
//   singletonBind(UserDataPersistence, PersistenceProtocol) { name(User) }
//   singletonBind(SessionDataPersistence, PersistenceProtocol) { name(Session) }
//
//   bind(NetworkManager, NetworkManagerProtocol)
//   bind(AuthNetworkManager, NetworkManagerProtocol) { name(Authenticated) }
//
//   instance(LoggedOutApi) { access(public) }
//   bind(OtherApi, ApiClient) { access(public) name(Other) }
//   bind(UserInfoApi, ApiClient) { name(User) }
//
//   instance(providesUserName) { name(UserName) }
//   bind(providesUserEmail, String) { name(UserEmail) }
//   instance(UserViewModel)
// }
protocol MyContainerProtocol {
}

public protocol ApiClient {}

protocol SomethingExternal {}

// wiring: inject
final class LoggedOutApi: ApiClient {
    let networkManager: NetworkManagerProtocol
    let something: SomethingExternal
    let parameter: String

    init(
        // wiring: dependency
        networkManager: NetworkManagerProtocol,
        // wiring: dependency
        something: SomethingExternal,
        parameter: String
    ) {
        self.networkManager = networkManager
        self.something = something
        self.parameter = parameter
    }
}

// wiring: inject
final class OtherApi: ApiClient {
    let networkManager: NetworkManagerProtocol

    init(
        // wiring: dependency
        networkManager: NetworkManagerProtocol
    ) {
        self.networkManager = networkManager
    }
}

// wiring: inject
final class UserInfoApi: ApiClient {
    let authNetworkManager: NetworkManagerProtocol
    
    init(
        // wiring: dependency(Authenticated)
        authNetworkManager: NetworkManagerProtocol
    ) {
        self.authNetworkManager = authNetworkManager
    }
}

protocol NetworkManagerProtocol {
    func perform(request: URLRequest) async throws -> Data
}

// wiring: inject
final class NetworkManager: NetworkManagerProtocol {
    init() {}

    func perform(request: URLRequest) async throws -> Data {
        Data()
    }
}

// wiring: inject
final class AuthNetworkManager: NetworkManagerProtocol {
    let sessionManager: SessionManager

    init(/* wiring: dependency */ sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func perform(request: URLRequest) async throws -> Data {
        Data()
    }
}

// wiring: inject
public final class UserManager {
    let persistence: PersistenceProtocol
    let apiClient: ApiClient
    let sessionManager: SessionManager
    let userName: String
    let userEmail: String

    init(
        /* wiring: dependency(User) */ persistence: PersistenceProtocol,
        /* wiring: dependency(User) */ apiClient: ApiClient,
        /* wiring: dependency */ sessionManager: SessionManager
    ) {
        self.persistence = persistence
        self.apiClient = apiClient
        self.sessionManager = sessionManager
        self.userName = "Some name"
        self.userEmail = "email@email.com"
    }
}

// wiring: inject
final class SessionManager {
    let persistence: PersistenceProtocol

    init(/* wiring: dependency(Session) */ persistence: PersistenceProtocol) {
        self.persistence = persistence
    }
}

protocol PersistenceProtocol {
}

// wiring: inject
final class SessionDataPersistence: PersistenceProtocol {
    init() {}
}

// wiring: inject
final class UserDataPersistence: PersistenceProtocol {
    init() {}
}

// wiring: inject
func providesUserName(
    /* wiring: dependency */ userManager: UserManager
) -> String {
    userManager.userName
}

// wiring: inject
func providesUserEmail(
    /* wiring: dependency */ userManager: UserManager
) -> String {
    userManager.userEmail
}

// wiring: inject
final class UserViewModel {
    let userName: String
    let userEmail: String

    init(
        /* wiring: dependency(UserName) */ userName: String,
        /* wiring: dependency(UserEmail) */ userEmail: String
    ) {
        self.userName = userName
        self.userEmail = userEmail
    }
}
