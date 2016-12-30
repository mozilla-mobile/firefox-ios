#import "SwrveBaseConversation.h"
#import "SwrveMessageEventHandler.h"
#import "SwrveConversationAtom.h"
#import "SwrveConversationButton.h"
#import "SwrveConversationEvents.h"
#import "SwrveConversationItemViewController.h"
#import "SwrveConversationPane.h"
#import "SwrveInputMultiValue.h"
#import "SwrveContentImage.h"
#import "SwrveSetup.h"
#import "SwrveConversationEvents.h"
#import "SwrveCommon.h"
#import "SwrveConversationStyler.h"
#import "SwrveConversationUIButton.h"

@interface SwrveConversationItemViewController() {
    NSUInteger numViewsReady;
    CGFloat keyboardOffset;
    UIDeviceOrientation currentOrientation;
    UITapGestureRecognizer *localRecognizer;
    SwrveBaseConversation *conversation;
    id<SwrveMessageEventHandler> controller;
}

@property (nonatomic) BOOL wasShownToUserNotified;

@end

@implementation SwrveConversationItemViewController

@synthesize fullScreenBackgroundImageView;
@synthesize contentTableView;
@synthesize buttonsView;
@synthesize cancelButtonView;
@synthesize conversationPane = _conversationPane;
@synthesize conversation;
@synthesize wasShownToUserNotified;
@synthesize cancelButtonViewTop;
@synthesize contentTableViewTop;
@synthesize contentHeight;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.wasShownToUserNotified == NO) {
        [self.conversation wasShownToUser];
        self.wasShownToUserNotified = YES;
    }
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Subscrite to internal notifications and orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewReady:)
                                                 name:kSwrveNotificationViewReady
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object: nil];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    self.navigationController.navigationBarHidden = YES;
    [self updateUI];
    [self.view setHidden:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom viewDidDisappear];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Unsubscribe from internal notifications and orientation changes
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kSwrveNotificationViewReady
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    // Cleanup views for all panes
    for(SwrveConversationPane* page in self.conversation.pages) {
        for(SwrveConversationAtom* contentItem in page.content) {
            [contentItem removeView];
        }
        for(SwrveConversationAtom* contentItem in page.controls) {
            [contentItem removeView];
        }
    }
}

#pragma mark ViewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    }
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGSize wholeSize = self.view.superview.bounds.size;
    
    if (wholeSize.width > SWRVE_CONVERSATION_MAX_WIDTH) {
        float centerx = ((float)wholeSize.width - SWRVE_CONVERSATION_MAX_WIDTH)/2.0f;
        CGRect newFrame = CGRectMake(centerx, SWRVE_CONVERSATION_MODAL_MARGIN, SWRVE_CONVERSATION_MAX_WIDTH, wholeSize.height - (SWRVE_CONVERSATION_MODAL_MARGIN*2));
        if (!CGRectEqualToRect(self.view.frame, newFrame)) {
            
            if(contentHeight < (wholeSize.height - SWRVE_CONVERSATION_MODAL_MARGIN)) {
                newFrame.size.height = contentHeight + SWRVE_CONVERSATION_MODAL_MARGIN;
                newFrame.origin.y =  (wholeSize.height / 2) - (newFrame.size.height / 2);
            }
            
            self.view.frame = newFrame;
            // Apply styles from conversationPane
            [SwrveConversationStyler styleModalView:self.view withStyle:self.conversationPane.pageStyle];
            self.view.layer.masksToBounds = YES;
            // Remove top margin of close button and content.
            self.contentTableViewTop.constant = 0;
            [self.contentTableView setNeedsUpdateConstraints];
            self.cancelButtonViewTop.constant = 0;
            [self.cancelButtonView setNeedsUpdateConstraints];
            [self.view setNeedsLayout];
            
        }
    } else {
        CGRect newFrame = CGRectMake(0, 0, wholeSize.width, wholeSize.height);
        if (!CGRectEqualToRect(self.view.frame, newFrame)
            || self.contentTableViewTop.constant != self.topLayoutGuide.length
            || self.cancelButtonViewTop.constant != self.topLayoutGuide.length) {
            self.view.frame = newFrame;
            // Hide border
            self.view.layer.borderWidth = 0;
            self.view.layer.cornerRadius = 0.0f;
            
            // Add top margin of close button and content
            // to take into account the status bar.
            self.contentTableViewTop.constant = self.topLayoutGuide.length;
            [self.contentTableView setNeedsUpdateConstraints];
            self.cancelButtonViewTop.constant = self.topLayoutGuide.length;
            [self.cancelButtonView setNeedsUpdateConstraints];
            [self.view setNeedsLayout];
        }
    }
}

-(SwrveConversationPane *)conversationPane {
    return _conversationPane;
}

