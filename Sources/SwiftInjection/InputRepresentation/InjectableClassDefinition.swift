import Foundation
import SwiftSyntax
import SwiftParser

enum InjectableClassDefinitionError: Error {
    case missingInitializer
    case multipleInitializersDetected
    case classWithGenericsNotSupported
    case unsupportedInheritance
}

struct InjectableClassDefinition: CustomStringConvertible {
    let className: String
    let inheritanceChain: [String]
    let initializerDefinition: InitializerDefinition
    let classDeclaration: ClassDeclSyntax

    init?(
        converter: SourceLocationConverter,
        classDeclaration: ClassDeclSyntax
    ) throws {
        guard try hasInjectableClassAttribute(converter: converter, item: classDeclaration) else {
            return nil
        }

        if let genericParameterClause = classDeclaration.genericParameterClause {
            throw InputFileError(
                location: genericParameterClause.startLocation(converter: converter),
                error: InjectableClassDefinitionError.classWithGenericsNotSupported
            )
        }

        if let genericWhereClause = classDeclaration.genericWhereClause {
            throw InputFileError(
                location: genericWhereClause.startLocation(converter: converter),
                error: InjectableClassDefinitionError.classWithGenericsNotSupported
            )
        }

        self.className = classDeclaration.name.text

        self.inheritanceChain = try classDeclaration.inheritanceClause?.inheritedTypes.map { item in
            guard let identifier = item.type.as(IdentifierTypeSyntax.self) else {
                throw InputFileError(
                    location: item.startLocation(converter: converter),
                    error: InjectableClassDefinitionError.unsupportedInheritance
                )
            }

            if let genericArgumentClause = identifier.genericArgumentClause {
                throw InputFileError(
                    location: genericArgumentClause.startLocation(converter: converter),
                    error: InjectableClassDefinitionError.classWithGenericsNotSupported
                )
            }

            return identifier.name.text
        } ?? []

        self.classDeclaration = classDeclaration

        let initializers = classDeclaration.memberBlock.members.compactMap {
            item in item.decl.as(InitializerDeclSyntax.self)
        }

        // Only one initializer supported for now

        if initializers.count == 0 {
            throw InputFileError(
                location: classDeclaration.startLocation(converter: converter),
                error: InjectableClassDefinitionError.missingInitializer
            )
        } else if initializers.count > 1 {
            throw InputFileError(
                location: classDeclaration.startLocation(converter: converter),
                error: InjectableClassDefinitionError.multipleInitializersDetected
            )
        }

        self.initializerDefinition = try InitializerDefinition(converter: converter, initializerDeclaration: initializers[0])
    }

    func filteredClassDeclaration() -> ClassDeclSyntax {
        let filteredInitializerDeclaration = initializerDefinition.filteredInitializerDeclaration()

        return filterInjectableAttributes(from: classDeclaration)
            .with(
                \.memberBlock.members,
                .init(
                    classDeclaration.memberBlock.members.map { item in
                        if item.decl.is(InitializerDeclSyntax.self) {
                            var newItem = item
                            newItem.decl = .init(fromProtocol: filteredInitializerDeclaration)
                            return newItem
                        } else {
                            return item
                        }
                    }
                )
            )
    }

    var description: String {
        "InjectableClassDefinition(\(className), \(inheritanceChain), \(initializerDefinition))"
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

func filterInjectableAttributes(
    from item: ClassDeclSyntax
) -> ClassDeclSyntax {
    item.with(
        \.attributes,
        item.attributes.filter { element in
            if let attribute = element.as(AttributeSyntax.self),
                let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self),
                identifier.name.text == "Inject" {
                return false
            }

            return true
        }
    )
}
