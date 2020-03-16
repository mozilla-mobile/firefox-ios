//
//  AutocorrectTests_ViewTestActor.m
//  KIF Tests
//
//  Created by Harley Cooper on 2/7/18.
//

#import <KIF/KIF.h>

#import "KIFTextInputTraitsOverrides.h"

@interface AutocorrectTests_ViewTestActor : KIFTestCase
@end


@implementation AutocorrectTests_ViewTestActor

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
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

// These tests won't work on any version of iOS before iOS 11.
#ifdef __IPHONE_11_0
- (void)testSmartQuotesEnabled
{
    if (@available(iOS 11.0, *)) {
        [[viewTester usingLabel:@"Greeting"] clearAndEnterText:@"'\"'," expectedResult:@"’”’,"];
    }
}

- (void)testSmartDashesEnabled
{
    if (@available(iOS 11.0, *)) {
        [[viewTester usingLabel:@"Greeting"] clearAndEnterText:@"--a" expectedResult:@"—a"];
    }
}
#endif

@end

