//
//  ADJActivityHandlerTests.m
//  Adjust
//
//  Created by Pedro Filipe on 07/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ADJLoggerMock.h"
#import "ADJPackageHandlerMock.h"
#import "ADJAdjustFactory.h"
#import "ADJActivityHandler.h"
#import "ADJActivityPackage.h"
#import "ADJTestsUtil.h"
#import "ADJUtil.h"
#import "ADJLogger.h"
#import "ADJAttributionHandlerMock.h"
#import "ADJConfig.h"
#import "ADJAttributionChangedDelegate.h"
#import "ADJTestActivityPackage.h"
#import "ADJTrackingDelegate.h"
#import "ADJSdkClickHandlerMock.h"
#import "ADJSessionState.h"
#import "ADJDeeplinkDelegate.h"
#import "ADJActivityHandlerConstructorState.h"
#import "ADJEndSessionState.h"
#import "ADJInitState.h"

@interface ADJActivityHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJPackageHandlerMock *packageHandlerMock;
@property (atomic,strong) ADJAttributionHandlerMock *attributionHandlerMock;
@property (atomic,strong) ADJSdkClickHandlerMock * sdkClickHandlerMock;

@end

@implementation ADJActivityHandlerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.

    // check the server url
    XCTAssertEqual(@"https://app.adjust.com", ADJUtil.baseUrl);
}

- (void)tearDown
{
    [ADJAdjustFactory setTesting:NO];
    [ADJAdjustFactory setPackageHandler:nil];
    [ADJAdjustFactory setSdkClickHandler:nil];
    [ADJAdjustFactory setLogger:nil];
    [ADJAdjustFactory setSessionInterval:-1];
    [ADJAdjustFactory setSubsessionInterval:-1];
    [ADJAdjustFactory setTimerInterval:-1];
    [ADJAdjustFactory setTimerStart:-1];
    [ADJAdjustFactory setAttributionHandler:nil];
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)reset {
    [ADJAdjustFactory setTesting:YES];

    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    self.packageHandlerMock = [ADJPackageHandlerMock alloc];
    [ADJAdjustFactory setPackageHandler:self.packageHandlerMock];
    self.sdkClickHandlerMock = [ADJSdkClickHandlerMock alloc];
    [ADJAdjustFactory setSdkClickHandler:self.sdkClickHandlerMock];

    [ADJAdjustFactory setSessionInterval:-1];
    [ADJAdjustFactory setSubsessionInterval:-1];
    [ADJAdjustFactory setTimerInterval:-1];
    [ADJAdjustFactory setTimerStart:-1];

    self.attributionHandlerMock = [ADJAttributionHandlerMock alloc];
    [ADJAdjustFactory setAttributionHandler:self.attributionHandlerMock];

    // starting from a clean slate
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoActivityState" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoAttribution" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustSessionParameters" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustSessionCallbackParameters" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustSessionPartnerParameters" logger:self.loggerMock], @"%@", self.loggerMock);
}

- (void)testFirstSession
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  create handler and start the first session
    [self startAndCheckFirstSession:config];

    // checking the default values of the first session package
    //  should only have one package
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    ADJActivityPackage *activityPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * fields = [ADJPackageFields fields];

    // set first session
    [self testPackageSession:activityPackage fields:fields sessionCount:@"1"];
}

- (void)testEventBuffered
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // buffer events
    config.eventBufferingEnabled = YES;

    // set default tracker
    [config setDefaultTracker:@"default1234tracker"];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.eventBufferingIsEnabled = YES;
    initState.defaultTracker = @"default1234tracker";

    ADJSessionState * sessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    sessionState.eventBufferingIsEnabled = YES;

    [self checkInitAndStart:initState sessionState:sessionState];

    // create the first Event object with callback and partner parameters
    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"event1"];

    // add callback parameters
    [firstEvent addCallbackParameter:@"keyCall" value:@"valueCall"];
    [firstEvent addCallbackParameter:@"keyCall" value:@"valueCall2"];
    [firstEvent addCallbackParameter:@"fooCall" value:@"barCall"];

    // add partner paramters
    [firstEvent addPartnerParameter:@"keyPartner" value:@"valuePartner"];
    [firstEvent addPartnerParameter:@"keyPartner" value:@"valuePartner2"];
    [firstEvent addPartnerParameter:@"fooPartner" value:@"barPartner"];

    // check that callback parameter was overwritten
    aWarn(@"key keyCall was overwritten");

    // check that partner parameter was overwritten
    aWarn(@"key keyPartner was overwritten");

    // add revenue
    [firstEvent setRevenue:0.001 currency:@"EUR"];

    // set transaction id
    [firstEvent setReceipt:[[NSData alloc] init] transactionId:@"t_id_1"];

    // track the first event
    [activityHandler trackEvent:firstEvent];

    [NSThread sleepForTimeInterval:2];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was buffered
    aInfo(@"Buffered event (0.00100 EUR, 'event1')");

    // and not sent to package handler
    anTest(@"PackageHandler sendFirstPackage");

    // does not fire background timer
    anVerbose(@"Background timer starting");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:1");

    // create a second Event object to be discarded with duplicated transaction id
    ADJEvent * secondEvent = [ADJEvent eventWithEventToken:@"event2"];

    // set the same id
    [secondEvent setTransactionId:@"t_id_1"];

    // track the second event
    [activityHandler trackEvent:secondEvent];

    [NSThread sleepForTimeInterval:2];

    // dropping duplicate transaction id
    aInfo(@"Skipping duplicate transaction ID 't_id_1'");

    aVerbose(@"Found transaction ID in (");

    // create a third Event object with receipt
    ADJEvent * thirdEvent = [ADJEvent eventWithEventToken:@"event3"];

    // add revenue
    [thirdEvent setRevenue:0 currency:@"USD"];

    // add receipt information
    [thirdEvent setReceipt:[@"{ \"transaction-id\" = \"t_id_2\"; }" dataUsingEncoding:NSUTF8StringEncoding] transactionId:@"t_id_2"];

    // track the third event
    [activityHandler trackEvent:thirdEvent];

    [NSThread sleepForTimeInterval:2];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was buffered
    aInfo(@"Buffered event (0.00000 USD, 'event3')");

    // and not sent to package handler
    anTest(@"PackageHandler sendFirstPackage");

    // does not fire background timer
    anVerbose(@"Background timer starting");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:2");

    // create a forth Event object without revenue
    ADJEvent * forthEvent = [ADJEvent eventWithEventToken:@"event4"];

    // track the forth event
    [activityHandler trackEvent:forthEvent];

    [NSThread sleepForTimeInterval:2];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was buffered
    aInfo(@"Buffered event 'event4'");

    // and not sent to package handler
    anTest(@"PackageHandler sendFirstPackage");

    // does not fire background timer
    anVerbose(@"Background timer starting");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:3");

    // check the number of activity packages
    // 1 session + 3 events
    aiEquals(4, (int)[self.packageHandlerMock.packageQueue count]);

    // get the session package
    ADJActivityPackage *sessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * firstSessionPackageFields = [ADJPackageFields fields];

    firstSessionPackageFields.defaultTracker = @"default1234tracker";
    firstSessionPackageFields.eventBufferingEnabled = 1;

    // test first session
    [self testPackageSession:sessionPackage fields:firstSessionPackageFields sessionCount:@"1"];

    // get the first event
    ADJActivityPackage * firstEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create event package test
    ADJPackageFields * firstPackageFields = [ADJPackageFields fields];

    // set event test parameters
    firstPackageFields.eventCount = @"1";
    firstPackageFields.revenue = @"0.00100";
    firstPackageFields.currency = @"EUR";
    firstPackageFields.callbackParameters = @"{\"keyCall\":\"valueCall2\",\"fooCall\":\"barCall\"}";
    firstPackageFields.partnerParameters = @"{\"keyPartner\":\"valuePartner2\",\"fooPartner\":\"barPartner\"}";
    firstPackageFields.suffix = @"(0.00100 EUR, 'event1')";
    firstPackageFields.eventBufferingEnabled = 1;

    // test first event
    [self testEventPackage:firstEventPackage fields:firstPackageFields eventToken:@"event1"];

    // third event
    ADJActivityPackage * thirdEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[2];

    // create event package test
    ADJPackageFields * thirdPackageFields = [ADJPackageFields fields];

    // set event test parameters
    thirdPackageFields.eventCount = @"2";
    thirdPackageFields.revenue = @"0.00000";
    thirdPackageFields.currency = @"USD";
    thirdPackageFields.suffix = @"(0.00000 USD, 'event3')";
    thirdPackageFields.receipt = @"eyAidHJhbnNhY3Rpb24taWQiID0gInRfaWRfMiI7IH0";
    thirdPackageFields.eventBufferingEnabled = 1;

    // test third event
    [self testEventPackage:thirdEventPackage fields:thirdPackageFields eventToken:@"event3"];

    // fourth event
    ADJActivityPackage * fourthEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[3];

    // create event package test
    ADJPackageFields * fourthPackageFields = [ADJPackageFields fields];

    // set event test parameters
    fourthPackageFields.eventCount = @"3";
    fourthPackageFields.suffix = @"'event4'";
    fourthPackageFields.eventBufferingEnabled = 1;

    // test fourth event
    [self testEventPackage:fourthEventPackage fields:fourthPackageFields eventToken:@"event4"];
}

- (void)testEventsNotBuffered
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // create the first Event
    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"event1"];

    // track event
    [activityHandler trackEvent:firstEvent];

    [NSThread sleepForTimeInterval:2];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was sent to package handler
    aTest(@"PackageHandler sendFirstPackage");

    // and not buffered
    anInfo(@"Buffered event");

    // does not fire background timer
    anVerbose(@"Background timer starting");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state");
}

- (void)testEventBeforeStart {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // create the first Event
    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"event1"];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    // track event
    [activityHandler trackEvent:firstEvent];

    [NSThread sleepForTimeInterval:2];

    // test session
    ADJSessionState * sessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    // does not start until it goes to foreground
    sessionState.foregroundTimerStarts = NO;
    sessionState.toSend = NO;
    sessionState.startSubSession = NO;

    // XXX
    // test init values
    [self checkInitAndStartTestsWithHandler:activityHandler];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was sent to package handler
    aTest(@"PackageHandler sendFirstPackage");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:1 sc:1 ssc:1");
}

