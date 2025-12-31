import Foundation
import SwiftSyntax
import SwiftParser

struct DependencyDefinition: CustomStringConvertible {
    enum Kind {
        case singleton
        case build
    }

    enum BindingType {
        case binding(_ protocolName: String)
        case instance
    }

    let kind: Kind
    let bindingType: BindingType
    let className: String
    let sourceLocation: SourceLocation

    var bindingName: BindingName {
        switch bindingType {
        case .binding(let protocolName):
            protocolName
        case .instance:
            className
        }
    }

    var description: String {
        "DependencyDefinition(\(kind), \(className), \(bindingName))"
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
    let dependencyMap: [BindingName: DependencyDefinition]

    var dependencies: [DependencyDefinition] {
        dependencyMap.sorted(by: { $0.key < $1.key }).map({ $0.value })
    }

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
        self.dependencyMap = try bindingAttributes(converter: converter, item: protocolDeclaration)
        self.protocolDeclaration = protocolDeclaration
        self.sourceLocation = protocolDeclaration.startLocation(converter: converter)
    }

    func filteredProtocolDeclaration() -> ProtocolDeclSyntax {
        filterContainerAttributes(from: protocolDeclaration)
    }

    var description: String {
        "ContainerDefinition(\(containerName), \(containerProtocolName), \(dependencies))"
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

enum BindingAttributeError: Error {
    case missingAttributes
    case missingBindings
    case missingLabel
    case invalidNumberOfArguments
    case invalidBindingAttribute
    case multipleBindingsFoundFor(String)
}

///
/// Extracts Dependency attributes from a Protocol definition
/// Format:
///   @Bind(MyClass, MyProtocol)
///   @SingletonBind(MySingleton, MyOtherProtocol)
///   @Instance(MyClass)
///   @Singleton(MyClass)
///
func bindingAttributes(
    converter: SourceLocationConverter,
    item: ProtocolDeclSyntax
) throws -> [BindingName: DependencyDefinition] {
    guard !item.attributes.isEmpty else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: BindingAttributeError.missingAttributes
        )
    }

    let definitions: [DependencyDefinition] = try item.attributes.compactMap { element -> DependencyDefinition? in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self)
        else {
            return nil
        }

        let bindingKind: DependencyDefinition.Kind
        let bindsToProtocol: Bool

        switch identifier.name.text {
        case "Bind":
            bindingKind = .build
            bindsToProtocol = true
        case "Instance":
            bindingKind = .build
            bindsToProtocol = false
        case "SingletonBind":
            bindingKind = .singleton
            bindsToProtocol = true
        case "Singleton":
            bindingKind = .singleton
            bindsToProtocol = false
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

        let expectedArguments = bindsToProtocol ? 2 : 1

        guard labeledArguments.count == expectedArguments else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: BindingAttributeError.invalidNumberOfArguments
            )
        }

        let classIndex = labeledArguments.index(at: 0)

        guard let classNameExpression = labeledArguments[classIndex].expression.as(DeclReferenceExprSyntax.self) else {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: BindingAttributeError.invalidBindingAttribute
            )
        }

        let bindingType: DependencyDefinition.BindingType

        if bindsToProtocol {
            let protocolIndex = labeledArguments.index(at: 1)

            guard let protocolNameExpression = labeledArguments[protocolIndex].expression.as(DeclReferenceExprSyntax.self) else {
                throw InputFileError(
                    location: attribute.startLocation(converter: converter),
                    error: BindingAttributeError.invalidBindingAttribute
                )
            }

            bindingType = .binding(protocolNameExpression.baseName.text)
        } else {
            bindingType = .instance
        }

        return DependencyDefinition(
            kind: bindingKind,
            bindingType: bindingType,
            className: classNameExpression.baseName.text,
            sourceLocation: attribute.startLocation(converter: converter)
        )
    }

    guard !definitions.isEmpty else {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: BindingAttributeError.missingBindings
        )
    }

    var result: [BindingName: DependencyDefinition] = [:]

    for definition in definitions {
        if let existingBinding = result[definition.bindingName] {
            throw InputFileError(
                location: existingBinding.sourceLocation,
                error: BindingAttributeError.multipleBindingsFoundFor(definition.bindingName)
            )
        } else {
            result[definition.bindingName] = definition
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
                case "Container", "Bind", "SingletonBind", "Instance", "Singleton":
                    return false
                default:
                    return true
                }
            }

            return true
        }
    )
}
