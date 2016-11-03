#include <Foundation/Foundation.h>

/*! Used internally to swizzle AppDelegate methods */
@interface SwrveSwizzleHelper : NSObject
+ (IMP) swizzleMethod:(SEL)selector inClass:(Class)c withImplementationIn:(NSObject*)newObject;
+ (void) deswizzleMethod:(SEL)selector inClass:(Class)c originalImplementation:(IMP)originalImplementation;
@end
