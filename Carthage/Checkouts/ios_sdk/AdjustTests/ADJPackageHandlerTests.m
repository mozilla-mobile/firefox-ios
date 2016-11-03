//
//  ADJPackageHandlerTests.m
//  Adjust
//
//  Created by Pedro Filipe on 07/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ADJAdjustFactory.h"
#import "ADJLoggerMock.h"
#import "ADJActivityHandlerMock.h"
#import "ADJRequestHandlerMock.h"
#import "ADJTestsUtil.h"
#import "ADJTestActivityPackage.h"
#import "ADJResponseData.h"
#import "ADJBackoffStrategy.h"
#import "ADJPackageHandler.h"
#import "ADJAttributionHandlerMock.h"
#import "ADJPackageHandlerMock.h"
#import "ADJSdkClickHandlerMock.h"
#import "ADJSessionParameters.h"

typedef enum {
    ADJSendFirstEmptyQueue = 0,
    ADJSendFirstPaused = 1,
    ADJSendFirstIsSending = 2,
    ADJSendFirstSend = 3,
} ADJSendFirst;

@interface ADJPackageHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJRequestHandlerMock *requestHandlerMock;
@property (atomic,strong) ADJActivityHandlerMock *activityHandlerMock;

@end

@implementation ADJPackageHandlerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    [ADJAdjustFactory setRequestHandler:nil];
    [ADJAdjustFactory setLogger:nil];

    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)reset {
    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    self.requestHandlerMock = [ADJRequestHandlerMock alloc];
    [ADJAdjustFactory setRequestHandler:self.requestHandlerMock];

    ADJConfig * config = [ADJConfig configWithAppToken:@"123456789012" environment:ADJEnvironmentSandbox];
    self.activityHandlerMock = [[ADJActivityHandlerMock alloc] initWithConfig:config sessionParametersActionsArray:nil];

    //  delete previously created Package queue file to make a new queue
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoPackageQueue" logger:self.loggerMock], @"%@", self.loggerMock);
}

- (void)testAddPackage
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler];

    ADJActivityPackage *firstClickPackage = [ADJTestsUtil getClickPackage:@"FirstPackage"];

    [packageHandler addPackage:firstClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkAddPackage:1 packageString:@"clickFirstPackage"];

    id<ADJPackageHandler> secondPackageHandler = [self checkAddSecondPackage:nil];
    
    ADJActivityPackage *secondClickPackage = [ADJTestsUtil getClickPackage:@"ThirdPackage"];

    [secondPackageHandler addPackage:secondClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkAddPackage:3 packageString:@"clickThirdPackage"];

    // send the first click package/ first package
    [secondPackageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"RequestHandler sendPackage, activityPackage clickFirstPackage");
    aTest(@"RequestHandler sendPackage, queueSize 2");

    // send the second package
    [secondPackageHandler sendNextPackage:nil];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"RequestHandler sendPackage, activityPackage unknownSecondPackage");
    aTest(@"RequestHandler sendPackage, queueSize 1");

    // send the unknow package/ second package
    [secondPackageHandler sendNextPackage:nil];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"RequestHandler sendPackage, activityPackage clickThirdPackage");
    aTest(@"RequestHandler sendPackage, queueSize 0");
}

- (void)testSendFirst
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler];

    [self checkSendFirst:ADJSendFirstEmptyQueue];

    [self checkAddAndSendFirst:packageHandler];

    // try to send when it is still sending
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    // try to send paused
    [packageHandler pauseSending];
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstPaused];

    // unpause, it's still sending
    [packageHandler resumeSending];
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    // verify that both paused and isSending are reset with a new session
    id<ADJPackageHandler> secondpackageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self.activityHandlerMock
                                                                                  startsSending:YES];

    [secondpackageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    // send the package to request handler
    [self checkSendFirst:ADJSendFirstSend queueSize:0 packageString:@"unknownFirstPackage"];
}

