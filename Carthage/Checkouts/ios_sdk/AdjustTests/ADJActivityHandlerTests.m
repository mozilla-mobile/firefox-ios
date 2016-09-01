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
#import "ADJDelegateTest.h"
#import "ADJTestActivityPackage.h"

@interface ADJActivityHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJPackageHandlerMock *packageHandlerMock;
@property (atomic,strong) ADJAttributionHandlerMock *attributionHandlerMock;

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
    [ADJAdjustFactory setPackageHandler:nil];
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
    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    self.packageHandlerMock = [ADJPackageHandlerMock alloc];
    [ADJAdjustFactory setPackageHandler:self.packageHandlerMock];

    [ADJAdjustFactory setSessionInterval:-1];
    [ADJAdjustFactory setSubsessionInterval:-1];
    [ADJAdjustFactory setTimerInterval:-1];
    [ADJAdjustFactory setTimerStart:-1];

    self.attributionHandlerMock = [ADJAttributionHandlerMock alloc];
    [ADJAdjustFactory setAttributionHandler:self.attributionHandlerMock];

    // starting from a clean slate
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoActivityState" logger:self.loggerMock], @"%@", self.loggerMock);
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoAttribution" logger:self.loggerMock], @"%@", self.loggerMock);
}

- (void)testFirstSession
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    //  create handler and start the first session
    [ADJActivityHandler handlerWithConfig:config];

    // it's necessary to sleep the activity for a while after each handler call
    //  to let the internal queue act
    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    // check event buffering is disabled
    anInfo(@"Event buffering is enabled");

    // check does not have default tracker
    anInfo(@"Default tracker:");

    // test first session start
    [self checkFirstSession];

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
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // buffer events
    config.eventBufferingEnabled = YES;

    // set verbose log level
    config.logLevel = ADJLogLevelVerbose;

    // set default tracker
    [config setDefaultTracker:@"default1234tracker"];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"1"];

    // check event buffering is enabled
    aInfo(@"Event buffering is enabled");

    // check does have default tracker
    aInfo(@"Default tracker: default1234tracker");

    // test first session start
    [self checkFirstSession];

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

    // after tracking the event it should write the activity state
    aDebug(@"Wrote Activity state: ec:2");

    // create a forth Event object without revenue
    ADJEvent * forthEvent = [ADJEvent eventWithEventToken:@"event4"];

    // test push token
    const char bytes[] = "\xFC\x07\x21\xB6\xDF\xAD\x5E\xE1\x10\x97\x5B\xB2\xA2\x63\xDE\x00\x61\xCC\x70\x5B\x4A\x85\xA8\xAE\x3C\xCF\xBE\x7A\x66\x2F\xB1\xAB";
    [activityHandler setDeviceToken:[NSData dataWithBytes:bytes length:(sizeof(bytes) - 1)]];

    // track the forth event
    [activityHandler trackEvent:forthEvent];

    [NSThread sleepForTimeInterval:2];

    // check that event package was added
    aTest(@"PackageHandler addPackage");

    // check that event was buffered
    aInfo(@"Buffered event 'event4'");

    // and not sent to package handler
    anTest(@"PackageHandler sendFirstPackage");

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

    // test first event
    [self testEventSession:firstEventPackage fields:firstPackageFields eventToken:@"event1"];

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

    // test third event
    [self testEventSession:thirdEventPackage fields:thirdPackageFields eventToken:@"event3"];

    // fourth event
    ADJActivityPackage * fourthEventPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[3];

    // create event package test
    ADJPackageFields * fourthPackageFields = [ADJPackageFields fields];

    // set event test parameters
    fourthPackageFields.eventCount = @"3";
    fourthPackageFields.suffix = @"'event4'";
    fourthPackageFields.pushToken = @"fc0721b6dfad5ee110975bb2a263de0061cc705b4a85a8ae3ccfbe7a662fb1ab";

    // test fourth event
    [self testEventSession:fourthEventPackage fields:fourthPackageFields eventToken:@"event4"];
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
    id<ADJActivityHandler> nilConfigActivityHandler = [ADJActivityHandler handlerWithConfig:nil];

    aError(@"AdjustConfig missing");
    aNil(nilConfigActivityHandler);

    // activity handler created with an invalid config
    id<ADJActivityHandler> invalidConfigActivityHandler = [ADJActivityHandler handlerWithConfig:nilAppTokenConfig];

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
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set the log level
    config.logLevel = ADJLogLevelDebug;

    //  set the delegate that doesn't implement the optional selector
    ADJTestsUtil * delegateNotImpl = [[ADJTestsUtil alloc] init];
    [config setDelegate:delegateNotImpl];

    aError(@"Delegate does not implement AdjustDelegate");

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler =[ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:2];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"2"];

    // test first session start
    [self checkFirstSession];

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

    sessionPackageFields.hasDelegate = @"0";

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
    [self testEventSession:eventPackage fields:eventFields eventToken:@"event1"];
}

