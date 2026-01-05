import UIKit

// This container has all dependencies for the Logged In state.
@Container(MainContainer)
@Instance(MainCoordinator)

// User Tab
@Instance(UserCoordinator)
@Instance(UserViewModel)

// Settings Tab
@Instance(SettingsCoordinator)
@Instance(SettingsViewModel)
protocol MainContainerProtocol {}
