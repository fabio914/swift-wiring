import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser

struct InjectCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "inject",
        abstract: "Use this command to generate Swift files with Container implementations"
    )

    @Option(name: .customShort("i"), help: "Input swift files")
    var inputFiles: [String]

//    @Option(name: .customShort("o"), help: "Output directory for the filtered files")
//    var outputDirectory: String

//    @Option(name: .customLong("container"), help: "Container output file")
//    var containerOutputFile: String

    func run() {
        let console = ConsoleOutput()

        do {
            let sourceFiles = try inputFiles.map { fileName in
                try SourceDefinition(fileName: fileName, tree: try SourceFileReader.parse(file: fileName))
            }

            let resolvedContainers = try DependencyResolver(sources: sourceFiles).resolvedContainers

            // TODO: Output file with Container implementations

            // TODO: Combine Containers

            for resolvedContainer in resolvedContainers {
                let containerOutput = ContainerOutput(resolvedContainer: resolvedContainer).generateSource()

                print("// \(resolvedContainer.containerDefinition.containerName).swift \n")
                print(containerOutput)
                print("")
            }
        } catch {
            console.fatalError(error)
        }
    }
}
