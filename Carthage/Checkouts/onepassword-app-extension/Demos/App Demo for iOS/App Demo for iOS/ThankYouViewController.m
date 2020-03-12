//
//  ThankYouViewController.m
//  App Demo for iOS
//
//  Created by Rad Azzouz on 2014-07-21.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "ThankYouViewController.h"

@interface ThankYouViewController ()

@end

@implementation ThankYouViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"login-background.png"]]];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleLightContent;
}

@end
