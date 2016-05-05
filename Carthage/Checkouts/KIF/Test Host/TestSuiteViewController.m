//
//  TestSuiteViewController.m
//  Test Suite
//
//  Created by Brian K Nickel on 6/26/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TestSuiteViewController : UITableViewController <UIActionSheetDelegate>
@end

@implementation TestSuiteViewController

-(void) viewDidLoad
{
	[super viewDidLoad];

	//set up an accessibility label on the table.
	self.tableView.isAccessibilityElement = YES;
	self.tableView.accessibilityLabel = @"Table View";

	//set up the pull to refresh with handler.
}

- (void) setupRefreshControl
{
	self.refreshControl = [[UIRefreshControl alloc] init];
	self.refreshControl.backgroundColor = [UIColor grayColor];
	self.refreshControl.tintColor = [UIColor whiteColor];
	[self.refreshControl addTarget:self
							action:@selector(pullToRefreshHandler)
				  forControlEvents:UIControlEventValueChanged];
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing...", @"") attributes:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self setupRefreshControl];
	});
}

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
            [[[UIActionSheet alloc] initWithTitle:@"Action Sheet" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Destroy" otherButtonTitles:@"A", @"B", nil] showInView:tableView];
            break;
        }

        case 3:
        {
            Class AVCClass = NSClassFromString(@"UIActivityViewController");
            if (AVCClass) {
                UIActivityViewController *controller = [[AVCClass alloc] initWithActivityItems:@[@"Hello World"] applicationActivities:nil];

                if ([controller respondsToSelector:@selector(popoverPresentationController)] && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    // iOS 8 iPad presents in a popover
                    controller.popoverPresentationController.sourceView = [tableView cellForRowAtIndexPath:indexPath];
                    UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:controller];
                    [popover presentPopoverFromRect:controller.popoverPresentationController.sourceView.frame inView:tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                } else {
                    [self presentViewController:controller animated:YES completion:nil];
                }
            }
            break;
        }
    }
}

-(void)pullToRefreshHandler
{
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Bingo!", @"") attributes:nil];
	[self.refreshControl performSelector: @selector(endRefreshing) withObject: nil afterDelay: 4.0f];
	[self performSelector: @selector(endedRefreshing) withObject: nil afterDelay: 4.5f]; //just a little hacky
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[[UIAlertView alloc] initWithTitle:@"Alert View" message:@"Message" delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil] show];
}

- (void) endedRefreshing
{
	self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Refreshing...", @"") attributes:nil];
}
@end
