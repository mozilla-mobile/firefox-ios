#import <UIKit/UIKit.h>
#import "SwrveMessageEventHandler.h"

@class SwrveConversationResource;
@class SwrveConversationPane;
@class SwrveConversationItemViewController;
@class SwrveBaseConversation;
@class SwrveConversationButton;

typedef enum {
    SwrveCallNumberActionType,
    SwrveVisitURLActionType,
    SwrveDeeplinkActionType,
    SwrvePermissionRequestActionType
} SwrveConversationActionType;

@interface SwrveConversationItemViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    SwrveConversationPane *_conversationPane;
    SwrveConversationResource *_engine;
}

@property (strong, nonatomic) IBOutlet UIImageView *fullScreenBackgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *contentTableView;
@property (strong, nonatomic) IBOutlet UIButton *cancelButtonView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cancelButtonViewTop;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentTableViewTop;

@property (unsafe_unretained, nonatomic) IBOutlet UIView *buttonsView;
@property (strong, nonatomic) SwrveBaseConversation *conversation;
@property (strong, nonatomic) SwrveConversationPane *conversationPane;
@property (readwrite, nonatomic) float contentHeight;

-(void)setConversation:(SwrveBaseConversation*)conversation andMessageController:(id<SwrveMessageEventHandler>)controller;
-(BOOL)transitionWithControl:(SwrveConversationButton *)control;

-(IBAction)cancelButtonTapped:(id)sender;
-(void)updateUI;
-(void)dismiss;
@end
