import Foundation
import SwiftSyntax
import SwiftParser

struct Binding: CustomStringConvertible {
    enum Kind {
        case singleton
        case build
    }

    let kind: Kind
    let className: String
    let protocolName: String
    let sourceLocation: SourceLocation

    var description: String {
        "Binding(\(kind), \(className), \(protocolName))"
    }
}

struct Injectable: CustomStringConvertible {
    let className: String
    let sourceLocation: SourceLocation
    
    var description: String {
        "Injectable(\(className))"
    }
}

///
/// Container Definition
/// A container can hold instances (singletons), build instances, and inject instances.
/// This container definition is a protocol with extra attributes defining the Container name,
/// its bindings and singletons.
///
struct ContainerDefinition: CustomStringConvertible {
    let containerName: String
    let containerProtocolName: String

    let bindings: [ProtocolName: Binding]

    // These can only be built (with other dependencies) but won't be injected into other dependencies
    let injectables: [String: Injectable]

    let protocolDeclaration: ProtocolDeclSyntax
    let sourceLocation: SourceLocation

    init?(
        converter: SourceLocationConverter,
        protocolDeclaration: ProtocolDeclSyntax
    ) throws {
        guard let containerName = try containerNameAttribute(converter: converter, item: protocolDeclaration) else {
            return nil
        }

        self.containerName = containerName
        self.containerProtocolName = protocolDeclaration.name.text
        self.bindings = try bindingAttributes(converter: converter, item: protocolDeclaration)
        self.injectables = try injectableAttributes(converter: converter, item: protocolDeclaration)
        self.protocolDeclaration = protocolDeclaration
        self.sourceLocation = protocolDeclaration.startLocation(converter: converter)
    }

    func filteredProtocolDeclaration() -> ProtocolDeclSyntax {
        filterContainerAttributes(from: protocolDeclaration)
    }

    var description: String {
        "ContainerDefinition(\(containerName), \(containerProtocolName), \(bindings))"
    }
}

// MARK: - Attributes

enum ContainerNameAttributeError: Error {
    case missingLabelWithContainerName
    case containerNameIsMissing
    case containerAttributeShouldOnlyHaveOneParameter
    case invalidContainerAttribute
    case multipleContainerAttributesDetected
}

///
/// Extracts a Container Name attribute from a Protocol definition
/// Format: @Container(MyContainerName)
///
func containerNameAttribute(
    converter: SourceLocationConverter,
    item: ProtocolDeclSyntax
) throws -> String? {
    guard !item.attributes.isEmpty else {
        // This protocol isn't a container
        return nil
    }

    let containerNameAttributes: [String] = try item.attributes.compactMap { element -> String? in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self),
              identifier.name.text == "Container"
        else {
            return nil
        }

        guard let labeledArguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              labeledArguments.count != 0
        else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: ContainerNameAttributeError.missingLabelWithContainerName
            )
        }

        guard labeledArguments.count == 1 else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: ContainerNameAttributeError.containerAttributeShouldOnlyHaveOneParameter
            )
        }

        let firstIndex = labeledArguments.index(at: 0)

        guard let declReference = labeledArguments[firstIndex].expression.as(DeclReferenceExprSyntax.self) else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: ContainerNameAttributeError.invalidContainerAttribute
            )
        }

        return declReference.baseName.text
    }

    guard let containerName = containerNameAttributes.first else {
        // This protocol isn't a container
        return nil
    }

    guard containerNameAttributes.count == 1 else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: ContainerNameAttributeError.multipleContainerAttributesDetected
        )
    }

    return containerName
}

enum InjectableAttributeError: Error {
    case missingLabelWithClassName
    case classNameIsMissing
    case injectableAttributeShouldOnlyHaveOneParameter
    case invalidInjectableAttribute
    case multipleInjectablesForClass(String)
}

