//
//  NSString+ADJAdditions.h
//  Adjust
//
//  Created by Christian Wellenbrock on 23.07.12.
//  Copyright (c) 2012-2014 adjust GmbH. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface NSString(ADJAdditions)

- (NSString *)adjTrim;
- (NSString *)adjUrlEncode;
- (NSString *)adjRemoveColons;

+ (NSString *)adjJoin:(NSString *)strings, ...;
+ (BOOL) adjIsEqual:(NSString *)first toString:(NSString *)second;

@end
