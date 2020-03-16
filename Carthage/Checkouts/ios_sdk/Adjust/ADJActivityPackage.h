//
//  ADJActivityPackage.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityKind.h"

@interface ADJActivityPackage : NSObject <NSCoding>

// Data

@property (nonatomic, copy) NSString *path;

@property (nonatomic, copy) NSString *clientSdk;

@property (nonatomic, assign) NSInteger retries;

@property (nonatomic, strong) NSMutableDictionary *parameters;

@property (nonatomic, strong) NSDictionary *partnerParameters;

@property (nonatomic, strong) NSDictionary *callbackParameters;

// Logs

@property (nonatomic, copy) NSString *suffix;

@property (nonatomic, assign) ADJActivityKind activityKind;

- (NSString *)extendedString;

- (NSString *)successMessage;

- (NSString *)failureMessage;

- (NSInteger)getRetries;

- (NSInteger)increaseRetries;

@end