-(void) setConversationPane:(SwrveConversationPane *)conversationPane {
    _conversationPane = conversationPane;
    numViewsReady = 0;
    [SwrveConversationEvents impression:conversation onPage:_conversationPane.tag];
    // Apply styles from conversationPane
    [SwrveConversationStyler styleModalView:self.view withStyle:conversationPane.pageStyle];
}

-(CGFloat) buttonHorizontalPadding {
    return 6.0;
}

-(void) performActions:(SwrveConversationButton *)control {
    [self performActions:control withConversationPaneTag:self.conversationPane.tag];
}

-(void) performActions:(SwrveConversationButton *)control withConversationPaneTag:(NSString *)conversationPaneTag {
    NSDictionary *actions = control.actions;
    SwrveConversationActionType actionType = SwrveVisitURLActionType;
    id param;
    
    if (actions == nil) {
        return;
    }
    
    for (NSString *key in [actions allKeys]) {
        if ([key isEqualToString:@"visit"]) {
            actionType = SwrveVisitURLActionType;
            NSDictionary *visitDict = [actions objectForKey:@"visit"];
            param = [visitDict objectForKey:@"url"];
        } else if ([key isEqualToString:@"deeplink"]) {
            actionType = SwrveDeeplinkActionType;
            NSDictionary *deeplinkDict = [actions objectForKey:@"deeplink"];
            param = [deeplinkDict objectForKey:@"url"];
        } else if ([key isEqualToString:@"call"]) {
            actionType = SwrveCallNumberActionType;
            param = [actions objectForKey:@"call"];
        } else if ([key isEqualToString:@"permission_request"]) {
            actionType = SwrvePermissionRequestActionType;
            NSDictionary *permissionDict = [actions objectForKey:@"permission_request"];
            param = [permissionDict objectForKey:@"permission"];
        } else {
            [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
        }
    }
    
    switch (actionType) {
        case SwrveCallNumberActionType: {
            [SwrveConversationEvents callNumber:conversation onPage:conversationPaneTag withControl:control.tag];
            NSURL *callUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", param]];
            [[UIApplication sharedApplication] openURL:callUrl];
            break;
        }
        case SwrveVisitURLActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                return;
            }
            
            NSURL *target = [NSURL URLWithString:param];
            if (![target scheme]) {
                target = [NSURL URLWithString:[@"http://" stringByAppendingString:param]];
            }
            
            if (![[UIApplication sharedApplication] canOpenURL:target]) {
                // The URL scheme could be an app URL scheme, but there is a chance that
                // the user doesn't have the app installed, which leads to confusing behaviour
                // Notify the user that the app isn't available and then just return.
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                DebugLog(@"Could not open the Conversation URL: %@", param, nil);
            } else {
                [SwrveConversationEvents linkVisit:conversation onPage:conversationPaneTag withControl:control.tag];
                [[UIApplication sharedApplication] openURL:target];
            }
            break;
        }
        case SwrvePermissionRequestActionType: {
            // Ask for the configured permission
            if(![[SwrveCommon sharedInstance] processPermissionRequest:param]) {
                DebugLog(@"Unknown permission request %@", param, nil);
            } else {
                [SwrveConversationEvents permissionRequest:conversation onPage:conversationPaneTag withControl:control.tag];
            }
            break;
        }
        case SwrveDeeplinkActionType: {
            if (!param) {
                [SwrveConversationEvents error:conversation onPage:conversationPaneTag withControl:control.tag];
                return;
            }
            NSURL *target = [NSURL URLWithString:param];
            [SwrveConversationEvents deeplinkVisit:conversation onPage:conversationPaneTag withControl:control.tag];
            [[UIApplication sharedApplication] openURL:target];
        }
        default:
            break;
    }
}

- (IBAction)cancelButtonTapped:(id)sender {
#pragma unused(sender)
    [SwrveConversationEvents cancel:conversation onPage:self.conversationPane.tag];
    // Send queued user input events
    [SwrveConversationEvents gatherAndSendUserInputs:self.conversationPane forConversation:conversation];
    [self dismiss];
}

-(void) buttonTapped:(id)sender {
    SwrveConversationButton *control = [self mapButtonToControl:(UIButton*)sender];
    [self transitionWithControl:control];
}

-(SwrveConversationButton*)mapButtonToControl:(UIButton*)button {
    // The sender is tagged with its index in the list of controls in the
    // conversation pane. Use this to lift the tag associated with the control
    // to populate the finished conversation event.
    NSUInteger tag = (NSUInteger)button.tag;
    return self.conversationPane.controls[(NSUInteger)tag];
}

