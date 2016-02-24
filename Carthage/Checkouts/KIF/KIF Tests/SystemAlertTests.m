//
//  SystemAlertTests.m
//  KIF
//
//  Created by Joe Masilotti on 12/1/14.
//
//

#import <KIF/KIF.h>

@interface SystemAlertTests : KIFTestCase

@end

@implementation SystemAlertTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"System Alerts"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testAuthorizingLocationServicesAndNotificationsScheduling {
    [tester tapViewWithAccessibilityLabel:@"Location Services and Notifications"];
    XCTAssertTrue([tester acknowledgeSystemAlert]);
	XCTAssertTrue([tester acknowledgeSystemAlert]);
	XCTAssertFalse([tester acknowledgeSystemAlert]);
}

- (void)testAuthorizingPhotosAccess {
    [tester tapViewWithAccessibilityLabel:@"Photos"];
    [tester acknowledgeSystemAlert];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

@end
