//
//  PhotoStreamCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PhotoStreamCell.h"

@interface PhotoStreamCell()
// Will help with animating the like button
@property (nonatomic, readwrite) CGRect likeButtonBounds;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@end

@implementation PhotoStreamCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        DLog();
    }
    return self;
}

-(void)setBorderAroundView:(UIView *)view
{
    view.clipsToBounds = YES;
    view.layer.borderWidth = 0.5;
    view.layer.borderColor = [UIColor lightGrayColor].CGColor;
    view.layer.cornerRadius = 1;
}


-(void)makeInitialPlaceholderView:(UIView *)contextView name:(NSString *)person
{
    [[contextView subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectZero;
    NSString *initials = [[self initialStringForPersonString:person] uppercaseString];
    NSUInteger numberOfCharacters = initials.length;
    
    if (numberOfCharacters == 1){
        
        frame = CGRectMake(contextView.bounds.origin.x+(contextView.bounds.size.width/2)-5, contextView.bounds.origin.y, contextView.bounds.size.width, contextView.bounds.size.height);
    }else if (numberOfCharacters == 2){
        
        frame = CGRectMake(contextView.bounds.origin.x+(contextView.bounds.size.width/2)-10, contextView.bounds.origin.y, contextView.bounds.size.width, contextView.bounds.size.height);
    }
    
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    
    UILabel *initialsLabel = [[UILabel alloc] initWithFrame:frame];
    initialsLabel.textColor = [UIColor whiteColor];
    initialsLabel.font = font;
    initialsLabel.text = initials;
    contextView.backgroundColor = [self circleColor];
    
    [contextView addSubview:initialsLabel];
    
}


- (UIColor *)circleColor {
    return [UIColor colorWithHue:arc4random() % 256 / 256.0 saturation:0.5 brightness:0.8 alpha:1.0];
}

- (NSString *)initialStringForPersonString:(NSString *)personString {
    NSString *initials = nil;
    @try {
        if (![personString isKindOfClass:[NSNull class]]) {
            
            NSArray *comps = [personString componentsSeparatedByString:k_SEPARATOR_CHARACTER];
            NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
            
            for (NSString *component in mutableComps) {
                if ([component isEqualToString:kEMPTY_STRING_WITH_SPACE]
                    || [component isEqualToString:kEMPTY_STRING_WITHOUT_SPACE]){
                    
                    [mutableComps removeObject:component];
                }
            }
            
            if ([mutableComps count] >= 2) {
                NSString *firstName = mutableComps[0];
                NSString *lastName = mutableComps[1];
                
                initials =  [NSString stringWithFormat:@"%@%@", [firstName substringToIndex:1], [lastName substringToIndex:1]];
            } else if ([mutableComps count] == 1) {
                NSString *name = mutableComps[0];
                initials =  [name substringToIndex:1];
            }
        }
        
    }@catch (NSException *exception) {}
    @finally {}
    
    return initials;
}

-(void)fillView:(UIView *)view WithImage:(NSString *)imageURL
{
    [[view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    
    view.backgroundColor = [UIColor clearColor];
    
    [view addSubview:imageView];
    
    
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


/*-(void)bounceLikeButton
{
    
    // Reset the buttons bounds to their initial state.  See the comment in
    ((UIButton *)self.likePhotoButton).bounds = self.likeButtonBounds;
    DLog(@"Bouncing -%@",NSStringFromCGRect(((UIButton *)self.likePhotoButton).bounds));
    // UIDynamicAnimator instances are relatively cheap to create.
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.contentView];
    
    // APLPositionToBoundsMapping maps the center of an id<ResizableDynamicItem>
    // (UIDynamicItem with mutable bounds) to its bounds.  As dynamics modifies
    // the center.x, the changes are forwarded to the bounds.size.width.
    // Similarly, as dynamics modifies the center.y, the changes are forwarded
    // to bounds.size.height.
    APLPositionToBoundsMapping *buttonBoundsDynamicItem = [[APLPositionToBoundsMapping alloc] initWithTarget:self.likePhotoButton];
    
    // Create an attachment between the buttonBoundsDynamicItem and the initial
    // value of the button's bounds.
    UIAttachmentBehavior *attachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:buttonBoundsDynamicItem attachedToAnchor:buttonBoundsDynamicItem.center];
    [attachmentBehavior setFrequency:2.0];
    [attachmentBehavior setDamping:0.3];
    [animator addBehavior:attachmentBehavior];
    
    UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[buttonBoundsDynamicItem] mode:UIPushBehaviorModeInstantaneous];
    pushBehavior.angle = M_PI_4;
    pushBehavior.magnitude = 2.0;
    [animator addBehavior:pushBehavior];
    
    [pushBehavior setActive:TRUE];

    self.animator = animator;
  
}

-(void)saveInitialBounds
{
    self.likeButtonBounds = ((UIButton *)self.likePhotoButton).bounds;
    DLog(@"Bouncing -%@",NSStringFromCGRect(((UIButton *)self.likePhotoButton).bounds));
    // Force the button image to scale with its bounds.
    ((UIButton *)self.likePhotoButton).contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    
    ((UIButton *)self.likePhotoButton).contentVerticalAlignment = UIControlContentHorizontalAlignmentFill;
    
}*/



@end
