//
//  LPInternalState.h
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import <Foundation/Foundation.h>
#import "LPRegisterDevice.h"
#import "LPActionManager.h"

@interface LPInternalState : NSObject

@property(strong, nonatomic) NSMutableArray *startBlocks, *variablesChangedBlocks,
*interfaceChangedBlocks, *eventsChangedBlocks, *noDownloadsBlocks, *onceNoDownloadsBlocks,
*startIssuedBlocks, *messageDisplayedBlocks;
@property(strong, nonatomic) NSMutableDictionary *actionBlocks, *actionResponders;
@property(strong, nonatomic) NSMutableSet *startResponders, *variablesChangedResponders,
*interfaceChangedResponders, *eventsChangedResponders, *noDownloadsResponders;
@property(assign, nonatomic) NSUncaughtExceptionHandler *customExceptionHandler;
@property(strong, nonatomic) LPRegisterDevice *registration;
@property(assign, nonatomic) BOOL calledStart, hasStarted, hasStartedAndRegisteredAsDeveloper,
startSuccessful, issuedStart, stripViewControllerFromState;
@property(strong, nonatomic) LPActionManager *actionManager;
@property(strong, nonatomic) NSString *deviceId;
@property(strong, nonatomic) NSString *appVersion;
@property(strong, nonatomic) NSMutableArray *userAttributeChanges;
@property(assign, nonatomic) BOOL isScreenTrackingEnabled;
@property(assign, nonatomic) BOOL isVariantDebugInfoEnabled;
@property(assign, nonatomic) BOOL isInterfaceEditingEnabled;
@property(assign, nonatomic) BOOL calledHandleNotification;

+ (LPInternalState *)sharedState;

@end
