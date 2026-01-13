import Foundation

protocol SessionPersistenceProtocol: AnyObject {
    func readSession() throws -> Session?
    func readUser() throws -> User?
    func saveSession(_ session: Session) throws
    func saveUser(_ user: User) throws
    func clearSession()
    func clearUser()
}

enum SessionManagerError: Error {
    case failedToReadSession(Error)
    case failedToReadUser(Error)
    case failedToPersistSession(Error)
}

/* sw:inject */
final class SessionManager: SessionManagerProtocol {

    weak var delegate: SessionManagerDelegate?

    private let persistence: SessionPersistenceProtocol

    private let logger: LoggerProtocol

    init(/* sw:dependency */ persistence: SessionPersistenceProtocol, /* sw:dependency */ logger: LoggerProtocol) {
        self.persistence = persistence
        self.logger = logger
    }

    var session: Session? {
        do {
            return try persistence.readSession()
        } catch {
            logger.logError(SessionManagerError.failedToReadSession(error))
            return nil
        }
    }

    var user: User? {
        do {
            return try persistence.readUser()
        } catch {
            logger.logError(SessionManagerError.failedToReadUser(error))
            return nil
        }
    }

    func hasSession() -> Bool {
        session != nil && user != nil
    }

    @MainActor
    func setSession(session: Session, user: User) {
        do {
            try persistence.saveUser(user)
            try persistence.saveSession(session)
        } catch {
            logger.logError(SessionManagerError.failedToPersistSession(error))
        }

        delegate?.sessionDidStart(self, session: session, user: user)
    }

    @MainActor
    func clearSession() {
        persistence.clearSession()
        persistence.clearUser()
        delegate?.sessionDidEnd(self)
    }
}