- (void)testSessons
{
    //  reseting to make the test order independent
    [self reset];

    //  adjust the intervals for testing
    [ADJAdjustFactory setSessionInterval:(4)]; // 4 seconds
    [ADJAdjustFactory setSubsessionInterval:(1)]; // 1 second

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set verbose log level
    config.logLevel = ADJLogLevelInfo;

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:2];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    // test first session start
    [self checkFirstSession];

    // trigger a new sub session session
    [activityHandler trackSubsessionStart];

    // and end it
    [activityHandler trackSubsessionEnd];

    [NSThread sleepForTimeInterval:5];

    [self checkSubsession:1 subSessionCount:2 timerAlreadyStarted:YES];

    [self checkEndSession];

    // trigger a new session
    [activityHandler trackSubsessionStart];

    [NSThread sleepForTimeInterval:1];

    // new session
    [self checkNewSession:NO
             sessionCount:2
               eventCount:0
     timerAlreadyStarted:YES];

    // end the session
    [activityHandler trackSubsessionEnd];

    [NSThread sleepForTimeInterval:1];

    [self checkEndSession];

    // 2 session packages
    aiEquals(2, (int)[self.packageHandlerMock.packageQueue count]);

    // first session
    ADJActivityPackage *firstSessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * firstSessionfields = [ADJPackageFields fields];

    // test first session
    [self testPackageSession:firstSessionPackage fields:firstSessionfields sessionCount:@"1"];

    // get second session package
    ADJActivityPackage *secondSessionPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create second session test package
    ADJPackageFields * secondSessionfields = [ADJPackageFields fields];

    // check if it saved the second subsession in the new package
    secondSessionfields.subSessionCount = @"2";

    // test second session
    [self testPackageSession:secondSessionPackage fields:secondSessionfields sessionCount:@"2"];
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
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set log level
    config.logLevel = ADJLogLevelWarn;

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    // check that is true by default
    aTrue([activityHandler isEnabled]);

    // disable sdk
    [activityHandler setEnabled:NO];

    // check that it is disabled
    aFalse([activityHandler isEnabled]);

    // not writing activity state because it did not had time to start
    anDebug(@"Wrote Activity state");

    // check if message the disable of the SDK
    aInfo(@"Pausing package handler and attribution handler to disable the SDK");

    // it's necessary to sleep the activity for a while after each handler call
    // to let the internal queue act
    [NSThread sleepForTimeInterval:2];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"4"];

    // test first session start without attribution handler
    [self checkFirstSession:YES];

    // test end session of disable
    [self checkEndSession];

    // try to do activities while SDK disabled
    [activityHandler trackSubsessionStart];
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:3];

    // check that timer was not executed
    anDebug(@"Session timer fired");

    // check that it did not resume
    anTest(@"PackageHandler resumeSending");

    // check that it did not wrote activity state from new session or subsession
    anDebug(@"Wrote Activity state");

    // check that it did not add any event package
    anTest(@"PackageHandler addPackage");

    // only the first session package should be sent
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    // put in offline mode
    [activityHandler setOfflineMode:YES];

    // pausing due to offline mode
    aInfo(@"Pausing package and attribution handler to put in offline mode");

    // wait to update status
    [NSThread sleepForTimeInterval:6.0];

    // test end session of offline
    [self checkEndSession];

    // re-enable the SDK
    [activityHandler setEnabled:YES];

    // check that it is enabled
    aTrue([activityHandler isEnabled]);

    // check message of SDK still paused
    aInfo(@"Package and attribution handler remain paused due to the SDK is offline");

    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:1.0];

    [self checkNewSession:YES sessionCount:2 eventCount:0 timerAlreadyStarted:NO];

    // and that the timer is not fired
    anDebug(@"Session timer fired");
    
    // track an event
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:1.0];

    // check that it did add the event package
    aTest(@"PackageHandler addPackage");

    // and send it
    aTest(@"PackageHandler sendFirstPackage");

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
    [self testEventSession:eventPackage fields:eventFields eventToken:@"event1"];

    // put in online mode
    [activityHandler setOfflineMode:NO];

    // message that is finally resuming
    aInfo(@"Resuming package handler and attribution handler to put in online mode");

    [NSThread sleepForTimeInterval:6.0];

    // check status update
    aTest(@"AttributionHandler resumeSending");
    aTest(@"PackageHandler resumeSending");

    // track sub session
    [activityHandler trackSubsessionStart];

    [NSThread sleepForTimeInterval:1.0];

    // test sub session not paused
    [self checkNewSession:NO sessionCount:3 eventCount:1 timerAlreadyStarted:YES];
}

