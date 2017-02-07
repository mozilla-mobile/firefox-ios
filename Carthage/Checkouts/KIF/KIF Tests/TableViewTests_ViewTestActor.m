//
//  NewTableViewTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//


#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"
#import "UIApplication-KIFAdditions.h"

@interface TableViewTests_ViewTestActor : KIFTestCase
@end

@implementation TableViewTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"TableViews"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testTappingRows
{
    [[viewTester usingIdentifier:@"TableView Tests Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:2]];
    [[[viewTester usingLabel:@"Last Cell"] usingTraits:UIAccessibilityTraitSelected] waitForView];
    [[viewTester usingIdentifier:@"TableView Tests Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[viewTester usingLabel:@"First Cell"] usingTraits:UIAccessibilityTraitSelected] waitForView];
}

- (void)testTappingLastRowAndSection
{
    [[viewTester usingIdentifier:@"TableView Tests Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1]];
    [[[viewTester usingLabel:@"Last Cell"] usingTraits:UIAccessibilityTraitSelected] waitForView];
}

- (void)testOutOfBounds
{
    KIFExpectFailure([[[viewTester usingTimeout:1] usingIdentifier:@"TableView Tests Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:99]]);
}

- (void)testUnknownTable
{
    KIFExpectFailure([[[viewTester usingTimeout:1] usingIdentifier:@"Unknown Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
}

- (void)testScrollingToTop
{
    [[viewTester usingIdentifier:@"TableView Tests Table"] tapRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    [viewTester tapStatusBar];

    UITableView *tableView = (UITableView *)[viewTester usingIdentifier:@"TableView Tests Table"].view;
    [viewTester runBlock:^KIFTestStepResult(NSError *__autoreleasing *error) {
        KIFTestWaitCondition(tableView.contentOffset.y == - tableView.contentInset.top, error, @"Waited for scroll view to scroll to top, but it ended at %@", NSStringFromCGPoint(tableView.contentOffset));
        return KIFTestStepResultSuccess;
    }];
}

- (void)testTappingRowsByLabel
{
    // Tap the first row, which is already visible
    [[viewTester usingLabel:@"First Cell"] tap];

    // Tap the last row, which will need to be scrolled up
    [[viewTester usingLabel:@"Last Cell"] tap];

    // Tap the first row, which will need to be scrolled down
    [[viewTester usingLabel:@"First Cell"] tap];
}

- (void)testMoveRowDown
{
    [[viewTester usingLabel:@"Edit"] tap];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"Cell 0", @"");
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]].textLabel.text, @"Cell 4", @"");

    [[viewTester usingIdentifier:@"TableView Tests Table"] moveRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"Cell 1", @"");
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]].textLabel.text, @"Cell 0", @"");

    [[viewTester usingLabel:@"Done"] tap];
}

- (void)testMoveRowUp
{
    [[viewTester usingLabel:@"Edit"] tap];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"Cell 0", @"");
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]].textLabel.text, @"Cell 4", @"");

    [[viewTester usingIdentifier:@"TableView Tests Table"] moveRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].textLabel.text, @"Cell 4", @"");
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:1]].textLabel.text, @"Cell 3", @"");

    [[viewTester usingLabel:@"Done"] tap];
}

- (void)testMoveRowUpUsingNegativeRowIndexes
{
    [[viewTester usingLabel:@"Edit"] tap];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1]].textLabel.text, @"Cell 35", @"");
	[viewTester waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1]];
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1]].textLabel.text, @"Cell 37", @"");

    [[viewTester usingIdentifier:@"TableView Tests Table"] moveRowInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1] toIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1]];

    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-3 inSection:1]].textLabel.text, @"Cell 37", @"");
    __KIFAssertEqualObjects([[viewTester usingIdentifier:@"TableView Tests Table"] waitForCellInTableViewAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:1]].textLabel.text, @"Cell 36", @"");

    [[viewTester usingLabel:@"Done"] tap];
}

- (void)testTogglingSwitch
{
    [[viewTester usingLabel:@"Table View Switch"] setSwitchOn:NO];
    [[viewTester usingLabel:@"Table View Switch"] setSwitchOn:YES];
}

- (void)testButtonAbsentAfterRemoveFromSuperview
{
    [[viewTester usingLabel:@"Button"] waitForView];

    [[viewTester usingLabel:@"Button"].view removeFromSuperview];
    [[viewTester usingLabel:@"Button"] waitForAbsenceOfView];
}

- (void)testButtonAbsentAfterSetHidden
{
    [[viewTester usingLabel:@"Button"] waitForView];

    UIView *button = [viewTester usingLabel:@"Button"].view;

    [button setHidden:YES];
    [[viewTester usingLabel:@"Button"] waitForAbsenceOfView];

    [button setHidden:NO];
    [[viewTester usingLabel:@"Button"] waitForView];
}

- (void)testEnteringTextIntoATextFieldInATableCell
{
    [[viewTester usingLabel:@"TextField"] enterText:inputFieldTestString];
}

@end
