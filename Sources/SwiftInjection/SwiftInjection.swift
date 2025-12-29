import ArgumentParser
import Foundation
import SwiftSyntax
import SwiftParser

enum SwiftInjectionError: Error {
    case failedToReadFile(String, Error)
}

@main
struct SwiftInjection: ParsableCommand {
    @Option(name: .customShort("i"), help: "Input swift files")
    var inputFiles: [String]

//    @Option(name: .customShort("o"), help: "Output directory")
//    var outputDirectory: String

    func run() {
        let console = ConsoleOutput()

        do {
            let sourceFiles = try inputFiles.map { fileName in
                try SourceDefinition(fileName: fileName, tree: try parse(file: fileName))
            }

            let resolvedContainers = try DependencyResolver(sources: sourceFiles).resolvedContainers
            print(resolvedContainers)

            // TODO: Filter out source files and save to output

            // TODO: Output file with Container implementations
        } catch {
            console.fatalError(error)
        }
    }

    func parse(file: String) throws -> SourceFileSyntax {
        do {
            let url = URL(fileURLWithPath: file)
            let source = try String(contentsOf: url, encoding: .utf8)
            return Parser.parse(source: source)
        } catch {
            throw SwiftInjectionError.failedToReadFile(file, error)
        }
    }
}
