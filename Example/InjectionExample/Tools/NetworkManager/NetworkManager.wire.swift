import Foundation

enum NetworkManagerError: Error {
    case notImplemented
}

/* wiring:inject */
final class NetworkManager: NetworkManagerProtocol {

    let sessionManager: SessionManagerProtocol

    init(
        /* wiring:dependency */ sessionManager: SessionManagerProtocol
    ) {
        self.sessionManager = sessionManager
    }

    func perform(request: URLRequest) async throws -> RequestResult {
        throw NetworkManagerError.notImplemented
    }

    func perform(authRequest: URLRequest) async throws -> RequestResult {
        throw NetworkManagerError.notImplemented
    }
}
