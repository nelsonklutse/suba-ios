//
//  PlacesWatchingStreamCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/30/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PlacesWatchingStreamCell.h"

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





#pragma UIPhotoGalleryDelegate methods
- (void)photoGallery:(UIPhotoGalleryView *)photoGallery didTapAtIndex:(NSInteger)index {
    
    //NSMutableArray
    if (index > 0) {
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
    
    //self.galleryIndex = indexPath.row;
    
    self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
    
    self.pGallery.contentMode = UIViewContentModeScaleToFill;
    self.pGallery.dataSource = self;
    self.pGallery.delegate = self;
    
    self.pGallery.galleryMode = UIPhotoGalleryModeImageRemote;
    self.pGallery.verticalGallery = NO;
    self.pGallery.peakSubView = YES;
    self.pGallery.initialIndex = 0;
    self.pGallery.showsScrollIndicator = NO;
    self.pGallery.subviewGap = 10;
    self.pGallery.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"blurBg"]];
    
    
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
