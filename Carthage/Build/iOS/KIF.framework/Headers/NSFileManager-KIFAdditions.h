//
//  NSFileManager-KIFAdditions.h
//  KIF
//
//  Created by Michael Thole on 6/1/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <Foundation/Foundation.h>


@interface NSFileManager (KIFAdditions)

- (NSString *)createUserDirectory:(NSSearchPathDirectory)searchPath;
- (BOOL)recursivelyCreateDirectory:(NSString *)path;

@end
