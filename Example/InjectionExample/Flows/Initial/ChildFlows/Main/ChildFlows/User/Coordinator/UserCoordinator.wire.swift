import UIKit

/* wiring:inject */
final class UserCoordinator: CoordinatorProtocol {

    let mainContainer: MainContainer
    weak var navigationController: UINavigationController?

    init(
        /* wiring:dependency */ mainContainer: MainContainer
    ) {
        self.mainContainer = mainContainer
    }

    func instantiateRoot() -> UIViewController? {
        let viewModel = self.mainContainer.buildUserViewModel(coordinator: self)
        let viewController = UserScreen.makeViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        self.navigationController = navigationController
        return navigationController
    }
}

extension UserCoordinator: UserCoordinatorProtocol {

}
