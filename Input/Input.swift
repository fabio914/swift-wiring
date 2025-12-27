import Foundation

@Container(MyContainer)
@Bind(MyClass, SomeProtocol)
@Singleton(MySingleton, SomeOtherProtocol)
protocol MyContainerProtocol {
}

@Inject
final class MyClass: SomeProtocol {

    let someDependency: SomeDependency
    let anotherDependency: AnotherDependency
    let singleton: SomeOtherProtocol
    let parameter: Int

    init(
        @Dependency someDependency: SomeDependency,
        @Dependency anotherDependency: AnotherDependency,
        @Dependency singleton: SomeOtherProtocol,
        parameter: Int,
        otherParameter: Array<Int>
    ) {
        self.someDependency = someDependency
        self.anotherDependency = anotherDependency
        self.singleton = singleton
        self.parameter = parameter
    }

    func someFunction() -> Int {
        return parameter
    }
}

// Singletons can't have parameters.
// Singletons can only depend on singletons, external dependencies,
// or dependencies without parameters, or have no dependencies.

@Inject
class MySingleton: SomeOtherProtocol {

    let someDependency: SomeDependency

    init(
        @Dependency someDependency: SomeDependency
    ) {
        self.someDependency = someDependency
    }
}

protocol SomeProtocol {
    func someFunction() -> Int
}

protocol SomeOtherProtocol {

}

protocol SomeDependency {

}

