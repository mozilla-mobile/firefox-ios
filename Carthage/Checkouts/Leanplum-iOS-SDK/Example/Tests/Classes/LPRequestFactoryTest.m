//
//  LPRequestFactoryTest.m
//  Leanplum-SDK_Tests
//
//  Created by Grace on 10/8/18.
//  Copyright © 2018 Leanplum. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Leanplum/LPRequestFactory.h>
#import <Leanplum/LeanplumRequest.h>
#import <Leanplum/LPRequest.h>

NSString *LP_API_METHOD_START = @"start";
NSString *LP_API_METHOD_GET_VARS = @"getVars";
NSString *LP_API_METHOD_SET_VARS = @"setVars";
NSString *LP_API_METHOD_STOP = @"stop";
NSString *LP_API_METHOD_RESTART = @"restart";
NSString *LP_API_METHOD_TRACK = @"track";
NSString *LP_API_METHOD_ADVANCE = @"advance";
NSString *LP_API_METHOD_PAUSE_SESSION = @"pauseSession";
NSString *LP_API_METHOD_PAUSE_STATE = @"pauseState";
NSString *LP_API_METHOD_RESUME_SESSION = @"resumeSession";
NSString *LP_API_METHOD_RESUME_STATE = @"resumeState";
NSString *LP_API_METHOD_MULTI = @"multi";
NSString *LP_API_METHOD_REGISTER_FOR_DEVELOPMENT = @"registerDevice";
NSString *LP_API_METHOD_SET_USER_ATTRIBUTES = @"setUserAttributes";
NSString *LP_API_METHOD_SET_DEVICE_ATTRIBUTES = @"setDeviceAttributes";
NSString *LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO = @"setTrafficSourceInfo";
NSString *LP_API_METHOD_UPLOAD_FILE = @"uploadFile";
NSString *LP_API_METHOD_DOWNLOAD_FILE = @"downloadFile";
NSString *LP_API_METHOD_HEARTBEAT = @"heartbeat";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION = @"saveInterface";
NSString *LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE = @"saveInterfaceImage";
NSString *LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST = @"getViewControllerVersionsList";
NSString *LP_API_METHOD_LOG = @"log";
NSString *LP_API_METHOD_GET_INBOX_MESSAGES = @"getNewsfeedMessages";
NSString *LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ = @"markNewsfeedMessageAsRead";
NSString *LP_API_METHOD_DELETE_INBOX_MESSAGE = @"deleteNewsfeedMessage";

@interface LPRequestFactory(UnitTest)

@property (nonatomic, strong) LPFeatureFlagManager *featureFlagManager;

- (id<LPRequesting>)createGetForApiMethod:(NSString *)apiMethod params:(nullable NSDictionary *)params;
- (id<LPRequesting>)createPostForApiMethod:(NSString *)apiMethod params:(nullable NSDictionary *)params;
- (BOOL)shouldReturnLPRequestClass;

@end

@interface LPRequestFactoryTest : XCTestCase

@end

@implementation LPRequestFactoryTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testCreateGetForApiMethodLPRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LPRequestMock = OCMClassMock([LPRequest class]);
    reqFactory.featureFlagManager = OCMClassMock([LPFeatureFlagManager class]);
    OCMStub([reqFactory.featureFlagManager isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]).andReturn(true);
    NSString *apiMethod = @"test";
    
    [reqFactory createGetForApiMethod:apiMethod params:nil];
    
    OCMVerify([LPRequestMock get:apiMethod params:nil]);
}

- (void)testCreateGetForApiMethodLeanplumRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LeanplumRequestMock = OCMClassMock([LeanplumRequest class]);
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createGetForApiMethod:apiMethod params:nil];
    
    OCMVerify([LeanplumRequestMock get:apiMethod params:nil]);
}

- (void)testCreatePostForApiMethodLPRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LPRequestMock = OCMClassMock([LPRequest class]);
    reqFactory.featureFlagManager = OCMClassMock([LPFeatureFlagManager class]);
    OCMStub([reqFactory.featureFlagManager isFeatureFlagEnabled:LP_FEATURE_FLAG_REQUEST_REFACTOR]).andReturn(true);
    
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createPostForApiMethod:apiMethod params:nil];
    
    OCMVerify([LPRequestMock post:apiMethod params:nil]);
}