- (void)testAppWillOpenUrl
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set log level
    config.logLevel = ADJLogLevelError;

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    // it's necessary to sleep the activity for a while after each handler call
    //  to let the internal queue act
    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"5"];

    // test first session start
    [self checkFirstSession];

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

    [NSThread sleepForTimeInterval:2];

    // three click packages: attributions, extraParams and mixed
    for (int i = 3; i > 0; i--) {
        aTest(@"PackageHandler addPackage");
    }

    // checking the default values of the first session package
    // 1 session + 3 click
    aiEquals(4, (int)[self.packageHandlerMock.packageQueue count]);

    // get the click package
    ADJActivityPackage * attributionClickPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

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

    // test the first deeplink
    [self testClickPackage:attributionClickPackage fields:attributionClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * extraParamsClickPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[2];

    // create activity package test
    ADJPackageFields * extraParamsClickFields = [ADJPackageFields fields];

    // other deep link parameters
    extraParamsClickFields.deepLinkParameters = @"{\"key\":\"value\",\"foo\":\"bar\"}";

    // test the second deeplink
    [self testClickPackage:extraParamsClickPackage fields:extraParamsClickFields source:@"deeplink"];

    // get the click package
    ADJActivityPackage * mixedClickPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[3];

    // create activity package test
    ADJPackageFields * mixedClickFields = [ADJPackageFields fields];

    // create the attribution
    ADJAttribution * secondAttribution = [[ADJAttribution alloc] init];
    secondAttribution.campaign = @"campaignValue";
    secondAttribution.adgroup = @"adgroupValue";
    secondAttribution.creative = @"creativeValue";

    // and set it
    mixedClickFields.attribution = secondAttribution;

    // other deep link parameters
    mixedClickFields.deepLinkParameters = @"{\"foo\":\"bar\"}";

    // test the third deeplink
    [self testClickPackage:mixedClickPackage fields:mixedClickFields source:@"deeplink"];
}

