//
//  Created by Tony Arnold on 21/12/2013.
//  Copyright (c) 2013 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordTestBase.h"
#import "MagicalRecordLogging.h"

@implementation MagicalRecordTestBase

- (void)setUp
{
    [super setUp];

    // Don't pollute the tests with logging
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];

    // Setup the default model from the current class' bundle
    [MagicalRecord setDefaultModelFromClass:[self class]];

    // Setup a default in-memory store
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
}

- (void)tearDown
{
    [MagicalRecord cleanUp];

    [super tearDown];
}

@end
