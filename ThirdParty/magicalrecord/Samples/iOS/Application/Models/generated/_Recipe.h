// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Recipe.h instead.

#import <CoreData/CoreData.h>


extern const struct RecipeAttributes {
	__unsafe_unretained NSString *instructions;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *overview;
	__unsafe_unretained NSString *prepTime;
	__unsafe_unretained NSString *thumbnailImage;
} RecipeAttributes;

extern const struct RecipeRelationships {
	__unsafe_unretained NSString *image;
	__unsafe_unretained NSString *ingredients;
	__unsafe_unretained NSString *type;
} RecipeRelationships;

extern const struct RecipeFetchedProperties {
} RecipeFetchedProperties;

@class NSManagedObject;
@class Ingredient;
@class NSManagedObject;





@class NSObject;

@interface RecipeID : NSManagedObjectID {}
@end

@interface _Recipe : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (RecipeID*)objectID;





@property (nonatomic, strong) NSString* instructions;



//- (BOOL)validateInstructions:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* overview;



//- (BOOL)validateOverview:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* prepTime;



//- (BOOL)validatePrepTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) id thumbnailImage;



//- (BOOL)validateThumbnailImage:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSManagedObject *image;

//- (BOOL)validateImage:(id*)value_ error:(NSError**)error_;




@property (nonatomic, strong) NSSet *ingredients;

- (NSMutableSet*)ingredientsSet;




@property (nonatomic, strong) NSManagedObject *type;

//- (BOOL)validateType:(id*)value_ error:(NSError**)error_;





@end

@interface _Recipe (CoreDataGeneratedAccessors)

- (void)addIngredients:(NSSet*)value_;
- (void)removeIngredients:(NSSet*)value_;
- (void)addIngredientsObject:(Ingredient*)value_;
- (void)removeIngredientsObject:(Ingredient*)value_;

@end

@interface _Recipe (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveInstructions;
- (void)setPrimitiveInstructions:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitiveOverview;
- (void)setPrimitiveOverview:(NSString*)value;




- (NSString*)primitivePrepTime;
- (void)setPrimitivePrepTime:(NSString*)value;




- (id)primitiveThumbnailImage;
- (void)setPrimitiveThumbnailImage:(id)value;





- (NSManagedObject*)primitiveImage;
- (void)setPrimitiveImage:(NSManagedObject*)value;



- (NSMutableSet*)primitiveIngredients;
- (void)setPrimitiveIngredients:(NSMutableSet*)value;



- (NSManagedObject*)primitiveType;
- (void)setPrimitiveType:(NSManagedObject*)value;


@end
