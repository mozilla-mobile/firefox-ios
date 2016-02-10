//
//  TableViewTests.m
//  Test Suite
//
//  Created by Brian Nickel on 7/31/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"
#import "UIApplication-KIFAdditions.h"

@interface TableViewTests : KIFTestCase
@end

@implementation TableViewTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"TableViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

//TODO: Fail on iOS 9 (UITableViewCell accessibilityTraits is incorrect when selected)
- (void)testTappingRows
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"First Cell" traits:UIAccessibilityTraitSelected];
}

//TODO: Fail on iOS 9 (UITableViewCell accessibilityTraits is incorrect when selected)
- (void)testTappingLastRowAndSection
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testOutOfBounds
{
    KIFExpectFailure([[tester usingTimeout:1] tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:99] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"]);
}

- (void)testUnknownTable
{
    KIFExpectFailure([[tester usingTimeout:1] tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Unknown Table"]);
}

- (void)testScrollingToTop
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester tapStatusBar];
    
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"TableView Tests Table" tappable:NO];
    [tester runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        KIFTestWaitCondition(tableView.contentOffset.y == - tableView.contentInset.top, error, @"Waited for scroll view to scroll to top, but it ended at %@", NSStringFromCGPoint(tableView.contentOffset));
        return KIFTestStepResultSuccess;
    }];
}

- (void)testTappingRowsByLabel
{
    // Tap the first row, which is already visible
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
    
    // Tap the last row, which will need to be scrolled up
    [tester tapViewWithAccessibilityLabel:@"Last Cell"];
    
    // Tap the first row, which will need to be scrolled down
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
}

- (void)testMoveRowDown
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 0", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 4", @"");
    
    [tester moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 1", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 0", @"");
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
}

- (void)testMoveRowUp
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 0", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 4", @"");
    
    [tester moveRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 4", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 3", @"");
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
}

- (void)testMoveRowUpUsingNegativeRowIndexes
{
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 35", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 37", @"");

    [tester moveRowAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];

    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 37", @"");
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Cell 36", @"");
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
}

- (void)testTogglingSwitch
{
    [tester setOn:NO forSwitchWithAccessibilityLabel:@"Table View Switch"];
    [tester setOn:YES forSwitchWithAccessibilityLabel:@"Table View Switch"];
}

- (void)testButtonAbsentAfterRemoveFromSuperview
{
    UIView *view = [tester waitForViewWithAccessibilityLabel:@"Button"];
    
    [view removeFromSuperview];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Button"];
}

- (void)testButtonAbsentAfterSetHidden
{
    UIView *view = [tester waitForViewWithAccessibilityLabel:@"Button"];
    
    [view setHidden:YES];
    [tester waitForAbsenceOfViewWithAccessibilityLabel:@"Button"];

    [view setHidden:NO];
    [tester waitForViewWithAccessibilityLabel:@"Button"];
}

- (void)testEnteringTextIntoATextFieldInATableCell
{
    [tester enterText:@"Test-Driven Development" intoViewWithAccessibilityLabel:@"TextField"];
}

// Delete first and last rows in table view
- (void)testSwipingRows {
    
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"TableView Tests Table" tappable:NO];
    
    // First row
    [tester swipeRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableView:tableView inDirection:KIFSwipeDirectionLeft];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Deleted", @"");
    
    // Last row
    [tester swipeRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] inTableView:tableView inDirection:KIFSwipeDirectionLeft];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Deleted", @"");
    
}

@end
