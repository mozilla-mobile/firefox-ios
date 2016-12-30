#import "SwrveConversationPane.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationAtomFactory.h"
#import "SwrveConversationButton.h"
#import "SwrveSetup.h"

@implementation SwrveConversationPane
@synthesize content = _content;
@synthesize controls = _controls;
@synthesize tag = _tag;
@synthesize title = _title;
@synthesize pageStyle = _pageStyle;
@synthesize isActive = _isActive;

-(id) initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        _tag = [dict objectForKey:@"tag"];
        _title = [dict objectForKey:@"title"];
        NSArray *contentItems = [dict objectForKey:@"content"];
        if(contentItems) {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:contentItems.count];
            for(NSDictionary *contentItemDict in contentItems) {
                if (contentItemDict != (NSDictionary*)[NSNull null]) {
                    NSMutableArray<SwrveConversationAtom*> *atoms = [SwrveConversationAtomFactory atomsForDictionary:contentItemDict];
                    if([atoms count] > 0) {
                        [arr addObjectsFromArray:atoms];
                    }
                }
                
            }
            _content = [NSArray arrayWithArray:arr];
        } else {
            _content = nil;
        }
        NSArray *controlItems = [dict objectForKey:@"controls"];
        if(controlItems) {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:controlItems.count];
            for(NSDictionary *controlItemDict in controlItems) {
                NSMutableArray<SwrveConversationAtom*> *atoms = [SwrveConversationAtomFactory atomsForDictionary:controlItemDict];
                if([atoms count] > 0){
                    // Only buttons in this dictionary so cast below should always be right.
                    SwrveConversationButton *button = (SwrveConversationButton *) [atoms firstObject];
                    if(button) {
                        [arr addObject:button];
                    }
                }
            }
            _controls = [NSArray arrayWithArray:arr];
        } else {
            _controls = nil;
        }
        NSDictionary *pagesJson = [dict objectForKey:@"style"];
        if(pagesJson) {
            _pageStyle = pagesJson;
        }
    }
    return self;
}

- (NSMutableArray <SwrveConversationAtom *> *) contentForTag:(NSString*)tag {
    NSMutableArray <SwrveConversationAtom*> *atoms = [NSMutableArray array];
    for(unsigned int i=0; i < [self.content count]; i++) {
        SwrveConversationAtom *atom = (SwrveConversationAtom*)self.content[i];
        if ([atom.tag isEqualToString:tag]) {
            [atoms addObject:atom];
        }
    }
    return atoms;
}

@end
