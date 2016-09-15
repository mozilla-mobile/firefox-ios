//
//  ViewControllertvOS.m
//  AdjustExample-tvOS
//
//  Created by Pedro Filipe on 12/10/15.
//  Copyright © 2015 adjust. All rights reserved.
//

#import "Adjust.h"
#import "Constants.h"
#import "URLRequest.h"
#import "ViewControllertvOS.h"

@interface ViewControllertvOS ()

@property (weak, nonatomic) IBOutlet UIButton *btnTrackSimpleEvent;
@property (weak, nonatomic) IBOutlet UIButton *btnTrackRevenueEvent;
@property (weak, nonatomic) IBOutlet UIButton *btnTrackCallbackEvent;
@property (weak, nonatomic) IBOutlet UIButton *btnTrackPartnerEvent;
@property (weak, nonatomic) IBOutlet UIButton *btnEnableOfflineMode;
@property (weak, nonatomic) IBOutlet UIButton *btnDisableOfflineMode;
@property (weak, nonatomic) IBOutlet UIButton *btnEnableSdk;
@property (weak, nonatomic) IBOutlet UIButton *btnDisableSdk;
@property (weak, nonatomic) IBOutlet UIButton *btnIsSdkEnabled;
@property (weak, nonatomic) IBOutlet UIButton *btnForgetThisDevice;

@end

@implementation ViewControllertvOS

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)clickTrackSimpleEvent:(UIButton *)sender {
    ADJEvent *event = [ADJEvent eventWithEventToken:kEventToken1];

    [Adjust trackEvent:event];
}

- (IBAction)clickTrackRevenueEvent:(UIButton *)sender {
    ADJEvent *event = [ADJEvent eventWithEventToken:kEventToken2];

    // Add revenue 1 cent of an euro.
    [event setRevenue:0.01 currency:@"EUR"];

    [Adjust trackEvent:event];
}

- (IBAction)clickTrackCallbackEvent:(UIButton *)sender {
    ADJEvent *event = [ADJEvent eventWithEventToken:kEventToken3];

    // Add callback parameters to this event.
    [event addCallbackParameter:@"a" value:@"b"];
    [event addCallbackParameter:@"key" value:@"value"];
    [event addCallbackParameter:@"a" value:@"c"];

    [Adjust trackEvent:event];
}

- (IBAction)clickTrackPartnerEvent:(UIButton *)sender {
    ADJEvent *event = [ADJEvent eventWithEventToken:kEventToken4];

    // Add partner parameteres to this event.
    [event addPartnerParameter:@"x" value:@"y"];
    [event addPartnerParameter:@"foo" value:@"bar"];
    [event addPartnerParameter:@"x" value:@"z"];

    [Adjust trackEvent:event];
}

- (IBAction)clickEnableOfflineMode:(id)sender {
    [Adjust setOfflineMode:YES];
}

- (IBAction)clickDisableOfflineMode:(id)sender {
    [Adjust setOfflineMode:NO];
}

- (IBAction)clickEnableSdk:(id)sender {
    [Adjust setEnabled:YES];
}

- (IBAction)clickDisableSdk:(id)sender {
    [Adjust setEnabled:NO];
}

- (IBAction)clickIsSdkEnabled:(id)sender {
    NSString *message;

    if ([Adjust isEnabled]) {
        message = @"SDK is ENABLED!";
    } else {
        message = @"SDK is DISABLED!";
    }

    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Is SDK Enabled?"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)clickForgetThisDevice:(id)sender {
    NSString *idfv = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

    [URLRequest forgetDeviceWithAppToken:kAppToken
                                    idfv:idfv
                         responseHandler:^(NSString *response) {
                             [self responseHandler:response];
                         }];
}

- (void)responseHandler:(NSString *)response {
    NSString *message;

    if ([[response lowercaseString] containsString:[@"Forgot device" lowercaseString]]) {
        message = @"Device is forgotten!";
    } else {
        message = @"Device isn't known!";
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showResultInMainThread:message];
    });
}

- (void)showResultInMainThread:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:@"Forget device"
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
