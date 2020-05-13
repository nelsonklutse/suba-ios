//
//  SearchBarCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/20/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "SearchBarCell.h"

@implementation SearchBarCell

-(id)init
{
    self = [super init];
    
    if (self) {
        // Initialization code
        //self.searchBar.showsCancelButton = YES;
        DLog(@"Showing search bar");
        
        for (UIView *view in self.searchBar.subviews)
        {
            for (id subview in view.subviews)
            {
                if ( [subview isKindOfClass:[UIButton class]] )
                {
                    // customize cancel button
                    UIButton* cancelBtn = (UIButton*)subview;
                    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateHighlighted];
                    //[cancelBtn setEnabled:YES];
                    break;
                }
            }
        }
    }
    return self;

}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        //self.searchBar.showsCancelButton = YES;
        //DLog(@"Showing search bar");
        
        for (UIView *view in self.searchBar.subviews)
        {
            for (id subview in view.subviews)
            {
                if ( [subview isKindOfClass:[UIButton class]] )
                {
                    // customize cancel button
                    UIButton* cancelBtn = (UIButton*)subview;
                    [cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal | UIControlStateHighlighted];
                    //[cancelBtn setEnabled:YES];
                    break;
                }
            }
        }
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
