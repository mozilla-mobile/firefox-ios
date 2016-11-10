//
//  ADJAttributionHandlerTests.m
//  adjust
//
//  Created by Pedro Filipe on 12/12/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "ADJAdjustFactory.h"
#import "ADJLoggerMock.h"
#import "NSURLConnection+NSURLConnectionSynchronousLoadingMocking.h"
#import "NSURLSession+NSURLDataWithRequestMocking.h"
#import "ADJTestsUtil.h"
#import "ADJActivityHandlerMock.h"
#import "ADJAttributionHandlerMock.h"
#import "ADJAttributionHandler.h"
#import "ADJPackageHandlerMock.h"
#import "ADJUtil.h"
#import "ADJTestActivityPackage.h"

@interface ADJAttributionHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJActivityHandlerMock *activityHandlerMock;
@property (atomic,strong) ADJActivityPackage * attributionPackage;
@property (atomic,strong) ADJActivityPackage * firstSessionPackage;

@end

@implementation ADJAttributionHandlerTests

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
    [NSURLConnection reset];

    [super tearDown];
}

- (void)reset {
    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    ADJConfig * config = [ADJConfig configWithAppToken:@"qwerty123456" environment:ADJEnvironmentSandbox];

    self.activityHandlerMock = [[ADJActivityHandlerMock alloc] initWithConfig:config
                                                sessionParametersActionsArray:nil];
    [self savePackages:config];
    [NSURLConnection reset];
}

- (void)savePackages:(ADJConfig *)config {
    ADJAttributionHandlerMock * attributionHandlerMock = [ADJAttributionHandlerMock alloc];
    [ADJAdjustFactory setAttributionHandler:attributionHandlerMock];

    ADJPackageHandlerMock * packageHandlerMock = [ADJPackageHandlerMock alloc];
    [ADJAdjustFactory setPackageHandler:packageHandlerMock];

    [ADJAdjustFactory setSessionInterval:-1];
    [ADJAdjustFactory setSubsessionInterval:-1];
    [ADJAdjustFactory setTimerInterval:-1];
    [ADJAdjustFactory setTimerStart:-1];

    [ADJTestsUtil deleteFile:@"AdjustIoActivityState" logger:self.loggerMock];
    [ADJTestsUtil deleteFile:@"AdjustIoAttribution" logger:self.loggerMock];

    id<ADJActivityHandler> activityHandler = [ADJActivityHandler handlerWithConfig:config sessionParametersActionsArray:nil];
    [activityHandler applicationDidBecomeActive];
    [NSThread sleepForTimeInterval:5.0];

    ADJActivityPackage * attributionPackage = attributionHandlerMock.attributionPackage;

    ADJPackageFields * fields = [ADJPackageFields fields];

    [self testAttributionPackage:attributionPackage fields:fields];

    self.firstSessionPackage = packageHandlerMock.packageQueue[0];

    self.attributionPackage = attributionPackage;

    [self.loggerMock reset];
}

- (void)testGetAttribution
{
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:YES hasAttributionChangedDelegate:YES];

    // test null response without error
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeNil];

    // check empty error
    aError(@"Failed to get attribution (empty error)");

    // check response was not logged
    anVerbose(@"Response");

    // test client exception
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeConnError];

    // check the client error
    aError(@"Failed to get attribution (connection error)");

    // test wrong json response
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeWrongJson];

    aVerbose(@"Response: not a json response");

    aError(@"Failed to parse json response. (The data couldn’t be read because it isn’t in the correct format.)");

    // test empty response
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeEmptyJson];

    aVerbose(@"Response: { }");

    aInfo(@"No message found");

    aTest(@"ActivityHandler setAskingAttribution, 0");

    // check attribution was called without ask_in
    aTest(@"ActivityHandler launchAttributionResponseTasks, message:(null) timestamp:(null) adid:(null) success:1 willRetry:0 attribution:(null) deeplink:(null) json:{\n}");

    // test server error
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeServerError];

    // the response logged
    aVerbose(@"Response: { \"message\": \"testResponseError\"}");

    // the message in the response
    aError(@"testResponseError");

    aTest(@"ActivityHandler setAskingAttribution, 0");

    // check attribution was called without ask_in
    aTest(@"ActivityHandler launchAttributionResponseTasks, message:testResponseError timestamp:(null) adid:(null) success:0 willRetry:0 attribution:(null) deeplink:(null) json:{\n    message = testResponseError;\n}");

    // test ok response with message
    [self checkGetAttributionResponse:attributionHandler responseType:ADJSessionResponseTypeMessage];

    [self checkOkMessageGetAttributionResponse];
}

