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
    self.activityHandlerMock = [[ADJActivityHandlerMock alloc] initWithConfig:config];

    //  delete previously created Package queue file to make a new queue
    XCTAssert([ADJTestsUtil deleteFile:@"AdjustIoPackageQueue" logger:self.loggerMock], @"%@", self.loggerMock);
}

- (void)testAddPackage
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createPackageHandler];

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

    aTest(@"RequestHandler sendPackage, clickFirstPackage");

    // send the second click package/ third package
    [secondPackageHandler sendNextPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"RequestHandler sendPackage, clickThirdPackage");

    // send the unknow package/ second package
    [secondPackageHandler sendNextPackage];
    [NSThread sleepForTimeInterval:1.0];

    aTest(@"RequestHandler sendPackage, unknownSecondPackage");
}

- (void)testSendFirst
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createPackageHandler];

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
                                                                                  startPaused:NO];

    [secondpackageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    // send the package to request handler
    [self checkSendFirst:ADJSendFirstSend packageString:@"unknownFirstPackage"];
}

- (void)testSendNext
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createPackageHandler];

    // add and send the first package
    [self checkAddAndSendFirst:packageHandler];

    // try to send when it is still sending
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    // add a second package
    [self checkAddSecondPackage:packageHandler];

    //send next package
    [packageHandler sendNextPackage];
    [NSThread sleepForTimeInterval:2.0];

    aDebug(@"Package handler wrote 1 packages");

    // try to send the second package
    [self checkSendFirst:ADJSendFirstSend packageString:@"unknownSecondPackage"];
}

- (void)testCloseFirstPackage
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createPackageHandler];

    [self checkAddAndSendFirst:packageHandler];

    // try to send when it is still sending
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:1.0];

    [self checkSendFirst:ADJSendFirstIsSending];

    //send next package
    [packageHandler closeFirstPackage];
    [NSThread sleepForTimeInterval:2.0];

    anDebug(@"Package handler wrote");

    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:2.0];

    // try to send the first package again
    [self checkSendFirst:ADJSendFirstSend packageString:@"unknownFirstPackage"];
}

- (void)testCalls
{
    //  reseting to make the test order independent
    [self reset];

    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [self createPackageHandler:YES];

    ADJActivityPackage *firstActivityPackage = [ADJTestsUtil getUnknowPackage:@"FirstPackage"];

    [packageHandler addPackage:firstActivityPackage];
    [packageHandler sendFirstPackage];
    [NSThread sleepForTimeInterval:2.0];

    [self checkAddPackage:1 packageString:@"unknownFirstPackage"];

    [self checkSendFirst:ADJSendFirstPaused];

    [packageHandler finishedTracking:nil];

    aTest(@"ActivityHandler finishedTracking, (null)");
}

- (id<ADJPackageHandler>)createPackageHandler
{
    return [self createPackageHandler:NO];
}

- (id<ADJPackageHandler>)createPackageHandler:(BOOL)startPaused
{
    //  initialize Package Handler
    id<ADJPackageHandler> packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self.activityHandlerMock
                                                                                  startPaused:startPaused];
    [NSThread sleepForTimeInterval:2.0];

    aVerbose(@"Package queue file not found");

    return packageHandler;
}

- (id<ADJPackageHandler>)checkAddSecondPackage:(id<ADJPackageHandler>)packageHandler
{
    if (packageHandler == nil) {
        packageHandler = [ADJAdjustFactory packageHandlerForActivityHandler:self.activityHandlerMock
                                                                startPaused:NO];

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

    [self checkSendFirst:ADJSendFirstSend packageString:@"unknownFirstPackage"];
}

- (void)checkSendFirst:(ADJSendFirst)sendFirstState
{
    [self checkSendFirst:sendFirstState packageString:nil];
}
- (void)checkSendFirst:(ADJSendFirst)sendFirstState
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
        NSString * aSend = [NSString stringWithFormat:@"RequestHandler sendPackage, %@", packageString];
        aTest(aSend);
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
