//
//  ModalViewTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

@interface ModalViewTests : KIFTestCase
@end

@implementation ModalViewTests

- (void)beforeEach
{
    [tester waitForTimeInterval:0.25];
}

- (void)testInteractionWithAnAlertView
{
    [tester tapViewWithAccessibilityLabel:@"UIAlertView"];
    [tester waitForViewWithAccessibilityLabel:@"Alert View"];
    [tester waitForViewWithAccessibilityLabel:@"Message"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Cancel"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Continue"];
    [tester tapViewWithAccessibilityLabel:@"Continue"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Message"];
}

- (void)testInteractionWithAnActionSheet
{
    [tester tapViewWithAccessibilityLabel:@"UIActionSheet"];
    [tester waitForViewWithAccessibilityLabel:@"Action Sheet"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Destroy"];
    [tester waitForTappableViewWithAccessibilityLabel:@"A"];
    [tester waitForTappableViewWithAccessibilityLabel:@"B"];

    [self _dismissModal];

    [tester waitForViewWithAccessibilityLabel:@"Alert View"];
    [tester tapViewWithAccessibilityLabel:@"Continue"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Alert View"];
}

- (void)testInteractionWithAnActivityViewController
{
    NSOperatingSystemVersion iOS11 = {11, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)]
        && [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS11]) {
        NSLog(@"This test can't be run on iOS 11, as the activity sheet is hosted in an `AXRemoteElement`");
        return;
    }
    
    if (!NSClassFromString(@"UIActivityViewController")) {
        return;
    }
    
    [tester tapViewWithAccessibilityLabel:@"UIActivityViewController"];
    [tester waitForTappableViewWithAccessibilityLabel:@"Copy"];

    if ([UIDevice.currentDevice.systemVersion compare:@"10.0" options:NSNumericSearch] < 0) {
        [tester waitForTappableViewWithAccessibilityLabel:@"Mail"];
    } else {
        [tester waitForTappableViewWithAccessibilityLabel:@"Add To iCloud Drive"];
    }

    // On iOS7, the activity controller appears at the bottom
    // On iOS8 and beyond, it is shown in a popover control
    if ([UIDevice.currentDevice.systemVersion compare:@"8.0" options:NSNumericSearch] < 0) {
        [tester tapViewWithAccessibilityLabel:@"Cancel"];
    } else {
        [self _dismissModal];
    }

    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Copy"];
}

#pragma mark - Private Methods

- (void)_dismissModal;
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [tester dismissPopover];
    } else {
        [tester tapViewWithAccessibilityLabel:@"Cancel"];
    }
}

@end
