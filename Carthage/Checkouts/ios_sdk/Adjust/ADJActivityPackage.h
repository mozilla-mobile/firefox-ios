//
//  ADJActivityPackage.h
//  Adjust
//
//  Created by Christian Wellenbrock on 2013-07-03.
//  Copyright (c) 2013 adjust GmbH. All rights reserved.
//

#import "ADJActivityKind.h"

@interface ADJActivityPackage : NSObject <NSCoding>

// data
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *clientSdk;
@property (nonatomic, strong) NSMutableDictionary *parameters;

@property (nonatomic, assign) NSInteger retries;

@property (nonatomic, strong) NSDictionary *callbackParameters;
@property (nonatomic, strong) NSDictionary *partnerParameters;

// logs
@property (nonatomic, assign) ADJActivityKind activityKind;
@property (nonatomic, copy) NSString *suffix;

- (NSString *)extendedString;
- (NSString *)successMessage;
- (NSString *)failureMessage;

- (NSInteger)getRetries;
- (NSInteger)increaseRetries;

@end
