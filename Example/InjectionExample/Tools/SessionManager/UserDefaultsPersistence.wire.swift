import Foundation

// Use the Keychain for session persistence in a Prod app, please
@Inject
final class UserDefaultsPersistence: SessionPersistenceProtocol {

    private let userDefaults = UserDefaults.standard

    init() {
    }

    func readSession() throws -> Session? {
        guard let data = userDefaults.data(forKey: "session") else { return nil }
        return try JSONDecoder().decode(Session.self, from: data)
    }

    func readUser() throws -> User? {
        guard let data = userDefaults.data(forKey: "user") else { return nil }
        return try JSONDecoder().decode(User.self, from: data)
    }

    func saveSession(_ session: Session) throws {
        userDefaults.set(try JSONEncoder().encode(session), forKey: "session")
    }

    func saveUser(_ user: User) throws {
        userDefaults.set(try JSONEncoder().encode(user), forKey: "user")
    }

    func clearSession() {
        userDefaults.removeObject(forKey: "session")
    }

    func clearUser() {
        userDefaults.removeObject(forKey: "user")
    }
}
