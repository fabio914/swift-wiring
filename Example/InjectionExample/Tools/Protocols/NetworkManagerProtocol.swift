import Foundation

struct RequestResult: Sendable, Equatable {
    let response: HTTPURLResponse
    let data: Data
}

protocol NetworkManagerProtocol: AnyObject {
    func perform(request: URLRequest) async throws -> RequestResult
    func perform(authRequest: URLRequest) async throws -> RequestResult
}
