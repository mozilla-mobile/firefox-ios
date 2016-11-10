//
//  ADJSdkClickHandlerMock.m
//  Adjust
//
//  Created by Pedro Filipe on 02/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJSdkClickHandlerMock.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"
#import "ADJActivityPackage.h"

static NSString * const prefix = @"SdkClickHandler ";

@interface ADJSdkClickHandlerMock()

@property (nonatomic, strong) ADJLoggerMock *loggerMock;

@end

@implementation ADJSdkClickHandlerMock

- (id)initWithStartsSending:(BOOL)startsSending {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[prefix stringByAppendingFormat:@"initWithStartsSending, startsSending: %d", startsSending]];

    self.packageQueue = [NSMutableArray array];

    return self;
}

- (void)pauseSending {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"pauseSending"]];
}

- (void)resumeSending {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"resumeSending"]];
}

- (void)sendSdkClick:(ADJActivityPackage *)sdkClickPackage {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"sendSdkClick"]];
    [self.packageQueue addObject:sdkClickPackage];
}

- (void)teardown {
    [self.loggerMock test:[prefix stringByAppendingString:@"teardown"]];
}

@end
