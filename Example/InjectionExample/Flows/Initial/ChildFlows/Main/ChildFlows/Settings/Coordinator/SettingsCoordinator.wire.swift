import UIKit

/* sw:inject */
final class SettingsCoordinator: CoordinatorProtocol {

    let mainContainer: MainContainer
    weak var navigationController: UINavigationController?

    init(/* sw:dependency */ mainContainer: MainContainer) {
        self.mainContainer = mainContainer
    }

    func instantiateRoot() -> UIViewController? {
        let viewModel = self.mainContainer.buildSettingsViewModel(coordinator: self)
        let viewController = SettingsScreen.makeViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        self.navigationController = navigationController
        return navigationController
    }
}

extension SettingsCoordinator: SettingsCoordinatorProtocol {

}
