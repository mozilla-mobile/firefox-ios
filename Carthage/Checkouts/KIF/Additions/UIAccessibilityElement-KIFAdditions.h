//
//  UIAccessibilityElement-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/23/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>


@interface UIAccessibilityElement (KIFAdditions)

/*!
 @abstract Finds the first view that the accessibility element is part of.
 @discussion There is not always a one-to-one mapping between views and accessibility elements.  Accessibility elements may not even map to the view you will expect.  For instance, table view cell accessibility elements return the @c UITableView and keyboard keys map to the keyboard as a whole.
 
 @param element The accessibility element.
 @return The first matching @c UIView as determined by the accessibility API.
 */
+ (UIView *)viewContainingAccessibilityElement:(UIAccessibilityElement *)element;

/*!
 @abstract Finds an accessibility element and view with a matching label, value, and traits, optionally passing a tappability test.
 @discussion This method combines @c +accessibilityElementWithLabel:value:traits:error: and @c +viewContainingAccessibilityElement:tappable:error: for convenience.
 @param foundElement The found accessibility element or @c nil if the method returns @c NO.  Can be @c NULL.
 @param foundView The first matching view for @c foundElement as determined by the accessibility API or @c nil if the view is hidden or fails the tappability test. Can be @c NULL.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @param error A reference to an error object to be populated when no matching element or view is found.  Can be @c NULL.
 @result @c YES if the element and view were found.  Otherwise @c NO.
 */
+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits tappable:(BOOL)mustBeTappable error:(out NSError **)error;

/*!
 @abstract Finds an accessibility element and view with a matching label, value, and traits, optionally passing a tappability test.
 @discussion This method combines @c +accessibilityElementWithLabel:value:traits:error: and @c +viewContainingAccessibilityElement:tappable:error: for convenience.
 @param foundElement The found accessibility element or @c nil if the method returns @c NO.  Can be @c NULL.
 @param foundView The first matching view for @c foundElement as determined by the accessibility API or @c nil if the view is hidden or fails the tappability test. Can be @c NULL.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @param fromView The root view to start looking for the accessibility element.
 @param error A reference to an error object to be populated when no matching element or view is found.  Can be @c NULL.
 @result @c YES if the element and view were found.  Otherwise @c NO.
 */
+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits fromRootView:(UIView *)fromView tappable:(BOOL)mustBeTappable error:(out NSError **)error;

/*!
 @abstract Finds an accessibility element with a matching label, value, and traits.
 @discussion This functionality is identical to <tt>-[UIApplication accessibilityElementWithLabel:accessibilityValue:traits:]</tt> except that it detailed error messaging in the case where the element cannot be found.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @param error A reference to an error object to be populated when no element is found.  Can be @c NULL.
 @return The found accessibility element.  If @c nil see the @c error for a detailed reason.
 */
+ (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits error:(out NSError **)error;

/*!
 @abstract Finds an accessibility element with a matching label, value, and traits from specified root view.
 @discussion This functionality is identical to <tt>-[UIApplication accessibilityElementWithLabel:accessibilityValue:traits:]</tt> except that it detailed error messaging in the case where the element cannot be found.
 @param label The accessibility label of the element to wait for.
 @param value The accessibility value of the element to tap.
 @param traits The accessibility traits of the element to wait for. Elements that do not include at least these traits are ignored.
 @param fromView The root view to start looking for the accessibility element.
 @param error A reference to an error object to be populated when no element is found.  Can be @c NULL.
 @return The found accessibility element.  If @c nil see the @c error for a detailed reason.
 */
+ (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label value:(NSString *)value traits:(UIAccessibilityTraits)traits fromRootView:(UIView *)fromView error:(out NSError **)error;

/*!
 @abstract Finds an accessibility element and view from the specified root view where the element passes the predicate, optionally passing a tappability test.
 @param foundElement The found accessibility element or @c nil if the method returns @c NO.  Can be @c NULL.
 @param foundView The first matching view for @c foundElement as determined by the accessibility API or @c nil if the view is hidden or fails the tappability test. Can be @c NULL.
 @param fromView The root view to start looking for the accessibility element.
 @param predicate The predicate to test the accessibility element on.
 @param error A reference to an error object to be populated when no matching element or view is found.  Can be @c NULL.
 @result @c YES if the element and view were found.  Otherwise @c NO.
 */
+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withElementMatchingPredicate:(NSPredicate *)predicate fromRootView:(UIView *)fromView tappable:(BOOL)mustBeTappable error:(out NSError **)error;

/*!
 @abstract Finds an accessibility element and view where the element passes the predicate, optionally passing a tappability test.
 @param foundElement The found accessibility element or @c nil if the method returns @c NO.  Can be @c NULL.
 @param foundView The first matching view for @c foundElement as determined by the accessibility API or @c nil if the view is hidden or fails the tappability test. Can be @c NULL.
 @param predicate The predicate to test the accessibility element on.
 @param error A reference to an error object to be populated when no matching element or view is found.  Can be @c NULL.
 @result @c YES if the element and view were found.  Otherwise @c NO.
 */
+ (BOOL)accessibilityElement:(out UIAccessibilityElement **)foundElement view:(out UIView **)foundView withElementMatchingPredicate:(NSPredicate *)predicate tappable:(BOOL)mustBeTappable error:(out NSError **)error;

/*!
 @abstract Finds and attempts to make visible a view for a given accessibility element.
 @discussion If the element is found, off screen, and is inside a scroll view, this method will attempt to programmatically scroll the view onto the screen before performing any logic as to if the view is tappable.
 
 @param element The accessibility element.
 @param mustBeTappable If @c YES, a tappability test will be performed.
 @param error A reference to an error object to be populated when no element is found.  Can be @c NULL.
 @return The first matching view as determined by the accessibility API or nil if the view is hidden or fails the tappability test.
 */
+ (UIView *)viewContainingAccessibilityElement:(UIAccessibilityElement *)element tappable:(BOOL)mustBeTappable error:(NSError **)error;

/*!
 @abstract Returns a human readable string of UIAccessiblityTrait names, derived from UIAccessibilityConstants.h.
 @param traits The accessibility traits to list.
*/
+ (NSString *)stringFromAccessibilityTraits:(UIAccessibilityTraits)traits;

@end
