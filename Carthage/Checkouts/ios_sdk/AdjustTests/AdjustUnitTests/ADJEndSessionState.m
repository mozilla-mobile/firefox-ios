//
//  ADJEndSessionState.m
//  Adjust
//
//  Created by Pedro Filipe on 30/06/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "ADJEndSessionState.h"

@implementation ADJEndSessionState

- (id)init {
    self = [super init];
    if (self == nil) return nil;

    // default values
    self.pausing = YES;
    self.updateActivityState = YES;
    self.eventBufferingEnabled = NO;
    self.checkOnPause = NO;
    self.forgroundAlreadySuspended = NO;
    self.backgroundTimerStarts = NO;

    return self;
}
@end
