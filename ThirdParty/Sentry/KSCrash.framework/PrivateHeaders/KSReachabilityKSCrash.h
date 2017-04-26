//
//  KSReachability.h
//
//  Created by Karl Stenerud on 2012-05-05.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import <Foundation/Foundation.h>
#import "KSSystemCapabilities.h"
#if KSCRASH_HAS_REACHABILITY
#import <SystemConfiguration/SystemConfiguration.h>
#endif

/** This is the notification name used in the Apple reachability example. */
#define kDefaultNetworkReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"


/** Monitors network connectivity.
 *
 * Note: Upon construction, this object will fetch its initial reachability
 * state in the background. This means that the reachability status will ALWAYS
 * be "unreachable" until some time after object construction. If you want
 * the true reachability state before the current code block ends, you can call
 * updateFlags. Note, however, that it will probably block.
 *
 * You can elect to be notified via blocks (onReachabilityChanged),
 * notifications (notificationName), or KVO (flags, reachable, and WWANOnly).
 *
 * All notification methods are disabled by default.
 */
@interface KSReachabilityKSCrash : NSObject

#pragma mark Constructors

/** Reachability to a specific host.
 *
 * @param hostname The name or IP address of the host to monitor. If nil or
 *                 empty string, check reachability to the internet in general.
 */
+ (KSReachabilityKSCrash*) reachabilityToHost:(NSString*) hostname;

/** Reachability to the local (wired or wifi) network.
 */
+ (KSReachabilityKSCrash*) reachabilityToLocalNetwork;


#pragma mark General Information

/** The host we are monitoring reachability to, if any. */
@property(nonatomic,readonly,retain) NSString* hostname;


#pragma mark Notifications and Callbacks

/** If non-nil, called whenever reachability flags change.
 * Block will be invoked on the main thread.
 */
@property(nonatomic,readwrite,copy) void(^onReachabilityChanged)(KSReachabilityKSCrash* reachability);

/** The notification to send when reachability changes (nil = don't send).
 * Default = nil
 */
@property(nonatomic,readwrite,retain) NSString* notificationName;


#pragma mark KVO Compliant Status Properties

/** The current reachability flags. */
#if KSCRASH_HAS_REACHABILITY
@property(nonatomic,readonly,assign) SCNetworkReachabilityFlags flags;
#endif

/** Whether the host is reachable or not. */
@property(nonatomic,readonly,assign) BOOL reachable;

/* If YES, the host is only reachable by WWAN (iOS only). */
@property(nonatomic,readonly,assign) BOOL WWANOnly;


#pragma mark Utility

/** Force updating of the reachability flags.
 * This method will potentially block.
 *
 * @return YES if the flags were successfully updated.
 */
- (BOOL) updateFlags;

@end



/** A one-time operation to perform as soon as a host is deemed reachable.
 * The operation will only be performed once, regardless of how many times a
 * host becomes reachable.
 */
@interface KSReachableOperationKSCrash: NSObject

/** Constructor.
 *
 * @param hostname The name or IP address of the host to monitor. If nil or
 *                 empty string, check reachability to the internet in general.
 *                 If hostname is a URL string, it will use the host portion.
 *
 * @param allowWWAN If NO, a WWAN-only connection is not enough to trigger
 *                  this operation.
 *
 * @param block The block to invoke when the host becomes reachable.
 *              Block will be invoked on the main thread.
 */
+ (KSReachableOperationKSCrash*) operationWithHost:(NSString*) hostname
                                         allowWWAN:(BOOL) allowWWAN
                                             block:(void(^)()) block;

/** Constructor.
 *
 * @param hostname The name or IP address of the host to monitor. If nil or
 *                 empty string, check reachability to the internet in general.
 *                 If hostname is a URL string, it will use the host portion.
 *
 * @param allowWWAN If NO, a WWAN-only connection is not enough to trigger
 *                  this operation.
 *
 * @param block The block to invoke when the host becomes reachable.
 *              Block will be invoked on the main thread.
 */
- (id) initWithHost:(NSString*) hostname
          allowWWAN:(BOOL) allowWWAN
              block:(void(^)()) block;

@end
