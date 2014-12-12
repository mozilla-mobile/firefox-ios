# Working with Managed Object Contexts

## Creating New Contexts

A variety of simple class methods are provided to help you create new contexts:

-  `+ [NSManagedObjectContext MR_newContext]`: Sets the default context as it's parent context. Has a concurrency type of **NSPrivateQueueConcurrencyType**.
- `+ [NSManagedObjectContext MR_newMainQueueContext]`: Has a concurrency type of ** NSMainQueueConcurrencyType**.
- `+ [NSManagedObjectContext MR_newPrivateQueueContext]`: Has a concurrency type of **NSPrivateQueueConcurrencyType**.
- `+ [NSManagedObjectContext MR_newContextWithParent:…]`: Allows you to specify the parent context that will be set. Has a concurrency type of **NSPrivateQueueConcurrencyType**.
- `+ [NSManagedObjectContext MR_newContextWithStoreCoordinator:…]`: Allows you to specify the persistent store coordinator for the new context. Has a concurrency type of **NSPrivateQueueConcurrencyType**.

## The Default Context

When working with Core Data, you will regularly deal with two main objects: `NSManagedObject` and `NSManagedObjectContext`.

MagicalRecord provides a simple class method to retrieve a default `NSManagedObjectContext` that can be used throughout your app. This context operates on the main thread, and is great for simple, single-threaded apps.

To access the default context, call:

```objective-c
NSManagedObjectContext *defaultContext = [NSManagedObjectContext MR_defaultContext];
```

This context will be used throughout MagicalRecord in any method that uses a context, but does not provde a specific managed object context parameter.

If you need to create a new managed object context for use in non-main threads, use the following method:

```objective-c
NSManagedObjectContext *myNewContext = [NSManagedObjectContext MR_newContext];
```

This will create a new managed object context which has the same object model and persistent store as the default context, but is safe for use on another thread. It automatically sets the default context as it's parent context.

If you'd like to make your `myNewContext` instance the default for all fetch requests, use the following class method:

```objective-c
[NSManagedObjectContext MR_setDefaultContext:myNewContext];
```

> **NOTE:** It is *highly* recommended that the default context is created and set on the main thread using a managed object context with a concurrency type of `NSMainQueueConcurrencyType`.


## Performing Work on Background Threads

MagicalRecord provides methods to set up and work with contexts for use in background threads. The background saving operations are inspired by the UIView animation block methods, with a few minor differences:

* The block in which you make changes to your entities will never be executed on the main thread.
* A single **NSManagedObjectContext** is provided for you within these blocks.

For example, if we have Person entity, and we need to set the firstName and lastName fields, this is how you would use MagicalRecord to setup a background context for your use:

```objective-c
Person *person = ...;

[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext){

  Person *localPerson = [person MR_inContext:localContext];
  localPerson.firstName = @"John";
  localPerson.lastName = @"Appleseed";

}];
```

In this method, the specified block provides you with the proper context in which to perform your operations, you don't need to worry about setting up the context so that it tells the Default Context that it's done, and should update because changes were performed on another thread.

To perform an action after this save block is completed, you can fill in a completion block:

```objective-c
Person *person = ...;

[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext){

  Person *localPerson = [person MR_inContext:localContext];
  localPerson.firstName = @"John";
  localPerson.lastName = @"Appleseed";

} completion:^(BOOL success, NSError *error) {

  self.everyoneInTheDepartment = [Person findAll];

}];
```

This completion block is called on the main thread (queue), so this is also safe for triggering UI updates.
