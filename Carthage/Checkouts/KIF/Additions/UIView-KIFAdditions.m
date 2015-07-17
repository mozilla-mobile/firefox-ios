//
//  UIView-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UIView-KIFAdditions.h"
#import "CGGeometry-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "UIApplication-KIFAdditions.h"
#import "UITouch-KIFAdditions.h"
#import <objc/runtime.h>
#import "UIEvent+KIFAdditions.h"

double KIFDegreesToRadians(double deg) {
    return (deg) / 180.0 * M_PI;
}

double KIFRadiansToDegrees(double rad) {
    return ((rad) * (180.0 / M_PI));
}

static CGFloat const kTwoFingerConstantWidth = 40;

@interface UIApplication (KIFAdditionsPrivate)
- (UIEvent *)_touchesEvent;
@end

@interface NSObject (UIWebDocumentViewInternal)

- (void)tapInteractionWithLocation:(CGPoint)point;

@end

// On iOS 6 the accessibility label may contain line breaks, so when trying to find the
// element, these line breaks are necessary. But on iOS 7 the system replaces them with
// spaces. So the same test breaks on either iOS 6 or iOS 7. iOS8 befuddles this again by
//limiting replacement to spaces in between strings. To work around this replace
// the line breaks in both and try again.
NS_INLINE BOOL StringsMatchExceptLineBreaks(NSString *expected, NSString *actual) {
    if (expected == actual) {
        return YES;
    }
    
    if (expected.length != actual.length) {
        return NO;
    }
    
    if ([expected isEqualToString:actual]) {
        return YES;
    }
    
    if ([expected rangeOfString:@"\n"].location == NSNotFound) {
        return NO;
    }
    
    for (NSUInteger i = 0; i < expected.length; i ++) {
        unichar expectedChar = [expected characterAtIndex:i];
        unichar actualChar = [actual characterAtIndex:i];
        if (expectedChar != actualChar && !(expectedChar == '\n' && actualChar == ' ')) {
            return NO;
        }
    }
    
    return YES;
}


@implementation UIView (KIFAdditions)

