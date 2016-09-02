//
//  ADJRequestHandlerMock.m
//  Adjust
//
//  Created by Pedro Filipe on 10/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import "ADJRequestHandlerMock.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"

static NSString * const prefix = @"RequestHandler ";

@interface ADJRequestHandlerMock()

@property (nonatomic, assign) id<ADJPackageHandler> packageHandler;
@property (nonatomic, assign) ADJLoggerMock *loggerMock;

@end

@implementation ADJRequestHandlerMock

- (id)initWithPackageHandler:(id<ADJPackageHandler>) packageHandler {
    self = [super init];
    if (self == nil) return nil;

    self.packageHandler = packageHandler;
    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[prefix stringByAppendingString:@"initWithPackageHandler"]];

    self.connectionError = NO;

    return self;
}

- (void)sendPackage:(ADJActivityPackage *)activityPackage {
    [self.loggerMock test:[prefix stringByAppendingFormat:@"sendPackage, %@", activityPackage]];

    /*
    NSDictionary *jsonDict;

    if (self.connectionError) {
        jsonDict = nil;
    } else {
        jsonDict = @{@"tracker_token": @"token",@"tracker_name":@"name"};
    }

    [self.packageHandler finishedTrackingActivity:jsonDict];

    if (self.connectionError) {
        [self.packageHandler closeFirstPackage];
    } else {
        [self.packageHandler sendNextPackage];
    }
     */
}

@end
