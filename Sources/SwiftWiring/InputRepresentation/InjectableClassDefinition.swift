import Foundation
import SwiftSyntax
import SwiftParser

enum InjectableClassDefinitionError: Error {
    case missingInitializer
    case multipleInitializersDetected
    case classWithGenericsNotSupported
    case unsupportedInheritance
}

struct InjectableClassDefinition: CustomStringConvertible {
    let className: ClassName
    let inheritanceChain: [BindingName]
    let initializerDefinition: InitializerDefinition
    let classDeclaration: ClassDeclSyntax
    let sourceLocation: SourceLocation

    init?(
        converter: SourceLocationConverter,
        classDeclaration: ClassDeclSyntax
    ) throws {
        guard try hasInjectableClassCommand(converter: converter, item: classDeclaration) else {
            return nil
        }

        if let genericParameterClause = classDeclaration.genericParameterClause {
            throw InputFileError(
                location: genericParameterClause.startLocation(converter: converter),
                error: InjectableClassDefinitionError.classWithGenericsNotSupported
            )
        }

        if let genericWhereClause = classDeclaration.genericWhereClause {
            throw InputFileError(
                location: genericWhereClause.startLocation(converter: converter),
                error: InjectableClassDefinitionError.classWithGenericsNotSupported
            )
        }

        self.className = classDeclaration.name.text

        self.inheritanceChain = try classDeclaration.inheritanceClause?.inheritedTypes.map { item in
            guard let identifier = item.type.as(IdentifierTypeSyntax.self) else {
                throw InputFileError(
                    location: item.startLocation(converter: converter),
                    error: InjectableClassDefinitionError.unsupportedInheritance
                )
            }

            if let genericArgumentClause = identifier.genericArgumentClause {
                throw InputFileError(
                    location: genericArgumentClause.startLocation(converter: converter),
                    error: InjectableClassDefinitionError.classWithGenericsNotSupported
                )
            }

            return identifier.name.text
        } ?? []

        self.classDeclaration = classDeclaration

        let initializers = classDeclaration.memberBlock.members.compactMap {
            item in item.decl.as(InitializerDeclSyntax.self)
        }

        // Only one initializer supported for now

        if initializers.count == 0 {
            throw InputFileError(
                location: classDeclaration.startLocation(converter: converter),
                error: InjectableClassDefinitionError.missingInitializer
            )
        } else if initializers.count > 1 {
            throw InputFileError(
                location: classDeclaration.startLocation(converter: converter),
                error: InjectableClassDefinitionError.multipleInitializersDetected
            )
        }

        self.initializerDefinition = try InitializerDefinition(converter: converter, initializerDeclaration: initializers[0])
        self.sourceLocation = classDeclaration.startLocation(converter: converter)
    }

    var description: String {
        "InjectableClassDefinition(\(className), \(inheritanceChain), \(initializerDefinition))"
    }
}

enum InjectableClassCommandError: Error {
    case expectedInjectCommand(found: WiringCommand)
}

///
/// Returns true if this is a class with `sw: inject`
///
private func hasInjectableClassCommand(
    converter: SourceLocationConverter,
    item: ClassDeclSyntax
) throws -> Bool {
    do {
        let wiringCommand = try item.leadingTrivia.wiringCommand()

        switch wiringCommand {
        case .inject:
            return true
        case .empty:
            return false
        default:
            throw InjectableClassCommandError.expectedInjectCommand(found: wiringCommand)
        }
    } catch {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: error
        )
    }
}
