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
#import "KIFUITestActor.h"

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
    
    if ([expected rangeOfString:@"\n"].location == NSNotFound &&
        [actual rangeOfString:@"\n"].location == NSNotFound) {
        return NO;
    }
    
    for (NSUInteger i = 0; i < expected.length; i ++) {
        unichar expectedChar = [expected characterAtIndex:i];
        unichar actualChar = [actual characterAtIndex:i];
        if (expectedChar != actualChar &&
           !(expectedChar == '\n' && actualChar == ' ') &&
           !(expectedChar == ' '  && actualChar == '\n')) {
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
        
        return [UIView accessibilityElement:element hasLabel:label accessibilityValue:value traits:traits];
        
    }];
}

+ (BOOL)accessibilityElement:(UIAccessibilityElement *)element hasLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits
{
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
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;
{
    return [self accessibilityElementMatchingBlock:matchBlock notHidden:YES];
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock notHidden:(BOOL)notHidden;
{
    if (notHidden && self.hidden) {
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

        // Avoid crash within accessibilityElementCount while traversing map subviews
        // See https://github.com/kif-framework/KIF/issues/802
        if ([element isKindOfClass:NSClassFromString(@"MKBasicMapView")]) {
            continue;
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
                // Skip table view cell accessibility elements, they're handled below
                if ([subelement isKindOfClass:NSClassFromString(@"UITableViewCellAccessibilityElement")]) {
                    continue;
                }
                
                [elementStack addObject:subelement];
            }
        }
    }
    
    if (!matchingButOccludedElement && self.window) {
        CGPoint scrollContentOffset = {-1.0, -1.0};
        UIScrollView *scrollView = nil;
        if ([self isKindOfClass:[UITableView class]]) {
            NSString * subViewName = nil;
            //special case for UIPickerView (which has a private class UIPickerTableView)
            for (UIView *view in [self subviews])
            {
                subViewName = [NSString stringWithFormat:@"%@", [view class]];
                if ([subViewName containsString:@"UIPicker"] )
                {
                    scrollView = (UIScrollView*)self;
                    scrollContentOffset = [scrollView contentOffset];
                    break;
                }
            }

            UITableView *tableView = (UITableView *)self;
            CGRect initialPosition = CGRectMake(tableView.contentOffset.x, tableView.contentOffset.y, tableView.frame.size.width, tableView.frame.size.height);

            // Because of a bug in [UITableView indexPathsForVisibleRows] http://openradar.appspot.com/radar?id=5191284490764288
            // We use [UITableView visibleCells] to determine the index path of the visible cells
            NSMutableArray *indexPathsForVisibleRows = [[NSMutableArray alloc] init];
            [[tableView visibleCells] enumerateObjectsUsingBlock:^(UITableViewCell *cell, NSUInteger idx, BOOL *stop) {
                NSIndexPath *indexPath = [tableView indexPathForCell:cell];
                if (indexPath) {
                    [indexPathsForVisibleRows addObject:indexPath];
                }
            }];

            CFTimeInterval delay = 0.05;
            for (NSUInteger section = 0, numberOfSections = [tableView numberOfSections]; section < numberOfSections; section++) {
                for (NSUInteger row = 0, numberOfRows = [tableView numberOfRowsInSection:section]; row < numberOfRows; row++) {
                    if (!self.window) {
                        break;
                    }

                    // Skip visible rows because they are already handled.
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                    if ([indexPathsForVisibleRows containsObject:indexPath]) {
                        @autoreleasepool {
                            //scroll to the last row of each section before continuing. Attemps to ensure we can get to sections that are off screen. KIF tests (e.g. testButtonAbsentAfterRemoveFromSuperview) fails without this line. Also without this... we can't expose the next section (in code downstream)
                            [tableView scrollToRowAtIndexPath:[indexPathsForVisibleRows lastObject] atScrollPosition:UITableViewScrollPositionNone animated:NO];
                            continue;
                        }
                    }

                    @autoreleasepool {
                        // Scroll to the cell and wait for the animation to complete. Using animations here may not be optimal.
                        CGRect sectionRect = [tableView rectForRowAtIndexPath:indexPath];
                        [tableView scrollRectToVisible:sectionRect animated:NO];

                        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                        UIAccessibilityElement *element = [cell accessibilityElementMatchingBlock:matchBlock notHidden:NO];

                        // Skip this cell if it isn't the one we're looking for
                        if (!element) {
                            continue;
                        }
                    }

                    // Note: using KIFRunLoopRunInModeRelativeToAnimationSpeed here may cause tests to stall
                    CFRunLoopRunInMode(UIApplicationCurrentRunMode, delay, false);
                    return [self accessibilityElementMatchingBlock:matchBlock];
                }
            }

			//if we're in a picker (scrollView), let's make sure we set the position back to how it was last set.
            if(scrollView != nil && scrollContentOffset.x != -1.0)
            {
                [scrollView setContentOffset:scrollContentOffset];
            } else {
                [tableView scrollRectToVisible:initialPosition animated:NO];
            }
            CFRunLoopRunInMode(UIApplicationCurrentRunMode, delay, false);
        } else if ([self isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self;
            
            NSArray *indexPathsForVisibleItems = [collectionView indexPathsForVisibleItems];
            
            for (NSUInteger section = 0, numberOfSections = [collectionView numberOfSections]; section < numberOfSections; section++) {
                for (NSUInteger item = 0, numberOfItems = [collectionView numberOfItemsInSection:section]; item < numberOfItems; item++) {
                    if (!self.window) {
                        break;
                    }

                    // Skip visible items because they are already handled
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                    if ([indexPathsForVisibleItems containsObject:indexPath]) {
                        continue;
                    }
                    
                    @autoreleasepool {
                        // Get the cell directly from the dataSource because UICollectionView will only vend visible cells
                        UICollectionViewCell *cell = [collectionView.dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];

                        // The cell contents might change just prior to being displayed, so we simulate the cell appearing onscreen
                        if ([collectionView.delegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)]) {
                            [collectionView.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
                        }
                        
                        UIAccessibilityElement *element = [cell accessibilityElementMatchingBlock:matchBlock notHidden:NO];
                        
                        // Remove the cell from the collection view so that it doesn't stick around
                        [cell removeFromSuperview];
                        
                        // Skip this cell if it isn't the one we're looking for
                        // Sometimes we get cells with no size here which can cause an endless loop, so we ignore those
                        if (!element || CGSizeEqualToSize(cell.frame.size, CGSizeZero)) {
                            continue;
                        }
                    }
                    
                    // Scroll to the cell and wait for the animation to complete
                    CGRect frame = [collectionView.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath].frame;
                    [collectionView scrollRectToVisible:frame animated:YES];
                    // Note: using KIFRunLoopRunInModeRelativeToAnimationSpeed here may cause tests to stall
                    CFRunLoopRunInMode(UIApplicationCurrentRunMode, 0.5, false);
                    
                    // Now try finding the element again
                    return [self accessibilityElementMatchingBlock:matchBlock];
                }
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
    NSArray<NSValue *> *path = [self pointsFromStartPoint:startPoint toPoint:endPoint steps:stepCount];
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

- (void)dragPointsAlongPaths:(NSArray<NSArray<NSValue *> *> *)arrayOfPaths {
    // There must be at least one path with at least one point
    if (arrayOfPaths.count == 0 || arrayOfPaths.firstObject.count == 0)
    {
        return;
    }

    // all paths must have the same number of points
    NSUInteger pointsInPath = [arrayOfPaths[0] count];
    for (NSArray *path in arrayOfPaths)
    {
        if (path.count != pointsInPath)
        {
            return;
        }
    }

    NSMutableArray<UITouch *> *touches = [NSMutableArray array];
    
    // Convert paths to be in window coordinates before we start, because the view may
    // move relative to the window.
    NSMutableArray<NSArray<NSValue *> *> *newPaths = [[NSMutableArray alloc] init];
    
    for (NSArray * path in arrayOfPaths) {
        NSMutableArray<NSValue *> *newPath = [[NSMutableArray alloc] init];
        for (NSValue *pointValue in path) {
            CGPoint point = [pointValue CGPointValue];
            [newPath addObject:[NSValue valueWithCGPoint:[self.window convertPoint:point fromView:self]]];
        }
        [newPaths addObject:newPath];
    }
    
    arrayOfPaths = newPaths;

    for (NSUInteger pointIndex = 0; pointIndex < pointsInPath; pointIndex++) {
        // create initial touch event and send touch down event
        if (pointIndex == 0)
        {
            for (NSArray<NSValue *> *path in arrayOfPaths)
            {
                CGPoint point = [path[pointIndex] CGPointValue];
                // The starting point needs to be relative to the view receiving the UITouch event.
                point = [self convertPoint:point fromView:self.window];
                UITouch *touch = [[UITouch alloc] initAtPoint:point inView:self];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseBegan];
                [touches addObject:touch];
            }
            UIEvent *eventDown = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:eventDown];
            
            CFRunLoopRunInMode(UIApplicationCurrentRunMode, DRAG_TOUCH_DELAY, false);
        }
        else
        {
            UITouch *touch;
            for (NSUInteger pathIndex = 0; pathIndex < arrayOfPaths.count; pathIndex++)
            {
                NSArray<NSValue *> *path = arrayOfPaths[pathIndex];
                CGPoint point = [path[pointIndex] CGPointValue];
                touch = touches[pathIndex];
                [touch setLocationInWindow:point];
                [touch setPhaseAndUpdateTimestamp:UITouchPhaseMoved];
            }
            UIEvent *event = [self eventWithTouches:[NSArray arrayWithArray:touches]];
            [[UIApplication sharedApplication] sendEvent:event];

            CFRunLoopRunInMode(UIApplicationCurrentRunMode, DRAG_TOUCH_DELAY, false);

            // The last point needs to also send a phase ended touch.
            if (pointIndex == pointsInPath - 1) {
                for (UITouch * touch in touches) {
                    [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
                    UIEvent *eventUp = [self eventWithTouch:touch];
                    [[UIApplication sharedApplication] sendEvent:eventUp];
                    
                }

            }
        }
    }

    // Dispatching the event doesn't actually update the first responder, so fake it
    if ([touches.firstObject view] == self && [self canBecomeFirstResponder]) {
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
    NSArray<NSValue *> *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray<NSValue *> *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
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
    NSArray<NSValue *> *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray<NSValue *> *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
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
    NSArray<NSValue *> *finger1Path = [self pointsFromStartPoint:finger1Start toPoint:finger1End steps:stepCount];
    NSArray<NSValue *> *finger2Path = [self pointsFromStartPoint:finger2Start toPoint:finger2End steps:stepCount];
    NSArray *paths = @[finger1Path, finger2Path];

    [self dragPointsAlongPaths:paths];
}

- (void)twoFingerRotateAtPoint:(CGPoint)centerPoint angle:(CGFloat)angleInDegrees {
    // Very rough approximation. 90deg = ~45 steps, 360 deg = ~180 steps
    // Enforce a minimum of 2 steps.
    NSInteger stepCount = MAX(ABS(angleInDegrees)/2, 2);

    CGFloat radius = kTwoFingerConstantWidth*2;
    double angleInRadians = KIFDegreesToRadians(angleInDegrees);

    NSMutableArray<NSValue *> *finger1Path = [NSMutableArray array];
    NSMutableArray<NSValue *> *finger2Path = [NSMutableArray array];
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

- (NSArray<NSValue *> *)pointsFromStartPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount {

    CGPoint displacement = CGPointMake(toPoint.x - startPoint.x, toPoint.y - startPoint.y);
    NSMutableArray<NSValue *> *points = [NSMutableArray array];

    for (NSUInteger i = 0; i < stepCount; i++) {
        CGFloat progress = ((CGFloat)i)/(stepCount - 1);
        CGPoint point = CGPointMake(startPoint.x + (progress * displacement.x),
                                    startPoint.y + (progress * displacement.y));
        [points addObject:[NSValue valueWithCGPoint:point]];
    }
    return [points copy];
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
    
    // Somtimes views are inside a UIControl and don't have user interaction enabled.
    // Walk up the hierarchary evaluating the parent UIControl subclass and use that instead.
    if (!isUserInteractionEnabled && [self.superview isKindOfClass:[UIControl class]]) {
        // If this view is inside a UIControl, and it is enabled, then consider the view enabled
        UIControl *control = (UIControl *)[self superview];
        while (control && [control isKindOfClass:[UIControl class]]) {
            if (control.isUserInteractionEnabled) {
                isUserInteractionEnabled = YES;
                break;
            }
            control = (UIControl *)[control superview];
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

- (BOOL)isVisibleInWindowFrame;
{
    __block CGRect visibleFrame = [self.superview convertRect:self.frame toView:nil];
    [self performBlockOnAscendentViews:^(UIView *view, BOOL *stop) {
        if (view.clipsToBounds) {
            CGRect clippingFrame = [view.superview convertRect:view.frame toView:nil];
            visibleFrame = CGRectIntersection(visibleFrame, clippingFrame);
        }
        if (CGSizeEqualToSize(visibleFrame.size, CGSizeZero)) {
            // Our frame has been fully clipped
            *stop = YES;
        }
        if (view.superview == view.window) {
            // Walked all ancestors (skip the top level window that has no superview)
            *stop = YES;
        }
    }];
    return !CGSizeEqualToSize(visibleFrame.size, CGSizeZero);
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


@end
