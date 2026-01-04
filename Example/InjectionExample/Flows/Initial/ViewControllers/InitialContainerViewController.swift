import UIKit

protocol InitialContainerCoordinatorProtocol {
    @MainActor
    func didAppearForTheFirstTime()
}

final class InitialContainerViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        lastChildViewController?.preferredStatusBarStyle ?? .lightContent
    }

    let coordinator: InitialContainerCoordinatorProtocol
    private var firstAppearance = true

    init(coordinator: InitialContainerCoordinatorProtocol) {
        self.coordinator = coordinator
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstAppearance {
            firstAppearance = false
            coordinator.didAppearForTheFirstTime()
        }
    }

    weak var lastChildViewController: UIViewController?

    func present(childViewController: UIViewController?) {
        if let lastChildViewController {
            dismiss(animated: false, completion: nil)
            lastChildViewController.willMove(toParent: nil)
            lastChildViewController.view.removeFromSuperview()
            lastChildViewController.removeFromParent()
        }

        guard let childViewController else { return }

        self.lastChildViewController = childViewController
        addChild(childViewController)
        childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(childViewController.view)

        NSLayoutConstraint.activate([
            childViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            childViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        childViewController.view.frame = view.frame
        childViewController.didMove(toParent: self)
        setNeedsStatusBarAppearanceUpdate()
    }
}
