# Swift Wiring

This is a command line tool for compile-time Automatic Dependency Injection for [Swift](https://www.swift.org). It reads `wiring:` annotations in the Swift source code and generates `Container`s with your resolved dependencies.

This tool is still in active development and is **experimental**. I don't recommend adopting it in your project yet. Check the TO-DO list below for some of the things that still need to be implemented.

**Input**
```swift
import Foundation

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

// wiring: inject
class MySingleton: SomeOtherProtocol {

    let someDependency: SomeDependency

    init(
        /* wiring:dependency */ someDependency: SomeDependency
    ) {
        self.someDependency = someDependency
    }
}

//wiring:inject
class AnotherSingleton {
    let firstSingleton: SomeOtherProtocol

    init(
        //wiring:dependency
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

protocol SomeOtherProtocol {}

protocol SomeDependency {}

protocol AnotherDependency {}
```

**Output**
```swift
import Foundation

internal final class MyContainer: MyContainerProtocol {
    let externalAnotherDependency: () -> AnotherDependency

    let externalSomeDependency: () -> SomeDependency

    private(set) lazy var singletonAnotherSingleton: AnotherSingleton = buildAnotherSingleton()

    private(set) lazy var singletonSomeOtherProtocol: SomeOtherProtocol = buildSomeOtherProtocol()

    public init(
        anotherDependency: @autoclosure @escaping () -> AnotherDependency,
        someDependency: @autoclosure @escaping () -> SomeDependency
    ) {
        self.externalAnotherDependency = anotherDependency
        self.externalSomeDependency = someDependency
    }

    internal func buildAnotherSingleton() -> AnotherSingleton {
        return AnotherSingleton(
            firstSingleton: self.singletonSomeOtherProtocol
        )
    }

    internal func buildSomeInstance(
        parameter: Int
    ) -> SomeInstance {
        return SomeInstance(
            firstSingleton: self.singletonSomeOtherProtocol,
            parameter: parameter
        )
    }

    internal func buildSomeInstanceWithoutParameters() -> SomeInstanceWithoutParameters {
        return SomeInstanceWithoutParameters(
            firstSingleton: self.singletonSomeOtherProtocol,
            anotherSingleton: self.singletonAnotherSingleton
        )
    }

    internal func buildSomeOtherProtocol() -> SomeOtherProtocol {
        return MySingleton(
            someDependency: self.externalSomeDependency()
        )
    }

    internal func buildSomeProtocol(
        parameter: Int,
        otherParameter: Array<Int>
    ) -> SomeProtocol {
        return MyClass(
            instance: self.buildSomeInstanceWithoutParameters(),
            someDependency: self.externalSomeDependency(),
            anotherDependency: self.externalAnotherDependency(),
            singleton: self.singletonSomeOtherProtocol,
            parameter: parameter,
            otherParameter: otherParameter,
            container: self
        )
    }
}
```

## Usage

```shell
swift-wiring inject <source files> -o <output file with your Containers>
```

## Example

Navigate to the `Example/` folder and use [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate an Xcode project of an iOS app that uses this tool.

You can install this command line tool with [Mint](https://github.com/yonaskolb/Mint).

## TO-DOs

 - [] Detect dependency cycles;
 - [] Named dependencies;
 - [] Access control;
 - [] Allow containers to extend other containers;
 - [] Support actors and main actors;
 - [] Support multiple initializers;
 etc...

## Credits

Developed by Fabio de Albuquerque Dela Antonio.

This project relies heavily on [Swift Syntax](https://github.com/swiftlang/swift-syntax).