+ (NSSet *)classesToSkipAccessibilitySearchRecursion
{
    static NSSet *classesToSkip;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // UIDatePicker contains hundreds of thousands of placeholder accessibility elements that aren't useful to KIF,
        // so don't recurse into a date picker when searching for matching accessibility elements
        classesToSkip = [[NSSet alloc] initWithObjects:[UIDatePicker class], nil];
    });
    
    return classesToSkip;
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label
{
    return [self accessibilityElementWithLabel:label traits:UIAccessibilityTraitNone];
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;
{
    return [self accessibilityElementWithLabel:label accessibilityValue:nil traits:traits];
}

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;
{
    return [self accessibilityElementMatchingBlock:^(UIAccessibilityElement *element) {
        
        // TODO: This is a temporary fix for an SDK defect.
        NSString *accessibilityValue = nil;
        @try {
            accessibilityValue = element.accessibilityValue;
        }
        @catch (NSException *exception) {
            NSLog(@"KIF: Unable to access accessibilityValue for element %@ because of exception: %@", element, exception.reason);
        }
        
        if ([accessibilityValue isKindOfClass:[NSAttributedString class]]) {
            accessibilityValue = [(NSAttributedString *)accessibilityValue string];
        }
        
        BOOL labelsMatch = StringsMatchExceptLineBreaks(label, element.accessibilityLabel);
        BOOL traitsMatch = ((element.accessibilityTraits) & traits) == traits;
        BOOL valuesMatch = !value || [value isEqual:accessibilityValue];

        return (BOOL)(labelsMatch && traitsMatch && valuesMatch);
    }];
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;
{
    if (self.hidden) {
        return nil;
    }
    
    // In case multiple elements with the same label exist, prefer ones that are currently visible
    UIAccessibilityElement *matchingButOccludedElement = nil;
    
    BOOL elementMatches = matchBlock((UIAccessibilityElement *)self);

    if (elementMatches) {
        if (self.isTappable) {
            return (UIAccessibilityElement *)self;
        } else {
            matchingButOccludedElement = (UIAccessibilityElement *)self;
        }
    }
    
    if ([[[self class] classesToSkipAccessibilitySearchRecursion] containsObject:[self class]]) {
        return matchingButOccludedElement;
    }
    
    // Check the subviews first. Even if the receiver says it's an accessibility container,
    // the returned objects are UIAccessibilityElementMockViews (which aren't actually views)
    // rather than the real subviews it contains. We want the real views if possible.
    // UITableViewCell is such an offender.
    for (UIView *view in [self.subviews reverseObjectEnumerator]) {
        UIAccessibilityElement *element = [view accessibilityElementMatchingBlock:matchBlock];
        if (!element) {
            continue;
        }
        
        UIView *viewForElement = [UIAccessibilityElement viewContainingAccessibilityElement:element];
        CGRect accessibilityFrame = [viewForElement.window convertRect:element.accessibilityFrame toView:viewForElement];
        
        if ([viewForElement isTappableInRect:accessibilityFrame]) {
            return element;
        } else {
            matchingButOccludedElement = element;
        }
    }
    
    NSMutableArray *elementStack = [NSMutableArray arrayWithObject:self];
    
    while (elementStack.count) {
        UIAccessibilityElement *element = [elementStack lastObject];
        [elementStack removeLastObject];

        BOOL elementMatches = matchBlock(element);

        if (elementMatches) {
            UIView *viewForElement = [UIAccessibilityElement viewContainingAccessibilityElement:element];
            CGRect accessibilityFrame = [viewForElement.window convertRect:element.accessibilityFrame toView:viewForElement];

            if ([viewForElement isTappableInRect:accessibilityFrame]) {
                return element;
            } else {
                matchingButOccludedElement = element;
                continue;
            }
        }
        
        // If the view is an accessibility container, and we didn't find a matching subview,
        // then check the actual accessibility elements
        NSInteger accessibilityElementCount = element.accessibilityElementCount;
        if (accessibilityElementCount == 0 || accessibilityElementCount == NSNotFound) {
            continue;
        }
        
        for (NSInteger accessibilityElementIndex = 0; accessibilityElementIndex < accessibilityElementCount; accessibilityElementIndex++) {
            UIAccessibilityElement *subelement = [element accessibilityElementAtIndex:accessibilityElementIndex];
            
            if (subelement) {
                [elementStack addObject:subelement];
            }
        }
    }
    
    if (!matchingButOccludedElement && [self isKindOfClass:[UICollectionView class]]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        
        NSArray *indexPathsForVisibleItems = [collectionView indexPathsForVisibleItems];
        
        for (NSUInteger section = 0, numberOfSections = [collectionView numberOfSections]; section < numberOfSections; section++) {
            for (NSUInteger item = 0, numberOfItems = [collectionView numberOfItemsInSection:section]; item < numberOfItems; item++) {
                // Skip visible items because they are already handled
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                if ([indexPathsForVisibleItems containsObject:indexPath]) {
                    continue;
                }
                
                @autoreleasepool {
                    // Get the cell directly from the dataSource because UICollectionView will only vend visible cells
                    UICollectionViewCell *cell = [collectionView.dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
                    
                    UIAccessibilityElement *element = [cell accessibilityElementMatchingBlock:matchBlock];
                    
                    // Remove the cell from the collection view so that it doesn't stick around
                    [cell removeFromSuperview];
                    
                    // Skip this cell if it isn't the one we're looking for
                    // Sometimes we get cells with no size here which can cause an endless loop, so we ignore those
                    if (!element || CGSizeEqualToSize(cell.frame.size, CGSizeZero)) {
                        continue;
                    }
                }
                
                // Scroll to the cell and wait for the animation to complete
                [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
                CFRunLoopRunInMode(UIApplicationCurrentRunMode, 0.5, false);
                
                // Now try finding the element again
                return [self accessibilityElementMatchingBlock:matchBlock];
            }
        }
    }
        
    return matchingButOccludedElement;
}

- (UIView *)subviewWithClassNamePrefix:(NSString *)prefix;
{
    NSArray *subviews = [self subviewsWithClassNamePrefix:prefix];
    if ([subviews count] == 0) {
        return nil;
    }
    
    return subviews[0];
}

- (NSArray *)subviewsWithClassNamePrefix:(NSString *)prefix;
{
    NSMutableArray *result = [NSMutableArray array];
    
    // Breadth-first population of matching subviews
    // First traverse the next level of subviews, adding matches.
    for (UIView *view in self.subviews) {
        if ([NSStringFromClass([view class]) hasPrefix:prefix]) {
            [result addObject:view];
        }
    }
    
    // Now traverse the subviews of the subviews, adding matches.
    for (UIView *view in self.subviews) {
        NSArray *matchingSubviews = [view subviewsWithClassNamePrefix:prefix];
        [result addObjectsFromArray:matchingSubviews];
    }

    return result;
}

- (UIView *)subviewWithClassNameOrSuperClassNamePrefix:(NSString *)prefix;
{
    NSArray *subviews = [self subviewsWithClassNameOrSuperClassNamePrefix:prefix];
    if ([subviews count] == 0) {
        return nil;
    }
    
    return subviews[0];
}

- (NSArray *)subviewsWithClassNameOrSuperClassNamePrefix:(NSString *)prefix;
{
    NSMutableArray * result = [NSMutableArray array];
    
    // Breadth-first population of matching subviews
    // First traverse the next level of subviews, adding matches
    for (UIView *view in self.subviews) {
        Class klass = [view class];
        while (klass) {
            if ([NSStringFromClass(klass) hasPrefix:prefix]) {
                [result addObject:view];
                break;
            }
            
            klass = [klass superclass];
        }
    }
    
    // Now traverse the subviews of the subviews, adding matches
    for (UIView *view in self.subviews) {
        NSArray * matchingSubviews = [view subviewsWithClassNameOrSuperClassNamePrefix:prefix];
        [result addObjectsFromArray:matchingSubviews];
    }

    return result;
}


- (BOOL)isDescendantOfFirstResponder;
{
    if ([self isFirstResponder]) {
        return YES;
    }
    return [self.superview isDescendantOfFirstResponder];
}

- (void)flash;
{
	UIColor *originalBackgroundColor = self.backgroundColor;
    for (NSUInteger i = 0; i < 5; i++) {
        self.backgroundColor = [UIColor yellowColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
        self.backgroundColor = [UIColor blueColor];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, .05, false);
    }
    self.backgroundColor = originalBackgroundColor;
}

- (void)tap;
{
    CGPoint centerPoint = CGPointMake(self.frame.size.width * 0.5f, self.frame.size.height * 0.5f);
    
    [self tapAtPoint:centerPoint];
}

- (void)tapAtPoint:(CGPoint)point;
{
    // Web views don't handle touches in a normal fashion, but they do have a method we can call to tap them
    // This may not be necessary anymore. We didn't properly support controls that used gesture recognizers
    // when this was added, but we now do. It needs to be tested before we can get rid of it.
    id /*UIWebBrowserView*/ webBrowserView = nil;
    
    if ([NSStringFromClass([self class]) isEqual:@"UIWebBrowserView"]) {
        webBrowserView = self;
    } else if ([self isKindOfClass:[UIWebView class]]) {
        id webViewInternal = [self valueForKey:@"_internal"];
        webBrowserView = [webViewInternal valueForKey:@"browserView"];
    }
    
    if (webBrowserView) {
        [webBrowserView tapInteractionWithLocation:point];
        return;
    }
    
    // Handle touches in the normal way for other views
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *event = [self eventWithTouch:touch];

    [[UIApplication sharedApplication] sendEvent:event];
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [[UIApplication sharedApplication] sendEvent:event];

    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:self] && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }

}

- (void)twoFingerTapAtPoint:(CGPoint)point {
    CGPoint finger1 = CGPointMake(point.x - kTwoFingerConstantWidth, point.y - kTwoFingerConstantWidth);
    CGPoint finger2 = CGPointMake(point.x + kTwoFingerConstantWidth, point.y + kTwoFingerConstantWidth);
    UITouch *touch1 = [[UITouch alloc] initAtPoint:finger1 inView:self];
    UITouch *touch2 = [[UITouch alloc] initAtPoint:finger2 inView:self];
    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseBegan];

    UIEvent *event = [self eventWithTouches:@[touch1, touch2]];
    [[UIApplication sharedApplication] sendEvent:event];

    [touch1 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    [touch2 setPhaseAndUpdateTimestamp:UITouchPhaseEnded];

    [[UIApplication sharedApplication] sendEvent:event];
}

#define DRAG_TOUCH_DELAY 0.01

- (void)longPressAtPoint:(CGPoint)point duration:(NSTimeInterval)duration
{
    UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
    
    UIEvent *eventDown = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventDown];
    
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, DRAG_TOUCH_DELAY, false);
    
    for (NSTimeInterval timeSpent = DRAG_TOUCH_DELAY; timeSpent < duration; timeSpent += DRAG_TOUCH_DELAY)
    {
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
        
        UIEvent *eventStillDown = [self eventWithTouch:touch];
        [[UIApplication sharedApplication] sendEvent:eventStillDown];
        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, DRAG_TOUCH_DELAY, false);
    }
    
    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
    UIEvent *eventUp = [self eventWithTouch:touch];
    [[UIApplication sharedApplication] sendEvent:eventUp];
    
    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touch.view isDescendantOfView:self] && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }
    
}

- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;
{
    [self dragFromPoint:startPoint toPoint:endPoint steps:3];
}


- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint steps:(NSUInteger)stepCount;
{
    KIFDisplacement displacement = CGPointMake(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
    [self dragFromPoint:startPoint displacement:displacement steps:stepCount];
}

- (void)dragFromPoint:(CGPoint)startPoint displacement:(KIFDisplacement)displacement steps:(NSUInteger)stepCount;
{
    CGPoint endPoint = CGPointMake(startPoint.x + displacement.x, startPoint.y + displacement.y);
    NSArray *path = [self pointsFromStartPoint:startPoint toPoint:endPoint steps:stepCount];
    [self dragPointsAlongPaths:@[path]];
}

- (void)dragAlongPathWithPoints:(CGPoint *)points count:(NSInteger)count;
{
    // convert point array into NSArray with NSValue
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < count; i++)
    {
        [array addObject:[NSValue valueWithCGPoint:points[i]]];
    }
    [self dragPointsAlongPaths:@[[array copy]]];
}

- (void)dragPointsAlongPaths:(NSArray *)arrayOfPaths {
    // must have at least one path, and each path must have the same number of points
    if (arrayOfPaths.count == 0)
    {
        return;
    }

    // all paths must have similar number of points
    NSUInteger pointsInPath = [arrayOfPaths[0] count];
    for (NSArray *path in arrayOfPaths)
    {
        if (path.count != pointsInPath)
        {
            return;
        }
    }

    NSMutableArray *touches = [NSMutableArray array];

    for (NSUInteger pointIndex = 0; pointIndex < pointsInPath; pointIndex++) {
        // create initial touch event and send touch down event
        if (pointIndex == 0)
        {
            for (NSArray *path in arrayOfPaths)
            {
                CGPoint point = [path[pointIndex] CGPointValue];
                UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
                [touches addObject:touch];
            }
            UIEvent *eventDown = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:eventDown];
        }
        else
        {
            UITouch *touch;
            for (NSUInteger pathIndex = 0; pathIndex < arrayOfPaths.count; pathIndex++)
            {
                NSArray *path = arrayOfPaths[pathIndex];
                CGPoint point = [path[pointIndex] CGPointValue];
                touch = touches[pathIndex];
                [touch setLocationInWindow:[self.window convertPoint:point fromView:self]];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            }
            UIEvent *event = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:event];

            CFRunLoopRunInMode(UIApplicationCurrentRunMode, DRAG_TOUCH_DELAY, false);

            // The last point needs to also send a phase ended touch.
            if (pointIndex == pointsInPath - 1) {
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
                UIEvent *eventUp = [self eventWithTouch:touch];
                [[UIApplication sharedApplication] sendEvent:eventUp];
            }
        }
    }

    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touches[0] view] == self && [self canBecomeFirstResponder]) {
        [self becomeFirstResponder];
    }

    while (UIApplicationCurrentRunMode != kCFRunLoopDefaultMode) {
        CFRunLoopRunInMode(UIApplicationCurrentRunMode, 0.1, false);
    }
}

