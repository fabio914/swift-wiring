import Foundation

protocol LoginApiClientProtocol: AnyObject {
    func login(userName: String) async throws -> (User, Session)
}

enum LoginError: Error {
    case emptyUserName
    case randomError
}

/* wiring:inject */
final class LoginApiClient: LoginApiClientProtocol {

    let networkManager: NetworkManagerProtocol

    init(
        /* wiring:dependency */ networkManager: NetworkManagerProtocol
    ) {
        self.networkManager = networkManager
    }

    func login(userName: String) async throws -> (User, Session) {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // We would make a network call here...

        let trimmed = userName.trimmingCharacters(in: .whitespaces)

        if trimmed.isEmpty {
            throw LoginError.emptyUserName
        } else if Bool.random() {
            throw LoginError.randomError
        } else {
            let user = User(userId: Int.random(in: 0 ..< 1_000_000), userName: userName)
            let session = Session(sessionToken: UUID().uuidString)
            return (user, session)
        }
    }
}
