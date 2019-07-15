# Deferred

This is an implementation of [OCaml's Deferred](https://ocaml.janestreet.com/ocaml-core/111.25.00/doc/async_kernel/#Deferred) for Swift.

## Overview

`Deferred` is designed for supporting asynchronous programming. An instance of
`Deferred` represents a value that will be available at some point in the
future. Deferred objects can trivially replace completion blocks (see
[Running Closures Upon Fulfillment](#upon)), but also enable some higher level,
powerful composition techniques.

All properties and methods on an instance of `Deferred` can safely be called from
multiple threads simultaneously; a lock is used internally for synchronization.
Obviously this does not guarantee thread-safety of the contained result (which
`Deferred` knows nothing about).

An instance of `Deferred` can only be filled once. It is a programmer error to
fill an already-filled `Deferred`, and this will result in a runtime trap. (The
method `fillIfUnfilled` is available for conditional filling.)

## Usage - Producer

```swift
// Potentially long-running operation.
func performOperation() -> Deferred<Int> {
		// 1. Create deferred.
    let deferred = Deferred<Int>()

		// 2. Kick off asynchronous code that will eventually...
    dispatch_async(dispatch_get_main_queue(), {
        let result = compute_result()

				// 3. ... fill the deferred in with its value
        deferred.fill(result)
    })

		// 4. Return the (currently still unfilled) deferred
    return deferred
}
```

## Usage - Consumer

### <a name="upon"></a>Running Closures Upon Fulfillment

You can use the `upon` method to run a closure once the `Deferred` has been
filled. `upon` can be called multiple times, and the closures will be called
in the order they were supplied to `upon` (with the normal race condition caveat
if you are calling `upon` from multiple threads simultaneously).

By default, `upon` will run the closures on a background concurrent GCD queue.
You can change this by passing a different default queue when the `Deferred` is
created, or by using the `uponQueue` method to specify a queue for the closure.

```swift
let deferredResult = performOperation()

deferredResult.upon { result in
    println("got \(result)")
}
```

### Peeking at Current Value

Use the `peek` method to determine whether or not the `Deferred` is currently
filled.

```swift
let deferredResult = performOperation()

if let result = deferredResult.peek() {
		println("filled with \(result)")
} else {
		println("currently unfilled")
}
```

### Blocking on Fulfillment

Use the `value` property to wait for the `Deferred` to be filled and get the value.

```swift
// WARNING: Blocks the calling thread!
let result: Int = performOperation().value
```

### Chaining Deferreds

Monadic `bind` and `map` are available to chain `Deferred` results. For example,
suppose you have a method that asynchronously reads a string, and you want to
call `toInt()` on that string:

```swift
// Producer
func readString() -> Deferred<String> {
		let deferredResult = Deferred<String>()
		// dispatch_async something to fill deferredResult...
		return deferredResult
}

// Consumer
let deferredInt: Deferred<Int?> = readString().map { $0.toInt() }
```

`bind` and `map`, like `upon`, execute on a concurrent background thread by
default (once the instance has been filled), unless a different queue is
passed when the `Deferred` instance is created. `bindQueue` and `mapQueue` are
available if you want to specify the GCD queue as the consumer.

### Combining Deferreds

There are three functions available for combining multiple `Deferred` instances:

```swift
// `both` creates a new Deferred that is filled once both inputs are available
let d1: Deferred<Int> = ...
let d2: Deferred<String> = ...
let dBoth : Deferred<(Int,String) = d1.both(d2)

// `all` creates a new Deferred that is filled once all inputs are available.
// All of the input Deferreds must contain the same type.
var deferreds: [Deferred<Int>] = []
for i in 0 ..< 10 {
		deferreds.append(...)
}
var allDeferreds: Deferred<[Int]> = all(deferreds)
// Once all 10 input deferreds are filled, allDeferreds[i] will contain the result
// of deferreds[i].

// `any` creates a new Deferred that is filled once any one of its inputs is available.
// If multiple inputs become available simultaneously, no guarantee is made about which
// will be selected.
var anyDeferred: Deferred<Deferred<Int>> = any(deferreds)
// Once any one of the 10 input deferreds is filled, anyDeferred will contain that
// Deferred instance, which is guaranteed to be filled.
```

## Integration

Add this repository as a submodule, or use [Carthage](https://github.com/Carthage/Carthage/).

## Author

John Gallagher, jgallagher@bignerdranch.com

## License

Deferred is available under the MIT license. See the LICENSE file for more info.