- (void)twoFingerPanFromPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount {
    //estimate the first finger to be diagonally up and left from the center
    CGPoint finger1Start = CGPointMake(startPoint.x - kTwoFingerConstantWidth,
                                       startPoint.y - kTwoFingerConstantWidth);
    CGPoint finger1End = CGPointMake(toPoint.x - kTwoFingerConstantWidth,
                                     toPoint.y - kTwoFingerConstantWidth);
    //estimate the second finger to be diagonally down and right from the center
    CGPoint finger2Start = CGPointMake(startPoint.x + kTwoFingerConstantWidth,
                                       startPoint.y + kTwoFingerConstantWidth);
    CGPoint finger2End = CGPointMake(toPoint.x + kTwoFingerConstantWidth,
                                     toPoint.y + kTwoFingerConstantWidth);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];

    [self dragPointsAlongPaths:paths];
}

- (void)pinchAtPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount {
    //estimate the first finger to be on the left
    CGPoint finger1Start = CGPointMake(centerPoint.x - kTwoFingerConstantWidth - distance, centerPoint.y);
    CGPoint finger1End = CGPointMake(centerPoint.x - kTwoFingerConstantWidth, centerPoint.y);
    //estimate the second finger to be on the right
    CGPoint finger2Start = CGPointMake(centerPoint.x + kTwoFingerConstantWidth + distance, centerPoint.y);
    CGPoint finger2End = CGPointMake(centerPoint.x + kTwoFingerConstantWidth, centerPoint.y);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];

    [self dragPointsAlongPaths:paths];
}

