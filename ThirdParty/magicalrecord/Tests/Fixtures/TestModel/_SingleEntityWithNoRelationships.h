// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SingleEntityWithNoRelationships.h instead.

#import <CoreData/CoreData.h>

extern const struct SingleEntityWithNoRelationshipsAttributes {
	__unsafe_unretained NSString *booleanAsStringTestAttribute;
	__unsafe_unretained NSString *booleanTestAttribute;
	__unsafe_unretained NSString *colorTestAttribute;
	__unsafe_unretained NSString *dateTestAttribute;
	__unsafe_unretained NSString *dateWithCustomFormat;
	__unsafe_unretained NSString *decimalTestAttribute;
	__unsafe_unretained NSString *doubleTestAttribute;
	__unsafe_unretained NSString *floatTestAttribute;
	__unsafe_unretained NSString *int16TestAttribute;
	__unsafe_unretained NSString *int32TestAttribute;
	__unsafe_unretained NSString *int64TestAttribute;
	__unsafe_unretained NSString *mappedStringAttribute;
	__unsafe_unretained NSString *notInJsonAttribute;
	__unsafe_unretained NSString *nullTestAttribute;
	__unsafe_unretained NSString *numberAsStringTestAttribute;
	__unsafe_unretained NSString *stringTestAttribute;
	__unsafe_unretained NSString *unixTime13TestAttribute;
	__unsafe_unretained NSString *unixTimeTestAttribute;
} SingleEntityWithNoRelationshipsAttributes;

@interface SingleEntityWithNoRelationshipsID : NSManagedObjectID {}
@end

@interface _SingleEntityWithNoRelationships : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SingleEntityWithNoRelationshipsID*)objectID;

@property (nonatomic, strong) NSNumber* booleanAsStringTestAttribute;

//- (BOOL)validateBooleanAsStringTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* booleanTestAttribute;

//- (BOOL)validateBooleanTestAttribute:(id*)value_ error:(NSError**)error_;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIColor *colorTestAttribute;
#else
@property (nonatomic, strong) NSColor *colorTestAttribute;
#endif

//- (BOOL)validateColorTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* dateTestAttribute;

//- (BOOL)validateDateTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* dateWithCustomFormat;

//- (BOOL)validateDateWithCustomFormat:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDecimalNumber* decimalTestAttribute;

//- (BOOL)validateDecimalTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* doubleTestAttribute;

//- (BOOL)validateDoubleTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* floatTestAttribute;

//- (BOOL)validateFloatTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* int16TestAttribute;

//- (BOOL)validateInt16TestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* int32TestAttribute;

//- (BOOL)validateInt32TestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* int64TestAttribute;

//- (BOOL)validateInt64TestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* mappedStringAttribute;

//- (BOOL)validateMappedStringAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* notInJsonAttribute;

//- (BOOL)validateNotInJsonAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSNumber* nullTestAttribute;

//- (BOOL)validateNullTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* numberAsStringTestAttribute;

//- (BOOL)validateNumberAsStringTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* stringTestAttribute;

//- (BOOL)validateStringTestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* unixTime13TestAttribute;

//- (BOOL)validateUnixTime13TestAttribute:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSDate* unixTimeTestAttribute;

//- (BOOL)validateUnixTimeTestAttribute:(id*)value_ error:(NSError**)error_;

@end

@interface _SingleEntityWithNoRelationships (CoreDataGeneratedPrimitiveAccessors)

- (NSNumber*)primitiveBooleanAsStringTestAttribute;
- (void)setPrimitiveBooleanAsStringTestAttribute:(NSNumber*)value;

- (NSNumber*)primitiveBooleanTestAttribute;
- (void)setPrimitiveBooleanTestAttribute:(NSNumber*)value;

#if TARGET_OS_IPHONE
- (UIColor *)primitiveColorTestAttribute;
- (void)setPrimitiveColorTestAttribute:(UIColor *)value;
#else
- (NSColor *)primitiveColorTestAttribute;
- (void)setPrimitiveColorTestAttribute:(NSColor *)value;
#endif

- (NSDate*)primitiveDateTestAttribute;
- (void)setPrimitiveDateTestAttribute:(NSDate*)value;

- (NSDate*)primitiveDateWithCustomFormat;
- (void)setPrimitiveDateWithCustomFormat:(NSDate*)value;

- (NSDecimalNumber*)primitiveDecimalTestAttribute;
- (void)setPrimitiveDecimalTestAttribute:(NSDecimalNumber*)value;

- (NSNumber*)primitiveDoubleTestAttribute;
- (void)setPrimitiveDoubleTestAttribute:(NSNumber*)value;

- (NSNumber*)primitiveFloatTestAttribute;
- (void)setPrimitiveFloatTestAttribute:(NSNumber*)value;

- (NSNumber*)primitiveInt16TestAttribute;
- (void)setPrimitiveInt16TestAttribute:(NSNumber*)value;

- (NSNumber*)primitiveInt32TestAttribute;
- (void)setPrimitiveInt32TestAttribute:(NSNumber*)value;

- (NSNumber*)primitiveInt64TestAttribute;
- (void)setPrimitiveInt64TestAttribute:(NSNumber*)value;

- (NSString*)primitiveMappedStringAttribute;
- (void)setPrimitiveMappedStringAttribute:(NSString*)value;

- (NSString*)primitiveNotInJsonAttribute;
- (void)setPrimitiveNotInJsonAttribute:(NSString*)value;

- (NSNumber*)primitiveNullTestAttribute;
- (void)setPrimitiveNullTestAttribute:(NSNumber*)value;

- (NSString*)primitiveNumberAsStringTestAttribute;
- (void)setPrimitiveNumberAsStringTestAttribute:(NSString*)value;

- (NSString*)primitiveStringTestAttribute;
- (void)setPrimitiveStringTestAttribute:(NSString*)value;

- (NSDate*)primitiveUnixTime13TestAttribute;
- (void)setPrimitiveUnixTime13TestAttribute:(NSDate*)value;

- (NSDate*)primitiveUnixTimeTestAttribute;
- (void)setPrimitiveUnixTimeTestAttribute:(NSDate*)value;

@end
