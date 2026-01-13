import Foundation

/* sw:inject */
final class PrintLogger: LoggerProtocol {

    init() {
    }

    func log(_ message: String) {
        print("[MESSAGE] \(message)")
    }

    func logError(_ error: Error) {
        print("[ERROR] \(error)")
    }
}