- (void)testCheckSessionResponse
{
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:YES hasAttributionChangedDelegate:YES];

    NSMutableDictionary * attributionDictionary = [[NSMutableDictionary alloc] init];
    [attributionDictionary setObject:@"ttValue" forKey:@"tracker_token"];
    [attributionDictionary setObject:@"tnValue" forKey:@"tracker_name"];
    [attributionDictionary setObject:@"nValue" forKey:@"network"];
    [attributionDictionary setObject:@"cpValue" forKey:@"campaign"];
    [attributionDictionary setObject:@"aValue" forKey:@"adgroup"];
    [attributionDictionary setObject:@"ctValue" forKey:@"creative"];
    [attributionDictionary setObject:@"clValue" forKey:@"click_label"];

    NSMutableDictionary * jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:attributionDictionary forKey:@"attribution"];

    ADJSessionResponseData * sessionResponseData = [ADJResponseData buildResponseData:self.firstSessionPackage];
    sessionResponseData.jsonResponse = jsonDictionary;

    [attributionHandler checkSessionResponse:sessionResponseData];
    [NSThread sleepForTimeInterval:2.0];

    // updated set askingAttribution to false
    aTest(@"ActivityHandler setAskingAttribution, 0");

    // it did not update to true
    anTest(@"ActivityHandler setAskingAttribution, 1");

    // and waiting for query
    anDebug(@"Waiting to query attribution");

    // check attribution changed delegate was called
    aTest(@"ActivityHandler launchSessionResponseTasks, message:(null) timestamp:(null) adid:(null) success:0 willRetry:0 attribution:tt:ttValue tn:tnValue net:nValue cam:cpValue adg:aValue cre:ctValue cl:clValue");
}

- (void)testAskIn
{
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:YES hasAttributionChangedDelegate:YES];

    NSMutableDictionary * askIn4sDictionary = [[NSMutableDictionary alloc] init];
    [askIn4sDictionary setObject:@"4000" forKey:@"ask_in"];

    // set null response to avoid a cycle;
    [NSURLSession setResponseType:ADJSessionResponseTypeMessage];

    ADJSessionResponseData * sessionResponseData = [ADJResponseData buildResponseData:self.firstSessionPackage];
    sessionResponseData.jsonResponse = askIn4sDictionary;

    [attributionHandler checkSessionResponse:sessionResponseData];

    // sleep enough not to trigger the timer
    [NSThread sleepForTimeInterval:1.0];

    // check attribution was called with ask_in
    anTest(@"ActivityHandler updateAttribution");

    // it did update to true
    aTest(@"ActivityHandler setAskingAttribution, 1");

    // and waited to for query
    aDebug(@"Waiting to query attribution in 4000 milliseconds");

    // sleep enough not to trigger the timer
    [NSThread sleepForTimeInterval:1.0];

    NSMutableDictionary * askIn5sDictionary = [[NSMutableDictionary alloc] init];
    [askIn5sDictionary setObject:@"5000" forKey:@"ask_in"];

    sessionResponseData.jsonResponse = askIn5sDictionary;

    [attributionHandler checkSessionResponse:sessionResponseData];

    // sleep enough not to trigger the old timer
    [NSThread sleepForTimeInterval:3.0];

    // it did update to true
    aTest(@"ActivityHandler setAskingAttribution, 1");

    // and waited to for query
    aDebug(@"Waiting to query attribution in 5000 milliseconds");

    // it was been waiting for 1000 + 2000 + 3000 = 6 seconds
    // check that the mock http client was not called because the original clock was reseted
    anTest(@"NSURLSession dataTaskWithRequest");

    // check that it was finally called after 7 seconds after the second ask_in
    [NSThread sleepForTimeInterval:4.0];

    // test ok response with message
    aTest(@"NSURLSession dataTaskWithRequest");

    [self checkOkMessageGetAttributionResponse];

    [self checkRequest:[NSURLConnection getLastRequest]];
}

- (void)testPause
{
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:NO hasAttributionChangedDelegate:YES];

    [NSURLSession setResponseType:ADJSessionResponseTypeMessage];

    [attributionHandler getAttribution];

    [NSThread sleepForTimeInterval:1.0];

    // check that the activity handler is paused
    aDebug(@"Attribution handler is paused");

    // and it did not call the http client
    aNil([NSURLConnection getLastRequest]);

    anTest(@"NSURLSession dataTaskWithRequest");
}

