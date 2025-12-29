import Foundation

enum DependencyResolverError: Error {
    case missingInputFiles
    case missingContainers
    case containerWithThisNameAlreadyExists(String)
    case classWithThisNameAlreadyExists(String)
}

struct ExternalDependency {
    let protocolName: String
}

struct InternalDependency {
    let binding: Binding
    let injectableClass: InjectableClassDefinition
}

typealias ProtocolName = String

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

struct ResolvedContainer {
    let containerDefinition: ContainerDefinition
//    let resolvedDependencies: [ResolvedDependency]
}

struct DependencyResolver {
    let resolvedContainers: [ResolvedContainer]

    init(sources: [SourceDefinition]) throws {
        guard !sources.isEmpty else {
            throw DependencyResolverError.missingInputFiles
        }

        let containers = try Self.collectContainers(from: sources)
        let injectableClasses = try Self.collectInjectableClasses(from: sources)

        // TODO: Implement resolution
        self.resolvedContainers = []
    }

    static func collectContainers(from sources: [SourceDefinition]) throws -> [String: ContainerDefinition] {
        var containerDefinitions: [String: ContainerDefinition] = [:]

        for container in sources.flatMap(\.containers) {
            if let existingContainer = containerDefinitions[container.containerName] {
                throw InputFileError(
                    location: container.sourceLocation,
                    error: DependencyResolverError.containerWithThisNameAlreadyExists(existingContainer.containerName)
                )
            } else {
                containerDefinitions[container.containerName] = container
            }
        }

        guard !containerDefinitions.isEmpty else {
            throw DependencyResolverError.missingContainers
        }

        return containerDefinitions
    }

    static func collectInjectableClasses(from sources: [SourceDefinition]) throws -> [ProtocolName: [InjectableClassDefinition]] {
        var injectableClassDefinitions: [ProtocolName: [InjectableClassDefinition]] = [:]

        for injectableClass in sources.flatMap(\.injectableClasses) {
            if injectableClass.inheritanceChain.isEmpty {
                injectableClassDefinitions[""] = injectableClassDefinitions["", default: []] + [injectableClass]
            } else {
                for protocolName in injectableClass.inheritanceChain {
                    injectableClassDefinitions[protocolName] = injectableClassDefinitions[protocolName, default: []] + [injectableClass]
                }
            }
        }

        return injectableClassDefinitions
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
