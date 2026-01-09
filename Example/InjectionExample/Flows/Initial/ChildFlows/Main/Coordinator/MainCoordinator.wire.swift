import UIKit

/* wiring:inject */
final class MainCoordinator: CoordinatorProtocol {

    let mainContainer: MainContainer
    weak var tabBarController: UITabBarController?

    init(/* wiring:dependency */ mainContainer: MainContainer) {
        self.mainContainer = mainContainer
    }

    func instantiateRoot() -> UIViewController? {
        let tabBarController = UITabBarController(tabs: [
            UITab(
                title: "User",
                image: UIImage(systemName: "person"),
                identifier: "user-tab",
                viewControllerProvider: { _ in
                    // Strong self reference (View Controllers retain the Coordinators)
                    self.mainContainer.buildUserCoordinator().instantiateRoot() ?? UIViewController()
                }
            ),
            UITab(
                title: "Settings",
                image: UIImage(systemName: "gear"),
                identifier: "settings-tab",
                viewControllerProvider: { _ in
                    // Strong self reference (View Controllers retain the Coordinators)
                    self.mainContainer.buildSettingsCoordinator().instantiateRoot() ?? UIViewController()
                }
            )
        ])

        self.tabBarController = tabBarController
        return tabBarController
    }
}

extension MainCoordinator: UserCoordinatorProtocol {

}
