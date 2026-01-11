import UIKit

public protocol CoordinatorProtocol: AnyObject {
    @MainActor
    func instantiateRoot() -> UIViewController?
}