- (void)testChecks
{
    //  reseting to make the test order independent
    [self reset];

    // create the config with null app token
    ADJConfig * nilAppTokenConfig = [ADJConfig configWithAppToken:nil environment:ADJEnvironmentSandbox];

    aError(@"Missing App Token");
    aFalse(nilAppTokenConfig.isValid);

    // config with wrong size app token
    ADJConfig * sizeAppTokenConfig = [ADJConfig configWithAppToken:@"1234567890123" environment:ADJEnvironmentSandbox];

    aError(@"Malformed App Token '1234567890123'");
    aFalse(sizeAppTokenConfig.isValid);

    // config with null environment
    ADJConfig * nilEnvironmentConfig = [ADJConfig configWithAppToken:@"123456789012" environment:nil];

    aError(@"Missing environment");
    aFalse(nilEnvironmentConfig.isValid);

    // create the config with environment not standart
    ADJConfig * wrongEnvironmentConfig = [ADJConfig configWithAppToken:@"123456789012" environment:@"Other"];

    aError(@"Unknown environment 'Other'");
    aFalse(wrongEnvironmentConfig.isValid);

    // activity handler created with a nil config
    id<ADJActivityHandler> nilConfigActivityHandler = [ADJActivityHandler handlerWithConfig:nil
                                                              sessionParametersActionsArray:nil];

    aError(@"AdjustConfig missing");
    aNil(nilConfigActivityHandler);

    // activity handler created with an invalid config
    id<ADJActivityHandler> invalidConfigActivityHandler = [ADJActivityHandler handlerWithConfig:nilAppTokenConfig
                                                                  sessionParametersActionsArray:nil];

    aError(@"AdjustConfig not initialized correctly");
    aNil(invalidConfigActivityHandler);

    // event with nil token
    ADJEvent * nilTokenEvent = [ADJEvent eventWithEventToken:nil];

    aError(@"Missing Event Token");
    aFalse(nilTokenEvent.isValid);

    // event with malformed token
    ADJEvent * malformedTokenEvent = [ADJEvent eventWithEventToken:@"event1x"];

    aError(@"Malformed Event Token 'event1x'");
    aFalse(malformedTokenEvent.isValid);

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  set the delegate that doesn't implement the optional selector
    ADJTestsUtil * delegateNotImpl = [[ADJTestsUtil alloc] init];
    [config setDelegate:delegateNotImpl];

    aError(@"Delegate does not implement any optional method");

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // track null event
    [activityHandler trackEvent:nil];

    [NSThread sleepForTimeInterval:1];

    aError(@"Event missing");

    // track invalid event
    [activityHandler trackEvent:nilTokenEvent];
    [NSThread sleepForTimeInterval:1];

    aError(@"Event not initialized correctly");

    // create the first Event object
    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"event1"];

    // event with negative revenue
    [firstEvent setRevenue:-0.0001 currency:@"EUR"];

    aError(@"Invalid amount -0.00010");

    // event with null currency
    [firstEvent setRevenue:0 currency:nil];

    aError(@"Currency must be set with revenue");

    // event with empty currency
    [firstEvent setRevenue:0 currency:@""];

    aError(@"Currency is empty");

    // callback parameter null key
    [firstEvent addCallbackParameter:nil value:@"valueCall"];

    aError(@"Callback parameter key is missing");

    // callback parameter empty key
    [firstEvent addCallbackParameter:@"" value:@"valueCall"];

    aError(@"Callback parameter key is empty");

    // callback parameter null value
    [firstEvent addCallbackParameter:@"keyCall" value:nil];

    aError(@"Callback parameter value is missing");

    // callback parameter empty value
    [firstEvent addCallbackParameter:@"keyCall" value:@""];

    aError(@"Callback parameter value is empty");

    // partner parameter null key
    [firstEvent addPartnerParameter:nil value:@"valuePartner"];

    aError(@"Partner parameter key is missing");

    // partner parameter empty key
    [firstEvent addPartnerParameter:@"" value:@"valuePartner"];

    aError(@"Partner parameter key is empty");

    // partner parameter null value
    [firstEvent addPartnerParameter:@"keyPartner" value:nil];

    aError(@"Partner parameter value is missing");

    // partner parameter empty value
    [firstEvent addPartnerParameter:@"keyPartner" value:@""];

    aError(@"Partner parameter value is empty");

    // receipt without transaction id
    [firstEvent setReceipt:[@"value" dataUsingEncoding:NSUTF8StringEncoding] transactionId:nil];
    
    aError(@"Missing transactionId");

    // track event without optional parameters
    [activityHandler trackEvent:firstEvent];
    [NSThread sleepForTimeInterval:1];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was not buffered
    anInfo(@"Buffered event");

    // check that event was sent to package handler
    aTest(@"PackageHandler sendFirstPackage");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:1");

    // check the number of activity packages
    // 1 session + 1 event
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    // get the session package
    ADJActivityPackage *sessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * sessionPackageFields = [ADJPackageFields fields];

    // test first session
    [self testPackageSession:sessionPackage fields:sessionPackageFields sessionCount:@"1"];

    // get the first event
    ADJActivityPackage * eventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create event package test
    ADJPackageFields * eventFields = [ADJPackageFields fields];

    // set event test parameters
    eventFields.eventCount = @"1";
    eventFields.suffix = @"'event1'";

    // test first event
    [self testEventPackage:eventPackage fields:eventFields eventToken:@"event1"];

    [activityHandler resetSessionCallbackParameters];
    [activityHandler resetSessionPartnerParameters];

    [activityHandler removeSessionCallbackParameter:nil];
    [activityHandler removeSessionCallbackParameter:@""];
    [activityHandler removeSessionCallbackParameter:@"nonExistent"];

    [activityHandler removeSessionPartnerParameter:nil];
    [activityHandler removeSessionPartnerParameter:@""];
    [activityHandler removeSessionPartnerParameter:@"nonExistent"];

    [activityHandler addSessionCallbackParameter:nil value:@"value"];
    [activityHandler addSessionCallbackParameter:@"" value:@"value"];

    [activityHandler addSessionCallbackParameter:@"key" value:nil];
    [activityHandler addSessionCallbackParameter:@"key" value:@""];

    [activityHandler addSessionPartnerParameter:nil value:@"value"];
    [activityHandler addSessionPartnerParameter:@"" value:@"value"];

    [activityHandler addSessionPartnerParameter:@"key" value:nil];
    [activityHandler addSessionPartnerParameter:@"key" value:@""];

    [activityHandler removeSessionCallbackParameter:@"nonExistent"];
    [activityHandler removeSessionPartnerParameter:@"nonExistent"];

    [NSThread sleepForTimeInterval:2];

    aWarn(@"Session Callback parameters are not set");
    aWarn(@"Session Partner parameters are not set");

    aError(@"Session Callback parameter key is missing");
    aError(@"Session Callback parameter key is empty");
    aWarn(@"Session Callback parameters are not set");

    aError(@"Session Partner parameter key is missing");
    aError(@"Session Partner parameter key is empty");
    aWarn(@"Session Partner parameters are not set");

    aError(@"Session Callback parameter key is missing");
    aError(@"Session Callback parameter key is empty");
    aError(@"Session Callback parameter value is missing");
    aError(@"Session Callback parameter value is empty");

    aError(@"Session Partner parameter key is missing");
    aError(@"Session Partner parameter key is empty");
    aError(@"Session Partner parameter value is missing");
    aError(@"Session Partner parameter value is empty");

    aWarn(@"Session Callback parameters are not set");
    aWarn(@"Session Partner parameters are not set");
}


- (void)testSessions
{
    //  reseting to make the test order independent
    [self reset];

    //  adjust the intervals for testing
    [ADJAdjustFactory setSessionInterval:(4)]; // 4 seconds
    [ADJAdjustFactory setSubsessionInterval:(1)]; // 1 second

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1];

    // test the end of the subsession
    [self checkEndSession];

    [activityHandler applicationDidBecomeActive];

    ADJInternalState * internalState = [activityHandler internalState];

    // comes to the foreground
    aTrue([internalState isForeground]);

    [NSThread sleepForTimeInterval:1];

    // test the new sub session
    ADJSessionState * secondSubsession = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    secondSubsession.subsessionCount = 2;
    secondSubsession.toSend = YES;
    [self checkStartInternal:secondSubsession];

    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:5];

    // test the end of the subsession
    [self checkEndSession];

    // trigger a new session
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    // new session
    ADJSessionState * secondSession = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    secondSession.sessionCount = 2;
    secondSession.timerAlreadyStarted = YES;
    secondSession.toSend = YES;
    [self checkStartInternal:secondSession];

    // stop and start the activity with little interval
    // so it won't trigger a sub session
    [self stopActivity:activityHandler];
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    // test the end of the subsession
    ADJEndSessionState * endState = [[ADJEndSessionState alloc] init];
    endState.pausing = NO;

    [self checkEndSession:endState];

    // test non sub session
    ADJSessionState * nonSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeNonSession];
    nonSessionState.toSend = YES;
    [self checkStartInternal:nonSessionState];

    // 2 session packages
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    ADJActivityPackage * firstSessionActivityPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * firstSessionPackageFields = [ADJPackageFields fields];

    // test first session
    [self testPackageSession:firstSessionActivityPackage fields:firstSessionPackageFields sessionCount:@"1"];

    // get second session package
    ADJActivityPackage * secondSessionActivityPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create second session test package
    ADJPackageFields * secondSessionPackageFields = [ADJPackageFields fields];

    // check if it saved the second subsession in the new package
    secondSessionPackageFields.subSessionCount = @"2";
    
    // test second session
    [self testPackageSession:secondSessionActivityPackage fields:secondSessionPackageFields sessionCount:@"2"];
}


- (void)testDisable
{
    //  reseting to make the test order independent
    [self reset];

    //  starting from a clean slate
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoActivityState" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoAttribution" logger:self.loggerMock], @"%@", self.loggerMock);

    //  adjust the intervals for testing
    [ADJAdjustFactory setSessionInterval:(4)]; // 4 seconds
    [ADJAdjustFactory setSubsessionInterval:(1)]; // 1 second

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start activity handler with config
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    // check that it is enabled
    aTrue([activityHandler isEnabled]);

    // disable sdk
    [activityHandler setEnabled:NO];

    // check that it is disabled
    aFalse([activityHandler isEnabled]);

    // not writing activity state because it set enable does not start the sdk
    anDebug(@"Wrote Activity state");

    // check if message the disable of the SDK
    aInfo(@"Handlers will start as paused due to the SDK being disabled");

    [NSThread sleepForTimeInterval:4.0];

    // test init values
    [self checkInitAndStartTestsWithHandler:activityHandler];

    // disable runs after start
    [self checkHandlerStatus:YES];

    // try to do activities while SDK disabled
    [activityHandler applicationDidBecomeActive];
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:3];

    aVerbose(@"Subsession start");

    [self checkStartDisable];

    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1.0];

    ADJEndSessionState * endState = [[ADJEndSessionState alloc] init];
    endState.updateActivityState = NO;
    // test end session of disable
    [self checkEndSession:endState];

    // only the first session package should be sent
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    // put in offline mode
    [activityHandler setOfflineMode:YES];

    // pausing due to offline mode
    aInfo(@"Pausing handlers to put SDK offline mode");

    // wait to update status
    [NSThread sleepForTimeInterval:5.0];

    // after pausing, even when it's already paused
    // tries to update the status
    [self checkHandlerStatus:YES];

    // re-enable the SDK
    [activityHandler setEnabled:YES];

    // check that it is enabled
    aTrue([activityHandler isEnabled]);

    // check message of SDK still paused
    aInfo(@"Handlers remain paused");

    [NSThread sleepForTimeInterval:1.0];

    // even though it will remained paused,
    // it will update the status to paused
    [self checkHandlerStatus:YES];

    // start the sdk
    // foreground timer does not start because it's offline
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1.0];

    ADJSessionState * secondPausedSession = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];

    secondPausedSession.toSend = NO;
    secondPausedSession.sessionCount = 2;
    secondPausedSession.foregroundTimerStarts = NO;
    secondPausedSession.foregroundTimerAlreadyStarted = NO;

    [self checkStartInternal:secondPausedSession];

    // track an event
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:5.0];

    // check that it did add the event package
    aTest(@"PackageHandler addPackage");

    // and send it
    aTest(@"PackageHandler sendFirstPackage");

    // does not fire background timer
    anVerbose(@"Background timer starting");

    // it should have the second session and the event
    aiEquals(3, (int)[self.packageHandlerMock.packageQueue count]);

    ADJActivityPackage *secondSessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create activity package test
    ADJPackageFields * secondSessionFields = [ADJPackageFields fields];

    secondSessionFields.subSessionCount = @"1";

    // set second session
    [self testPackageSession:secondSessionPackage fields:secondSessionFields sessionCount:@"2"];

    ADJActivityPackage *eventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[2];

    // create event package test
    ADJPackageFields * eventFields = [ADJPackageFields fields];

    eventFields.suffix = @"'event1'";

    // test event
    [self testEventPackage:eventPackage fields:eventFields eventToken:@"event1"];

    // end the session
    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1.0];

    [self checkEndSession];

    // put in online mode
    [activityHandler setOfflineMode:NO];

    // message that is finally resuming
    aInfo(@"Resuming handlers to put SDK in online mode");

    [NSThread sleepForTimeInterval:1.0];

    // after un-pausing the sdk, tries to update the handlers
    // it is still paused because it's on the background
    [self checkHandlerStatus:YES];

    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1.0];

    // test sub session not paused
    ADJSessionState * thirdSessionStarting = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    thirdSessionStarting.sessionCount = 3;
    thirdSessionStarting.eventCount = 1;
    thirdSessionStarting.timerAlreadyStarted = NO;
    thirdSessionStarting.toSend = YES;

    [self checkStartInternal:thirdSessionStarting];
}

- (void)testAppWillOpenUrl
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    NSURL* attributions = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_tracker=trackerValue&other=stuff&adjust_campaign=campaignValue&adjust_adgroup=adgroupValue&adjust_creative=creativeValue"];
    NSURL* extraParams = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_foo=bar&other=stuff&adjust_key=value"];
    NSURL* mixed = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_foo=bar&other=stuff&adjust_campaign=campaignValue&adjust_adgroup=adgroupValue&adjust_creative=creativeValue"];
    NSURL* emptyQueryString = [NSURL URLWithString:@"AdjustTests://"];
    NSURL* emptyString = [NSURL URLWithString:@""];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSURL* nilString = [NSURL URLWithString:nil];
