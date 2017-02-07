//
//  NewSystemAlertTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//


#import <KIF/KIF.h>

@interface SystemAlertTests_ViewTestActor : KIFTestCase
@end


@implementation SystemAlertTests_ViewTestActor

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
    [[viewTester usingLabel:@"System Alerts"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testAuthorizingLocationServices
{
    [tester tapViewWithAccessibilityLabel:@"Location Services and Notifications"];

    // In a clean state this will pop two alerts, but in a dirty state it will pop one or none.
    // Call acknowledgeSystemAlert 2x without checking the return value (as the alerts might not be there).
    // Finally check that the final attempt is indeed false and no alerts remain on screen.

    ([tester acknowledgeSystemAlert]);
    ([tester acknowledgeSystemAlert]);
    XCTAssertFalse([tester acknowledgeSystemAlert]);
}

- (void)testAuthorizingPhotosAccess
{
    [[viewTester usingLabel:@"Photos"] tap];
    [viewTester acknowledgeSystemAlert];
    [[viewTester usingLabel:@"Cancel"] tap];
}

@end
