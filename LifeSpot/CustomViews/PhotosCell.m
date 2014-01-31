//
//  Photos.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/20/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PhotosCell.h"

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
    
    self.photoGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
    
    self.photoGallery.dataSource = self;
    self.photoGallery.delegate = self;
    
    self.photoGallery.galleryMode = UIPhotoGalleryModeImageRemote;
    self.photoGallery.verticalGallery = _photoGallery.peakSubView = NO;
    self.photoGallery.initialIndex = 0;
    self.photoGallery.showsScrollIndicator = NO;
    self.photoGallery.backgroundColor = [UIColor blackColor];
    
    
}


@end
