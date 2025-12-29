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

    var hasDependencies: Bool {
        parameters.first(where: {
            switch $0.kind {
            case .dependency:
                true
            default:
                false
            }
        }) != nil
    }

    func filteredInitializerDeclaration() -> InitializerDeclSyntax {
        // TODO: Filter out our attributes, so we could print this in the output version of this file
        // without the extra annotations
        initializerDeclaration
    }

    var description: String {
        "InitializerDefinition(\(parameters))"
    }
}

struct ParameterDefinition: CustomStringConvertible {
    enum Kind {
        case dependency(DependencyDefinition)
        case parameter
    }

    let kind: Kind
    let functionParameter: FunctionParameterSyntax

    init(
        converter: SourceLocationConverter,
        functionParameter: FunctionParameterSyntax
    ) throws {
        self.functionParameter = functionParameter

        if let dependency = try dependencyAttribute(converter: converter, item: functionParameter) {
            self.kind = .dependency(dependency)
        } else {
            self.kind = .parameter
        }
    }

    func filteredFunctionParameterDefinition() -> FunctionParameterSyntax {
        // TODO: Filter out our attributes, so we could print this in the output version of this file
        // without the extra annotations
        functionParameter
    }

    var description: String {
        "ParameterDefinition(\(kind))"
    }
}

// MARK: - Attributes

enum DependencyDefinitionError: Error {
    case invalidArgumentsInDependencyAttribute
    case multipleDependencyAttributes
    case defaultValuesNotSupported
    case parameterTypeNotSupported
    case genericTypeNotSupported
}

struct DependencyDefinition: CustomStringConvertible {
    let parameterName: String
    let type: String

    var description: String {
        "DependencyDefinition(\(parameterName), \(type))"
    }
}

///
/// Detects a Dependency Annotation in a Function Parameter
/// Example:
///   @Dependency someDependency: SomeDependencyProtocol
///
func dependencyAttribute(
    converter: SourceLocationConverter,
    item: FunctionParameterSyntax
) throws -> DependencyDefinition? {
    guard !item.attributes.isEmpty else {
        return nil
    }

    let dependencyAttribute: AttributeListSyntax = try item.attributes.filter { element in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self),
              identifier.name.text == "Dependency"
        else {
            return false
        }

        if let labeledArguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              labeledArguments.count != 0 {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: DependencyDefinitionError.invalidArgumentsInDependencyAttribute
            )
        }

        return true
    }

    if dependencyAttribute.count == 0 {
        return nil
    }

    if dependencyAttribute.count > 1 {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: DependencyDefinitionError.multipleDependencyAttributes
        )
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

    return DependencyDefinition(
        parameterName: item.firstName.text,
        type: identifier.name.text
    )
}
