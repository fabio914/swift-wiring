import UIKit

/*

This container has the base dependencies (that are available
whether or not the app has a session)

sw: container(AppContainer) {
  access(public)

  // Tools
  singleton(UserDefaultsPersistence, SessionPersistenceProtocol)
  singleton(PrintLogger, LoggerProtocol) {
    access(public)
  }
  singleton(SessionManager, SessionManagerProtocol)
  singleton(NetworkManager, NetworkManagerProtocol)

  // Initial flow
  build(InitialCoordinator, CoordinatorProtocol) {
    access(public)
    name(Initial)
  }

  // Logged out flow
  build(LoginApiClient, LoginApiClientProtocol)
  build(LoggedOutCoordinator)
  build(IntroViewModel)
  build(LoginViewModel)
}

*/
protocol AppContainerProtocol {}
