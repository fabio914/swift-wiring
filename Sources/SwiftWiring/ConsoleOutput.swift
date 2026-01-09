import Foundation

final class ConsoleOutput {

    func fatalError(_ error: Error) {
        var err = StandardErrorOutputStream()
        print(error, to: &err)
        exit(1)
    }
}

struct StandardErrorOutputStream: TextOutputStream {
    private let stderr = FileHandle.standardError

    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        stderr.write(data)
    }
}