- (void)testCreatePostForApiMethodLeanplumRequest {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id LeanplumRequestMock = OCMClassMock([LeanplumRequest class]);
    
    NSString *apiMethod = @"ApiMethod";
    
    [reqFactory createPostForApiMethod:apiMethod params:nil];
    
    OCMVerify([LeanplumRequestMock post:apiMethod params:nil]);
}

- (void)testStartWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory startWithParams:nil];
 
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_START params:nil]);
}

- (void)testGetVarsWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getVarsWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_VARS params:nil]);
}

- (void)testSetVarsWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setVarsWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_VARS params:nil]);
}

- (void)testStopWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory stopWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_STOP params:nil]);
}

- (void)testRestartWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory restartWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESTART params:nil]);
}

- (void)testTrackWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory trackWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_TRACK params:nil]);
}

- (void)testAdvanceWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory advanceWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_ADVANCE params:nil]);
}

- (void)testPauseSessionWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory pauseSessionWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_PAUSE_SESSION params:nil]);
}

- (void)testPauseStateWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory pauseStateWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_PAUSE_STATE params:nil]);
}

- (void)testResumeSessionWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory resumeSessionWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESUME_SESSION params:nil]);
}

- (void)testResumeStateWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory resumeStateWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_RESUME_STATE params:nil]);
}

- (void)testMultiWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory multiWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_MULTI params:nil]);
}

- (void)testRegisterDeviceWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory registerDeviceWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_REGISTER_FOR_DEVELOPMENT params:nil]);
}

- (void)testSetUserAttributesWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setUserAttributesWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_USER_ATTRIBUTES params:nil]);
}

- (void)testSetDeviceAttributesWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setDeviceAttributesWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_DEVICE_ATTRIBUTES params:nil]);
}

- (void)testSetTrafficSourceInfoWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory setTrafficSourceInfoWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SET_TRAFFIC_SOURCE_INFO params:nil]);
}

- (void)testUploadFileWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory uploadFileWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_UPLOAD_FILE params:nil]);
}

- (void)testDownloadFileWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory downloadFileWithParams:nil];
    
    OCMVerify([reqFactoryMock createGetForApiMethod:LP_API_METHOD_DOWNLOAD_FILE params:nil]);
}

- (void)testHeartbeatWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory heartbeatWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_HEARTBEAT params:nil]);
}

- (void)testSaveInterfaceWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory saveInterfaceWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_VERSION params:nil]);
}

- (void)testSaveInterfaceImageWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory saveInterfaceImageWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_SAVE_VIEW_CONTROLLER_IMAGE params:nil]);
}

- (void)testGetViewControllerVersionsListWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getViewControllerVersionsListWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_VIEW_CONTROLLER_VERSIONS_LIST params:nil]);
}

- (void)testLogWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory logWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_LOG params:nil]);
}

- (void)testGetNewsfeedMessagesWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory getNewsfeedMessagesWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_GET_INBOX_MESSAGES params:nil]);
}

- (void)testMarkNewsfeedMessageAsReadWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory markNewsfeedMessageAsReadWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_MARK_INBOX_MESSAGE_AS_READ params:nil]);
}

- (void)testDeleteNewsfeedMessageWithParams {
    LPFeatureFlagManager *featureFlagManager = [[LPFeatureFlagManager alloc] init];
    LPRequestFactory *reqFactory = [[LPRequestFactory alloc]
                                    initWithFeatureFlagManager:featureFlagManager];
    id reqFactoryMock = OCMPartialMock(reqFactory);
    [reqFactory deleteNewsfeedMessageWithParams:nil];
    
    OCMVerify([reqFactoryMock createPostForApiMethod:LP_API_METHOD_DELETE_INBOX_MESSAGE params:nil]);
}

@end

