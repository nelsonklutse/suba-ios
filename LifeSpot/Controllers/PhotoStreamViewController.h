//
//  PhotoStreamViewController.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kSpot = 0,
    kPhoto
}Mutant;

typedef enum{
    kTakeCamera = 0,
    kGallery
}PhotoSourceType;

typedef enum{
    kSexuallyExplicit = 0,
    kUnrelated
}ReportOptions;


@interface PhotoStreamViewController : UIViewController

@property (strong,nonatomic) NSMutableArray *photos;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,nonatomic) NSString *spotName;
@property (strong,nonatomic) NSString *spotID;
@property (strong,nonatomic) NSString *photoToShow;
@property BOOL isLaunchingFromNotification;
@property BOOL shouldShowPhoto;
@property BOOL shouldShowDoodle;
@property (strong,nonatomic) NSString *isUserMemberOfStream;
@property NSInteger numberOfPhotos;


- (IBAction)flipPhotoToShowRemix:(id)sender;

















@end
