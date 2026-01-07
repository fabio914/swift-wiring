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
        instance: SomeInstanceWithoutParameters,
        // wiring: dependency
        someDependency: SomeDependency,
        // wiring: dependency
        anotherDependency: AnotherDependency,
        // wiring: dependency
        singleton: SomeOtherProtocol,
        parameter value: Int,
        otherParameter: Array<Int>,
        /* wiring:dependency */ container: MyContainerProtocol
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
        /* wiring:dependency */ someDependency: SomeDependency
    ) {
        self.someDependency = someDependency
    }
}

// wiring: inject
class AnotherSingleton {
    let firstSingleton: SomeOtherProtocol

    init(
        // wiring: dependency
        firstSingleton: SomeOtherProtocol
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
        firstSingleton: SomeOtherProtocol,
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
        firstSingleton: SomeOtherProtocol,
        // wiring: dependency
        anotherSingleton: AnotherSingleton
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
