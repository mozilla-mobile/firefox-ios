//
//  ADJSessionState.m
//  Adjust
//
//  Created by Pedro Filipe on 10/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJSessionState.h"

@implementation ADJSessionState


- (id)initWithSessionType:(ADJSessionType)sessionType {
    self = [super init];
    if (self == nil) return nil;

    // default values
    self.toSend = NO;
    self.sessionCount = 1;
    self.subsessionCount = 1;
    self.eventCount = 0;
    self.getAttributionIsCalled = nil;
    self.timerAlreadyStarted = NO;
    self.eventBufferingIsEnabled = NO;
    self.foregroundTimerStarts = YES;
    self.foregroundTimerAlreadyStarted = NO;
    self.sdkClickHandlerAlsoPauses = YES;
    self.delayStart = nil;
    self.activityStateCreated = NO;
    self.startSubSession = YES;
/*
    if (sessionType == ADJSessionTypeSubSession ||
        sessionType == ADJSessionTypeNonSession)
    {
        self.timerAlreadyStarted = YES;
        self.toSend = YES;
    }
*/
    self.sessionType = sessionType;

    return self;
}

+ (ADJSessionState *)sessionStateWithSessionType:(ADJSessionType)sessionType {
    return [[ADJSessionState alloc] initWithSessionType:sessionType];
}

@end
