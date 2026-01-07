import Foundation
import SwiftUI

// wiring: container(MyContainer) {
//   bind(MyClass, SomeProtocol)
//   singletonBind(MySingleton, SomeOtherProtocol)
//   singleton(AnotherSingleton)
//   instance(SomeInstance)
//   instance(SomeInstanceWithoutParameters)
// }
protocol MyContainerProtocol {
}

// wiring: inject
final class MyClass: SomeProtocol {

    let instance: SomeInstanceWithoutParameters
    let someDependency: SomeDependency
    let anotherDependency: AnotherDependency
    let singleton: SomeOtherProtocol
    let parameter: Int

    init(
        // wiring: dependency
        @Dependency instance: SomeInstanceWithoutParameters,
        // wiring: dependency
        @Dependency someDependency: SomeDependency,
        // wiring: dependency
        @Dependency anotherDependency: AnotherDependency,
        // wiring: dependency
        @Dependency singleton: SomeOtherProtocol,
        parameter value: Int,
        otherParameter: Array<Int>,
        // wiring: dependency
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

// wiring: inject
class MySingleton: SomeOtherProtocol {

    let someDependency: SomeDependency

    init(
        // wiring: dependency
        @Dependency someDependency: SomeDependency
    ) {
        self.someDependency = someDependency
    }
}

// wiring: inject
class AnotherSingleton {
    let firstSingleton: SomeOtherProtocol

    init(
        // wiring: dependency
        @Dependency firstSingleton: SomeOtherProtocol
    ) {
        self.firstSingleton = firstSingleton
    }
}

// wiring: inject
class SomeInstance {
    let firstSingleton: SomeOtherProtocol
    let parameter: Int

    init(
        // wiring: dependency
        @Dependency firstSingleton: SomeOtherProtocol,
        parameter: Int
    ) {
        self.firstSingleton = firstSingleton
        self.parameter = parameter
    }
}

// wiring: inject
class SomeInstanceWithoutParameters {
    let firstSingleton: SomeOtherProtocol
    let anotherSingleton: AnotherSingleton

    init(
        // wiring: dependency
        @Dependency firstSingleton: SomeOtherProtocol,
        // wiring: dependency
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
