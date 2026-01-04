import Foundation

protocol SessionManagerDelegate: AnyObject {
    @MainActor
    func sessionDidStart(_ sessionManager: SessionManagerProtocol, session: Session, user: User)

    @MainActor
    func sessionDidEnd(_ sessionManager: SessionManagerProtocol)
}

protocol SessionManagerProtocol: AnyObject {
    @MainActor
    /* weak */ var delegate: SessionManagerDelegate? { get set }

    var session: Session? { get }
    var user: User? { get }

    func hasSession() -> Bool

    @MainActor
    func setSession(session: Session, user: User)

    @MainActor
    func clearSession()
}

struct Session: Codable {
    let sessionToken: String
}

struct User: Codable {
    let userId: Int
    let userName: String
}
