import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String

enum InjectableClassCollectionError: Error {
    case classWithThisNameAlreadyExists(String)
}

struct InjectableClassCollection {
    let byBinding: [BindingName: [ClassName: InjectableClassDefinition]]
    let byClassName: [ClassName: InjectableClassDefinition]

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

        var byClassName: [String: InjectableClassDefinition] = [:]

        for injectableClass in sources.flatMap(\.injectableClasses) {

            if let existingClassDefinition = byClassName[injectableClass.className] {
                throw InputFileError(
                    location: injectableClass.sourceLocation,
                    error: InjectableClassCollectionError.classWithThisNameAlreadyExists(existingClassDefinition.className)
                )
            }

            byClassName[injectableClass.className] = injectableClass
        }

        self.byBinding = byBinding
        self.byClassName = byClassName
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

struct ExternalDependency {
    let protocolName: String
}

struct InternalDependency {
    let definition: DependencyDefinition
    let injectableClass: InjectableClassDefinition
}

//enum ResolvedDependencyWithoutParameters {
//    case external(ExternalDependency)
//    case singleton(InternalDependency, _ children: [ProtocolName: ResolvedDependencyWithoutParameters])
//    case builderWithoutParameters(InternalDependency, _ children: [ProtocolName: ResolvedDependencyWithoutParameters])
//}
//
//enum ResolvedDependency {
//    case builderWithParameters(InternalDependency, _ children: [ProtocolName: ResolvedDependencyWithoutParameters])
//    case injectableBuilder(InjectableClassDefinition, _ children: [ProtocolName: ResolvedDependencyWithoutParameters])
//}

enum ResolvedContainerError: Error {
    case missingClassFor(ClassName, BindingName)
}

struct ResolvedContainer {
    let containerDefinition: ContainerDefinition
//    let resolvedDependencies: [ResolvedDependency]

    init(containerDefinition: ContainerDefinition, injectableClasses: InjectableClassCollection) throws {
        self.containerDefinition = containerDefinition

        var unresolvedInternalDependencies: [InternalDependency] = []

        for dependency in containerDefinition.dependencies {
            if let injectableClassDefinition = injectableClasses.byBinding[dependency.bindingName]?[dependency.className] {
                unresolvedInternalDependencies.append(.init(definition: dependency, injectableClass: injectableClassDefinition))
            } else {
                throw InputFileError(
                    location: containerDefinition.sourceLocation,
                    error: ResolvedContainerError.missingClassFor(dependency.className, dependency.bindingName)
                )
            }
        }

        // TODO: Resolve initializers

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

//    static func resolve(container: ContainerDefinition, injectableClasses: [ProtocolName: [InjectableClassDefinition]]) throws -> ResolvedContainer {
//        var containerDependencies: [ProtocolName: InternalDependency] = [:]
//        var injectableDependencies: [InjectableClassDefinition] = [:]
//
//        for binding in container.bindings.values.sorted(by: { $0.className < $1.className }) {
//            binding
//
//        }
//
//        for injectable in container.injectables.values.sorted(by: { $0.className < $1.className }) {
//            let definitions = injectableClasses["", default: []].filter({ $0.className == injectable.className })
//            // TODO: Search in other protocols too...
//
//            if definitions.count == 0 {
//                // TODO: Throw error missing Injectable
//            } else if definitions.count > 1 {
//                // TODO: Throw error
//            } else {
//                injectableDependencies.append(definitions[0])
//            }
//        }
//
//        // TODO: Resolution
//    }
}
