# Installing MagicalRecord

**Adding MagicalRecord to your project is simple**: Just choose whichever method you're most comfortable with and follow the instructions below.

## Using CocoaPods

The easiest way to integrate MagicalRecord in your project is to use [CocoaPods](http://cocoapods.org/):

1. Add the following line to your `Podfile`:

    ````ruby
    pod "MagicalRecord"
    ````

2. In your project directory, run `pod update`
3. You should now be able to add `#import <MagicalRecord/CoreData+MagicalRecord.h>` to any of your target's source files and begin using MagicalRecord!

## Using an Xcode subproject

Xcode sub-projects allow your project to use and build MagicalRecord as an implicit dependency.

1. Add MagicalRecord to your project as a Git submodule:

    ````
    $ cd MyXcodeProjectFolder
    $ git submodule add https://github.com/magicalpanda/MagicalRecord.git Vendor/MagicalRecord
    $ git commit -m "Add MagicalRecord submodule"
    ````
2. Drag `Vendor/MagicalRecord/MagicalRecord.xcproj` into your existing Xcode project
3. Navigate to your project's settings, then select the target you wish to add MagicalRecord to
4. Navigate to **Build Phases** and expand the **Link Binary With Libraries** section
5. Click the **+** and find the version of MagicalRecord appropriate to your target's platform (`libMagicalRecord-iOS.a` for iOS, `libMagicalRecord-OSX.dylib` for OS X)
6. Navigate to **Build Settings**, then search for **Header Search Paths** and double-click it to edit
7. Add a new item using **+**: `"$(SRCROOT)/Vendor/MagicalRecord/MagicalRecord"` and ensure that it is set to *recursive*
8. You should now be able to add `#import "CoreData+MagicalRecord.h"` to any of your target's source files and begin using MagicalRecord!

> **Note** Please be aware that if you've set Xcode's **Link Frameworks Automatically** to **No** then you may need to add the CoreData.framework to your project on iOS, as UIKit does not include Core Data by default. On OS X, Cocoa includes Core Data.

## Manually from source

If you don't want to use CocoaPods or use an Xcode subproject, you can add MagicalRecord's source directly to your project.

1. Add MagicalRecord to your project as a Git submodule

    ````
    $ cd MyXcodeProjectFolder
    $ git submodule add https://github.com/magicalpanda/MagicalRecord.git Vendor/MagicalRecord
    $ git commit -m "Add MagicalRecord submodule"
    ````
2. Drag `Vendor/MagicalRecord/MagicalRecord` into your Xcode project, and ensure that you add it to the targets that you wish to use it with.
3. You should now be able to add `#import "CoreData+MagicalRecord.h"` to any of your target's source files and begin using MagicalRecord!

> **Note** Please be aware that if you've set Xcode's **Link Frameworks Automatically** to **No** then you may need to add the CoreData.framework to your project on iOS, as UIKit does not include Core Data by default. On OS X, Cocoa includes Core Data.


# Shorthand Category Methods

By default, all of the category methods that MagicalRecord provides are prefixed with `MR_`. This is inline with [Apple's recommendation not to create unadorned category methods to avoid naming clashes](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html#//apple_ref/doc/uid/TP40011210-CH6-SW4).

If you're prepared to take the risk, and prefer the shorter method names you can do so by following setting the **MR_SHORTHAND** variable before the first time you import MagicalRecord's header into your project:

 ```objective-c
#define MR_SHORTHAND 1
#import "CoreData+MagicalRecord.h"
 ```

**Please note that we do not offer support for this feature**. If it doesn't work, [please file an issue](https://github.com/magicalpanda/MagicalRecord/issues/new) and we'll fix it when we can.
