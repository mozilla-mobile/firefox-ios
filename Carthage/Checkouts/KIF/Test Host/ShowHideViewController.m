//
//  ShowHideViewController.m
//  Test Suite
//
//  Created by Brian K Nickel on 6/26/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShowHideViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *aButton;
@property (weak, nonatomic) IBOutlet UIButton *bButton;
@property (weak, nonatomic) IBOutlet UIView *obscuringView;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@end

@implementation ShowHideViewController

- (IBAction)coverUncoverClicked
{
    CGPoint aCenter = self.aButton.center;
    CGPoint bCenter = self.bButton.center;
    CGPoint center = self.obscuringView.center;
    
    [UIView animateWithDuration:2 animations:^{
        self.obscuringView.center = (ABS(center.y - aCenter.y) < ABS(center.y - bCenter.y)) ? bCenter : aCenter;
    }];
}

- (IBAction)delayedButtonClicked
{
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.contentLabel.hidden = !self.contentLabel.hidden;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DelayedShowHide" object:[UIApplication sharedApplication]];
    });
}

- (IBAction)instantButtonClicked
{
    self.contentLabel.hidden = !self.contentLabel.hidden;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"InstantShowHide" object:[UIApplication sharedApplication]];
}

- (IBAction)toggleSelection:(UIButton *)sender
{
    sender.selected = !sender.selected;
}

@end
