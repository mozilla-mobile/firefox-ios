//
//  CompositionTests.m
//  Test Suite
//
//  Created by Brian Nickel on 7/31/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import "UIApplication-KIFAdditions.h"
#import "UIAccessibilityElement-KIFAdditions.h"

@interface KIFUITestActor (Composition)

- (void)tapViewIfNotSelected:(NSString *)label;
- (void)tapViewWithAccessibilityHint:(NSString *)hint;

@end

@implementation KIFUITestActor (Composition)

- (void)tapViewIfNotSelected:(NSString *)label
{
    UIAccessibilityElement *element;
    UIView *view;
    [self waitForAccessibilityElement:&element view:&view withLabel:label value:nil traits:UIAccessibilityTraitNone tappable:YES];
    
    if ((element.accessibilityTraits & UIAccessibilityTraitSelected) == UIAccessibilityTraitNone) {
        [self tapAccessibilityElement:element inView:view];
    }
}

- (void)tapViewWithAccessibilityHint:(NSString *)hint
{
    __block UIAccessibilityElement *element;
    __block UIView *view;
    
    [self runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        
        element = [[UIApplication sharedApplication] accessibilityElementMatchingBlock:^BOOL(UIAccessibilityElement *element) {
            return [element.accessibilityHint isEqualToString:hint];
        }];
        
        KIFTestWaitCondition(element, error, @"Could not find element with hint: %@", hint);
        
        view = [UIAccessibilityElement viewContainingAccessibilityElement:element tappable:YES error:error];
        return view ? KIFTestStepResultSuccess : KIFTestStepResultWait;
    }];
    
    [self tapAccessibilityElement:element inView:view];
}

@end

@interface CompositionTests : KIFTestCase
@end

@implementation CompositionTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Show/Hide"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testTappingViewWithHint
{
    [tester tapViewWithAccessibilityHint:@"A button for A"];
    [tester waitForViewWithAccessibilityLabel:@"A" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingOnlyIfNotSelected
{
    [tester tapViewIfNotSelected:@"A"];
    [tester waitForViewWithAccessibilityLabel:@"A" traits:UIAccessibilityTraitSelected];
    
    // This should not deselect the element.
    [tester tapViewIfNotSelected:@"A"];
    [tester waitForViewWithAccessibilityLabel:@"A" traits:UIAccessibilityTraitSelected];
}

@end
