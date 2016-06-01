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
    [tester tapViewWithAccessibilityLabel:@"CollectionViews"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testTappingItems
{
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
