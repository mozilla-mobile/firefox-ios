//
//  ADJClickHandlerTests.m
//  Adjust
//
//  Created by Pedro Filipe on 19/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ADJTestActivityPackage.h"
#import "ADJAdjustFactory.h"
#import "ADJLoggerMock.h"
#import "NSURLConnection+NSURLConnectionSynchronousLoadingMocking.h"
#import "NSURLSession+NSURLDataWithRequestMocking.h"
#import "ADJActivityHandlerMock.h"
#import "ADJSdkClickHandlerMock.h"
#import "ADJAttributionHandlerMock.h"
#import "ADJPackageHandlerMock.h"
#import "ADJBackoffStrategy.h"
#import "ADJSdkClickHandler.h"

@interface ADJSdkClickHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJActivityHandlerMock *activityHandlerMock;
@property (atomic,strong) ADJActivityPackage * sdkClickPackage;

@end

@implementation ADJSdkClickHandlerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    [ADJAdjustFactory setLogger:nil];

    // Put teardown code here; it will be run once, after the last test case.
    [ADJAdjustFactory setPackageHandler:nil];
    [ADJAdjustFactory setAttributionHandler:nil];
    [NSURLSession reset];

    [super tearDown];
}

- (void)reset {
    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    ADJConfig * config = [ADJConfig configWithAppToken:@"qwerty123456" environment:ADJEnvironmentSandbox];

    self.activityHandlerMock = [[ADJActivityHandlerMock alloc] initWithConfig:config sessionParametersActionsArray:nil];
    self.sdkClickPackage = [self getClickPackage];

    [NSURLSession reset];
}

- (void) testPaused {
    //  reseting to make the test order independent
    [self reset];

    self.sdkClickPackage.clientSdk = @"Test-First-Click";

    ADJActivityPackage * secondSdkClickPackage = [self getClickPackage];
    secondSdkClickPackage.clientSdk = @"Test-Second-Click";

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoWait]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:NO];

    [NSURLSession setResponseType:ADJSessionResponseTypeConnError];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    // added first click package to the queue
    aDebug(@"Added sdk_click 1");
    aVerbose(@"Path:      /sdk_click\nClientSdk: Test-First-Click");

    // but not send because it's paused
    anTest(@"NSURLSession dataTaskWithRequest");

    // send second sdk click
    [sdkClickHandler sendSdkClick:secondSdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    // added second click package to the queue
    aDebug(@"Added sdk_click 2");

    aVerbose(@"Path:      /sdk_click\nClientSdk: Test-Second-Click");

    // wait two seconds before sending
    [NSURLSession setWaitingTime:2];

    // try to send first package
    [self checkSendPackage:sdkClickHandler retries:1 clientSdk:@"Test-First-Click"];
    // and then the second
    [self checkSendPackage:sdkClickHandler retries:1 clientSdk:@"Test-Second-Click"];

    // try to send first package again
    [self checkSendPackage:sdkClickHandler retries:2 clientSdk:@"Test-First-Click"];
    // and then the second again
    [self checkSendPackage:sdkClickHandler retries:2 clientSdk:@"Test-Second-Click"];
}

- (void)testNullResponse {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoRetry]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeNil];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    aDebug(@"Added sdk_click 1");

    //assertUtil.test("MockHttpsURLConnection getInputStream, responseType: null");
    aTest(@"NSURLSession dataTaskWithRequest");

    aError(@"Failed to track click (empty error) Will retry later");

    // tries to retry
    aError(@"Retrying sdk_click package for the 1 time");

    // adds to end of the queue
    aDebug(@"Added sdk_click 1");

    // waiting to try again
    aVerbose(@"Waiting for");
}

- (void)testClientException {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoRetry]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeConnError];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    //assertUtil.test("MockHttpsURLConnection getInputStream, responseType: CLIENT_PROTOCOL_EXCEPTION");
    aTest(@"NSURLSession dataTaskWithRequest");

    aError(@"Failed to track click (connection error) Will retry later");

    // tries to retry
    aError(@"Retrying sdk_click package for the 1 time");

    // adds to end of the queue
    aDebug(@"Added sdk_click 1");

    // waiting to try again
    aVerbose(@"Waiting for");
}

