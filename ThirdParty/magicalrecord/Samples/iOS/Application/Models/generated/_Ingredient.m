// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Ingredient.m instead.

#import "_Ingredient.h"

const struct IngredientAttributes IngredientAttributes = {
	.amount = @"amount",
	.displayOrder = @"displayOrder",
	.name = @"name",
};

const struct IngredientRelationships IngredientRelationships = {
	.recipe = @"recipe",
};

const struct IngredientFetchedProperties IngredientFetchedProperties = {
};

@implementation IngredientID
@end

@implementation _Ingredient

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Ingredient" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Ingredient";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Ingredient" inManagedObjectContext:moc_];
}

- (IngredientID*)objectID {
	return (IngredientID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"displayOrderValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"displayOrder"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic amount;






@dynamic displayOrder;



- (int16_t)displayOrderValue {
	NSNumber *result = [self displayOrder];
	return [result shortValue];
}

- (void)setDisplayOrderValue:(int16_t)value_ {
	[self setDisplayOrder:@(value_)];
}

- (int16_t)primitiveDisplayOrderValue {
	NSNumber *result = [self primitiveDisplayOrder];
	return [result shortValue];
}

- (void)setPrimitiveDisplayOrderValue:(int16_t)value_ {
	[self setPrimitiveDisplayOrder:@(value_)];
}





@dynamic name;






@dynamic recipe;

	






@end
