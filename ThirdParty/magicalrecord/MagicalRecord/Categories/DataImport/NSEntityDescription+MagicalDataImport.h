//
//  NSEntityDescription+MagicalDataImport.h
//  Magical Record
//
//  Created by Saul Mora on 9/5/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//


@interface NSEntityDescription (MagicalRecord_DataImport)

- (NSAttributeDescription *) MR_primaryAttributeToRelateBy;
- (NSManagedObject *) MR_createInstanceInContext:(NSManagedObjectContext *)context;

/**
 *	Safely returns an attribute description for the given name, otherwise returns nil. In certain circumstances, the keys of the dictionary returned by `attributesByName` are not standard NSStrings and won't match using object subscripting or standard `objectForKey:` lookups.
 *
 *  There may be performance implications to using this method if your entity has hundreds or thousands of attributes.
 *
 *	@param	name	Name of the attribute description in the `attributesByName` dictionary on this instance
 *
 *	@return	The attribute description for the given name, otherwise nil
 */
- (NSAttributeDescription *) MR_attributeDescriptionForName:(NSString *)name;

@end
