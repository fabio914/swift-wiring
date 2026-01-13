# Swift Wiring

This is a command line tool for compile-time Automatic Dependency Injection for [Swift](https://www.swift.org). 
It reads `sw:` annotations in the Swift source code and generates `Container`s with your resolved dependencies.

This tool is still in active development and is **experimental**. I don't recommend adopting it in your project yet. 
Check the TO-DO list below for some of the things that still need to be implemented.

**Input**
```swift
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
```

**Output**
```swift
import Foundation

public final class MyContainer: MyContainerProtocol {
    let externalSomethingExternal: () -> SomethingExternal

    private(set) lazy var singletonSessionPersistenceProtocol: PersistenceProtocol = buildSessionPersistenceProtocol()

    private(set) lazy var singletonUserPersistenceProtocol: PersistenceProtocol = buildUserPersistenceProtocol()

    private(set) lazy var singletonSessionManager: SessionManager = buildSessionManager()

    public private(set) lazy var singletonUserManager: UserManager = buildUserManager()

    public init(
        somethingExternal: @autoclosure @escaping () -> SomethingExternal
    ) {
        self.externalSomethingExternal = somethingExternal
    }

    public func buildOtherApiClient() -> ApiClient {
        return OtherApi(
            networkManager: self.buildNetworkManagerProtocol()
        )
    }

    internal func buildUserApiClient() -> ApiClient {
        return UserInfoApi(
            authNetworkManager: self.buildAuthenticatedNetworkManagerProtocol()
        )
    }

    public func buildLoggedOutApi(
        parameter: String
    ) -> LoggedOutApi {
        return LoggedOutApi(
            networkManager: self.buildNetworkManagerProtocol(),
            something: self.externalSomethingExternal(),
            parameter: parameter
        )
    }

    internal func buildNetworkManagerProtocol() -> NetworkManagerProtocol {
        return NetworkManager(
        )
    }

    internal func buildAuthenticatedNetworkManagerProtocol() -> NetworkManagerProtocol {
        return AuthNetworkManager(
            sessionManager: self.singletonSessionManager
        )
    }

    private func buildSessionPersistenceProtocol() -> PersistenceProtocol {
        return SessionDataPersistence(
        )
    }

    private func buildUserPersistenceProtocol() -> PersistenceProtocol {
        return UserDataPersistence(
        )
    }

    private func buildSessionManager() -> SessionManager {
        return SessionManager(
            persistence: self.singletonSessionPersistenceProtocol
        )
    }

    internal func buildUserEmailString() -> String {
        return providesUserEmail(
            userManager: self.singletonUserManager
        )
    }

    private func buildUserManager() -> UserManager {
        return UserManager(
            persistence: self.singletonUserPersistenceProtocol,
            apiClient: self.buildUserApiClient(),
            sessionManager: self.singletonSessionManager
        )
    }

    internal func buildUserViewModel() -> UserViewModel {
        return UserViewModel(
            userName: self.buildUserNameString(),
            userEmail: self.buildUserEmailString()
        )
    }

    internal func buildUserNameString() -> String {
        return providesUserName(
            userManager: self.singletonUserManager
        )
    }
}
```

## Usage

```shell
swift-wiring inject <source files> -o <output file with your Containers>
```

## Example

Navigate to the `Example/` folder and use [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate an Xcode project of an iOS app that uses this tool.

You can install this command line tool with [Mint](https://github.com/yonaskolb/Mint):

```shell
mint install fabio914/swift-wiring@main
```

## TO-DOs

 - [ ] Add documentation;
 - [ ] Add Scopes with a collection of containers;
 - [ ] Support actors and main actors;
 - [ ] Support multiple initializers;
 
 etc...

## Credits

Developed by Fabio de Albuquerque Dela Antonio.

This project relies heavily on [Swift Syntax](https://github.com/swiftlang/swift-syntax).
