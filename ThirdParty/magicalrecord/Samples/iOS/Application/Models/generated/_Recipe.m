// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Recipe.m instead.

#import "_Recipe.h"

const struct RecipeAttributes RecipeAttributes = {
	.instructions = @"instructions",
	.name = @"name",
	.overview = @"overview",
	.prepTime = @"prepTime",
	.thumbnailImage = @"thumbnailImage",
};

const struct RecipeRelationships RecipeRelationships = {
	.image = @"image",
	.ingredients = @"ingredients",
	.type = @"type",
};

const struct RecipeFetchedProperties RecipeFetchedProperties = {
};

@implementation RecipeID
@end

@implementation _Recipe

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Recipe" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Recipe";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Recipe" inManagedObjectContext:moc_];
}

- (RecipeID*)objectID {
	return (RecipeID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic instructions;






@dynamic name;






@dynamic overview;






@dynamic prepTime;






@dynamic thumbnailImage;






@dynamic image;

	

@dynamic ingredients;

	
- (NSMutableSet*)ingredientsSet {
	[self willAccessValueForKey:@"ingredients"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"ingredients"];
  
	[self didAccessValueForKey:@"ingredients"];
	return result;
}
	

@dynamic type;

	






@end
