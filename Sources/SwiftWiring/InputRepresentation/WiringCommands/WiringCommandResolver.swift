import Foundation

typealias BindingName = String // Protocol or the Class own name
typealias ClassName = String
typealias ContainerName = String
typealias Name = String

enum AccessLevel {
    case `public`
    case `internal`
}

enum WiringCommand {
    enum BindingCommand {
        case access(AccessLevel)
        case name(Name)
    }

    enum ContainerCommand {
        case access(AccessLevel)
        case bind(ClassName, BindingName, [BindingCommand])
        case singletonBind(ClassName, BindingName, [BindingCommand])
        case instance(ClassName, [BindingCommand])
        case singleton(ClassName, [BindingCommand])
    }

    case empty
    case inject
    // case provider
    case dependency(Name?)
    case container(containerName: ContainerName, commands: [ContainerCommand])
}

enum CommandResolverError: Error {
    case multipleCommands
    case invalidNumberOfArgumentsFor(command: String, expected: ClosedRange<Int>)
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
            try verifyCommand(firstCommand, named: "dependency", withArgumentsRange: 0...1, andBody: .empty)

            return .dependency({ () -> Name? in
                guard let name = firstCommand.arguments.first, !name.isEmpty else { return nil }
                return name
            }())
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
        case "access":
            return .access(try resolveAccessCommand(rawCommand))
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
            return .access(try resolveAccessCommand(rawCommand))
        case "name":
            try verifyCommand(rawCommand, named: "name", withArguments: 1, andBody: .empty)
            return .name(rawCommand.arguments[0])
        default:
            throw CommandResolverError.unrecognizedCommand(rawCommand.name)
        }
    }

    private static func resolveAccessCommand(_ rawCommand: CommandParser.Command) throws -> AccessLevel {
        try verifyCommand(rawCommand, named: "access", withArguments: 1, andBody: .empty)
        switch rawCommand.arguments[0] {
        case "public":
            return .public
        case "internal":
            return .internal
        case "private":
            throw CommandResolverError.argumentNotSupported(rawCommand.arguments[0])
        default:
            throw CommandResolverError.invalidArgument(rawCommand.arguments[0])
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
        withArgumentsRange argumentRange: ClosedRange<Int>,
        andBody bodyType: BodyType
    ) throws {
        guard argumentRange.contains(rawCommand.arguments.count) else {
            throw CommandResolverError.invalidNumberOfArgumentsFor(command: command, expected: argumentRange)
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

    private static func verifyCommand(
        _ rawCommand: CommandParser.Command,
        named command: String,
        withArguments argumentCount: Int,
        andBody bodyType: BodyType
    ) throws {
        try verifyCommand(rawCommand, named: command, withArgumentsRange: argumentCount...argumentCount, andBody: bodyType)
    }
}

// MARK: - Helper functions to extract properties from the command body

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

    var name: Name? {
        compactMap {
            guard case let .name(string) = $0, !string.isEmpty else {
                return nil
            }

            return string
        }
        .last
    }
}

extension Array where Element == WiringCommand.ContainerCommand {
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
