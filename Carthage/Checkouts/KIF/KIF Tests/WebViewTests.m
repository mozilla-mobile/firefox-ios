//
//  WebViewTests.m
//  KIF
//
//  Created by Joe Masilotti on 11/19/14.
//
//

#import <KIF/KIFTestCase.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import <KIF/KIFTestStepValidation.h>

@interface WebViewTests : KIFTestCase
@end

@implementation WebViewTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"WebViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testTappingLinks {
    [tester tapViewWithAccessibilityLabel:@"A link"];
    [tester waitForViewWithAccessibilityLabel:@"Page 2"];
}

- (void)testScrolling {
    // Off screen, the web view will need to be scrolled down
    [tester waitForViewWithAccessibilityLabel:@"Footer"];
}

- (void)testEnteringText {
    [tester tapViewWithAccessibilityLabel:@"Input Label"];
    [tester enterTextIntoCurrentFirstResponder:@"Keyboard text"];
}

@end
