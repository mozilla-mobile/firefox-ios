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
@property (nonatomic, readwrite) BOOL twoFingerPanSuccess;
@property (nonatomic, readwrite) BOOL zoomSuccess;
@end

@implementation MultiFingerTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"ScrollViews"];

    // reset scroll view
    UIScrollView *scrollView = (UIScrollView *)[tester waitForViewWithAccessibilityLabel:@"Scroll View"];
    scrollView.contentOffset = CGPointZero;

    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    self.twoFingerPanSuccess = NO;
    self.zoomSuccess = NO;
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

@end
