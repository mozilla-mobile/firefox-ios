// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityWithNoRelationships.m instead.

#import "_SingleEntityWithNoRelationships.h"

const struct SingleEntityWithNoRelationshipsAttributes SingleEntityWithNoRelationshipsAttributes = {
	.booleanAsStringTestAttribute = @"booleanAsStringTestAttribute",
	.booleanTestAttribute = @"booleanTestAttribute",
	.colorTestAttribute = @"colorTestAttribute",
	.dateTestAttribute = @"dateTestAttribute",
	.dateWithCustomFormat = @"dateWithCustomFormat",
	.decimalTestAttribute = @"decimalTestAttribute",
	.doubleTestAttribute = @"doubleTestAttribute",
	.floatTestAttribute = @"floatTestAttribute",
	.int16TestAttribute = @"int16TestAttribute",
	.int32TestAttribute = @"int32TestAttribute",
	.int64TestAttribute = @"int64TestAttribute",
	.mappedStringAttribute = @"mappedStringAttribute",
	.notInJsonAttribute = @"notInJsonAttribute",
	.nullTestAttribute = @"nullTestAttribute",
	.numberAsStringTestAttribute = @"numberAsStringTestAttribute",
	.stringTestAttribute = @"stringTestAttribute",
	.unixTime13TestAttribute = @"unixTime13TestAttribute",
	.unixTimeTestAttribute = @"unixTimeTestAttribute",
};

@implementation SingleEntityWithNoRelationshipsID
@end

@implementation _SingleEntityWithNoRelationships

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"SingleEntityWithNoRelationships" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"SingleEntityWithNoRelationships";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"SingleEntityWithNoRelationships" inManagedObjectContext:moc_];
}

- (SingleEntityWithNoRelationshipsID*)objectID {
	return (SingleEntityWithNoRelationshipsID*)[super objectID];
}

@dynamic booleanAsStringTestAttribute;

@dynamic booleanTestAttribute;

@dynamic colorTestAttribute;

@dynamic dateTestAttribute;

@dynamic dateWithCustomFormat;

@dynamic decimalTestAttribute;

@dynamic doubleTestAttribute;

@dynamic floatTestAttribute;

@dynamic int16TestAttribute;

@dynamic int32TestAttribute;

@dynamic int64TestAttribute;

@dynamic mappedStringAttribute;

@dynamic notInJsonAttribute;

@dynamic nullTestAttribute;

@dynamic numberAsStringTestAttribute;

@dynamic stringTestAttribute;

@dynamic unixTime13TestAttribute;

@dynamic unixTimeTestAttribute;

@end

