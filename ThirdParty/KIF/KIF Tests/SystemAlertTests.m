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

- (void)testAuthorizingLocationServices {
    [tester tapViewWithAccessibilityLabel:@"Location Services"];
    [tester acknowledgeSystemAlert];
}

- (void)testAuthorizingPhotosAccess {
    [tester tapViewWithAccessibilityLabel:@"Photos"];
    [tester acknowledgeSystemAlert];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

- (void)testNotificationScheduling {
    [tester tapViewWithAccessibilityLabel:@"Notifications"];
    [tester acknowledgeSystemAlert];
}

@end
