import Foundation
import SwiftSyntax

struct InputFileError: Error, CustomStringConvertible {
    let fileName: String
    let line: Int
    let column: Int
    let error: Error

    init(location: SourceLocation, error: Error) {
        self.fileName = location.file
        self.line = location.line
        self.column = location.column
        self.error = error
    }

    var description: String {
        "\(fileName):\(line):\(column): error: \(error)"
    }
}
