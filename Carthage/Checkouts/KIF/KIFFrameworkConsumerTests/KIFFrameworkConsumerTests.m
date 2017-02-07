//
//  KIFFrameworkConsumerTests.m
//  KIFFrameworkConsumerTests
//
//  Created by Alex Odawa on 3/30/16.
//
//

#import <KIF/KIF.h>

@interface KIFFrameworkConsumerTests : KIFTestCase

@end

@implementation KIFFrameworkConsumerTests


- (void)test_Framework {
    [tester waitForViewWithAccessibilityLabel:@"Button"];
    [[viewTester usingLabel:@"Button"] tap];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Label"];
    [[viewTester usingLabel:@"Tapped"] waitForView];
}


@end
