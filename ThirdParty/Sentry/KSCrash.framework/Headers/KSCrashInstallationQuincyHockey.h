//
//  KSCrashInstallationQuincyHockey.h
//
//  Created by Karl Stenerud on 2013-02-10.
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
#import "KSCrashInstallation.h"
#import "KSCrashReportWriter.h"


/**
 * Common properties to both Quincy and Hockey.
 *
 * Generally, you only need to modify the value properties, not the "key" properties.
 * Any property that is set to nil won't be written to the crash report.
 *
 *
 * Key properties:
 *
 * The "key" properties specify what name the field will be stored under when
 * writing a crash report, and the value properties are the values that will
 * be written to the next crash report. The "key" properties are preset with
 * sensible defaults that you probably don't need to change.
 *
 * Using keypaths in key properties:
 *
 * Normally, "key" properties are meant to be retrieved from the "user" object at
 * the top level of the report. If you wish to retrieve the property from a different
 * part of the report, you can use keypath semantics. For example, "some_object/user_id"
 * will cause it to look in the "user" object of the report for "some_object", and then
 * inside that for "user_id".
 *
 * Using absolute keypaths will cause it to search from the report root. For
 * example, "/system/system_name" will look in the "system" object of the report for
 * "system_name".
 *
 * Note: The installation is incapable of storing directly to a keypath, so for
 *       any property that uses keypaths, you must manually store the value to
 *       the report using the custom onCrash callback.
 *
 * This is an abstract class.
 */
@interface KSCrashInstallationBaseQuincyHockey : KSCrashInstallation

// ======================================================================
#pragma mark - Basic properties (nil by default) -
// ======================================================================

// The values of these properties will be written to the next crash report.

@property(nonatomic,readwrite,retain) NSString* userID;
@property(nonatomic,readwrite,retain) NSString* userName;
@property(nonatomic,readwrite,retain) NSString* contactEmail;
@property(nonatomic,readwrite,retain) NSString* crashDescription;


// ======================================================================
#pragma mark - Advanced settings (normally you don't need to change these) -
// ======================================================================

// The above properties will be written to the user section report using the
// following keys.

@property(nonatomic,readwrite,retain) NSString* userIDKey;
@property(nonatomic,readwrite,retain) NSString* userNameKey;
@property(nonatomic,readwrite,retain) NSString* contactEmailKey;
@property(nonatomic,readwrite,retain) NSString* crashDescriptionKey;

/** Data stored under these keys will be appended to the description
 * (in JSON format) before sending to Quincy/Hockey.
 */
@property(nonatomic,readwrite,retain) NSArray* extraDescriptionKeys;

/** If YES, wait until the host becomes reachable before trying to send.
 * If NO, it will attempt to send right away, and either succeed or fail.
 *
 * Default: YES
 */
@property(nonatomic,readwrite,assign) BOOL waitUntilReachable;

@end


/**
 * Quincy installation.
 */
@interface KSCrashInstallationQuincy : KSCrashInstallationBaseQuincyHockey

/** URL to send reports to (mandatory) */
@property(nonatomic, readwrite, retain) NSURL* url;

+ (KSCrashInstallationQuincy*) sharedInstance;

@end


/**
 * Hockey installation.
 */
@interface KSCrashInstallationHockey: KSCrashInstallationBaseQuincyHockey

/** App identifier you received from Hockey (mandatory) */
@property(nonatomic, readwrite, retain) NSString* appIdentifier;

+ (instancetype) sharedInstance;

@end
