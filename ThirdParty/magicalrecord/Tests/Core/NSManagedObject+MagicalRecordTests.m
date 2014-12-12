//
//  Created by Tony Arnold on 11/04/2014.
//  Copyright (c) 2014 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "NSManagedObject+MagicalRecord.h"

#import "DifferentClassNameMapping.h"
#import "EntityWithoutEntityNameMethod.h"

@interface NSManagedObjectMagicalRecord : MagicalRecordTestBase

@end

@implementation NSManagedObjectMagicalRecord

- (void)testThatInternalEntityNameReturnsClassNameWhenEntityNameMethodIsNotImplemented
{
    expect([EntityWithoutEntityNameMethod MR_entityName]).toNot.beNil();
    expect([EntityWithoutEntityNameMethod MR_entityName]).to.equal(NSStringFromClass([EntityWithoutEntityNameMethod class]));
}

- (void)testThatInternalEntityNameReturnsProvidedNameWhenEntityNameMethodIsImplemented
{
    expect([EntityWithoutEntityNameMethod MR_entityName]).toNot.beNil();
    expect([DifferentClassNameMapping MR_entityName]).toNot.equal(NSStringFromClass([DifferentClassNameMapping class]));
    expect([DifferentClassNameMapping MR_entityName]).to.equal([DifferentClassNameMapping entityName]);
}

@end
