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
@property (nonatomic, assign) BOOL startPaused;

@end

@implementation ADJPackageHandlerMock

- (id)init {
    return [self initWithActivityHandler:nil startPaused:NO];
}
- (id)initWithActivityHandler:(id<ADJActivityHandler>)activityHandler
                  startPaused:(BOOL)startPaused
{
    self = [super init];
    if (self == nil) return nil;

    self.startPaused = startPaused;
    self.activityHandler = activityHandler;

    self.loggerMock = (ADJLoggerMock *) ADJAdjustFactory.logger;
    self.packageQueue = [NSMutableArray array];

    [self.loggerMock test:[NSString stringWithFormat:@"%@initWithActivityHandler, paused: %d", prefix, startPaused]];

    return self;
}

- (void)addPackage:(ADJActivityPackage *)package {
    [self.loggerMock test:[prefix stringByAppendingString:@"addPackage"]];
    [self.packageQueue addObject:package];
}

- (void)sendFirstPackage {
    [self.loggerMock test:[prefix stringByAppendingString:@"sendFirstPackage"]];
}

- (void)sendNextPackage {
    [self.loggerMock test:[prefix stringByAppendingString:@"sendNextPackage"]];
}

- (void)closeFirstPackage {
    [self.loggerMock test:[prefix stringByAppendingString:@"closeFirstPackage"]];
}

- (void)pauseSending {
    [self.loggerMock test:[prefix stringByAppendingString:@"pauseSending"]];
}

- (void)resumeSending {
    [self.loggerMock test:[prefix stringByAppendingString:@"resumeSending"]];
}

- (void)finishedTracking:(NSDictionary *)jsonDict {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"finishedTracking, %@", jsonDict.descriptionInStringsFileFormat]];
    self.jsonDict = jsonDict;
}

@end
