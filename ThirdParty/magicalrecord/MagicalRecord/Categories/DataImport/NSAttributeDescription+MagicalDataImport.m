//
//  NSAttributeDescription+MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 9/4/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSAttributeDescription+MagicalDataImport.h"
#import "NSManagedObject+MagicalDataImport.h"
#import "MagicalImportFunctions.h"

@implementation NSAttributeDescription (MagicalRecord_DataImport)

- (NSString *) MR_primaryKey;
{
    return nil;
}

- (id) MR_valueForKeyPath:(NSString *)keyPath fromObjectData:(id)objectData;
{
    id value = [objectData valueForKeyPath:keyPath];
    
    NSAttributeType attributeType = [self attributeType];
    NSString *desiredAttributeType = [[self userInfo] valueForKey:kMagicalRecordImportAttributeValueClassNameKey];
    if (desiredAttributeType) 
    {
        if ([desiredAttributeType hasSuffix:@"Color"])
        {
            value = colorFromString(value);
        }
    }
    else 
    {
        if (attributeType == NSDateAttributeType)
        {
            if (![value isKindOfClass:[NSDate class]]) 
            {
                NSString *dateFormat = [[self userInfo] valueForKey:kMagicalRecordImportCustomDateFormatKey];
                if ([value isKindOfClass:[NSNumber class]]) {
                    value = MR_dateFromNumber(value, [dateFormat isEqualToString:kMagicalRecordImportUnixTimeString]);
                }
                else {
                    value = MR_dateFromString([value description], dateFormat ?: kMagicalRecordImportDefaultDateFormatString);
                }
            }
        }
        else if (attributeType == NSInteger16AttributeType ||
                 attributeType == NSInteger32AttributeType ||
                 attributeType == NSInteger64AttributeType ||
                 attributeType == NSDecimalAttributeType ||
                 attributeType == NSDoubleAttributeType ||
                 attributeType == NSFloatAttributeType) {
            if (![value isKindOfClass:[NSNumber class]] && value != [NSNull null]) {
                value = MR_numberFromString([value description]);
            }
        }
        else if (attributeType == NSBooleanAttributeType) {
            if (![value isKindOfClass:[NSNumber class]] && value != [NSNull null]) {
            value = [NSNumber numberWithBool:[value boolValue]];
            }
        }
        else if (attributeType == NSStringAttributeType) {
            if (![value isKindOfClass:[NSString class]] && value != [NSNull null]) {
                value = [value description];
            }
        }
    }
    
    return value == [NSNull null] ? nil : value;   
}

@end
