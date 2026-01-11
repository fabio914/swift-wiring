import Foundation

enum InjectableCollectionError: Error {
    case injectableWithThisNameAlreadyExists(ClassOrFunctionName)
}

struct InjectableCollection {
    let byBinding: [BindingName: [ClassOrFunctionName: Injectable]]

    init(sources: [SourceDefinition]) throws {
        var byBinding: [BindingName: [ClassOrFunctionName: Injectable]] = [:]

        for injectableClass in sources.flatMap(\.injectableClasses) {
            let namesToCheck: [BindingName] = injectableClass.inheritanceChain + [injectableClass.className]

            for bindingName in namesToCheck {
                var current = byBinding[bindingName, default: [:]]

                if let existingDefinition = current[injectableClass.className] {
                    throw InputFileError(
                        location: injectableClass.sourceLocation,
                        error: InjectableCollectionError.injectableWithThisNameAlreadyExists(existingDefinition.classOrFunctionName)
                    )
                }

                current[injectableClass.className] = .class(injectableClass)
                byBinding[bindingName] = current
            }
        }

        for injectableFunction in sources.flatMap(\.injectableFunctions) {
            // Adding the `injectableFunction.functionName` here too so we're able to find
            // injectable functions for `instance(functionName)` and `singleton(functionName)` cases
            let namesToCheck: [BindingName] = [injectableFunction.bindingName, injectableFunction.functionName]

            for bindingName in namesToCheck {
                var current = byBinding[bindingName, default: [:]]

                if let existingDefinition = current[injectableFunction.functionName] {
                    throw InputFileError(
                        location: injectableFunction.sourceLocation,
                        error: InjectableCollectionError.injectableWithThisNameAlreadyExists(existingDefinition.classOrFunctionName)
                    )
                }

                current[injectableFunction.functionName] = .function(injectableFunction)
                byBinding[bindingName] = current
            }
        }

        self.byBinding = byBinding
    }
}

enum ContainerCollectionError: Error {
    case missingContainers
    case containerWithThisNameAlreadyExists(String)
}

struct ContainerCollection {
    let containers: [ContainerDefinition]

    init(sources: [SourceDefinition]) throws {
        var containerDefinitions: [ContainerName: ContainerDefinition] = [:]

        for container in sources.flatMap(\.containers) {
            if let existingContainer = containerDefinitions[container.containerName] {
                throw InputFileError(
                    location: container.sourceLocation,
                    error: ContainerCollectionError.containerWithThisNameAlreadyExists(existingContainer.containerName)
                )
            } else {
                containerDefinitions[container.containerName] = container
            }
        }

        guard !containerDefinitions.isEmpty else {
            throw ContainerCollectionError.missingContainers
        }

        self.containers = containerDefinitions.sorted(by: { $0.key < $1.key }).map({ $0.value })
    }
}

struct ExternalDependency: Hashable, CustomStringConvertible {
    let identifier: DependencyIdentifier

    var description: String {
        "ExternalDependency(\(identifier))"
    }
}

struct InternalDependency: CustomStringConvertible {
    let definition: DependencyDefinition
    let injectable: Injectable

    var description: String {
        "InternalDependency(\(definition), \(injectable))"
    }
}

struct ContainerDependency: Hashable, CustomStringConvertible {
    let containerName: String

    var description: String {
        "ContainerDependency(\(containerName))"
    }
}

enum DependencyType: CustomStringConvertible {
    case container(ContainerDependency)
    case external(ExternalDependency)
    case `internal`(InternalDependency)

    var description: String {
        switch self {
        case .container(let containerDependency):
            containerDependency.description
        case .external(let externalDependency):
            externalDependency.description
        case .internal(let internalDependency):
            internalDependency.description
        }
    }
}

struct ResolvedDependency: CustomStringConvertible {
    let definition: DependencyDefinition
    let injectable: Injectable
    let dependencies: [DependencyIdentifier: DependencyType]

    var description: String {
        "ResolvedDependency(\(definition), \(injectable), \(dependencies))"
    }
}

enum ResolvedContainerError: Error {
    case missingInjectableFor(ClassOrFunctionName, BindingName)
    case singletonCannotHaveParameters(ClassOrFunctionName)
    case classDependsOnClassThatRequireParameters(ClassOrFunctionName)
    case dependencyCycleDetected(String)
}

struct ResolvedContainer: CustomStringConvertible {
    let containerDefinition: ContainerDefinition

    let externalDependencies: [ExternalDependency]
    let resolvedDependencies: [ResolvedDependency]

