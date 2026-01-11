import Foundation
import SwiftSyntax
import SwiftParser

struct SourceDefinition: CustomStringConvertible {
    let containers: [ContainerDefinition]
    let injectableClasses: [InjectableClassDefinition]
    let injectableFunctions: [InjectableFunctionDefinition]

    let fileName: String
    let tree: SourceFileSyntax

    init(fileName: String, tree: SourceFileSyntax) throws {
        let sourceLocationConverter = SourceLocationConverter(fileName: fileName, tree: tree)

        var containers: [ContainerDefinition] = []
        var injectableClasses: [InjectableClassDefinition] = []
        var injectableFunctions: [InjectableFunctionDefinition] = []

        let imports: [ImportDeclSyntax] = tree.statements.compactMap { item in
            guard let importDeclaration = item.item.as(ImportDeclSyntax.self) else { return nil }
            return importDeclaration
        }

        try tree.statements.forEach { item in
            if let protocolDeclaration = item.item.as(ProtocolDeclSyntax.self) {
                if let container = try ContainerDefinition(converter: sourceLocationConverter, imports: imports, protocolDeclaration: protocolDeclaration) {
                    containers.append(container)
                }
            } else if let classDeclaration = item.item.as(ClassDeclSyntax.self) {
                // Ignoring nested classes
                if let injectableClass = try InjectableClassDefinition(converter: sourceLocationConverter, classDeclaration: classDeclaration) {
                    injectableClasses.append(injectableClass)
                }
            } else if let functionDeclaration = item.item.as(FunctionDeclSyntax.self) {
                // Ignoring nested functions
                if let injectableFunction = try InjectableFunctionDefinition(converter: sourceLocationConverter, functionDeclaration: functionDeclaration) {
                    injectableFunctions.append(injectableFunction)
                }
            }
        }

        self.fileName = fileName
        self.tree = tree
        self.containers = containers
        self.injectableClasses = injectableClasses
        self.injectableFunctions = injectableFunctions
    }

    var description: String {
        "SourceDefinition(\(fileName), \(containers), \(injectableClasses))"
    }
}
