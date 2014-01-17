//
//  PersonalSpotCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/10/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PersonalSpotCell.h"
#import "MainStreamViewController.h"
#import "S3PhotoFetcher.h"

@interface PersonalSpotCell()<TFScrollerDelegate,UIPhotoGalleryDataSource,UIPhotoGalleryDelegate>
@property (strong,nonatomic) NSArray *gImages;
@property int galleryIndex;
@property (retain,nonatomic) MainStreamViewController *mainStreamVC;
@end

@implementation PersonalSpotCell
/*-(NSArray *)gImages
{
    return @[@"gard_12.jpg",@"grad_01@2x.jpg",@"grad_05.jpg",@"grad_06.jpg",@"grad_07.jpg"];
}*/



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        //self.photoGalleryView.backgroundColor = [UIColor clearColor];
    }
    //[self setGImages:@[@"gard_12.jpg",@"grad_01@2x.jpg",@"grad_05.jpg",@"grad_06.jpg",@"grad_07.jpg"]];
     self.mainStreamVC = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"MAINSTREAM_VC"];
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




- (TFScroller *)mScroller
{
 
    if (!_mScroller){
        //DLog(@"Scroller is NIL");
        _mScroller = [[TFScroller alloc]
                      initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        //DLog(@"super class - %@,\nSuper height 1- %f\n",[super class],self.photoGalleryView.bounds.size.height);
        _mScroller.mDelegate = self;
        [_mScroller scrollViewInitialisation];
        
    }
    
    return _mScroller;
}


/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */



/*
#pragma mark - TFScroller Delegate
#pragma mark -
#pragma mark TFSCROLLER DELEGATE FUNCTIONS
-(void)tfscroller:(TFScroller*)tfscroller didSelectImageAtIndex:(NSInteger)pIndex
{
	
}

-(NSString*)tfScroller:(TFScroller*)tfscroller viewForIndex:(NSInteger)pInteger
{
    MagazineTeaserView *imageView =  [tfscroller.mImageViewsArray objectAtIndex:pInteger];
    
    __block UIImage *image = nil;
    DLog(@"Image is - %@ before assignment",image);
   	//pInteger = pInteger%3;
	UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[self gImages][pInteger]]];
    //DLog(@"Image named - %@",[NSString stringWithFormat:@"%@.jpg",[self gImages][pInteger]]);
	return image;
    
    DLog(@"Image URL being sent for index %i",pInteger);
    NSString *imageURL = self.gImages[pInteger][@"s3name"];
    
    return imageURL;
}


-(NSUInteger)numberOfPagesInScroller:(TFScroller*)tfscroller
{
    //DLog(@"Tnere should be %i photos in this cell's gallery",[self.gImages count]);
	return 3;
}
-(CGFloat)widthForPagesInScroller:(TFScroller*)tfscroller
{
    //DLog();
	return 220;
}
-(CGFloat)gapForPagesInScroller:(TFScroller*)tfscroller
{
    //DLog();
	return 10;
}
*/

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
    self.galleryIndex = index;
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
     object:nil userInfo:@{@"photoIndex": @(index),@"photoURLs" : self.gImages}];
}


#pragma mark - Class Helpers
- (void)prepareForGallery:(NSArray *)allSpots index:(NSIndexPath *)indexPath
{
    //DLog(@"PhotoURLs in cell are: %@",allSpots);
      //  self.gImages = allSpots;
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    NSArray *sortedPhotos = [allSpots sortedArrayUsingDescriptors:sortDescriptors];
    self.gImages = [NSMutableArray arrayWithArray:sortedPhotos];

        self.galleryIndex = indexPath.row;
    
        self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        self.pGallery.dataSource = self;
        self.pGallery.delegate = self;
    
        self.pGallery.galleryMode = UIPhotoGalleryModeImageRemote;
        self.pGallery.verticalGallery = _pGallery.peakSubView = NO;
        self.pGallery.initialIndex = 1;
        self.pGallery.showsScrollIndicator = NO;
        self.pGallery.backgroundColor = [UIColor blackColor];
        
    
}


@end
