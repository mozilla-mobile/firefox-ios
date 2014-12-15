# Saving Entities

## When should I save?

In general, your app should save to it's persistent store(s) when data changes. Some applications choose to save on application termination, however this shouldn't be necessary in most circumstances — in fact, **if you're only saving when your app terminates, you're risking data loss**! What happens if your app crashes? The user will lose all the changes they've made — that's a terrible experience, and easily avoided.

If you find that saving is taking a long time, there are a couple of things you should consider doing:

1. **Save in a background thread**: MagicalRecord provides a simple, clean API for making changes to your entities and subsequently saving them in a background thread — for example:
	````objective-c
	[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

		// Do your work to be saved here, against the `localContext` instance
		// Everything you do in this block will occur on a background thread

	} completion:^(BOOL success, NSError *error) {
		[application endBackgroundTask:bgTask];
		bgTask = UIBackgroundTaskInvalid;
	}];
	````

2. **Break the task down into smaller saves**: tasks like importing large amounts of data should always be broken down into smaller chunks. There's no one-size-fits all rule for how much data you should be saving in one go, so you'll need to measure your application's performance using a tool like Apple's Instruments and tune appropriately.


## Handling Long-running Saves

### On iOS

When an application terminates on iOS, it is given a small window of opportunity to tidy up and save any data to disk. If you know that a save operation is likely to take a while, the best approach is to request an extension to your application's expiration, like so:

````objective-c
UIApplication *application = [UIApplication sharedApplication];

__block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}];

[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

	// Do your work to be saved here

} completion:^(BOOL success, NSError *error) {
	[application endBackgroundTask:bgTask];
	bgTask = UIBackgroundTaskInvalid;
}];
````

Be sure to carefully [read the documentation for `beginBackgroundTaskWithExpirationHandler`](https://developer.apple.com/library/iOS/documentation/UIKit/Reference/UIApplication_Class/Reference/Reference.html#//apple_ref/occ/instm/UIApplication/beginBackgroundTaskWithExpirationHandler:), as inappropriately or unnecessarily extending your application's lifetime may earn your app a rejection from the App Store.

### On OS X

On OS X Mavericks (10.9) and later, App Nap can cause your application to act as though it is effectively terminated when it is in the background. If you know that a save operation is likely to take a while, the best approach is to disable automatic and sudden termination temporarily (assuming that your app supports these features):

````objective-c
NSProcessInfo *processInfo = [NSProcessInfo processInfo];

[processInfo disableSuddenTermination];
[processInfo disableAutomaticTermination:@"Application is currently saving to persistent store"];

[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

	// Do your work to be saved here

} completion:^(BOOL success, NSError *error) {
	[processInfo enableSuddenTermination];
	[processInfo enableAutomaticTermination:@"Application has finished saving to the persistent store"];
}];
````

As with the iOS approach, be sure to [read the documentation on NSProcessInfo](https://developer.apple.com/library/mac/documentation/cocoa/reference/foundation/Classes/NSProcessInfo_Class/Reference/Reference.html) before implementing this approach in your app.

---

## Changes to saving in MagicalRecord 2.3.0

### Context For Current Thread Deprecation

In earlier releases of MagicalRecord, we provided methods to retrieve the managed object context for the thread that the method was called on. Unfortunately, **it's not possible to return the context for the currently executing thread in a reliable manner** anymore. Grand Central Dispatch (GCD) makes no guarantees that a queue will be executed on a single thread, and our approach was based upon the older NSThread API while CoreData has transitioned to use GCD. For more details, please see Saul's post "[Why contextForCurrentThread Doesn't Work in MagicalRecord](http://saulmora.com/2013/09/15/why-contextforcurrentthread-doesn-t-work-in-magicalrecord/)".

In MagicalRecord 2.3.0, we continue to use `+MR_contextForCurrentThread` internally in a few places to maintain compatibility with older releases. These methods are deprecated, and you will be warned if you use them.

In particular, **do not use `+MR_contextForCurrentThread` from within any of the `+[MagicalRecord saveWithBlock:…]` methods — the returned context may not be correct!**

If you'd like to begin preparing for the change now, please use the method variants that accept a "context" parameter, and use the context that's passed to you in the `+[MagicalRecord saveWithBlock:…]` method block. Instead of:

```objective-c
[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
	NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntity];
	// …
}];
```

You should now use:

```objective-c
[MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {
	NSManagedObject *inserted = [SingleEntityWithNoRelationships MR_createEntityInContext:localContext];
	// …
}];
```

**When MagicalRecord 3.0 is released, the context for current thread methods will be removed entirely**. The methods that do not accept a "context" parameter will move to using the default context of the default stack — please see the MagicalRecord 3.0 release notes for more details.

---

## Changes to saving in MagicalRecord 2.2.0

In MagicalRecord 2.2, the APIs for saving were revised to behave more consistently, and also to follow naming patterns present in Core Data. Extensive work has gone into adding automated tests that ensure the save methods (both new and deprecated) continue to work as expected through future updates.

`MR_save` has been temporarily restored to it's original state of running synchronously on the current thread, and saving to the persistent store. However, the __`MR_save` method is marked as deprecated and will be removed in the next major release of MagicalRecord (version 3.0)__. You should use `MR_saveToPersistentStoreAndWait` if you want the same behaviour in future versions of the library.

### New Methods
The following methods have been added:

#### NSManagedObjectContext+MagicalSaves

```objective-c
- (void) MR_saveOnlySelfWithCompletion:(MRSaveCompletionHandler)completion;
- (void) MR_saveToPersistentStoreWithCompletion:(MRSaveCompletionHandler)completion;
- (void) MR_saveOnlySelfAndWait;
- (void) MR_saveToPersistentStoreAndWait;
- (void) MR_saveWithOptions:(MRSaveContextOptions)mask completion:(MRSaveCompletionHandler)completion;
```

#### __MagicalRecord+Actions__

```objective-c
+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block;
+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(MRSaveCompletionHandler)completion;
+ (void) saveWithBlockAndWait:(void(^)(NSManagedObjectContext *localContext))block;
+ (void) saveUsingCurrentThreadContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(MRSaveCompletionHandler)completion;
+ (void) saveUsingCurrentThreadContextWithBlockAndWait:(void (^)(NSManagedObjectContext *localContext))block;
```

### Deprecations

The following methods have been deprecated in favour of newer alternatives, and will be removed in MagicalRecord 3.0:

#### NSManagedObjectContext+MagicalSaves

```objective-c
- (void) MR_save;
- (void) MR_saveWithErrorCallback:(void(^)(NSError *error))errorCallback;
- (void) MR_saveInBackgroundCompletion:(void (^)(void))completion;
- (void) MR_saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback;
- (void) MR_saveInBackgroundErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
- (void) MR_saveNestedContexts;
- (void) MR_saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback;
- (void) MR_saveNestedContextsErrorHandler:(void (^)(NSError *error))errorCallback completion:(void (^)(void))completion;
```

### MagicalRecord+Actions
```objective-c
+ (void) saveWithBlock:(void(^)(NSManagedObjectContext *localContext))block;
+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block;
+ (void) saveInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))completion;
+ (void) saveInBackgroundUsingCurrentContextWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(void (^)(void))completion errorHandler:(void (^)(NSError *error))errorHandler;
```
