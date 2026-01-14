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

    // MARK: - Build function

    private func makeBuildFunctionSignature(for resolvedDependency: ResolvedDependency) -> FunctionSignatureSyntax {
        FunctionSignatureSyntax(
            parameterClause: FunctionParameterClauseSyntax(
                parameters: FunctionParameterListSyntax {
                    let parameters = resolvedDependency.injectable.parameters
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
                    name: .identifier(resolvedDependency.definition.identifier.bindingName)
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
        resolvedDependency.injectable.parameters
            .compactMap { parameter in
                switch parameter.kind {
                case .dependency(let dependencyDefinition):
                    guard let dependency = resolvedDependency.dependencies[dependencyDefinition.identifier] else {
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
                                    baseName: .identifier(externalDependency.externalClosureName)
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
                                        baseName: .identifier(internalDependency.definition.buildFunctionName)
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
                                    baseName: .identifier(internalDependency.definition.singletonName)
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
                baseName: .identifier(resolvedDependency.injectable.classOrFunctionName)
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
            name: .identifier(resolvedDependency.definition.buildFunctionName),
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
                        identifier: .identifier(resolvedDependency.definition.singletonName)
                    ),
                    typeAnnotation: TypeAnnotationSyntax(
                        type: IdentifierTypeSyntax(
                            leadingTrivia: .space,
                            name: .identifier(resolvedDependency.definition.identifier.bindingName),
                            trailingTrivia: .space
                        )
                    ),
                    initializer: InitializerClauseSyntax(
                        value: FunctionCallExprSyntax(
                            leadingTrivia: .space,
                            calledExpression: DeclReferenceExprSyntax(
                                baseName: .identifier(resolvedDependency.definition.buildFunctionName)
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

    private func externalDependencyWrapper() -> DeclSyntax {
        let syntax: DeclSyntax =
        """
            public struct ExternalDependency<T> {
                let closure: () -> T
                
                init(closure: @escaping () -> T) {
                    self.closure = closure
                }
                
                public static func constant(_ value: T) -> Self {
                    .init(closure: { value })
                }
                
                public static func builder(_ closure: @escaping () -> T) -> Self {
                    .init(closure: closure)
                }
            }
        """

        return syntax
            .with(\.leadingTrivia, .newlines(2) + .spaces(4))
            .with(\.trailingTrivia, .newline)
    }

    private func typeFor(externalDependency: ExternalDependency) -> FunctionTypeSyntax {
        FunctionTypeSyntax(
            leadingTrivia: .space,
            parameters: TupleTypeElementListSyntax {},
            returnClause: ReturnClauseSyntax(
                leadingTrivia: .space,
                type: IdentifierTypeSyntax(
                    leadingTrivia: .space,
                    name: .identifier(externalDependency.identifier.bindingName)
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
                        identifier: .identifier(externalDependency.externalClosureName)
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
                                firstName: .identifier(externalDependency.initParameterName),
                                type: IdentifierTypeSyntax(
                                    leadingTrivia: .space,
                                    name: .identifier("ExternalDependency"),
                                    genericArgumentClause: GenericArgumentClauseSyntax(
                                        arguments: GenericArgumentListSyntax {
                                            GenericArgumentSyntax(
                                                argument: .init(
                                                    IdentifierTypeSyntax(
                                                        name: .identifier(externalDependency.identifier.bindingName)
                                                    )
                                                )
                                            )
                                        }
                                    )
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
                                            baseName: .identifier(externalDependency.externalClosureName)
                                        )
                                    ),
                                    operator: AssignmentExprSyntax(
                                        leadingTrivia: .space,
                                        trailingTrivia: .space
                                    ),
                                    rightOperand: MemberAccessExprSyntax(
                                        base: DeclReferenceExprSyntax(
                                            baseName: .identifier(externalDependency.initParameterName)
                                        ),
                                        declName: DeclReferenceExprSyntax(
                                            baseName: .identifier("closure")
                                        )
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
            if !resolvedContainer.externalDependencies.isEmpty {
                externalDependencyWrapper()
            }

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
