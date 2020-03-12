//
//  NewWebViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/26/15.
//
//

#import <KIF/KIFTestCase.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import <KIF/KIFTestStepValidation.h>

@interface WebViewTests_ViewTestActor : KIFTestCase
@end


@implementation WebViewTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"WebViews"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testTappingLinks
{
    [[viewTester usingLabel:@"A link"] tap];
    [[viewTester usingLabel:@"Page 2"] waitForView];
}

- (void)testScrolling
{
    // Off screen, the web view will need to be scrolled down
    [[viewTester usingLabel:@"Footer"] waitForView];
}

- (void)testEnteringText
{
    // Needs to opt-out of text validation, because the matched UI element is actually the UIWebView.
    // It responds to `text`, but is equal to whole view's text rather than just being scoped to the entered text.
    [[[viewTester validateEnteredText:NO] usingLabel:@"Input Label"] enterText:@"Keyboard text"];
}

@end
