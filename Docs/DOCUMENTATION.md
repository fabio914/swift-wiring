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

### Inject

<details>

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

### Dependency

<details>

| Syntax | `sw: dependency(OptionalName?)` |
|---|---|
| Examples | `sw: dependency`, `sw: dependency()` or `sw: dependency(SomeName)` |
| Usage | Inside a `class`' `init`'s parameters list, or inside a top-level `func`'s parameters list |

**Description**

TODO

</details>

### Container

<details>

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

### Access

<details>

| Syntax | `access(public \| internal)` |
|---|---|
| Examples | `access(public)` or `access(internal)` |

**Description**

TODO

</details>

### Build

<details>

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


### Singleton

<details>

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

### Access

<details>

| Syntax | `access(public \| internal)` |
|---|---|
| Examples | `access(public)` or `access(internal)` |

**Description**

TODO

</details>

### Name

<details>

| Syntax | `name(DependencyName)` |
|---|---|
| Examples | `name(Authenticated)` or `name(UserEmail)` |

**Description**

TODO

</details>

