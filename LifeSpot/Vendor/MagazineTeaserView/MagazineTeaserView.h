//
//  MagazineTeaserView.h
//  CampaignIpad
//
//  Created by rajat talwar on 26/02/11.
//  Copyright 2011 Rajat. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MagazineTeaserDelegate;

@interface MagazineTeaserView : UIView {
	
	CGFloat mWidth,mHeight;
}
@property(assign)	id <MagazineTeaserDelegate> mDelegate;
@property(readwrite)	NSInteger mIndex;
@property(nonatomic,retain) 	UIImage *mImage;
@property(nonatomic,retain) UIButton *mButton;
@property(nonatomic,retain) UILabel *mIssueText;
@property(nonatomic,retain) UITextView *mTextView;
@property (strong,nonatomic) UIActivityIndicatorView *activityIndicator;
//@property(nonatomic,retain)	ImageLoader *mImageLoader;


- (id)initWithFrame:(CGRect)frame andImage:(UIImage*)pImage width:(CGFloat)pWidth height:(CGFloat)pHeight;
- (id)initWithFrame:(CGRect)frame andImageURL:(NSString *)pImageURL width:(CGFloat)pWidth height:(CGFloat)pHeight;

@end

@protocol MagazineTeaserDelegate
-(void)magazineTeaser:(MagazineTeaserView*)magazineTeaser didSelectPageAtIndex:(NSInteger)pIndex;
@end