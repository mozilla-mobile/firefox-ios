//
//  ADJInitState.h
//  Adjust
//
//  Created by Pedro Filipe on 01/07/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ADJActivityHandler.h"

@interface ADJInitState : NSObject

@property (nonatomic, strong) ADJInternalState * internalState;
@property (nonatomic, assign) BOOL startsSending;
@property (nonatomic, assign) BOOL sdkClickHandlerAlsoStartsPaused;
@property (nonatomic, copy) NSString * defaultTracker;
@property (nonatomic, assign) BOOL eventBufferingIsEnabled;
@property (nonatomic, assign) BOOL sendInBackgroundConfigured;
@property (nonatomic, assign) BOOL delayStartConfigured;
@property (nonatomic, assign) BOOL updatePackages;
@property (nonatomic, assign) BOOL activityStateAlreadyCreated;
@property (nonatomic, copy) NSString * readCallbackParameters;
@property (nonatomic, copy) NSString * readPartnerParameters;
@property (nonatomic, assign) int foregroundTimerStart;
@property (nonatomic, assign) int foregroundTimerCycle;

- (id)initWithActivityHandler:(ADJActivityHandler *)activityHandler;

@end
