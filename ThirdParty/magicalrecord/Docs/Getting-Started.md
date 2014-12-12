# Getting Started

To get started, import the `MagicalRecord.h` header file in your project's pch file. This will allow a global include of all the required headers.

If you're using CocoaPods or MagicalRecord.framework, your import should look like:

```objective-c
#import <MagicalRecord/MagicalRecord.h>
```

Otherwise, if you've added MagicalRecord's source files directly to your project, your import should be:

```objective-c
#import "MagicalRecord.h"
```

Next, somewhere in your app delegate, in either the `- applicationDidFinishLaunching: withOptions:` method, or `-awakeFromNib`, use **one** of the following setup calls with the **MagicalRecord** class:

```objective-c
+ (void)setupCoreDataStack;
+ (void)setupAutoMigratingCoreDataStack;
+ (void)setupCoreDataStackWithInMemoryStore;
+ (void)setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void)setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;
+ (void)setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL;
+ (void)setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;
```

Each call instantiates one of each piece of the Core Data stack, and provides getter and setter methods for these instances. These well known instances to MagicalRecord, and are recognized as "defaults".

When using the default SQLite data store with the `DEBUG` flag set, changing your model without creating a new model version will cause MagicalRecord to delete the old store and create a new one automatically. This can be a huge time saver — no more needing to uninstall and reinstall your app every time you make a change your data model! **Please be sure not to ship your app with `DEBUG` enabled: Deleting your app's data without telling the user about it is really bad form!**

Before your app exits, you should call `+cleanUp` class method:

```objective-c
[MagicalRecord cleanUp];
```

This tidies up after MagicalRecord, tearing down our custom error handling and setting all of the Core Data stack created by MagicalRecord to nil.

## iCloud-enabled Persistent Stores

To take advantage of Apple's iCloud Core Data syncing, use **one** of the following setup methods in place of the standard methods listed in the previous section:

```objective-c
+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                              localStoreNamed:(NSString *)localStore;

+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                               contentNameKey:(NSString *)contentNameKey
                              localStoreNamed:(NSString *)localStoreName
                      cloudStorePathComponent:(NSString *)pathSubcomponent;

+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                               contentNameKey:(NSString *)contentNameKey
                              localStoreNamed:(NSString *)localStoreName
                      cloudStorePathComponent:(NSString *)pathSubcomponent
                                   completion:(void (^)(void))completion;

+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                              localStoreAtURL:(NSURL *)storeURL;

+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                               contentNameKey:(NSString *)contentNameKey
                              localStoreAtURL:(NSURL *)storeURL
                      cloudStorePathComponent:(NSString *)pathSubcomponent;

+ (void)setupCoreDataStackWithiCloudContainer:(NSString *)containerID
                               contentNameKey:(NSString *)contentNameKey
                              localStoreAtURL:(NSURL *)storeURL
                      cloudStorePathComponent:(NSString *)pathSubcomponent
                                   completion:(void (^)(void))completion;
```

For further details, please refer to [Apple's "iCloud Programming Guide for Core Data"](https://developer.apple.com/library/ios/documentation/DataManagement/Conceptual/UsingCoreDataWithiCloudPG/Introduction/Introduction.html#//apple_ref/doc/uid/TP40013491).


### Notes

If you are managing multiple iCloud-enabled stores, we recommended that you use one of the longer setup methods that allows you to specify your own **contentNameKey**. The shorter setup methods automatically generate the **NSPersistentStoreUbiquitousContentNameKey** based on your app's bundle identifier (`CFBundleIdentifier`):
