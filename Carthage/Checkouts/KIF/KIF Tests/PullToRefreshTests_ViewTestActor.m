//
//  PullToRefreshTests_ViewTestActor.m
//  KIF
//
//  Created by Alex Odawa on 1/29/16.
//
//

#import <Foundation/Foundation.h>
#import "KIFUIViewTestActor.h"

@interface PullToRefreshTests_ViewTestActor : KIFTestCase
@end

@implementation PullToRefreshTests_ViewTestActor

-(void) testPullToRefreshByAccessibilityLabelWithDuration
{
    [[viewTester usingIdentifier:@"Test Suite TableView"] waitForView];
    [[viewTester usingLabel:@"Table View"] pullToRefreshWithDuration:KIFPullToRefreshInAboutOneSecond];
    [[viewTester usingLabel:@"Bingo!"] waitForView];
    [[viewTester usingLabel:@"Bingo!"] waitForAbsenceOfView];
    [viewTester waitForTimeInterval:1.0f];
}

-(void) testPullToRefreshWithBigContentSize
{
    
    UITableView *tableView = (id)[[viewTester usingIdentifier:@"Test Suite TableView"] waitForView];
    CGSize originalSize = tableView.contentSize;
    tableView.contentSize = CGSizeMake(1000, 10000);

    [[viewTester usingLabel:@"Table View"] pullToRefreshWithDuration:KIFPullToRefreshInAboutOneSecond];
    [[viewTester usingLabel:@"Bingo!"] waitForView];
    [[viewTester usingLabel:@"Bingo!"] waitForAbsenceOfView];
    [viewTester waitForTimeInterval:1.0f];
    
    tableView.contentSize = originalSize;
}

@end
