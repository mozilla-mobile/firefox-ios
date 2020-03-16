//
//  AutocorrectTests.m
//  KIF Tests
//
//  Created by Harley Cooper on 2/7/18.
//

#import <KIF/KIF.h>

#import "KIFTextInputTraitsOverrides.h"

@interface AutocorrectTests : KIFTestCase
@end

@implementation AutocorrectTests

+ (void)setUp
{
    [super setUp];

    KIFTextInputTraitsOverrides.allowDefaultAutocorrectBehavior = YES;
    KIFTextInputTraitsOverrides.allowDefaultSmartDashesBehavior = YES;
    KIFTextInputTraitsOverrides.allowDefaultSmartQuotesBehavior = YES;
}

+ (void)tearDown
{
    [super tearDown];

    KIFTextInputTraitsOverrides.allowDefaultAutocorrectBehavior = NO;
    KIFTextInputTraitsOverrides.allowDefaultSmartDashesBehavior = NO;
    KIFTextInputTraitsOverrides.allowDefaultSmartQuotesBehavior = NO;
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

// These tests won't work on any version of iOS before iOS 11.
#ifdef __IPHONE_11_0
- (void)testSmartQuotesEnabled
{
    if (@available(iOS 11.0, *)) {
        [tester clearTextFromAndThenEnterText:@"'\"'," intoViewWithAccessibilityLabel:@"Greeting" traits:UIAccessibilityTraitNone expectedResult:@"’”’,"];
    }
}

- (void)testSmartDashesEnabled
{
    if (@available(iOS 11.0, *)) {
        [tester clearTextFromAndThenEnterText:@"--a" intoViewWithAccessibilityLabel:@"Greeting" traits:UIAccessibilityTraitNone expectedResult:@"—a"];
    }
}
#endif
@end
