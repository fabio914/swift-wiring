import Foundation
import ArgumentParser
import SwiftSyntax
import SwiftParser

struct TestCommand: ParsableCommand {

    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Testing"
    )

    func run() throws {
        let source = """
            /**
             * wiring: container(MyContainer) {
             *   // Adding some bindings
             *   bind(MyClass, MyProtocol)
             *   instance(MyOtherClass)
             * }
             */
            protocol SomeContainerProtocol {}

            // wiring: inject
            @MainActor
            final class MyOtherClass {
                init(
                    /* wiring: dependency */ container: MyContainer,
                    // wiring: dependency()
                    something: MyProtocol,
                    parameter: Int
                ) {
                    self.container = container
                    self.something = something
                    self.value = parameter
                }
            
                let container: MyContainer
                let something: MyProtocol
                let value: Int
            }
            
            // wiring: inject()
            final class MyClass: MyProtocol {
                init() { }
            }
            """

        let tag = "wiring:"
        var tree = Parser.parse(source: source)

        let protocolDefinition = tree.statements.remove(at: tree.statements.index(at: 0))
        let protocolDefinitionLeadingTrivia = protocolDefinition.item.leadingTrivia
        let protocolComments = protocolDefinitionLeadingTrivia.allComments
        let protocolCommands = try CommandParser.parse(protocolComments, tag: tag)
        print(protocolCommands)

        let classDefinition = tree.statements.remove(at: tree.statements.index(at: 0))
        let classDefinitionLeadingTrivia = classDefinition.item.leadingTrivia
        let classComments = classDefinitionLeadingTrivia.allComments
        let classCommands = try CommandParser.parse(classComments, tag: tag)
        print(classCommands)

        try classDefinition.item.as(ClassDeclSyntax.self)?.memberBlock.members.first?.decl.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters.forEach {
            let initializerComment = $0.leadingTrivia.allComments
            let initializerCommand = try CommandParser.parse(initializerComment, tag: tag)
            print(initializerCommand)
        }
    }
}
