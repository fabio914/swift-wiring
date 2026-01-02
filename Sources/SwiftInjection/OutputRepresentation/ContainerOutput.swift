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
            classKeyword: .keyword(.class, trailingTrivia: .space),
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
            for resolvedDependency in resolvedContainer.resolvedDependencies {
                buildFunction(for: resolvedDependency)
            }
            // TODO: Add lazy vars for the singletons
        }

        return DeclSyntax(classDeclaration)
    }

    private func buildFunctionName(for resolvedDependency: ResolvedDependency) -> String {
        "build\(resolvedDependency.definition.bindingName.CamelCased)"
    }

    private func buildFunction(for resolvedDependency: ResolvedDependency) -> DeclSyntax {
        let functionDeclaration = FunctionDeclSyntax(
            leadingTrivia: .newlines(1) + .spaces(4),
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.internal), trailingTrivia: .space) // TODO: Implement access control
            },
            funcKeyword: TokenSyntax(
                .keyword(.func),
                trailingTrivia: .space,
                presence: .present
            ),
            name: .identifier(buildFunctionName(for: resolvedDependency)),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        for parameter in resolvedDependency.injectableClass.initializerDefinition.parameters {
                            if case .parameter = parameter.kind {
                                parameter.functionParameter
                                    .with(\.leadingTrivia, .newline + .spaces(8))
                            }
                        }
                    }
                    .with(\.trailingTrivia, .newline + .spaces(4)),
                    trailingTrivia: .space
                ),
                returnClause: ReturnClauseSyntax(
                    type: IdentifierTypeSyntax(
                        leadingTrivia: .space,
                        name: .identifier(resolvedDependency.definition.bindingName)
                    ),
                    trailingTrivia: .space
                )
            ),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax {
                    CodeBlockItemSyntax(
                        leadingTrivia: .newline + .spaces(8),
                        item: .init(
                            ReturnStmtSyntax(
                                expression: FunctionCallExprSyntax(
                                    leadingTrivia: .space,
                                    calledExpression: DeclReferenceExprSyntax(
                                        baseName: .identifier(resolvedDependency.injectableClass.className)
                                    ),
                                    leftParen: .leftParenToken(),
                                    arguments: LabeledExprListSyntax { }, // TODO: Pass arguments
                                    rightParen: .rightParenToken(leadingTrivia: .newline + .spaces(8))
                                )
                            )
                        ),
                        trailingTrivia: .newline
                    )
                },
                rightBrace: .rightBraceToken(leadingTrivia: .spaces(4))
            ),
            trailingTrivia: .newlines(1)
        )

        return DeclSyntax(functionDeclaration)
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
