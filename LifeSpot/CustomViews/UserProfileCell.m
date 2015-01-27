//
//  UserProfileCell.m
//  LifeSpot
//
//  Created by Kwame Nelson on 6/18/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "UserProfileCell.h"
#import "DACircularProgressView.h"
#import "S3PhotoFetcher.h"

@interface UserProfileCell()

@property (strong,nonatomic) NSArray *gImages;
@property (strong,nonatomic) NSArray *allPhotos;
@property (strong,nonatomic) NSMutableDictionary *spotInfo;
@property NSInteger galleryIndex;

@end

@implementation UserProfileCell

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
    
    DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                            initWithFrame:CGRectMake((page.bounds.size.width/2) - 20, (page.bounds.size.height/2) - 20, 40.0f, 40.0f)];
    progressView.thicknessRatio = .1f;
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor colorWithRed:0.850f green:0.301f blue:0.078f alpha:1];
    [page addSubview:progressView];
    
    [[S3PhotoFetcher s3FetcherWithBaseURL]
                    downloadPhoto:imageURL to:page
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
    
    
    //self.allPhotos = [firstArray arrayByAddingObjectsFromArray:secondArray];
    [self.spotInfo setValue:self.allPhotos forKey:@"photoURLs"];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:kPhotoGalleryTappedAtIndexNotification
     object:nil userInfo:@{@"photoIndex": @(index),@"spotInfo" : self.spotInfo}];
    
}*/


/*#pragma mark - Class Helpers
- (void)prepareForGallery:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath
{
    //DLog(@"SpotInfo is: %@",spotInfo);
    self.spotInfo = [NSMutableDictionary dictionaryWithDictionary:spotInfo];
    NSArray *allphotos = [NSMutableArray arrayWithArray:
                          [NSOrderedSet orderedSetWithArray:spotInfo[@"photoURLs"]].array];
    
    //DLog(@"Number of Photos to load - %i",[allphotos count]);
    
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    self.allPhotos = [allphotos sortedArrayUsingDescriptors:sortDescriptors];
    
    self.gImages = [NSMutableArray arrayWithObject:self.allPhotos[0]];
    
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
    
}*/


#pragma mark - Stream members images
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

- (NSString *)initialStringForPersonString:(NSString *)personString {
    NSString *initials = nil;
    @try {
        if (![personString isKindOfClass:[NSNull class]]) {
            
            NSArray *comps = [personString componentsSeparatedByString:k_SEPARATOR_CHARACTER];
            NSMutableArray *mutableComps = [NSMutableArray arrayWithArray:comps];
            
            for (NSString *component in mutableComps) {
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

-(void)fillView:(UIView *)view WithImage:(NSString *)imageURL
{
    [[view subviews]
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGRect frame = CGRectMake(view.bounds.origin.x, view.bounds.origin.y, view.bounds.size.width, view.bounds.size.height);
    
    //DLog(@"View Bounds - %@\nView frame - %@",NSStringFromCGRect(view.bounds),NSStringFromCGRect(view.frame));
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    
    view.backgroundColor = [UIColor clearColor];
    
    [view addSubview:imageView];
    
    
}

-(void)setUpBorderWithColor:(CGColorRef)colorRef AndThickness:(CGFloat)height
{
    self.contentView.clipsToBounds = YES;
    CALayer *TopBorder = [CALayer layer];
    TopBorder.frame = CGRectMake(0.0f,0.0f,self.contentView.frame.size.width,height);
    TopBorder.backgroundColor = colorRef;
    
    [self.contentView.layer addSublayer:TopBorder];
}


- (void)setImageURL:(NSDictionary *)spotInfo index:(NSIndexPath *)indexPath
{
    if ([self.contentView viewWithTag:1500]) {
        // If we have a DACircular Progress View
        [[self.contentView viewWithTag:1500] removeFromSuperview];
    }
    
    
    self.spotInfo = [NSMutableDictionary dictionaryWithDictionary:spotInfo];
    NSArray *allphotos = spotInfo[@"photoURLs"];
    
    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
    self.allPhotos = [allphotos sortedArrayUsingDescriptors:sortDescriptors];
    
    self.gImages = [NSMutableArray arrayWithObject:self.allPhotos[0]];
    NSString *imageURL = self.gImages[0][@"s3name"];
    
    DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                            initWithFrame:CGRectMake((self.firstPhotoImageView.bounds.size.width/2) -
                                                                     20,(self.firstPhotoImageView.bounds.size.height/2)+10, 40.0f, 40.0f)];
    
    progressView.thicknessRatio = .1f;
    progressView.roundedCorners = YES;
    progressView.trackTintColor = [UIColor whiteColor];
    progressView.progressTintColor = [UIColor colorWithRed:0.850f green:0.301f blue:0.078f alpha:1];
    progressView.tag = 1500;
    [self.contentView addSubview:progressView];
    
    [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:imageURL to:self.firstPhotoImageView placeholderImage:[UIImage imageNamed:@"blurBg"] progressView:progressView downloadOption:SDWebImageContinueInBackground completion:^(id results, NSError *error){
        
        [progressView removeFromSuperview];
    }];

}



@end