-(BOOL)transitionWithControl:(SwrveConversationButton *)control {
    // Things that are 'running' need to be 'stopped'
    // Bit of a band-aid for videos continuing to play in the background for now.
    [self stopAtoms];
    
    // Issue events for data from the user
    [SwrveConversationEvents gatherAndSendUserInputs:self.conversationPane forConversation:conversation];
    
    // Move onto the next page in the conversation - fetch the next Convseration pane
    if ([control endsConversation]) {
        [SwrveConversationEvents done:conversation onPage:self.conversationPane.tag withControl:control.tag];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self dismiss];
        });
    } else {
        SwrveConversationPane *nextPage = [conversation pageForTag:control.target];
        [SwrveConversationEvents pageTransition:conversation fromPage:self.conversationPane.tag toPage:nextPage.tag withControl:control.tag];
        
        self.conversationPane = nextPage;
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self updateUI];
        });
    }
    
    [self runControlActions:control onPage:self.conversationPane.tag];
    return YES;
}

-(void)stopAtoms {
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom stop];
    }
}

-(void)dismiss {
    // Stop videos etc
    [self stopAtoms];
    // Close the view controller
    self.conversationPane.isActive = NO;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        @synchronized(self->controller) {
            // Delay for .01ms to account for killing the conversation stuff (iOS6) 
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (u_int64_t)0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self->controller conversationClosed];
            });
        }
    }];
}

-(void)runControlActions:(SwrveConversationButton*)control onPage:(NSString *)tag{
    if (control.actions != nil) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self performActions:control withConversationPaneTag:tag];
        });
    }
}

-(void) viewReady:(NSNotification *)notification {
#pragma unused (notification)
    numViewsReady++;
    if(numViewsReady == self.conversationPane.content.count) {
        contentHeight = 0; //reset the contentHeight before we reload
        
        for(SwrveConversationAtom *atom in self.conversationPane.content) {
            
            if([atom.type isEqualToString:kSwrveInputMultiValue]) {
                SwrveInputMultiValue *multValue = (SwrveInputMultiValue *)atom;
                
                for(uint i = 0; i < (uint)[multValue.values count]; i++){
                    contentHeight += (float)[multValue heightForRow:(uint)i inTableView:self.contentTableView];
                }
                
            }else if([atom.type isEqualToString:kSwrveContentTypeImage]) {
                SwrveContentImage *imageAtom = (SwrveContentImage *)atom;
                contentHeight += (float)imageAtom.view.frame.size.height;
                
            }else{
                contentHeight += (float)atom.view.frame.size.height;
            }
        }
        
        for (SwrveConversationAtom *atom in self.conversationPane.controls) {
            contentHeight +=(float)atom.view.frame.size.height + SWRVE_CONVERSATION_MODAL_MARGIN;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
            [self viewWillLayoutSubviews];
            self.conversationPane.isActive = YES;
            self.view.hidden = NO;
        });
    }
}