- (void)testIad
{
    //  reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set log level
    config.logLevel = ADJLogLevelAssert;

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    // it's necessary to sleep the activity for a while after each handler call
    //  to let the internal queue act
    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"6"];

    // test first session start
    [self checkFirstSession];

    // should be ignored
    [activityHandler setIadDate:nil withPurchaseDate:nil];
    [NSThread sleepForTimeInterval:1];

    // check that iAdImpressionDate was not received.
    aVerbose(@"iAdImpressionDate not received");

    // didn't send click package
    anTest(@"PackageHandler addPackage");

    [activityHandler setIadDate:nil withPurchaseDate:[NSDate date]];
    [NSThread sleepForTimeInterval:1];

    // check that iAdImpressionDate was not received.
    aVerbose(@"iAdImpressionDate not received");

    // didn't send click package
    anTest(@"PackageHandler addPackage");


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
    NSString * iAdImpressionDate1Log =[NSString stringWithFormat:@"iAdImpressionDate received: %@", date1];
    aVerbose(iAdImpressionDate1Log);

    // first iad package added
    aTest(@"PackageHandler addPackage");

    [activityHandler setIadDate:date2 withPurchaseDate:nil];
    [NSThread sleepForTimeInterval:1];

    // iAdImpressionDate received
    NSString * iAdImpressionDate2Log =[NSString stringWithFormat:@"iAdImpressionDate received: %@", date2];
    aVerbose(iAdImpressionDate2Log);

    // second iad package added
    aTest(@"PackageHandler addPackage");

    // 1 session + 2 click packages
    aiEquals(3, (int)[self.packageHandlerMock.packageQueue count]);

    // first iad package
    ADJActivityPackage *firstIadPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[1];

    // create activity package test
    ADJPackageFields * firstIadFields = [ADJPackageFields fields];

    firstIadFields.iadTime = date1String;
    firstIadFields.purchaseTime = date2String;

    // test the click package
    [self testClickPackage:firstIadPackage fields:firstIadFields source:@"iad"];

    // second iad package
    ADJActivityPackage * secondIadPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[2];

    // create activity package test
    ADJPackageFields * secondIadFields = [ADJPackageFields fields];

    secondIadFields.iadTime = date2String;

    // test the click package
    [self testClickPackage:secondIadPackage fields:secondIadFields source:@"iad"];
}

- (void)testFinishedTracking
{
    // reseting to make the test order independent
    [self reset];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentProduction];

    // set verbose log level
    config.logLevel = ADJLogLevelDebug;

    // set delegate
    ADJDelegateTest * delegateTests = [[ADJDelegateTest alloc] init];
    [config setDelegate:delegateTests];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentProduction logLevel:@"6"];

    // test first session start
    [self checkFirstSession];

    // test nil response
    [activityHandler finishedTracking:nil];
    [NSThread sleepForTimeInterval:1.0];

    // if the response is null
    anTest(@"AttributionHandler checkAttribution");
    anTest(@"Unable to open deep link");
    anTest(@"Open deep link");

    // set package handler to respond with a valid attribution

    NSString * deeplinkString = @"{\"deeplink\":\"wrongDeeplink://\"}";
    NSData * deeplinkData = [deeplinkString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary * deeplinkDictionary = [ADJUtil buildJsonDict:deeplinkData];

    anNil(deeplinkDictionary);

    [activityHandler finishedTracking:deeplinkDictionary];

    [NSThread sleepForTimeInterval:1.0];

    // check that it was unable to open the url
    aError(@"Unable to open deep link (wrongDeeplink://)");

    // and it check the attribution
    aTest(@"AttributionHandler checkAttribution");
    // TODO add test that opens url

    // checking the default values of the first session package
    //  should only have one package
    aiEquals(1, (int)[self.packageHandlerMock.packageQueue count]);

    ADJActivityPackage *activityPackage = (ADJActivityPackage *) self.packageHandlerMock.packageQueue[0];

    // create activity package test
    ADJPackageFields * fields = [ADJPackageFields fields];

    fields.hasDelegate = @"1";
    fields.environment = @"production";

    // set first session
    [self testPackageSession:activityPackage fields:fields sessionCount:@"1"];
}

