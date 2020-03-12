//
//  CollectionViewTests.m
//  Test Suite
//
//  Created by Tony Mann on 7/31/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>
#import "KIFTestStepValidation.h"

@interface CollectionViewTests : KIFTestCase
@end

@implementation CollectionViewTests

- (void)beforeEach
{
    XCTAssertTrue([[tester class] testActorAnimationsEnabled]);
    [tester tapViewWithAccessibilityLabel:@"CollectionViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
    [[tester class] setTestActorAnimationsEnabled:YES];
}

- (void)testTappingItems
{
    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:199 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"First Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingItemsWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];

    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:199 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"First Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingLastItemAndSection
{
    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:-1 inSection:-1] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
}

- (void)testTappingLastItemAndSectionWithoutAnimation
{
    [[tester class] setTestActorAnimationsEnabled:NO];

    [tester tapItemAtIndexPath:[NSIndexPath indexPathForItem:-1 inSection:-1] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"];
    [tester waitForViewWithAccessibilityLabel:@"Last Cell" traits:UIAccessibilityTraitSelected];
}


- (void)testScrollingLastAndFirstRowAtPositionWithAccessiblityIdentifier
{
    UICollectionViewCell *lastCell = [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView" atPosition:UICollectionViewScrollPositionBottom];
    CGRect lastCellConverted = [lastCell.superview convertRect:lastCell.frame toView:nil];
    CGRect superviewConverted = [lastCell convertRect:lastCell.superview.frame toView:nil];
    XCTAssertEqual(lastCellConverted.origin.y, superviewConverted.origin.y);
    UICollectionViewCell *firstCell = [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView" atPosition:UICollectionViewScrollPositionTop];
    CGRect firstCellConverted = [firstCell.superview convertRect:firstCell.frame toView:nil];
    superviewConverted = [firstCell convertRect:firstCell.superview.frame toView:nil];
    XCTAssertEqual(firstCellConverted.origin.y, superviewConverted.origin.y);
}

- (void)testScrollingLastAndFirstRowAtPositionWithView
{
    UICollectionView *collectionView = (UICollectionView *)[[viewTester usingIdentifier:@"CollectionView Tests CollectionView"] waitForView];
    UICollectionViewCell *lastCell = [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:-1 inSection:-1] inCollectionView:collectionView atPosition:UICollectionViewScrollPositionBottom];
    CGRect lastCellConverted = [lastCell.superview convertRect:lastCell.frame toView:nil];
    CGRect superviewConverted = [lastCell convertRect:lastCell.superview.frame toView:nil];
    XCTAssertEqual(lastCellConverted.origin.y, superviewConverted.origin.y);
    UICollectionViewCell *firstCell = [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inCollectionView:collectionView atPosition:UICollectionViewScrollPositionTop];
    CGRect firstCellConverted = [firstCell.superview convertRect:firstCell.frame toView:nil];
    superviewConverted = [firstCell convertRect:firstCell.superview.frame toView:nil];
    XCTAssertEqual(firstCellConverted.origin.y, superviewConverted.origin.y);
}

- (void)testOutOfBounds
{
    KIFExpectFailure([[tester usingTimeout:1] tapItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:99] inCollectionViewWithAccessibilityIdentifier:@"CollectionView Tests CollectionView"]);
}

- (void)testUnknownCollectionView
{
    KIFExpectFailure([[tester usingTimeout:1] tapItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] inCollectionViewWithAccessibilityIdentifier:@"Unknown CollectionView"]);
}

- (void)testTappingItemsByLabel
{
    // Tap the first item, which is already visible
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
    
    // Tap the last item, which will need to be scrolled up
    [tester tapViewWithAccessibilityLabel:@"Last Cell"];
    
    // Tap the first item, which will need to be scrolled down
    [tester tapViewWithAccessibilityLabel:@"First Cell"];
}

@end
