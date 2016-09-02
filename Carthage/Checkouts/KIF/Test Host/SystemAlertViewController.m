//
//  SystemAlertViewController.m
//  KIF
//
//  Created by Joe Masilotti on 12/1/14.
//
//

#import <CoreLocation/CoreLocation.h>
#import <AddressBookUI/AddressBookUI.h>

@interface SystemAlertViewController : UIViewController
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation SystemAlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.locationManager = [[CLLocationManager alloc] init];
}

- (IBAction)requestLocationServicesAccess {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (IBAction)requestPhotosAccess {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (IBAction)requestNotificationScheduling {
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
}

- (IBAction)requestLocationServicesAndNotificicationsSchedulingAccesses {
	[self requestLocationServicesAccess];
	[self requestNotificationScheduling];
}

@end
