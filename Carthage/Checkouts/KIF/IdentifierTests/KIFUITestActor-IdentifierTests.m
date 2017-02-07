//
//  KIFUITestActor+IdentifierTests.m
//  KIF
//
//  Created by Brian Nickel on 11/6/14.
//
//

#import <UIKit/UIKit.h>
#import "KIFUITestActor-IdentifierTests.h"
#import "UIAccessibilityElement-KIFAdditions.h"
#import "NSError-KIFAdditions.h"
#import "UIWindow-KIFAdditions.h"

@implementation KIFUITestActor (IdentifierTests)

- (UIView *)waitForViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    return [self waitForViewWithAccessibilityIdentifier:accessibilityIdentifier tappable:NO];
}

- (UIView *)waitForTappableViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    return [self waitForViewWithAccessibilityIdentifier:accessibilityIdentifier tappable:YES];
}

- (void)tapViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    @autoreleasepool {
        UIView *view = nil;
        UIAccessibilityElement *element = nil;
        [self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
        [self tapAccessibilityElement:element inView:view];
    }
}

- (void)waitForAbsenceOfViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", accessibilityIdentifier];
    [self waitForAbsenceOfViewWithElementMatchingPredicate:predicate];
}

- (UIView *)waitForViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier tappable:(BOOL)mustBeTappable
{
    UIView *view = nil;
    @autoreleasepool {
        [self waitForAccessibilityElement:NULL view:&view withIdentifier:accessibilityIdentifier tappable:mustBeTappable];
    }
    
    return view;
}

- (void)longPressViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier duration:(NSTimeInterval)duration
{
	@autoreleasepool {
		UIView *view = nil;
		UIAccessibilityElement *element = nil;
		[self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
		[self longPressAccessibilityElement:element inView:view duration:duration];
	}
}

- (void)enterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	return [self enterText:text intoViewWithAccessibilityIdentifier:accessibilityIdentifier expectedResult:nil];
}

- (void)enterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier expectedResult:(NSString *)expectedResult
{
	UIView *view = nil;
	UIAccessibilityElement *element = nil;
	
	[self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
    [self enterText:text intoElement:element inView:view expectedResult:expectedResult];
}

- (void)clearTextFromViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	UIView *view = nil;
	UIAccessibilityElement *element = nil;
	
	[self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
	[self clearTextFromElement:element inView:view];
}

- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	[self clearTextFromViewWithAccessibilityIdentifier:accessibilityIdentifier];
	[self enterText:text intoViewWithAccessibilityIdentifier:accessibilityIdentifier];
}

- (void)clearTextFromAndThenEnterText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier expectedResult:(NSString *)expectedResult
{
	[self clearTextFromViewWithAccessibilityIdentifier:accessibilityIdentifier];
	[self enterText:text intoViewWithAccessibilityIdentifier:accessibilityIdentifier expectedResult:expectedResult];
}

- (void)setText:(NSString *)text intoViewWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
    UIView *view = nil;
    UIAccessibilityElement *element = nil;

    [self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
    if ([view respondsToSelector:@selector(setText:)]) {
        [view performSelector:@selector(setText:) withObject:text];
    }
}

- (void)setOn:(BOOL)switchIsOn forSwitchWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	UIView *view = nil;
	UIAccessibilityElement *element = nil;
	
	[self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
	
	if (![view isKindOfClass:[UISwitch class]]) {
		[self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility identifier \"%@\" is a %@, not a UISwitch", accessibilityIdentifier, NSStringFromClass([view class])] stopTest:YES];
	}
	
	UISwitch *switchView = (UISwitch *)view;
	
	// No need to switch it if it's already in the correct position
	if (switchView.isOn == switchIsOn) {
		return;
	}
	
	[self tapAccessibilityElement:element inView:view];
	
	// If we succeeded, stop the test.
	if (switchView.isOn == switchIsOn) {
		return;
	}
	
	NSLog(@"Faking turning switch %@ with accessibility identifier %@", switchIsOn ? @"ON" : @"OFF", accessibilityIdentifier);
	[switchView setOn:switchIsOn animated:YES];
	[switchView sendActionsForControlEvents:UIControlEventValueChanged];
	[self waitForTimeInterval:0.5];
	
	// We gave it our best shot.  Fail the test.
	if (switchView.isOn != switchIsOn) {
		[self failWithError:[NSError KIFErrorWithFormat:@"Failed to toggle switch to \"%@\"; instead, it was \"%@\"", switchIsOn ? @"ON" : @"OFF", switchView.on ? @"ON" : @"OFF"] stopTest:YES];
	}
	
}