- (void)testSendNext
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler];

    // add and send the first package
    [self checkAddAndSendFirst:packageHandler];

    // try to send when it is still sending
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    // add a second package
    [self checkAddSecondPackage:packageHandler];

    //send next package
    [packageHandler sendNextPackage:nil];
    [NSThread sleepForTimeInterval:2.0];

    aDebug(@"Package handler wrote 1 packages");

    // try to send the second package
    [self checkSendFirst:ADJSendFirstSend queueSize:0 packageString:@"unknownSecondPackage"];
}

- (void)testCloseFirstPackage
{
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setPackageHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoWait]];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler];

    [self checkAddAndSendFirst:packageHandler];

    // try to send when it is still sending
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    //send next package
    ADJActivityPackage *activityPackage = [[ADJActivityPackage alloc] init];
    ADJResponseData * responseData = [ADJResponseData buildResponseData:activityPackage];
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:2.0];

    aTest(@"ActivityHandler finishedTracking, message:(null) timestamp:(null) adid:(null)");
    aVerbose(@"Package handler can send");

    anDebug(@"Package handler wrote");

    // tries to send the next package after sleeping
    [self checkSendFirst:ADJSendFirstSend queueSize:0 packageString:@"unknownFirstPackage"];
}

- (void) testBackoffJitter
{
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setPackageHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJTestWait]];

    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler];

    ADJActivityPackage * activityPackage = [ADJTestsUtil getUnknowPackage:@"FirstPackage"];

    ADJResponseData * responseData = [ADJResponseData buildResponseData:activityPackage];
    //Pattern pattern = Pattern.compile("Sleeping for (\\d+\\.\\d) seconds before retrying the (\\d+) time");

    NSString * sleepingLogPattern = @"Waiting for (\\d+\\.\\d) seconds before retrying the (\\d+) time";
    NSError *error = NULL;
    NSRegularExpression *regex  = [NSRegularExpression
                                   regularExpressionWithPattern:sleepingLogPattern
                                   options:NSRegularExpressionCaseInsensitive
                                   error:&error];

    if (error != nil) {
        [self.loggerMock test:@"regex error %@", error.description];
        aFail();
    }

    // 1st
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    NSString * sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);
    // Sleeping for 0.1 seconds before retrying the 1 time

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:0.1
               maxRange:0.2
             maxCeiling:1
             minCeiling:0.5
          numberRetries:1];

    // 2nd
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:0.2
               maxRange:0.4
             maxCeiling:1
             minCeiling:0.5
          numberRetries:2];

    // 3rd
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:0.4
               maxRange:0.8
             maxCeiling:1
             minCeiling:0.5
          numberRetries:3];

    // 4th
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:0.8
               maxRange:1.6
             maxCeiling:1
             minCeiling:0.5
          numberRetries:4];

    // 5th
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:1.6
               maxRange:3.2
             maxCeiling:1
             minCeiling:0.5
          numberRetries:5];

    // 6th
    [packageHandler closeFirstPackage:responseData activityPackage:activityPackage];
    [NSThread sleepForTimeInterval:1.5];

    sleepingLogMessage = [self.loggerMock containsMessage:ADJLogLevelVerbose beginsWith:@"Waiting for"];
    anNil(sleepingLogMessage);

    [self checkSleeping:regex
            sleepingLog:sleepingLogMessage
               minRange:6.4
               maxRange:12.8
             maxCeiling:1
             minCeiling:0.5
          numberRetries:6];
}

