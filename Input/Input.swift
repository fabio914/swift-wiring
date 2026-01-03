import Foundation
import SwiftUI

@Container(MyContainer)
@Bind(MyClass, SomeProtocol)
@SingletonBind(MySingleton, SomeOtherProtocol)
@Singleton(AnotherSingleton)
@Instance(SomeInstance)
@Instance(SomeInstanceWithoutParameters)
protocol MyContainerProtocol {
}

@Inject
final class MyClass: SomeProtocol {

    let instance: SomeInstanceWithoutParameters
    let someDependency: SomeDependency
    let anotherDependency: AnotherDependency
    let singleton: SomeOtherProtocol
    let parameter: Int

    init(
        @Dependency instance: SomeInstanceWithoutParameters,
        @Dependency someDependency: SomeDependency,
        @Dependency anotherDependency: AnotherDependency,
        @Dependency singleton: SomeOtherProtocol,
        parameter value: Int,
        otherParameter: Array<Int>,
        @Dependency container: MyContainerProtocol
    ) {
        self.instance = instance
        self.someDependency = someDependency
        self.anotherDependency = anotherDependency
        self.singleton = singleton
        self.parameter = value
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

@Inject
class AnotherSingleton {
    let firstSingleton: SomeOtherProtocol

    init(
        @Dependency firstSingleton: SomeOtherProtocol
    ) {
        self.firstSingleton = firstSingleton
    }
}

@Inject
class SomeInstance {
    let firstSingleton: SomeOtherProtocol
    let parameter: Int

    init(
        @Dependency firstSingleton: SomeOtherProtocol,
        parameter: Int
    ) {
        self.firstSingleton = firstSingleton
        self.parameter = parameter
    }
}

@Inject
class SomeInstanceWithoutParameters {
    let firstSingleton: SomeOtherProtocol
    let anotherSingleton: AnotherSingleton

    init(
        @Dependency firstSingleton: SomeOtherProtocol,
        @Dependency anotherSingleton: AnotherSingleton
    ) {
        self.firstSingleton = firstSingleton
        self.anotherSingleton = anotherSingleton
    }
}

protocol SomeProtocol {
    func someFunction() -> Int
}

protocol SomeOtherProtocol {

}

protocol SomeDependency {

}

protocol AnotherDependency {

}
