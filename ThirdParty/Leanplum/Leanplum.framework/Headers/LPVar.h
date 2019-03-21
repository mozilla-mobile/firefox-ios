
//  Leanplum.h
//  Leanplum iOS SDK Version 2.0.6
//
//  Copyright (c) 2012 Leanplum, Inc. All rights reserved.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^LeanplumVariablesChangedBlock)(void);

@class LPVar;

/**
 * Receives callbacks for {@link LPVar}
 */
@protocol LPVarDelegate <NSObject>
@optional
/**
 * For file variables, called when the file is ready.
 */
- (void)fileIsReady:(LPVar *)var;
/**
 * Called when the value of the variable changes.
 */
- (void)valueDidChange:(LPVar *)var;
@end

/**
 * A variable is any part of your application that can change from an experiment.
 * Check out {@link Macros the macros} for defining variables more easily.
 */
@interface LPVar : NSObject
/**
 * @{
 * Defines a {@link LPVar}
 */

+ (LPVar *)define:(NSString *)name;
+ (LPVar *)define:(NSString *)name withInt:(int)defaultValue;
+ (LPVar *)define:(NSString *)name withFloat:(float)defaultValue;
+ (LPVar *)define:(NSString *)name withDouble:(double)defaultValue;
+ (LPVar *)define:(NSString *)name withCGFloat:(CGFloat)cgFloatValue;
+ (LPVar *)define:(NSString *)name withShort:(short)defaultValue;
+ (LPVar *)define:(NSString *)name withChar:(char)defaultValue;
+ (LPVar *)define:(NSString *)name withBool:(BOOL)defaultValue;
+ (LPVar *)define:(NSString *)name withString:(NSString *)defaultValue;
+ (LPVar *)define:(NSString *)name withNumber:(NSNumber *)defaultValue;
+ (LPVar *)define:(NSString *)name withInteger:(NSInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withLong:(long)defaultValue;
+ (LPVar *)define:(NSString *)name withLongLong:(long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedChar:(unsigned char)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInt:(unsigned int)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedInteger:(NSUInteger)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLong:(unsigned long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedLongLong:(unsigned long long)defaultValue;
+ (LPVar *)define:(NSString *)name withUnsignedShort:(unsigned short)defaultValue;
+ (LPVar *)define:(NSString *)name withFile:(NSString *)defaultFilename;
+ (LPVar *)define:(NSString *)name withDictionary:(NSDictionary *)defaultValue;
+ (LPVar *)define:(NSString *)name withArray:(NSArray *)defaultValue;
+ (LPVar *)define:(NSString *)name withColor:(UIColor *)defaultValue;
/**@}*/

/**
 * Returns the name of the variable.
 */
- (NSString *)name;

/**
 * Returns the components of the variable's name.
 */
- (NSArray *)nameComponents;

/**
 * Returns the default value of a variable.
 */
- (id)defaultValue;

/**
 * Returns the kind of the variable.
 */
- (NSString *)kind;

/**
 * Returns whether the variable has changed since the last time the app was run.
 */
- (BOOL)hasChanged;

/**
 * For file variables, called when the file is ready.
 */
- (void)onFileReady:(LeanplumVariablesChangedBlock)block;

/**
 * Called when the value of the variable changes.
 */
- (void)onValueChanged:(LeanplumVariablesChangedBlock)block;

/**
 * Sets the delegate of the variable in order to use
 * {@link LPVarDelegate::fileIsReady:} and {@link LPVarDelegate::valueDidChange:}
 */
- (void)setDelegate:(id <LPVarDelegate>)delegate;

/**
 * @{
 * Accessess the value(s) of the variable
 */
- (id)objectForKey:(NSString *)key;
- (id)objectAtIndex:(NSUInteger )index;
- (id)objectForKeyPath:(id)firstComponent, ... NS_REQUIRES_NIL_TERMINATION;
- (id)objectForKeyPathComponents:(NSArray *)pathComponents;
- (NSUInteger)count;

- (NSNumber *)numberValue;
- (NSString *)stringValue;
- (NSString *)fileValue;
- (UIImage *)imageValue;
- (int)intValue;
- (double)doubleValue;
- (CGFloat)cgFloatValue;
- (float)floatValue;
- (short)shortValue;
- (BOOL)boolValue;
- (char)charValue;
- (long)longValue;
- (long long)longLongValue;
- (NSInteger)integerValue;
- (unsigned char)unsignedCharValue;
- (unsigned short)unsignedShortValue;
- (unsigned int)unsignedIntValue;
- (NSUInteger)unsignedIntegerValue;
- (unsigned long)unsignedLongValue;
- (unsigned long long)unsignedLongLongValue;
- (UIColor *)colorValue;
/**@}*/
@end
