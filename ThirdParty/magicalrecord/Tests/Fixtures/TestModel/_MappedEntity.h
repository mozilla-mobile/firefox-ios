// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to MappedEntity.h instead.

#import <CoreData/CoreData.h>

extern const struct MappedEntityAttributes {
	__unsafe_unretained NSString *mappedEntityID;
	__unsafe_unretained NSString *nestedAttribute;
	__unsafe_unretained NSString *sampleAttribute;
	__unsafe_unretained NSString *testMappedEntityID;
} MappedEntityAttributes;

extern const struct MappedEntityUserInfo {
	__unsafe_unretained NSString *relatedByAttribute;
} MappedEntityUserInfo;

@interface MappedEntityID : NSManagedObjectID {}
@end

@interface _MappedEntity : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (MappedEntityID*)objectID;

@property (nonatomic, strong) NSNumber* mappedEntityID;

//- (BOOL)validateMappedEntityID:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* nestedAttribute;

//- (BOOL)validateNestedAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* sampleAttribute;

//- (BOOL)validateSampleAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* testMappedEntityID;

//- (BOOL)validateTestMappedEntityID:(id*)value_ error:(NSError**)error_;

@end

@interface _MappedEntity (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveMappedEntityID;
- (void)setPrimitiveMappedEntityID:(NSNumber*)value;

- (NSString*)primitiveNestedAttribute;
- (void)setPrimitiveNestedAttribute:(NSString*)value;

- (NSString*)primitiveSampleAttribute;
- (void)setPrimitiveSampleAttribute:(NSString*)value;

- (NSNumber*)primitiveTestMappedEntityID;
- (void)setPrimitiveTestMappedEntityID:(NSNumber*)value;

@end
