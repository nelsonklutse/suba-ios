//
//  Photos.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/20/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PhotosCell.h"
#import "DACircularProgressView.h"
#import "S3PhotoFetcher.h"

@interface PhotosCell()<UIPhotoGalleryDataSource,UIPhotoGalleryDelegate>

@property (strong,nonatomic) NSDictionary *gImages;

@end

@implementation PhotosCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


#pragma UIPhotoGalleryDataSource methods
- (NSInteger)numberOfViewsInPhotoGallery:(UIPhotoGalleryView *)photoGallery {
   // DLog(@"Number of images in gallery is %i",[self.gImages[@"images"] count]);
    return [self.gImages[@"images"] count];
}


- (NSURL*)photoGallery:(UIPhotoGalleryView *)photoGallery remoteImageURLAtIndex:(NSInteger)index {
    NSString *imageURL = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,self.gImages[@"images"][index]];
    //DLog(@"Setting Image at src=%@",imageURL);
    return [NSURL URLWithString:imageURL];
}


-(UIView *)photoGallery:(UIPhotoGalleryView *)photoGallery customViewAtIndex:(NSInteger)index
{
    
    UIImageView *page = [[UIImageView alloc] init];
    NSUInteger photos = [self.gImages[@"images"] count];
    
    if (photos == 1) {
        page.frame = CGRectMake(0, 0, photoGallery.frame.size.width, photoGallery.frame.size.height);
    }else{
        page.frame = CGRectMake(0, 0, photoGallery.frame.size.width, photoGallery.frame.size.height);
    }
    page.contentMode = UIViewContentModeScaleAspectFill;
    //DLog(@"PhotoGallery frame - %@\nPhotoGallery subview gap - %f\nImage frame - %@",NSStringFromCGRect(photoGallery.frame),photoGallery.subviewGap,NSStringFromCGRect(page.frame));
    
    //page.backgroundColor = [UIColor yellowColor];
    NSString *imageURL = self.gImages[@"images"][index];
    
   //DLog(@"Image URL - %@",imageURL);
    DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                            initWithFrame:CGRectMake((page.bounds.size.width/2) - 20, (page.bounds.size.height/2) - 20, 40.0f, 40.0f)];
    progressView.thicknessRatio = .1f;
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor colorWithRed:0.850f green:0.301f blue:0.078f alpha:1];
    [page addSubview:progressView];
    
    [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:imageURL to:page placeholderImage:[UIImage imageNamed:@"blurBg"] progressView:progressView completion:^(id results, NSError *error) {
        //DLog(@"IMAGE DOWNLOADED");
        //page.image = (UIImage *)results;
        [progressView removeFromSuperview];
    }];
    
    return page;
}




#pragma UIPhotoGalleryDelegate methods
- (void)photoGallery:(UIPhotoGalleryView *)photoGallery didTapAtIndex:(NSInteger)index {
    //self.galleryIndex = index;
    //NSMutableArray
  
        //DLog(@"Index Tapped - %i",index);
        /*NSRange rangeForFirstArray = NSMakeRange(index, [self.gImages count] - index);
        NSRange rangeSecondArray = NSMakeRange(0, index);
        NSArray *firstArray = [self.gImages subarrayWithRange:rangeForFirstArray];
        NSArray *secondArray = [self.gImages subarrayWithRange:rangeSecondArray];
        
        self.gImages = [firstArray arrayByAddingObjectsFromArray:secondArray];*/
    
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kPhotoCellTappedAtIndexNotification
     object:nil userInfo:@{@"photoIndex": @(index),@"photoURLs" : self.gImages}];
    
}




#pragma mark - Class Helpers
- (void)prepareForGallery:(NSDictionary *)photosData index:(NSIndexPath *)indexPath
{
    //NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    //NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    //NSArray *sortedPhotos = [allSpots sortedArrayUsingDescriptors:sortDescriptors];
    self.gImages = photosData;
    
    //DLog(@"gImages - %@",[allSpots debugDescription]);
    
    //self.galleryIndex = indexPath.row;
    DLog(@"self.photoGalleryView.frame - %@",NSStringFromCGRect(self.photoGalleryView.frame));
    if ([self.gImages[@"images"] count] == 1) {
         self.photoGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        self.photoGallery.initialIndex = 0;
        //DLog(@"Set photo gallery initial index to %i",self.photoGallery.initialIndex);
    }else{
       self.photoGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(20, 0, 280,self.photoGalleryView.frame.size.height)];
        
}
    
    
    self.photoGallery.dataSource = self;
    self.photoGallery.delegate = self;
    
    self.photoGallery.galleryMode = UIPhotoGalleryModeCustomView;
    self.photoGallery.verticalGallery = _photoGallery.peakSubView = NO;
    
    self.photoGallery.showsScrollIndicator = NO;
    [self.photoGallery setSubviewGap:5];
    self.photoGalleryView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blurBg"]];
    //self.photoGallery.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blurBg"]];
    
    if ([self.gImages count] > 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100000), dispatch_get_main_queue(), ^{
            if (self.photoGallery.initialIndex != 1) {
                [self.photoGallery setInitialIndex:1 animated:NO];
            }
            
        });
    }
}


@end
