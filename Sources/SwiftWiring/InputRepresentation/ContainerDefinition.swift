import Foundation
import SwiftSyntax
import SwiftParser

struct DependencyDefinition: CustomStringConvertible {
    enum Kind {
        case singleton
        case build
    }

    enum BindingType {
        case binding(_ protocolName: String)
        case instance
    }

    let kind: Kind
    let bindingType: BindingType
    let className: String
    let sourceLocation: SourceLocation
    let accessLevel: AccessLevel

    var bindingName: BindingName {
        switch bindingType {
        case .binding(let protocolName):
            protocolName
        case .instance:
            className
        }
    }

    var description: String {
        "DependencyDefinition(\(kind), \(className), \(bindingName))"
    }

    init?(
        sourceLocation: SourceLocation,
        command: WiringCommand.ContainerCommand
    ) {
        self.sourceLocation = sourceLocation

        switch command {
        case let .bind(className, bindingName, subCommands):
            self.kind = .build
            self.bindingType = .binding(bindingName)
            self.className = className
            self.accessLevel = subCommands.accessLevel
        case let .singletonBind(className, bindingName, subCommands):
            self.kind = .singleton
            self.bindingType = .binding(bindingName)
            self.className = className
            self.accessLevel = subCommands.accessLevel
        case let .instance(className, subCommands):
            self.kind = .build
            self.bindingType = .instance
            self.className = className
            self.accessLevel = subCommands.accessLevel
        case let .singleton(className, subCommands):
            self.kind = .singleton
            self.bindingType = .instance
            self.className = className
            self.accessLevel = subCommands.accessLevel
        default:
            return nil
        }
    }
}

///
/// Container Definition
/// A container can hold instances (singletons), build instances, and inject instances.
/// This container definition is a protocol with extra attributes defining the Container name,
/// its bindings and singletons.
///
struct ContainerDefinition: CustomStringConvertible {
    let containerName: String
    let containerProtocolName: String
    let dependencyMap: [BindingName: DependencyDefinition]

    var dependencies: [DependencyDefinition] {
        dependencyMap.sorted(by: { $0.key < $1.key }).map({ $0.value })
    }

    let imports: [ImportDeclSyntax]
    let protocolDeclaration: ProtocolDeclSyntax
    let sourceLocation: SourceLocation
    let accessLevel: AccessLevel

    init?(
        converter: SourceLocationConverter,
        imports: [ImportDeclSyntax],
        protocolDeclaration: ProtocolDeclSyntax
    ) throws {
        guard let (containerName, commands) = try containerCommand(converter: converter, item: protocolDeclaration) else {
            return nil
        }

        self.containerName = containerName
        self.containerProtocolName = protocolDeclaration.name.text
        self.dependencyMap = try bindings(sourceLocation: protocolDeclaration.startLocation(converter: converter), commands: commands)
        self.imports = imports
        self.protocolDeclaration = protocolDeclaration
        self.sourceLocation = protocolDeclaration.startLocation(converter: converter)
        self.accessLevel = commands.accessLevel
    }

    var description: String {
        "ContainerDefinition(\(containerName), \(containerProtocolName), \(dependencies))"
    }
}

enum ContainerCommandError: Error {
    case expectedContainerCommand
}

///
/// Extracts `wiring: container(...) { ... }` command
///
private func containerCommand(
    converter: SourceLocationConverter,
    item: ProtocolDeclSyntax
) throws -> (ContainerName, [WiringCommand.ContainerCommand])? {
    do {
        let wiringCommand = try item.leadingTrivia.wiringCommand()

        switch wiringCommand {
        case .container(let containerName, let commands):
            return (containerName, commands)
        case .empty:
            return nil
        default:
            throw ContainerCommandError.expectedContainerCommand
        }
    } catch {
        throw InputFileError(
            location: item.startLocation(converter: converter),
            error: error
        )
    }
}

enum BindingError: Error {
    case missingBindings
    case multipleBindingsFoundFor(String)
}

private func bindings(
    sourceLocation: SourceLocation,
    commands: [WiringCommand.ContainerCommand]
) throws -> [BindingName: DependencyDefinition] {
    let definitions = commands.compactMap { command in
        DependencyDefinition(sourceLocation: sourceLocation, command: command)
    }

    guard !definitions.isEmpty else {
        throw InputFileError(
            location: sourceLocation,
            error: BindingError.missingBindings
        )
    }

    var result: [BindingName: DependencyDefinition] = [:]

    for definition in definitions {
        if let existingBinding = result[definition.bindingName] {
            throw InputFileError(
                location: existingBinding.sourceLocation,
                error: BindingError.multipleBindingsFoundFor(definition.bindingName)
            )
        } else {
            result[definition.bindingName] = definition
        }
    }

    return result
}
