import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

final class ContainerOutput {
    let resolvedContainer: ResolvedContainer

    init(resolvedContainer: ResolvedContainer) {
        self.resolvedContainer = resolvedContainer
    }

    private func imports() -> [CodeBlockItemSyntax] {
        resolvedContainer.containerDefinition.imports.compactMap {
            CodeBlockItemSyntax(
                item: .init($0)
            )
        }
    }

    private func containerClass() -> DeclSyntax {
        let classDeclaration = ClassDeclSyntax(
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.internal), trailingTrivia: .space) // TODO: Implement access control
            },
            classKeyword: TokenSyntax(
                .keyword(.class),
                trailingTrivia: .space,
                presence: .present
            ),
            name: .identifier(resolvedContainer.containerDefinition.containerName),
            inheritanceClause: InheritanceClauseSyntax {
                InheritedTypeSyntax(
                    leadingTrivia: .space,
                    type: TypeSyntax(stringLiteral: resolvedContainer.containerDefinition.containerProtocolName),
                    trailingTrivia: .space
                )
            }
        ) {
            // TODO: Add initializer
            // TODO: Add builder functions
            // TODO: Add lazy vars for the singletons
        }

        return DeclSyntax(classDeclaration)
    }

    private func classes() -> [CodeBlockItemSyntax] {
        [
            CodeBlockItemSyntax(
                leadingTrivia: .newlines(2),
                item: .init(containerClass()),
                trailingTrivia: .newlines(1)
            )
        ]
    }

    func generateSource() -> SourceFileSyntax {
        SourceFileSyntax(
            statements: CodeBlockItemListSyntax(imports() + classes())
        )
    }
}
