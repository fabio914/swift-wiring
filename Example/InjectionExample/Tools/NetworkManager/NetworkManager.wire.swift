import Foundation

enum NetworkManagerError: Error {
    case notImplemented
}

/* sw:inject */
final class NetworkManager: NetworkManagerProtocol {

    let sessionManager: SessionManagerProtocol

    init(/* sw:dependency */ sessionManager: SessionManagerProtocol) {
        self.sessionManager = sessionManager
    }

    func perform(request: URLRequest) async throws -> RequestResult {
        throw NetworkManagerError.notImplemented
    }

    func perform(authRequest: URLRequest) async throws -> RequestResult {
        throw NetworkManagerError.notImplemented
    }
}
