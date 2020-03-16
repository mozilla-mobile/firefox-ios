//
//  NewMultiFingerTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//


#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"
#import <KIF/UIApplication-KIFAdditions.h>

@interface MultiFingerTests_ViewTestActor : KIFTestCase
@property (nonatomic, readwrite) BOOL twoFingerPanSuccess;
@property (nonatomic, readwrite) BOOL zoomSuccess;
@property (nonatomic, readwrite) double latestRotation;
@end

@implementation MultiFingerTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"ScrollViews"] tap];
    // reset scroll view
    UIScrollView *scrollView = (UIScrollView *)[viewTester usingLabel:@"Scroll View"].view;
    scrollView.contentOffset = CGPointZero;

    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
    self.latestRotation = 0;
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
    self.latestRotation = 0;
}

#pragma mark - Tests

- (void)testTwoFingerPan
{
    CGFloat offset = 50.0;

    UIScrollView *scrollView = (UIScrollView *)[viewTester usingLabel:@"Scroll View"].view;
	[viewTester waitForAnimationsToFinish];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_twoFingerPanned:)];
    panGestureRecognizer.minimumNumberOfTouches = 2;
    [scrollView addGestureRecognizer:panGestureRecognizer];

    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    CGPoint endPoint = CGPointMake(startPoint.x, startPoint.y + offset);
    [scrollView twoFingerPanFromPoint:startPoint toPoint:endPoint steps:10];

    __KIFAssertEqual(self.twoFingerPanSuccess, YES);
}

- (void)testZoom
{
    CGFloat distance = 50.0;

    UIScrollView *scrollView = (UIScrollView *)[[viewTester usingLabel:@"Scroll View"] waitForView];
	[viewTester waitForAnimationsToFinish];
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(_zoomed:)];

    [scrollView addGestureRecognizer:pinchRecognizer];

    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    [scrollView zoomAtPoint:startPoint distance:distance steps:10];

    __KIFAssertEqual(self.zoomSuccess, YES);
}

- (void)testRotate
{
    UIScrollView *scrollView = (UIScrollView *)[[viewTester usingLabel:@"Scroll View"] waitForView];
    [viewTester waitForAnimationsToFinish];
    UIRotationGestureRecognizer *rotateRecognizer =
    [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(_rotated:)];

    [scrollView addGestureRecognizer:rotateRecognizer];

    [self _assertThatLatestRotationIsWithinThreshold:1];
    [self _assertThatLatestRotationIsWithinThreshold:45];
    [self _assertThatLatestRotationIsWithinThreshold:90];
    [self _assertThatLatestRotationIsWithinThreshold:180];
    [self _assertThatLatestRotationIsWithinThreshold:270];
    [self _assertThatLatestRotationIsWithinThreshold:360];

    [scrollView removeGestureRecognizer:rotateRecognizer];
}

#pragma mark - Internal Helpers

- (void)_assertThatLatestRotationIsWithinThreshold:(double)targetRotationInDegrees
{
    UIScrollView *scrollView = (UIScrollView *)[[viewTester usingLabel:@"Scroll View"] waitForView];
    CGPoint startPoint = CGPointMake(CGRectGetMidX(scrollView.bounds), CGRectGetMidY(scrollView.bounds));
    [scrollView twoFingerRotateAtPoint:startPoint angle:targetRotationInDegrees];

    // check we have rotated to within some small threshold of the target rotation amount
    // 0.2 radians is ~12 degrees
    BOOL withinThreshold = (self.latestRotation - KIFDegreesToRadians(targetRotationInDegrees)) < 0.2;
    __KIFAssertEqual(withinThreshold, YES);
}

#pragma mark - Gesture Recognizers

- (void)_twoFingerPanned:(UIGestureRecognizer *)gr
{
    if (gr.state == UIGestureRecognizerStateEnded) {
        self.twoFingerPanSuccess = YES;
    }
}

- (void)_zoomed:(UIPinchGestureRecognizer *)pinchRecognizer
{
    if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
        if (pinchRecognizer.scale > 1) {
            self.zoomSuccess = YES;
        }
    }
}

- (void)_rotated:(UIRotationGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        self.latestRotation = recognizer.rotation;
    }
}

@end
