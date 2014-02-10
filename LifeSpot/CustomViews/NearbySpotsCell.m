//
//  NearbySpotsCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 2/7/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "NearbySpotsCell.h"
#import "InfinitePagingView.h"

@interface NearbySpotsCell()

@property (strong,nonatomic) NSArray *galleryImages;

@end


@implementation NearbySpotsCell

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



-(void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath
{
    //CGFloat naviBarHeight = self.navigationController.navigationBar.frame.size.height;
    
    //self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    // pagingView
    InfinitePagingView *pagingView = [[InfinitePagingView alloc] initWithFrame:CGRectMake(0.f, 0.f, 320, 200.f)];
    pagingView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blurBg"]];
    pagingView.pageSize = CGSizeMake(120.f, 200);
    //[self.view addSubview:pagingView];
    
    for (NSUInteger i = 1; i <= 15; ++i) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.JPG", i]];
        UIImageView *page = [[UIImageView alloc] initWithImage:image];
        page.frame = CGRectMake(0.f, 0.f, 100.f, pagingView.frame.size.height);
        page.contentMode = UIViewContentModeScaleAspectFit;
        [pagingView addPageView:page];
    }
  
}

@end
