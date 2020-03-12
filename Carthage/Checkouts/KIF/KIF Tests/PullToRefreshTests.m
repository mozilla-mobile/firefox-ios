//
//  PullToRefreshTests.m
//  KIF
//
//  Created by Michael Lupo on 9/22/15.
//
//

#import <KIF/KIFTestCase.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import <KIF/KIFTestStepValidation.h>

@interface PullToRefreshTests : KIFTestCase
@end

@implementation PullToRefreshTests

-(void) testPullToRefreshByAccessibilityLabelWithDuration
{
	UITableView *tableView;
	[tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Test Suite TableView" tappable:NO];

	[tester pullToRefreshViewWithAccessibilityLabel:@"Table View" pullDownDuration:KIFPullToRefreshInAboutThreeSeconds];
	[tester waitForViewWithAccessibilityLabel:@"Bingo!"];
	[tester waitForAbsenceOfViewWithAccessibilityLabel:@"Bingo!"];

	[tester waitForTimeInterval:5.0f]; //make sure the PTR is finished.
}

-(void) testPullToRefreshWithBigContentSize
{
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Test Suite TableView" tappable:NO];
    CGSize originalSize = tableView.contentSize;
    tableView.contentSize = CGSizeMake(1000, 10000);
    
    [tester pullToRefreshViewWithAccessibilityLabel:@"Table View" pullDownDuration:KIFPullToRefreshInAboutThreeSeconds];
    [tester waitForViewWithAccessibilityLabel:@"Bingo!"];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Bingo!"];
    
    [tester waitForTimeInterval:5.0f]; //make sure the PTR is finished.
    tableView.contentSize = originalSize;
}

@end
