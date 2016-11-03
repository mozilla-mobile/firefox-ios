#import "SwrveInputMultiValue.h"
#import "SwrveConversationStyler.h"
#import "SwrveConversationResource.h"

@implementation SwrveInputMultiValue {
    UIView* containerView;
    UIFont* descriptionFont;
    UIFont* cellFont;
}

@synthesize values;
@synthesize description;
@synthesize selectedIndex;

-(id) initWithTag:(NSString *)tag andDictionary:(NSDictionary *)dict {
    self = [super initWithTag:tag type:kSwrveInputMultiValue andDictionary:dict];
    if(self) {
        self.description = [dict objectForKey:@"description"];
        // Get the values here
        NSArray *vals = [dict objectForKey:@"values"];
        self.values = vals;
        self.selectedIndex = -1;
        
        // init UI
        descriptionFont = [UIFont boldSystemFontOfSize:20.0];
        cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    }
    return self;
}

-(void)setSelectedIndex:(NSInteger)inx {
    selectedIndex = inx;
}

-(UITableViewCell *) cellForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (![self hasDescription] || row > 0) {
        UITableViewCell *cell = [self fetchStandardCell:tableView];
        NSUInteger finalRow = row - ([self hasDescription]? 1 : 0);
        NSDictionary *dict = [self.values objectAtIndex:finalRow];
        
        // The form for each cell in the choice is
        // {
        //    "answer_id" = "54264172-option";
        //    "answer_text" = "The text to show";
        // }
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = cellFont;
        cell.textLabel.text = [dict objectForKey:@"answer_text"];
        
        if(self.selectedIndex == (NSInteger)row) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        [SwrveConversationStyler styleView:cell withStyle:self.style];
        return [self styleCell:cell atRow:finalRow];
    } else {
        return [self fetchDescriptionCell:tableView];
    }
}

-(NSString *) userResponse {
    if(self.selectedIndex <= 0) {
        return @"";
    }
    NSUInteger inx = (NSUInteger)(self.selectedIndex - 1);
    NSDictionary *dict = [self.values objectAtIndex:inx];
    return [dict valueForKey:@"answer_id"];
}

-(void) loadViewWithContainerView:(UIView*)cw {
    containerView = cw;
    // Note: A multivalue can only be used in a table, so it doesn't load a view as such
    [[NSNotificationCenter defaultCenter] postNotificationName:kSwrveNotificationViewReady object:nil];
}

-(BOOL)hasDescription {
    return self.description != nil;
}

-(NSUInteger) numberOfRowsNeeded {
    if(self.values != ((id)[NSNull null])) {
        return self.values.count + ([self hasDescription] ? 1 : 0);
    } else {
        return 0;
    }
}

-(UITableViewCell*) styleCell:(UITableViewCell *)cell atRow:(NSUInteger) row {
    NSString *imageName;
    if (SYSTEM_VERSION_LESS_THAN(@"7.0")) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:nil];
    } else {
        if(row == 0) {
            // Potentially a top row
            if(self.values.count == 1) {
                // Its actually a top + bottom
                imageName = @"grouped_cell_single_ios7";
            } else {
                // Actually a top
                imageName = @"grouped_cell_top_ios7";
            }
        } else {
            // Not a top row
            if(row == self.values.count-1) {
                // It is a bottom row
                imageName = @"grouped_cell_bottom_ios7";
            } else {
                // Must be a mid, yo
                imageName = @"grouped_cell_mid_ios7";
            }
        }
        UIImage *img = [SwrveConversationResource imageFromBundleNamed:imageName];
        cell.backgroundView = [[UIImageView alloc] initWithImage:img];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:nil];
    }
    return cell;
}

-(CGFloat) heightForRow:(NSUInteger)row inTableView:(UITableView *)tableView {
    if (row == 0) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.description
                                                                             attributes:@{
                                                                                          NSFontAttributeName:descriptionFont
                                                                                          }];
        CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];

        return (float)ceil(rect.size.height);
    } else {
        NSUInteger finalRow = row - ([self hasDescription]? 1 : 0);
        NSDictionary *dict = [self.values objectAtIndex:finalRow];
        NSString *cellText = [dict objectForKey:@"answer_text"];
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:cellText
                                                                             attributes:@{
                                                                                          NSFontAttributeName: cellFont
                                                                                          }];
        CGRect rect = [attributedText boundingRectWithSize:CGSizeMake(tableView.bounds.size.width, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
        return (float)(ceil(rect.size.height) + 22);
    }
}

-(UITableViewCell*) fetchDescriptionCell:(UITableView*)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"descriptionCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.textLabel setFont:descriptionFont];
        cell.userInteractionEnabled = NO;
    }
    cell.textLabel.text = self.description;
    [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    cell.textLabel.numberOfLines = 0;
    [SwrveConversationStyler styleView:cell withStyle:self.style];
    return cell;
}

-(UITableViewCell*) fetchStandardCell:(UITableView*)tableView {
    NSString *cellId = [NSString stringWithFormat:@"%@CellId", self.type];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    return cell;
}

@end
