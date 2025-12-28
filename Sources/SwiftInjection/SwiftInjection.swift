import ArgumentParser
import Foundation
import SwiftSyntax
import SwiftParser

enum SwiftInjectionError: Error {
    case missingInputFile
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
            let sourceFiles = try inputFiles.map(parse)

            //        print(sourceFiles)

            guard sourceFiles.count > 0 else {
                throw SwiftInjectionError.missingInputFile
            }

            let firstFileName = inputFiles[0]
            let firstSource = sourceFiles[0]
            let sourceLocationConverter = SourceLocationConverter(fileName: firstFileName, tree: firstSource)

            let protocols = firstSource.statements.compactMap { item in item.item.as(ProtocolDeclSyntax.self) }

            let containers: [ContainerDefinition] = try protocols.compactMap { item -> ContainerDefinition? in
                try ContainerDefinition(converter: sourceLocationConverter, protocolDeclaration: item)
            }

            let classes = firstSource.statements.compactMap { item in item.item.as(ClassDeclSyntax.self) }

            let injectableClasses = try classes.compactMap { item -> InjectableClassDefinition? in
                try InjectableClassDefinition(converter: sourceLocationConverter, classDeclaration: item)
            }

            print(containers)
            print(injectableClasses)
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
