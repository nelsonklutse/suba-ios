//
//  NearbyStreamsHeaderView.m
//  LifeSpot
//
//  Created by Kwame Nelson on 5/29/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "NearbyStreamsHeaderView.h"

@implementation NearbyStreamsHeaderView

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



#pragma mark - General Helpers
- (void)makeInitialPlaceholderViewWithSize:(NSInteger)labelSize view:(UIView *)contextView name:(NSString *)person
{
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:labelSize];
    
    UILabel *initialsLabel = [[UILabel alloc] initWithFrame:contextView.bounds];
    initialsLabel.textAlignment = NSTextAlignmentCenter;
    initialsLabel.textColor = [UIColor whiteColor];
    initialsLabel.font = font;
    initialsLabel.text = [[self initialStringForPersonString:person] uppercaseString];
    contextView.backgroundColor = [self circleColor];
    contextView.layer.cornerRadius = 45.0f;
    contextView.layer.borderColor = [UIColor whiteColor].CGColor;
    contextView.layer.borderWidth = 2.0f;
    contextView.clipsToBounds = YES;
    [contextView addSubview:initialsLabel];
}

- (UIColor *)circleColor
{
    UIColor *color = [UIColor colorWithRed:(217.0f/255.0f)
                                               green:(77.0f/255.0f)
                                                blue:(20.0f/255.0f)
                                               alpha:1];
    return color;
}

- (NSString *)initialStringForPersonString:(NSString *)personString
{
    NSString *initials = nil;
    NSArray *comps = [personString componentsSeparatedByString:kEMPTY_STRING_WITH_SPACE];
    NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
    
    for (NSString *component in mutableComps) {
        if ([component isEqualToString:kEMPTY_STRING_WITH_SPACE]) {
            [mutableComps removeObject:component];
        }
    }
    
    if ([mutableComps count] >= 2) {
        NSString *firstName = mutableComps[0];
        NSString *lastName = mutableComps[1];
        
        initials =  [NSString stringWithFormat:@"%@%@", [firstName substringToIndex:1], [lastName substringToIndex:1]];
    } else if ([mutableComps count]) {
        NSString *name = mutableComps[0];
        initials =  [name substringToIndex:1];
    }
    
    return initials;
}


- (void)fillView:(UIView *)view WithImage:(NSString *)imageURL
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


@end
