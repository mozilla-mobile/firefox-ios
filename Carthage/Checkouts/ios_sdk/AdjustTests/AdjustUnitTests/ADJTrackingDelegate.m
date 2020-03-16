//
//  ADJTrackingDelegate.m
//  Adjust
//
//  Created by Pedro Filipe on 13/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJTrackingDelegate.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"

static NSString * const succeededPrefix = @"ADJTrackingSucceededDelegate ";
static NSString * const failedPrefix = @"ADJTrackingFailedDelegate ";

@interface ADJTrackingSucceededDelegate()
@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@end

@implementation ADJTrackingSucceededDelegate

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[succeededPrefix stringByAppendingFormat:@"init"]];

    return self;
}

- (void)adjustSessionTrackingSucceeded:(ADJSessionSuccess *)sessionSuccessResponseData {
    [self.loggerMock test:[succeededPrefix stringByAppendingFormat:@"adjustSessionTrackingSucceeded, %@", sessionSuccessResponseData]];
}

- (void)adjustEventTrackingSucceeded:(ADJEventSuccess *)eventSuccessResponseData {
    [self.loggerMock test:[succeededPrefix stringByAppendingFormat:@"adjustEventTrackingSucceeded, %@", eventSuccessResponseData]];
}
@end

@interface ADJTrackingFailedDelegate()
@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@end

@implementation ADJTrackingFailedDelegate

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[failedPrefix stringByAppendingFormat:@"init"]];

    return self;
}

- (void)adjustSessionTrackingFailed:(ADJSessionFailure *)sessionFailureResponseData {
    [self.loggerMock test:[failedPrefix stringByAppendingFormat:@"adjustSessionTrackingFailed, %@", sessionFailureResponseData]];
}

- (void)adjustEventTrackingFailed:(ADJEventFailure *)eventFailureResponseData {
    [self.loggerMock test:[failedPrefix stringByAppendingFormat:@"adjustEventTrackingFailed, %@", eventFailureResponseData]];
}

@end