- (void)testUpdateAttribution
{
    // reseting to make the test order independent
    [self reset];

    // create the config
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // start the session
    id<ADJActivityHandler> activityHandler =[ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:2];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    // test first session start
    [self checkFirstSession];

    // check if Attribution is not created with nil
    ADJAttribution * nilAttribution = [[ADJAttribution alloc] initWithJsonDict:nil];

    aNil(nilAttribution);

    // check it does not update a nil attribution
    aFalse([activityHandler updateAttribution:nilAttribution]);

    // create an empty attribution
    NSMutableDictionary * emptyJsonDictionary = [[NSMutableDictionary alloc] init];
    ADJAttribution * emptyAttribution = [[ADJAttribution alloc] initWithJsonDict:emptyJsonDictionary];

    // check that updates attribution
    aTrue([activityHandler updateAttribution:emptyAttribution]);
    aDebug(@"Wrote Attribution: tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null)");

    // check that it did not launch a non existent delegate
    // not possible to test in iOs
    //[NSThread sleepForTimeInterval:1];
    //anTest(@"ADJDelegateTest adjustAttributionChanged");

    emptyAttribution = [[ADJAttribution alloc] initWithJsonDict:emptyJsonDictionary];

    // check that it does not update the attribution
    aFalse([activityHandler updateAttribution:emptyAttribution]);
    anDebug(@"Wrote Attribution");

    // end session
    [activityHandler trackSubsessionEnd];
    [NSThread sleepForTimeInterval:2];

    [self checkEndSession];

    // create the new config
    config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set delegate to see attribution launched
    ADJDelegateTest * delegateTests = [[ADJDelegateTest alloc] init];
    [config setDelegate:delegateTests];

    id<ADJActivityHandler> restartActivityHandler = [ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:3];

    // test init values
    [self checkInit:ADJEnvironmentSandbox
           logLevel:@"3"
  readActivityState:@"ec:0 sc:1 ssc:1"
    readAttribution:@"tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null)"];

    // test second subsession
    [self checkSubsession:1 subSessionCount:2 timerAlreadyStarted:NO];

    // check that it does not update the attribution after the restart
    aFalse([restartActivityHandler updateAttribution:emptyAttribution]);
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
    NSDictionary * firstAttributionDictionary = [ADJUtil buildJsonDict:firstAttributionData];

    anNil(firstAttributionDictionary);

    ADJAttribution * firstAttribution = [[ADJAttribution alloc] initWithJsonDict:firstAttributionDictionary];

    //check that it updates
    aTrue([restartActivityHandler updateAttribution:firstAttribution]);
    aDebug(@"Wrote Attribution: tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");

    // check that it launch the saved attribute
    // not possible to test in iOs
    //[NSThread sleepForTimeInterval:2];
    //aTest(@"ADJDelegateTest adjustAttributionChanged, tt:null tn:null net:null cam:null adg:null cre:null cl:null");

    // check that it does not update the attribution
    aFalse([restartActivityHandler updateAttribution:firstAttribution]);
    anDebug(@"Wrote Attribution");

    // end session
    [restartActivityHandler trackSubsessionEnd];
    [NSThread sleepForTimeInterval:2];

    [self checkEndSession];

    // create the new config
    config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set delegate to see attribution launched
    [config setDelegate:delegateTests];

    id<ADJActivityHandler> secondRestartActivityHandler = [ADJActivityHandler handlerWithConfig:config];

    [NSThread sleepForTimeInterval:3];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3" readActivityState:@"ec:0 sc:1 ssc:2" readAttribution:@"tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue"];

    // test third subsession
    [self checkSubsession:1 subSessionCount:3 timerAlreadyStarted:NO];

    // check that it does not update the attribution after the restart
    aFalse([secondRestartActivityHandler updateAttribution:firstAttribution]);
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
    NSDictionary * secondAttributionDictionary = [ADJUtil buildJsonDict:secondAttributionData];

    anNil(secondAttributionDictionary);

    ADJAttribution * secondAttribution = [[ADJAttribution alloc] initWithJsonDict:secondAttributionDictionary];

    //check that it updates
    aTrue([secondRestartActivityHandler updateAttribution:secondAttribution]);
    aDebug(@"Wrote Attribution: tt:ttValue2 tn:tnValue2 net:nValue2 cam:cpValue2 adg:aValue2 cre:ctValue2 cl:clValue2");

    // check that it launch the saved attribute
    // not possible to test in iOs
    //[NSThread sleepForTimeInterval:1];
    //aTest(@"onAttributionChanged: tt:ttValue2 tn:tnValue2 net:nValue2 cam:cpValue2 adg:aValue2 cre:ctValue2 cl:clValue2");

    // check that it does not update the attribution
    aFalse([secondRestartActivityHandler updateAttribution:secondAttribution]);
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
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    // put SDK offline
    [activityHandler setOfflineMode:YES];

    [NSThread sleepForTimeInterval:3];

    // check if message the disable of the SDK
    aInfo(@"Pausing package and attribution handler to put in offline mode");

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    // test first session start
    [self checkFirstSession:YES];

    // test end session logs
    [self checkEndSession];

    // disable the SDK
    [activityHandler setEnabled:NO];

    // check that it is disabled
    aFalse([activityHandler isEnabled]);

    // writing activity state after disabling
    aDebug(@"Wrote Activity state: ec:0 sc:1 ssc:1");

    // check if message the disable of the SDK
    aInfo(@"Pausing package handler and attribution handler to disable the SDK");

    [NSThread sleepForTimeInterval:1];

    // test end session logs
    [self checkEndSession];

    // put SDK back online
    [activityHandler setOfflineMode:NO];

    aInfo(@"Package and attribution handler remain paused because the SDK is disabled");

    [NSThread sleepForTimeInterval:1];

    // doesn't pause if it was already paused
    anTest(@"AttributionHandler pauseSending");
    anTest(@"PackageHandler pauseSending");

    // try to do activities while SDK disabled
    [activityHandler trackSubsessionStart];
    [activityHandler trackEvent:[ADJEvent eventWithEventToken:@"event1"]];

    [NSThread sleepForTimeInterval:3];

    // check that timer was not executed
    [self checkTimerIsFired:NO];

    // check that it did not wrote activity state from new session or subsession
    anDebug(@"Wrote Activity state");

    // check that it did not add any package
    anTest(@"PackageHandler addPackage");

    // enable the SDK again
    [activityHandler setEnabled:YES];

    // check that is enabled
    aTrue([activityHandler isEnabled]);

    [NSThread sleepForTimeInterval:1];

    // check that it re-enabled
    aInfo(@"Resuming package handler and attribution handler to enabled the SDK");

    // test that is not paused anymore
    [self checkNewSession:NO sessionCount:2 eventCount:0];
}

