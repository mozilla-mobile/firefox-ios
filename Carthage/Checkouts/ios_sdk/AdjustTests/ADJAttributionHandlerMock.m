//
//  ADJAttributionHandlerMock.m
//  adjust
//
//  Created by Pedro Filipe on 10/12/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJAttributionHandlerMock.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"

static NSString * const prefix = @"AttributionHandler ";

@interface ADJAttributionHandlerMock()

@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@property (nonatomic, assign) BOOL startsSending;
@property (nonatomic, assign) BOOL hasDelegate;

@end


@implementation ADJAttributionHandlerMock

- (id)initWithActivityHandler:(id<ADJActivityHandler>) activityHandler
       withAttributionPackage:(ADJActivityPackage *) attributionPackage
                startsSending:(BOOL)startsSending
hasAttributionChangedDelegate:(BOOL)hasDelegate
{
    self = [super init];
    if (self == nil) return nil;

    self.startsSending = startsSending;
    self.hasDelegate = hasDelegate;
    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    self.attributionPackage = attributionPackage;
    [self.loggerMock test:[prefix stringByAppendingFormat:@"initWithActivityHandler, startsSending: %d", startsSending]];

    return self;
}

- (void)checkSessionResponse:(ADJSessionResponseData *)sessionResponseData {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"checkSessionResponse, responseData: %@", sessionResponseData]];
}

- (void)checkAttributionResponse:(ADJAttributionResponseData *)attributionResponseData {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"checkAttributionResponse, responseData: %@", attributionResponseData]];
}

- (void)getAttribution {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"getAttribution"]];
}

- (void)pauseSending {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"pauseSending"]];
}

- (void)resumeSending {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"resumeSending"]];
}

- (void)teardown {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"teardown"]];
}

@end
