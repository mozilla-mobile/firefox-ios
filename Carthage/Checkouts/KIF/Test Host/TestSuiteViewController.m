//
//  TestSuiteViewController.m
//  Test Suite
//
//  Created by Brian K Nickel on 6/26/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestSuiteViewController : UITableViewController
@end

@implementation TestSuiteViewController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != 1) {
        return;
    }

    switch (indexPath.row) {
        case 0:
        {
            [[[UIAlertView alloc] initWithTitle:@"Alert View" message:@"Message" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil] show];
            break;
        }

        case 1:
        {
            break;
        }

        case 2:
        {
            [[[UIActionSheet alloc] initWithTitle:@"Action Sheet" delegate:nil cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Destroy" otherButtonTitles:@"A", @"B", nil] showInView:tableView];
            break;
        }

        case 3:
        {
            Class AVCClass = NSClassFromString(@"UIActivityViewController");
            if (AVCClass) {
                UIActivityViewController *controller = [[AVCClass alloc] initWithActivityItems:@[@"Hello World"] applicationActivities:nil];
                [self presentViewController:controller animated:YES completion:nil];
            }
            break;
        }
    }
}

@end