- (void)testUpdate
{
    //  reseting to make the test order independent
    [self reset];

    NSArray * delayPackages = [self createDelayPackages];

    ADJActivityPackage * firstSessionPackage = delayPackages[0];
    ADJActivityPackage * firstEventPackage = delayPackages[1];
    ADJActivityPackage * secondEventPackage = delayPackages[2];

    // create event package test
    ADJPackageFields * sessionPackageFields = [ADJPackageFields fields];

    [self testPackageSession:firstSessionPackage fields:sessionPackageFields sessionCount:@"1"];

    // create event package test
    ADJPackageFields * firstEventPackageFields = [ADJPackageFields fields];

    // set event test parameters
    firstEventPackageFields.eventCount = @"1";
    firstEventPackageFields.savedCallbackParameters = @{@"ceFoo":@"ceBar"};
    firstEventPackageFields.savedPartnerParameters = @{@"peFoo":@"peBar"};
    firstEventPackageFields.suffix = @"'event1'";

    // test first event
    [self testEventPackage:firstEventPackage fields:firstEventPackageFields eventToken:@"event1"];

    // create event package test
    ADJPackageFields * secondEventPackageFields = [ADJPackageFields fields];

    // set event test parameters
    secondEventPackageFields.eventCount = @"2";
    secondEventPackageFields.savedCallbackParameters = @{@"scpKey":@"ceBar"};
    secondEventPackageFields.savedPartnerParameters = @{@"sppKey":@"peBar"};
    secondEventPackageFields.suffix = @"'event2'";

    // test second event
    [self testEventPackage:secondEventPackage fields:secondEventPackageFields eventToken:@"event2"];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createFirstPackageHandler:NO];

    [self checkSendFirst:ADJSendFirstEmptyQueue];

    [packageHandler addPackage:firstSessionPackage];

    [packageHandler addPackage:firstEventPackage];

    [packageHandler addPackage:secondEventPackage];

    [NSThread sleepForTimeInterval:1];

    [self checkAddPackage:1 packageString:@"session"];

    [self checkAddPackage:2 packageString:@"event'event1'"];

    [self checkAddPackage:3 packageString:@"event'event2'"];

    [packageHandler updatePackages:nil];

    [NSThread sleepForTimeInterval:1];

    aDebug(@"Updating package handler queue");

    aVerbose(@"Session callback parameters: (null)");
    aVerbose(@"Session partner parameters: (null)");

    ADJSessionParameters * sessionParameters = [[ADJSessionParameters alloc] init];

    sessionParameters.callbackParameters = [NSMutableDictionary dictionary];
    [sessionParameters.callbackParameters setObject:@"scpValue" forKey:@"scpKey"];

    sessionParameters.partnerParameters = [NSMutableDictionary dictionary];
    [sessionParameters.partnerParameters setObject:@"sppValue" forKey:@"sppKey"];


    [packageHandler updatePackages:sessionParameters];

    [NSThread sleepForTimeInterval:2];

    aDebug(@"Updating package handler queue");

    aVerbose(@"Session callback parameters: {\n    scpKey = scpValue;\n}");
    aVerbose(@"Session partner parameters: {\n    sppKey = sppValue;\n}");

    aWarn(@"Key scpKey with value scpValue from Callback parameter was replaced by value ceBar");
    aWarn(@"Key sppKey with value sppValue from Partner parameter was replaced by value peBar");
    aDebug(@"Package handler wrote 3 packages");
    
    sessionPackageFields.callbackParameters = @"{\"scpKey\":\"scpValue\"}";
    sessionPackageFields.partnerParameters = @"{\"sppKey\":\"sppValue\"}";

    [self testPackageSession:firstSessionPackage fields:sessionPackageFields sessionCount:@"1"];

    firstEventPackageFields.callbackParameters = @"{\"scpKey\":\"scpValue\",\"ceFoo\":\"ceBar\"}";
    firstEventPackageFields.partnerParameters = @"{\"peFoo\":\"peBar\",\"sppKey\":\"sppValue\"}";

    [self testEventPackage:firstEventPackage fields:firstEventPackageFields eventToken:@"event1"];

    secondEventPackageFields.callbackParameters = @"{\"scpKey\":\"ceBar\"}";
    secondEventPackageFields.partnerParameters = @"{\"sppKey\":\"peBar\"}";

    [self testEventPackage:secondEventPackage fields:secondEventPackageFields eventToken:@"event2"];
}

