#import <UIKit/UIKit.h>
#import "SwrveConversationAtom.h"

@interface SwrveConversationAtomFactory : NSObject

+ (NSMutableArray<SwrveConversationAtom *> *) atomsForDictionary:(NSDictionary *)dict;

@end
