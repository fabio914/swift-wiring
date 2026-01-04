import UIKit

protocol CoordinatorProtocol: AnyObject {
    @MainActor
    func instantiateRoot() -> UIViewController?
}
