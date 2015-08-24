//
//  MultiFingerTests.m
//  KIF
//
//  Created by Ying Quan Tan on 7/30/14.
//
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"
#import <KIF/UIApplication-KIFAdditions.h>

@interface MultiFingerTests : KIFTestCase
@property (nonatomic, readwrite) BOOL twoFingerTapSuccess;
@property (nonatomic, readwrite) BOOL twoFingerPanSuccess;
@property (nonatomic, readwrite) BOOL zoomSuccess;
@property (nonatomic, readwrite) double latestRotation;
@end

@implementation MultiFingerTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"ScrollViews"];

    // reset scroll view
    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    scrollView.contentOffset = CGPointZero;

    self.twoFingerTapSuccess = NO;
    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
    self.latestRotation = 0;
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    self.twoFingerTapSuccess = NO;
    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
    self.latestRotation = 0;
}

- (void)testTwoFingerTap {
    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    UITapGestureRecognizer *twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(twoFingerTapped)];
    twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    [scrollView addGestureRecognizer:twoFingerTapRecognizer];

    [scrollView twoFingerTapAtPoint:CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds))];

    __KIFAssertEqual(self.twoFingerTapSuccess, YES);
    [scrollView removeGestureRecognizer:twoFingerTapRecognizer];
}

- (void)twoFingerTapped {
    self.twoFingerTapSuccess = YES;
}

- (void)testTwoFingerPan
{
    CGFloat offset = 50.0;

    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerPanned)];
    panGestureRecognizer.minimumNumberOfTouches = 2;
    [scrollView addGestureRecognizer:panGestureRecognizer];

    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    CGPoint endPoint = CGPointMake(startPoint.x, startPoint.y + offset);
    [scrollView twoFingerPanFromPoint:startPoint toPoint:endPoint steps:10];

    __KIFAssertEqual(self.twoFingerPanSuccess, YES);
    [scrollView removeGestureRecognizer:panGestureRecognizer];
}

- (void)twoFingerPanned {
    self.twoFingerPanSuccess = YES;
}

- (void)testZoom {
    CGFloat distance = 50.0;

    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(zoomed:)];

    [scrollView addGestureRecognizer:pinchRecognizer];

    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    [scrollView zoomAtPoint:startPoint distance:distance steps:10];

    __KIFAssertEqual(self.zoomSuccess, YES);
    [scrollView removeGestureRecognizer:pinchRecognizer];
}

- (void)zoomed:(UIPinchGestureRecognizer *)pinchRecognizer {

    if (pinchRecognizer.state == UIGestureRecognizerStateChanged)
    {
        if (pinchRecognizer.scale > 1)
        {
            self.zoomSuccess = YES;
        }
    }

}

- (void)testRotate {
    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    UIRotationGestureRecognizer *rotateRecognizer =
        [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotated:)];

    [scrollView addGestureRecognizer:rotateRecognizer];

    [self assertThatLatestRotationIsWithinThreshold:45];
    [self assertThatLatestRotationIsWithinThreshold:90];
    [self assertThatLatestRotationIsWithinThreshold:180];
    [self assertThatLatestRotationIsWithinThreshold:270];
    [self assertThatLatestRotationIsWithinThreshold:360];

    [scrollView removeGestureRecognizer:rotateRecognizer];
}

- (void)assertThatLatestRotationIsWithinThreshold:(double)targetRotationInDegrees {
    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    [scrollView twoFingerRotateAtPoint:startPoint angle:targetRotationInDegrees];

    // check we have rotated to within some small threshold of the target rotation amount
    // 0.2 radians is ~12 degrees
    BOOL withinThreshold = (self.latestRotation - KIFDegreesToRadians(targetRotationInDegrees)) < 0.2;
    __KIFAssertEqual(withinThreshold, YES);
}

- (void)rotated:(UIRotationGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.latestRotation = recognizer.rotation;
    }
}

@end
