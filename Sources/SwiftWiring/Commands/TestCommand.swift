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
             * myCommand: Test {
             *   test
             *  }
             */
            // Test { }
            /// Test2 { }
            /**
              Test3 { }
             */
            /**
             * Test[4]
             */
            /*
             Test_5
             */
            /*
             * Test 6
             */
            protocol Something {}
            // inject1

            // inject2
            
            // inject3
            @MainActor
            final class OtherClass {

                init(
                    /* dependency */ something: Int,
                    // another_dependency
                    somethingElse: Int
                ) {

                }
            }
            """


        var tree = Parser.parse(source: source)

        let protocolDefinition = tree.statements.remove(at: tree.statements.index(at: 0))
        let protocolDefinitionLeadingTrivia = protocolDefinition.item.leadingTrivia
        print(protocolDefinitionLeadingTrivia.allComments)

        let classDefinition = tree.statements.remove(at: tree.statements.index(at: 0))
        let classDefinitionLeadingTrivia = classDefinition.item.leadingTrivia
        print(classDefinitionLeadingTrivia.allComments)

        classDefinition.item.as(ClassDeclSyntax.self)?.memberBlock.members.first?.decl.as(InitializerDeclSyntax.self)?.signature.parameterClause.parameters.forEach {
            print($0.leadingTrivia.allComments)
        }
    }
}
