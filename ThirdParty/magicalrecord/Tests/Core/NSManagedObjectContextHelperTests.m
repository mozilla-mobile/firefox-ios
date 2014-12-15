//
//  NSManagedObjectContextHelperTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "SingleEntityWithNoRelationships.h"

@interface NSManagedObjectContextHelperTests : MagicalRecordTestBase

@end


@implementation NSManagedObjectContextHelperTests

- (void) testCanCreateContextForCurrentThead
{
    NSManagedObjectContext *firstContext = [NSManagedObjectContext MR_contextForCurrentThread];
    NSManagedObjectContext *secondContext = [NSManagedObjectContext MR_contextForCurrentThread];

    XCTAssertEqualObjects(firstContext, secondContext, @"Contexts should be equal");
}

- (void) testCanNotifyDefaultContextOnSave
{
    NSManagedObjectContext *testContext = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];

    XCTAssertEqualObjects([testContext parentContext], [NSManagedObjectContext MR_defaultContext], @"Parent context should be the default context");
}

- (void) testThatSavedObjectsHavePermanentIDs
{
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    SingleEntityWithNoRelationships *entity = [SingleEntityWithNoRelationships MR_createEntityInContext:context];

    XCTAssertTrue([[entity objectID] isTemporaryID], @"Entity should have a temporary ID before saving");
    [context MR_saveOnlySelfAndWait];
    XCTAssertFalse([[entity objectID] isTemporaryID], @"Entity should not have a temporary ID after saving");
}


@end
