//
//  ADJInitState.m
//  Adjust
//
//  Created by Pedro Filipe on 01/07/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJInitState.h"

@implementation ADJInitState

- (id)initWithActivityHandler:(ADJActivityHandler *)activityHandler {
    self = [super init];
    if (self == nil) return nil;

    self.internalState = [activityHandler internalState];

    // default values
    self.startsSending = NO;
    self.sdkClickHandlerAlsoStartsPaused = YES;
    self.defaultTracker = nil;
    self.eventBufferingIsEnabled = NO;
    self.sendInBackgroundConfigured = NO;
    self.delayStartConfigured = NO;
    self.updatePackages = NO;
    self.activityStateAlreadyCreated = NO;
    self.readCallbackParameters = nil;
    self.readPartnerParameters = nil;
    self.foregroundTimerStart = 60;
    self.foregroundTimerCycle = 60;

    return self;
}

@end
