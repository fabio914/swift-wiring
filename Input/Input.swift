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

    init(
        /* wiring: dependency(User) */ persistence: PersistenceProtocol,
        /* wiring: dependency(User) */ apiClient: ApiClient,
        /* wiring: dependency */ sessionManager: SessionManager
    ) {
        self.persistence = persistence
        self.apiClient = apiClient
        self.sessionManager = sessionManager
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
