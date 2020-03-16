//
//  SentryFrame.h
//  Sentry
//
//  Created by Daniel Griesser on 05/05/2017.
//  Copyright © 2017 Sentry. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<Sentry/Sentry.h>)

#import <Sentry/SentrySerializable.h>

#else
#import "SentrySerializable.h"
#endif

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Frame)
@interface SentryFrame : NSObject <SentrySerializable>

/**
 * SymbolAddress of the frame
 */
@property(nonatomic, copy) NSString *_Nullable symbolAddress;

/**
 * Filename is used only for reporting JS frames
 */
@property(nonatomic, copy) NSString *_Nullable fileName;

/**
 * Function name of the frame
 */
@property(nonatomic, copy) NSString *_Nullable function;

/**
 * Module of the frame, mostly unused
 */
@property(nonatomic, copy) NSString *_Nullable module;

/**
 * Corresponding package
 */
@property(nonatomic, copy) NSString *_Nullable package;

/**
 * ImageAddress if the image related to the frame
 */
@property(nonatomic, copy) NSString *_Nullable imageAddress;

/**
 * Set the platform for the individual frame, will use platform of the event.
 * Mostly used for react native crashes.
 */
@property(nonatomic, copy) NSString *_Nullable platform;

/**
 * InstructionAddress of the frame
 */
@property(nonatomic, copy) NSString *_Nullable instructionAddress;

/**
 * User for react native, will be ignored for cocoa frames
 */
@property(nonatomic, copy) NSNumber *_Nullable lineNumber;

/**
 * User for react native, will be ignored for cocoa frames
 */
@property(nonatomic, copy) NSNumber *_Nullable columnNumber;

- (instancetype)init;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
