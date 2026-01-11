import Foundation
import SwiftSyntax
import SwiftParser

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
        // TODO: Implement
        return nil
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
