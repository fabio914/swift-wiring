import Foundation
import SwiftSyntax
import SwiftParser

struct SourceDefinition: CustomStringConvertible {
    let containers: [ContainerDefinition]
    let injectableClasses: [InjectableClassDefinition]

    let fileName: String
    let tree: SourceFileSyntax

    init(fileName: String, tree: SourceFileSyntax) throws {
        let sourceLocationConverter = SourceLocationConverter(fileName: fileName, tree: tree)

        let protocols = tree.statements.compactMap { item in item.item.as(ProtocolDeclSyntax.self) }

        self.containers = try protocols.compactMap { item -> ContainerDefinition? in
            try ContainerDefinition(converter: sourceLocationConverter, protocolDeclaration: item)
        }

        // Ignoring nested classes
        let classes = tree.statements.compactMap { item in item.item.as(ClassDeclSyntax.self) }

        self.injectableClasses = try classes.compactMap { item -> InjectableClassDefinition? in
            try InjectableClassDefinition(converter: sourceLocationConverter, classDeclaration: item)
        }

        self.fileName = fileName
        self.tree = tree
    }

    // TODO: Filter source

    var description: String {
        "SourceDefinition(\(fileName), \(containers), \(injectableClasses))"
    }
}