- (void)setValue:(float)value forSliderWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	UISlider *slider = nil;
	UIAccessibilityElement *element = nil;
	[self waitForAccessibilityElement:&element view:&slider withIdentifier:accessibilityIdentifier tappable:YES];
	
	if (![slider isKindOfClass:[UISlider class]]) {
		[self failWithError:[NSError KIFErrorWithFormat:@"View with accessibility identifier \"%@\" is a %@, not a UISlider", accessibilityIdentifier, NSStringFromClass([slider class])] stopTest:YES];
	}
	[self setValue:value forSlider:slider];
}

- (void)waitForFirstResponderWithAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
	[self runBlock:^KIFTestStepResult(NSError **error) {
		UIResponder *firstResponder = [[[UIApplication sharedApplication] keyWindow] firstResponder];
		if ([firstResponder isKindOfClass:NSClassFromString(@"UISearchBarTextField")]) {
			do {
				firstResponder = [(UIView *)firstResponder superview];
			} while (firstResponder && ![firstResponder isKindOfClass:[UISearchBar class]]);
		}
		UIResponder<UIAccessibilityIdentification>* firstResponderIdentification = nil;
		if ([firstResponder conformsToProtocol:@protocol(UIAccessibilityIdentification)])
		{
			firstResponderIdentification = (UIResponder<UIAccessibilityIdentification>*)firstResponder;
		}
		else
		{
			[self failWithError:[NSError KIFErrorWithFormat:@"First responder does not conform to UIAccessibilityIdentification %@",  NSStringFromClass([firstResponder class])] stopTest:YES];
			
		}
		KIFTestWaitCondition([[firstResponderIdentification accessibilityIdentifier] isEqualToString:accessibilityIdentifier],
							 error, @"Expected accessibility identifier for first responder to be '%@', got '%@'",
							 accessibilityIdentifier, [firstResponderIdentification accessibilityIdentifier]);
		
		return KIFTestStepResultSuccess;
	}];
}

- (BOOL) tryFindingViewWithAccessibilityIdentifier:(NSString *) accessibilityIdentifier
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accessibilityIdentifier = %@", accessibilityIdentifier];
    return [UIAccessibilityElement accessibilityElement:nil view:nil withElementMatchingPredicate:predicate tappable:NO error:nil];
}

- (void)swipeViewWithAccessibilityIdentifier:(NSString *)identifier inDirection:(KIFSwipeDirection)direction
{
    UIView *viewToSwipe = nil;
    UIAccessibilityElement *element = nil;

    [self waitForAccessibilityElement: &element view:&viewToSwipe withIdentifier:identifier tappable:NO];

    [self swipeAccessibilityElement:element inView:viewToSwipe inDirection:direction];
}

- (void)pullToRefreshViewWithAccessibilityIdentifier:(NSString *)identifier
{
	UIView *viewToSwipe = nil;
	UIAccessibilityElement *element = nil;

	[self waitForAccessibilityElement: &element view:&viewToSwipe withIdentifier:identifier tappable:NO];

	[self pullToRefreshAccessibilityElement:element inView:viewToSwipe pullDownDuration:0];
}

- (void)pullToRefreshViewWithAccessibilityIdentifier:(NSString *)identifier pullDownDuration:(KIFPullToRefreshTiming) pullDownDuration
{
	UIView *viewToSwipe = nil;
	UIAccessibilityElement *element = nil;

	[self waitForAccessibilityElement: &element view:&viewToSwipe withIdentifier:identifier tappable:NO];

	[self pullToRefreshAccessibilityElement:element inView:viewToSwipe pullDownDuration:pullDownDuration];
}

-(void) tapStepperWithAccessibilityIdentifier: (NSString *)accessibilityIdentifier increment: (KIFStepperDirection) stepperDirection
{
	@autoreleasepool {
		UIView *view = nil;
		UIAccessibilityElement *element = nil;
		[self waitForAccessibilityElement:&element view:&view withIdentifier:accessibilityIdentifier tappable:YES];
		[self tapStepperWithAccessibilityElement:element increment:stepperDirection inView:view];
	}
}
@end