- (void)testWithoutListener
{
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:YES hasAttributionChangedDelegate:NO];

    [NSURLConnection setResponseType:ADJResponseTypeMessage];

    [attributionHandler getAttribution];

    [NSThread sleepForTimeInterval:1.0];

    // check that the activity handler is not paused
    anDebug(@"Attribution handler is paused");

    // but it did not call the http client
    aNil([NSURLConnection getLastRequest]);

    anTest(@"NSURLSession dataTaskWithRequest");
}

- (void)testDeeplink {
    //  reseting to make the test order independent
    [self reset];

    id<ADJAttributionHandler> attributionHandler = [ADJAttributionHandler handlerWithActivityHandler:self.activityHandlerMock withAttributionPackage:self.attributionPackage startsSending:YES hasAttributionChangedDelegate:YES];

    NSMutableDictionary * attributionDictionary = [[NSMutableDictionary alloc] init];
    [attributionDictionary setObject:@"testDeeplinkAttribution://" forKey:@"deeplink"];

    NSMutableDictionary * jsonDictionary = [[NSMutableDictionary alloc] init];
    [jsonDictionary setObject:attributionDictionary forKey:@"attribution"];
    [jsonDictionary setObject:@"testDeeplinkRoot://" forKey:@"deeplink"];

    ADJSessionResponseData * sessionResponseData = [ADJResponseData buildResponseData:self.firstSessionPackage];
    sessionResponseData.jsonResponse = jsonDictionary;

    [attributionHandler checkSessionResponse:sessionResponseData];
    [NSThread sleepForTimeInterval:2.0];

    aTest(@"ActivityHandler setAskingAttribution, 0");

    aTest(@"ActivityHandler launchSessionResponseTasks, message:(null) timestamp:(null) adid:(null) success:0 willRetry:0 attribution:tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null) json:{\n    attribution =     {\n        deeplink = \"testDeeplinkAttribution://\";\n    };\n    deeplink = \"testDeeplinkRoot://\";\n}");

    ADJAttributionResponseData * attributionResponseData = [ADJResponseData buildResponseData:self.attributionPackage];
    attributionResponseData.jsonResponse = jsonDictionary;
    [attributionHandler checkAttributionResponse:attributionResponseData];
    [NSThread sleepForTimeInterval:2.0];

    aTest(@"ActivityHandler setAskingAttribution, 0");

    aTest(@"ActivityHandler launchAttributionResponseTasks, message:(null) timestamp:(null) adid:(null) success:0 willRetry:0 attribution:tt:(null) tn:(null) net:(null) cam:(null) adg:(null) cre:(null) cl:(null) deeplink:testDeeplinkAttribution:// json:{\n    attribution =     {\n        deeplink = \"testDeeplinkAttribution://\";\n    };\n    deeplink = \"testDeeplinkRoot://\";\n}");

    aEquals([attributionResponseData.deeplink absoluteString], @"testDeeplinkAttribution://");
}

- (void)checkOkMessageGetAttributionResponse
{
    // the response logged
    aVerbose(@"Response: { \"message\" : \"response OK\"}");

    // the message in the response
    aInfo(@"response OK");

    // check attribution was called without ask_in
    aTest(@"ActivityHandler setAskingAttribution, 0");

    aTest(@"ActivityHandler launchAttributionResponseTasks, message:response OK timestamp:(null) adid:(null) success:1 willRetry:0 attribution:(null) deeplink:(null) json:{\n    message = \"response OK\";\n}");
}

- (void)checkGetAttributionResponse:(id<ADJAttributionHandler>) attributionHandler
                       responseType:(ADJSessionResponseType)responseType
{
    //[NSURLConnection setResponseType:responseType];
    [NSURLSession setResponseType:responseType];

    [attributionHandler getAttribution];
    [NSThread sleepForTimeInterval:2.0];

    // delay time is 0
    anDebug(@"Waiting to query attribution");

    // it tried to send the request
    aTest(@"NSURLSession dataTaskWithRequest");

    [self checkRequest:[NSURLConnection getLastRequest]];
}

- (void)checkRequest:(NSURLRequest *)request
{
    if (request == nil) {
        return;
    }

    NSURL * url = [request URL];

    aslEquals(@"https", url.scheme, request.description);

    aslEquals(@"app.adjust.com", url.host, request.description);

    aslEquals(@"GET", [request HTTPMethod], request.description);
}

@end

