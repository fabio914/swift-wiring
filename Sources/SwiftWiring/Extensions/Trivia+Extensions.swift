import Foundation
import SwiftSyntax
import SwiftParser

extension TriviaPiece {

    var rawComment: String {
        switch self {
        case .docLineComment(let comment):
            String(comment.dropFirst(3))
        case .docBlockComment(let comment):
            comment
                .replacingOccurrences(of: "/**\n", with: "\n")
                .replacingOccurrences(of: "*/", with: "")
                .replacingOccurrences(of: "\n *", with: "\n")
        case .lineComment(let comment):
            String(comment.dropFirst(2))
        case .blockComment(let comment):
            comment
                .replacingOccurrences(of: "/*", with: "")
                .replacingOccurrences(of: "*/", with: "")
                .replacingOccurrences(of: "\n *", with: "\n")
        default:
            ""
        }
    }
}

extension Trivia {

    var allComments: String {
        pieces
            .filter({ $0.isComment })
            .map({ $0.rawComment })
            .joined(separator: "\n")
    }
}