#pragma clang diagnostic pop
    NSURL* nilUrl = nil;
    NSURL* single = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_foo"];
    NSURL* prefix = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_=bar"];
    NSURL* incomplete = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_foo="];

    [activityHandler appWillOpenUrl:attributions];
    [activityHandler appWillOpenUrl:extraParams];
    [activityHandler appWillOpenUrl:mixed];
    [activityHandler appWillOpenUrl:emptyQueryString];
    [activityHandler appWillOpenUrl:emptyString];
    [activityHandler appWillOpenUrl:nilString];
    [activityHandler appWillOpenUrl:nilUrl];
    [activityHandler appWillOpenUrl:single];
    [activityHandler appWillOpenUrl:prefix];
    [activityHandler appWillOpenUrl:incomplete];

    [NSThread sleepForTimeInterval:1];

    // three click packages: attributions, extraParams and mixed
    for (int i = 7; i > 0; i--) {
        aTest(@"SdkClickHandler sendSdkClick");
    }

    anTest(@"SdkClickHandler sendSdkClick");

    // 7 clicks
    aiEquals(7, (int)[self.sdkClickHandlerMock.packageQueue count]);

    // get the click package
    ADJActivityPackage * attributionClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * attributionClickFields = [ADJPackageFields fields];

    // create the attribution
    ADJAttribution * firstAttribution = [[ADJAttribution alloc] init];
    firstAttribution.trackerName = @"trackerValue";
    firstAttribution.campaign = @"campaignValue";
    firstAttribution.adgroup = @"adgroupValue";
    firstAttribution.creative = @"creativeValue";

    // and set it
    attributionClickFields.attribution = firstAttribution;

    attributionClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_tracker=trackerValue&other=stuff&adjust_campaign=campaignValue&adjust_adgroup=adgroupValue&adjust_creative=creativeValue";

    // test the first deeplink
    [self testClickPackage:attributionClickPackage fields:attributionClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * extraParamsClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[1];

    // create activity package test
    ADJPackageFields * extraParamsClickFields = [ADJPackageFields fields];

    // other deep link parameters
    extraParamsClickFields.deepLinkParameters = @"{\"key\":\"value\",\"foo\":\"bar\"}";

    extraParamsClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_foo=bar&other=stuff&adjust_key=value";

    // test the second deeplink
    [self testClickPackage:extraParamsClickPackage fields:extraParamsClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * mixedClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[2];

    // create activity package test
    ADJPackageFields * mixedClickFields = [ADJPackageFields fields];

    // create the attribution
    ADJAttribution * secondAttribution = [[ADJAttribution alloc] init];
    secondAttribution.campaign = @"campaignValue";
    secondAttribution.adgroup = @"adgroupValue";
    secondAttribution.creative = @"creativeValue";

    // and set it
    mixedClickFields.attribution = secondAttribution;

    mixedClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_foo=bar&other=stuff&adjust_campaign=campaignValue&adjust_adgroup=adgroupValue&adjust_creative=creativeValue";

    // other deep link parameters
    mixedClickFields.deepLinkParameters = @"{\"foo\":\"bar\"}";

    // test the third deeplink
    [self testClickPackage:mixedClickPackage fields:mixedClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * emptyQueryStringClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[3];

    // create activity package test
    ADJPackageFields * emptyQueryStringClickFields = [ADJPackageFields fields];

    emptyQueryStringClickFields.deepLink = @"AdjustTests://";

    // test the second deeplink
    [self testClickPackage:emptyQueryStringClickPackage fields:emptyQueryStringClickFields source:@"deeplink"];
    
    // get the click package
    ADJActivityPackage * singleClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[4];

    // create activity package test
    ADJPackageFields * singleClickFields = [ADJPackageFields fields];

    singleClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_foo";

    // test the second deeplink
    [self testClickPackage:singleClickPackage fields:singleClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * prefixClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[5];

    // create activity package test
    ADJPackageFields * prefixClickFields = [ADJPackageFields fields];

    prefixClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_=bar";

    // test the second deeplink
    [self testClickPackage:prefixClickPackage fields:prefixClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * incompleteClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[6];

    // create activity package test
    ADJPackageFields * incompleteClickFields = [ADJPackageFields fields];

    incompleteClickFields.deepLink = @"AdjustTests://example.com/path/inApp?adjust_foo=";

    // test the second deeplink
    [self testClickPackage:incompleteClickPackage fields:incompleteClickFields source:@"deeplink"];
}

- (void)testIadDates
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // should be ignored
    [activityHandler setIadDate:nil withPurchaseDate:nil];
    [NSThread sleepForTimeInterval:1];

    // check that iAdImpressionDate was not received.
    aDebug(@"iAdImpressionDate not received");

    // didn't send click package
    anTest(@"SdkClickHandler sendSdkClick");

    [activityHandler setIadDate:nil withPurchaseDate:[NSDate date]];
    [NSThread sleepForTimeInterval:1];

    // check that iAdImpressionDate was not received.
    aDebug(@"iAdImpressionDate not received");

    // didn't send click package
    anTest(@"SdkClickHandler sendSdkClick");

    // 1 session
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'Z"];

    NSDate * date1 = [NSDate date];
    NSString * date1String = [dateFormat stringFromDate:date1];
    NSDate * date2 = [NSDate date];
    NSString * date2String = [dateFormat stringFromDate:date2];

    [self.loggerMock test:@"date1 %@, date2 %@", date1.description, date2.description];

    [activityHandler setIadDate:date1 withPurchaseDate:date2];
    [NSThread sleepForTimeInterval:1];

    // iAdImpressionDate received
    NSString * iAdImpressionDate1Log = [NSString stringWithFormat:@"iAdImpressionDate received: %@", date1];
    aDebug(iAdImpressionDate1Log);

    // first iad package added
    aTest(@"SdkClickHandler sendSdkClick");

    [activityHandler setIadDate:date2 withPurchaseDate:nil];
    [NSThread sleepForTimeInterval:1];

    // iAdImpressionDate received
    NSString * iAdImpressionDate2Log = [NSString stringWithFormat:@"iAdImpressionDate received: %@", date2];
    aDebug(iAdImpressionDate2Log);

    // second iad package added
    aTest(@"SdkClickHandler sendSdkClick");

    // 1 session + 2 click packages
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    aiEquals(2, (int)[self.sdkClickHandlerMock.packageQueue count]);

    // first iad package
    ADJActivityPackage *firstIadPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * firstIadFields = [ADJPackageFields fields];

    firstIadFields.iadTime = date1String;
    firstIadFields.purchaseTime = date2String;

    // test the click package
    [self testClickPackage:firstIadPackage fields:firstIadFields source:@"iad"];

    // second iad package
    ADJActivityPackage * secondIadPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[1];

    // create activity package test
    ADJPackageFields * secondIadFields = [ADJPackageFields fields];

    secondIadFields.iadTime = date2String;

    // test the click package
    [self testClickPackage:secondIadPackage fields:secondIadFields source:@"iad"];
}

- (void)testIadDetails
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler =[self startAndCheckFirstSession:config];

    // test iad details
    // should be ignored
    NSError * errorCode0 = [[NSError alloc] initWithDomain:@"adjust" code:0 userInfo:nil];
    NSError * errorCode1 = [[NSError alloc] initWithDomain:@"adjust" code:1 userInfo:nil];

    [activityHandler setIadDetails:nil error:errorCode0 retriesLeft:-1];
    [NSThread sleepForTimeInterval:1];

    aWarn(@"Unable to read iAd details");
    aWarn(@"Limit number of retry for iAd v3 surpassed");

    [activityHandler setIadDetails:nil error:errorCode0 retriesLeft:0];
    [NSThread sleepForTimeInterval:4];

    aWarn(@"Unable to read iAd details");
    anWarn(@"Limit number of retry for iAd v3 surpassed");

    aDebug(@"iAd with 0 tries to read v3");
    aWarn(@"Reached limit number of retry for iAd v3. Trying iAd v2");

    [activityHandler setIadDetails:nil error:errorCode0 retriesLeft:1];
    [NSThread sleepForTimeInterval:4];

    aWarn(@"Unable to read iAd details");

    aDebug(@"iAd with 1 tries to read v3");
    anWarn(@"Reached limit number of retry for iAd v3. Trying iAd v2");

    [activityHandler setIadDetails:nil error:errorCode1 retriesLeft:1];
    [NSThread sleepForTimeInterval:4];

    aWarn(@"Unable to read iAd details");
    anDebug(@"iAd with 1 tries to read v3");

    [activityHandler setIadDetails:nil error:nil retriesLeft:1];
    [NSThread sleepForTimeInterval:4];

    anWarn(@"Unable to read iAd details");
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'Z"];

    NSDate * date1 = [NSDate date];
    NSString * date1String = [dateFormat stringFromDate:date1];

    NSDictionary * attributionDetails = @{ @"iadVersion3" : @{ @"date" : date1 ,
                                                               @"decimal" : [NSNumber numberWithDouble:0.1],
                                                               @"string" : @"value"} };

    [activityHandler setIadDetails:attributionDetails error:nil retriesLeft:1];
    [NSThread sleepForTimeInterval:2];

    aTest(@"SdkClickHandler sendSdkClick");
    // check the number of activity packages
    // 1 session + 1 sdk_click
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    aiEquals(1, (int)[self.sdkClickHandlerMock.packageQueue count]);

    // get the click package
    ADJActivityPackage *clickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * clickPackageFields = [ADJPackageFields fields];

    clickPackageFields.iadDetails = [NSString stringWithFormat:@"{\"iadVersion3\":{\"date\":\"%@\",\"decimal\":\"0.1\",\"string\":\"value\"}}", date1String];

    // test first session
    [self testClickPackage:clickPackage fields:clickPackageFields source:@"iad3"];
}

- (void)testSetDeviceToken {
    // reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    const char bytes[] = "\xFC\x07\x21\xB6\xDF\xAD\x5E\xE1\x10\x97\x5B\xB2\xA2\x63\xDE\x00\x61\xCC\x70\x5B\x4A\x85\xA8\xAE\x3C\xCF\xBE\x7A\x66\x2F\xB1\xAB";
    [activityHandler setDeviceToken:[NSData dataWithBytes:bytes length:(sizeof(bytes) - 1)]];

    [NSThread sleepForTimeInterval:1];

    aTest(@"SdkClickHandler sendSdkClick");

    // get the click package
    ADJActivityPackage * deviceTokenClickPackage = (ADJActivityPackage *) self.sdkClickHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * deviceTokenClickFields = [ADJPackageFields fields];

    // and set it
    deviceTokenClickFields.pushToken = @"fc0721b6dfad5ee110975bb2a263de0061cc705b4a85a8ae3ccfbe7a662fb1ab";

    // test the first deeplink
    [self testClickPackage:deviceTokenClickPackage fields:deviceTokenClickFields source:@"push"];
}

- (void)testAttributionDelegate
{
    // reseting to make the test order independent
    [self reset];

    ADJAttributionChangedDelegate * delegateTests = [[ADJAttributionChangedDelegate alloc] init];

    [self checkFinishTasks:delegateTests
attributionDelegatePresent:YES
eventSuccessDelegatePresent:NO
eventFailureDelegatePresent:NO
sessionSuccessDelegatePresent:NO
sessionFailureDelegatePresent:NO];

}

- (void)testSuccessDelegates
{
    // reseting to make the test order independent
    [self reset];

    ADJTrackingSucceededDelegate * successDelegate = [[ADJTrackingSucceededDelegate alloc] init];

    [self checkFinishTasks:successDelegate
attributionDelegatePresent:NO
eventSuccessDelegatePresent:YES
eventFailureDelegatePresent:NO
sessionSuccessDelegatePresent:YES
sessionFailureDelegatePresent:NO];

}

- (void)testFailureDelegates
{
    // reseting to make the test order independent
    [self reset];

    ADJTrackingFailedDelegate * failureDelegate = [[ADJTrackingFailedDelegate alloc] init];

    [self checkFinishTasks:failureDelegate
attributionDelegatePresent:NO
eventSuccessDelegatePresent:NO
eventFailureDelegatePresent:YES
sessionSuccessDelegatePresent:NO
sessionFailureDelegatePresent:YES];
}

- (void)testLaunchDeepLink
{
    // reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start the session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    [activityHandler finishedTracking:nil];

    [NSThread sleepForTimeInterval:1.0];

    // if the response is null
    anTest(@"AttributionHandler checkAttributionResponse");
    anError(@"Unable to open deep link");
    anInfo(@"Open deep link");

    // test success session response data
    ADJActivityPackage * sessionPackage = self.packageHandlerMock.packageQueue[0];

    ADJSessionResponseData * sessionResponseData = [ADJResponseData buildResponseData:sessionPackage];

    [activityHandler launchSessionResponseTasks:sessionResponseData];
    [NSThread sleepForTimeInterval:2.0];

    // does not launch deeplink from session responses anymore
    anInfo(@"Open deep link (wrongDeeplink://)");

    // test attribution response
    ADJActivityPackage * attributionPackage = self.attributionHandlerMock.attributionPackage;
    ADJAttributionResponseData * attributionResponseData = [ADJResponseData buildResponseData:attributionPackage];
    attributionResponseData.deeplink = [NSURL URLWithString:@"wrongDeeplink://"];

    [activityHandler launchAttributionResponseTasks:attributionResponseData];
    [NSThread sleepForTimeInterval:2.0];

    aInfo(@"Open deep link (wrongDeeplink://)");

    // checking the default values of the first session package
    //  should only have one package
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    //ADJActivityPackage *activityPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    //ADJPackageFields * fields = [ADJPackageFields fields];

    //fields.environment = @"production";
    // set first session
    //[self testPackageSession:activityPackage fields:fields sessionCount:@"1"];

}

- (void)testNotLaunchDeeplinkCallback {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    ADJDeeplinkNotLaunchDelegate * notLaunchDeeplinkDelegate = [[ADJDeeplinkNotLaunchDelegate alloc] init];

    [config setDelegate:notLaunchDeeplinkDelegate];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // get attribution response data
    ADJActivityPackage * attributionPackage = self.attributionHandlerMock.attributionPackage;

    // try to open deeplink
    ADJAttributionResponseData * attributionResponseData = [ADJResponseData buildResponseData:attributionPackage];
    attributionResponseData.deeplink = [NSURL URLWithString:@"wrongDeeplink://"];

    [activityHandler launchAttributionResponseTasks:attributionResponseData];

    [NSThread sleepForTimeInterval:2.0];

    // deeplink to launch
    aInfo(@"Open deep link (wrongDeeplink://)");

    // deeplink to launch
    aDebug(@"Launching in the background for testing");

    // callback called
    aTest(@"ADJDeeplinkNotLaunchDelegate adjustDeeplinkResponse not launch, wrongDeeplink://");

    // but deeplink not launched
    anError(@"Unable to open deep link");
}

- (void)testDeeplinkCallback
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    ADJDeeplinkLaunchDelegate * launchDeeplinkDelegate = [[ADJDeeplinkLaunchDelegate alloc] init];

    [config setDelegate:launchDeeplinkDelegate];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // get attribution response data
    ADJActivityPackage * attributionPackage = self.attributionHandlerMock.attributionPackage;

    // try to open deeplink
    ADJAttributionResponseData * attributionResponseData = [ADJResponseData buildResponseData:attributionPackage];
    attributionResponseData.deeplink = [NSURL URLWithString:@"wrongDeeplink://"];

    [activityHandler launchAttributionResponseTasks:attributionResponseData];

    [NSThread sleepForTimeInterval:2.0];

    // deeplink to launch
    aInfo(@"Open deep link (wrongDeeplink://)");

    // deeplink to launch
    aDebug(@"Launching in the background for testing");

    // callback called
    aTest(@"ADJDeeplinkLaunchDelegate adjustDeeplinkResponse launch, wrongDeeplink://");

    // and deeplink launched
    aError(@"Unable to open deep link (wrongDeeplink://)");
}

- (void)testUpdateAttribution
{
    // reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    ADJAttributionChangedDelegate * attributionChangedDelegate = [[ADJAttributionChangedDelegate alloc] init];
    [config setDelegate:attributionChangedDelegate];

    aDebug(@"Delegate implements adjustAttributionChanged");

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // check if Attribution is not created with nil
    ADJAttribution * nilAttribution = [[ADJAttribution alloc] initWithJsonDict:nil];

    aNil(nilAttribution);

    // check it does not update a nil attribution
    aFalse([activityHandler updateAttributionI:activityHandler attribution:nilAttribution]);

    // create an empty attribution
    NSMutableDictionary * emptyJsonDictionary = [[NSMutableDictionary alloc] init];
    ADJAttribution * emptyAttribution = [[ADJAttribution alloc] initWithJsonDict:emptyJsonDictionary];

    // check that updates attribution
    aTrue([activityHandler updateAttributionI:activityHandler attribution:emptyAttribution]);
    aDebug(@"Wrote Attribution: tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null)");

    emptyAttribution = [[ADJAttribution alloc] initWithJsonDict:emptyJsonDictionary];

    // test first session package
    ADJActivityPackage * firstSessionPackage = self.packageHandlerMock.packageQueue[0];
    // simulate a session response with attribution data
    ADJSessionResponseData * sessionResponseDataWithAttribution = [ADJResponseData buildResponseData:firstSessionPackage];

    sessionResponseDataWithAttribution.attribution = emptyAttribution;
    // check that it does not update the attribution
    [activityHandler launchSessionResponseTasks:sessionResponseDataWithAttribution];
    [NSThread sleepForTimeInterval:1];

    anDebug(@"Wrote Attribution");

    // end session
    [self stopActivity:activityHandler];
    [NSThread sleepForTimeInterval:2];

    [self checkEndSession];

    // create the new config
    config = [self getConfig];

    // set delegate to see attribution launched
    [config setDelegate:attributionChangedDelegate];

    ADJActivityHandlerConstructorState * restartCState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    restartCState.readActivityState = @"ec:0 sc:1 ssc:1";
    restartCState.readAttribution = @"tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null)";
    id<ADJActivityHandler> restartActivityHandler = [self getActivityHandler:restartCState];

    [NSThread sleepForTimeInterval:2];

    ADJSessionState * firstRestart = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    firstRestart.subsessionCount = 2;
    firstRestart.timerAlreadyStarted = NO;
    firstRestart.toSend = NO;

    // test init values
    [self checkInitAndStartTestsWithHandler:restartActivityHandler sessionState:firstRestart];

    // check that it does not update the attribution after the restart
    aFalse([restartActivityHandler updateAttributionI:activityHandler attribution:emptyAttribution]);
    anDebug(@"Wrote Attribution");

    // new attribution
    NSString * firstAttributionString = @"{ "
                                        "\"tracker_token\" : \"ttValue\" , "
                                        "\"tracker_name\"  : \"tnValue\" , "
                                        "\"network\"       : \"nValue\" , "
                                        "\"campaign\"      : \"cpValue\" , "
                                        "\"adgroup\"       : \"aValue\" , "
                                        "\"creative\"      : \"ctValue\" , "
                                        "\"click_label\"   : \"clValue\" }";

    NSData * firstAttributionData = [firstAttributionString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSException *exception = nil;

    NSDictionary * firstAttributionDictionary = [ADJUtil buildJsonDict:firstAttributionData exceptionPtr:&exception errorPtr:&error];

    anNil(firstAttributionDictionary);

    ADJAttribution * firstAttribution = [[ADJAttribution alloc] initWithJsonDict:firstAttributionDictionary];

    //check that it updates
    sessionResponseDataWithAttribution.attribution = firstAttribution;
    [restartActivityHandler launchSessionResponseTasks:sessionResponseDataWithAttribution];
    [NSThread sleepForTimeInterval:1];

    aDebug(@"Wrote Attribution: tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");
    aDebug(@"Launching in the background for testing");
    aTest(@"ADJAttributionChangedDelegate adjustAttributionChanged, tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");

    // test first session package
    ADJActivityPackage * attributionPackage = self.attributionHandlerMock.attributionPackage;
    // simulate a session response with attribution data
    ADJAttributionResponseData * attributionResponseDataWithAttribution = [ADJResponseData buildResponseData:attributionPackage];

    attributionResponseDataWithAttribution.attribution = firstAttribution;
    // check that it does not update the attribution
    [restartActivityHandler launchAttributionResponseTasks:attributionResponseDataWithAttribution];
    [NSThread sleepForTimeInterval:1];

    anDebug(@"Wrote Attribution");
    anTest(@"ADJAttributionChangedDelegate adjustAttributionChanged");

    // end session
    [self stopActivity:restartActivityHandler];
    [NSThread sleepForTimeInterval:1];

    [self checkEndSession];

    // create the new config
    config = [self getConfig];

    // set delegate to see attribution launched
    [config setDelegate:attributionChangedDelegate];

    ADJActivityHandlerConstructorState * secondRestartCState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    secondRestartCState.readActivityState = @"ec:0 sc:1 ssc:2";
    secondRestartCState.readAttribution = @"tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue";

    id<ADJActivityHandler> secondRestartActivityHandler = [self getActivityHandler:secondRestartCState];

    [NSThread sleepForTimeInterval:2];

    ADJSessionState * secondRestart = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    secondRestart.subsessionCount = 3;
    secondRestart.timerAlreadyStarted = NO;
    secondRestart.toSend = NO;

    [self checkInitAndStartTestsWithHandler:secondRestartActivityHandler sessionState:secondRestart];

    // check that it does not update the attribution after the restart
    aFalse([secondRestartActivityHandler updateAttributionI:secondRestartActivityHandler attribution:firstAttribution]);
    anDebug(@"Wrote Attribution");

    // new attribution
    NSString * secondAttributionString = @"{ "
                                        "\"tracker_token\" : \"ttValue2\" , "
                                        "\"tracker_name\"  : \"tnValue2\" , "
                                        "\"network\"       : \"nValue2\" , "
                                        "\"campaign\"      : \"cpValue2\" , "
                                        "\"adgroup\"       : \"aValue2\" , "
                                        "\"creative\"      : \"ctValue2\" , "
                                        "\"click_label\"   : \"clValue2\" }";

    NSData * secondAttributionData = [secondAttributionString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * secondAttributionDictionary = [ADJUtil buildJsonDict:secondAttributionData exceptionPtr:&exception errorPtr:&error];

    anNil(secondAttributionDictionary);

    ADJAttribution * secondAttribution = [[ADJAttribution alloc] initWithJsonDict:secondAttributionDictionary];

    //check that it updates
    attributionResponseDataWithAttribution.attribution = secondAttribution;

    [secondRestartActivityHandler launchAttributionResponseTasks:attributionResponseDataWithAttribution];
    [NSThread sleepForTimeInterval:1];

    aDebug(@"Wrote Attribution: tt:ttValue2 tn:tnValue2 net:nValue2 cam:cpValue2 adg:aValue2 cre:ctValue2 cl:clValue2");
    aDebug(@"Launching in the background for testing");
    aTest(@"ADJAttributionChangedDelegate adjustAttributionChanged, tt:ttValue2 tn:tnValue2 net:nValue2 cam:cpValue2 adg:aValue2 cre:ctValue2 cl:clValue2");

    // check that it does not update the attribution
    aFalse([secondRestartActivityHandler updateAttributionI:secondRestartActivityHandler attribution:secondAttribution]);
    anDebug(@"Wrote Attribution");
}

- (void)testOfflineMode
{
    //  reseting to make the test order independent
    [self reset];

    //  adjust the intervals for testing
    [ADJAdjustFactory setSessionInterval:(2)]; // 2 seconds
    [ADJAdjustFactory setSubsessionInterval:(0.5)]; // 1/2 second

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    ADJInternalState * internalState = [activityHandler internalState];

    // check that it is online
    aTrue([internalState isOnline]);

    // put SDK offline
    [activityHandler setOfflineMode:YES];

    aTrue([internalState isOffline]);

    // not writing activity state because it set enable does not start the sdk
    anDebug(@"Wrote Activity state");

    // check if message the disable of the SDK
    aInfo(@"Handlers will start paused due to SDK being offline");

    [NSThread sleepForTimeInterval:3.0];

    // test init values
    [self checkInitAndStartTestsWithHandler:activityHandler];

    // offline runs after start
    [self checkHandlerStatus:YES];

    // start the second session
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    // test second session start
    ADJSessionState * secondSessionStartPaused = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];

    secondSessionStartPaused.sessionCount = 2;
    secondSessionStartPaused.toSend = NO;
    secondSessionStartPaused.foregroundTimerStarts = NO;
    secondSessionStartPaused.foregroundTimerAlreadyStarted = NO;

    // check session that is paused
    [self checkStartInternal:secondSessionStartPaused];

    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1];

    // test end session of disable
    [self checkEndSession];

    // disable the SDK
    [activityHandler setEnabled:NO];

    // check that it is disabled
    aFalse([activityHandler isEnabled]);

    // writing activity state after disabling
    aDebug(@"Wrote Activity state: ec:0 sc:2 ssc:1");

    // check if message the disable of the SDK
    aInfo(@"Pausing handlers due to SDK being disabled");

    [NSThread sleepForTimeInterval:1];

    [self checkHandlerStatus:YES];

    // put SDK back online
    [activityHandler setOfflineMode:NO];

    aInfo(@"Handlers remain paused");

    [NSThread sleepForTimeInterval:1];

    // even though it will remained paused,
    // it will update the status to paused
    [self checkHandlerStatus:YES];

    // try to do activities while SDK disabled
    [activityHandler applicationDidBecomeActive];
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:3];

    // check that timer was not executed
    [self checkForegroundTimerFired:NO];

    // check that it did not wrote activity state from new session or subsession
    anDebug(@"Wrote Activity state");

    // check that it did not add any package
    anTest(@"PackageHandler addPackage");

    // end the session
    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1];

    ADJEndSessionState * endStateDoNotPause = [[ADJEndSessionState alloc] init];
    endStateDoNotPause.updateActivityState = NO;

    [self checkEndSession:endStateDoNotPause];

    // enable the SDK again
    [activityHandler setEnabled:YES];

    // check that is enabled
    aTrue([activityHandler isEnabled]);

    [NSThread sleepForTimeInterval:3];

    aDebug(@"Wrote Activity state");

    // check that it re-enabled
    aInfo(@"Resuming handlers due to SDK being enabled");

    // it is still paused because it's on the background
    [self checkHandlerStatus:YES];

    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    ADJSessionState * thirdSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    thirdSessionState.sessionCount = 3;
    thirdSessionState.toSend = YES;

    // test that is not paused anymore
    [self checkStartInternal:thirdSessionState];
}

