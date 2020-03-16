//
//  NewModalViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//

#import <KIF/KIF.h>

@interface ModalViewTests_ViewTestActor : KIFTestCase
@end

@implementation ModalViewTests_ViewTestActor

- (void)beforeEach
{
    [viewTester waitForTimeInterval:0.25];
}

- (void)testInteractionWithAnAlertView
{
    [[viewTester usingLabel:@"UIAlertView"] tap];
    [[viewTester usingLabel:@"Alert View"] waitForView];
    [[viewTester usingLabel:@"Message"] waitForView];
    [[viewTester usingLabel:@"Cancel"] waitForTappableView];
    [[viewTester usingLabel:@"Continue"] waitForTappableView];
    [[viewTester usingLabel:@"Continue"] tap];
    [[viewTester usingLabel:@"Message"] waitForAbsenceOfView];
}

- (void)testInteractionWithAnActionSheet
{
    [[viewTester usingLabel:@"UIActionSheet"] tap];
    [[viewTester usingLabel:@"Action Sheet"] waitForView];
    [[viewTester usingLabel:@"Destroy"] waitForTappableView];
    [[viewTester usingLabel:@"A"] waitForTappableView];
    [[viewTester usingLabel:@"B"] waitForTappableView];

    [self _dismissModal];
    
    [[viewTester usingLabel:@"Alert View"] waitForView];
    [[viewTester usingLabel:@"Continue"] tap];
    [[viewTester usingLabel:@"Alert View"] waitForAbsenceOfView];
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

    [[viewTester usingLabel:@"UIActivityViewController"] tap];
    [[viewTester usingLabel:@"Copy"] waitForTappableView];

    if ([UIDevice.currentDevice.systemVersion compare:@"10.0" options:NSNumericSearch] < 0) {
        [[viewTester usingLabel:@"Mail"] waitForTappableView];
    } else {
        [[viewTester usingLabel:@"Add To iCloud Drive"] waitForTappableView];
    }

    // On iOS7, the activity controller appears at the bottom
    // On iOS8 and beyond, it is shown in a popover control
    if ([UIDevice.currentDevice.systemVersion compare:@"8.0" options:NSNumericSearch] < 0) {
        [[viewTester usingLabel:@"Cancel"] tap];
    } else {
        [self _dismissModal];
    }
}

#pragma mark - Private Methods

- (void)_dismissModal;
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [viewTester dismissPopover];
    } else {
        [[viewTester usingLabel:@"Cancel"] tap];
    }
}

@end