- (void)testGetAttribution
{
    //  reseting to make the test order independent
    [self reset];

    //  adjust the intervals for testing
    [ADJAdjustFactory setTimerStart:0.5]; // 0.5 second
    [ADJAdjustFactory setSessionInterval:(4)]; // 4 second

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    // set delegate
    ADJDelegateTest * delegateTests = [[ADJDelegateTest alloc] init];
    [config setDelegate:delegateTests];

    //  create handler and start the first session
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];

    // it's necessary to sleep the activity for a while after each handler call
    //  to let the internal queue act
    [NSThread sleepForTimeInterval:3.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    /***
     * // if it' a new session
     * if (self.activityState.subsessionCount <= 1) {
     *     return;
     * }
     *
     * // if there is already an attribution saved and there was no attribution being asked
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
    [self checkFirstSession];

    // test that get attribution wasn't called
    anTest(@"AttributionHandler getAttribution");

    // subsession count increased to 2
    // attribution is still null,
    // askingAttribution is still false,
    // -> Called

    // trigger a new sub session
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:1 subSessionCount:2 timerAlreadyStarted:YES getAttributionIsCalled:YES];

    // subsession count increased to 3
    // attribution is still null,
    // askingAttribution is set to true,
    // -> Called

    // set asking attribution
    [activityHandler setAskingAttribution:YES];
    aDebug(@"Wrote Activity state: ec:0 sc:1 ssc:2");

    // trigger a new session
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:1 subSessionCount:3 timerAlreadyStarted:YES getAttributionIsCalled:YES];

    // subsession is reset to 1 with new session
    // attribution is still null,
    // askingAttribution is set to true,
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:2 subSessionCount:1 timerAlreadyStarted:YES getAttributionIsCalled:NO];

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
    NSDictionary * attributionDictionary = [ADJUtil buildJsonDict:attributionData];

    anNil(attributionDictionary);

    ADJAttribution * attribution = [[ADJAttribution alloc] initWithJsonDict:attributionDictionary];

    // update the attribution
    [activityHandler updateAttribution:attribution];

    // attribution was updated
    aDebug(@"Wrote Attribution: tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");

    // trigger a new sub session
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:2 subSessionCount:2 timerAlreadyStarted:YES getAttributionIsCalled:YES];

    // subsession count is reset to 1
    // attribution is set,
    // askingAttribution is set to true,
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:3 subSessionCount:1 timerAlreadyStarted:YES getAttributionIsCalled:NO];

    // subsession increased to 2
    // attribution is set,
    // askingAttribution is set to false
    // -> Not called

    [activityHandler setAskingAttribution:NO];
    aDebug(@"Wrote Activity state: ec:0 sc:3 ssc:1");

    // trigger a new sub session
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:3 subSessionCount:2 timerAlreadyStarted:YES getAttributionIsCalled:NO];

    // subsession is reset to 1
    // attribution is set,
    // askingAttribution is set to false
    // -> Not called

    [NSThread sleepForTimeInterval:3.0]; // 5 seconds = 2 + 3
    [activityHandler trackSubsessionStart];
    [NSThread sleepForTimeInterval:2.0];

    [self checkSubsession:4 subSessionCount:1 timerAlreadyStarted:YES getAttributionIsCalled:NO];
}

- (void)testTimer
{
    //  reseting to make the test order independent
    [self reset];

    //  change the timer defaults
    [ADJAdjustFactory setTimerInterval:4];
    [ADJAdjustFactory setTimerStart:0];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];

    //  create handler and start the first session
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config];
#pragma clang diagnostic pop

    // it's necessary to sleep the activity for a while after each handler call
    //  to let the internal queue act
    [NSThread sleepForTimeInterval:2.0];

    // test init values
    [self checkInit:ADJEnvironmentSandbox logLevel:@"3"];

    // test first session start
    [self checkFirstSession];

    // wait enough to fire the first cycle
    [NSThread sleepForTimeInterval:3.0];

    [self checkTimerIsFired:YES];

    // end subsession to stop timer
    //[activityHandler trackSubsessionEnd];

    // wait enough for a new cycle
    //[NSThread sleepForTimeInterval:6.0];

    //[activityHandler trackSubsessionStart];

    //[NSThread sleepForTimeInterval:1.0];

    //[self checkTimerIsFired:NO];
}

- (void)checkInit:(NSString *)environment
         logLevel:(NSString *)logLevel
{
    [self checkInit:environment logLevel:logLevel readActivityState:nil readAttribution:nil];
}

- (void)checkInit:(NSString *)environment
         logLevel:(NSString *)logLevel
readActivityState:(NSString *)readActivityState
  readAttribution:(NSString *)readAttribution
{

    // check environment level
    if ([environment isEqualToString:ADJEnvironmentSandbox]) {
        aAssert(@"SANDBOX: Adjust is running in Sandbox mode. Use this setting for testing. Don't forget to set the environment to `production` before publishing");
    } else if ([environment isEqualToString:ADJEnvironmentProduction]) {
        aAssert(@"PRODUCTION: Adjust is running in Production mode. Use this setting only for the build that you want to publish. Set the environment to `sandbox` if you want to test your app!");
    } else {
        aFail();
    }

    // check log level
    aTest([@"ADJLogger setLogLevel: " stringByAppendingString:logLevel]);

    // check read files
    [self checkReadFiles:readActivityState readAttribution:readAttribution];

    // tries to read iad v3
    aDebug(@"iAd with 5 tries to read v3");

    // iad is not disabled
    anDebug(@"ADJUST_NO_IAD or TARGET_OS_TV set");
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

- (void)checkFirstSession:(BOOL)paused
{
    // test if package handler started paused
    if (paused) {
        aTest(@"PackageHandler initWithActivityHandler, paused: 1");
    } else {
        aTest(@"PackageHandler initWithActivityHandler, paused: 0");
    }

    [self checkNewSession:paused
             sessionCount:1
               eventCount:0
      timerAlreadyStarted:NO];
}

- (void)checkFirstSession
{
    [self checkFirstSession:NO];
}

- (void)checkNewSession:(BOOL)paused
           sessionCount:(int)sessionCount
             eventCount:(int)eventCount
{
    [self checkNewSession:paused sessionCount:sessionCount eventCount:eventCount timerAlreadyStarted:NO];
}
- (void)checkNewSession:(BOOL)paused
           sessionCount:(int)sessionCount
             eventCount:(int)eventCount
    timerAlreadyStarted:(BOOL)timerAlreadyStarted
{
    // when a session package is being sent the attribution handler should resume sending
    if (paused) {
        aTest(@"AttributionHandler pauseSending");
    } else {
        aTest(@"AttributionHandler resumeSending");
    }

    // when a session package is being sent the package handler should resume sending
    if (paused) {
        aTest(@"PackageHandler pauseSending");
    } else {
        aTest(@"PackageHandler resumeSending");
    }

    // if the package was build, it was sent to the Package Handler
    aTest(@"PackageHandler addPackage");

    // after adding, the activity handler ping the Package handler to send the package
    aTest(@"PackageHandler sendFirstPackage");

    // after sending a package saves the activity state
    NSString * aStateWrote = [NSString stringWithFormat:@"Wrote Activity state: ec:%d sc:%d ssc:1", eventCount, sessionCount];
    aDebug(aStateWrote);

    [self checkTimerIsFired:!(paused || timerAlreadyStarted)];
}

- (void)checkSubsession:(int)sessionCount
       subSessionCount:(int)subsessionCount
    timerAlreadyStarted:(BOOL)timerAlreadyStarted
 getAttributionIsCalled:(BOOL)getAttributionIsCalled
{
    [self checkSubsession:sessionCount subSessionCount:subsessionCount];

    if (getAttributionIsCalled) {
        aTest(@"AttributionHandler getAttribution");
    } else {
        anTest(@"AttributionHandler getAttribution");
    }

    [self checkTimerIsFired:!timerAlreadyStarted];
}

- (void)checkSubsession:(int)sessionCount
        subSessionCount:(int)subsessionCount
    timerAlreadyStarted:(BOOL)timerAlreadyStarted
{
    [self checkSubsession:sessionCount subSessionCount:subsessionCount];

    [self checkTimerIsFired:!timerAlreadyStarted];
}

- (void)checkSubsession:(int)sessionCount
        subSessionCount:(int)subsessionCount
{
    // test the new sub session
    aTest(@"PackageHandler resumeSending");

    // save activity state
    NSString * aStateWrote = [NSString stringWithFormat:@"Wrote Activity state: ec:0 sc:%d ssc:%d", sessionCount, subsessionCount];
    aDebug(aStateWrote);
    //aDebug(@"Wrote Activity state: ec:0 sc:1 ssc:2");

    if (subsessionCount > 1) {
        // test the subsession message
        NSString * subsessionStarted = [NSString stringWithFormat:@"Started subsession %d of session %d", subsessionCount, sessionCount];
        aInfo(subsessionStarted);
    } else {
        // test the subsession message
        anInfo(@"Started subsession ");
    }
}

- (void)checkEndSession
{
    aTest(@"PackageHandler pauseSending");
    aTest(@"AttributionHandler pauseSending");
    aDebug(@"Wrote Activity state:");
}

- (void)checkTimerIsFired:(BOOL)timerFired
{
    if(timerFired) {
        aDebug(@"Session timer fired");
    } else {
        anDebug(@"Session timer fired");
    }
}

@end