- (void)zoomAtPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount {
    //estimate the first finger to be on the left
    CGPoint finger1Start = CGPointMake(centerPoint.x - kTwoFingerConstantWidth, centerPoint.y);
    CGPoint finger1End = CGPointMake(centerPoint.x - kTwoFingerConstantWidth - distance, centerPoint.y);
    //estimate the second finger to be on the right
    CGPoint finger2Start = CGPointMake(centerPoint.x + kTwoFingerConstantWidth, centerPoint.y);
    CGPoint finger2End = CGPointMake(centerPoint.x + kTwoFingerConstantWidth + distance, centerPoint.y);
    NSArray *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];

    [self dragPointsAlongPaths:paths];
}

- (void)twoFingerRotateAtPoint:(CGPoint)centerPoint angle:(CGFloat)angleInDegrees {
    NSInteger stepCount = ABS(angleInDegrees)/2; // very rough approximation. 90deg = ~45 steps, 360 deg = ~180 steps
    CGFloat radius = kTwoFingerConstantWidth*2;
    double angleInRadians = KIFDegreesToRadians(angleInDegrees);

    NSMutableArray *finger1Path = [NSMutableArray array];
    NSMutableArray *finger2Path = [NSMutableArray array];
    for (NSUInteger i = 0; i < stepCount; i++) {
        double currentAngle = 0;
        if (i == stepCount - 1) {
            currentAngle = angleInRadians; // do not interpolate for the last step for maximum accuracy
        }
        else {
            double interpolation = i/(double)stepCount;
            currentAngle = interpolation * angleInRadians;
        }
        // interpolate betwen 0 and the target rotation
        CGPoint offset1 = CGPointMake(radius * cos(currentAngle), radius * sin(currentAngle));
        CGPoint offset2 = CGPointMake(-offset1.x, -offset1.y); // second finger is just opposite of the first

        CGPoint finger1 = CGPointMake(centerPoint.x + offset1.x, centerPoint.y + offset1.y);
        CGPoint finger2 = CGPointMake(centerPoint.x + offset2.x, centerPoint.y + offset2.y);

        [finger1Path addObject:[NSValue valueWithCGPoint:finger1]];
        [finger2Path addObject:[NSValue valueWithCGPoint:finger2]];
    }
    [self dragPointsAlongPaths:@[[finger1Path copy], [finger2Path copy]]];
}

