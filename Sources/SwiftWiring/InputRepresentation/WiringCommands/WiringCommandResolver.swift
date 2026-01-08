import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String
//typealias Name = String

enum AccessLevel {
    case `public`
    case `internal`
}

enum WiringCommand {
    enum BindingCommand {
        case access(AccessLevel)

        // TODO: Support named dependencies
//        case name(Name)
    }

    enum ContainerCommand {
        case bind(ClassName, BindingName, [BindingCommand])
        case singletonBind(ClassName, BindingName, [BindingCommand])
        case instance(ClassName, [BindingCommand])
        case singleton(ClassName, [BindingCommand])
    }

    case empty
    case inject
    // TODO: Implement named dependencies
    case dependency
    case container(containerName: ContainerName, commands: [ContainerCommand])
}

enum CommandResolverError: Error {
    case multipleCommands
    case invalidNumberOfArgumentsFor(command: String, expected: Int)
    case unexpectedBodyFor(command: String)
    case missingBodyFor(command: String)
    case unrecognizedCommand(String)
    case argumentNotSupported(String)
    case invalidArgument(String)
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
            return .container(
                containerName: firstCommand.arguments[0],
                commands: try containerSubCommands(firstCommand)
            )
        default:
            throw CommandResolverError.unrecognizedCommand(firstCommand.name)
        }
    }

    private static func containerSubCommands(_ rawCommand: CommandParser.Command) throws -> [WiringCommand.ContainerCommand] {
        try rawCommand.body.map { try resolveContainerCommand($0) }
    }

    private static func resolveContainerCommand(_ rawCommand: CommandParser.Command) throws -> WiringCommand.ContainerCommand {
        switch rawCommand.name {
        case "bind":
            try verifyCommand(rawCommand, named: "bind", withArguments: 2, andBody: .optional)
            return .bind(rawCommand.arguments[0], rawCommand.arguments[1], try bindingSubCommands(rawCommand))
        case "bindToSingleton":
            try verifyCommand(rawCommand, named: "bindToSingleton", withArguments: 2, andBody: .optional)
            return .bind(rawCommand.arguments[0], rawCommand.arguments[1], try bindingSubCommands(rawCommand))
        case "singletonBind":
            try verifyCommand(rawCommand, named: "singletonBind", withArguments: 2, andBody: .optional)
            return .singletonBind(rawCommand.arguments[0], rawCommand.arguments[1], try bindingSubCommands(rawCommand))
        case "instance":
            try verifyCommand(rawCommand, named: "instance", withArguments: 1, andBody: .optional)
            return .instance(rawCommand.arguments[0], try bindingSubCommands(rawCommand))
        case "singleton":
            try verifyCommand(rawCommand, named: "singleton", withArguments: 1, andBody: .optional)
            return .singleton(rawCommand.arguments[0], try bindingSubCommands(rawCommand))
        default:
            throw CommandResolverError.unrecognizedCommand(rawCommand.name)
        }
    }

    private static func bindingSubCommands(_ rawCommand: CommandParser.Command) throws -> [WiringCommand.BindingCommand] {
        try rawCommand.body.map { try resolveBindingCommand($0) }
    }

    private static func resolveBindingCommand(_ rawCommand: CommandParser.Command) throws -> WiringCommand.BindingCommand {
        switch rawCommand.name {
        case "access":
            try verifyCommand(rawCommand, named: "access", withArguments: 1, andBody: .empty)
            switch rawCommand.arguments[0] {
            case "public":
                return .access(.public)
            case "internal":
                return .access(.internal)
            case "private":
                throw CommandResolverError.argumentNotSupported(rawCommand.arguments[0])
            default:
                throw CommandResolverError.invalidArgument(rawCommand.arguments[0])
            }

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

extension Array where Element == WiringCommand.BindingCommand {

    var accessLevel: AccessLevel {
        compactMap {
            guard case let .access(level) = $0 else {
                return nil
            }

            return level
        }
        .last ?? .internal
    }
}
