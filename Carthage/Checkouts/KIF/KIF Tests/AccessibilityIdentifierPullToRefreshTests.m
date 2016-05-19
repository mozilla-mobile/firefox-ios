//
//  AccessibilityIdentifierPullToRefreshTests.m
//  KIF
//
//  Created by Michael Lupo on 9/22/15.
//
//

#import <KIF/KIFTestCase.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import <KIF/KIFTestStepValidation.h>

@interface AccessibilityIdentifierPullToRefreshTests : KIFTestCase
@end

@implementation AccessibilityIdentifierPullToRefreshTests

-(void) testPullToRefreshByAccessibilityIdentifier
{
	UITableView *tableView;
	[tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Test Suite TableView" tappable:NO];

	[tester pullToRefreshViewWithAccessibilityIdentifier:@"Test Suite TableView"];
	[tester waitForViewWithAccessibilityLabel:@"Bingo!"];
	[tester waitForAbsenceOfViewWithAccessibilityLabel:@"Bingo!"];
}

-(void) testPullToRefreshByAccessibilityIdentifierWithDuration
{
	UITableView *tableView;
	[tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"Test Suite TableView" tappable:NO];

	[tester pullToRefreshViewWithAccessibilityIdentifier:@"Test Suite TableView" pullDownDuration:KIFPullToRefreshInAboutThreeSeconds];
	[tester waitForViewWithAccessibilityLabel:@"Bingo!"];
	[tester waitForAbsenceOfViewWithAccessibilityLabel:@"Bingo!"];
}

@end
