import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

final class ContainerOutput {
    let resolvedContainer: ResolvedContainer

    init(resolvedContainer: ResolvedContainer) {
        self.resolvedContainer = resolvedContainer
    }

    // MARK: - Imports

    private func imports() -> [CodeBlockItemSyntax] {
        resolvedContainer.containerDefinition.imports.compactMap {
            CodeBlockItemSyntax(
                item: .init($0)
            )
        }
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

    // MARK: - Build function

    private func makeBuildFunctionSignature(for resolvedDependency: ResolvedDependency) -> FunctionSignatureSyntax {
        FunctionSignatureSyntax(
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
        )
    }

    struct InitializerArgument {
        let label: String
        let expression: ExprSyntaxProtocol
    }

    private func makeInitializerArguments(for resolvedDependency: ResolvedDependency) -> [InitializerArgument] {
        resolvedDependency.injectableClass.initializerDefinition.parameters
            .compactMap { parameter in
                switch parameter.kind {
                case .dependency(let dependencyDefinition):
                    guard let dependency = resolvedDependency.dependencies[dependencyDefinition.type] else {
                        // If we resolved this correctly, then this should never happen
                        return nil
                    }

                    let expression: ExprSyntaxProtocol = switch dependency {
                    case .container:
                        DeclReferenceExprSyntax(
                            baseName: .keyword(.self)
                        )
                    case .external(let externalDependency):
                        FunctionCallExprSyntax(
                            calledExpression: MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: .keyword(.self)
                                ),
                                declName: DeclReferenceExprSyntax(
                                    baseName: .identifier(externalClosureNameFor(definition: externalDependency))
                                )
                            ),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax {},
                            rightParen: .rightParenToken()
                        )
                    case .internal(let internalDependency):
                        switch internalDependency.definition.kind {
                        case .build:
                            FunctionCallExprSyntax(
                                calledExpression: MemberAccessExprSyntax(
                                    base: DeclReferenceExprSyntax(
                                        baseName: .keyword(.self)
                                    ),
                                    declName: DeclReferenceExprSyntax(
                                        baseName: .identifier(buildFunctionNameFor(definition: internalDependency.definition))
                                    )
                                ),
                                leftParen: .leftParenToken(),
                                arguments: LabeledExprListSyntax {},
                                rightParen: .rightParenToken()
                            )
                        case .singleton:
                            MemberAccessExprSyntax(
                                base: DeclReferenceExprSyntax(
                                    baseName: .keyword(.self)
                                ),
                                declName: DeclReferenceExprSyntax(
                                    baseName: .identifier(singletonNameFor(definition: internalDependency.definition))
                                )
                            )
                        }
                    }

                    return InitializerArgument(
                        label: dependencyDefinition.parameterName,
                        expression: expression
                    )
                case .parameter(let parameterName):
                    return InitializerArgument(
                        label: parameterName,
                        expression: DeclReferenceExprSyntax(
                            baseName: .identifier(parameterName)
                        )
                    )
                }
            }
    }

    private func makeInitializerCallExpression(for resolvedDependency: ResolvedDependency) -> FunctionCallExprSyntax {
        FunctionCallExprSyntax(
            leadingTrivia: .space,
            calledExpression: DeclReferenceExprSyntax(
                baseName: .identifier(resolvedDependency.injectableClass.className)
            ),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax {
                for argument in makeInitializerArguments(for: resolvedDependency) {
                    LabeledExprSyntax(
                        leadingTrivia: .newline + .spaces(12),
                        label: .identifier(argument.label),
                        colon: .colonToken(trailingTrivia: .space),
                        expression: argument.expression
                    )
                }
            },
            rightParen: .rightParenToken(leadingTrivia: .newline + .spaces(8))
        )
    }

    private func buildFunction(for resolvedDependency: ResolvedDependency) -> DeclSyntax {
        let functionDeclaration = FunctionDeclSyntax(
            leadingTrivia: .newline + .spaces(4),
            modifiers: DeclModifierListSyntax {
                switch resolvedDependency.definition.kind {
                case .singleton:
                    // Singleton's build functions are always private
                    DeclModifierSyntax(name: .keyword(.private), trailingTrivia: .space)
                case .build:
                    switch resolvedDependency.definition.accessLevel {
                    case .internal:
                        DeclModifierSyntax(name: .keyword(.internal), trailingTrivia: .space)
                    case .public:
                        DeclModifierSyntax(name: .keyword(.public), trailingTrivia: .space)
                    }
                }
            },
            funcKeyword: .keyword(.func, trailingTrivia: .space),
            name: .identifier(buildFunctionNameFor(definition: resolvedDependency.definition)),
            signature: makeBuildFunctionSignature(for: resolvedDependency),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax {
                    CodeBlockItemSyntax(
                        leadingTrivia: .newline + .spaces(8),
                        item: .init(
                            ReturnStmtSyntax(
                                expression: makeInitializerCallExpression(for: resolvedDependency)
                            )
                        ),
                        trailingTrivia: .newline
                    )
                },
                rightBrace: .rightBraceToken(leadingTrivia: .spaces(4))
            ),
            trailingTrivia: .newline
        )

        return DeclSyntax(functionDeclaration)
    }

    // MARK: - Singletons

    private func singletonLazyVar(for resolvedDependency: ResolvedDependency) -> DeclSyntax? {
        guard case .singleton = resolvedDependency.definition.kind else {
            return nil
        }

        let variableDeclaration = VariableDeclSyntax(
            leadingTrivia: .newline + .spaces(4),
            modifiers: DeclModifierListSyntax {
                if case .public = resolvedDependency.definition.accessLevel {
                    DeclModifierSyntax(name: .keyword(.public), trailingTrivia: .space)
                }
                DeclModifierSyntax(
                    name: .keyword(.private),
                    detail: DeclModifierDetailSyntax(detail: .keyword(.set)),
                    trailingTrivia: .space
                )
                DeclModifierSyntax(
                    name: .keyword(.lazy),
                    trailingTrivia: .space
                )
            },
            bindingSpecifier: .keyword(.var, trailingTrivia: .space),
            bindings: PatternBindingListSyntax {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: .identifier(singletonNameFor(definition: resolvedDependency.definition))
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(
                            leadingTrivia: .space,
                            name: .identifier(resolvedDependency.definition.bindingName),
                            trailingTrivia: .space
                        )
                    ),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            leadingTrivia: .space,
                            calledExpression: DeclReferenceExprSyntax(
                                baseName: .identifier(buildFunctionNameFor(definition: resolvedDependency.definition))
                            ),
                            leftParen: .leftParenToken(),
                            arguments: LabeledExprListSyntax {},
                            rightParen: .rightParenToken()
                        )
                    )
                )
            },
            trailingTrivia: .newline
        )

        return DeclSyntax(variableDeclaration)
    }

    // MARK: - External Dependencies

    private func typeFor(externalDependency: ExternalDependency) -> FunctionTypeSyntax {
        FunctionTypeSyntax(
            leadingTrivia: .space,
            parameters: TupleTypeElementListSyntax {},
            returnClause: ReturnClauseSyntax(
                leadingTrivia: .space,
                type: IdentifierTypeSyntax(
                    leadingTrivia: .space,
                    name: .identifier(externalDependency.protocolName)
                )
            )
        )
    }

    private func externalDependencyLet(for externalDependency: ExternalDependency) -> DeclSyntax {
        let variableDeclaration = VariableDeclSyntax(
            leadingTrivia: .newline + .spaces(4),
            bindingSpecifier: .keyword(.let, trailingTrivia: .space),
            bindings: PatternBindingListSyntax {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(
                        identifier: .identifier(externalClosureNameFor(definition: externalDependency))
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: typeFor(externalDependency: externalDependency)
                    )
                )
            },
            trailingTrivia: .newline
        )

        return DeclSyntax(variableDeclaration)
    }

    // MARK: - Initializer

    private func parameterNameFor(externalDependency: ExternalDependency) -> String {
        externalDependency.protocolName.camelCased
    }

    private func initializer(with externalDependencies: [ExternalDependency]) -> DeclSyntax {
        let initializerDeclaration = InitializerDeclSyntax(
            leadingTrivia: .newline + .spaces(4),
            modifiers: DeclModifierListSyntax {
                DeclModifierSyntax(
                    name: .keyword(.public),
                    trailingTrivia: .space
                )
            },
            initKeyword: .keyword(.`init`),
            signature: FunctionSignatureSyntax(
                parameterClause: FunctionParameterClauseSyntax(
                    parameters: FunctionParameterListSyntax {
                        for externalDependency in externalDependencies {
                            FunctionParameterSyntax(
                                leadingTrivia: .newline + .spaces(8),
                                firstName: .identifier(parameterNameFor(externalDependency: externalDependency)),
                                type: AttributedTypeSyntax(
                                    specifiers: TypeSpecifierListSyntax {},
                                    attributes: AttributeListSyntax {
                                        AttributeSyntax(
                                            leadingTrivia: .space,
                                            attributeName: IdentifierTypeSyntax(name: .identifier("autoclosure"))
                                        )
                                        AttributeSyntax(
                                            leadingTrivia: .space,
                                            attributeName: IdentifierTypeSyntax(name: .identifier("escaping"))
                                        )
                                    },
                                    baseType: typeFor(externalDependency: externalDependency)
                                )
                            )
                        }
                    }
                    .with(\.trailingTrivia, .newline + .spaces(4)),
                    trailingTrivia: .space
                )
            ),
            body: CodeBlockSyntax(
                statements: CodeBlockItemListSyntax {
                    for externalDependency in externalDependencies {
                        CodeBlockItemSyntax(
                            item: .init(
                                InfixOperatorExprSyntax(
                                    leadingTrivia: .newline + .spaces(8),
                                    leftOperand: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: .keyword(.self)
                                        ),
                                        declName: DeclReferenceExprSyntax(
                                            baseName: .identifier(externalClosureNameFor(definition: externalDependency))
                                        )
                                    ),
                                    operator: AssignmentExprSyntax(
                                        leadingTrivia: .space,
                                        trailingTrivia: .space
                                    ),
                                    rightOperand: DeclReferenceExprSyntax(
                                        baseName: .identifier(parameterNameFor(externalDependency: externalDependency))
                                    )
                                )
                            )
                        )
                    }
                }
                .with(\.trailingTrivia, .newline + .spaces(4))
            ),
            trailingTrivia: .newline
        )

        return DeclSyntax(initializerDeclaration)
    }

    // MARK: - Container Class

    private func containerClass() -> DeclSyntax {
        let classDeclaration = ClassDeclSyntax(
            modifiers: DeclModifierListSyntax {
                switch resolvedContainer.containerDefinition.accessLevel {
                case .internal:
                    DeclModifierSyntax(name: .keyword(.internal), trailingTrivia: .space)
                case .public:
                    DeclModifierSyntax(name: .keyword(.public), trailingTrivia: .space)
                }
                DeclModifierSyntax(name: .keyword(.final), trailingTrivia: .space)
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
            for externalDependency in resolvedContainer.externalDependencies {
                externalDependencyLet(for: externalDependency)
            }

            for resolvedDependency in resolvedContainer.resolvedDependencies {
                if let lazyVar = singletonLazyVar(for: resolvedDependency) {
                    lazyVar
                }
            }

            initializer(with: resolvedContainer.externalDependencies)

            for resolvedDependency in resolvedContainer.resolvedDependencies {
                buildFunction(for: resolvedDependency)
            }
        }

        return DeclSyntax(classDeclaration)
    }

    private func classes() -> [CodeBlockItemSyntax] {
        [
            CodeBlockItemSyntax(
                leadingTrivia: .newlines(2),
                item: .init(containerClass()),
                trailingTrivia: .newline
            )
        ]
    }

    func generateSource() -> SourceFileSyntax {
        SourceFileSyntax(
            statements: CodeBlockItemListSyntax(imports() + classes())
        )
    }
}