- (void)testGetAttribution
{
    //  reseting to make the test order independent
    [self reset];

    //  adjust the intervals for testing
    //[ADJAdjustFactory setTimerStart:0.5]; // 0.5 second
    [ADJAdjustFactory setSessionInterval:(4)]; // 4 second

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // set delegate
    ADJAttributionChangedDelegate * attributionChangedDelegate = [[ADJAttributionChangedDelegate alloc] init];
    [config setDelegate:attributionChangedDelegate];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    /***
     *  if it' a new session
     * if (self.activityState.subsessionCount <= 1) {
     *     return;
     * }
     *
     *  if there is already an attribution saved and there was no attribution being asked
     * if (self.attribution != nil && !self.activityState.askingAttribution) {
     *     return;
     * }
     *
     * [[self getAttributionHandler] getAttribution];
     */

    // subsession count is 1
    // attribution is null,
    // askingAttribution is false by default,
    // -> Not called

    // test first session start
    ADJSessionState * newSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    newSessionState.getAttributionIsCalled = [NSNumber numberWithBool:NO];

    // test init values
    [self checkInitAndStartTestsWithHandler:activityHandler sessionState:newSessionState];

    // subsession count increased to 2
    // attribution is still null,
    // askingAttribution is still false,
    // -> Called

    // trigger a new sub session
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubSession:1 subsessionCount:2 getAttributionIsCalled:YES];

    // subsession count increased to 3
    // attribution is still null,
    // askingAttribution is set to true,
    // -> Called

    // set asking attribution
    [activityHandler setAskingAttribution:YES];
    aDebug(@"Wrote Activity state: ec:0 sc:1 ssc:2");

    // trigger a new session
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubSession:1 subsessionCount:3 getAttributionIsCalled:YES];

    // subsession is reset to 1 with new session
    // attribution is still null,
    // askingAttribution is set to true,
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkFurtherSessions:2 getAttributionIsCalled:NO];

    // subsession count increased to 2
    // attribution is set,
    // askingAttribution is set to true,
    // -> Called

    NSString * attributionString = @"{ "
                                    "\"tracker_token\" : \"ttValue\" , "
                                    "\"tracker_name\"  : \"tnValue\" , "
                                    "\"network\"       : \"nValue\" , "
                                    "\"campaign\"      : \"cpValue\" , "
                                    "\"adgroup\"       : \"aValue\" , "
                                    "\"creative\"      : \"ctValue\" , "
                                    "\"click_label\"   : \"clValue\" }";

    NSData * attributionData = [attributionString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSException *exception = nil;
    NSDictionary * attributionDictionary = [ADJUtil buildJsonDict:attributionData exceptionPtr:&exception errorPtr:&error];

    anNil(attributionDictionary);

    ADJAttribution * attribution = [[ADJAttribution alloc] initWithJsonDict:attributionDictionary];

    // update the attribution
    [activityHandler updateAttributionI:activityHandler attribution:attribution];

    // attribution was updated
    aDebug(@"Wrote Attribution: tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");

    // trigger a new sub session
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubSession:2 subsessionCount:2 getAttributionIsCalled:YES];

    // subsession count is reset to 1
    // attribution is set,
    // askingAttribution is set to true,
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkFurtherSessions:3 getAttributionIsCalled:NO];

    // subsession increased to 2
    // attribution is set,
    // askingAttribution is set to false
    // -> Not called

    [activityHandler setAskingAttribution:NO];
    aDebug(@"Wrote Activity state: ec:0 sc:3 ssc:1");

    // trigger a new sub session
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubSession:3 subsessionCount:2 getAttributionIsCalled:NO];

    // subsession is reset to 1
    // attribution is set,
    // askingAttribution is set to false
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:2.0];

    [self checkFurtherSessions:4 getAttributionIsCalled:NO];
}

