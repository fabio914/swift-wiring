import Foundation
import SwiftSyntax
import SwiftParser

struct InjectableClassDefinition: CustomStringConvertible {
    let className: String
    // TODO: Extract dependencies and parameters

    init?(
        converter: SourceLocationConverter,
        classDeclaration: ClassDeclSyntax
    ) throws {
        guard try hasInjectableClassAttribute(converter: converter, item: classDeclaration) else {
            return nil
        }

        self.className = classDeclaration.name.text
    }

    var description: String {
        "InjectableClassDefinition(\(className))"
    }
}

// MARK: - Attributes

enum InjectableClassAttributeError: Error {
    case invalidArgumentsInInjectAttribute
    case multipleInjectAttributes
}

///
/// Returns true if this is a class with an @Inject annotation
///
func hasInjectableClassAttribute(
    converter: SourceLocationConverter,
    item: ClassDeclSyntax
) throws -> Bool {
    guard !item.attributes.isEmpty else {
        return false
    }

    let injectAttribute: AttributeListSyntax = try item.attributes.filter { element in
        guard let attribute = element.as(AttributeSyntax.self),
            let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self),
              identifier.name.text == "Inject"
        else {
            return false
        }

        if let labeledArguments = attribute.arguments?.as(LabeledExprListSyntax.self),
              labeledArguments.count != 0 {
            throw InputFileError(
                location: attribute.startLocation(converter: converter),
                error: InjectableClassAttributeError.invalidArgumentsInInjectAttribute
            )
        }

        return true
    }

    if injectAttribute.count == 0 {
        return false
    }

    if injectAttribute.count > 1 {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: InjectableClassAttributeError.multipleInjectAttributes
        )
    }

    return true
}
