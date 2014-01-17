//
//  MagazineTeaserView.m
//  CampaignIpad
//
//  Created by rajat talwar on 26/02/11.
//  Copyright 2011 Rajat. All rights reserved.
//

#import "MagazineTeaserView.h"
#import "S3PhotoFetcher.h"

@interface MagazineTeaserView()
@end

@implementation MagazineTeaserView

/*@synthesize mButton,mImage,
mIssueText,mIndex,
mTextView,mDelegate;*/

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event 
{
	[self.mDelegate magazineTeaser:self didSelectPageAtIndex:_mIndex];

}

-(UIActivityIndicatorView *)activityIndicator
{
   UIActivityIndicatorView *aIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    aIndicator.frame = CGRectMake(20, 20, 25, 25);
    aIndicator.hidesWhenStopped = YES;
    aIndicator.color = [UIColor darkGrayColor];
    
    return aIndicator;
}


- (id)initWithFrame:(CGRect)frame andImage:(UIImage*)pImage width:(CGFloat)pWidth height:(CGFloat)pHeight{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
		mWidth  = pWidth;
		mHeight = pHeight;
		//NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
//		[center addObserver:self
//				   selector:@selector(remove:)
//					   name:UIApplicationDidReceiveMemoryWarningNotification
//					 object:nil];
		
		
        [self setBackgroundColor:[UIColor clearColor]];
		self.opaque = TRUE;
		self.mImage = pImage;
    }
    return self;
}


-(id)initWithFrame:(CGRect)frame andImageURL:(NSString *)pImageURL width:(CGFloat)pWidth height:(CGFloat)pHeight
{
   // __block UIImage *realImage = nil;
    self = [super initWithFrame:frame];
    
    
    if (self) {
        // Initialization code.
        
		mWidth  = pWidth;
		mHeight = pHeight;
        
        [self setBackgroundColor:[UIColor lightGrayColor]];
		self.opaque = TRUE;
        
        [self addSubview:self.activityIndicator];
        [self.activityIndicator startAnimating];
        
        [[S3PhotoFetcher s3FetcherWithBaseURL]
                        downloadPhoto:pImageURL
                            completion:^(UIImage *results, NSError *error) {
                    
                    self.mImage = results;
                    [self.activityIndicator stopAnimating];
                   // DLog(@"Magazine View image - %@",NSStringFromCGSize(<#CGSize size#>));
        }];
        
		
    }
    
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
	CGContextRef myContext = UIGraphicsGetCurrentContext();

	CGContextTranslateCTM(myContext, 0, mHeight);
	CGContextScaleCTM(myContext, 1.0, -1.0);
	
	CGContextDrawImage(myContext, CGRectMake(0, 0, mWidth, mHeight), [_mImage CGImage]);

}



@end
