// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to AbstractRelatedEntity.m instead.

#import "_AbstractRelatedEntity.h"

const struct AbstractRelatedEntityAttributes AbstractRelatedEntityAttributes = {
	.sampleBaseAttribute = @"sampleBaseAttribute",
};

@implementation AbstractRelatedEntityID
@end

@implementation _AbstractRelatedEntity

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"AbstractRelatedEntity" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"AbstractRelatedEntity";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"AbstractRelatedEntity" inManagedObjectContext:moc_];
}

- (AbstractRelatedEntityID*)objectID {
	return (AbstractRelatedEntityID*)[super objectID];
}

@dynamic sampleBaseAttribute;

@end

