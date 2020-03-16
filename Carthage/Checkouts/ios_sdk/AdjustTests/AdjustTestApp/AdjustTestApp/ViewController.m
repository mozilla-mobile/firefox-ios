//
//  ViewController.m
//  AdjustTestApp
//
//  Created by Pedro Silva (@nonelse) on 23rd August 2017.
//  Copyright © 2017-2018 Adjust GmbH. All rights reserved.
//

#import "Adjust.h"
#import "ViewController.h"
#import "ATLTestLibrary.h"
#import "ADJAdjustFactory.h"
#import "ATAAdjustCommandExecutor.h"

@interface ViewController ()

@property (nonatomic, strong) ATLTestLibrary *testLibrary;
@property (nonatomic, strong) ATAAdjustCommandExecutor *adjustCommandExecutor;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.adjustCommandExecutor = [[ATAAdjustCommandExecutor alloc] init];
    self.testLibrary = [ATLTestLibrary testLibraryWithBaseUrl:baseUrl
                                                andControlUrl:controlUrl
                                           andCommandDelegate:self.adjustCommandExecutor];
    [self.adjustCommandExecutor setTestLibrary:self.testLibrary];

    // [self.testLibrary addTestDirectory:@"current/sdkInfo"];
    // [self.testLibrary addTest:@"current/appSecret/Test_AppSecret_no_secret"];

    // [self.testLibrary doNotExitAfterEnd];
    [self startTestSession];
}

- (void)startTestSession {
    [self.testLibrary startTestSession:[Adjust sdkVersion]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)restartTestClick:(UIButton *)sender {
    [self startTestSession];
}

@end
