#include <Foundation/Foundation.h>

/*! Resource setup in the dashboard. A collection of attributes under a UID. */
@interface SwrveResource : NSObject

@property (atomic, retain) NSDictionary* attributes;    /*!< Resource attributes */

/*! Create a resource with given attributes.
 *
 * \param resourceAttributes Resource attributes.
 * \returns New resource instance with the given attributes.
 */
- (id) init:(NSDictionary*)resourceAttributes;

/*! Get an attribute of the resource as a string.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (NSString*) getAttributeAsString:(NSString*)attributeId withDefault:(NSString*)defaultValue;

/*! Get an attribute of the resource as an integer.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (int) getAttributeAsInt:(NSString*)attributeId withDefault:(int)defaultValue;

/*! Get an attribute of the resource as a float.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (float) getAttributeAsFloat:(NSString*)attributeId withDefault:(float)defaultValue;

/*! Get an attribute of the resource as a boolean.
 *
 * \param attributeId Attribute identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (BOOL) getAttributeAsBool:(NSString*)attributeId withDefault:(BOOL)defaultValue;

@end

/*! Offers access to the latest resources and values for this user */
@interface SwrveResourceManager : NSObject

@property (atomic, readonly) NSDictionary* resources;   /*!< List of available resources */

/*! Get all resources.
 *
 * \returns All resources in an NSDictionary.
 */
- (NSDictionary*) getResources;

/*! Get a resource identified by the given uid.
 *
 * \param resourceId Unique resource identifier.
 * \returns The resource with the given uid or nil.
 */
- (SwrveResource*) getResource:(NSString*)resourceId;

/*! Get an attribute of the resource as a string.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (NSString*) getAttributeAsString:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(NSString*)defaultValue;

/*! Get an attribute of the resource as an integer.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (int) getAttributeAsInt:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(int)defaultValue;

/*! Get an attribute of the resource as a float.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (float) getAttributeAsFloat:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(float)defaultValue;

/*! Get an attribute of the resource as a boolean.
 *
 * \param attributeId Attribute identifier.
 * \param resourceId Resource unique identifier.
 * \param defaultValue Default attribute value.
 * \returns The value of the attribute or the default value provided.
 */
- (BOOL) getAttributeAsBool:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(BOOL)defaultValue;

@end
