import Foundation
import SwiftSyntax
import SwiftParser

enum InitializerDefinitionError: Error {
    case invalidDependencyDefinition
}

struct InitializerDefinition: CustomStringConvertible {
    // TODO: Extract dependencies and parameters
    let initializerDeclaration: InitializerDeclSyntax

    init(
        converter: SourceLocationConverter,
        initializerDeclaration: InitializerDeclSyntax
    ) throws {
        self.initializerDeclaration = initializerDeclaration
    }

    func filteredInitializerDeclaration() -> InitializerDeclSyntax {
        // TODO: Filter out our attributes, so we could print this in the output version of this file
        // without the extra annotations
        initializerDeclaration
    }

    var description: String {
        "InitializerDefinition()"
    }
}
