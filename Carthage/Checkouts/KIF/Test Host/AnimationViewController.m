//
//  AnimationViewController.m
//  KIF
//
//  Created by Hendrik von Prince on 11.11.14.
//
//

#import <UIKit/UIKit.h>

@interface AnimationViewController : UIViewController
@property (strong, nonatomic) IBOutlet UILabel *testLabel;
@end

@implementation AnimationViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // simulate a time-consuming calculation
    sleep(2);
    self.testLabel.hidden = NO;
}

@end