- (NSArray *)createDelayPackages {
    ADJPackageHandlerMock * packageHandlerMock = [ADJPackageHandlerMock alloc];
    [ADJAdjustFactory setPackageHandler:packageHandlerMock];

    ADJSdkClickHandlerMock * sdkClickHandlerMock = [ADJSdkClickHandlerMock alloc];
    [ADJAdjustFactory setSdkClickHandler:sdkClickHandlerMock];

    ADJAttributionHandlerMock * attributionHandlerMock = [ADJAttributionHandlerMock alloc];
    [ADJAdjustFactory setAttributionHandler:attributionHandlerMock];

    [ADJAdjustFactory setSessionInterval:-1];
    [ADJAdjustFactory setSubsessionInterval:-1];
    [ADJAdjustFactory setTimerInterval:-1];
    [ADJAdjustFactory setTimerStart:-1];

    [ADJTestsUtil deleteFile:@"AdjustIoActivityState" logger:self.loggerMock];
    [ADJTestsUtil deleteFile:@"AdjustIoAttribution" logger:self.loggerMock];
    [ADJTestsUtil deleteFile:@"AdjustSessionParameters" logger:self.loggerMock];
    [ADJTestsUtil deleteFile:@"AdjustSessionCallbackParameters" logger:self.loggerMock];
    [ADJTestsUtil deleteFile:@"AdjustSessionPartnerParameters" logger:self.loggerMock];

    ADJConfig * config = [ADJConfig configWithAppToken:@"qwerty123456" environment:ADJEnvironmentSandbox];

    [config setDelayStart:4];

    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config sessionParametersActionsArray:nil];

    [activityHandler addSessionCallbackParameter:@"scpKey" value:@"scpValue"];
    [activityHandler addSessionPartnerParameter:@"sppKey" value:@"sppValue"];

    [activityHandler applicationDidBecomeActive];

    ADJEvent * event1 = [ADJEvent eventWithEventToken:@"event1"];
    [event1 addCallbackParameter:@"ceFoo" value:@"ceBar"];
    [event1 addPartnerParameter:@"peFoo" value:@"peBar"];
    [activityHandler trackEvent:event1];

    ADJEvent * event2 = [ADJEvent eventWithEventToken:@"event2"];
    [event2 addCallbackParameter:@"scpKey" value:@"ceBar"];
    [event2 addPartnerParameter:@"sppKey" value:@"peBar"];
    [activityHandler trackEvent:event2];

    [NSThread sleepForTimeInterval:3.0];

    ADJActivityPackage * firstSessionPackage = packageHandlerMock.packageQueue[0];

    ADJActivityPackage * firstEventPackage = packageHandlerMock.packageQueue[1];
    ADJActivityPackage * secondEventPackage = packageHandlerMock.packageQueue[2];

    [self.loggerMock reset];

    return @[firstSessionPackage, firstEventPackage, secondEventPackage];
}

- (void)checkSleeping:(NSRegularExpression *)regex
          sleepingLog:(NSString *)sleepingLog
             minRange:(double)minRange
             maxRange:(double)maxRange
           maxCeiling:(NSInteger)maxCeiling
           minCeiling:(double)minCeiling
        numberRetries:(NSInteger)numberRetries
{
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:sleepingLog options:0 range:NSMakeRange(0, [sleepingLog length])];

    if ([matches count] == 0) {
        aFail();
    }

    NSTextCheckingResult *match = matches[0];

    if ([match numberOfRanges] != 3) {
        aFail();
    }

    NSString * sleepingTimeString = [sleepingLog substringWithRange:[match rangeAtIndex:1]];
    double sleepingTime = [sleepingTimeString doubleValue];

    [self.loggerMock test:@"sleeping time %f", sleepingTime];

    BOOL failsCeiling = sleepingTime > maxCeiling;
    aFalse(failsCeiling);

    if (maxRange < maxCeiling) {
        BOOL failsMinRange = sleepingTime < minRange;
        aFalse(failsMinRange);
    } else {
        BOOL failsMinRange = sleepingTime < minCeiling ;
        aFalse(failsMinRange);
    }

    if (maxRange < maxCeiling) {
        BOOL failsMaxRange = sleepingTime > maxRange;
        aFalse(failsMaxRange);
    } else {
        BOOL failsMaxRange = sleepingTime > maxCeiling;
        aFalse(failsMaxRange);
    }

    NSString * retryTimeString = [sleepingLog substringWithRange:[match rangeAtIndex:2]];
    NSInteger retryTime = [retryTimeString integerValue];

    [self.loggerMock test:@"retry time %ld", retryTime];

    aliEquals(numberRetries, retryTime);
}

