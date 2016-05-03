//
//  KIFUITestActor-ConditionalTests.h
//  KIF
//
//  Created by Brian Nickel on 7/24/14.
//
//

#import "KIF.h"

@interface KIFUITestActor (ConditionalTests)

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 
 If the view you want to check for is tappable, use the -tryFindingTappableViewWithAccessibilityLabel: methods instead as they provide a more strict test.
 
 */
- (BOOL)tryFindingViewWithAccessibilityLabel:(NSString *)label error:(out NSError **)error;

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (BOOL)tryFindingViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits error:(out NSError **)error;

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (BOOL)tryFindingViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits error:(out NSError **)error;

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 */
- (BOOL)tryFindingTappableViewWithAccessibilityLabel:(NSString *)label error:(out NSError **)error;

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (BOOL)tryFindingTappableViewWithAccessibilityLabel:(NSString *)label traits:(UIAccessibilityTraits)traits error:(out NSError **)error;

/*!
 @abstract Checks if an accessibility element is visible on screen.
 @discussion The view or accessibility element with the given label is searched in the view hierarchy. If the element isn't found, then NO is returned.  Note that the view does not necessarily have to be visible on the screen, and may be behind another view or offscreen. Views with their hidden property set to YES are ignored.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 */
- (BOOL)tryFindingTappableViewWithAccessibilityLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits error:(out NSError **)error;

- (BOOL)tryFindingAccessibilityElement:(out UIAccessibilityElement **)element view:(out UIView **)view withIdentifier:(NSString *)identifier tappable:(BOOL)mustBeTappable error:(out NSError **)error;

- (BOOL)tryFindingAccessibilityElement:(out UIAccessibilityElement **)element view:(out UIView **)view withElementMatchingPredicate:(NSPredicate *)predicate tappable:(BOOL)mustBeTappable error:(out NSError **)error;

@end
