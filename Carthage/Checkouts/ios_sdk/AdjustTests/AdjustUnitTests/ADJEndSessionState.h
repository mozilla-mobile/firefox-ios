//
//  ADJEndSessionState.h
//  Adjust
//
//  Created by Pedro Filipe on 30/06/2016.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ADJEndSessionState : NSObject

@property (nonatomic, assign) BOOL pausing;
@property (nonatomic, assign) BOOL updateActivityState;
@property (nonatomic, assign) BOOL eventBufferingEnabled;
@property (nonatomic, assign) BOOL checkOnPause;
@property (nonatomic, assign) BOOL forgroundAlreadySuspended;
@property (nonatomic, assign) BOOL backgroundTimerStarts;
@end
