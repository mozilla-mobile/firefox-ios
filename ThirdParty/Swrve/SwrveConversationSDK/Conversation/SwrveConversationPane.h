#import <Foundation/Foundation.h>
#import "SwrveConversationAtom.h"

@interface SwrveConversationPane : NSObject 

@property (atomic, strong) NSArray *content;  // Array of SwrveConversationAtoms
@property (readonly, atomic, strong) NSArray *controls; // Array of SwrveConversationButtons
@property (readonly, atomic, strong) NSString *tag;
@property (readonly, atomic, strong) NSString *title;
@property (readonly, atomic, strong) NSDictionary *pageStyle;
@property (nonatomic) BOOL isActive;

- (id) initWithDictionary:(NSDictionary *)dict;
- (NSMutableArray <SwrveConversationAtom *> *) contentForTag:(NSString*)tag;
@end
