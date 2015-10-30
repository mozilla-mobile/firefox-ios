//
//  UIImageViewAligned.m
//  awards
//
//  Created by Andrei Stanescu on 7/29/13.
//

#import "UIImageViewAligned.h"

@implementation UIImageViewAligned

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}


- (id)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self)
        [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
        [self commonInit];
    return self;
}

- (void)commonInit
{
    _enableScaleDown = TRUE;
    _enableScaleUp = TRUE;
    
    _alignment = UIImageViewAlignmentMaskCenter;
    
    _realImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _realImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _realImageView.contentMode = self.contentMode;
    [self addSubview:_realImageView];
    
    // Move any image we might have from this container to the real image view
    if (super.image != nil)
    {
        UIImage* img = super.image;
        super.image = nil;
        self.image = img;
    }
}

- (UIImage*)image
{
    return _realImageView.image;
}

- (void)setImage:(UIImage *)image
{
    [_realImageView setImage:image];
    [self setNeedsLayout];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    _realImageView.contentMode = contentMode;
    [self setNeedsLayout];
}

- (void)setAlignment:(UIImageViewAlignmentMask)alignment
{
    if (_alignment == alignment)
        return ;
    
    _alignment = alignment;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    CGSize realsize = [self realContentSize];
    
    // Start centered
    CGRect realframe = CGRectMake((self.bounds.size.width - realsize.width)/2, (self.bounds.size.height - realsize.height) / 2, realsize.width, realsize.height);
    
    if ((_alignment & UIImageViewAlignmentMaskLeft) != 0)
        realframe.origin.x = 0;
    else if ((_alignment & UIImageViewAlignmentMaskRight) != 0)
        realframe.origin.x = CGRectGetMaxX(self.bounds) - realframe.size.width;
    
    if ((_alignment & UIImageViewAlignmentMaskTop) != 0)
        realframe.origin.y = 0;
    else if ((_alignment & UIImageViewAlignmentMaskBottom) != 0)
        realframe.origin.y = CGRectGetMaxY(self.bounds) - realframe.size.height;
    
    _realImageView.frame = realframe;

    // Make sure we clear the contents of this container layer, since it refreshes from the image property once in a while.
    self.layer.contents = nil;
}

- (CGSize)realContentSize
{
    CGSize size = self.bounds.size;

    if (self.image == nil)
        return size;

    switch (self.contentMode)
    {
        case UIViewContentModeScaleAspectFit:
        {
            float scalex = self.bounds.size.width / _realImageView.image.size.width;
            float scaley = self.bounds.size.height / _realImageView.image.size.height;
            float scale = MIN(scalex, scaley);

            if ((scale > 1.0f && !_enableScaleUp) ||
                (scale < 1.0f && !_enableScaleDown))
                scale = 1.0f;
            size = CGSizeMake(_realImageView.image.size.width * scale, _realImageView.image.size.height * scale);
            break;
        }
            
        case UIViewContentModeScaleAspectFill:
        {
            float scalex = self.bounds.size.width / _realImageView.image.size.width;
            float scaley = self.bounds.size.height / _realImageView.image.size.height;
            float scale = MAX(scalex, scaley);
            
            if ((scale > 1.0f && !_enableScaleUp) ||
                (scale < 1.0f && !_enableScaleDown))
                scale = 1.0f;
            
            size = CGSizeMake(_realImageView.image.size.width * scale, _realImageView.image.size.height * scale);
            break;
        }
            
        case UIViewContentModeScaleToFill:
        {
            float scalex = self.bounds.size.width / _realImageView.image.size.width;
            float scaley = self.bounds.size.height / _realImageView.image.size.height;

            if ((scalex > 1.0f && !_enableScaleUp) ||
                (scalex < 1.0f && !_enableScaleDown))
                scalex = 1.0f;
            if ((scaley > 1.0f && !_enableScaleUp) ||
                (scaley < 1.0f && !_enableScaleDown))
                scaley = 1.0f;
            
            size = CGSizeMake(_realImageView.image.size.width * scalex, _realImageView.image.size.height * scaley);
            break;
        }

        default:
            size = _realImageView.image.size;
            break;
    }

    return size;
}


#pragma mark - UIImageView overloads

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.layer.contents = nil;
}

#pragma mark - Properties needed for Interface Builder

- (BOOL)alignLeft
{
    return (_alignment & UIImageViewAlignmentMaskLeft) != 0;
}
- (void)setAlignLeft:(BOOL)alignLeft
{
    if (alignLeft)
        self.alignment |= UIImageViewAlignmentMaskLeft;
    else
        self.alignment &= ~UIImageViewAlignmentMaskLeft;
}

- (BOOL)alignRight
{
    return (_alignment & UIImageViewAlignmentMaskRight) != 0;
}
- (void)setAlignRight:(BOOL)alignRight
{
    if (alignRight)
        self.alignment |= UIImageViewAlignmentMaskRight;
    else
        self.alignment &= ~UIImageViewAlignmentMaskRight;
}


- (BOOL)alignTop
{
    return (_alignment & UIImageViewAlignmentMaskTop) != 0;
}
- (void)setAlignTop:(BOOL)alignTop
{
    if (alignTop)
        self.alignment |= UIImageViewAlignmentMaskTop;
    else
        self.alignment &= ~UIImageViewAlignmentMaskTop;
}

- (BOOL)alignBottom
{
    return (_alignment & UIImageViewAlignmentMaskBottom) != 0;
}
- (void)setAlignBottom:(BOOL)alignBottom
{
    if (alignBottom)
        self.alignment |= UIImageViewAlignmentMaskBottom;
    else
        self.alignment &= ~UIImageViewAlignmentMaskBottom;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return [self.realImageView sizeThatFits:size];
}


@end
