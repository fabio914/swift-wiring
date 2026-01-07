import Foundation
import SwiftSyntax
import SwiftParser

enum InitializerDefinitionError: Error {
    case invalidDependencyDefinition
    case initializerWithOptionalsNotSupported
    case initializerWithGenericsNotSupported
    case initializerWithReturnsNotSupported
}

struct InitializerDefinition: CustomStringConvertible {
    let parameters: [ParameterDefinition]
    let initializerDeclaration: InitializerDeclSyntax

    init(
        converter: SourceLocationConverter,
        initializerDeclaration: InitializerDeclSyntax
    ) throws {
        self.initializerDeclaration = initializerDeclaration

        if let returnClause = initializerDeclaration.signature.returnClause {
            throw InputFileError(
                location: returnClause.startLocation(converter: converter),
                error: InitializerDefinitionError.initializerWithReturnsNotSupported
            )
        }

        if let optionalMark = initializerDeclaration.optionalMark {
            throw InputFileError(
                location: optionalMark.startLocation(converter: converter),
                error: InitializerDefinitionError.initializerWithOptionalsNotSupported
            )
        }

        if let genericParameterClause = initializerDeclaration.genericParameterClause {
            throw InputFileError(
                location: genericParameterClause.startLocation(converter: converter),
                error: InitializerDefinitionError.initializerWithGenericsNotSupported
            )
        }

        if let genericWhereClause = initializerDeclaration.genericWhereClause {
            throw InputFileError(
                location: genericWhereClause.startLocation(converter: converter),
                error: InitializerDefinitionError.initializerWithGenericsNotSupported
            )
        }

        self.parameters = try initializerDeclaration.signature.parameterClause.parameters.compactMap { parameter in
            try ParameterDefinition(converter: converter, functionParameter: parameter)
        }
    }

    var dependencies: [InitializerDependencyDefinition] {
        parameters.compactMap {
            switch $0.kind {
            case .dependency(let dependency):
                dependency
            default:
                nil
            }
        }
    }

    var hasParameters: Bool {
        parameters.first(where: {
            switch $0.kind {
            case .parameter:
                true
            default:
                false
            }
        }) != nil
    }

    var description: String {
        "InitializerDefinition(\(parameters))"
    }
}

struct ParameterDefinition: CustomStringConvertible {
    enum Kind {
        case dependency(InitializerDependencyDefinition)
        case parameter(String)
    }

    let kind: Kind
    let functionParameter: FunctionParameterSyntax

    init(
        converter: SourceLocationConverter,
        functionParameter: FunctionParameterSyntax
    ) throws {
        self.functionParameter = functionParameter

        if let dependency = try dependencyCommand(converter: converter, item: functionParameter) {
            self.kind = .dependency(dependency)
        } else {
            self.kind = .parameter(functionParameter.firstName.text)
        }
    }

    var description: String {
        "ParameterDefinition(\(kind))"
    }
}

enum DependencyDefinitionError: Error {
    case expectedDependencyCommand(found: WiringCommand)
    case defaultValuesNotSupported
    case parameterTypeNotSupported
    case genericTypeNotSupported
}

struct InitializerDependencyDefinition: CustomStringConvertible {
    let parameterName: String
    let type: String

    var description: String {
        "InitializerDependencyDefinition(\(parameterName), \(type))"
    }
}

private func hasDependencyCommand(
    converter: SourceLocationConverter,
    item: FunctionParameterSyntax
) throws -> Bool {
    do {
        let wiringCommand = try item.leadingTrivia.wiringCommand()

        switch wiringCommand {
        case .dependency:
            return true
        case .empty:
            return false
        default:
            throw DependencyDefinitionError.expectedDependencyCommand(found: wiringCommand)
        }
    } catch {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: error
        )
    }
}

///
/// Detects a `wiring: dependency` in a Function Parameter
/// Example:
///   /* wiring: dependency */ someDependency: SomeDependencyProtocol
///
private func dependencyCommand(
    converter: SourceLocationConverter,
    item: FunctionParameterSyntax
) throws -> InitializerDependencyDefinition? {
    guard try hasDependencyCommand(converter: converter, item: item) else {
        return nil
    }

    guard item.defaultValue == nil else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: DependencyDefinitionError.defaultValuesNotSupported
        )
    }

    // Functions and Tuples are not supported yet
    guard let identifier = item.type.as(IdentifierTypeSyntax.self) else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: DependencyDefinitionError.parameterTypeNotSupported
        )
    }

    // Generics are not supported yet
    guard identifier.genericArgumentClause == nil else {
        throw InputFileError(
            location: identifier.startLocation(converter: converter),
            error: DependencyDefinitionError.genericTypeNotSupported
        )
    }

    return InitializerDependencyDefinition(
        parameterName: item.firstName.text,
        type: identifier.name.text
    )
}