- (void)testForegroundTimer
{
    //  reseting to make the test order independent
    [self reset];

    //  change the timer defaults
    [ADJAdjustFactory setTimerInterval:4];
    [ADJAdjustFactory setTimerStart:4];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.foregroundTimerCycle = 4;
    initState.foregroundTimerStart = 4;
    [self checkInitTests:initState];

    [self checkFirstSession];

    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:5.0];

    ADJSessionState * subSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    subSessionState.subsessionCount = 2;
    subSessionState.toSend = YES;

    [self checkStartInternal:subSessionState];

    // wait enough to fire the first cycle
    [self checkForegroundTimerFired:YES];

    // end subsession to stop timer
    [activityHandler applicationWillResignActive];

    // don't wait enough for a new cycle
    [NSThread sleepForTimeInterval:2];

    // start a new session
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    // check that not enough time passed to fire again
    //[self checkForegroundTimerFired:NO];

    // enough time passed since it was suspended
    [self checkForegroundTimerFired:YES];

/*
    // end subsession to stop timer
    [activityHandler applicationWillResignActive];

    // wait enough for a new cycle
    [NSThread sleepForTimeInterval:6];

    // start a new session
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1];

    // check that enough time passed to fire again
    [self checkForegroundTimerFired:YES];
    */
}

- (void)testSendBackground {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setTimerInterval:4];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // enable send in the background
    [config setSendInBackground:YES];

    // create activity handler without starting
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:2.0];

    // handlers start sending
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.startsSending = YES;
    initState.sendInBackgroundConfigured = YES;
    initState.foregroundTimerCycle = 4;

    // test session
    ADJSessionState * sesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    sesssionState.sendInBackgroundConfigured = YES;
    sesssionState.toSend = YES;

    [self checkInitAndStart:initState sessionState:sesssionState];

    ADJSessionState * nonSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeNonSession];
    //subSessionState.subsessionCount = 2;
    nonSessionState.toSend = YES;
    [self checkStartInternal:nonSessionState];

    // end subsession
    // background timer starts
    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1.0];

    // session end does not pause the handlers
    ADJEndSessionState * endSession1 = [[ADJEndSessionState alloc] init];
    endSession1.pausing = NO;
    endSession1.checkOnPause = YES;
    endSession1.backgroundTimerStarts = YES;

    [self checkEndSession:endSession1];

    // end subsession again
    // to test if background timer starts again
    [self stopActivity:activityHandler];

    [NSThread sleepForTimeInterval:1.0];

    ADJEndSessionState * endSession2 = [[ADJEndSessionState alloc] init];
    endSession2.pausing = NO;
    endSession2.checkOnPause = YES;
    endSession2.forgroundAlreadySuspended = YES;

    // session end does not pause the handlers
    [self checkEndSession:endSession2];

    // wait for background timer launch
    [NSThread sleepForTimeInterval:3.0];

    // background timer fired
    aTest(@"PackageHandler sendFirstPackage");

    // wait enough time
    [NSThread sleepForTimeInterval:3.0];

    // check that background timer does not fire again
    anTest(@"PackageHandler sendFirstPackage");

    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"abc123"]];

    [NSThread sleepForTimeInterval:1.0];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was sent to package handler
    aTest(@"PackageHandler sendFirstPackage");

    // and not buffered
    anInfo(@"Buffered event");

    // does fire background timer
    aVerbose(@"Background timer starting. Launching in 4.0 seconds");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state");

    // disable and enable the sdk while in the background
    [activityHandler setEnabled:NO];

    // check that it is disabled
    aFalse([activityHandler isEnabled]);

    // check if message the disable of the SDK
    aInfo(@"Pausing handlers due to SDK being disabled");

    [NSThread sleepForTimeInterval:1.0];

    // handlers being paused because of the disable
    [self checkHandlerStatus:YES];

    [activityHandler setEnabled:YES];

    // check that it is enabled
    aTrue([activityHandler isEnabled]);

    // check if message the enable of the SDK
    aInfo(@"Resuming handlers due to SDK being enabled");

    [NSThread sleepForTimeInterval:1.0];

    // handlers being resumed because of the enable
    // even in the background because of the sendInBackground option
    [self checkHandlerStatus:NO];

    // set offline and online the sdk while in the background
    [activityHandler setOfflineMode:YES];

    ADJInternalState * internalState = [activityHandler internalState];

    // check that it is offline
    aTrue([internalState isOffline]);

    // check if message the offline of the SDK
    aInfo(@"Pausing handlers to put SDK offline mode");

    [NSThread sleepForTimeInterval:1.0];

    // handlers being paused because of the offline
    [self checkHandlerStatus:YES];

    [activityHandler setOfflineMode:NO];

    // check that it is online
    aTrue([internalState isOnline]);

    // check if message the online of the SDK
    aInfo(@"Resuming handlers to put SDK in online mode");

    [NSThread sleepForTimeInterval:1.0];

    // handlers being resumed because of the online
    // even in the background because of the sendInBackground option
    [self checkHandlerStatus:NO];
}

- (void)testConvertUniversalLink
{
    //  reseting to make the test order independent
    [self reset];

    // nil url
    aNil([ADJUtil convertUniversalLink:nil scheme:nil]);
    aError(@"Received universal link is nil");

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSURL* nilStringUrl = [NSURL URLWithString:nil];
#pragma clang diagnostic pop

    // empty url
    aNil([ADJUtil convertUniversalLink:nilStringUrl scheme:nil]);
    aError(@"Received universal link is nil");

    // nil scheme
    NSString * nilScheme = nil;

    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@""] scheme:nilScheme]);
    aWarn(@"Non-empty scheme required, using the scheme \"AdjustUniversalScheme\"");
    aInfo(@"Converted deeplink from universal link AdjustUniversalScheme://");

    // empty Scheme
    NSString * emptyScheme = @"";

    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@""] scheme:emptyScheme]);
    aWarn(@"Non-empty scheme required, using the scheme \"AdjustUniversalScheme\"");
    aInfo(@"Converted deeplink from universal link AdjustUniversalScheme://");

    // custom scheme empty path
    NSString * adjustScheme = @"AdjustTestScheme";

    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@""] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://");

    // non Universal Url
    NSURL * nonUniversalUrl = [NSURL URLWithString:@"AdjustTestScheme://nonUniversalUrl"];
    aNil([ADJUtil convertUniversalLink:nonUniversalUrl scheme:adjustScheme]);
    aError(@"Url doesn't match as universal link or short version");

    // path /
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://");

    // path /yourpath
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath");

    // path /yourpath/
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath/"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/");

    // path yourpath
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath");

    // path yourpath/
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath/"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/");

    // path / query ?key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar");

    // path /yourpath query ?key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath?key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath?key=value&foo=bar");

    // path /yourpath/ query ?key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath/?key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/?key=value&foo=bar");

    // path yourpath query ?key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath?key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath?key=value&foo=bar");

    // path yourpath/ query ?key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath/?key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/?key=value&foo=bar");

    // empty path/query fragment #
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"#"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://#");

    // empty path/query fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://#fragment");

    // path /yourpath/ fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath/#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/#fragment");

    // path yourpath fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath#fragment");

    // empty path query ?key=value&foo=bar fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"?key=value&foo=bar#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar#fragment");

    // path /yourpath/ query ?key=value&foo=bar fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/yourpath/?key=value&foo=bar#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath/?key=value&foo=bar#fragment");

    // path yourpath query ?key=value&foo=bar fragment #fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"yourpath?key=value&foo=bar#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://yourpath?key=value&foo=bar#fragment");
}

- (void)testRemoveRedirect
{
    //  reseting to make the test order independent
    [self reset];

    // custom scheme empty path
    NSString * adjustScheme = @"AdjustTestScheme";

    // path / query ?key=value&foo=bar&adjust_redirect=test
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?key=value&foo=bar&adjust_redirect=test"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar");

    // path / query ?key=value&adjust_redirect=test&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?key=value&adjust_redirect=test&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar");

    // path / query ?adjust_redirect=test&key=value&foo=bar
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?adjust_redirect=test&key=value&foo=bar"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar");

    // path / query ?adjust_redirect=test
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?adjust_redirect=test"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://");

    // path / query ?key=value&foo=bar&adjust_redirect=test#fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?key=value&foo=bar&adjust_redirect=test#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?key=value&foo=bar#fragment");

    // path / query ?adjust_redirect=test#fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?adjust_redirect=test#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://#fragment");

    // path / query ?adjust_redirect=test&foo=bar#fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?adjust_redirect=test&foo=bar#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?foo=bar#fragment");

    // path / query ?foo=bar&adjust_redirect=test#fragment
    anNil([ADJUtil convertUniversalLink:[self getUniversalLinkUrl:@"/?foo=bar&adjust_redirect=test#fragment"] scheme:adjustScheme]);
    aInfo(@"Converted deeplink from universal link AdjustTestScheme://?foo=bar#fragment");
}

