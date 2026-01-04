import Foundation

protocol TestProtocol {
    func printSomething()
}

protocol SomeDependency {

}

@Inject
final class Dependency: SomeDependency {
    init() {}
}

@Inject
final class TestClass: TestProtocol {

    let dependency: SomeDependency

    init(
        @Dependency dependency: SomeDependency,
        parameter: Int
    ) {
        self.dependency = dependency
    }

    func printSomething() {
        print("Something")
    }
}

@Inject
final class SomethingElse: TestProtocol {

    init() {}

    func printSomething() {
        print("SomethingElse")
    }
}