///
/// Extracts a Injectable attribute from a Protocol definition
/// Format: @Injectable(MyInjectableClass)
///
func injectableAttributes(
    converter: SourceLocationConverter,
    item: ProtocolDeclSyntax
) throws -> [String: Injectable] {
    guard !item.attributes.isEmpty else {
        return [:]
    }

    let injectableAttributes: [Injectable] = try item.attributes.compactMap { element -> Injectable? in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self),
              identifier.name.text == "Injectable"
        else {
            return nil
        }

        guard let labeledArguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              labeledArguments.count != 0
        else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: InjectableAttributeError.missingLabelWithClassName
            )
        }

        guard labeledArguments.count == 1 else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: InjectableAttributeError.injectableAttributeShouldOnlyHaveOneParameter
            )
        }

        let firstIndex = labeledArguments.index(at: 0)

        guard let declReference = labeledArguments[firstIndex].expression.as(DeclReferenceExprSyntax.self) else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: InjectableAttributeError.invalidInjectableAttribute
            )
        }

        return Injectable(
            className: declReference.baseName.text,
            sourceLocation: attribute.startLocation(converter: converter)
        )
    }

    var result: [String: Injectable] = [:]

    for injectable in injectableAttributes {
        if let existingInjectable = result[injectable.className] {
            throw InputFileError(
                location: existingInjectable.sourceLocation,
                error: InjectableAttributeError.multipleInjectablesForClass(injectable.className)
            )
        } else {
            result[injectable.className] = injectable
        }
    }

    return result
}

enum BindingAttributeError: Error {
    case missingAttributes
    case missingBindings
    case missingLabel
    case invalidNumberOfArgumentsForBinding
    case invalidBindingAttribute
    case multipleBindingsFoundForProtocol(String)
}

///
/// Extracts Binding attributes from a Protocol definition
/// Format:
///   @Bind(MyClass, MyProtocol)
///   @Singleton(MySingleton, MyOtherProtocol)
///
func bindingAttributes(
    converter: SourceLocationConverter,
    item: ProtocolDeclSyntax
) throws -> [ProtocolName: Binding] {
    guard !item.attributes.isEmpty else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: BindingAttributeError.missingAttributes
        )
    }

    let bindings: [Binding] = try item.attributes.compactMap { element -> Binding? in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self)
        else {
            return nil
        }

        let bindingKind: Binding.Kind

        switch identifier.name.text {
        case "Bind":
            bindingKind = .build
        case "Singleton":
            bindingKind = .singleton
        default:
            return nil
        }

        guard let labeledArguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              labeledArguments.count != 0
        else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: BindingAttributeError.missingLabel
            )
        }

        guard labeledArguments.count == 2 else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: BindingAttributeError.invalidNumberOfArgumentsForBinding
            )
        }

        let classIndex = labeledArguments.index(at: 0)
        let protocolIndex = labeledArguments.index(at: 1)

        guard let classNameExpression = labeledArguments[classIndex].expression.as(DeclReferenceExprSyntax.self),
              let protocolNameExpression = labeledArguments[protocolIndex].expression.as(DeclReferenceExprSyntax.self)
        else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: BindingAttributeError.invalidBindingAttribute
            )
        }

        return Binding(
            kind: bindingKind,
            className: classNameExpression.baseName.text,
            protocolName: protocolNameExpression.baseName.text,
            sourceLocation: attribute.startLocation(converter: converter)
        )
    }

    guard !bindings.isEmpty else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: BindingAttributeError.missingBindings
        )
    }

    var result: [ProtocolName: Binding] = [:]

    for binding in bindings {
        if let existingBinding = result[binding.protocolName] {
            throw InputFileError(
                location: existingBinding.sourceLocation,
                error: BindingAttributeError.multipleBindingsFoundForProtocol(binding.protocolName)
            )
        } else {
            result[binding.protocolName] = binding
        }
    }

    return result
}

func filterContainerAttributes(
    from item: ProtocolDeclSyntax
) -> ProtocolDeclSyntax {
    item.with(
        \.attributes,
        item.attributes.filter { element in
            if let attribute = element.as(AttributeSyntax.self),
                let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self) {
                switch identifier.name.text {
                case "Container", "Bind", "Singleton", "Injectable":
                    return false
                default:
                    return true
                }
            }

            return true
        }
    )
}