- (void)testServerError {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoWait]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeServerError];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"NSURLSession dataTaskWithRequest");

    aVerbose(@"Response: { \"message\": \"testResponseError\"}");

    aError(@"testResponseError");
}

- (void)testWrongJson {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoRetry]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeWrongJson];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"NSURLSession dataTaskWithRequest");

    aVerbose(@"Response: not a json response");

    aError(@"Failed to parse json response. (The data couldn’t be read because it isn’t in the correct format.)");
}

- (void)testEmptyJson {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoRetry]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeEmptyJson];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"NSURLSession dataTaskWithRequest");

    aVerbose(@"Response: { }");

    aInfo(@"No message found");
}

- (void)testMessage {
    //  reseting to make the test order independent
    [self reset];

    [ADJAdjustFactory setSdkClickHandlerBackoffStrategy:[ADJBackoffStrategy backoffStrategyWithType:ADJNoRetry]];

    id<ADJSdkClickHandler> sdkClickHandler = [ADJSdkClickHandler handlerWithStartsSending:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeMessage];

    [sdkClickHandler sendSdkClick:self.sdkClickPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"NSURLSession dataTaskWithRequest");

    aVerbose(@"Response: { \"message\" : \"response OK\"}");

    aInfo(@"response OK");
}
- (void)checkSendPackage:(id<ADJSdkClickHandler>)sdkClickHandler
                 retries:(NSInteger)retries
               clientSdk:(NSString *)clientSdk
{
    // try to send the second package that is at the start of the queue
    [sdkClickHandler resumeSending];

    [NSThread sleepForTimeInterval:1.0];

    // prevent sending next again
    [sdkClickHandler pauseSending];

    [NSThread sleepForTimeInterval:2.0];

    // check that it tried to send the second package
    //assertUtil.test("MockHttpsURLConnection setRequestProperty, field Client-SDK, newValue Test-Second-Click");

    // and that it will try to send it again
    NSString * errorLog = [NSString stringWithFormat:@"Retrying sdk_click package for the %ld time", retries];
    aError(errorLog);

    // second package added again on the end of the queue
    aDebug(@"Added sdk_click 2");

    NSString * messageLog = [NSString stringWithFormat:@"Path:      /sdk_click\nClientSdk: %@", clientSdk];
    aVerbose(messageLog);

    // does not continue to send because it was paused
    //assertUtil.notInTest("MockHttpsURLConnection setRequestProperty");
}




- (ADJActivityPackage *) getClickPackage {
    ADJSdkClickHandlerMock * mockSdkClickHandler = [ADJSdkClickHandlerMock alloc];
    ADJAttributionHandlerMock * mockAttributionHandler = [ADJAttributionHandlerMock alloc];

    ADJPackageHandlerMock * mockPackageHandler = [ADJPackageHandlerMock alloc];

    [ADJAdjustFactory setPackageHandler:mockPackageHandler];
    [ADJAdjustFactory setSdkClickHandler:mockSdkClickHandler];
    [ADJAdjustFactory setAttributionHandler:mockAttributionHandler];

    // create the config to start the session
    ADJConfig * config = [ADJConfig configWithAppToken:@"qwerty123456" environment:@"sandbox"];

    // start activity handler with config
    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config sessionParametersActionsArray:nil];
    [activityHandler applicationDidBecomeActive];
    [activityHandler appWillOpenUrl:[NSURL URLWithString:@"AdjustTests://"]];
    [NSThread sleepForTimeInterval:2.0];

    ADJActivityPackage * sdkClickPackage = (ADJActivityPackage *) mockSdkClickHandler.packageQueue[0];
    [self.loggerMock reset];

    return sdkClickPackage;
}


@end
