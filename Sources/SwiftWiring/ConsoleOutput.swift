import Foundation

final class ConsoleOutput {

    private var err = FileHandle.standardError

    func fatalError(_ error: Error) {
        print(error, to: &err)
        exit(1)
    }
}

extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
