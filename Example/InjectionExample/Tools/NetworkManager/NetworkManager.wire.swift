import Foundation

enum NetworkManagerError: Error {
    case notImplemented
}

@Inject
final class NetworkManager: NetworkManagerProtocol {

    let sessionManager: SessionManagerProtocol

    init(
        @Dependency sessionManager: SessionManagerProtocol
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
