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

@interface PhotosCell()

@property (strong,nonatomic) NSArray *gImages;
@property (strong,nonatomic) NSMutableDictionary *spotInfo;
@property NSUInteger galleryIndex;

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


/*#pragma UIPhotoGalleryDataSource methods
- (NSInteger)numberOfViewsInPhotoGallery:(UIPhotoGalleryView *)photoGallery {
    if ([self.gImages count] >= 3) {
        return 3;
    }
    
    return [self.gImages count];
}


- (NSURL*)photoGallery:(UIPhotoGalleryView *)photoGallery remoteImageURLAtIndex:(NSInteger)index {
    NSString *imageURL = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,self.gImages[index][@"s3name"]];
    //DLog(@"Image URL being sent is %@ for index %li",imageURL,(long)index);
    
    return [NSURL URLWithString:imageURL];
}


-(UIView *)photoGallery:(UIPhotoGalleryView *)photoGallery customViewAtIndex:(NSInteger)index
{
    
    UIImageView *page = [[UIImageView alloc] init];
    NSUInteger photos = [self.gImages count];
    
    if (photos == 1) {
        page.frame = CGRectMake(0, 0, photoGallery.frame.size.width, photoGallery.frame.size.height);
    }else{
        page.frame = CGRectMake(0, 0, photoGallery.frame.size.width, photoGallery.frame.size.height);
    }
    
    page.contentMode = UIViewContentModeScaleAspectFill;
    
    NSString *imageURL = self.gImages[index][@"s3name"];
    
    //DLog(@"Image URL - %@",imageURL);
    DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                            initWithFrame:CGRectMake((page.bounds.size.width/2) - 20, (page.bounds.size.height/2) - 20, 40.0f, 40.0f)];
    
    progressView.thicknessRatio = .1f;
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor colorWithRed:0.850f green:0.301f blue:0.078f alpha:1];
    [page addSubview:progressView];
    
    [[S3PhotoFetcher s3FetcherWithBaseURL]
        downloadPhoto:imageURL
        to:page
        placeholderImage:[UIImage imageNamed:@"blurBg"]
        progressView:progressView
        downloadOption:SDWebImageContinueInBackground
        completion:^(id results, NSError *error){
            
        [progressView removeFromSuperview];
    }];
    
    return page;
}

#pragma UIPhotoGalleryDelegate methods
- (void)photoGallery:(UIPhotoGalleryView *)photoGallery didTapAtIndex:(NSInteger)index {
    
    self.galleryIndex = index;
    
    NSRange rangeForFirstArray = NSMakeRange(index, [self.gImages count] - index);
    NSRange rangeSecondArray = NSMakeRange(0, index);
    NSArray *firstArray = [self.gImages subarrayWithRange:rangeForFirstArray];
    NSArray *secondArray = [self.gImages subarrayWithRange:rangeSecondArray];
    
    self.gImages = [firstArray arrayByAddingObjectsFromArray:secondArray];
    
    [self.spotInfo setValue:self.gImages forKey:@"photoURLs"];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kPhotoCellTappedAtIndexNotification
     object:nil userInfo:@{@"photoIndex": @(index),@"photoInfo" : self.spotInfo}];
    
}




#pragma mark - Class Helpers
- (void)prepareForGallery:(NSDictionary *)photosData index:(NSIndexPath *)indexPath
{
    self.spotInfo = [NSMutableDictionary dictionaryWithDictionary:photosData];
    
    NSArray *allphotos = photosData[@"images"];
    
    //DLog(@"Photos - %@",allphotos);
    
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    NSArray *sortedPhotos = [allphotos sortedArrayUsingDescriptors:sortDescriptors];
    
    self.gImages = [NSMutableArray arrayWithArray:sortedPhotos];
    
    self.galleryIndex = indexPath.row;
    self.galleryIndex = indexPath.row;
    
    //DLog(@"self.photoGalleryView.frame - %@",NSStringFromCGRect(self.photoGalleryView.frame));
    if ([self.gImages count] == 1) {
        self.photoGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        self.photoGallery.initialIndex = 0;
        
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
}*/


@end
