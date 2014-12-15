// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to DifferentClassNameMapping.m instead.

#import "_DifferentClassNameMapping.h"

@implementation DifferentClassNameMappingID
@end

@implementation _DifferentClassNameMapping

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"EntityWithDifferentClassName" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"EntityWithDifferentClassName";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"EntityWithDifferentClassName" inManagedObjectContext:moc_];
}

- (DifferentClassNameMappingID*)objectID {
	return (DifferentClassNameMappingID*)[super objectID];
}

@end

