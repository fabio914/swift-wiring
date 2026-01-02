import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String

enum InjectableClassCollectionError: Error {
    case classWithThisNameAlreadyExists(String)
}

struct InjectableClassCollection {
    let byBinding: [BindingName: [ClassName: InjectableClassDefinition]]

    init(sources: [SourceDefinition]) throws {
        var byBinding: [BindingName: [ClassName: InjectableClassDefinition]] = [:]

        for injectableClass in sources.flatMap(\.injectableClasses) {
            let namesToCheck: [BindingName] = injectableClass.inheritanceChain + [injectableClass.className]

            for bindingName in namesToCheck {
                var current = byBinding[bindingName, default: [:]]

                if let existingClassDefinition = current[injectableClass.className] {
                    throw InputFileError(
                        location: injectableClass.sourceLocation,
                        error: InjectableClassCollectionError.classWithThisNameAlreadyExists(existingClassDefinition.className)
                    )
                }

                current[injectableClass.className] = injectableClass
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
    let protocolName: String

    var description: String {
        "ExternalDependency(\(protocolName))"
    }
}

struct InternalDependency: CustomStringConvertible {
    let definition: DependencyDefinition
    let injectableClass: InjectableClassDefinition

    var dependencyNames: [BindingName] {
        injectableClass.initializerDefinition.dependencies.map(\.type)
    }

    var description: String {
        "InternalDependency(\(definition), \(injectableClass))"
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
    let injectableClass: InjectableClassDefinition
    let dependencies: [BindingName: DependencyType]

    var description: String {
        "ResolvedDependency(\(definition), \(injectableClass), \(dependencies))"
    }
}

enum ResolvedContainerError: Error {
    case missingClassFor(ClassName, BindingName)
    case singletonClassCannotHaveParameters(ClassName)
    case classDependsOnClassThatRequireParameters(ClassName)
    case circularDependency(ClassName, BindingName)
}

struct ResolvedContainer: CustomStringConvertible {
    let containerDefinition: ContainerDefinition

    let externalDependencies: [ExternalDependency]
    let resolvedDependencies: [ResolvedDependency]

    init(containerDefinition: ContainerDefinition, injectableClasses: InjectableClassCollection) throws {
        self.containerDefinition = containerDefinition

        // Collecting unresolved dependencies

        var unresolvedInternalDependencies: [InternalDependency] = []
        var dependencyDefinitionMap: [BindingName: InternalDependency] = [:]

        for dependency in containerDefinition.dependencies {
            if let injectableClassDefinition = injectableClasses.byBinding[dependency.bindingName]?[dependency.className] {
                let internalDependency = InternalDependency(definition: dependency, injectableClass: injectableClassDefinition)
                dependencyDefinitionMap[dependency.bindingName] = internalDependency
                unresolvedInternalDependencies.append(internalDependency)
            } else {
                throw InputFileError(
                    location: containerDefinition.sourceLocation,
                    error: ResolvedContainerError.missingClassFor(dependency.className, dependency.bindingName)
                )
            }
        }

        // Verifying dependencies and extracting external dependencies

        var externalDependencies: Set<ExternalDependency> = []
        var resolvedDependencies: [ResolvedDependency] = []

        for unresolvedInternalDependency in unresolvedInternalDependencies {
            // Singletons cannot have parameters.
            if case .singleton = unresolvedInternalDependency.definition.kind,
               unresolvedInternalDependency.injectableClass.initializerDefinition.hasParameters {
                throw InputFileError(
                    location: unresolvedInternalDependency.injectableClass.sourceLocation,
                    error: ResolvedContainerError.singletonClassCannotHaveParameters(unresolvedInternalDependency.injectableClass.className)
                )
            }

            var dependencyTypes: [BindingName: DependencyType] = [:]

            for dependencyName in unresolvedInternalDependency.dependencyNames {
                if let definition = dependencyDefinitionMap[dependencyName] {
                    // Instances and Singletons can only depend on other Instances
                    // or Singletons that take no parameters, or external dependencies.
                    // (Otherwise its `build` function would need to contain its
                    // own parameters and the dependency's parameters too, and etc)

                    if definition.injectableClass.initializerDefinition.hasParameters {
                        throw InputFileError(
                            location: unresolvedInternalDependency.injectableClass.sourceLocation,
                            error: ResolvedContainerError.classDependsOnClassThatRequireParameters(definition.injectableClass.className)
                        )
                    }

                    dependencyTypes[dependencyName] = .internal(definition)
                } else if dependencyName == containerDefinition.containerName || dependencyName == containerDefinition.containerProtocolName {
                    // Dependencies can be injected with the container itself.
                    // However, they should avoid retaining the container strongly, or else this
                    // can lead to retain cycles. Especially if this instance is a singleton within that container.
                    dependencyTypes[dependencyName] = .container(ContainerDependency(containerName: dependencyName))
                } else {
                    // Dependencies that aren't part of this container will be added to
                    // the external dependencies set and will be part of the container's
                    // `init` function.

                    let externalDependency = ExternalDependency(protocolName: dependencyName)
                    externalDependencies.insert(externalDependency)
                    dependencyTypes[dependencyName] = .external(externalDependency)
                }
            }

            resolvedDependencies.append(
                ResolvedDependency(
                    definition: unresolvedInternalDependency.definition,
                    injectableClass: unresolvedInternalDependency.injectableClass,
                    dependencies: dependencyTypes
                )
            )
        }

        // TODO: Verify cycles

        // TODO: Resolve initializers

        self.externalDependencies = externalDependencies.sorted(by: { $0.protocolName < $1.protocolName })
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
        let injectableClasses = try InjectableClassCollection(sources: sources)

        self.resolvedContainers = try containers.containers.map {
            try ResolvedContainer(containerDefinition: $0, injectableClasses: injectableClasses)
        }
    }
}
