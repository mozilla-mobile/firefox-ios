/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <SafariServices/SafariServices.h>

#import "Swizzling.h"

NSString* const FSReadingListAddReadingListItemNotification = @"FSReadingListAddReadingListItemNotification";

@interface FSReadingList: NSObject
+ (id) sharedInstance;
+ (BOOL)supportsURL:(NSURL *)URL;
- (BOOL)addReadingListItemWithURL:(NSURL *)URL title:(NSString *)title previewText:(NSString *)previewText error:(NSError **)error;
@end

@implementation FSReadingList
+ (id) sharedInstance {
    static FSReadingList *sharedFSReadingList = nil;
    @synchronized (self) {
        if (sharedFSReadingList == nil) {
            sharedFSReadingList = [FSReadingList new];
        }
    }
    return sharedFSReadingList;
}

+ (BOOL)supportsURL:(NSURL *)URL {
    return [[URL scheme] isEqualToString: @"http"] || [[URL scheme] isEqualToString: @"https"];
}

- (BOOL)addReadingListItemWithURL:(NSURL *)URL title:(NSString *)title previewText:(NSString *)previewText error:(NSError **)error {
    if (error != NULL) {
        *error = nil;
    }
    // To keep this as simple as possible and have as little as possible coupling between this Objective-C
    // singleton and our Swift world, we simply send out a notification that our AppDelegate (which has access
    // to the browser profile and reading list service) can respond to.
    [[NSNotificationCenter defaultCenter] postNotificationName: FSReadingListAddReadingListItemNotification
        object:self userInfo: @{@"URL": URL, @"Title": title}];
    return YES;
}
@end

// This class extension on SSReadingList implements an initialize method that will be called when the class
// is instantiated. It swizzles defaultReadingList to our own implementation which returns a shared instance
// of the FSReadingList. ("FirefoxServices" Reading List)

@implementation SSReadingList (Firefox)
+ (void) initialize {
    if ([SSReadingList class] == self) {
        SwizzleClassMethods([SSReadingList class], @selector(defaultReadingList), @selector(defaultFSReadingList));
    }
}

+ (id) defaultFSReadingList {
    return [FSReadingList sharedInstance];
}
@end
