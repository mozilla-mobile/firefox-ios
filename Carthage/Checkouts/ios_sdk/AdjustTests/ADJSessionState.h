//
//  ADJSessionState.h
//  Adjust
//
//  Created by Pedro Filipe on 10/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ADJSessionTypeSession       = 1,
    ADJSessionTypeSubSession    = 2,
    ADJSessionTypeTimeTravel    = 3,
    ADJSessionTypeNonSession    = 4
} ADJSessionType;

@interface ADJSessionState : NSObject

@property (nonatomic, assign) BOOL toSend;
//@property (nonatomic, assign) BOOL paused;
@property (nonatomic, assign) NSInteger sessionCount;
@property (nonatomic, assign) NSInteger subsessionCount;
@property (nonatomic, assign) ADJSessionType sessionType;
@property (nonatomic, assign) NSInteger eventCount;
@property (nonatomic, copy) NSNumber * getAttributionIsCalled;
@property (nonatomic, assign) BOOL timerAlreadyStarted;
@property (nonatomic, assign) BOOL eventBufferingIsEnabled;
@property (nonatomic, assign) BOOL foregroundTimerStarts;
@property (nonatomic, assign) BOOL foregroundTimerAlreadyStarted;
@property (nonatomic, assign) BOOL sendInBackgroundConfigured;
@property (nonatomic, assign) BOOL sdkClickHandlerAlsoPauses;
@property (nonatomic, copy) NSString * delayStart;
@property (nonatomic, assign) BOOL activityStateCreated;
@property (nonatomic, assign) BOOL startSubSession;


/*
boolean toSend = true;
boolean paused = false;
int sessionCount = 1;
int subsessionCount = 1;
SessionType sessionType = null;
int eventCount = 0;
Boolean getAttributionIsCalled = null;
Boolean timerAlreadyStarted = false;
boolean eventBufferingIsEnabled = false;
boolean foregroundTimerStarts = true;
boolean foregroundTimerAlreadyStarted = false;
*/

- (id)initWithSessionType:(ADJSessionType)sessionType;
+ (ADJSessionState *)sessionStateWithSessionType:(ADJSessionType)sessionType;
@end
