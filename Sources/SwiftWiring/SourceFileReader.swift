import Foundation
import SwiftSyntax
import SwiftParser

enum SwiftWiringError: Error {
    case failedToReadFile(String, Error)
}

enum SourceFileReader {

    static func parse(file: String) throws -> SourceFileSyntax {
        do {
            let url = URL(fileURLWithPath: file)
            let source = try String(contentsOf: url, encoding: .utf8)
            return Parser.parse(source: source)
        } catch {
            throw SwiftWiringError.failedToReadFile(file, error)
        }
    }
}
