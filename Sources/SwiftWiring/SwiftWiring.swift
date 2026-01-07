import ArgumentParser

@main
struct SwiftWiring: ParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "swift-wiring",
        abstract: "swift-wiring is a tool to autogenerate dependency injection code for your Swift projects",
        subcommands: [
            InjectCommand.self
        ]
    )

    public init() {}
}
