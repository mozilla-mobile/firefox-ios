//
//  UIView-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>

extern double KIFDegreesToRadians(double deg);
extern double KIFRadiansToDegrees(double rad);

typedef CGPoint KIFDisplacement;

@interface UIView (KIFAdditions)

@property (nonatomic, readonly, getter=isProbablyTappable) BOOL probablyTappable;

- (BOOL)isDescendantOfFirstResponder;
- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label;
- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label traits:(UIAccessibilityTraits)traits;
- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;
+ (BOOL)accessibilityElement:(UIAccessibilityElement *)element hasLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;

/*!
 @method accessibilityElementMatchingBlock:
 @abstract Finds the descendent accessibility element that matches the conditions defined by the match block.
 @param matchBlock A block which returns YES for matching elements.
 @result The matching accessibility element.
 */
- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;

- (UIView *)subviewWithClassNamePrefix:(NSString *)prefix __deprecated;
- (NSArray *)subviewsWithClassNamePrefix:(NSString *)prefix;
- (UIView *)subviewWithClassNameOrSuperClassNamePrefix:(NSString *)prefix __deprecated;
- (NSArray *)subviewsWithClassNameOrSuperClassNamePrefix:(NSString *)prefix;

- (void)flash;
- (void)tap;
- (void)tapAtPoint:(CGPoint)point;
- (void)twoFingerTapAtPoint:(CGPoint)point;
- (void)longPressAtPoint:(CGPoint)point duration:(NSTimeInterval)duration;

/*!
 @method dragFromPoint:toPoint:
 @abstract Simulates dragging a finger on the screen between the given points.
 @discussion Causes the application to dispatch a sequence of touch events which simulate dragging a finger from startPoint to endPoint.
 @param startPoint The point at which to start the drag, in the coordinate system of the receiver.
 @param endPoint The point at which to end the drag, in the coordinate system of the receiver.
 */
- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint;
- (void)dragFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint steps:(NSUInteger)stepCount;
- (void)dragFromPoint:(CGPoint)startPoint displacement:(KIFDisplacement)displacement steps:(NSUInteger)stepCount;
- (void)dragAlongPathWithPoints:(CGPoint *)points count:(NSInteger)count;
- (void)twoFingerPanFromPoint:(CGPoint)startPoint toPoint:(CGPoint)toPoint steps:(NSUInteger)stepCount;
- (void)pinchAtPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount;
- (void)zoomAtPoint:(CGPoint)centerPoint distance:(CGFloat)distance steps:(NSUInteger)stepCount;
- (void)twoFingerRotateAtPoint:(CGPoint)centerPoint angle:(CGFloat)angleInDegrees;
/*!
 @method isTappableWithHitTestResultView:
 @abstract Easy hook to override whether a hit test result makes a view tappable.
 @discussion Some times, your view hierarchies involve putting overlays over views that would otherwise be tappable. Since KIF doesn't know about these exceptions, you can override this method as a convenient way of hooking in to the check for something being tappable. Your implementation will probably want to call up to super.
 @param hitView The view -hitTest: returned when trying to tap on a point inside your view's bounds
 @result Whether or not the view is tappable.
 */
- (BOOL)isTappableWithHitTestResultView:(UIView *)hitView;

/*!
 @method isTappableInRect:
 @abstract Whether or not the receiver can be tapped inside the given rectangular area.
 @discussion Determines whether or not tapping within the given rectangle would actually hit the receiver or one of its children. This is useful for determining if the view is actually on screen and enabled.
 @param rect A rectangle specifying an area in the receiver in the receiver's frame coordinates.
 @result Whether or not the view is tappable.
 */
- (BOOL)isTappableInRect:(CGRect)rect;

/*!
 @method tappablePointInRect:(CGRect)rect;
 @abstract Finds a point in the receiver that is tappable.
 @discussion Finds a tappable point in the receiver, where tappable is defined as a point that, when tapped, will hit the receiver.
 @param rect A rectangle specifying an area in the receiver in the receiver's frame coordinates.
 @result A tappable point in the receivers frame coordinates.
 */
- (CGPoint)tappablePointInRect:(CGRect)rect;

- (UIEvent *)eventWithTouch:(UITouch *)touch;

/*!
 @abstract Evaluates if user interaction is enabled including edge cases.
 */
- (BOOL)isUserInteractionActuallyEnabled;

/*!
 @abstract Evaluates if the view and all its superviews are visible.
 */
- (BOOL)isVisibleInViewHierarchy;

/*!
 @abstract Evaluates if the view has some portion of its frame intersect with its ancestor views clip it from being visible on the screen.
 */
- (BOOL)isVisibleInWindowFrame;

/*!
 @method performBlockOnDescendentViews:
 @abstract Calls a block on the view itself and on all its descendent views.
 @param block The block that will be called on the views. Stop the traversation of the views by assigning YES to the stop-parameter of the block.
 */
- (void)performBlockOnDescendentViews:(void (^)(UIView *view, BOOL *stop))block;

/*!
 @method performBlockOnAscendentViews:
 @abstract Calls a block on the view itself and on all its superviews.
 @param block The block that will be called on the views. Stop the traversation of the views by assigning YES to the stop-parameter of the block.
 */
- (void)performBlockOnAscendentViews:(void (^)(UIView *view, BOOL *stop))block;

/*!
 @abstract Returns either the current window or another window if a transform is applied.  Returns `nil` if all windows in the application have transforms.
 */
@property (nonatomic, readonly) UIWindow *windowOrIdentityWindow;

@end
