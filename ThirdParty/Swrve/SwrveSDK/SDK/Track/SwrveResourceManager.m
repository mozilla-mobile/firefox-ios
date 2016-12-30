#import "SwrveResourceManager.h"

/*
 * SwrveResource: A collection of attributes
 */
@implementation SwrveResource

@synthesize attributes;

- (id) init:(NSDictionary*)resourceAttributes
{
    if (self = [super init]) {
        self.attributes = resourceAttributes;
    }
    return self;
}

- (NSString*) getAttributeAsString:(NSString*)attributeId withDefault:(NSString*)defaultValue
{
    NSString* attribute = [[self attributes] objectForKey:attributeId];
    if (attribute != nil) {
        return attribute;
    }
    return defaultValue;
}

- (int) getAttributeAsInt:(NSString*)attributeId withDefault:(int)defaultValue
{
    NSString* attribute = [[self attributes] objectForKey:attributeId];
    if (attribute != nil) {
        return attribute.intValue;
    }
    return defaultValue;
}

- (float) getAttributeAsFloat:(NSString*)attributeId withDefault:(float)defaultValue
{
    NSString* attribute = [[self attributes] objectForKey:attributeId];
    if (attribute != nil) {
        return attribute.floatValue;
    }
    return defaultValue;
}

- (BOOL) getAttributeAsBool:(NSString*)attributeId withDefault:(BOOL)defaultValue
{
    NSString* attribute = [[self attributes] objectForKey:attributeId];
    if (attribute != nil) {
        return (([attribute caseInsensitiveCompare:@"true"] == NSOrderedSame) || ([attribute caseInsensitiveCompare:@"yes"] == NSOrderedSame));
    }
    return defaultValue;
}

@end



@implementation SwrveResourceManager

@synthesize resources;

- (id) init
{
    if (self = [super init]) {
        resources = [[NSDictionary alloc] init];
    }
    return self;
}

- (void)setResourcesFromArray:(NSArray*)resourcesArray
{
    NSMutableDictionary* resourcesDict = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary* obj in resourcesArray) {
        NSString* itemName = [obj objectForKey:@"uid"];
        [resourcesDict setObject:obj forKey:itemName];
    }
    
    resources = resourcesDict;
}

- (NSDictionary*) getResources
{
    return resources;
}

- (SwrveResource*) getResource:(NSString*)resourceId
{
    NSDictionary* resourceDict = [[self resources] objectForKey:resourceId];
    if (resourceDict != nil) {
        return [[SwrveResource alloc] init:resourceDict];
    }
    return nil;
}

- (NSString*) getAttributeAsString:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(NSString*)defaultValue
{
    SwrveResource* resource = [self getResource:resourceId];
    if (resource != nil) {
        return [resource getAttributeAsString:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (int) getAttributeAsInt:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(int)defaultValue
{
    SwrveResource* resource = [self getResource:resourceId];
    if (resource != nil) {
        return [resource getAttributeAsInt:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (float) getAttributeAsFloat:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(float)defaultValue
{
    SwrveResource* resource = [self getResource:resourceId];
    if (resource != nil) {
        return [resource getAttributeAsFloat:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

- (BOOL) getAttributeAsBool:(NSString*)attributeId ofResource:(NSString*)resourceId withDefault:(BOOL)defaultValue
{
    SwrveResource* resource = [self getResource:resourceId];
    if (resource != nil) {
        return [resource getAttributeAsBool:attributeId withDefault:defaultValue];
    }
    return defaultValue;
}

@end