- (void)testSessionParameters {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    //  create handler and start the first session
    ADJActivityHandlerConstructorState * cState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    cState.sessionParametersActionsArray = @[^(ADJActivityHandler * activityHandler)
    {
        //
        [activityHandler addSessionCallbackParameterI:activityHandler key:@"cKey" value:@"cValue"];
        [activityHandler addSessionCallbackParameterI:activityHandler key:@"cFoo" value:@"cBar"];

        [activityHandler addSessionCallbackParameterI:activityHandler key:@"cKey" value:@"cValue2"];
        [activityHandler resetSessionCallbackParametersI:activityHandler];

        [activityHandler addSessionCallbackParameterI:activityHandler key:@"cKey" value:@"cValue"];
        [activityHandler addSessionCallbackParameterI:activityHandler key:@"cFoo" value:@"cBar"];
        [activityHandler removeSessionCallbackParameterI:activityHandler key:@"cKey"];

        //
        [activityHandler addSessionPartnerParameterI:activityHandler key:@"pKey" value:@"pValue"];
        [activityHandler addSessionPartnerParameterI:activityHandler key:@"pFoo" value:@"pBar"];

        [activityHandler addSessionPartnerParameterI:activityHandler key:@"pKey" value:@"pValue2"];
        [activityHandler resetSessionPartnerParametersI:activityHandler];

        [activityHandler addSessionPartnerParameterI:activityHandler key:@"pKey" value:@"pValue"];
        [activityHandler addSessionPartnerParameterI:activityHandler key:@"pFoo" value:@"pBar"];
        [activityHandler removeSessionPartnerParameterI:activityHandler key:@"pKey"];
    }];

    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"abc123"];

    id<ADJActivityHandler> activityHandler = [self getActivityHandler:cState];

    // track event
    [activityHandler trackEvent:firstEvent];

    [NSThread sleepForTimeInterval:2.0];

    //
    aDebug(@"Wrote Session Callback parameters: {\n    cKey = cValue;\n}");
    aDebug(@"Wrote Session Callback parameters: {\n    cFoo = cBar;\n    cKey = cValue;\n}");

    aWarn(@"Key cKey will be overwritten");
    aDebug(@"Wrote Session Callback parameters: {\n    cFoo = cBar;\n    cKey = cValue2;\n}");

    aDebug(@"Wrote Session Callback parameters: (null)");

    anWarn(@"Key cKey will be overwritten"); // XXX
    aDebug(@"Wrote Session Callback parameters: {\n    cKey = cValue;\n}");
    aDebug(@"Wrote Session Callback parameters: {\n    cFoo = cBar;\n    cKey = cValue;\n}");

    aDebug(@"Key cKey will be removed");
    aDebug(@"Wrote Session Callback parameters: {\n    cFoo = cBar;\n}");

    //
    aDebug(@"Wrote Session Partner parameters: {\n    pKey = pValue;\n}");
    aDebug(@"Wrote Session Partner parameters: {\n    pFoo = pBar;\n    pKey = pValue;\n}");

    aWarn(@"Key pKey will be overwritten");
    aDebug(@"Wrote Session Partner parameters: {\n    pFoo = pBar;\n    pKey = pValue2;\n}");

    aDebug(@"Wrote Session Partner parameters: (null)");

    anWarn(@"Key pKey will be overwritten"); // XXX
    aDebug(@"Wrote Session Partner parameters: {\n    pKey = pValue;\n}");
    aDebug(@"Wrote Session Partner parameters: {\n    pFoo = pBar;\n    pKey = pValue;\n}");

    aDebug(@"Key pKey will be removed");
    aDebug(@"Wrote Session Partner parameters: {\n    pFoo = pBar;\n}");

    [self checkInitAndStartTestsWithHandler:activityHandler];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was sent to package handler
    aTest(@"PackageHandler sendFirstPackage");

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:1 sc:1 ssc:1");

    // 1 session + 1 event
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    // get the session package
    ADJActivityPackage * sessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create event package test
    ADJPackageFields * sessionPackageFields = [ADJPackageFields fields];

    // set event test parameters
    sessionPackageFields.callbackParameters = @"{\"cFoo\":\"cBar\"}";
    sessionPackageFields.partnerParameters = @"{\"pFoo\":\"pBar\"}";

    [self testPackageSession:sessionPackage fields:sessionPackageFields sessionCount:@"1"];

    // get the event
    ADJActivityPackage * eventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create event package test
    ADJPackageFields * eventPackageFields = [ADJPackageFields fields];

    // set event test parameters
    eventPackageFields.eventCount = @"1";
    eventPackageFields.suffix = @"'abc123'";
    eventPackageFields.callbackParameters = @"{\"cFoo\":\"cBar\"}";
    eventPackageFields.partnerParameters = @"{\"pFoo\":\"pBar\"}";

    [self testEventPackage:eventPackage fields:eventPackageFields eventToken:@"abc123"];

    // end current session
    [activityHandler applicationWillResignActive];
    [NSThread sleepForTimeInterval:1.0];

    [self checkEndSession];
    [activityHandler teardown:NO];
    activityHandler = nil;
    [NSThread sleepForTimeInterval:1.0];

    // start new one
    ADJActivityHandlerConstructorState * cRestartState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    cRestartState.readActivityState = @"";

    id<ADJActivityHandler> restartActivityHandler = [self getActivityHandler:cRestartState];
    [NSThread sleepForTimeInterval:1.0];

    // test init values
    ADJInitState * restartInitState = [[ADJInitState alloc] initWithActivityHandler:restartActivityHandler];

    // delay start not configured because activity state is already created
    restartInitState.activityStateAlreadyCreated = YES;
    restartInitState.readCallbackParameters = @"{\n    cFoo = cBar;\n}";
    restartInitState.readPartnerParameters = @"{\n    pFoo = pBar;\n}";

    ADJSessionState * restartSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    restartSessionState.subsessionCount = 2;
    restartSessionState.eventCount = 1;

    [self checkInitAndStart:restartInitState sessionState:restartSessionState];

    ADJEvent * event1 = [ADJEvent eventWithEventToken:@"abc123"];
    [event1 addCallbackParameter:@"ceFoo" value:@"ceBar"];
    [event1 addPartnerParameter:@"peFoo" value:@"peBar"];

    [restartActivityHandler trackEvent:event1];

    ADJEvent * event2 = [ADJEvent eventWithEventToken:@"abc123"];
    [event2 addCallbackParameter:@"cFoo" value:@"ceBar"];
    [event2 addPartnerParameter:@"pFoo" value:@"peBar"];

    [restartActivityHandler trackEvent:event2];

    [NSThread sleepForTimeInterval:2.0];

    // 2 events
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    // get the event
    ADJActivityPackage * firstEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create event package test
    ADJPackageFields * firstEventPackageFields = [ADJPackageFields fields];

    // set event test parameters
    firstEventPackageFields.eventCount = @"2";
    firstEventPackageFields.suffix = @"'abc123'";
    firstEventPackageFields.callbackParameters = @"{\"cFoo\":\"cBar\",\"ceFoo\":\"ceBar\"}";
    firstEventPackageFields.partnerParameters = @"{\"pFoo\":\"pBar\",\"peFoo\":\"peBar\"}";

    [self testEventPackage:firstEventPackage fields:firstEventPackageFields eventToken:@"abc123"];

    // get the event
    ADJActivityPackage * secondEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create event package test
    ADJPackageFields * secondEventPackageFields = [ADJPackageFields fields];

    // set event test parameters
    secondEventPackageFields.eventCount = @"3";
    secondEventPackageFields.suffix = @"'abc123'";
    secondEventPackageFields.callbackParameters = @"{\"cFoo\":\"ceBar\"}";
    secondEventPackageFields.partnerParameters = @"{\"pFoo\":\"peBar\"}";

    [self testEventPackage:secondEventPackage fields:secondEventPackageFields eventToken:@"abc123"];
}

- (void)testDelayStartTimerFirst {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    [config setDelayStart:4];

    ADJActivityHandlerConstructorState * cState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];

    cState.sessionParametersActionsArray = @[^(ADJActivityHandler * activityHandler)
    {
        [activityHandler addSessionCallbackParameter:@"scpKey" value:@"scpValue"];
        [activityHandler addSessionPartnerParameter:@"sppKey" value:@"sppValue"];
    }];
    //  create handler and start the first session
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getActivityHandler:cState];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.delayStartConfigured = YES;

    [self checkInitAndStart:initState];

    [activityHandler applicationDidBecomeActive];
    [activityHandler applicationDidBecomeActive];

    // create the first Event object with callback and partner parameters
    ADJEvent * firstEvent = [ADJEvent eventWithEventToken:@"event1"];

    [firstEvent addCallbackParameter:@"keyCall" value:@"valueCall"];
    [firstEvent addPartnerParameter:@"keyPartner" value:@"valuePartner"];

    [activityHandler trackEvent:firstEvent];

    [NSThread sleepForTimeInterval:1.0];

    // test session
    ADJSessionState * subSesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    // foreground timer does not start XXX change so that fTimer does not pause
    subSesssionState.foregroundTimerStarts = NO;
    // delay start means it starts paused
    subSesssionState.toSend = NO;
    // sdk click handler does not start paused
    subSesssionState.sdkClickHandlerAlsoPauses = NO;
    // delay configured
    subSesssionState.delayStart = @"4.0";
    subSesssionState.subsessionCount = 2;

    [self checkStartInternal:subSesssionState];

    subSesssionState.delayStart = nil;
    subSesssionState.sessionType = ADJSessionTypeNonSession;

    [self checkStartInternal:subSesssionState];

    // check that event package was added and tried to send
    aTest(@"PackageHandler addPackage");
    aTest(@"PackageHandler sendFirstPackage");

    [NSThread sleepForTimeInterval:4.0];

    aVerbose(@"Delay Start timer fired");

    [self checkSendFirstPackages:YES internalState:[activityHandler internalState] activityStateCreated:YES pausing:NO];

    [activityHandler sendFirstPackages];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirstPackages:NO internalState:[activityHandler internalState] activityStateCreated:YES pausing:NO];

    // 1 session + 1 event
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    // get the first event
    ADJActivityPackage * firstEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create event package test
    ADJPackageFields * firstPackageFields = [ADJPackageFields fields];

    // set event test parameters
    firstPackageFields.eventCount = @"1";
    firstPackageFields.savedCallbackParameters = @{@"keyCall":@"valueCall"};
    firstPackageFields.savedPartnerParameters = @{@"keyPartner":@"valuePartner"};
    firstPackageFields.suffix = @"'event1'";

    // test first event
    [self testEventPackage:firstEventPackage fields:firstPackageFields eventToken:@"event1"];
}

- (void)testDelayStartSendFirst {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    [config setDelayStart:5];

    //  create handler and start the first session
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.delayStartConfigured = YES;

    [self checkInitAndStart:initState];

    [activityHandler applicationDidBecomeActive];
    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1.0];

    // test first subSession
    ADJSessionState * subSesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    // foreground timer does not start
    subSesssionState.foregroundTimerStarts = NO;
    // delay start means it starts paused
    subSesssionState.toSend = NO;
    // sdk click handler does not start paused
    subSesssionState.sdkClickHandlerAlsoPauses = NO;
    // delay configured
    subSesssionState.delayStart = @"5.0";
    subSesssionState.subsessionCount = 2;

    [self checkStartInternal:subSesssionState];

    subSesssionState.delayStart = nil;
    subSesssionState.sessionType = ADJSessionTypeNonSession;

    [self checkStartInternal:subSesssionState];

    [activityHandler sendFirstPackages];

    [NSThread sleepForTimeInterval:3.0];

    anVerbose(@"Delay Start timer fired");

    [self checkSendFirstPackages:YES internalState:[activityHandler internalState] activityStateCreated:YES pausing:NO];

    [activityHandler sendFirstPackages];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirstPackages:NO internalState:[activityHandler internalState] activityStateCreated:YES pausing:NO];
}

- (void)testUpdateStart {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    [config setDelayStart:10.1];

    //  create handler and start the first session
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.delayStartConfigured = YES;
    [self checkInitAndStart:initState];
    //[self checkInitTests:initState];

    [activityHandler applicationDidBecomeActive];

    [NSThread sleepForTimeInterval:1.0];

    // test session
    ADJSessionState * subSesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    // foreground timer does not start
    subSesssionState.foregroundTimerStarts = NO;
    // delay start means it starts paused
    subSesssionState.toSend = NO;
    // sdk click handler does not start paused
    subSesssionState.sdkClickHandlerAlsoPauses = NO;
    // delay configured
    subSesssionState.delayStart = @"10.1";
    subSesssionState.subsessionCount = 2;

    [self checkStartInternal:subSesssionState];

    //[self checkSendFirstPackages:YES internalState:[activityHandler internalState] activityStateCreated:YES pausing:NO];
    // did not update and send packages
    anTest(@"PackageHandler updatePackages");

    [activityHandler applicationWillResignActive];
    [NSThread sleepForTimeInterval:1.0];

    [self checkEndSession];
    [activityHandler teardown:NO];
    activityHandler = nil;
    [NSThread sleepForTimeInterval:1.0];

    ADJActivityHandlerConstructorState * cState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    cState.readActivityState = @"";
    cState.isToUpdatePackages = YES;
    id<ADJActivityHandler> restartActivityHandler = [self getActivityHandler:cState];
    [NSThread sleepForTimeInterval:1.0];

    // test init values
    ADJInitState * restartInitState = [[ADJInitState alloc] initWithActivityHandler:restartActivityHandler];

    // delay start not configured because activity state is already created
    restartInitState.updatePackages = YES;
    restartInitState.activityStateAlreadyCreated = YES;
    //restartInitState.readSessionParameters = @"";

    ADJSessionState * restartSubSesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];
    restartSubSesssionState.subsessionCount = 3;
    restartSubSesssionState.toSend = NO;

    [self checkInitAndStart:restartInitState sessionState:restartSubSesssionState];
}

- (void)testLogLevel {
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    config.logLevel = ADJLogLevelVerbose;
    config.logLevel = ADJLogLevelDebug;
    config.logLevel = ADJLogLevelInfo;
    config.logLevel = ADJLogLevelWarn;
    config.logLevel = ADJLogLevelError;
    config.logLevel = ADJLogLevelAssert;

    aTest(@"ADJLogger setLogLevel: 1");
    aTest(@"ADJLogger setLogLevel: 2");
    aTest(@"ADJLogger setLogLevel: 3");
    aTest(@"ADJLogger setLogLevel: 4");
    aTest(@"ADJLogger setLogLevel: 5");
    aTest(@"ADJLogger setLogLevel: 6");

    config.logLevel = ADJLogLevelSuppress;
    // chooses Assert because config object was not configured to allow suppress
    aTest(@"ADJLogger setLogLevel: 6");

    // init log level with assert because it was not configured to allow suppress
    config = [self getConfig:@"production" appToken:@"qwerty123456" allowSuppressLogLevel:NO initLogLevel:@"6"];

    config.logLevel = ADJLogLevelSuppress;
    // chooses Assert because config object was not configured to allow suppress
    aTest(@"ADJLogger setLogLevel: 6");

    // init with info because it's sandbox
    config = [self getConfig:@"sandbox" appToken:@"qwerty123456" allowSuppressLogLevel:YES initLogLevel:@"3"];

    config.logLevel = ADJLogLevelSuppress;
    // chooses Suppress because config object was configured to allow suppress
    aTest(@"ADJLogger setLogLevel: 7");

    // init with info because it's sandbox
    config = [self getConfig:@"production" appToken:@"qwerty123456" allowSuppressLogLevel:YES initLogLevel:@"7"];

    config.logLevel = ADJLogLevelAssert;
    // chooses Suppress because config object was configured to allow suppress
    aTest(@"ADJLogger setLogLevel: 7");
}

