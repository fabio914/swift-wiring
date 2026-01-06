import Foundation

enum CommandParserError: Error {
    case characterMismatch(expected: Character, found: Character, position: Int)
    case identifierExpected(description: String, position: Int)
}

final class CommandParser {
    typealias Tag = String
    typealias Identifier = String

    struct TaggedCommand {
        let tag: Tag
        let command: Command
    }

    struct Command {
        let name: Identifier
        let arguments: [Identifier]
        let body: [Command]
    }

    private let string: [Character]
    private var position: Int = 0
    private let length: Int
    private let tag: Tag

    private let whitespace: CharacterSet = .whitespacesAndNewlines
    private let newline: CharacterSet = .newlines

    // FIXME: Identifiers in Swift also support other Unicode characters
    private let identifierHead: CharacterSet = .underscore.union(.letters)
    private let identifierCharacter: CharacterSet = .underscore.union(.letters).union(.decimalDigits)

    static func parse(_ string: String, tag: Tag) throws -> [TaggedCommand] {
        try CommandParser(string: string, tag: tag).parse()
    }

    private init(string: String, tag: Tag) {
        self.string = Array(string)
        self.length = string.count
        self.tag = tag
    }

    private func parse() throws -> [TaggedCommand] {
        position = 0
        return try parseChildren()
    }

    private func char(offset: Int) -> Character {
        let index = position + offset
        guard index >= 0, index < length else {
            return "\0"
        }
        return string[index]
    }

    private var lookupChar: Character { char(offset: 0) }
    private var previousLookupChar: Character { char(offset: -1) }
    private var nextLookupChar: Character { char(offset: 1) }

    @discardableResult
    func nextChar() -> Character {
        let char = lookupChar
        position += 1
        return char
    }

    private func isEnd(_ character: Character) -> Bool {
        character == "\0"
    }

    private func isNewline(_ character: Character) -> Bool {
        newline.containsCharacter(character)
    }

    private func isWhite(_ character: Character) -> Bool {
        whitespace.containsCharacter(character)
    }

    private func isIdentifierHead(_ character: Character) -> Bool {
        identifierHead.containsCharacter(character)
    }

    private func isIdentifierCharacter(_ character: Character) -> Bool {
        identifierCharacter.containsCharacter(character)
    }

    private func skipWhite() {
        while isWhite(lookupChar) {
            nextChar()
        }
        skipLineComment()
    }

    private func skipLineComment() {
        if lookupChar == "/", nextLookupChar == "/" {
            nextChar()
            nextChar()

            while !isNewline(lookupChar), !isEnd(lookupChar) {
                nextChar()
            }

            skipWhite()
        }
    }

    private func match(_ character: Character) throws {
        guard character == lookupChar else {
            throw CommandParserError.characterMismatch(expected: character, found: lookupChar, position: position)
        }
        nextChar()
    }

    private func skipWhiteAndMatch(_ character: Character) throws {
        skipWhite()
        try match(character)
        skipWhite()
    }

    private func parseIdentifier(_ description: String) throws -> String {
        var identifier = [Character]()

        guard isIdentifierHead(lookupChar) else {
            throw CommandParserError.identifierExpected(description: description, position: position)
        }

        identifier.append(nextChar())

        while isIdentifierCharacter(lookupChar) {
            identifier.append(nextChar())
        }

        skipWhite()

        return String(identifier)
    }

    private func skipUntilTag(_ tag: Tag) -> Tag? {
        assert(!tag.isEmpty)
        let tagCharacters = Array(tag)
        var tagPosition = 0
        var matchedTag = false

        while !matchedTag, !isEnd(lookupChar) {
            if lookupChar == tagCharacters[tagPosition] {
                if tagPosition == 0 {
                    // Only start matching the tag if the previous position
                    // is the start of the string or a whitespace character

                    if isEnd(previousLookupChar) || isWhite(previousLookupChar) {
                        tagPosition += 1
                    } else {
                        tagPosition = 0
                    }
                } else {
                    tagPosition += 1
                }
            } else {
                tagPosition = 0
            }

            nextChar()
            matchedTag = tagPosition == tagCharacters.count
        }

        skipWhite()
        return matchedTag ? tag : nil
    }

    private func parseArguments() throws -> [Identifier] {
        guard lookupChar == "(" else {
            return []
        }

        try skipWhiteAndMatch("(")
        var arguments: [Identifier] = []

        if lookupChar == ")" {
            try skipWhiteAndMatch(")")
            return []
        }

        var collectArguments = true

        while collectArguments {
            let argument = try parseIdentifier("Argument")
            arguments.append(argument)

            if lookupChar == "," {
                try skipWhiteAndMatch(",")
                collectArguments = true
            } else {
                collectArguments = false
            }
        }

        try skipWhiteAndMatch(")")
        return arguments
    }

    private func parseBody() throws -> [Command] {
        guard lookupChar == "{" else {
            return []
        }

        try skipWhiteAndMatch("{")
        var commands: [Command] = []

        while lookupChar != "}" {
            commands.append(try parseCommand())
        }

        try skipWhiteAndMatch("}")
        return commands
    }

    private func parseCommand() throws -> Command {
        let commandName = try parseIdentifier("Command name")
        let arguments = try parseArguments()
        let body = try parseBody()
        return Command(name: commandName, arguments: arguments, body: body)
    }

    private func parseTaggedCommand() throws -> TaggedCommand? {
        guard let tag = skipUntilTag(self.tag) else {
            return nil
        }

        return TaggedCommand(tag: tag, command: try parseCommand())
    }

    private func parseChildren() throws -> [TaggedCommand] {
        var taggedCommands = [TaggedCommand]()

        while let taggedCommand = try parseTaggedCommand() {
            taggedCommands.append(taggedCommand)
        }
        
        return taggedCommands
    }
}

private extension CharacterSet {
    static var underscore: CharacterSet {
        CharacterSet(charactersIn: "_")
    }

    func containsCharacter(_ character: Character) -> Bool {
        CharacterSet(charactersIn: String(character)).isSubset(of: self)
    }
}
