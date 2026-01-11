import Foundation
import SwiftSyntax
import SwiftParser

enum InitializerDefinitionError: Error {
    case invalidDependencyDefinition
    case initializerWithOptionalsNotSupported
    case initializerWithGenericsNotSupported
    case initializerWithEffectSpecifiersNotSupported
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

        if let effectSpecifiers = initializerDeclaration.signature.effectSpecifiers {
            throw InputFileError(
                location: effectSpecifiers.startLocation(converter: converter),
                error: InitializerDefinitionError.initializerWithEffectSpecifiersNotSupported
            )
        }

        self.parameters = try ParameterDefinition.parameters(from: initializerDeclaration.signature, converter: converter)
    }

    var dependencies: [FunctionParameterDependencyDefinition] {
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