- (void)testTeardown {
    //  reseting to make the test order independent
    [self reset];

    //  change the timer defaults
    [ADJAdjustFactory setTimerInterval:4];
    //[ADJAdjustFactory setTimerStart:4];

    // create the config to start the session
    ADJConfig * config = [self getConfig];

    [config setDelayStart:4];
    [config setSendInBackground:YES];

    //  create handler and start the first session
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    initState.delayStartConfigured = YES;
    initState.sendInBackgroundConfigured = YES;
    initState.startsSending = NO;
    initState.sdkClickHandlerAlsoStartsPaused = NO;
    initState.foregroundTimerCycle = 4;

    // test session
    ADJSessionState * sesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    sesssionState.sendInBackgroundConfigured = YES;
    sesssionState.foregroundTimerStarts = NO;
    sesssionState.toSend = NO;
    sesssionState.sdkClickHandlerAlsoPauses = NO;

    [self checkInitAndStart:initState sessionState:sesssionState];

    //[NSThread sleepForTimeInterval:1.0];

    [activityHandler teardown:NO];
    aVerbose(@"ADJActivityHandler teardown");

    aTest(@"AttributionHandler teardown");
    aTest(@"PackageHandler teardown, deleteState: 0");
    aTest(@"SdkClickHandler teardown");

    // when timer is cancel, it tries to resume what was halted
    //aVerbose(@"Foreground timer dealloc");

    [NSThread sleepForTimeInterval:5.0];

    //[self checkEndSession];
    //[NSThread sleepForTimeInterval:5.0];
}

- (NSURL*)getUniversalLinkUrl:(NSString*)path
{
    return [NSURL URLWithString:[NSString
                                 stringWithFormat:@"https://[hash].ulink.adjust.com/ulink%@", path]];
}

- (NSURL*)getUniversalLinkUrl:(NSString*)path
                        query:(NSString*)query
                     fragment:(NSString*)fragment
{
    return [NSURL URLWithString:[NSString
                                 stringWithFormat:@"https://[hash].ulink.adjust.com/ulink%@%@%@", path, query, fragment]];
}

- (void)checkForegroundTimerFired:(BOOL)timerFired
{
    // timer fired
    if (timerFired) {
        aVerbose(@"Foreground timer fired");
    } else {
        anVerbose(@"Foreground timer fired");
    }
}

- (void)checkInitAndStart:(ADJInitState *)initState {
    [self checkInitTests:initState];

    [self checkFirstSession];
}

- (void)checkInitAndStartTestsWithHandler:(ADJActivityHandler *)activityHandler {
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    [self checkInitTests:initState];

    [self checkFirstSession];
}

- (void)checkInitAndStart:(ADJInitState *)initState
             sessionState:(ADJSessionState *)sessionState
{
    [self checkInitTests:initState];

    [self checkStartInternal:sessionState];
}

- (void)checkInitAndStartTestsWithHandler:(ADJActivityHandler *)activityHandler
                             sessionState:(ADJSessionState *)sessionState
{
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    [self checkInitTests:initState];

    [self checkStartInternal:sessionState];
}


- (void)checkInitTestsWithHandler:(ADJActivityHandler *)activityHandler {
    ADJInitState * initState = [[ADJInitState alloc] initWithActivityHandler:activityHandler];
    [self checkInitTests:initState];
}

- (void)checkInitTests:(ADJInitState *)initState
{
    if (initState.readCallbackParameters == nil) {
        aVerbose(@"Session Callback parameters file not found");
    } else {
        aDebug([@"Read Session Callback parameters: " stringByAppendingString:initState.readCallbackParameters]);
    }
    if (initState.readPartnerParameters == nil) {
        aVerbose(@"Session Partner parameters file not found");
    } else {
        aDebug([@"Read Session Partner parameters: " stringByAppendingString:initState.readPartnerParameters]);
    }

    // check event buffering
    if (initState.eventBufferingIsEnabled) {
        aInfo(@"Event buffering is enabled");
    } else {
        anInfo(@"Event buffering is enabled");
    }

    // check default tracker
    if (initState.defaultTracker != nil) {
        NSString * defaultTrackerLog = [NSString stringWithFormat:@"Default tracker: '%@'", initState.defaultTracker];
        aInfo(defaultTrackerLog);
    }

    NSString * foregroundLog = [NSString stringWithFormat:@"Foreground timer configured to fire after %d.0 seconds of starting and cycles every %d.0 seconds", initState.foregroundTimerStart, initState.foregroundTimerCycle];
    aVerbose(foregroundLog);

    if (initState.sendInBackgroundConfigured) {
        aInfo(@"Send in background configured");
    } else {
        anInfo(@"Send in background configured");
    }

    if (initState.delayStartConfigured) {
        aInfo(@"Delay start configured");
        aTrue(initState.internalState.delayStart);
    } else {
        anInfo(@"Delay start configured");
        aFalse(initState.internalState.delayStart);
    }

    if (initState.startsSending) {
        aTest(@"PackageHandler initWithActivityHandler, startsSending: 1");
    } else {
        aTest(@"PackageHandler initWithActivityHandler, startsSending: 0");
    }

    if (initState.updatePackages) {
        [self checkUpdatePackages:initState.internalState activityStateCreated:initState.activityStateAlreadyCreated];
    }

    if (initState.startsSending) {
        aTest(@"AttributionHandler initWithActivityHandler, startsSending: 1");
        aTest(@"SdkClickHandler initWithStartsSending, startsSending: 1");
    } else {
        aTest(@"AttributionHandler initWithActivityHandler, startsSending: 0");
        if (initState.sdkClickHandlerAlsoStartsPaused) {
            aTest(@"SdkClickHandler initWithStartsSending, startsSending: 0");
        } else {
            aTest(@"SdkClickHandler initWithStartsSending, startsSending: 1");
        }
    }
}

- (void)checkEndSession
{
    ADJEndSessionState * endState = [[ADJEndSessionState alloc] init];
    [self checkEndSession:endState];
}

- (void)checkEndSession:(ADJEndSessionState *)endState
{
    if (endState.checkOnPause) {
        [self checkOnPause:endState.forgroundAlreadySuspended
     backgroundTimerStarts:endState.backgroundTimerStarts];
    }

    if (endState.pausing) {
        [self checkHandlerStatus:endState.pausing
         eventBufferingIsEnabled:endState.eventBufferingEnabled
       sdkClickHandlerAlsoPauses:YES];
    }

    if (endState.updateActivityState) {
        aDebug(@"Wrote Activity state: ");
    } else {
        anDebug(@"Wrote Activity state: ");
    }
}

- (void) checkOnPause:(BOOL)foregroundAlreadySuspended
backgroundTimerStarts:(BOOL)backgroundTimerStarts
{
    // stop foreground timer
    if (foregroundAlreadySuspended) {
        aVerbose(@"Foreground timer is already suspended");
    } else {
        aVerbose(@"Foreground timer suspended");
    }

    // start background timer
    if (backgroundTimerStarts) {
        aVerbose(@"Background timer starting.");
    } else {
        anVerbose(@"Background timer starting.");
    }

    // starts the subsession
    aVerbose(@"Subsession end");
}

- (void)checkReadFiles:(NSString *)readActivityState
       readAttribution:(NSString *)readAttribution
{
    if (readAttribution == nil) {
        aVerbose(@"Attribution file not found");
    } else {
        aDebug([@"Read Attribution: " stringByAppendingString:readAttribution]);
    }

    if (readActivityState == nil) {
        aVerbose(@"Activity state file not found");
    } else {
        aDebug([@"Read Activity state: " stringByAppendingString:readActivityState]);
    }
}

- (ADJConfig *)getConfig {
    return [self getConfig:@"sandbox" appToken:@"qwerty123456" allowSuppressLogLevel:NO initLogLevel:@"3"];
}

- (ADJConfig *)getConfig:(NSString *)environment
                appToken:(NSString *)appToken
    allowSuppressLogLevel:(BOOL)allowSuppressLogLevel
            initLogLevel:(NSString *)initLogLevel
{
    ADJConfig * config = nil;

    if (allowSuppressLogLevel) {
        config = [ADJConfig configWithAppToken:appToken environment:environment allowSuppressLogLevel:YES];
    } else {
        config = [ADJConfig configWithAppToken:appToken environment:environment];
    }

    if (config != nil) {
        if (initLogLevel != nil) {
            aTest([@"ADJLogger setLogLevel: " stringByAppendingString:initLogLevel]);
        }
        if ([environment isEqualToString:ADJEnvironmentSandbox]) {
            aAssert(@"SANDBOX: Adjust is running in Sandbox mode. Use this setting for testing. Don't forget to set the environment to `production` before publishing");
        } else if ([environment isEqualToString:ADJEnvironmentProduction]) {
            aAssert(@"PRODUCTION: Adjust is running in Production mode. Use this setting only for the build that you want to publish. Set the environment to `sandbox` if you want to test your app!");
        } else {
            aFail();
        }
    }

    return config;
}

- (id<ADJActivityHandler>)startAndCheckFirstSession:(ADJConfig *)config
{
    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [self getFirstActivityHandler:config];

    [NSThread sleepForTimeInterval:2.0];

    [self checkInitAndStartTestsWithHandler:activityHandler];

    return activityHandler;
}

- (void)stopActivity:(id<ADJActivityHandler>)activityHandler {
    // stop activity
    [activityHandler applicationWillResignActive];

    ADJInternalState * internalState = [activityHandler internalState];

    // goes to the background
    aTrue([internalState isBackground]);
}

- (id<ADJActivityHandler>)getFirstActivityHandler:(ADJConfig *)config
{
    ADJActivityHandlerConstructorState * cState = [[ADJActivityHandlerConstructorState alloc] initWithConfig:config];
    return [self getActivityHandler:cState];
}

- (id<ADJActivityHandler>)getActivityHandler:(ADJActivityHandlerConstructorState *)cState
{
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:cState.config
                                                     sessionParametersActionsArray:cState.sessionParametersActionsArray];

    if (activityHandler != nil) {
        aTest(@"ADJLogger lockLogLevel");

        // check if files are read in constructor
        [self checkReadFiles:cState.readActivityState readAttribution:cState.readAttribution];

        ADJInternalState * internalState = [activityHandler internalState];
        // test default values
        aiEquals(cState.startEnabled, [internalState isEnabled]);
        aTrue([internalState isOnline]);
        aTrue([internalState isBackground]);
        aTrue([internalState isToStartNow]);
        aiEquals(cState.isToUpdatePackages, [internalState isToUpdatePackages]);
    }

    return activityHandler;
}

- (void)checkStartDisable {
    anTest(@"AttributionHandler resumeSending");
    anTest(@"PackageHandler resumeSending");
    anTest(@"SdkClickHandler resumeSending");
    anTest(@"AttributionHandler pauseSending");
    anTest(@"PackageHandler pauseSending");
    anTest(@"SdkClickHandler pauseSending");
    anTest(@"PackageHandler addPackage");
    anTest(@"PackageHandler sendFirstPackage");
    anVerbose(@"Started subsession");
    anVerbose(@"Time span since last activity too short for a new subsession");
    anError(@"Time travel!");
    anDebug(@"Wrote Activity state: ");
    anTest(@"AttributionHandler getAttribution");
    [self checkForegroundTimerFired:NO];
}

- (void)checkFirstSession {
    ADJSessionState * sesssionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];
    [self checkStartInternal:sesssionState];
}

- (void)checkSubSession:(NSInteger)sessionCount
        subsessionCount:(NSInteger)subsessionCount
 getAttributionIsCalled:(BOOL)getAttributionIsCalled
{
    ADJSessionState * subSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSubSession];

    subSessionState.sessionCount = sessionCount;
    subSessionState.subsessionCount = subsessionCount;
    subSessionState.getAttributionIsCalled = [NSNumber numberWithBool:getAttributionIsCalled];
    subSessionState.foregroundTimerAlreadyStarted = YES;
    subSessionState.toSend = YES;
    [self checkStartInternal:subSessionState];
}

- (void)checkFurtherSessions:(NSInteger)sessionCount
 getAttributionIsCalled:(BOOL)getAttributionIsCalled
{
    ADJSessionState * furtherSessionState = [ADJSessionState sessionStateWithSessionType:ADJSessionTypeSession];

    furtherSessionState.sessionCount = sessionCount;
    furtherSessionState.timerAlreadyStarted = YES;
    furtherSessionState.getAttributionIsCalled = [NSNumber numberWithBool:getAttributionIsCalled];
    furtherSessionState.foregroundTimerAlreadyStarted = YES;
    furtherSessionState.toSend = YES;

    [self checkStartInternal:furtherSessionState];
}

- (void)checkAppBecomeActive:(ADJSessionState *)sessionState {
    [self checkDelayStart:sessionState];

    // check applicationDidBecomeActive
    [self checkApplicationDidBecomeActive:sessionState];

    [self checkStartInternal:sessionState];
}

