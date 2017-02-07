//
//  KIFTypist.h
//  KIF
//
//  Created by Pete Hodgson on 8/12/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.


@interface KIFTypist : NSObject

+ (void)registerForNotifications;
+ (BOOL)keyboardHidden;
+ (BOOL)enterCharacter:(NSString *)characterString;

+ (NSTimeInterval)keystrokeDelay;
+ (void)setKeystrokeDelay:(NSTimeInterval)delay;

+ (BOOL)hasHardwareKeyboard;
+ (BOOL)hasKeyInputResponder;

@end
