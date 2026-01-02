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
            for resolvedDependency in resolvedContainer.resolvedDependencies {
                buildFunction(for: resolvedDependency)
            }
            // TODO: Add lazy vars for the singletons
        }

        return DeclSyntax(classDeclaration)
    }

    private func buildFunctionNameFor(definition: DependencyDefinition) -> String {
        "build\(definition.bindingName.CamelCased)"
    }

    private func singletonNameFor(definition: DependencyDefinition) -> String {
        "singleton\(definition.bindingName.CamelCased)"
    }

    private func externalClosureNameFor(definition: ExternalDependency) -> String {
        "external\(definition.protocolName.CamelCased)"
    }

    private func buildFunction(for resolvedDependency: ResolvedDependency) -> DeclSyntax {
        let functionDeclaration = FunctionDeclSyntax(
            leadingTrivia: .newlines(1) + .spaces(4),
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.internal), trailingTrivia: .space) // TODO: Implement access control
            },
            funcKeyword: .keyword(.func, trailingTrivia: .space),
            name: .identifier(buildFunctionNameFor(definition: resolvedDependency.definition)),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        let parameters = resolvedDependency.injectableClass.initializerDefinition.parameters
                            .filter { if case .parameter = $0.kind { true } else { false } }

                        for i in 0 ..< parameters.count {
                            let parameter = parameters[i]
                            let isLast = (i == parameters.count - 1)

                            if case .parameter = parameter.kind {
                                parameter.functionParameter
                                    .with(\.firstName, parameter.functionParameter.firstName.with(\.trailingTrivia, .spaces(0)))
                                    .with(\.secondName, nil)
                                    .with(\.trailingComma, isLast ? nil : .commaToken())
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
                                    arguments: LabeledExprListSyntax {
                                        let parameters = resolvedDependency.injectableClass.initializerDefinition.parameters

                                        for i in 0 ..< parameters.count {
                                            let parameter = parameters[i]
                                            let isLast = (i == parameters.count - 1)

                                            switch parameter.kind {
                                            case .dependency(let dependencyDefinition):
                                                if let dependency = resolvedDependency.dependencies[dependencyDefinition.type] {
                                                    switch dependency {
                                                    case .container:
                                                        LabeledExprSyntax(
                                                            leadingTrivia: .newline + .spaces(12),
                                                            label: .identifier(dependencyDefinition.parameterName),
                                                            colon: .colonToken(trailingTrivia: .space),
                                                            expression: DeclReferenceExprSyntax(
                                                                baseName: .keyword(.self)
                                                            ),
                                                            trailingComma: isLast ? nil : .commaToken()
                                                        )
                                                    case .external(let externalDependency):
                                                        LabeledExprSyntax(
                                                            leadingTrivia: .newline + .spaces(12),
                                                            label: .identifier(dependencyDefinition.parameterName),
                                                            colon: .colonToken(trailingTrivia: .space),
                                                            expression: FunctionCallExprSyntax(
                                                                calledExpression: DeclReferenceExprSyntax(
                                                                    baseName: .identifier(externalClosureNameFor(definition: externalDependency))
                                                                ),
                                                                leftParen: .leftParenToken(),
                                                                arguments: LabeledExprListSyntax {},
                                                                rightParen: .rightParenToken()
                                                            ),
                                                            trailingComma: isLast ? nil : .commaToken()
                                                        )
                                                    case .internal(let internalDependency):
                                                        switch internalDependency.definition.kind {
                                                        case .build:
                                                            LabeledExprSyntax(
                                                                leadingTrivia: .newline + .spaces(12),
                                                                label: .identifier(dependencyDefinition.parameterName),
                                                                colon: .colonToken(trailingTrivia: .space),
                                                                expression: FunctionCallExprSyntax(
                                                                    calledExpression: DeclReferenceExprSyntax(
                                                                        baseName: .identifier(buildFunctionNameFor(definition: internalDependency.definition))
                                                                    ),
                                                                    leftParen: .leftParenToken(),
                                                                    arguments: LabeledExprListSyntax {},
                                                                    rightParen: .rightParenToken()
                                                                ),
                                                                trailingComma: isLast ? nil : .commaToken()
                                                            )
                                                        case .singleton:
                                                            LabeledExprSyntax(
                                                                leadingTrivia: .newline + .spaces(12),
                                                                label: .identifier(dependencyDefinition.parameterName),
                                                                colon: .colonToken(trailingTrivia: .space),
                                                                expression: DeclReferenceExprSyntax(
                                                                    baseName: .identifier(singletonNameFor(definition: internalDependency.definition))
                                                                ),
                                                                trailingComma: isLast ? nil : .commaToken()
                                                            )
                                                        }
                                                    }
                                                }
                                            case .parameter(let parameterName):
                                                LabeledExprSyntax(
                                                    leadingTrivia: .newline + .spaces(12),
                                                    label: .identifier(parameterName),
                                                    colon: .colonToken(trailingTrivia: .space),
                                                    expression: DeclReferenceExprSyntax(
                                                        baseName: .identifier(parameterName)
                                                    ),
                                                    trailingComma: isLast ? nil : .commaToken()
                                                )
                                            }
                                        }
                                    },
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
