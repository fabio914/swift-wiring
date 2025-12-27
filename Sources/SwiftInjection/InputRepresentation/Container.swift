import Foundation
import SwiftSyntax
import SwiftParser

enum ContainerDefinitionError: Error {

}

struct Binding {
    let className: String
    let protocolName: String
}

struct ContainerDefinition {
    let containerName: String
//    let containerProtocolName: String
//    let binds: [Binding]
//    let singletons: [Binding]

    init?(
        converter: SourceLocationConverter,
        protocolDeclaration: ProtocolDeclSyntax
    ) throws {
        guard let containerName = try containerNameAttribute(converter: converter, item: protocolDeclaration) else {
            return nil
        }

        self.containerName = containerName
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
