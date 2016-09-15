//
//  LandscapeTests.m
//  KIF
//
//  Created by Brian Nickel on 9/11/13.
//
//

#import <KIF/KIF.h>

@interface LandscapeTests : KIFTestCase
@end

@implementation LandscapeTests

- (void)beforeAll
{
    [system simulateDeviceRotationToOrientation:UIDeviceOrientationLandscapeLeft];
    [tester scrollViewWithAccessibilityIdentifier:@"Test Suite TableView" byFractionOfSizeHorizontal:0 vertical:-0.2];
}

- (void)afterAll
{
    [system simulateDeviceRotationToOrientation:UIDeviceOrientationPortrait];
    [tester waitForTimeInterval:0.5];
}

- (void)beforeEach
{
    [tester waitForTimeInterval:0.25];
}

- (void)testThatAlertViewsCanBeTappedInLandscape
{
    [tester tapViewWithAccessibilityLabel:@"UIAlertView"];
    [tester tapViewWithAccessibilityLabel:@"Continue"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Message"];
}

@end
