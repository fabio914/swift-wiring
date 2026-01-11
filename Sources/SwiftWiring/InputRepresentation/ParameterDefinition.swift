import Foundation
import SwiftSyntax
import SwiftParser

struct ParameterDefinition: CustomStringConvertible {
    enum Kind {
        case dependency(FunctionParameterDependencyDefinition)
        case parameter(String)
    }

    let kind: Kind
    let functionParameter: FunctionParameterSyntax

    init(
        converter: SourceLocationConverter,
        previousTrailingTrivia: Trivia,
        functionParameter: FunctionParameterSyntax
    ) throws {
        self.functionParameter = functionParameter

        if let dependency = try dependencyCommand(
            converter: converter,
            previousTrailingTrivia: previousTrailingTrivia,
            item: functionParameter
        ) {
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

struct FunctionParameterDependencyDefinition: CustomStringConvertible {
    let parameterName: String
    let identifier: DependencyIdentifier

    var description: String {
        "FunctionParameterDependencyDefinition(\(parameterName), \(identifier))"
    }
}

private struct DependencyCommand {
    let name: Name?
}

private func parseDependencyCommand(
    converter: SourceLocationConverter,
    previousTrailingTrivia: Trivia,
    item: FunctionParameterSyntax
) throws -> DependencyCommand? {
    do {
        let trivia = previousTrailingTrivia + item.leadingTrivia
        let wiringCommand = try trivia.wiringCommand()

        switch wiringCommand {
        case .dependency(let name):
            return DependencyCommand(name: name)
        case .empty:
            return nil
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
/// Detects a `wiring: dependency` or `wiring: dependency(SomeName)` in a Function Parameter
/// Example:
///   /* wiring: dependency */ someDependency: SomeDependencyProtocol
///
private func dependencyCommand(
    converter: SourceLocationConverter,
    previousTrailingTrivia: Trivia,
    item: FunctionParameterSyntax
) throws -> FunctionParameterDependencyDefinition? {
    guard let dependency = try parseDependencyCommand(
        converter: converter,
        previousTrailingTrivia: previousTrailingTrivia,
        item: item
    ) else {
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

    return FunctionParameterDependencyDefinition(
        parameterName: item.firstName.text,
        identifier: DependencyIdentifier(
            bindingName: identifier.name.text,
            name: dependency.name
        )
    )
}
