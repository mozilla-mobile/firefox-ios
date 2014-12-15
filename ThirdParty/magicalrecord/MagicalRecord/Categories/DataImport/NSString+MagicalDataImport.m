//
//  NSString+MagicalRecord_MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 12/10/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSString+MagicalDataImport.h"


@implementation NSString (MagicalRecord_DataImport)

- (NSString *) MR_capitalizedFirstCharacterString;
{
    if ([self length] > 0)
    {
        NSString *firstChar = [[self substringToIndex:1] capitalizedString];
        return [firstChar stringByAppendingString:[self substringFromIndex:1]];
    }
    return self;
}

- (id) MR_relatedValueForRelationship:(NSRelationshipDescription *)relationshipInfo
{
    return self;
}

- (NSString *) MR_lookupKeyForAttribute:(NSAttributeDescription *)attributeInfo
{
    return nil;
}

@end

