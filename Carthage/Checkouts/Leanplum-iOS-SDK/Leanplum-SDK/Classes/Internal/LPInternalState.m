//
//  LPInternalState.m
//  Leanplum-iOS-SDK-source
//
//  Created by Mayank Sanganeria on 4/24/18.
//

#import "LPInternalState.h"

@implementation LPInternalState

+ (LPInternalState *)sharedState {
    static LPInternalState *sharedLPInternalState = nil;
    static dispatch_once_t onceLPInternalStateToken;
    dispatch_once(&onceLPInternalStateToken, ^{
        sharedLPInternalState = [[self alloc] init];
    });
    return sharedLPInternalState;
}

- (id)init {
    if (self = [super init]) {
        _startBlocks = nil;
        _variablesChangedBlocks = nil;
        _interfaceChangedBlocks = nil;
        _eventsChangedBlocks = nil;
        _noDownloadsBlocks = nil;
        _onceNoDownloadsBlocks = nil;
        _messageDisplayedBlocks = nil;
        _actionBlocks = nil;
        _actionResponders = nil;
        _startResponders = nil;
        _variablesChangedResponders = nil;
        _interfaceChangedResponders = nil;
        _eventsChangedResponders = nil;
        _noDownloadsResponders = nil;
        _customExceptionHandler = nil;
        _registration = nil;
        _calledStart = NO;
        _hasStarted = NO;
        _hasStartedAndRegisteredAsDeveloper = NO;
        _startSuccessful = NO;
        _actionManager = nil;
        _deviceId = nil;
        _userAttributeChanges = [NSMutableArray array];
        _stripViewControllerFromState = NO;
        _isScreenTrackingEnabled = NO;
        _isInterfaceEditingEnabled = NO;
        _calledHandleNotification = NO;
    }
    return self;
}

@end