- (void)checkStartInternal:(ADJSessionState *)sessionState {
    // update Handlers Status
    [self checkHandlerStatus:!sessionState.toSend
     eventBufferingIsEnabled:sessionState.eventBufferingIsEnabled
     sdkClickHandlerAlsoPauses:sessionState.sdkClickHandlerAlsoPauses];

    // process Session
    switch (sessionState.sessionType) {
        case ADJSessionTypeSession:
        {
            // if the package was build, it was sent to the Package Handler
            aTest(@"PackageHandler addPackage");

            // after adding, the activity handler ping the Package handler to send the package
            aTest(@"PackageHandler sendFirstPackage");
            break;
        }
        case ADJSessionTypeSubSession:
        {
            // test the subsession message
            NSString * startedSubsessionLog = [NSString stringWithFormat:@"Started subsession %ld of session %ld",
                                               sessionState.subsessionCount, sessionState.sessionCount];
            aVerbose(startedSubsessionLog);
            break;
        }
        case ADJSessionTypeNonSession:
        {
            // stopped for a short time, not enough for a new sub subsession
            aVerbose(@"Time span since last activity too short for a new subsession");
            break;
        }
        case ADJSessionTypeTimeTravel:
        {
            aError(@"Time travel!");
            break;
        }
    }

    // after processing the session, writes the activity state
    if (sessionState.sessionType != ADJSessionTypeNonSession) {
        NSString * wroteActivityLog = [NSString stringWithFormat:@"Wrote Activity state: ec:%ld sc:%ld ssc:%ld",
                                       sessionState.eventCount, sessionState.sessionCount, sessionState.subsessionCount];
        aDebug(wroteActivityLog);
    }
    // check Attribution State
    if (sessionState.getAttributionIsCalled != nil) {
        if ([sessionState.getAttributionIsCalled boolValue]) {
            aTest(@"AttributionHandler getAttribution");
        } else {
            anTest(@"AttributionHandler getAttribution");
        }
    }
}

- (void)checkApplicationDidBecomeActive:(ADJSessionState *)sessionState {
    // stops background timer
    if (sessionState.sendInBackgroundConfigured) {
        aVerbose(@"Background timer canceled");
    } else {
        anVerbose(@"Background timer canceled");
    }

    // start foreground timer
    if (sessionState.foregroundTimerStarts) {
        if (sessionState.foregroundTimerAlreadyStarted) {
            aVerbose(@"Foreground timer is already started");
        } else {
            aVerbose(@"Foreground timer starting");
        }
    } else {
        anVerbose(@"Foreground timer is already started");
        anVerbose(@"Foreground timer starting");
    }

    // starts the subsession
    if (sessionState.startSubSession) {
        aVerbose(@"Subsession start");
    } else {
        anVerbose(@"Subsession start");
    }
}

- (void)checkHandlerStatus:(BOOL)pausing
{
    [self checkHandlerStatus:pausing eventBufferingIsEnabled:NO sdkClickHandlerAlsoPauses:YES];
}

- (void)checkHandlerStatus:(BOOL)pausing
 sdkClickHandlerAlsoPauses:(BOOL)sdkClickHandlerAlsoPauses

{
    [self checkHandlerStatus:pausing eventBufferingIsEnabled:NO sdkClickHandlerAlsoPauses:sdkClickHandlerAlsoPauses];
}


- (void)checkHandlerStatus:(BOOL)pausing
   eventBufferingIsEnabled:(BOOL)eventBufferingIsEnabled
 sdkClickHandlerAlsoPauses:(BOOL)sdkClickHandlerAlsoPauses
{
    if (pausing) {
        aTest(@"AttributionHandler pauseSending");
        aTest(@"PackageHandler pauseSending");
        if (sdkClickHandlerAlsoPauses) {
            aTest(@"SdkClickHandler pauseSending");
        } else {
            aTest(@"SdkClickHandler resumeSending");
        }
    } else {
        aTest(@"AttributionHandler resumeSending");
        aTest(@"PackageHandler resumeSending");
        aTest(@"SdkClickHandler resumeSending");
        if (!eventBufferingIsEnabled) {
            aTest(@"PackageHandler sendFirstPackage");
        }
    }
}

- (void)checkHandlerStatusNotCalled
{
    anTest(@"AttributionHandler pauseSending");
    anTest(@"PackageHandler pauseSending");
    anTest(@"SdkClickHandler pauseSending");
    anTest(@"AttributionHandler resumeSending");
    anTest(@"PackageHandler resumeSending");
    anTest(@"SdkClickHandler resumeSending");
}

- (void)checkFinishTasks:(NSObject<AdjustDelegate> *)delegateTest
attributionDelegatePresent:(BOOL)attributionDelegatePresent
eventSuccessDelegatePresent:(BOOL)eventSuccessDelegatePresent
eventFailureDelegatePresent:(BOOL)eventFailureDelegatePresent
sessionSuccessDelegatePresent:(BOOL)sessionSuccessDelegatePresent
sessionFailureDelegatePresent:(BOOL)sessionFailureDelegatePresent
{
    // create the config to start the session
    ADJConfig * config = [self getConfig];

    // set delegate
    [config setDelegate:delegateTest];

    if (attributionDelegatePresent) {
        aDebug(@"Delegate implements adjustAttributionChanged");
    } else {
        anDebug(@"Delegate implements adjustAttributionChanged");
    }
    if (eventSuccessDelegatePresent) {
        aDebug(@"Delegate implements adjustEventTrackingSucceeded");
    } else {
        anDebug(@"Delegate implements adjustEventTrackingSucceeded");
    }
    if (eventFailureDelegatePresent) {
        aDebug(@"Delegate implements adjustEventTrackingFailed");
    } else {
        anDebug(@"Delegate implements adjustEventTrackingFailed");
    }
    if (sessionSuccessDelegatePresent) {
        aDebug(@"Delegate implements adjustSessionTrackingSucceeded");
    } else {
        anDebug(@"Delegate implements adjustSessionTrackingSucceeded");
    }
    if (sessionFailureDelegatePresent) {
        aDebug(@"Delegate implements adjustSessionTrackingFailed");
    } else {
        anDebug(@"Delegate implements adjustSessionTrackingFailed");
    }

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [self startAndCheckFirstSession:config];

    // test first session package
    ADJActivityPackage * firstSessionPackage = self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * firstSessionPackageFields = [ADJPackageFields fields];

    firstSessionPackageFields.hasResponseDelegate =
        attributionDelegatePresent ||
        eventFailureDelegatePresent ||
        eventSuccessDelegatePresent ||
        sessionFailureDelegatePresent ||
        sessionSuccessDelegatePresent;

    // test first session
    [self testPackageSession:firstSessionPackage fields:firstSessionPackageFields sessionCount:@"1"];

    // simulate a successful session
    ADJSessionResponseData * successSessionResponseData = [ADJResponseData buildResponseData:firstSessionPackage];
    successSessionResponseData.success = YES;

    [activityHandler finishedTracking:successSessionResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // attribution handler should always receive the session response
    aTest(@"AttributionHandler checkSessionResponse");
    // the first session does not trigger the event response delegate
    anDebug(@"Launching success event tracking delegate");
    anDebug(@"Launching failed event tracking delegate");

    [activityHandler launchSessionResponseTasks:successSessionResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // if present, the first session triggers the success session delegate
    if (sessionSuccessDelegatePresent) {
        aDebug(@"Launching success session tracking delegate");
        aDebug(@"Launching in the background for testing");
        aTest(@"ADJTrackingSucceededDelegate adjustSessionTrackingSucceeded");
    } else {
        anDebug(@"Launching success session tracking delegate");
    }
    // it doesn't trigger the failure session delegate
    anDebug(@"Launching failed session tracking delegate");

    // simulate a failure session
    ADJSessionResponseData * failureSessionResponseData = [ADJResponseData buildResponseData:firstSessionPackage];
    failureSessionResponseData.success = NO;

    [activityHandler launchSessionResponseTasks:failureSessionResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // it doesn't trigger the success session delegate
    anDebug(@"Launching success session tracking delegate");

    // if present, the first session triggers the failure session delegate
    if (sessionFailureDelegatePresent) {
        aDebug(@"Launching failed session tracking delegate");
        aDebug(@"Launching in the background for testing");
        aTest(@"ADJTrackingFailedDelegate adjustSessionTrackingFailed");
    } else {
        anDebug(@"Launching failed session tracking delegate");
    }

    // test success event response data
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"abc123"]];
    [NSThread sleepForTimeInterval:1.0];

    ADJActivityPackage * eventPackage = self.packageHandlerMock.packageQueue[1];
    ADJEventResponseData * eventSuccessResponseData = [ADJResponseData buildResponseData:eventPackage];
    eventSuccessResponseData.success = YES;

    [activityHandler finishedTracking:eventSuccessResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // attribution handler should never receive the event response
    anTest(@"AttributionHandler checkSessionResponse");

    // if present, the success event triggers the success event delegate
    if (eventSuccessDelegatePresent) {
        aDebug(@"Launching success event tracking delegate");
        aDebug(@"Launching in the background for testing");
        aTest(@"ADJTrackingSucceededDelegate adjustEventTrackingSucceeded");
    } else {
        anDebug(@"Launching success event tracking delegate");
    }
    // it doesn't trigger the failure event delegate
    anDebug(@"Launching failed event tracking delegate");

    // test failure event response data
    ADJEventResponseData * eventFailureResponseData = [ADJResponseData buildResponseData:eventPackage];
    eventFailureResponseData.success = NO;

    [activityHandler finishedTracking:eventFailureResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // attribution handler should never receive the event response
    anTest(@"AttributionHandler checkSessionResponse");

    // if present, the failure event triggers the failure event delegate
    if (eventFailureDelegatePresent) {
        aDebug(@"Launching failed event tracking delegate");
        aDebug(@"Launching in the background for testing");
        aTest(@"ADJTrackingFailedDelegate adjustEventTrackingFailed");
    } else {
        anDebug(@"Launching failed event tracking delegate");
    }
    // it doesn't trigger the success event delegate
    anDebug(@"Launching success event tracking delegate");

    // test click
    NSURL* attributions = [NSURL URLWithString:@"AdjustTests://example.com/path/inApp?adjust_tracker=trackerValue&other=stuff&adjust_campaign=campaignValue&adjust_adgroup=adgroupValue&adjust_creative=creativeValue"];

    [activityHandler appWillOpenUrl:attributions];

    [NSThread sleepForTimeInterval:1.0];

    aTest(@"SdkClickHandler sendSdkClick");

    // test sdk_click response data
    ADJActivityPackage * sdkClickPackage = self.sdkClickHandlerMock.packageQueue[0];
    ADJClickResponseData * sdkClickResponseData = [ADJResponseData buildResponseData:sdkClickPackage];

    [activityHandler finishedTracking:sdkClickResponseData];
    [NSThread sleepForTimeInterval:1.0];

    // attribution handler should never receive the click response
    anTest(@"AttributionHandler checkSessionResponse");
    // it doesn't trigger the any event delegate
    anDebug(@"Launching success event tracking delegate");
    anDebug(@"Launching failed event tracking delegate");
}

- (void)checkDelayStart:(ADJSessionState *)sessionState {
    if (sessionState.delayStart == nil) {
        anWarn(@"Waiting");
        return;
    }

    if ([sessionState.delayStart isEqualToString:@"10.1"]) {
        aWarn(@"Delay start of 10.1 seconds bigger than max allowed value of 10.0 seconds");
        sessionState.delayStart = @"10.0";
    }

    NSString * waitingLog = [NSString stringWithFormat:@"Waiting %@ seconds before starting first session", sessionState.delayStart];
    aInfo(waitingLog);

    NSString * delayStartLog = [NSString stringWithFormat:@"Delay Start timer starting. Launching in %@ seconds", sessionState.delayStart];

    aVerbose(delayStartLog);

    if (sessionState.activityStateCreated) {
        aDebug(@"Wrote Activity state");
    }
}

- (void)checkSendFirstPackages:(BOOL)delayStart
                 internalState:(ADJInternalState *)internalState
          activityStateCreated:(BOOL)activityStateCreated
                       pausing:(BOOL)pausing
{
    if (!delayStart) {
        aInfo(@"Start delay expired or never configured");
        anTest(@"PackageHandler updatePackages");
        return;
    }
    anInfo(@"Start delay expired or never configured");

    // update packages
    aTest(@"PackageHandler updatePackages");
    aFalse(internalState.updatePackages);
    if (activityStateCreated) {
        aDebug(@"Wrote Activity state");
    }
    // no longer is in delay start
    aFalse(internalState.delayStart);

    // cancel timer
    aVerbose(@"Delay Start timer canceled");

    [self checkHandlerStatus:pausing sdkClickHandlerAlsoPauses:NO];
}

- (void)checkUpdatePackages:(ADJInternalState *)internalState
     activityStateCreated:(BOOL)activityStateCreated
{
    aTest(@"PackageHandler updatePackages");
    aFalse(internalState.updatePackages);
    if (activityStateCreated) {
        aDebug(@"Wrote Activity state");
    } else {
        anDebug(@"Wrote Activity state");
    }
}
@end
