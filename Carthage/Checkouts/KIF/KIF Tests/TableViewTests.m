//
//  TableViewTests.m
//  Test Suite
//
//  Created by Brian Nickel on 7/31/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import <KIF/KIFUITestActor-IdentifierTests.h>
#import "KIFTestStepValidation.h"
#import "UIApplication-KIFAdditions.h"

@interface TableViewTests : KIFTestCase
@end

@implementation TableViewTests

- (void)beforeEach
{
    XCTAssertTrue([[tester class] testActorAnimationsEnabled]);
    [tester tapViewWithAccessibilityLabel:@"TableViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    [[tester class] setTestActorAnimationsEnabled:YES];
}

- (void)testTappingRows
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"First Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingRowsWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"First Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingLastRowAndSection
{
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1] inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingLastRowAndSectionWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];

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

- (void)testScrollingToTopWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
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

- (void)testTappingRowUnderToolbarByLabel
{
    // Ensure the toolbar is visible
    [tester waitForViewWithAccessibilityIdentifier:@"Toolbar"];

    // Tap row 31, which will scroll so that cell 32 is precisely positioned under the toolbar
    [tester tapViewWithAccessibilityLabel:@"Cell 31"];

    // Tap row 32, which should be scrolled up above the toolbar and then tapped
    [tester tapViewWithAccessibilityLabel:@"Cell 32"];
}

- (void)testTappingRowsByLabelWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
    
    // Tap the first row, which is already visible
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
    
    // Tap the last row, which will need to be scrolled up
    [tester tapViewWithAccessibilityLabel:@"Last Cell"];
    
    // Tap the first row, which will need to be scrolled down
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
}

- (void)testTappingRowUnderToolbarByLabelWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];

    // Ensure the toolbar is visible
    [tester waitForViewWithAccessibilityIdentifier:@"Toolbar"];
    
    // Tap row 31, which will scroll so that cell 32 is precisely positioned under the toolbar
    [tester tapViewWithAccessibilityLabel:@"Cell 31"];
    
    // Tap row 32, which should be scrolled up above the toolbar and then tapped
    [tester tapViewWithAccessibilityLabel:@"Cell 32"];
}

- (void)testWaitingRowByLabel
{
    UIView *v = [tester waitForViewWithAccessibilityLabel:@"First Cell"];
    XCTAssertTrue([v isKindOfClass:[UITableViewCell class]] || [v isKindOfClass:NSClassFromString(@"UITableViewLabel")], @"actual: %@", [v class]);
}

- (void)testWaitingRowByLabelAfterTapping
{
    // for view lookup changes caused by tapping rows
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
    UIView *v = [tester waitForViewWithAccessibilityLabel:@"First Cell"];
    XCTAssertTrue([v isKindOfClass:[UITableViewCell class]] || [v isKindOfClass:NSClassFromString(@"UITableViewLabel")], @"actual: %@", [v class]);
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

- (void)testMoveRowDownWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
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

- (void)testMoveRowUpWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
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

- (void)testMoveRowUpUsingNegativeRowIndexesWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
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

- (void)testTogglingSwitchWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];
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
    [tester enterText:inputFieldTestString intoViewWithAccessibilityLabel:@"TextField"];
}

// Delete first and last rows in table view
- (void)testSwipingRows {
    
    UITableView *tableView;
    [tester waitForAccessibilityElement:NULL view:&tableView withIdentifier:@"TableView Tests Table" tappable:NO];
	[tester waitForAnimationsToFinish];
    // First row
    NSIndexPath *firstCellPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [tester swipeRowAtIndexPath:firstCellPath inTableView:tableView inDirection:KIFSwipeDirectionLeft];
    [tester waitForDeleteStateForCellAtIndexPath:firstCellPath inTableView:tableView];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:firstCellPath inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Deleted", @"");
    
    // Last row
    NSIndexPath *lastCellPath = [NSIndexPath indexPathForRow:1 inSection:2];
    [tester swipeRowAtIndexPath:lastCellPath inTableView:tableView inDirection:KIFSwipeDirectionLeft];
    [tester waitForDeleteStateForCellAtIndexPath:lastCellPath inTableView:tableView];
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    
    __KIFAssertEqualObjects([tester waitForCellAtIndexPath:lastCellPath inTableViewWithAccessibilityIdentifier:@"TableView Tests Table"].textLabel.text, @"Deleted", @"");
}

@end
