import UIKit

/*

This container has all dependencies for the Logged In state.

wiring: container(MainContainer) {
  instance(MainCoordinator)

  // User Tab
  instance(UserCoordinator)
  instance(UserViewModel)

  // Settings Tab
  instance(SettingsCoordinator)
  instance(SettingsViewModel)

  // Providers
  bind(providesUserName, String) { name(UserName) }
  // the above is equivalent to: instance(providesUserName) { name(UserName) }

  singletonBind(providesShortDateFormatter, DateFormatter) { name(Short) }
  // the above is equivalent to: singleton(providesShortDateFormatter) { name(Short) }
}

*/
protocol MainContainerProtocol {}

// wiring: inject
func providesUserName(/* wiring: dependency */ user: User) -> String {
    user.userName
}

// wiring: inject
func providesShortDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
}
