//
//  ADJDeeplinkDelegate.m
//  Adjust
//
//  Created by Pedro Filipe on 13/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJDeeplinkDelegate.h"
#import "ADJLoggerMock.h"
#import "ADJAdjustFactory.h"

static NSString * const launchPrefix = @"ADJDeeplinkLaunchDelegate ";
static NSString * const notLaunchPrefix = @"ADJDeeplinkNotLaunchDelegate ";

@interface ADJDeeplinkLaunchDelegate()
@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@end

@implementation ADJDeeplinkLaunchDelegate

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[launchPrefix stringByAppendingFormat:@"init"]];

    return self;
}

- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    [self.loggerMock test:[launchPrefix stringByAppendingFormat:@"adjustDeeplinkResponse launch, %@", deeplink]];
    return YES;
}

@end

@interface ADJDeeplinkNotLaunchDelegate()
@property (nonatomic, strong) ADJLoggerMock *loggerMock;
@end

@implementation ADJDeeplinkNotLaunchDelegate

- (id) init {
    self = [super init];
    if (self == nil) return nil;

    self.loggerMock = (ADJLoggerMock *) [ADJAdjustFactory logger];

    [self.loggerMock test:[notLaunchPrefix stringByAppendingFormat:@"init"]];

    return self;
}

- (BOOL)adjustDeeplinkResponse:(NSURL *)deeplink {
    [self.loggerMock test:[notLaunchPrefix stringByAppendingFormat:@"adjustDeeplinkResponse not launch, %@", deeplink]];
    return NO;
}

@end