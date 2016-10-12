//
//  WaitForAnimationTests.m
//  KIF
//
//  Created by Hendrik von Prince on 11.11.14.
//
//

#import <KIF/KIF.h>

@interface WaitForAnimationTests : KIFTestCase

@end

@implementation WaitForAnimationTests

- (void)beforeEach {
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
    [tester tapViewWithAccessibilityLabel:@"Animations"];
}

- (void)afterEach {
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testWaitForFinishingAnimation {
    [tester waitForViewWithAccessibilityLabel:@"Label"];
}

@end
