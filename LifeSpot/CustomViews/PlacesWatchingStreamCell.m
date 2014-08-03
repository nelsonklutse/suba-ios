//
//  PlacesWatchingStreamCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/30/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PlacesWatchingStreamCell.h"
#import "DACircularProgressView.h"
#import "S3PhotoFetcher.h"

@interface PlacesWatchingStreamCell()<UIPhotoGalleryDataSource,UIPhotoGalleryDelegate,UIPhotoItemDelegate>
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,nonatomic) NSArray *gImages;
@end

@implementation PlacesWatchingStreamCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


#pragma UIPhotoGalleryDataSource methods
- (NSInteger)numberOfViewsInPhotoGallery:(UIPhotoGalleryView *)photoGallery {
    //DLog(@"Number of Images - %lu",(unsigned long)[self.gImages count]);
    if ([self.gImages count] >= 3) {
        return 3;
    }
    return [self.gImages count];
}

/*-(UIImage*)photoGallery:(UIPhotoGalleryView*)photoGallery localImageAtIndex:(NSInteger)index {
 DLog();
 return [UIImage imageNamed:[NSString stringWithFormat:@"sample%d.jpg", index % 10]];
 }*/

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
    
    DLog(@"Image URL - %@",imageURL);
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
    
    //NSMutableArray
    if (index > 0){
        //DLog(@"Rearranging the array coz index is %i",index);
        NSRange rangeForFirstArray = NSMakeRange(index, [self.gImages count] - index);
        NSRange rangeSecondArray = NSMakeRange(0, index);
        NSArray *firstArray = [self.gImages subarrayWithRange:rangeForFirstArray];
        NSArray *secondArray = [self.gImages subarrayWithRange:rangeSecondArray];
        
        self.gImages = [firstArray arrayByAddingObjectsFromArray:secondArray];
    }
    
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kPhotoGalleryTappedAtIndexNotification
     object:nil userInfo:@{@"photoIndex": @(index),@"spotInfo" : self.spotInfo}];
}




- (UIPhotoGalleryDoubleTapHandler)photoGallery:(UIPhotoGalleryView *)photoGallery doubleTapHandlerAtIndex:(NSInteger)index {
    switch (photoGallery.galleryMode) {
        case UIPhotoGalleryModeImageLocal:
            return UIPhotoGalleryDoubleTapHandlerZoom;
            
        case UIPhotoGalleryModeImageRemote:
            return UIPhotoGalleryDoubleTapHandlerNone;
            
        default:
            return UIPhotoGalleryDoubleTapHandlerCustom;
    }
}



#pragma mark - Class Helpers
- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath
{
    DLog(@"SpotInfo is: %@",spotInfo);
    self.spotInfo = spotInfo;
    NSArray *allphotos = spotInfo[@"photoURLs"];
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    NSArray *sortedPhotos = [allphotos sortedArrayUsingDescriptors:sortDescriptors];
    self.gImages = [NSMutableArray arrayWithArray:sortedPhotos];
    
    if ([self.gImages count] == 1) {
        self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        self.pGallery.initialIndex = 0;
        //DLog(@"Set photo gallery initial index to %i",self.photoGallery.initialIndex);
    }else{
        self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(20, 0, 280,self.photoGalleryView.frame.size.height)];
        
    }
    
    self.pGallery.contentMode = UIViewContentModeScaleToFill;
    self.pGallery.dataSource = self;
    self.pGallery.delegate = self;
    
    self.pGallery.galleryMode = UIPhotoGalleryModeCustomView;
    self.pGallery.verticalGallery = NO;
    self.pGallery.peakSubView = YES;
    self.pGallery.initialIndex = 0;
    self.pGallery.showsScrollIndicator = NO;
    self.pGallery.subviewGap = 5;
    //self.pGallery.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blurBg"]];
    
    self.pGallery.backgroundColor = [UIColor clearColor];
    
    if ([self.gImages count] > 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100000), dispatch_get_main_queue(), ^{
            if (self.pGallery.initialIndex != 1) {
                [self.pGallery setInitialIndex:1 animated:NO];
            }
            
        });
    }

    
}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


@end
