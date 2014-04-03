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
    }
    return self;
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
