//
//  SentryCrashExceptionApplication.h
//  Sentry
//
//  Created by Daniel Griesser on 31.08.17.
//  Copyright © 2017 Sentry. All rights reserved.
//

#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
@interface SentryCrashExceptionApplication : NSApplication
#else
#import <Foundation/Foundation.h>
@interface SentryCrashExceptionApplication : NSObject
#endif

@end