-(void) updateUI {
    self.navigationItem.title = self.conversationPane.title;
    [SwrveConversationStyler styleView:fullScreenBackgroundImageView withStyle:self.conversationPane.pageStyle];
    self.contentTableView.backgroundColor = [UIColor clearColor];
    
    // In the case where a pane is scrolled, then the user moves on to the next
    // pane, that second pane will display as scrolled too, unless we reset the
    // tableview to the top of the content stack.
    [self.contentTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    self.contentTableView.separatorColor = [UIColor clearColor];
    
    NSArray *contentToAdd = self.conversationPane.content;
    for (SwrveConversationAtom *atom in contentToAdd) {
        [atom loadViewWithContainerView:self.view];
    }
    
    // Remove current buttons
    for (UIView *view in buttonsView.subviews) {
        [view removeFromSuperview];
    }
    
    NSArray *buttons = self.conversationPane.controls;
    // Buttons need to fit into width - 2*button padding
    // When there are n buttons, there are n-1 gaps between them
    // So, the buttons each take up (width-(n+1)*gapwidth)/numbuttons
    CGFloat buttonWidth = (buttonsView.frame.size.width-(buttons.count+1)*[self buttonHorizontalPadding])/buttons.count;
    CGFloat xOffset = [self buttonHorizontalPadding];
    for(NSUInteger i = 0; i < buttons.count; i++) {
        SwrveConversationButton *button = [buttons objectAtIndex:i];
        UIButton *buttonUIView = (UIButton*)button.view;
        buttonUIView.frame = CGRectMake(xOffset, 10, buttonWidth, 45.0);
        buttonUIView.tag = (NSInteger)i;
        buttonUIView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [buttonUIView.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [buttonUIView.titleLabel setNumberOfLines:1];
        [buttonUIView addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [SwrveConversationStyler styleButton:(SwrveConversationUIButton *)buttonUIView withStyle:button.style];
        [buttonsView addSubview:buttonUIView];
        xOffset += buttonWidth + [self buttonHorizontalPadding];
    }
}

#pragma mark - Rotation

// Rotation for iOS < 6
#if defined(__IPHONE_9_0)
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
#else
-(NSUInteger) supportedInterfaceOrientations {
#endif //defined(__IPHONE_9_0)
    return UIInterfaceOrientationMaskAll;
}
    
// Orientation Detection
- (void)deviceOrientationDidChange:(NSNotification *)notification {
#pragma unused (notification)
    
    // Do nothing unless conversationPane is Active
    if(self.conversationPane.isActive) {
        // Obtaining the current device orientation
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        // Ignoring specific orientations or if hasn't actually changed
        if (orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown || orientation == UIDeviceOrientationUnknown || currentOrientation == orientation) {
            return;
        }
        
        currentOrientation = orientation;
        // Delay for .01ms to account for rotation frame returned being out of date
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (u_int64_t)0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            // Tell everyone who needs to know that orientation has changed, individual items will react to this and change shape
            for(SwrveConversationAtom *atom in self.conversationPane.content) {
                if([atom.delegate respondsToSelector:@selector(respondToDeviceOrientationChange:)]) {
                    [atom.delegate respondToDeviceOrientationChange:orientation];
                }
            }
        });
    }
}
    
-(void)setConversation:(SwrveBaseConversation*)conv andMessageController:(id<SwrveMessageEventHandler>)ctrl
{
    conversation = conv;
    controller = ctrl;
    // The conversation is starting now, so issue a starting event
    SwrveConversationPane *firstPage = [conversation pageAtIndex:0];
    [SwrveConversationEvents started:conversation onStartPage:firstPage.tag];
    // Assigment will issue an impression event
    self.conversationPane = firstPage;
}

// Tapping the content view outside the context of any
// interactive input views requests the current first
// responder to relinquish its status. Gesture recognizer
// is then removed.
- (void)contentViewTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded)     {
        for(SwrveConversationAtom *atom in self.conversationPane.content) {
            if([atom isKindOfClass:[SwrveInputItem class]]) {
                if([(SwrveInputItem *)atom isFirstResponder]) {
                    [(SwrveInputItem *)atom resignFirstResponder];
                    [self.contentTableView removeGestureRecognizer:sender];
                    return;
                }
            }
        }
    }
}
    
-(NSIndexPath *) indexPathForAtom:(SwrveConversationAtom *)atom {
    for(NSUInteger i = 0; i < self.conversationPane.content.count; i++) {
        if(atom == [self.conversationPane.content objectAtIndex:i]) {
            return [NSIndexPath indexPathForRow:0 inSection:(NSInteger)i];
        }
    }
    return nil;
}

-(UIView*) findTopView {
    // This navigates up to the Application. Different stuff for
    // phones and iPads though.
    UIView *v = self.view;
    while (v.superview) {
        v = v.superview;
    }
    return v;
}
    
#pragma mark TableViewDelegate Methods
    
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#pragma unused (tableView)
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)section];
    return (NSInteger)[atom numberOfRowsNeeded];
}
    
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger objectIndex = [self objectIndexFromIndexPath:indexPath]; // HACK
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:objectIndex];
    return [atom cellForRow:(NSUInteger)indexPath.row inTableView:tableView];
}
    
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#pragma unused (tableView)
    // Each item is a "section"
    return (NSInteger)self.conversationPane.content.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
#pragma unused (tableView)
    NSUInteger objectIndex = [self objectIndexFromIndexPath:indexPath];
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:objectIndex];
    return [atom heightForRow:(NSUInteger)indexPath.row inTableView:tableView];
}
    
- (NSUInteger) objectIndexFromIndexPath:(NSIndexPath *)indexPath {
    NSUInteger checkedIndexPath = (NSUInteger)indexPath.section;
    NSUInteger paneCount = [self.conversationPane.content count];
    if(checkedIndexPath >= paneCount) {
        checkedIndexPath = paneCount - 1;
    }
    return checkedIndexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SwrveConversationAtom *atom = [self.conversationPane.content objectAtIndex:(NSUInteger)indexPath.section];
    if([atom.type isEqualToString:kSwrveInputMultiValue]) {
        SwrveInputMultiValue *vgInputMultiValue = (SwrveInputMultiValue *)atom;
        vgInputMultiValue.selectedIndex = indexPath.row;
        // Redraw the section, as we may have switched another off
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:(NSUInteger)indexPath.section];
        [tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#if defined(__IPHONE_8_0)
- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    for(SwrveConversationAtom *atom in self.conversationPane.content) {
        [atom viewWillTransitionToSize:self.view.frame.size];
    }
}
#endif //defined(__IPHONE_8_0)
    
@end
