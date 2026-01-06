import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String

enum WiringCommand {
    enum ContainerCommand {
        case bind(ClassName, BindingName)
        case singletonBind(ClassName, BindingName)
        case instance(ClassName)
        case singleton(ClassName)
    }

    case empty
    case inject
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
            try verifyBodylessCommand(firstCommand, named: "inject", withArguments: 0)
            return .inject
        case "dependency":
            try verifyBodylessCommand(firstCommand, named: "dependency", withArguments: 0)
            return .dependency
        case "container":
            try verifyBodyCommand(firstCommand, named: "container", withArguments: 1)
            let subCommands = try firstCommand.body.map { try resolveContainerCommand($0) }
            return .container(containerName: firstCommand.arguments[0], commands: subCommands)
        default:
            throw CommandResolverError.unrecognizedCommand(firstCommand.name)
        }
    }

    private static func resolveContainerCommand(_ rawCommand: CommandParser.Command) throws -> WiringCommand.ContainerCommand {
        switch rawCommand.name {
        case "bind":
            try verifyBodylessCommand(rawCommand, named: "bind", withArguments: 2)
            return .bind(rawCommand.arguments[0], rawCommand.arguments[1])
        case "singletonBind":
            try verifyBodylessCommand(rawCommand, named: "singletonBind", withArguments: 2)
            return .singletonBind(rawCommand.arguments[0], rawCommand.arguments[1])
        case "instance":
            try verifyBodylessCommand(rawCommand, named: "instance", withArguments: 1)
            return .instance(rawCommand.arguments[0])
        case "singleton":
            try verifyBodylessCommand(rawCommand, named: "singleton", withArguments: 1)
            return .singleton(rawCommand.arguments[0])
        default:
            throw CommandResolverError.unrecognizedCommand(rawCommand.name)
        }
    }

    private static func verifyBodylessCommand(
        _ rawCommand: CommandParser.Command,
        named command: String,
        withArguments countOfArguments: Int
    ) throws {
        guard rawCommand.arguments.count == countOfArguments else {
            throw CommandResolverError.invalidNumberOfArgumentsFor(command: command, expected: countOfArguments)
        }

        guard rawCommand.body.isEmpty else {
            throw CommandResolverError.unexpectedBodyFor(command: command)
        }
    }

    private static func verifyBodyCommand(
        _ rawCommand: CommandParser.Command,
        named command: String,
        withArguments countOfArguments: Int
    ) throws {
        guard rawCommand.arguments.count == countOfArguments else {
            throw CommandResolverError.invalidNumberOfArgumentsFor(command: command, expected: countOfArguments)
        }

        guard !rawCommand.body.isEmpty else {
            throw CommandResolverError.missingBodyFor(command: command)
        }
    }
}
