# Why Swift Wiring?

Most automatic dependency injection tools for Swift either only work in runtime and provide no compile-time guarantee. Other compile-time tools require changes to the code, and require the project to use specific Swift Macros and use Swift Package Manager.

Swift Wiring doesn't modify the existing code, and it doesn't require any other code dependencies to be added to your project.

It's core philosophy is to be:

**Non-intrusive**
All of its annotations and commands live in comments.

**Additive**
It does not modify your existing source code, and it only generates new code.

**Simple**
It has only a few commands. It also won't check every error, so it relies on the compiler to ultimately verify the generated Container code. The generated code is human-readable and can be debugged.

# Installation

You can install this command line tool with [Mint](https://github.com/yonaskolb/Mint), by running:

```shell
mint install fabio914/swift-wiring@main
```

Alternatively, you can clone this repository and run `sudo install.sh` to install it in `/usr/local/bin`.

# Configuration

```shell
swift-wiring inject <source files> -o <output file with your Containers>
```

<details>

<summary>
## 1. Configure your Xcode Target
</summary>

Add a "New Run Script Phase" to your target on Xcode to be able to run Swift Wiring as part of its build.

First, add `export PATH=$PATH:/path/to/swift-wiring/` to your script to add Swift Wiring to Xcode's PATH (if it's not already in that PATH), where `/path/to/swift-wiring/` should be replaced with the path to Swift Wiring, for example: `export PATH=$PATH:~/.mint/bin` if you installed it with Mint.

Swift Wiring only needs to read the Swift files in your target that require dependency injection.

You can then either list all the necessary input Swift files in the "Input files" section (and enable the "Run script: Based on dependency analysis" option), or alternatively you can add the `.wire.swift` extension to the files you want Swift Wiring to scan, and use the following:

```shell
find ${SRCROOT}/MyTarget -name "*.wire.swift" | tr '\n' ' '
```

to make the script find the path of all files ending in `.wire.swift` (where `MyTarget` is your the name of your target).

Example:

```shell
swift-wiring inject `find ${SRCROOT}/MyTarget -name "*.wire.swift" | tr '\n' ' '` -o ${SCRIPT_OUTPUT_FILE_0}
```

Now add an empty `Containers.generated.swift` file to your target, and add the path to this file to the "Output files" section (example: `$(SRCROOT)/MyTarget/Generated/Containers.generated.swift`). This is the file where Swift Wiring will output the code for your Containers.

![Run Phase](run_phase.png)

</details>

<details>

<summary>
## 2. Create your first Container
</summary>

TODO

</details>

<details>

<summary>
## 3. Annotate your Injectable Classes and Functions, and Dependencies
</summary>

TODO

</details>

# Swift Wiring Syntax

Swift Wiring commands are added to comments just before the parts of the Swift code that they should act on. 
The tool will ignore every part of the comment until a `sw:` tag is found.

**Example**

```swift
import Foundation

/*
  Swift Wiring will ignore this part of the comment.

  sw: container(MyContainer) {
    // Single line comments are allowed inside Swift Wiring blocks
    // ...
  }
*/
protocol MyContainerProtocol {}
```

## `sw:` commands

<details>

<summary>
### Inject
</summary>

| Syntax | `sw: inject` |
|---|---|
| Examples | `sw: inject` or `sw: inject()` |
| Usage | Before top-level `class`es or `func`s |

**Description**

You can add this command to:

 - Top-level `class`s (non-nested) with a single `init` function, without optionals, generics, etc, and without effects (`async`, `throws`, etc).

 - Top-level (non-nested) `func`s that return simple types (without optionals, tuples, generics, etc) and without effects (`async`, `throws`, etc).

Swift Wiring assumes that these classes and functions can be instantiated/called by the generated Container code. The programmer is responsible for defining the correct access control to ensure that this is the case.

TODO

</details>

<details>

<summary>
### Dependency
</summary>

| Syntax | `sw: dependency(OptionalName?)` |
|---|---|
| Examples | `sw: dependency`, `sw: dependency()` or `sw: dependency(SomeName)` |
| Usage | Inside a `class`' `init`'s parameters list, or inside a top-level `func`'s parameters list |

**Description**

TODO

</details>

<details>

<summary>
### Container
</summary>

| Syntax | `sw: container(ContainerName) { container subcommands }` |
|---|---|
| Usage | Before top-level `protocol`s |


**Example**
```
sw: container(MyContainer) {
    // Single line comments are allowed here
    access(internal)
    build(MyClass)
    build(MyClass, MyProtocol) {
        // Single line comments are allowed here too
        access(public)
        name(SpecialDependency)
    }
    singleton(MyOtherClass)
    singleton(MyOtherClass, MyProtocol) {
        access(internal)
    }
}
```

**Description**

This command receives a `ContainerName`, and a block with container subcommands.

You can add this command to `protocol`s to instruct Swift Wiring to generate a Container class named `ContainerName` that conforms to that protocol. Notice that Swift Wiring won't validate if the Container implementation actually implements that protocol, it is recommended to use this command with empty protocols.

Check the [Container subcommands](#container-subcommands) section below for the subcommands that are allowed in a Container definition. 

TODO

</details>

## Container subcommands

<details>

<summary>
### Access
</summary>

| Syntax | `access(public \| internal)` |
|---|---|
| Examples | `access(public)` or `access(internal)` |

**Description**

TODO

</details>

<details>

<summary>
### Build
</summary>

| Syntax |
|---|
| `build(ClassOrFunction, BindingType?) { optional binding subcommands }` |

**Examples**

```
build(MyClass)
```

```
build(MyClass, MyProtocol) { 
    access(public) 
}
```

```
build(myProvider, MyProtocol) {
    access(public)
    name(Authenticated)
}
```

**Description**

TODO

Check the [Binding subcommands](#binding-subcommands) section below for the subcommands that are allowed in a Build command.

</details>

<details>

<summary>
### Singleton
</summary>

| Syntax |
|---|
| `singleton(ClassOrFunction, BindingType?) { optional binding subcommands }` |

**Examples**

```
singleton(MyClass)
```

```
singleton(MyClass, MyProtocol) { 
    access(public) 
}
```

```
singleton(myProvider, MyProtocol) {
    access(public)
    name(Authenticated)
}
```

**Description**

TODO

Check the [Binding subcommands](#binding-subcommands) section below for the subcommands that are allowed in a Singleton command.

</details>

## Binding subcommands

<details>

<summary>
### Access
</summary>

| Syntax | `access(public \| internal)` |
|---|---|
| Examples | `access(public)` or `access(internal)` |

**Description**

TODO

</details>

<details>

<summary>
### Name
</summary>

| Syntax | `name(DependencyName)` |
|---|---|
| Examples | `name(Authenticated)` or `name(UserEmail)` |

**Description**

TODO

</details>

