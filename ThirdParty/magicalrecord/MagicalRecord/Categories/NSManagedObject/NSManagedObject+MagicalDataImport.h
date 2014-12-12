//
//  NSManagedObject+JSONHelpers.h
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString * const kMagicalRecordImportCustomDateFormatKey;
extern NSString * const kMagicalRecordImportDefaultDateFormatString;
extern NSString * const kMagicalRecordImportUnixTimeString;
extern NSString * const kMagicalRecordImportAttributeKeyMapKey;
extern NSString * const kMagicalRecordImportAttributeValueClassNameKey;

extern NSString * const kMagicalRecordImportRelationshipMapKey;
extern NSString * const kMagicalRecordImportRelationshipLinkedByKey;
extern NSString * const kMagicalRecordImportRelationshipTypeKey;

@protocol MagicalRecordDataImportProtocol <NSObject>

@optional
- (BOOL) shouldImport:(id)data;
- (void) willImport:(id)data;
- (void) didImport:(id)data;

@end

@interface NSManagedObject (MagicalRecord_DataImport) <MagicalRecordDataImportProtocol>

- (BOOL) MR_importValuesForKeysWithObject:(id)objectData;

+ (instancetype) MR_importFromObject:(id)data;
+ (instancetype) MR_importFromObject:(id)data inContext:(NSManagedObjectContext *)context;

+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData;
+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context;

@end