- (NSArray *)pointsFromStartPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount {

    CGPoint displacement = CGPointMake(toPoint.x - startPoint.x, toPoint.y - startPoint.y);
    NSMutableArray *points = [NSMutableArray array];

    for (NSUInteger i = 0; i < stepCount; i++) {
        CGFloat progress = ((CGFloat)i)/(stepCount - 1);
        CGPoint point = CGPointMake(startPoint.x + (progress * displacement.x),
                                    startPoint.y + (progress * displacement.y));
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    return [NSArray arrayWithArray:points];
}

- (BOOL)isProbablyTappable
{
    // There are some issues with the tappability check in UIWebViews, so if the view is a UIWebView we will just skip the check.
    return [NSStringFromClass([self class]) isEqualToString:@"UIWebBrowserView"] || self.isTappable;
}

// Is this view currently on screen?
- (BOOL)isTappable;
{
    return ([self hasTapGestureRecognizer] ||
            [self isTappableInRect:self.bounds]);
}

- (BOOL)hasTapGestureRecognizer
{
    __block BOOL hasTapGestureRecognizer = NO;
    
    [self.gestureRecognizers enumerateObjectsUsingBlock:^(id obj,
                                                          NSUInteger idx,
                                                          BOOL *stop) {
        if ([obj isKindOfClass:[UITapGestureRecognizer class]]) {
            hasTapGestureRecognizer = YES;
            
            if (stop != NULL) {
                *stop = YES;
            }
        }
    }];
    
    return hasTapGestureRecognizer;
}

- (BOOL)isTappableInRect:(CGRect)rect;
{
    CGPoint tappablePoint = [self tappablePointInRect:rect];
    
    return !isnan(tappablePoint.x);
}

- (BOOL)isTappableWithHitTestResultView:(UIView *)hitView;
{
    // Special case for UIControls, which may have subviews which don't respond to -hitTest:,
    // but which are tappable. In this case the hit view will be the containing
    // UIControl, and it will forward the tap to the appropriate subview.
    // This applies with UISegmentedControl which contains UISegment views (a private UIView
    // representing a single segment).
    if ([hitView isKindOfClass:[UIControl class]] && [self isDescendantOfView:hitView]) {
        return YES;
    }
    
    // Button views in the nav bar (a private class derived from UINavigationItemView), do not return
    // themselves in a -hitTest:. Instead they return the nav bar.
    if ([hitView isKindOfClass:[UINavigationBar class]] && [self isNavigationItemView] && [self isDescendantOfView:hitView]) {
        return YES;
    }
    
    return [hitView isDescendantOfView:self];
}

- (CGPoint)tappablePointInRect:(CGRect)rect;
{
    // Start at the top and recurse down
    CGRect frame = [self.window convertRect:rect fromView:self];
    
    UIView *hitView = nil;
    CGPoint tapPoint = CGPointZero;
    
    // Mid point
    tapPoint = CGPointCenteredInRect(frame);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Top left
    tapPoint = CGPointMake(frame.origin.x + 1.0f, frame.origin.y + 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Top right
    tapPoint = CGPointMake(frame.origin.x + frame.size.width - 1.0f, frame.origin.y + 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Bottom left
    tapPoint = CGPointMake(frame.origin.x + 1.0f, frame.origin.y + frame.size.height - 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    // Bottom right
    tapPoint = CGPointMake(frame.origin.x + frame.size.width - 1.0f, frame.origin.y + frame.size.height - 1.0f);
    hitView = [self.window hitTest:tapPoint withEvent:nil];
    if ([self isTappableWithHitTestResultView:hitView]) {
        return [self.window convertPoint:tapPoint toView:self];
    }
    
    return CGPointMake(NAN, NAN);
}

- (UIEvent *)eventWithTouches:(NSArray *)touches
{
    // _touchesEvent is a private selector, interface is exposed in UIApplication(KIFAdditionsPrivate)
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    
    [event _clearTouches];
    [event kif_setEventWithTouches:touches];

    for (UITouch *aTouch in touches) {
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }

    return event;
}

- (UIEvent *)eventWithTouch:(UITouch *)touch;
{
    NSArray *touches = touch ? @[touch] : nil;
    return [self eventWithTouches:touches];
}

- (BOOL)isUserInteractionActuallyEnabled;
{
    BOOL isUserInteractionEnabled = self.userInteractionEnabled;
    
    // Navigation item views don't have user interaction enabled, but their parent nav bar does and will forward the event
    if (!isUserInteractionEnabled && [self isNavigationItemView]) {
        // If this view is inside a nav bar, and the nav bar is enabled, then consider it enabled
        UIView *navBar = [self superview];
        while (navBar && ![navBar isKindOfClass:[UINavigationBar class]]) {
            navBar = [navBar superview];
        }
        if (navBar && navBar.userInteractionEnabled) {
            isUserInteractionEnabled = YES;
        }
    }
    
    // UIActionsheet Buttons have UIButtonLabels with userInteractionEnabled=NO inside,
    // grab the superview UINavigationButton instead.
    if (!isUserInteractionEnabled && [self isKindOfClass:NSClassFromString(@"UIButtonLabel")]) {
        UIView *button = [self superview];
        while (button && ![button isKindOfClass:NSClassFromString(@"UINavigationButton")]) {
            button = [button superview];
        }
        if (button && button.userInteractionEnabled) {
            isUserInteractionEnabled = YES;
        }
    }
    
    return isUserInteractionEnabled;
}

- (BOOL)isNavigationItemView;
{
    return [self isKindOfClass:NSClassFromString(@"UINavigationItemView")] || [self isKindOfClass:NSClassFromString(@"_UINavigationBarBackIndicatorView")];
}

- (UIWindow *)windowOrIdentityWindow
{
    if (CGAffineTransformIsIdentity(self.window.transform)) {
        return self.window;
    }
    
    for (UIWindow *window in [[UIApplication sharedApplication] windowsWithKeyWindow]) {
        if (CGAffineTransformIsIdentity(window.transform)) {
            return window;
        }
    }
    
    return nil;
}

- (BOOL)isVisibleInViewHierarchy
{
    __block BOOL result = YES;
    [self performBlockOnAscendentViews:^(UIView *view, BOOL *stop) {
        if (view.isHidden) {
            result = NO;
            if (stop != NULL) {
                *stop = YES;
            }
        }
    }];
    return result;
}

- (void)performBlockOnDescendentViews:(void (^)(UIView *view, BOOL *stop))block
{
    BOOL stop = NO;
    [self performBlockOnDescendentViews:block stop:&stop];
}

- (void)performBlockOnDescendentViews:(void (^)(UIView *view, BOOL *stop))block stop:(BOOL *)stop
{
    block(self, stop);
    if (*stop) {
        return;
    }
    
    for (UIView *view in self.subviews) {
        [view performBlockOnDescendentViews:block stop:stop];
        if (*stop) {
            return;
        }
    }
}

- (void)performBlockOnAscendentViews:(void (^)(UIView *view, BOOL *stop))block
{
    BOOL stop = NO;
    UIView *checkedView = self;
    while(checkedView && stop == NO) {
        block(checkedView, &stop);
        checkedView = checkedView.superview;
    }
}

- (void)printViewHierarchy {
    [self printViewHierarchyWithIndentation:0];
}

+(void)printViewHierarchy {
    NSArray* windows = [UIApplication sharedApplication].windows;
    if(windows.count == 1) {
        [windows[0] printViewHierarchy];
    } else {
        //more than one window, also print some information about each window
        for (UIWindow* window in windows) {
            printf("Window level %f", window.windowLevel);
            if(window.isKeyWindow) printf(" (key window)");
            printf("\n");
            [window printViewHierarchy];
            printf("\n");
        }
    }
}

- (void)printAccessibilityTraits:(UIAccessibilityTraits)traits {
    
    printf("traits: ");
    bool didPrintOne = false;
    if(traits == UIAccessibilityTraitNone) {
        printf("none");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitButton) {
        if(didPrintOne) printf(", ");
        printf("button");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitLink) {
        if(didPrintOne) printf(", ");
        printf("link");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitHeader) {
        if(didPrintOne) printf(", ");
        printf("header");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitSearchField) {
        if(didPrintOne) printf(", ");
        printf("search field");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitImage) {
        if(didPrintOne) printf(", ");
        printf("image");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitSelected) {
        if(didPrintOne) printf(", ");
        printf("selected");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitPlaysSound) {
        if(didPrintOne) printf(", ");
        printf("plays sound");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitKeyboardKey) {
        if(didPrintOne) printf(", ");
        printf("keyboard key");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitStaticText) {
        if(didPrintOne) printf(", ");
        printf("static text");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitSummaryElement) {
        if(didPrintOne) printf(", ");
        printf("summary element");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitNotEnabled) {
        if(didPrintOne) printf(", ");
        printf("not enabled");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitUpdatesFrequently) {
        if(didPrintOne) printf(", ");
        printf("updates frequently");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitStartsMediaSession) {
        if(didPrintOne) printf(", ");
        printf("starts media session");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitAdjustable) {
        if(didPrintOne) printf(", ");
        printf("adjustable");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitAllowsDirectInteraction) {
        if(didPrintOne) printf(", ");
        printf("allows direct interaction");
        didPrintOne = true;
    }
    if(traits & UIAccessibilityTraitCausesPageTurn) {
        if(didPrintOne) printf(", ");
        printf("causes page turn");
        didPrintOne = true;
    }
    if(!didPrintOne) {
        printf("unknown flags (0x%llx)", traits);
    }
}


- (void)printViewHierarchyWithIndentation:(int)indent {
    NSString* name = NSStringFromClass([self class]);
    NSString* label = self.accessibilityLabel;
    NSString* identifier = self.accessibilityIdentifier;
    for(int i = 0; i < indent; ++i) {
        printf("|\t");
    }
    printf("%s", name.UTF8String);
    if(label != nil) {
        printf(", label: %s", label.UTF8String);
    } else if(identifier != nil) {
        printf(", identifier: %s", identifier.UTF8String);
    }
    if(self.hidden) {
        printf(" (invisible)");
    }
    
    if([self isKindOfClass:[UIImageView class]]) {
        if(((UIImageView*)self).highlighted) {
            printf(" (highlighted)");
        } else {
            printf(" (not highlighted)");
        }
    }
    
    if([self isKindOfClass:[UIControl class]]) {
        UIControl* ctrl = (UIControl*)self;
        ctrl.enabled ? printf(" (enabled)") : printf(" (not enabled)");
        ctrl.selected ? printf(" (selected)") : printf(" (not selected)");
        ctrl.highlighted ? printf(" (highlighted)") : printf(" (not highlighted)");
    }
    printf("\n");
    
    //
    NSInteger numOfAccElements = self.accessibilityElementCount;
    if(numOfAccElements != NSNotFound) {
        for (NSInteger i = 0; i < numOfAccElements; ++i) {
            for(int i = 0; i < indent+1; ++i) {
                printf("|\t");
            }
            UIAccessibilityElement *e = [(UIAccessibilityElement*)self accessibilityElementAtIndex:i];
            printf("UIAccessibilityElement, label: %s", e.accessibilityLabel.UTF8String);
            if(e.accessibilityValue && e.accessibilityValue.length > 0) {
                printf(", value: %s", e.accessibilityValue.UTF8String);
            }
            if(e.accessibilityHint && e.accessibilityHint.length > 0) {
                printf(", hint: %s", e.accessibilityHint.UTF8String);
            }
            printf(", ");
            [self printAccessibilityTraits:e.accessibilityTraits];
            printf("\n");
        }
    }
    
    for (UIView *subview in self.subviews) {
        [subview printViewHierarchyWithIndentation:indent+1];
    }
}

@end
