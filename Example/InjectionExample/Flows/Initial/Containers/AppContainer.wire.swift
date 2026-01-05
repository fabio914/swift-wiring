import UIKit

// This container has the base dependencies (that are available
// whether or not the app has a session)
@Container(AppContainer)

// Tools
@SingletonBind(UserDefaultsPersistence, SessionPersistenceProtocol)
@SingletonBind(PrintLogger, LoggerProtocol)
@SingletonBind(SessionManager, SessionManagerProtocol)
@SingletonBind(NetworkManager, NetworkManagerProtocol)

// Initial flow
@Instance(InitialCoordinator)

// Logged out flow
@Bind(LoginApiClient, LoginApiClientProtocol)
@Instance(LoggedOutCoordinator)
@Instance(IntroViewModel)
@Instance(LoginViewModel)
protocol AppContainerProtocol {}
