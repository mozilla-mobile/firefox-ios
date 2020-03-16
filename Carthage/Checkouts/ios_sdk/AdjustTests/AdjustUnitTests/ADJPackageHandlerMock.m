//
//  ADJPackageHandlerMock.m
//  Adjust
//
//  Created by Pedro Filipe on 10/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJPackageHandlerMock.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"
#import "ADJActivityHandler.h"

static NSString * const prefix = @"PackageHandler ";

@interface ADJPackageHandlerMock()

@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@property (nonatomic, assign) id<ADJActivityHandler> activityHandler;
@property (nonatomic, assign) BOOL startsSending;

@end

@implementation ADJPackageHandlerMock

- (id)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
    return [self initWithActivityHandler:nil startsSending:YES];
#pragma clang diagnostic pop
}
- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                startsSending:(BOOL)startsSending
{
    self = [super init];
    if (self == nil) return nil;

    self.startsSending = startsSending;
    self.activityHandler = activityHandler;

    self.loggerMock = (ADJLoggerMock *) ADJAdjustFactory.logger;
    self.packageQueue = [NSMutableArray array];

    [self.loggerMock test:[prefix stringByAppendingFormat:@"initWithActivityHandler, startsSending: %d", startsSending]];

    return self;
}

- (void)addPackage:(ADJActivityPackage *)package {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"addPackage %d", package.activityKind]];
    [self.packageQueue addObject:package];
}

- (void)sendFirstPackage {
    [self.loggerMock test:[prefix stringByAppendingString:@"sendFirstPackage"]];
}

- (void)sendNextPackage:(ADJResponseData *)responseData {
    [self.loggerMock test:[prefix stringByAppendingString:@"sendNextPackage"]];
}

- (void)closeFirstPackage:(ADJResponseData *)responseData
          activityPackage:(ADJActivityPackage *)activityPackage
{
    [self.loggerMock test:[prefix stringByAppendingString:@"closeFirstPackage"]];
}

- (void)pauseSending {
    [self.loggerMock test:[prefix stringByAppendingString:@"pauseSending"]];
}

- (void)resumeSending {
    [self.loggerMock test:[prefix stringByAppendingString:@"resumeSending"]];
}

- (void)updatePackages:(ADJSessionParameters *)sessionParameters {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"updatePackages, sessionParameters: %@", sessionParameters]];

}

- (void)teardown:(BOOL)deleteState {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"teardown, deleteState: %d", deleteState]];
}

@end
