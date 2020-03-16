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

+ (XCTestSuite *)defaultTestSuite
{
    // 'acknowledgeSystemAlert' can't be used on iOS7
    // The console shows a message "AX Lookup problem! 22 com.apple.iphone.axserver:-1"
    if ([UIDevice.currentDevice.systemVersion compare:@"8.0" options:NSNumericSearch] < 0) {
        return nil;
    }

    return [super defaultTestSuite];
}

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

    // In a clean state this will pop two alerts, but in a dirty state it will pop one or none.
    // Call acknowledgeSystemAlert 2x without checking the return value (as the alerts might not be there).
    // Finally check that the final attempt is indeed false and no alerts remain on screen.
    
    [tester acknowledgeSystemAlert];
    [tester acknowledgeSystemAlert];
    XCTAssertFalse([tester acknowledgeSystemAlert]);
}

- (void)testAuthorizingPhotosAccess {
    [tester tapViewWithAccessibilityLabel:@"Photos"];
    [tester acknowledgeSystemAlert];
    [tester tapViewWithAccessibilityLabel:@"Cancel"];
}

@end
