//
//  PersonalSpotCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/10/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PersonalSpotCell.h"
#import "DACircularProgressView.h"
#import "S3PhotoFetcher.h"

@interface PersonalSpotCell()<UIPhotoGalleryDataSource,UIPhotoGalleryDelegate>

@property (strong,nonatomic) NSArray *gImages;
@property (strong,nonatomic) NSMutableDictionary *spotInfo;
@property NSInteger galleryIndex;
//@property (retain,nonatomic) MainStreamViewController *mainStreamVC;
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




/*- (TFScroller *)mScroller
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
}*/


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
    
    DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                            initWithFrame:CGRectMake((page.bounds.size.width/2) - 20, (page.bounds.size.height/2) - 20, 40.0f, 40.0f)];
    progressView.thicknessRatio = .1f;
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor colorWithRed:0.850f green:0.301f blue:0.078f alpha:1];
    [page addSubview:progressView];
    
    [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:imageURL to:page placeholderImage:[UIImage imageNamed:@"blurBg"] progressView:progressView completion:^(id results, NSError *error) {
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
     postNotificationName:kPhotoGalleryTappedAtIndexNotification
     object:nil userInfo:@{@"photoIndex": @(index),@"spotInfo" : self.spotInfo}];
    
}


#pragma mark - Class Helpers
- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath
{
    //DLog(@"SpotInfo is: %@",spotInfo);
    self.spotInfo = [NSMutableDictionary dictionaryWithDictionary:spotInfo];
    NSArray *allphotos = spotInfo[@"photoURLs"];
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    NSArray *sortedPhotos = [allphotos sortedArrayUsingDescriptors:sortDescriptors];
    
    self.gImages = [NSMutableArray arrayWithArray:sortedPhotos];
    
    self.galleryIndex = indexPath.row;
    
    //DLog(@"self.photoGalleryView.frame - %@",NSStringFromCGRect(self.photoGalleryView.frame));
    if ([self.gImages count] == 1) {
        self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(0, 0, self.photoGalleryView.frame.size.width,self.photoGalleryView.frame.size.height)];
        
        self.pGallery.initialIndex = 0;
        //DLog(@"Set photo gallery initial index to %i",self.photoGallery.initialIndex);
    }else{
        self.pGallery = [[UIPhotoGalleryView alloc] initWithFrame:CGRectMake(20, 0, 280,self.photoGalleryView.frame.size.height)];
        
    }

        
        self.pGallery.dataSource = self;
        self.pGallery.delegate = self;
    
        self.pGallery.galleryMode = UIPhotoGalleryModeCustomView;
        self.pGallery.verticalGallery = _pGallery.peakSubView = NO;
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


@end
