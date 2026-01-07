import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String

enum WiringCommand {
    enum ContainerCommand {
        // TODO: Add optional body to these commands, and add option to set the access control type.
        case bind(ClassName, BindingName)
        case singletonBind(ClassName, BindingName)
        case instance(ClassName)
        case singleton(ClassName)
        // TODO: Support named dependencies: namedBind(ClassName, BindingName, Name), namedSingletonBind(ClassName, BindingName, Name)
    }

    case empty
    case inject
    // TODO: Implement named dependencies: namedDependency(Name)
    case dependency
    case container(containerName: ContainerName, commands: [ContainerCommand])
}

enum CommandResolverError: Error {
    case multipleCommands
    case invalidNumberOfArgumentsFor(command: String, expected: Int)
    case unexpectedBodyFor(command: String)
    case missingBodyFor(command: String)
    case unrecognizedCommand(String)
}

final class WiringCommandResolver {

    static func resolve(_ string: String) throws -> WiringCommand {
        let rawCommand = try CommandParser.parse(string, tag: "wiring:")

        if rawCommand.isEmpty {
            return .empty
        }

        if rawCommand.count > 1 {
            throw CommandResolverError.multipleCommands
        }

        let firstCommand = rawCommand[0].command

        switch firstCommand.name {
        case "inject":
            try verifyCommand(firstCommand, named: "inject", withArguments: 0, andBody: .empty)
            return .inject
        case "dependency":
            try verifyCommand(firstCommand, named: "dependency", withArguments: 0, andBody: .empty)
            return .dependency
        case "container":
            try verifyCommand(firstCommand, named: "container", withArguments: 1, andBody: .required)
            let subCommands = try firstCommand.body.map { try resolveContainerCommand($0) }
            return .container(containerName: firstCommand.arguments[0], commands: subCommands)
        default:
            throw CommandResolverError.unrecognizedCommand(firstCommand.name)
        }
    }

    private static func resolveContainerCommand(_ rawCommand: CommandParser.Command) throws -> WiringCommand.ContainerCommand {
        switch rawCommand.name {
        case "bind":
            try verifyCommand(rawCommand, named: "bind", withArguments: 2, andBody: .empty)
            return .bind(rawCommand.arguments[0], rawCommand.arguments[1])
        case "singletonBind":
            try verifyCommand(rawCommand, named: "singletonBind", withArguments: 2, andBody: .empty)
            return .singletonBind(rawCommand.arguments[0], rawCommand.arguments[1])
        case "instance":
            try verifyCommand(rawCommand, named: "instance", withArguments: 1, andBody: .empty)
            return .instance(rawCommand.arguments[0])
        case "singleton":
            try verifyCommand(rawCommand, named: "singleton", withArguments: 1, andBody: .empty)
            return .singleton(rawCommand.arguments[0])
        default:
            throw CommandResolverError.unrecognizedCommand(rawCommand.name)
        }
    }

    enum BodyType {
        case empty
        case required
        case optional
    }

    private static func verifyCommand(
        _ rawCommand: CommandParser.Command,
        named command: String,
        withArguments countOfArguments: Int,
        andBody bodyType: BodyType
    ) throws {
        guard rawCommand.arguments.count == countOfArguments else {
            throw CommandResolverError.invalidNumberOfArgumentsFor(command: command, expected: countOfArguments)
        }

        switch bodyType {
        case .empty:
            guard rawCommand.body.isEmpty else {
                throw CommandResolverError.unexpectedBodyFor(command: command)
            }
        case .required:
            guard !rawCommand.body.isEmpty else {
                throw CommandResolverError.missingBodyFor(command: command)
            }
        case .optional:
            break
        }
    }
}