    init(containerDefinition: ContainerDefinition, injectables: InjectableCollection) throws {
        self.containerDefinition = containerDefinition

        // Collecting unresolved dependencies

        var unresolvedInternalDependencies: [InternalDependency] = []
        var dependencyDefinitionMap: [DependencyIdentifier: InternalDependency] = [:]

        for dependency in containerDefinition.dependencies {
            if let injectableDefinition = injectables.byBinding[dependency.identifier.bindingName]?[dependency.classOrFunctionName] {

                let identifier = switch injectableDefinition {
                case .class:
                    dependency.identifier
                case .function(let injectableFunction):
                    // Transforming dependency identifiers for the `instance(functionName)` and `singleton(functionName)`
                    // cases when we don't specify a separate `BindingName`.
                    // Replacing the potential function name with the binding name from the injectable function we found.
                    DependencyIdentifier(bindingName: injectableFunction.bindingName, name: dependency.identifier.name)
                }

                let internalDependency = InternalDependency(
                    definition: dependency.updating(identifier: identifier),
                    injectable: injectableDefinition
                )

                dependencyDefinitionMap[identifier] = internalDependency
                unresolvedInternalDependencies.append(internalDependency)
            } else {
                throw InputFileError(
                    location: containerDefinition.sourceLocation,
                    error: ResolvedContainerError.missingInjectableFor(dependency.classOrFunctionName, dependency.identifier.bindingName)
                )
            }
        }

        // Verifying dependencies and extracting external dependencies

        var externalDependencies: Set<ExternalDependency> = []
        var resolvedDependencies: [ResolvedDependency] = []
        let internalDependencyGraph = DependencyGraph<DependencyIdentifier>()

        for unresolvedInternalDependency in unresolvedInternalDependencies {
            // Singletons cannot have parameters.
            if case .singleton = unresolvedInternalDependency.definition.kind,
               unresolvedInternalDependency.injectable.hasParameters {
                throw InputFileError(
                    location: unresolvedInternalDependency.injectable.sourceLocation,
                    error: ResolvedContainerError.singletonCannotHaveParameters(unresolvedInternalDependency.injectable.classOrFunctionName)
                )
            }

            var dependencyTypes: [DependencyIdentifier: DependencyType] = [:]

            for dependencyIdentifier in unresolvedInternalDependency.injectable.dependencyIdentifiers {
                if let definition = dependencyDefinitionMap[dependencyIdentifier] {
                    // Instances and Singletons can only depend on other Instances
                    // or Singletons that take no parameters, or external dependencies.
                    // (Otherwise its `build` function would need to contain its
                    // own parameters and the dependency's parameters too, and etc)

                    if definition.injectable.hasParameters {
                        throw InputFileError(
                            location: unresolvedInternalDependency.injectable.sourceLocation,
                            error: ResolvedContainerError.classDependsOnClassThatRequireParameters(definition.injectable.classOrFunctionName)
                        )
                    }

                    internalDependencyGraph.add(unresolvedInternalDependency.definition.identifier, to: dependencyIdentifier)
                    dependencyTypes[dependencyIdentifier] = .internal(definition)
                } else if (dependencyIdentifier.bindingName == containerDefinition.containerName || dependencyIdentifier.bindingName == containerDefinition.containerProtocolName), dependencyIdentifier.name == nil {
                    // Dependencies can be injected with the container itself.
                    // However, they should avoid retaining the container strongly, or else this
                    // can lead to retain cycles. Especially if this instance is a singleton within that container.
                    dependencyTypes[dependencyIdentifier] = .container(ContainerDependency(containerName: dependencyIdentifier.bindingName))
                } else {
                    // Dependencies that aren't part of this container will be added to
                    // the external dependencies set and will be part of the container's
                    // `init` function.

                    let externalDependency = ExternalDependency(identifier: dependencyIdentifier)
                    externalDependencies.insert(externalDependency)
                    dependencyTypes[dependencyIdentifier] = .external(externalDependency)
                }
            }

            resolvedDependencies.append(
                ResolvedDependency(
                    definition: unresolvedInternalDependency.definition,
                    injectable: unresolvedInternalDependency.injectable,
                    dependencies: dependencyTypes
                )
            )
        }

        if case let .failure(.cycleDetected(path)) = internalDependencyGraph.verifyCycle() {
            throw InputFileError(
                location: containerDefinition.sourceLocation,
                error: ResolvedContainerError.dependencyCycleDetected(
                    path.map(\.description).joined(separator: " > ")
                )
            )
        }

        self.externalDependencies = externalDependencies.sorted(by: { $0.identifier < $1.identifier })
        self.resolvedDependencies = resolvedDependencies
    }

    var description: String {
        "ResolvedContainer(\(containerDefinition.containerName), \(externalDependencies), \(resolvedDependencies))"
    }
}

enum DependencyResolverError: Error {
    case missingInputFiles
}

struct DependencyResolver {
    let resolvedContainers: [ResolvedContainer]

    init(sources: [SourceDefinition]) throws {
        guard !sources.isEmpty else {
            throw DependencyResolverError.missingInputFiles
        }

        let containers = try ContainerCollection(sources: sources)
        let injectables = try InjectableCollection(sources: sources)

        self.resolvedContainers = try containers.containers.map {
            try ResolvedContainer(containerDefinition: $0, injectables: injectables)
        }
    }
}
