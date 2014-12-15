// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Ingredient.h instead.

#import <CoreData/CoreData.h>


extern const struct IngredientAttributes {
	__unsafe_unretained NSString *amount;
	__unsafe_unretained NSString *displayOrder;
	__unsafe_unretained NSString *name;
} IngredientAttributes;

extern const struct IngredientRelationships {
	__unsafe_unretained NSString *recipe;
} IngredientRelationships;

extern const struct IngredientFetchedProperties {
} IngredientFetchedProperties;

@class Recipe;





@interface IngredientID : NSManagedObjectID {}
@end

@interface _Ingredient : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (IngredientID*)objectID;





@property (nonatomic, strong) NSString* amount;



//- (BOOL)validateAmount:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* displayOrder;



@property int16_t displayOrderValue;
- (int16_t)displayOrderValue;
- (void)setDisplayOrderValue:(int16_t)value_;

//- (BOOL)validateDisplayOrder:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Recipe *recipe;

//- (BOOL)validateRecipe:(id*)value_ error:(NSError**)error_;





@end

@interface _Ingredient (CoreDataGeneratedAccessors)

@end

@interface _Ingredient (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAmount;
- (void)setPrimitiveAmount:(NSString*)value;




- (NSNumber*)primitiveDisplayOrder;
- (void)setPrimitiveDisplayOrder:(NSNumber*)value;

- (int16_t)primitiveDisplayOrderValue;
- (void)setPrimitiveDisplayOrderValue:(int16_t)value_;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;





- (Recipe*)primitiveRecipe;
- (void)setPrimitiveRecipe:(Recipe*)value;


@end
