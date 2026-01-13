import UIKit

/*

This container has all dependencies for the Logged In state.

sw: container(MainContainer) {
  build(MainCoordinator)

  // User Tab
  build(UserCoordinator)
  build(UserViewModel)

  // Settings Tab
  build(SettingsCoordinator)
  build(SettingsViewModel)

  // Providers
  build(providesUserName, String) { name(UserName) }
  // the above is equivalent to: build(providesUserName) { name(UserName) }

  singleton(providesShortDateFormatter, DateFormatter) { name(Short) }
  // the above is equivalent to: singleton(providesShortDateFormatter) { name(Short) }
}

*/
protocol MainContainerProtocol {}

// sw: inject
func providesUserName(/* sw: dependency */ user: User) -> String {
    user.userName
}

// sw: inject
func providesShortDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
}
