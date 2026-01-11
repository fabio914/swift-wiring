import Foundation
import SwiftSyntax

enum Injectable {
    case `class`(InjectableClassDefinition)
    case function(InjectableFunctionDefinition)

    var dependencyIdentifiers: [DependencyIdentifier] {
        switch self {
        case .class(let injectableClass):
            injectableClass.initializerDefinition.dependencies.map(\.identifier)
        case .function(let injectableFunction):
            injectableFunction.dependencies.map(\.identifier)
        }
    }

    var parameters: [ParameterDefinition] {
        switch self {
        case .class(let injectableClass):
            injectableClass.initializerDefinition.parameters
        case .function(let injectableFunction):
            injectableFunction.parameters
        }
    }

    var hasParameters: Bool {
        switch self {
        case .class(let injectableClass):
            injectableClass.initializerDefinition.hasParameters
        case .function(let injectableFunction):
            injectableFunction.hasParameters
        }
    }

    var sourceLocation: SourceLocation {
        switch self {
        case .class(let injectableClass):
            injectableClass.sourceLocation
        case .function(let injectableFunction):
            injectableFunction.sourceLocation
        }
    }

    var classOrFunctionName: ClassOrFunctionName {
        switch self {
        case .class(let injectableClass):
            injectableClass.className
        case .function(let injectableFunction):
            injectableFunction.functionName
        }
    }
}
