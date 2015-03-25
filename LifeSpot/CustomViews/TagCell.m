//
//  TagCell.m
//  Suba
//
//  Created by Kwame Nelson on 3/18/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import "TagCell.h"
#import "S3PhotoFetcher.h"

@implementation TagCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


-(void)fillView:(UIView *)view WithImageURL:(NSString *)imageURL placeholder:(UIImage *)image
{
    [[view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if ([imageURL class] != [NSNull class] && ![imageURL isEqualToString:@"-1"]) {
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:image];
    }else{
        imageView.image = image;
    }
    
    view.backgroundColor = [UIColor clearColor];
    
    [view addSubview:imageView];
    
    
}



- (void)fillView:(UIView *)view WithImage:(UIImage *)realImage
{
    [[view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    imageView.image = realImage;
    
    view.backgroundColor = [UIColor clearColor];
    
    [view addSubview:imageView];
    
}



- (NSString *)initialStringForPersonString:(NSString *)personString {
    NSString *initials = nil;
    
    @try {
        if (![personString isKindOfClass:[NSNull class]]) {
            
            NSArray *comps = [personString componentsSeparatedByString:k_SEPARATOR_CHARACTER];
            NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
            
            for (NSString *component in mutableComps){
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
        
        frame = CGRectMake(contextView.bounds.origin.x+(contextView.bounds.size.width/2)-11, contextView.bounds.origin.y, contextView.bounds.size.width, contextView.bounds.size.height);
    }
    
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
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


@end