- (id<ADJPackageHandler>)createFirstPackageHandler
{
    return [self createFirstPackageHandler:YES];
}

- (id<ADJPackageHandler>)createFirstPackageHandler:(BOOL)startsSending
{
    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [ADJPackageHandler handlerWithActivityHandler:self.activityHandlerMock startsSending:startsSending];

    [NSThread sleepForTimeInterval:2.0];

    aVerbose(@"Package queue file not found");

    return packageHandler;
}

- (id<ADJPackageHandler>)checkAddSecondPackage
{
    id<ADJPackageHandler> packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self.activityHandlerMock
                                                            startsSending:YES];

    [NSThread sleepForTimeInterval:2.0];

    ADJActivityPackage * secondActivityPackage = [ADJTestsUtil getUnknowPackage:@"SecondPackage"];

    [packageHandler addPackage:secondActivityPackage];
    [NSThread sleepForTimeInterval:1.0];

    return packageHandler;
}


- (id<ADJPackageHandler>)checkAddSecondPackage:(id<ADJPackageHandler>)packageHandler
{
    if (packageHandler == nil) {
        packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self.activityHandlerMock
                                                                startsSending:YES];

        [NSThread sleepForTimeInterval:2.0];

        anVerbose(@"Package queue file not found");

        // check that it can read the previously saved package
        aDebug(@"Package handler read 1 packages");
    }

    ADJActivityPackage * secondActivityPackage = [ADJTestsUtil getUnknowPackage:@"SecondPackage"];

    [packageHandler addPackage:secondActivityPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkAddPackage:2 packageString:@"unknownSecondPackage"];

    return packageHandler;
}

- (void)checkAddAndSendFirst:(id<ADJPackageHandler>)packageHandler
{
    // add a package
    ADJActivityPackage *firstActivityPackage = [ADJTestsUtil getUnknowPackage:@"FirstPackage"];

    // send the first package
    [packageHandler addPackage:firstActivityPackage];

    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:2.0];

    [self checkAddPackage:1 packageString:@"unknownFirstPackage"];

    [self checkSendFirst:ADJSendFirstSend queueSize:0 packageString:@"unknownFirstPackage"];
}

- (void)checkSendFirst:(ADJSendFirst)sendFirstState
{
    [self checkSendFirst:sendFirstState queueSize:0 packageString:nil];
}
- (void)checkSendFirst:(ADJSendFirst)sendFirstState
             queueSize:(NSUInteger)queueSize
         packageString:(NSString*)packageString
{
    if (sendFirstState == ADJSendFirstPaused) {
        aDebug(@"Package handler is paused");
    } else {
        anDebug(@"Package handler is paused");
    }

    if (sendFirstState == ADJSendFirstIsSending) {
        aVerbose(@"Package handler is already sending");
    } else {
        anVerbose(@"Package handler is already sending");
    }

    if (sendFirstState == ADJSendFirstSend) {
        NSString * aActivitySend = [NSString stringWithFormat:@"RequestHandler sendPackage, activityPackage %@", packageString];
        aTest(aActivitySend);
        NSString * aQueueSizeSend = [NSString stringWithFormat:@"RequestHandler sendPackage, queueSize %lu", queueSize];
        aTest(aQueueSizeSend);
    } else {
        anTest(@"RequestHandler sendPackage");
    }
}

- (void)checkAddPackage:(int)packageNumber
          packageString:(NSString*)packageString
{
    NSString * aAdded = [NSString stringWithFormat:@"Added package %d (%@)", packageNumber, packageString];
    aDebug(aAdded);

    NSString * aPackagesWrote = [NSString stringWithFormat:@"Package handler wrote %d packages", packageNumber];
    aDebug(aPackagesWrote);
}

@end
