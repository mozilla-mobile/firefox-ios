// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to AbstractRelatedEntity.h instead.

#import <CoreData/CoreData.h>

extern const struct AbstractRelatedEntityAttributes {
	__unsafe_unretained NSString *sampleBaseAttribute;
} AbstractRelatedEntityAttributes;

@interface AbstractRelatedEntityID : NSManagedObjectID {}
@end

@interface _AbstractRelatedEntity : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (AbstractRelatedEntityID*)objectID;

@property (nonatomic, strong) NSString* sampleBaseAttribute;

//- (BOOL)validateSampleBaseAttribute:(id*)value_ error:(NSError**)error_;

@end

@interface _AbstractRelatedEntity (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveSampleBaseAttribute;
- (void)setPrimitiveSampleBaseAttribute:(NSString*)value;

@end
