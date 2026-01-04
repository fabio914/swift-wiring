import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser

struct FilterCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "filter",
        abstract: "Use this command to output your Swift files without the swift-wiring annotations"
    )

    @Option(name: .customShort("i"), help: "Input Swift file")
    var inputFile: String

    @Option(name: .customShort("o"), help: "Output Swift file")
    var outputFile: String

    func run() {
        let console = ConsoleOutput()

        do {
            let sourceDefinition = try SourceDefinition(fileName: inputFile, tree: try SourceFileReader.parse(file: inputFile))
            let filteredSource = sourceDefinition.filteredSource().description
            try filteredSource.write(to: URL(fileURLWithPath: outputFile), atomically: true, encoding: .utf8)
        } catch {
            console.fatalError(error)
        }
    }
}
