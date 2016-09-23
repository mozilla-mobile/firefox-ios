//
//  ADJRequestHandlerTests.m
//  Adjust
//
//  Created by Pedro Filipe on 07/02/14.
//  Copyright (c) 2014 adjust GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ADJAdjustFactory.h"
#import "ADJLoggerMock.h"
#import "NSURLConnection+NSURLConnectionSynchronousLoadingMocking.h"
#import "NSURLSession+NSURLDataWithRequestMocking.h"
#import "ADJPackageHandlerMock.h"
#import "ADJRequestHandlerMock.h"
#import "ADJTestsUtil.h"
#import "ADJTestActivityPackage.h"

@interface ADJRequestHandlerTests : ADJTestActivityPackage

@property (atomic,strong) ADJPackageHandlerMock *packageHandlerMock;
@property (atomic,strong) id<ADJRequestHandler> requestHandler;


@end

@implementation ADJRequestHandlerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.

    //[self reset];
}

- (void)tearDown
{
    [ADJAdjustFactory setLogger:nil];
    [ADJAdjustFactory setPackageHandler:nil];
    [NSURLConnection reset];

    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)reset {
    self.loggerMock = [[ADJLoggerMock alloc] init];
    [ADJAdjustFactory setLogger:self.loggerMock];

    self.packageHandlerMock = [[ADJPackageHandlerMock alloc] init];
    [ADJAdjustFactory setPackageHandler:self.packageHandlerMock];

    self.requestHandler = [ADJAdjustFactory requestHandlerForPackageHandler:self.packageHandlerMock];
    [NSURLConnection reset];
}

- (void)testSend
{
    //  reseting to make the test order independent
    [self reset];

    // null response
    [NSURLSession setResponseType:ADJSessionResponseTypeNil];

    [self checkSendPackage];

    aTest(@"PackageHandler closeFirstPackage");

    // client exception
    [NSURLSession setResponseType:ADJSessionResponseTypeConnError];

    [self checkSendPackage];

    aError(@"Failed to track unknown (connection error) Will retry later");

    aTest(@"PackageHandler closeFirstPackage");

    // server error
    [NSURLSession setResponseType:ADJSessionResponseTypeServerError];

    [self checkSendPackage];

    aVerbose(@"Response: { \"message\": \"testResponseError\"}");

    aError(@"testResponseError");

    aTest(@"PackageHandler sendNextPackage");

    // wrong json
    [NSURLSession setResponseType:ADJSessionResponseTypeWrongJson];

    [self checkSendPackage];

    aVerbose(@"Response: not a json response");

    aError(@"Failed to parse json response. (The data couldn’t be read because it isn’t in the correct format.)");

    aTest(@"PackageHandler closeFirstPackage");

    // empty json
    [NSURLSession setResponseType:ADJSessionResponseTypeEmptyJson];

    [self checkSendPackage];

    aVerbose(@"Response: { }");

    aInfo(@"No message found");

    aTest(@"PackageHandler sendNextPackage");

    // message response
    [NSURLSession setResponseType:ADJSessionResponseTypeMessage];

    [self checkSendPackage];

    aVerbose(@"Response: { \"message\" : \"response OK\"}");

    aInfo(@"response OK");

    aTest(@"PackageHandler sendNextPackage");
}

- (void)checkSendPackage
{
    [self.requestHandler sendPackage:[ADJTestsUtil getUnknowPackage:@""] queueSize:0];

    [NSThread sleepForTimeInterval:1.0];

    aTest(@"NSURLSession dataTaskWithRequest");
}

@end
