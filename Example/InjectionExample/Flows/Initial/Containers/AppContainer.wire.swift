import UIKit

/*

This container has the base dependencies (that are available
whether or not the app has a session)

wiring: container(AppContainer) {
  access(public)

  // Tools
  singletonBind(UserDefaultsPersistence, SessionPersistenceProtocol)
  singletonBind(PrintLogger, LoggerProtocol) {
    access(public)
  }
  singletonBind(SessionManager, SessionManagerProtocol)
  singletonBind(NetworkManager, NetworkManagerProtocol)

  // Initial flow
  instance(InitialCoordinator) {
    access(public)
  }

  // Logged out flow
  bind(LoginApiClient, LoginApiClientProtocol)
  instance(LoggedOutCoordinator)
  instance(IntroViewModel)
  instance(LoginViewModel)
}

*/
protocol AppContainerProtocol {}
