//: Playground - noun: a place where people can play
//: This playground was created to demonstrate the defer keyword and swift 2.0 error handling
//: The motivation was to see if we could replace the Deferred and Result third party dependencies
//: with the native implementations
//:
//: conclusion: no we can't. Swift 2.0's defer keyword is more like a finally block in other languages
//: than like promises which our current Deferred implementation provides

import UIKit

//: Error types are generally enums that conform to ErrorType. They can therefore be as complex or as simple as any enum
enum FileError: ErrorType {
    case FileDoesntExist
    case FileIsEmpty
    case FileErrorWithInfo(NSError)
}


//: The defer keyword is kinda like a finally block. It ensures that a piece of code is always executed at the end of the scope that it is defined in. If that scope contains a return block, then the deferred block will be execute _after_ the return. This becomes useful when using swift 2.0 error handling as you can then ensure that wherever you leave the code, stuff that must be done, will be done
func cleanUp() {
    print("closing file handle")
    print("closing network connection")
    print("deallocating manually allocated buffer")
}

//: In this function, if we exit in any of the error conditions then cleanUp will never get called unless we explicitly call it from each exit case
func getContentsOfFile(filename: String) throws -> NSData {
    let fileManager = NSFileManager.defaultManager()
    if !fileManager.fileExistsAtPath(filename) {
        cleanUp()
        throw FileError.FileDoesntExist
    }
    guard let data = fileManager.contentsAtPath(filename) else { cleanUp(); throw FileError.FileIsEmpty }
    cleanUp()
    return data
}

do {
    try getContentsOfFile("file.txt")
} catch let error as FileError {
    print("got file error \(error)")
}

print("")

//: In this function, we can use defer to ensure that wherever we exit cleanUp always gets called
func deferredCleanUp() {
    print("Deferred Cleaning up")
}

func getContentsOfFileWithDefer(filename: String) throws -> NSData {
    defer { deferredCleanUp() }
    let fileManager = NSFileManager.defaultManager()
    if !fileManager.fileExistsAtPath(filename) {
        throw FileError.FileDoesntExist
    }
    guard let data = fileManager.contentsAtPath(filename) else { throw FileError.FileIsEmpty }
    return data
}

do {
    try getContentsOfFileWithDefer("file.txt")
} catch let error as FileError {
    print("got file error \(error)")
}

print("")

//: You can add as many deferred blocks as you like and they will be executed in reverse order (i.e. unrolled, like a FILO queue)
func count() {
    defer { print("Six") }
    defer { print("Five") }
    print("One")
    print("Two")
    print("Three")
    print("Four")
}

count()

//: you can also ensure that deferred blocks are scoped further using do {}
print("")

func counter() {
    defer { print("Nine") }
    print("One")
    print("Two")
    do {
        defer { print("Five") }
        print("Three")
        print("Four")
    }

    do {
        defer { print("Seven") }
        print("Six")
    }

    print("Eight")
}

counter()

//: or ensure that something happens at the end of every loop no matter how you go round
func counterWithLoop() {
    print("Counting...")
    var number = 200
    var iterations = 0
    while iterations < 5 {
        defer { iterations++ }
        switch number {
        case _ where number % 5 == 0:
            number = number / 5
            continue
        default:
            print("\(number) was not divisible by 5")
        }
        number--
    }

    print("number is \(number)")
    print("interations is \(iterations)")
}


counterWithLoop()

//: you can have as much code inside that defered block as you want

enum EqualError: ErrorType {
    case NoLeftHandValue
    case NoRightHandValue
}

func equalInts(a a: Int?, b: Int?) throws -> Bool {
    defer {
        print("closing file handle")
        print("closing network connection")
        print("closing database connection")
        print("deallocating manually allocated buffer")
        print("Deregistering for NSNotifications")
        print("Stopping listening for event")
        print("Deregisterng for KVO")
    }

    guard let lhs = a else { throw EqualError.NoLeftHandValue }
    guard let rhs = b else { throw EqualError.NoRightHandValue }
    print("Doing some important stuff")
    return lhs == rhs
}

do {
    print("")
    try equalInts(a: nil, b: 1)
} catch {
    print(error)
}

do {
    print("")
    try equalInts(a: 3, b: nil)
} catch {
    print(error)
}

do {
    print("")
    try equalInts(a: 3, b: 3)
} catch {
    print(error)
}


//: Now some error handling examples
//: Above we've seen the basics of error handling - throws, try's, do catch and ErrorType
//: But let's explore what else we can do here

//: There are 3 different types of try: try, try! and try?

enum ExampleError: ErrorType {
    case Default
    case Specific
    case Custom(message: String)
}

func throwingMethod() throws {
    throw ExampleError.Default
}

//: This is just a default catch of an error - function throws error, we catch
func tryExample() {
    do {
        try throwingMethod()
    } catch {
        print(error)
    }
}

//: As our method _could_ throw many different types of error we must test for each of those
func tryMultipleErrorsExample() {
    do {
        try throwingMethod()
    } catch ExampleError.Default {
        print("default error")
    } catch ExampleError.Custom(let message) {
        print("custom error \(message)")
    } catch ExampleError.Specific {
        print("specific errorErro")
    } catch {
        print("we have to be exhaustive in our catch \(error)")
    }
}

tryMultipleErrorsExample()

//: Sometimes you know a throwing function won't, in fact, throw an error at runtime. In this cases you can disable error propogation using try!
func throwingFunctionThatDoesntThrow() throws {
    let right = true
    if !right {
        throw ExampleError.Specific
    }
    print("right is always true")
}

func disableErrorPropogationExample() {
    try! throwingFunctionThatDoesntThrow()
}

disableErrorPropogationExample()

//: if you simply don't want to handle the error yourself but don't want to lose it you can just propgate it back up the chain by making your function throw
func callsThrowingFunction() throws {
    return try throwingMethod()
}

do {
    try callsThrowingFunction()
} catch {
    print(error)
}

//: But othertimes you don't actually care what the error is, you just want to do something based on whether or not it succeeds. 
//: Or your throwing function _may_ return something but won't if it fails. These are cases for try?
func cleanDivision(val: Int, by: Int) throws -> Int? {
    if val % by == 0 {
        return val / by
    }

    throw ExampleError.Custom(message: "\(val) is not cleanly divisible by \(by)")
}

func optionalTryExample() {
    guard let result1 = try? cleanDivision(9, by: 3) else { print("9 was not cleanly divisibly by 3"); return }
    print("9 was cleanly divisibly by 3 \(result1)")

    if let result2 = try? cleanDivision(7, by: 3) {
        print("7 was cleanly divisibly by 3 \(result2)")
    } else {
        print("7 was not cleanly divisibly by 3")
    }
}

optionalTryExample()
