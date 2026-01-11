import Foundation
import SwiftSyntax
import SwiftParser

enum InjectableFunctionDefinitionError: Error {
    case functionWithGenericsNotSupported
    case functionWithoutReturn
    case functionWithEffectSpecifiersNotSupported
}

struct InjectableFunctionDefinition: CustomStringConvertible {
    let functionName: FunctionName
    let bindingName: BindingName
    let parameters: [ParameterDefinition]
    let functionDeclaration: FunctionDeclSyntax
    let sourceLocation: SourceLocation

    init?(
        converter: SourceLocationConverter,
        functionDeclaration: FunctionDeclSyntax
    ) throws {
        guard try hasInjectableFunctionCommand(converter: converter, item: functionDeclaration) else {
            return nil
        }

        if let genericParameterClause = functionDeclaration.genericParameterClause {
            throw InputFileError(
                location: genericParameterClause.startLocation(converter: converter),
                error: InjectableFunctionDefinitionError.functionWithGenericsNotSupported
            )
        }

        if let genericWhereClause = functionDeclaration.genericWhereClause {
            throw InputFileError(
                location: genericWhereClause.startLocation(converter: converter),
                error: InjectableFunctionDefinitionError.functionWithGenericsNotSupported
            )
        }

        if let effectSpecifiers = functionDeclaration.signature.effectSpecifiers {
            throw InputFileError(
                location: effectSpecifiers.startLocation(converter: converter),
                error: InjectableFunctionDefinitionError.functionWithEffectSpecifiersNotSupported
            )
        }

        guard let returnClause = functionDeclaration.signature.returnClause else {
            throw InputFileError(
                location: functionDeclaration.signature.startLocation(converter: converter),
                error: InjectableFunctionDefinitionError.functionWithoutReturn
            )
        }

        self.functionName = functionDeclaration.name.text
        self.bindingName = try returnBindingName(converter: converter, item: returnClause)
        self.parameters = try ParameterDefinition.parameters(from: functionDeclaration.signature, converter: converter)
        self.functionDeclaration = functionDeclaration
        self.sourceLocation = functionDeclaration.startLocation(converter: converter)
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

    var description: String {
        "InjectableFunctionDefinition(\(functionName), \(bindingName), \(parameters))"
    }
}

enum InjectableFunctionCommandError: Error {
    case expectedInjectCommand(found: WiringCommand)
}

///
/// Returns true if this is a function with `wiring: inject`
///
private func hasInjectableFunctionCommand(
    converter: SourceLocationConverter,
    item: FunctionDeclSyntax
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

enum InjectableFunctionReturnError: Error {
    case returnTypeNotSupported
    case genericTypeNotSupported
}

private func returnBindingName(
    converter: SourceLocationConverter,
    item: ReturnClauseSyntax
) throws -> BindingName {

    // Functions, Tuples and Optionals are not supported yet
    guard let identifier = item.type.as(IdentifierTypeSyntax.self) else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: InjectableFunctionReturnError.returnTypeNotSupported
        )
    }

    // Generics are not supported yet
    guard identifier.genericArgumentClause == nil else {
        throw InputFileError(
            location: identifier.startLocation(converter: converter),
            error: InjectableFunctionReturnError.genericTypeNotSupported
        )
    }

    return identifier.name.text
}
