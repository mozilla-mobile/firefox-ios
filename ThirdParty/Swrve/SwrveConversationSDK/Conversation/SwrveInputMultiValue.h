#import "SwrveInputItem.h"

@interface SwrveInputMultiValue : SwrveInputItem

@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) NSInteger selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict;
-(void) loadViewWithContainerView:(UIView*)containerView;
-(BOOL) hasDescription;
-(NSUInteger) numberOfRowsNeeded;
-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView;

-(UITableViewCell*) fetchDescriptionCell:(UITableView*)tableView;
-(UITableViewCell*) fetchStandardCell:(UITableView*)tableView;
-(UITableViewCell*) styleCell:(UITableViewCell *)cell atRow:(NSUInteger)row;

@end
