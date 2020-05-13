//
//  PhotoStreamViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/14/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "PhotoStreamViewController.h"
#import "PhotoStreamCell.h"
#import "S3PhotoFetcher.h"
#import "StreamSettingsViewController.h"
#import "AlbumMembersViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "UserProfileViewController.h"
#import "Photo.h"
#import "User.h"
#import "Spot.h"
#import "Comment.h"
#import "BDKNotifyHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EmailInvitesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PhotoStreamFooterView.h"
#import "PhotoStreamHeaderView.h"
#import "InvitesViewController.h"
#import "SBDoodleViewController.h"
#import "TermsViewController.h"
#import <DACircularProgressView.h>
#import <AviarySDK/AVYPhotoEditorController.h>
#import <AviarySDK/AVYOpenGLManager.h>
#import <AviarySDK/AVYPhotoEditorCustomization.h>
#import "Branch.h"
#import "WhatsAppKit.h"
#import "CommentsViewController.h"
#import "PhotoTakersViewController.h"
#import "PhotoBrowserViewController.h"
#import "SBTransitionAnimator.h"
#import <MBProgressHUD.h>
#import "AMPopTip.h"

typedef enum{
    kActionLike = 0,
    kActionEdit
}ActionPending;

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);
typedef void (^StandardPhotoCompletion) (CGImageRef standardPhoto,NSError *error);
typedef void (^SBFlipDoodleCompletionHandler) (BOOL didFlipDoodle);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"

@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UIGestureRecognizerDelegate,MFMessageComposeViewControllerDelegate,UITextFieldDelegate,UIAlertViewDelegate,MFMailComposeViewControllerDelegate,AVYPhotoEditorControllerDelegate,UIViewControllerTransitioningDelegate>

{
    UIImage *selectedPhoto;
    NSIndexPath *selectedPhotoIndexPath;
    NSString *selectedPhotoId;
    PhotoStreamCell *selectedPhotoCell;
    NSArray *pendingActions;
    UILabel *titleView;
    NSData *imageToUpload;
    NSString *nameOfImageToUpload;
    BOOL didImageFinishUploading;
    BOOL isDoodling;
    BOOL isFiltered;
    BOOL shouldReplacePhoto;
    NSString *branchURLforInviteToStream;
    NSString *branchURLforShareStream;
    NSMutableArray *filteredPhotos;
    NSDictionary *selectedPicTaker;
    NSArray *_menuItems;
    NSURL *uploadingImageAssetURL;
    NSMutableArray *mwPhotos;
}


@property (strong,nonatomic) NSDictionary *photoInView;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;
@property (copy,nonatomic) NSString *firstName;
@property (copy,nonatomic) NSString *lastName;
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *userEmail;
@property (copy,nonatomic) NSString *userPassword;
@property (copy,nonatomic) NSString *userPasswordConfirm;

@property (weak, nonatomic) IBOutlet UILabel *streamNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *howLongLabel;

@property (retain, nonatomic) IBOutlet UIView *hiddenTopMenuView;

@property (retain, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;

@property (weak, nonatomic) IBOutlet UIButton *dismissDropDownButton;

@property (weak, nonatomic) IBOutlet UIView *loadingInfoIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingStreamInfoIndicator;
@property (weak, nonatomic) IBOutlet UIView *noPhotosView;

@property (weak, nonatomic) IBOutlet UIButton *addFirstPhotoCameraButton;

@property (retain, nonatomic) IBOutlet UIButton *shareStreamButton;
@property (retain, nonatomic) IBOutlet UIButton *streamSettingsButton;

@property (weak, nonatomic) IBOutlet UIView *uploadingPhoto;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *uploadingPhotoIndicator;
@property (retain, nonatomic) IBOutlet UIButton *requestForPhotosButton;
@property (weak, nonatomic) IBOutlet UIView *createAccountOptionsView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *facebookLoginIndicator;
@property (weak, nonatomic) IBOutlet UILabel *noActionLabel;


@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *reTypePasswordField;
@property (weak, nonatomic) IBOutlet UIScrollView *signUpWithEmailView;
@property (weak, nonatomic) IBOutlet UIScrollView *finalSignUpWithEmailView;

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIImageView *likeImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signUpSpinner;
@property (weak, nonatomic) IBOutlet UIView *firstTimeNotificationScreen;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *iconCameraButton;
@property (strong,nonatomic) UILabel *navItemTitle;

- (IBAction)unWindToPhotoStream:(UIStoryboardSegue *)segue;
- (IBAction)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue;


@property (weak, nonatomic) IBOutlet UIScrollView *createAccountView;
@property (weak, nonatomic) IBOutlet UIImageView *coachMarkImageView;
@property (weak, nonatomic) IBOutlet UIButton *gotItButton;


- (IBAction)sortPhotosButtonTapped:(UIButton *)sender;

- (IBAction)addFirstPhotoButtonTapped:(UIButton *)sender;

- (IBAction)remixPhotoDone:(UIStoryboardSegue *)segue;
- (IBAction)showTermsOfService:(UIButton *)sender;
- (IBAction)showPrivacyPolicy:(UIButton *)sender;
- (IBAction)dismissNotificationScreen:(id)sender;
- (IBAction)registerForPushNotification:(id)sender;

- (IBAction)remixPhoto:(UIControl *)sender;
- (IBAction)sharePhoto:(UIButton *)sender;
- (IBAction)likePhoto:(id)sender;
- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)showMoreActions:(UIButton *)sender;
- (IBAction)signUpWithEmailOptionChosen:(id)sender;
- (IBAction)dismissCreateSubaAccountScreen:(id)sender;
- (IBAction)moveToProfile:(UIButton *)sender;
- (IBAction)doFacebookLogin:(id)sender;
- (IBAction)showCommentsAction:(UIButton *)sender;

- (IBAction)showMembers:(id)sender;
- (IBAction)dismissCoachMark:(UIButton *)sender;
- (IBAction)showPhotoTakers:(id)sender;
- (IBAction)seeAllPhotos:(id)sender;

- (IBAction)seeTagsInPhoto:(UIButton *)sender;
- (void)showHiddenMoreOptions;
- (void)prepareBranchURLforInvitingFriendsToStream;
- (void)prepareBranchURLforSharingStream;
- (void)sendSMSToRecipients:(NSMutableArray *)recipients;
- (NSString *)getRandomPINString:(NSInteger)length;
- (void)preparePhotoBrowser:(NSMutableArray *)photos;
- (void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion;
- (void)deletePhotoAtIndexFromStream:(NSInteger)index;
- (void)uploadPhotos:(NSArray *)images;
- (void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo;
- (void)showHiddenMenu:(UITapGestureRecognizer *)sender;
- (void)savePhoto:(UIImage *)imageToSave;
- (void)photoCardTapped:(UITapGestureRecognizer *)sender;
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender;
- (void)savePhotoToCustomAlbum:(UIImage *)photo;
- (void)showPhotoOptions;
- (void)showReportOptions;
- (void)reportPhoto:(NSDictionary *)reportInfo;
- (void)loadSpotInfo:(NSString *)spotId;
- (void)loadSpotImages:(NSString *)spotId;
- (void)pickImage:(id)sender;
- (void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
- (void)unlikePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath;
- (void)resamplePhotoInfo:(NSDictionary *)info
                     flag:(NSString *)flag
            numberOfLikes:(NSString *)likes
                  atIndex:(NSInteger)selectedIndex;
- (void)setUpTitleView;
- (void)checkAllTextFields;
- (void)dismissCreateAccountPopUp;
- (void)showGivePushNotificationScreen;
- (void)uploadingPhotoView:(BOOL)flag;
- (void)executePendingAction:(ActionPending)pendingAction;
- (void)doodlePhoto:(PhotoStreamCell *)cell;
- (void)findAndShowPhoto:(NSString *)photoToShow;
- (NSMutableArray *)prepareMWPhotos:(NSMutableArray *)photoInfo;

@end


@implementation PhotoStreamViewController
int toggler;


- (IBAction)photoTagDone:(UIStoryboardSegue *)segue
{
    PhotoBrowserViewController *pVC = segue.sourceViewController;
    
    if (pVC.localTags.count > 0) {
        
    
    DLog(@"new tags: %@", pVC.localTags);
    
    
    
    NSInteger photoIdforTag = [pVC.imageId integerValue]; // id of the photo with the tags
    
    //1. Get the tags from the photos in this stream and update them with the tags that were just added
    
        NSMutableArray *streamPhotos = [self.photos mutableCopy];
    
        //Let's find the photoId in the photos array
        for (NSDictionary *photoInfo in streamPhotos) {
            NSInteger photoId = [photoInfo[@"id"] integerValue];
            NSMutableDictionary *mutablePhotoInfo = [photoInfo mutableCopy];
            if (photoId == photoIdforTag) {
                
                DLog(@"We've found the photo we want: %i = %i",photoIdforTag,photoId);
                
              // We've found the photo that was just tagged
              // Let's check if this photo has tags
                if ([mutablePhotoInfo[@"numberOfTags"] integerValue] > 0) {
                    // This photo has tags
                    NSMutableArray *photoTags = [(NSArray *)photoInfo[@"photoTags"] mutableCopy];
                    
                    DLog(@"Already existing tags: %@",[photoTags description]);
                    for (NSDictionary *tag in pVC.localTags){
                        
                        DLog(@"Adding this tag: %@",tag);
                        
                        [photoTags addObject:tag];
                    }
                    
                    [mutablePhotoInfo setValue:photoTags forKey:@"photoTags"];
                    [streamPhotos replaceObjectAtIndex:[streamPhotos indexOfObject:photoInfo] withObject:mutablePhotoInfo];
                    DLog(@"Updated tags in photo: %@",streamPhotos.description);
                    
                    break;
                    
                }else{
                    // this photo does not have tags so let's create one
                    DLog(@"This photo has no tags so we're going to create one");
                    
                    [mutablePhotoInfo setValue:@(pVC.localTags.count) forKey:@"numberOfTags"];
                    [mutablePhotoInfo setValue:pVC.localTags forKey:@"photoTags"];
                    
                    [streamPhotos replaceObjectAtIndex:[streamPhotos indexOfObject:photoInfo] withObject:mutablePhotoInfo];
                    
                    //[streamPhotos addObject:tagsDict];
                    
                    DLog(@"Photo info : %@",streamPhotos.description);
                    
                    break;
                    
                }
            }
        }
        
        self.photos = streamPhotos;
        [self.photoCollectionView reloadData];
    }
}


- (IBAction)remixPhotoDone:(UIStoryboardSegue *)segue
{
    SBDoodleViewController *ddVC = segue.sourceViewController;
    
    
    PhotoStreamCell *cell = (PhotoStreamCell *)[self.photoCollectionView
                                                cellForItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPhotoIndexPath.item inSection:0]];
    
    cell.remixedImageView.alpha = 1;
    cell.remixedImageView.image = ddVC.savedPhoto;
    NSData *data = UIImageJPEGRepresentation(ddVC.savedPhoto, 1.0);
    
    [self uploadDoodle:data WithName:self.photos[selectedPhotoIndexPath.item][@"s3name"]];
}

- (IBAction)showTermsOfService:(UIButton *)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
    [self.navigationController pushViewController:termsVC animated:YES];
}

- (IBAction)showPrivacyPolicy:(UIButton *)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
    [self.navigationController pushViewController:termsVC animated:YES];
}


- (void)setUpTitleView
{
    // Set up the hidden Menu
    self.requestForPhotosButton.layer.borderWidth = .5;
    self.requestForPhotosButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.shareStreamButton.layer.borderWidth = .5;
    self.shareStreamButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.streamSettingsButton.layer.borderWidth = .5;
    self.streamSettingsButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    //Construct container view for labels to sit inside
    CGRect headerTitleSubtitleFrame = CGRectMake(0, 10, 200, 44);
    UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
    _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
    _headerTitleSubtitleView.autoresizesSubviews = NO;
    
    CGRect titleFrame = CGRectMake(10, 5, 160, 24);
    titleView = [[UILabel alloc] initWithFrame:titleFrame];
    titleView.backgroundColor = [UIColor clearColor];
    titleView.textAlignment = NSTextAlignmentCenter;
    titleView.textColor = [UIColor whiteColor];
    titleView.shadowColor = [UIColor clearColor];
    
    //DLog(@"Setting up titleView with stream name - %@",self.spotName);
    //titleView.text = (self.spotName) ? self.spotName : @"Stream";
    titleView.text = @""; 
    //[titleView sizeToFit];
    titleView.adjustsFontSizeToFitWidth = YES;
    
    [_headerTitleSubtitleView addSubview:titleView];
    
    CGRect subtitleFrame = CGRectMake((160/2), 25, 160, 44-25);
    UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
    [IonIcons label:subtitleView setIcon:icon_arrow_down_b size:20.0f color:[UIColor whiteColor] sizeToFit:YES];
    subtitleView.backgroundColor = [UIColor clearColor];
    subtitleView.textAlignment = NSTextAlignmentCenter;
    //subtitleView.textColor = [UIColor whiteColor];
    //subtitleView.shadowColor = [UIColor clearColor];
    subtitleView.adjustsFontSizeToFitWidth = YES;
    //[subtitleView sizeToFit];
    [_headerTitleSubtitleView addSubview:subtitleView];
    
    self.navigationItem.titleView = _headerTitleSubtitleView;
    
    [self.navigationItem.titleView setUserInteractionEnabled:YES];
    [self.navigationItem.titleView setMultipleTouchEnabled:YES];
    
    UITapGestureRecognizer *oneTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHiddenMenu:)];
    
    [oneTapGestureRecognizer setNumberOfTapsRequired:1];
    [oneTapGestureRecognizer setDelegate:self];
    
    [self.navigationItem.titleView addGestureRecognizer:oneTapGestureRecognizer];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpRightBarButtonItems];
    self.dismissDropDownButton.hidden = YES;
    self.dismissDropDownButton.enabled = NO;
   
    isDoodling = NO;
    
    // Load Aviary stuff so user doesn't have to wait longer to see the editor
    [AVYOpenGLManager beginOpenGLLoad];
    
    [AVYPhotoEditorCustomization purgeGPUMemoryWhenPossible:YES];
    
    CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
    self.hiddenTopMenuView.alpha = 0;
    self.hiddenTopMenuView.frame = hiddenMenuFrame;
    self.createAccountView.alpha = 0;
    self.firstTimeNotificationScreen.alpha = 0;
    
    self.navigationController.navigationBar.topItem.title = (self.spotName)?:@"";
    
    //DLog(@"Photos: %@",self.photos);
    
    // Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    self.library = [[ALAssetsLibrary alloc] init];
    
    // Photostream is launching from an Activity Screen
    if(!self.photos && !self.spotName && self.numberOfPhotos == 0 && self.spotID){
        // We are coming from an activity screen
        //DLog(@"Stream id - %@ coz we're coming from the activity screen",self.spotID);
        [self loadSpotImages:self.spotID];
    }
    
    
    
    if(!self.photos && self.numberOfPhotos > 0 && self.spotID) {
        // We are coming from a place where spotName is not set so lets load spot info
        if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            //DLog(@"User status - %@",[AppHelper userStatus]);
            [UIView animateWithDuration:.5 animations:^{
                //self.navigationController.navigationBarHidden = YES;
                self.firstTimeNotificationScreen.alpha = 1;
            }];
        }
        
        [self loadSpotImages:self.spotID];
    }
    
    
    
    if (![self.isUserMemberOfStream isEqualToString:@"YES"]) { // If the user is not a member of this stream
        //DLog(@"User is not a member of this stream so we are joining");
        if (self.spotID) {
            [[User currentlyActiveUser] joinSpot:self.spotID completion:^(id results, NSError *error) {
                if (!error){
                    // Ask main stream to reload
                    //DLog(@"Stream Info: %@",results);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUpdateStreamNotification object:@{@"streamId" : results[@"spotId"]}];
                }else{
                    DLog(@"Error - %@",error);
                }
            }];
        }
    }

     DLog(@"Should show photo: %i\nPhoto to show: %@\nStream Id: %@",self.shouldShowPhoto,self.photoToShow,self.spotID);
    
    if(self.spotID && self.photoToShow && self.shouldShowPhoto){
        
       [self loadSpotInfo:self.spotID];
        }else{
           DLog(@"Spot Info already loaded here: %@",self.spotInfo);
        }
    
    
    if(self.numberOfPhotos == 0 && self.spotName && self.spotID){
        
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
        
        self.streamNameLabel.text = self.spotName;
        self.streamLocationLabel.text = self.streamVenue;
        self.howLongLabel.text = self.timestamp;
        
        
        UIAlertView *addfirstPhotAlert =  [[UIAlertView alloc] initWithTitle:@"Add first photo" message:@"Add first photo so your friends can find this stream in \"Nearby Streams\"" delegate:self cancelButtonTitle:@"Later" otherButtonTitles:@"Add first photo",nil];
        addfirstPhotAlert.tag = 201;
        [addfirstPhotAlert show];
        
    }
    

    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.createAccountView.alpha = 0;
    //isDoodling = NO;
}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.topItem.title = @"";
    [AppHelper increasePhotoStreamEntries];
    
    // Prepare branch
    if (self.spotInfo) {
        [self prepareBranchURLforInvitingFriendsToStream];
    }
    
    
}


-(IBAction)sortPhotosButtonTapped:(UIButton *)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        
    } completion:^(BOOL finished) {
       [self performSegueWithIdentifier:@"PhotoTakersSegue" sender:[self photoTakers]];
    }];
     
    toggler += 1;
    
}


-(void)preparePhotoBrowser:(NSMutableArray *)photos{}


-(void)loadSpotImages:(NSString *)spotId
{
   [Spot fetchSpotImagesUsingSpotId:spotId completion:^(id results, NSError *error) {
       if (!error){
           NSArray *allPhotos = [results objectForKey:@"spotPhotos"];
           NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
           NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
           
           NSArray *thePhotos = [NSMutableArray arrayWithArray:[allPhotos sortedArrayUsingDescriptors:sortDescriptors]];
           self.photos = [NSMutableArray arrayWithArray:[NSOrderedSet orderedSetWithArray:thePhotos].array];
           
           if ([self.photos count] > 0) {
               
               self.noPhotosView.hidden = YES;
               self.photoCollectionView.hidden = NO;
               
               [self.photoCollectionView reloadData];
               
               
               if (self.shouldShowPhoto == YES || self.shouldShowDoodle == YES){
                   //[self setUpTitleView];
                   // Also find photo
                   if (self.photoToShow) {
                       //DLog(@"Just when we are about to pass photo to show - %@",self.photoToShow);
                       [self findAndShowPhoto:self.photoToShow];
                   }
                   
               }
               
           }else{
                   self.noPhotosView.hidden = NO;
                   self.photoCollectionView.hidden = YES;
             }           
       }else{
           DLog(@"Error - %@",error);
       }
   }];
}


-(void)loadSpotInfo:(NSString *)spotId
{
 // Show activity indicator
    [AppHelper showLoadingDataView:self.loadingInfoIndicatorView
                         indicator:self.loadingStreamInfoIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
        [AppHelper showLoadingDataView:self.loadingInfoIndicatorView
                             indicator:self.loadingStreamInfoIndicator flag:NO];
        if (error) {
            DLog(@"Error - %@",error);
            //[AppHelper showAlert:@"Network Error" message:error.localizedDescription buttons:@[@"Ok"] delegate:nil];
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                self.spotInfo = (NSDictionary *)results;
                self.spotName = (self.spotName) ? self.spotName : results[@"spotName"];
                //self.navigationItem.title = self.spotName;
                //self.navItemTitle.text = self.spotName;
                
                titleView.text = self.spotName;
                
                /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
                           size:10.0f color:[UIColor whiteColor] sizeToFit:NO];
                
                [self.navItemTitle sizeToFit];*/
                [self.photoCollectionView reloadData];
                self.cameraButton.enabled = YES;
            }
            
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)dismissCoachMark:(UIButton *)sender
{
    [UIView animateWithDuration:1.0 animations:^{
        self.coachMarkImageView.alpha = 0;
        [self.view viewWithTag:10000].alpha = 0;
        [[self.view viewWithTag:10000] removeFromSuperview];
    }];
  
}



- (IBAction)showPhotoTakers:(id)sender
{
    [self performSegueWithIdentifier:@"PhotoTakersSegue" sender:[self photoTakers]];
    
}

- (void)showAllPhotos
{
    isFiltered = NO;
    
    //[self.photoCollectionView reloadData];
    
    [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
}

- (IBAction)seeAllPhotos:(id)sender
{
    [self showAllPhotos];
  
   
}

- (IBAction)seeTagsInPhoto:(UIButton *)sender
{
    PhotoBrowserViewController *pVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoBrowserScene"];
    
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    
    pVC.transitioningDelegate = self;
    pVC.modalPresentationStyle = UIModalPresentationCustom;
    
    NSDictionary *photoInfo = (isFiltered) ? filteredPhotos[indexpath.item] : self.photos[indexpath.item];
    
    NSString *s3name = (isFiltered) ? filteredPhotos[indexpath.item][@"s3name"] :
    self.photos[indexpath.item][@"s3name"];
    
    pVC.imageURL = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,s3name];
    pVC.streamId = self.spotID;
    pVC.imageId = (isFiltered) ? filteredPhotos[indexpath.item][@"id"] : self.photos[indexpath.item][@"id"];
    pVC.imageInfo = photoInfo;
    
    NSArray *tags = self.photos[indexpath.row][@"photoTags"];
    pVC.tagsInPhoto = [NSMutableArray arrayWithArray:tags];

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pVC];
    
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:nc animated:YES completion:nil];
}


- (NSString *)getRandomPINString:(NSInteger)length
{
    NSMutableString *returnString = [NSMutableString stringWithCapacity:length];
    
    NSString *numbers = @"0123456789";
    
    // First number cannot be 0
    [returnString appendFormat:@"%C", [numbers characterAtIndex:(arc4random() % ([numbers length]-1))+1]];
    
    for (int i = 1; i < length; i++)
    {
        [returnString appendFormat:@"%C", [numbers characterAtIndex:arc4random() % [numbers length]]];
    }
    
    return returnString;
}


-(void)reportPhoto:(NSDictionary *)reportInfo
{
    [User reportPhoto:reportInfo completion:^(id results, NSError *error) {
        BDKNotifyHUD *hud = [BDKNotifyHUD notifyHUDWithImage:nil text:@"Photo Reported!"];
        
        hud.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
        
        // Animate it, then get rid of it. These settings last 1 second, takes a half-second fade.
        [self.view addSubview:hud];
        [hud presentWithDuration:2.0f speed:0.5f inView:self.view completion:^{
            [hud removeFromSuperview];
            [CSNotificationView showInViewController:self
                                           tintColor: [UIColor colorWithRed:0.850 green:0.301 blue:0.078 alpha:1]
                                               image:nil
                                             message:@"Thank you for your report. We will remove this photo if it violates our Community Guidelines."
                                            duration:5.0f];
        }];
        
        
    }];
}

-(void)deletePhotoAtIndexFromStream:(NSInteger)index
{
    [FBAppEvents logEvent:@"Photo_Deleted"];
    NSInteger photoIndex = index;
    [self.photos removeObjectAtIndex:photoIndex];
    
    [S3PhotoFetcher deletePhotoFromStream:self.photoInView completion:^(id results, NSError *error) {
        DLog(@"Response - %@",results);
        if (!error) {
            [self.photoCollectionView performBatchUpdates:^{
                [self.photoCollectionView
                 deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:photoIndex inSection:0]]];
            } completion:^(BOOL finished) {
                if ([self.photos count] == 0) {
                    self.noPhotosView.hidden = NO;
                    self.photoCollectionView.hidden = YES;
                }
            }];
            
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
        }
    }];
    
}

/*-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoStreamCell *photoStreamCell = (PhotoStreamCell *)cell;
    
    DLog(@"cell picture taker - %@\nCell frame - %@\nCell bounds - %@",
         photoStreamCell.pictureTakerName.text,NSStringFromCGRect(photoStreamCell.frame),NSStringFromCGRect(photoStreamCell.bounds));
}*/

#pragma mark - UICollectionView Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if(isFiltered){
        return [filteredPhotos count];
    }
    
    return [self.photos count];
}


-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoStreamCell *photoCardCell = nil;
    NSMutableArray *photoInfo = nil;
    static NSString *cellIdentifier = @"PhotoStreamCell";
    
    if ([[AppHelper kindOfDeviceScreen] isEqualToString:kIPHONE_4_SCREEN]){
        // Use ipHone 4 screen cell
        photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        //CGRect footerFrame  = CGRectMake(0, 367, 285, 67);
        //photoCardCell.photoCardFooterView.frame = footerFrame;
    }else{
        // Bigger phone
        photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"iPHONEBIGPhotoStreamCell" forIndexPath:indexPath];
    }
    
    photoCardCell.showTagsButton.hidden = YES;
    
    
    //set contentView frame and autoresizingMask
    photoCardCell.contentView.frame = photoCardCell.bounds;
    photoCardCell.contentView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin |UIViewAutoresizingFlexibleTopMargin |UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;

    
    // Set up the Gesture Recognizers
    UITapGestureRecognizer *oneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [oneTapRecognizer setNumberOfTapsRequired:1];
    [oneTapRecognizer setDelegate:self];
    
    UITapGestureRecognizer *oneTapRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(photoCardTapped:)];
    
    [oneTapRecognizer1 setNumberOfTapsRequired:1];
    [oneTapRecognizer1 setDelegate:self];

    if (isFiltered) {
        photoInfo = [NSMutableArray arrayWithArray:filteredPhotos];
    }else photoInfo = [NSMutableArray arrayWithArray:self.photos];
    
    NSString *pictureTakerName = photoInfo[indexPath.row][@"pictureTaker"];
    
    // Give border around header View
    [photoCardCell setBorderAroundView:photoCardCell.headerView];
    [photoCardCell setBorderAroundView:photoCardCell.footerView];
    
    photoCardCell.pictureTakerView.layer.borderWidth = 1;
    photoCardCell.pictureTakerView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    photoCardCell.pictureTakerView.layer.cornerRadius = 10;
    photoCardCell.pictureTakerView.clipsToBounds = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
        NSString *photoLiked = photoInfo[indexPath.item][@"userLikedPhoto"];
        if ([photoLiked isEqualToString:@"YES"]) {
            [photoCardCell.likePhotoButton setSelected:YES];
        }else{
           [photoCardCell.likePhotoButton setSelected:NO];
        }
    });
    
    [photoCardCell makeInitialPlaceholderView:photoCardCell.pictureTakerView name:pictureTakerName];
    //DLog(@"PicTakername - %@",pictureTakerName);
    
    NSString *photoURLstring = photoInfo[indexPath.item][@"s3name"];
    NSString *photoRemixURLString = photoInfo[indexPath.item][@"s3RemixName"];
   
    if(photoInfo[indexPath.row][@"pictureTakerPhoto"]){
        
        NSString *pictureTakerPhotoURL = photoInfo[indexPath.row][@"pictureTakerPhoto"];
        [photoCardCell fillView:photoCardCell.pictureTakerView WithImage:pictureTakerPhotoURL];
    }
    
    photoCardCell.pictureTakerName.text = pictureTakerName;
    
    // Fill the number of likes
    if ([photoInfo[indexPath.row][@"likes"] integerValue] >= 1) {
       photoCardCell.numberOfLikesLabel.text = photoInfo[indexPath.item][@"likes"];
        
    }else{
        photoCardCell.numberOfLikesLabel.text = kEMPTY_STRING_WITHOUT_SPACE;
    }
    
    // Fill the number of comments
    if ([photoInfo[indexPath.row][@"comments"] integerValue] >= 1) {
        photoCardCell.numberOfCommentsLabel.text = photoInfo[indexPath.item][@"comments"];
        
    }else{
        photoCardCell.numberOfCommentsLabel.text = kEMPTY_STRING_WITHOUT_SPACE;
    }
    
    
    // Show view tags icon
    if ([photoInfo[indexPath.row][@"numberOfTags"] integerValue] >= 1) {
        photoCardCell.showTagsButton.hidden = NO;
    }else{
        photoCardCell.showTagsButton.hidden = YES;
    }
    
    
    // Add the gesture recognizer to original photo cell
    [photoCardCell.photoCardImage setUserInteractionEnabled:YES];
    [photoCardCell.photoCardImage setMultipleTouchEnabled:YES];
    [photoCardCell.photoCardImage addGestureRecognizer:oneTapRecognizer];
    
    // Add the gesture recognizer to remix photo cell
    [photoCardCell.remixedImageView setUserInteractionEnabled:YES];
    [photoCardCell.remixedImageView setMultipleTouchEnabled:YES];
    [photoCardCell.remixedImageView addGestureRecognizer:oneTapRecognizer1];
    
    DLog(@"AssetURL id: %@",photoInfo[indexPath.item][@"id"]);
    // check what kind of url we're loading
    if ([photoInfo[indexPath.item][@"id"] intValue] == 0){
        
        DLog(@"AssetURL: %@",photoInfo[indexPath.item][@"s3name"]);
        // s3name is an asset URL
        [self showLocalPhoto:photoCardCell.photoCardImage withURL:photoInfo[indexPath.item][@"s3name"]];
        
    }else{
        // Download photo card image
        if (shouldReplacePhoto) {
            DLog(@"We're replacing a photo with: %@",[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoURLstring]);
            
            [self downloadPhoto:photoCardCell.photoCardImage
                        withURL:photoURLstring
                 downloadOption:SDWebImageContinueInBackground placeholder:[UIImage imageWithData:imageToUpload]];
            
            [photoCardCell.photoCardImage sd_setImageWithURL:
             [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoURLstring]]];
            
        }else{
            [self downloadPhoto:photoCardCell.photoCardImage
                        withURL:photoURLstring
                 downloadOption:SDWebImageProgressiveDownload placeholder:[UIImage imageNamed:@"newOverlay"]];
        }
        
    }
    
    
    if (photoRemixURLString){
        
       
        [self downloadPhoto:photoCardCell.remixedImageView
                    withURL:photoRemixURLString
             downloadOption:SDWebImageRefreshCached placeholder:[UIImage imageNamed:@"newOverlay"]];
        
     }else{
        photoCardCell.remixedImageView.image = nil;
    }
    
    if ([self.photos[indexPath.item][@"remixers"] integerValue] <= 0){
        photoCardCell.remixedImageView.alpha = 0;
        photoCardCell.photoCardImage.alpha = 1;
        //photoCardCell.viewDoodleContainer;
        photoCardCell.viewDoodleContainer.hidden = YES;
        //photoCardCell.showCommentsActionButton.hidden = YES;
        photoCardCell.numberOfRemixersLabel.hidden = YES;
    }else{
        //DLog(@"There are remixers for this photo");
        NSInteger remixers = [photoInfo[indexPath.item][@"remixers"] integerValue];
        
        //photoCardCell.viewDoodleContainer.enabled = YES;
        photoCardCell.viewDoodleContainer.hidden = NO;
        
        //photoCardCell.showCommentsActionButton.hidden = NO;
        photoCardCell.remixedImageView.alpha = 1;
        photoCardCell.numberOfRemixersLabel.hidden = NO;
        if (remixers == 1){
            photoCardCell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodler",(long)remixers];
        }else{
            photoCardCell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodlers",(long)remixers];
        }
    }
    
    if (photoCardCell.photoCardImage.image != nil) {
        selectedPhoto = photoCardCell.photoCardImage.image;
    }
    
    
    DLog(@"Footer view: %@\n Cell frame: %@",NSStringFromCGRect(photoCardCell.photoCardFooterView.frame),NSStringFromCGRect(photoCardCell.contentView.frame));
    
    
    return photoCardCell;
}


- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionHeader){
       
       PhotoStreamHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PhotoStreamHeader" forIndexPath:indexPath];
        
        
        if (isFiltered) {
            NSString *sortText = [NSString stringWithFormat:@"SHOWING PHOTOS BY %@",selectedPicTaker[@"pictureTaker"]];
            headerView.sortStreamFilterLabel.text = sortText.uppercaseString;
        }else headerView.sortStreamFilterLabel.text = @"SHOWING ALL PHOTOS";
        
        if (self.spotInfo) {
            
            int numberOfPhotos = [self.spotInfo[@"photos"] intValue];
            
            headerView.streamNameLabel.text = self.spotInfo[@"spotName"];
            headerView.streamLocationLabel.text = ((NSString *)self.spotInfo[@"venue"]).uppercaseString;
            headerView.timeCreatedLabel.text = self.spotInfo[@"timestamp"];
            headerView.numberOfPhotosLabel.text = self.spotInfo[@"photos"];
            
            if (numberOfPhotos == 1) {
                headerView.photosLabel.text = @"PHOTO";
            }else {
                headerView.photosLabel.text = @"PHOTOS";
            }
            
            if (self.spotInfo[@"members"]){
                if ([self.spotInfo[@"members"] isKindOfClass:[NSArray class]]) {
                    NSArray *members = self.spotInfo[@"members"];
                    //DLog(@"Stream members are %i",[members count]);
                    if ([members count] == 1) {
                        headerView.membersLabel.text = @"MEMBER";
                    }else if ([members count] > 1){
                        headerView.membersLabel.text = @"MEMBERS";
                    }
                    
                    headerView.numberOfMembers.text = [NSString stringWithFormat:@"%lu",(unsigned long)[members count]];
                }else if ([self.spotInfo[@"members"] isKindOfClass:[NSString class]]){
                    int numOfMembers = [self.spotInfo[@"members"] intValue];
                    if (numOfMembers == 1) {
                        headerView.membersLabel.text = @"MEMBER";
                    }else{
                        headerView.membersLabel.text = @"MEMBERS";
                    }
                    
                    headerView.numberOfMembers.text = self.spotInfo[@"members"];
                }
            }
            
        }
        
        reusableview = headerView;
        
    }else if (kind == UICollectionElementKindSectionFooter) {
        PhotoStreamFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PhotoStreamFooter" forIndexPath:indexPath];
        
        footerView.emailTextField.alpha = 0;
        footerView.emailTextField.delegate = self;
        footerView.otherInviteOptionsButton.alpha = 0;
        reusableview = footerView;
    }
    return reusableview;
}



#pragma mark - UICollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   selectedPhotoIndexPath = indexPath;
}


#pragma mark - Methods
-(IBAction)showMembers:(id)sender
{
    [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:@{@"streamId" : self.spotID}];
}


- (IBAction)sharePhoto:(UIButton *)sender{
    
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    if (cell.photoCardImage.image != nil) {
        
        //DLog();
        [UIView animateWithDuration:0.2 animations:^{
            CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
            self.hiddenTopMenuView.frame = hiddenMenuFrame;
            self.hiddenTopMenuView.alpha = 0;
            
        } completion:^(BOOL finished) {
            
            selectedPhoto = cell.photoCardImage.image;
            // Actual code to share Share stream
            // Present Action Sheet
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share this photo via" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook",@"Twitter",@"Email", nil];
            
            actionSheet.tag = 3300;
            [actionSheet showInView:self.view];
        }];
        
        toggler += 1;
        
        //[self share:kPhoto Sender:sender];
    }else{
        [AppHelper showAlert:@"Share Image Request"
                     message:@"You can share image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
      }
}


-(void)likePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath
{
    [FBAppEvents logEvent:@"Photo_Liked"];
    
    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"1"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            [self resamplePhotoInfo:selectedPhotoInfo flag:@"YES" numberOfLikes:results[@"likes"] atIndex:indexPath.item];
            
            // Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            
            if ([results[@"likes"] integerValue] == 1){
                photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            }else if ([results[@"likes"] integerValue] > 1){
                photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            }
            
            [AppHelper showLikeImage:self.likeImage imageNamed:@"likeIcon_active"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                [UIView animateWithDuration:0.8 animations:^{
                    photoCardCell.likePhotoButton.alpha = 0;
                    [photoCardCell.likePhotoButton setSelected:YES];
                    photoCardCell.likePhotoButton.alpha = 1;
                }];
            });
        }
    }];
}


- (void)unlikePhotoWithID:(NSString *)photoId atIndexPath:(NSIndexPath *)indexPath
{
    [FBAppEvents logEvent:@"Photo_UnLiked"];

    PhotoStreamCell *photoCardCell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
    
    NSDictionary *selectedPhotoInfo = self.photos[indexPath.item];
    
    NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : photoId,@"updateFlag" :@"0"};
    
    [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
        
        if ([results[STATUS] isEqualToString:ALRIGHT]){
            
            [self resamplePhotoInfo:selectedPhotoInfo
                               flag:@"NO"
                      numberOfLikes:results[@"likes"]
                            atIndex:indexPath.item];
            
            //Ask main stream to reload
            [[NSNotificationCenter defaultCenter]
             postNotificationName:kUserReloadStreamNotification object:nil];
            if ([results[@"likes"] intValue] == 0) {
                photoCardCell.numberOfLikesLabel.hidden = YES;
            }else photoCardCell.numberOfLikesLabel.text = results[@"likes"];
            
            [AppHelper showLikeImage:self.likeImage imageNamed:@"unlike-button"];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(),^{
                [UIView animateWithDuration:0.8 animations:^{
                    photoCardCell.likePhotoButton.alpha = 0;
                    [photoCardCell.likePhotoButton setSelected:NO];
                    photoCardCell.likePhotoButton.alpha = 1;
                }];
            });
        }
    }];
}


- (IBAction)likePhoto:(id)sender
{
   
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_LIKE_PHOTOS;
        }];
    }else{
        
        UIButton *likeButtonAction = (UIButton *)sender;
        
        PhotoStreamCell *cell = (PhotoStreamCell *)likeButtonAction.superview.superview.superview;
        NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
        selectedPhotoIndexPath = indexPath;
        
        NSString *picId = self.photos[indexPath.item][@"id"];
        
        if (cell.likePhotoButton.state == UIControlStateNormal || cell.likePhotoButton.state == UIControlStateHighlighted)
        {
            //DLog(@"Setting selected");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                
                [cell.likePhotoButton setSelected:YES];
            });
            
            [self likePhotoWithID:picId atIndexPath:indexPath];
            
        }else{
            //DLog(@"Setting UnSelected");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10000), dispatch_get_main_queue(),^{
                
                [cell.likePhotoButton setSelected:NO];
            });
            
            [self unlikePhotoWithID:picId atIndexPath:indexPath];
        }
 
   }
}


/*-(void)updatePhotosNumberOfLikes:(NSMutableArray *)photos photoId:(NSString *)photoId update:(NSString *)likes
{
    NSMutableDictionary *guiltyPhoto = nil;
    NSInteger indexOfLikedPhoto = 0;
    for (NSDictionary *photo in photos) {
        if ([photo[@"id"] integerValue] == [photoId integerValue]){
            indexOfLikedPhoto = [photos indexOfObject:photo];
            DLog(@"Index of liked photo - %i",indexOfLikedPhoto);
            guiltyPhoto = [NSMutableDictionary dictionaryWithDictionary:photo];
            break;
        }
    }
    guiltyPhoto[@"id"] = likes;
    self.photos[indexOfLikedPhoto] = guiltyPhoto;
    DLog(@"Guilty photo - %@",self.photos[indexOfLikedPhoto]);
}*/



- (void)savePhoto:(UIImage *)imageToSave
{
    if([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
        
        [UIView animateWithDuration:.5 animations:^{
            self.createAccountView.alpha = 1;
            self.noActionLabel.text = CREATE_ACCOUNT_TO_SAVE_PHOTOS;
        }];
        
    }else{
        if (imageToSave != nil){
            [self savePhotoToCustomAlbum:imageToSave];
            
        }else{
            [AppHelper showAlert:@"Save Image Request"
                         message:@"You can save image after it loads"
                         buttons:@[@"OK, I'll wait"]
                        delegate:nil];
        }
    }
}


- (void)createStandardImage:(CGImageRef)image completon:(StandardPhotoCompletion)completion
{
    dispatch_queue_t createStandardPhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      dispatch_async(createStandardPhotoQueue, ^{
        
        const size_t width = CGImageGetWidth(image);
        const size_t height = CGImageGetHeight(image);
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, 8, 4*width, space,
                                                 kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst);
        CGColorSpaceRelease(space);
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image);
        CGImageRef dstImage = CGBitmapContextCreateImage(ctx);
        CGContextRelease(ctx);

        
        dispatch_async(dispatch_get_main_queue(),^{
            completion(dstImage,nil);
        });
    });

    //[UIImage alloc] in
}


/*- (void)resizePhoto:(UIImage*) image towidth:(float) width toHeight:(float) height completon:(PhotoResizedCompletion)completion
{
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         BOSImageResizeOperation* op = [[BOSImageResizeOperation alloc] initWithImage:image];
          [op start];
        
        UIImage* smallerImage = op.result;
        dispatch_async(dispatch_get_main_queue(),^{
            completion(smallerImage,nil);
        });
    });
}*/


- (IBAction)cameraButtonTapped:(id)sender
{
    [self showPhotoOptions];
}



-(void)showReportOptions
{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Why're you reporting photo?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@" This photo is sexually explicit",@"This photo is unrelated",nil];
    actionsheet.tag = 2000;
    [actionsheet showInView:self.view];
  
}


- (IBAction)showMoreActions:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = (isFiltered) ? filteredPhotos[indexpath.item] : self.photos[indexpath.item];
    selectedPhoto = cell.photoCardImage.image;
    
    @try {
        NSString *pictureTakerId = self.photos[indexpath.item][@"pictureTakerId"];
        
        if ([[AppHelper userID] isEqualToString:pictureTakerId]) {
            //DLog(@"Allow the user to delete photo because -%@ = %@",[AppHelper userName],pictureTaker);
            UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"More Actions"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Save Photo",@"Delete Photo",@"Report Photo", nil];
            actionsheet.tag = 5000;
            actionsheet.destructiveButtonIndex = 2;
            [actionsheet showInView:self.view];
            
        }else{
            UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"More Actions"
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Save Photo",@"Report Photo", nil];
            actionsheet.tag = 1000;
            actionsheet.destructiveButtonIndex = 1;
            [actionsheet showInView:self.view];
        }

    }
    @catch (NSException *exception) {}
    @finally {}
    
}



-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Add photos to this stream." delegate:self cancelButtonTitle:@"Not now" destructiveButtonTitle:nil otherButtonTitles:@"Take new photo",
                             @"Choose existing photo", nil];
    action.tag = 403;
    [action showInView:self.view];
}

-(void)resamplePhotoInfo:(NSDictionary *)info flag:(NSString *)flag numberOfLikes:(NSString *)likes atIndex:(NSInteger)selectedIndex
{
    [self.photos removeObjectAtIndex:selectedIndex];
    NSMutableDictionary *mutablePhotoInfo = [NSMutableDictionary dictionaryWithDictionary:info];
    
    mutablePhotoInfo[@"userLikedPhoto"] = flag;
    mutablePhotoInfo[@"likes"] = likes;
    
    [self.photos insertObject:mutablePhotoInfo atIndex:selectedIndex];

}


#pragma mark - Helpers for Social Media
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender
{
    NSArray *activityItems = nil;
    NSString *shareText = nil;
    
    if (objectOfInterest == kSpot){
        NSString *randomString = [self getRandomPINString:5];
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared photo stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.spotName,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        activityItems = @[self.albumSharePhoto,shareText];
        [FBAppEvents logEvent:@"Share_Stream_Tapped"];
        
    }else if (objectOfInterest == kPhoto){
        PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
        NSString *randomString = [self getRandomPINString:5];
        shareText = [NSString stringWithFormat:@"Check out this photo in my shared photo stream %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.spotName,[NSString stringWithFormat:@"%@%@",self.spotID,randomString]];
        
        if (cell.remixedImageView.alpha == 1) {
            activityItems = @[cell.remixedImageView.image,shareText];
        }else{
            activityItems = @[cell.photoCardImage.image,shareText];
        }
        
        [User updateUserStat:@"PHOTO_SHARED" completion:^(id results, NSError *error) {
            DLog(@"Response - %@",results);
        }];
        
        [FBAppEvents logEvent:@"Share_Photo_Tapped"];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll,UIActivityTypeAddToReadingList,UIActivityTypeAirDrop];
    
    activityVC.completionHandler = ^(NSString *activityType, BOOL completed){
        if (completed) {
            DLog(@"Completed with type: %@",activityType);
        }else{
            DLog(@"Dismissed");
        }
    };
    
    [self presentViewController:activityVC animated:YES completion:nil];
  
}





-(void)savePhotoToCustomAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba" completion:^(NSURL *assetURL, NSError *error) {
        [AppHelper showNotificationWithMessage:@"Image saved in camera roll" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
        
        [User updateUserStat:@"PHOTO_SAVED" completion:^(id results, NSError *error) {
            DLog(@"Response - %@",results);
        }];
        
        [FBAppEvents logEvent:@"Photo_Saved"];
        
    }failure:^(NSError *error){
        [AppHelper showAlert:@"Save image error"
                     message:@"There was an error saving the photo"
                     buttons:@[@"OK"]
                    delegate:nil];
    }];
}


/*- (void)pickAssets
{
    
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.navigationBar.translucent = NO;
    picker.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    //picker.navigationItem.rightBarButtonItem. = [UIColor whiteColor];
    picker.showsCancelButton = YES;
    //picker.navigationBar.barTintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                                     //green:(77.0f/255.0f)
                                                      //blue:(20.0f/255.0f)
                                                     //alpha:1];
    picker.maximumNumberOfSelection = 10;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Assets Picker Delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    //[self.assets addObjectsFromArray:assets];
    if ([assets count] == 1) {
        ALAsset *asset = (ALAsset *)assets[0];
        ALAssetRepresentation *representation = asset.defaultRepresentation;
        UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage
                                                           scale:1.0f
                                                     orientation:(UIImageOrientation)ALAssetOrientationUp];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
        
        //640.0f X 852.0f
        [self resizePhoto:fullResolutionImage towidth:1136.0f toHeight:640.0f completon:^(UIImage *compressedPhoto, NSError *error) {
            NSData *imageData = UIImageJPEGRepresentation(compressedPhoto, 1.0);
           // DLog(@"Size of image - %fKB",(unsigned long)[imageData length]/1000.0f);
            [self uploadPhoto:imageData WithName:trimmedString];
        }];
        
           }else if([assets count] > 1){ // User selected more than one photo
        [self uploadPhotos:assets];
    }else if([assets count] == 0){
        [AppHelper showAlert:@"Add Photo"
                     message:@"You did not select a photo to add to the stream"
                     buttons:@[@"OK"] delegate:nil];
    }
    
}*/



-(void)pickImage:(id)sender
{
    //DLog(@"Source Type - %@",sender);
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        if ([sender intValue] == kTakeCamera) {
            //[self openDBCamera];
            [self openNativeCamera:UIImagePickerControllerSourceTypeCamera];
        }else if ([sender intValue] == kGallery){
            [self openNativeCamera:UIImagePickerControllerSourceTypePhotoLibrary];
        }
       
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}


- (IBAction)moveToProfile:(UIButton *)sender
{
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
            [UIView animateWithDuration:.5 animations:^{
                self.createAccountView.hidden = NO;
                self.noActionLabel.text = CREATE_ACCOUNT_TO_SEE_PROFILE;
                //self.navigationController.navigationBarHidden = YES;
            }];
    }else{
        PhotoStreamCell *pCell = (PhotoStreamCell *)sender.superview.superview.superview;
        NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:pCell];
        NSDictionary *cellInfo = self.photos[indexPath.item];
        NSString *picTakerId = cellInfo[@"pictureTakerId"];
        
        DLog(@"We are going to %@ with ID - %@",cellInfo,picTakerId);
        
        [self performSegueWithIdentifier:@"PHOTOSTREAM_USERPROFILE" sender:cellInfo];
    }
}


#pragma mark - UIAlertView Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 400){
        if (buttonIndex == 1) {
            // Retry image upload now
            DLog(@"Retrying image upload");
            if (imageToUpload && nameOfImageToUpload) {
                [self uploadPhoto:imageToUpload WithName:nameOfImageToUpload];
            }
            
        }
    }else if (alertView.tag == 401){
     // Reload stream images
        if (buttonIndex == 1){
            
            DLog(@"Reloading stream");
            [self loadSpotImages:self.spotID];
        }
    }else if(alertView.tag == 3000){
        if (buttonIndex == 1) {
            NSInteger index = [self.photos indexOfObject:self.photoInView];
            [self deletePhotoAtIndexFromStream:index];
        }
    }else if (alertView.tag == 201){
        if (buttonIndex == 1) {
           [self showPhotoOptions];
        }
    }
}


#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Get branch link to share this stream
    
    if (actionSheet.tag == 3300) {
        
        [self sharePhotoWithButtonIndexSelected:buttonIndex photo:selectedPhoto];
        
        
    }else if(actionSheet.tag == 7000){
        
        [self shareStreamWithButtonIndexOptionSelected:buttonIndex];
        
                
    }else if (actionSheet.tag == 5000){
        
        if(buttonIndex == 0){
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]){
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_SAVE_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
                
            }else{
                //User wants to save photo
                [self savePhoto:selectedPhoto];
            }
            
        }else if (buttonIndex == 1){
            
            
            UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:@"Delete Photo" message:@"Are you sure you want to delete this photo?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
            deleteAlert.tag = 3000;
            [deleteAlert show];
        }
        
    }else if (actionSheet.tag == 1000){
        if(buttonIndex == 0){
                //User wants to save photo
            [self savePhoto:selectedPhoto];
        }
        
    }else if(actionSheet.tag == 2000){
        
        
            // User is reporting a photo
            NSString *reportType = nil;
            if (buttonIndex == kSexuallyExplicit){
                reportType = kSEXUALLY_EXPLICIT;
            }else{
                reportType = kUNRELATED_PHOTO;
            }
            
            NSDictionary *params = @{
                                     @"photoId":self.photoInView[@"id"],
                                     @"spotId" : self.spotID,
                                     @"pictureTakerName" : self.photoInView[@"pictureTaker"],
                                     @"reporterId" : [AppHelper userID],
                                     @"reportType" : reportType
                                     };
            
            
            [self reportPhoto:params];
      
    }else if(actionSheet.tag == 403){
    
    if (buttonIndex == kTakeCamera){
        // Call the Camera here
        //DLog(@"Calling camera");
        //[self pickPhoto:kTakeCamera];
        [self performSelector:@selector(pickImage:) withObject:@(kTakeCamera) afterDelay:0.5];
    }else if (buttonIndex == kGallery){
        // Choose from the Gallery
        //DLog(@"Using the assets picker");
        //[self pickPhoto:kGallery];
        [self performSelector:@selector(pickImage:) withObject:@(kGallery) afterDelay:0.5];
    }
}
    //NSLog(@"Button Clicked is %li",(long)buttonIndex);
    //[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
}


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1000){
        if (buttonIndex == 1) {
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_REPORT_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
            }else{
                [self showReportOptions];
            }
        }
    }else if (actionSheet.tag == 5000){
        if (buttonIndex == 2) {
            
            if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
                [UIView animateWithDuration:.5 animations:^{
                    self.createAccountView.alpha = 1;
                    self.noActionLabel.text = CREATE_ACCOUNT_TO_REPORT_PHOTOS;
                    //self.navigationController.navigationBarHidden = YES;
                }];
            }else{
                [self showReportOptions];
            }
        }
    }
}


#pragma mark - UIImagePickerController Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    DLog(@"");
    
    [FBAppEvents logEvent:@"Photo_Taken"];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    DLog(@"UIImagePickerInfo: %@",[info debugDescription]);
    if (info[UIImagePickerControllerMediaMetadata]) {
        NSMutableDictionary *imageMetaData = info[UIImagePickerControllerMediaMetadata];
        //DLog(@"UIImagePickerControllerMediaMetadata: %@",info[UIImagePickerControllerMediaMetadata]);
        
        [self.library writeImageToSavedPhotosAlbum:image.CGImage metadata:imageMetaData completionBlock:^(NSURL *assetURL, NSError *error) {
            if (!error) {
                DLog(@"Image saved in - %@",assetURL.description);
                uploadingImageAssetURL = assetURL;
            }else{
                DLog(@"Error - %@",error);
            }
            
        }];
    }else if(info[UIImagePickerControllerReferenceURL]){
       uploadingImageAssetURL = info[UIImagePickerControllerReferenceURL];
    }
    
    NSData *img = UIImageJPEGRepresentation(image, 1.0);
    
    DLog(@"Size of image - %fKB",[img length]/1024.0f);
    [picker dismissViewControllerAnimated:YES completion:^{
        //DLog(@"Lets display aviary");
        [self displayEditorForImage:image];
    }];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
}



-(void)uploadPhotos:(NSArray *)assets
{
    @try {
        NSMutableArray *imagesData = [NSMutableArray arrayWithCapacity:2];
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        
        NSString *urlPath = [[NSURL URLWithString:kUPLOAD_PHOTOS_PATH relativeToURL:baseURL] absoluteString];
        __block NSMutableURLRequest *request = nil;
        
        for (ALAsset *asset in assets){
            ALAssetRepresentation *representation = asset.defaultRepresentation;
            UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage
                                                               scale:1.0f
                                                         orientation:(UIImageOrientation)ALAssetOrientationUp];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
            NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
            NSString *name = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
            name = [name stringByReplacingOccurrencesOfString:@"-" withString:@":"];
            name = [name stringByReplacingCharactersInRange:NSMakeRange([name length]-7, 7) withString:@""];
            
            [imagesData addObject:@{@"imageData": fullResolutionImage, @"imageName" : name}];
            
        }
        
        
        /*Upload photo. New way*/
        NSProgress *progress = nil;
        request = [manager.requestSerializer
                   multipartFormRequestWithMethod:kHTTP_METHOD_POST
                   URLString:urlPath
                   parameters:params
                   constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                       for (NSDictionary *imageInfo in imagesData){
                           //DLog(@"Images being resized");
                           
                           //[self resizePhoto:imageInfo[@"imageData"] towidth:640.0f toHeight:852.0f
                           //      completon:^(UIImage *compressedPhoto, NSError *error){
                           //DLog(@"Does it even get here - %@",imageInfo[@"imageName"]);
                           NSData *imageData = UIImageJPEGRepresentation(imageInfo[@"imageData"], .8);
                           [formData appendPartWithFileData:imageData name:imageInfo[@"imageName"] fileName:[NSString stringWithFormat:@"%@.jpg",imageInfo[@"imageName"]] mimeType:@"image/jpeg"];
                           //}];
                       }

        } error:nil];
        
        NSURLSessionUploadTask *uploadTask = [manager uploadTaskWithStreamedRequest:request progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error){
            if (error) {
                // Handle error here. Your photo failed to upload. Will you like to upload again
            }else{
                
                // Photos were uploaded successfully
                DLog(@"Image upload response");
                NSDictionary *photoInfo =  responseObject;
                if ([photoInfo[STATUS] isEqualToString:ALRIGHT]) {
                    [FBAppEvents logEvent:@"Photo_Upload"];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:kUserReloadStreamNotification object:nil];
                    
                    self.noPhotosView.hidden = YES;
                    self.photoCollectionView.hidden = NO;
                    if (!self.photos) {
                        
                        self.photos = [NSMutableArray arrayWithArray:photoInfo[@"photos"]];
                    }else{
                        //[self.photos insertObject:photoInfo atIndex:0];
                        [self.photos insertObjects:photoInfo[@"photos"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [photoInfo[@"photos"] count])]];
                        DLog(@"Photos Uploaded - %@",photoInfo);
                    }
                    
                    [self upDateCollectionViewWithCapturedPhotos:photoInfo[@"photos"]];
                    
                }
            }
        }];
        
        
        [uploadTask resume];
        
        
    }@catch (NSException *exception) {
        [self uploadingPhotoView:NO];
        [AppHelper showAlert:@"Oops!" message:@"We encountered a problem uploading your photo" buttons:@[@"Try Again?"] delegate:nil];
        
        [Flurry logError:@"Photo Upload Error" message:[exception name] exception:exception];
    }
    @finally {
        [self uploadingPhotoView:NO];
    }
}


-(void)uploadDoodle:(NSData *)imageData WithName:(NSString *)name
{
    @try {
        
       // [self uploadingPhotoView:YES];
        
        //DLog(@"Selected photo ID = %@",self.photos[selectedPhotoIndexPath.item][@"id"]);
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId,@"originalPhotoURL" : name,@"photoId": self.photos[selectedPhotoIndexPath.item][@"id"]};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        
        NSString *urlPath = [[NSURL URLWithString:@"spot/picture/doodle" relativeToURL:baseURL] absoluteString];
        
        NSMutableURLRequest *request = [manager.requestSerializer
                                        multipartFormRequestWithMethod:@"POST"
                                        URLString:urlPath
                                        parameters:params
                                        constructingBodyWithBlock:^(id<AFMultipartFormData> formData){
                                            [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
                                            
                                        } error:nil];
        
         [manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
         AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        self.imageUploadProgressView.hidden = NO;
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
            
            // Anything can happen here so lets just catch the exception
            
            @try{
                
                self.imageUploadProgressView.progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
                
                if(self.imageUploadProgressView.progress == 1.0f){
                    
                    didImageFinishUploading = YES;
                    
                    self.imageUploadProgressView.hidden = YES; // or remove from superview
                    
                }
                
            }@catch(NSException *exception){}
            
        }];
        
        
       [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
           //[self uploadingPhotoView:NO];
           NSError *error = nil;
           NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
           
           [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
           
           PhotoStreamCell *cell = nil;
           for (NSDictionary *photo in self.photos){
               
               if([photoInfo[@"id"] integerValue] ==  [photo[@"id"] integerValue]){
                   
                   // Lets replace this NSDictionary coz this object is the photo that was doodled
                   NSUInteger indexOfOriginalPhoto = [self.photos indexOfObject:photo];
                   NSIndexPath *indexPath = [NSIndexPath indexPathForItem:indexOfOriginalPhoto inSection:0];
                   cell = (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
                   
                   [self.photos replaceObjectAtIndex:indexOfOriginalPhoto withObject:photoInfo];
                   
                   break;
               }
           }
           
           //DLog(@"Photo Info - %@",photoInfo);
           [FBAppEvents logEvent:@"Photo_Doodled"];
           if (cell != nil) {
               
               //cell.showCommentsActionButton.hidden = NO;
               
               [self showDoodleVersionOfPhotoInCell:cell completion:^(BOOL didFlipDoodle) {
                   //[self.photoCollectionView reloadItemsAtIndexPaths:@[[self.photoCollectionView indexPathForCell:cell]]];
                   //cell.commentsIcon.enabled = YES;
                   //cell.commentsIcon.hidden = NO;
                   //cell.showCommentsActionButton.hidden = NO;
                   cell.remixedImageView.alpha = 1;
                   cell.numberOfRemixersLabel.hidden = NO;
                   cell.viewDoodleContainer.hidden = NO;
                   NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
                  NSInteger remixers = [self.photos[indexPath.item][@"remixers"] integerValue];
                   if (remixers == 1){
                       cell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodler",(long)remixers];
                   }else{
                       cell.numberOfRemixersLabel.text = [NSString stringWithFormat:@"%li Doodlers",(long)remixers];
                   }

               }];
               
           }else{
               DLog(@"Lust reload the data==");
               [self.photoCollectionView reloadData];
           }
           if (isDoodling) {
               isDoodling = NO;
           }
       } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
           DLog(@"Error serializing %@", error);
           [AppHelper showAlert:@"Oops!"
                        message:@"Something went wrong. Try again?"
                        buttons:@[@"OK"] delegate:nil];

       }];
        
         [[NSOperationQueue mainQueue] addOperation:operation];
        
    }
    @catch (NSException *exception) {
        [self uploadingPhotoView:NO];
        [AppHelper showAlert:@"Oops!" message:@"We encountered a problem uploading your photo" buttons:@[@"Try Again?"] delegate:nil];
        
        [Flurry logError:@"Doodle Upload Error" message:[exception name] exception:exception];
    }
    @finally {
        [self uploadingPhotoView:NO];
    }
}





-(void)uploadPhoto:(NSData *)imageData WithName:(NSString *)name
{
    // Here we animate the stream to the beginning and then start uploading the photo
    // prepare
    
    @try{
        NSString *userId = [User currentlyActiveUser].userID;
        NSString *spotId = self.spotID;
        NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
        AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
        NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
        NSString *urlPath = [[NSURL URLWithString:kUPLOAD_PHOTO_PATH relativeToURL:baseURL] absoluteString];
        
        NSMutableURLRequest *request = [manager.requestSerializer multipartFormRequestWithMethod:kHTTP_METHOD_POST URLString:urlPath parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
            [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
        } error:nil];
        
        [manager.requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        self.imageUploadProgressView.hidden = NO;
        
        [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite){
            // Anything can happen here so lets just catch the exception
            @try{
                self.imageUploadProgressView.progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
                
                /*MBProgressHUD *imageUploadHUD = [MBProgressHUD showHUDAddedTo:selectedPhotoCell.photoCardImage animated:YES];
                imageUploadHUD.progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
                
                MRProgressOverlayView *imageUploadHUD = [MRProgressOverlayView showOverlayAddedTo:selectedPhotoCell.photoCardImage title:@"Uploading photo..." mode:MRProgressOverlayViewModeDeterminateHorizontalBar animated:NO];
               
                //DLog(@"imageUploadHUD frame: %@",NSStringFromCGRect(imageUploadHUD.frame));
                //imageUploadHUD setFrame:<#(CGRect)#>
                
                [imageUploadHUD setProgress:(float)totalBytesWritten/totalBytesExpectedToWrite
                                              animated:NO];*/
                
                if(self.imageUploadProgressView.progress == 1.0f){
                    didImageFinishUploading = YES;
                    self.imageUploadProgressView.hidden = YES; // or remove from superview
                    //[imageUploadHUD removeFromSuperview];
                    
                    /*[MRProgressOverlayView showOverlayAddedTo:selectedPhotoCell.photoCardImage title:@"Success" mode:MRProgressOverlayViewModeCheckmark animated:YES];*/
                    
                }
            }@catch(NSException *exception){}
        }];
        
        
        
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation,id responseObject){
            NSError *error = nil;
             if (responseObject != nil){
                 imageToUpload = nil;
                 nameOfImageToUpload = nil;
                 
                 NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingAllowFragments error:&error];
                 
                     DLog(@"Photo info: %@\nSerialized response: %@",photoInfo,operation.response.allHeaderFields[@"x-suba-status-code"]);
                 
                     [FBAppEvents logEvent:@"Photo_Upload"];
                     [[NSNotificationCenter defaultCenter]
                      postNotificationName:kUserReloadStreamNotification object:nil];
                     
                     self.noPhotosView.hidden = YES;
                     self.photoCollectionView.hidden = NO;
                 
                     if (!self.photos){
                         self.photos = [NSMutableArray arrayWithObject:photoInfo];
                     }else{
                         [self.photos replaceObjectAtIndex:0 withObject:photoInfo];
                     }
                 
                     [self upDateCollectionViewWithCapturedPhoto:photoInfo];
                }

         
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            
            DLog(@"Operation.response: %@",operation.response.allHeaderFields[@"x-suba-status-code"]);
            
            NSString *subaStatusCode = operation.response.allHeaderFields[@"x-suba-status-code"];
            if ([subaStatusCode isEqualToString:kFAILED_UPLOAD]){
                // Image was not uploaded so retry upload
                UIAlertView *failedUploadAlertView = [[UIAlertView alloc] initWithTitle:@"Retry Upload" message:@"There was a problem uploading your photo. Check your internet connection and upload again" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Retry", nil];
                
                failedUploadAlertView.tag = 400;
                [failedUploadAlertView show];
                
            }else if ([subaStatusCode isEqualToString:kRELOAD_STREAM_IMAGES]){
                // Image was uploaded so reload stream
                UIAlertView *failedUploadAlertView = [[UIAlertView alloc] initWithTitle:@"Reload Stream" message:@"Your image was uploaded but we could not update your stream.Hit reload stream to update the stream with the new photo." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reload Stream", nil];
                failedUploadAlertView.tag = 401;
                [failedUploadAlertView show];
            }
        }];
    
        [[NSOperationQueue mainQueue] addOperation:operation];
    }
    
    @catch (NSException *exception){
        
        [AppHelper showAlert:@"Oops!"
                     message:@"We encountered a problem uploading your photo"
                     buttons:@[@"Try Again"]
                    delegate:nil];
        
        [Flurry logError:@"Photo Upload Error" message:[exception name] exception:exception];
    }
}


-(void)upDateCollectionViewWithCapturedPhoto:(NSDictionary *)photoInfo{
    
    
    [self.photoCollectionView reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0]]];
    
       /* [self.photoCollectionView performBatchUpdates:^{
            @try {
            [self.photoCollectionView
             insertItemsAtIndexPaths:@[
                                       [NSIndexPath indexPathForItem:0 inSection:0]]];
                
            [self.photoCollectionView ]
            }@catch (NSException *exception) {
                // What to do when we have an exception
            }
        } completion:^(BOOL finished){
            @try{
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            }@catch (NSException *exception) {
                // What to do when we have an exception
            }
        }];*/
}


-(void)upDateCollectionViewWithCapturedPhotos:(NSArray *)photoInfo{
    
        [self uploadingPhotoView:NO];
        NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:2];
        for (int x = 0; x < [photoInfo count]; x++) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:x inSection:0]];
        }
        
        [self.photoCollectionView performBatchUpdates:^{
            @try {
            [self.photoCollectionView insertItemsAtIndexPaths:indexPaths];
                 }@catch (NSException *exception) {[self uploadingPhotoView:NO];}
        } completion:^(BOOL finished) {
            @try{
            [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            
             }@catch (NSException *exception) {[self uploadingPhotoView:NO];}
        }];
        
          
       
}

- (IBAction)doFacebookLogin:(id)sender
{
    [self.facebookLoginIndicator startAnimating];
    
    [AppHelper openFBSession:^(id results, NSError *error) {
        [AppHelper setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
        [FBAppEvents logEvent:@"Account_Confirmed_Facebook"];
        [self.facebookLoginIndicator stopAnimating];
        [self performSelector:@selector(dismissCreateAccountPopUp)];
        if ([pendingActions count] > 0) {
            int pAction = [[pendingActions lastObject] intValue];
            [self executePendingAction:pAction];
        }
    }];
}



#pragma mark - Segues
-(void)unWindToPhotoStream:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[PhotoTakersViewController class]]){
        if ([segue.identifier isEqualToString:@"PhotoTakerSelectedSegue"]){
            
            PhotoTakersViewController *pvc = segue.sourceViewController;
            if (pvc.selectedPhotoTaker){
                selectedPicTaker = pvc.selectedPhotoTaker;
                [self showPhotosTakenByMemberWithId:pvc.selectedPhotoTaker[@"pictureTakerId"]];
            }else{
                // User wants to see all photos
                [self showAllPhotos];
            }
        }
    }
}


-(void)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue
{
    StreamSettingsViewController *albumVC = segue.sourceViewController;
    self.navItemTitle.text = albumVC.spotName;

    /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
               size:10.0f color:[UIColor whiteColor] sizeToFit:NO];*/
    
    [self.navItemTitle sizeToFit];
}

- (IBAction)addFirstPhotoButtonTapped:(UIButton *)sender
{
    [self showPhotoOptions];
    //[self performSelector:@selector(pickImage:) withObject:@(kTakeCamera) afterDelay:0.5];
}

- (IBAction)registerForPushNotification:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDidSignUpNotification object:nil];
    [self performSelector:@selector(dismissNotificationScreen:) withObject:nil afterDelay:0.5];
}

- (IBAction)remixPhoto:(UIControl *)sender
{
    // Remix Photo
    isDoodling = YES;
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    selectedPhotoCell = cell;
    [self doodlePhoto:cell];
    
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FullScreenPhotoBrowserSegue"]){
        if ([segue.destinationViewController isKindOfClass:[PhotoBrowserViewController class]]) {
            // Set delegate for custom View controller Transition
            PhotoBrowserViewController *fullScreenBrowser = segue.destinationViewController;
            fullScreenBrowser.transitioningDelegate = self;
            fullScreenBrowser.modalPresentationStyle = UIModalPresentationCustom;
        }
    }else if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[StreamSettingsViewController class]]) {
            StreamSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
            albumVC.spotInfo = self.spotInfo;
            
            albumVC.whereToUnwind = [self.parentViewController childViewControllers][0];
        }
    }else if ([segue.identifier isEqualToString:@"AlbumMembersSegue"]){
        if ([segue.destinationViewController isKindOfClass:[AlbumMembersViewController class]]){
            AlbumMembersViewController *membersVC = segue.destinationViewController;
            if ([sender isKindOfClass:[NSDictionary class]]) {
                membersVC.shouldShowMembers = YES;
                membersVC.spotID = sender[@"streamId"];
            }else{
               membersVC.spotID = sender;
            }
            
            membersVC.spotInfo = self.spotInfo;
        }
    }else if ([segue.identifier isEqualToString:@"PHOTOSTREAM_USERPROFILE"]){
        UserProfileViewController *uVC = segue.destinationViewController;
        DLog(@"Sender UserId - %@",sender[@"pictureTakerId"]);
        uVC.userId = sender[@"pictureTakerId"];
    }else if ([segue.identifier isEqualToString:@"InviteFriendsSegue"]) {
            InvitesViewController *iVC = segue.destinationViewController;
            iVC.spotToInviteUserTo = self.spotInfo;
    }else if ([segue.identifier isEqualToString:@"PhotoToEmailInvitesSegue"]){
        EmailInvitesViewController *emailVC = segue.destinationViewController;
        emailVC.streamId = sender;
    }else if ([segue.identifier isEqualToString:@"DoodleSegue"]){
        SBDoodleViewController *doodleVC = segue.destinationViewController;
        doodleVC.imageToRemix = (UIImage *)sender;
        NSString *remixURL =self.photos[selectedPhotoIndexPath.item][@"s3RemixName"];
        doodleVC.imageToRemixURL = remixURL;
        doodleVC.remixImageID = [self.photoInView[@"id"] integerValue];
        
    }else if ([segue.identifier isEqualToString:@"CommentsSegue"]){
        CommentsViewController *commentsVC = segue.destinationViewController;
        
        commentsVC.photoId = self.photoInView[@"id"];
        //DLog(@"Comments %ld",(long)selectedPhotoIndexPath.row);
        commentsVC.comments = [self.photoInView[@"photoComments"] mutableCopy];
    }else if ([segue.identifier isEqualToString:@"PhotoTakersSegue"]){
        PhotoTakersViewController *pvc = segue.destinationViewController;
        pvc.phototakers = [self photoTakers];
    }
}



#pragma mark - handle gesture recognizer
- (void)photoCardTapped:(UITapGestureRecognizer *)sender
{
    
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        PhotoStreamCell *photoCardCell = (PhotoStreamCell *)sender.view.superview.superview;
        selectedPhotoCell = photoCardCell;
        NSInteger index = [self.photoCollectionView indexPathForCell:photoCardCell].item;
        
        NSDictionary *selectedPhotoInfo = nil;
        if (isFiltered) {
            selectedPhotoInfo = filteredPhotos[index];
        }else{
            selectedPhotoInfo = self.photos[index];
        }
        
            if (photoCardCell.photoCardImage.alpha == 1) {
                if(photoCardCell.photoCardImage.image){
                    
                    if(isFiltered){
                        mwPhotos = [self prepareMWPhotos:filteredPhotos];
                    }else{
                        mwPhotos = [self prepareMWPhotos:self.photos];
                    }
                    
                    // Call MWPhotoBrowser here
                    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
                    browser.displayActionButton = NO;
                    browser.displayNavArrows = NO;
                    browser.zoomPhotosToFill = NO;
                    browser.enableSwipeToDismiss = YES;
                    [browser setCurrentPhotoIndex:[self.photoCollectionView indexPathForCell:photoCardCell].item];
                    
                    // Modal
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
                    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    [self presentViewController:nc animated:YES completion:nil];
                
                }
            }else if (photoCardCell.remixedImageView.alpha == 1) {
                // If the doodle is showing
                //if (photoCardCell.remixedImageView.image){
                    DLog(@"Doodle is showing");
                    mwPhotos = [self prepareMWPhotos:[NSMutableArray arrayWithObject:selectedPhotoInfo]];
                    
                    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
                    browser.displayActionButton = NO;
                    browser.displayNavArrows = NO;
                    browser.zoomPhotosToFill = NO;
                    browser.enableSwipeToDismiss = YES;
                    
                    [browser setCurrentPhotoIndex:[self.photoCollectionView indexPathForCell:photoCardCell].item];
                    
                    // Modal
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
                    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
                    [self presentViewController:nc animated:YES completion:nil];
                    
                }
            //}
        }
     
}


/*- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.cameraButton.alpha = 0.2;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.cameraButton.alpha = 0.2;
}


-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
 
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    // Has the user scrolled more than half of the photo currently in view
    // Get the  x content offset (Since we're doing horizontal scrolling)
    // The scale factor tells us the index of the image being viewed
    
    //CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = scrollView.frame.origin.y;
    //int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    //int page = 300.0f;
    //[scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:NO];
    
    //DLog(@"Y-POS - %f",scrollView.frame.origin.y);
    [UIView animateWithDuration:.3
                     animations:^{
                         self.cameraButton.alpha = 1;
                     }];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
   // CGFloat xpos = self.photoCollectionView.contentOffset.x;
    //CGFloat ypos = self.photoCollectionView.frame.origin.y;
    //int multiFactor = (int)floorf(self.photoCollectionView.contentOffset.x/300.0);
    
    [self scrollToCorrect:scrollView];
}


-(void)scrollToCorrect:(UIScrollView*)scrollView
{
    CGFloat xpos = self.photoCollectionView.contentOffset.x;
    int multiFactor = (int) floorf(self.photoCollectionView.contentOffset.x/285.0);
    int quotient = (int)(xpos/285.0);
    
    int step = 310 * quotient;
    
    int lag = xpos - step;
    
    if (lag <= 143) {
        // Move to the next image
        multiFactor = quotient;
        
    }else multiFactor = quotient + 1;
    
    int page = 285.0f;
    
    DLog(@"\nCONTENT OFFSET - %@\n MULTIPLICATION FACTOR - %i\nNew offset - %i\n",
         NSStringFromCGPoint(self.photoCollectionView.contentOffset),multiFactor,multiFactor*page);
    
    [scrollView setContentOffset:CGPointMake(multiFactor*page,0) animated:YES];
}*/




#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    [coder encodeObject:self.spotName forKey:SpotNameKey];
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.photos forKey:SpotPhotosKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.spotInfo = [coder decodeObjectForKey:SpotInfoKey];
    self.spotName = [coder decodeObjectForKey:SpotNameKey];
    self.spotID = [coder decodeObjectForKey:SpotIdKey];
    self.photos = [coder decodeObjectForKey:SpotPhotosKey];
}

-(void)applicationFinishedRestoringState
{
    
    [self loadSpotInfo:self.spotID];
    //1. Update photos
    if (self.photos) {
        [self.photoCollectionView reloadData];
    }
    
    if (self.spotID){
        DLog(@"SpotId");
        [self loadSpotImages:self.spotID];
    }
    
    if (self.spotName){
        DLog(@"SpotId");
        self.navItemTitle.text = self.spotName;
        /*[IonIcons label:self.navItemTitle setIcon:icon_arrow_down_b
                   size:10.0f color:[UIColor whiteColor] sizeToFit:NO];*/
        
        [self.navItemTitle sizeToFit];
    }
    
    //2. If spotInfo is nil,loadspotInfo
    if (self.spotID && !self.spotInfo) {
        [self loadSpotInfo:self.spotID];
    }
    
  
}


-(void)showGivePushNotificationScreen
{
    if ([AppHelper numberOfPhotoStreamEntries] % 10 == 0) {
        [UIView animateWithDuration:.2 animations:^{
            self.firstTimeNotificationScreen.alpha = 1;
        }];
    }
    
}


- (IBAction)dismissNotificationScreen:(id)sender
{
    [UIView animateWithDuration:.2 animations:^{
        self.firstTimeNotificationScreen.alpha = 0;
        //self.navigationController.navigationBarHidden = NO;
        //[self.firstTimeNotificationScreen removeFromSuperview];
    }];
    
}



#pragma mark - MFMessageComposeViewControllerDelegate
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    
      switch (result)
    {
        case MessageComposeResultCancelled:
            DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"SMS_Invite_Cancelled"];
            break;
        case MessageComposeResultSent:
            DLog(@"SMS sent");
            [FBAppEvents logEvent:@"SMS_Invite_Sent"];
            break;
        case MessageComposeResultFailed:
            //DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"SMS_Invite_Failed"];
            break;
        default:
            DLog(@"SMS not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
}



#pragma mark - MFMailComposeViewController
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            //DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"Email_Share_Cancelled"];
            break;
        case MFMailComposeResultSent:
            //DLog(@"SMS sent");
            [FBAppEvents logEvent:@"Email_Share_Sent"];
            break;
        case MFMailComposeResultFailed:
            //DLog(@"SMS sending failed");
            [FBAppEvents logEvent:@"Email_Share_Failed"];
            break;
        default:
            DLog(@"Email not sent");
            break;
    }
    
    [controller dismissViewControllerAnimated:YES completion:nil];
    
    [[UINavigationBar appearance] setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
}




#pragma mark - Send SMS
-(void)sendSMSToRecipients:(NSMutableArray *)recipients
{
    @try {
        NSString *senderName = nil;
        if ([MFMessageComposeViewController canSendText]){
            
            MFMessageComposeViewController *smsComposer = [[MFMessageComposeViewController alloc] init];
            
            smsComposer.messageComposeDelegate = self;
            smsComposer.recipients = recipients;
           
            if(branchURLforInviteToStream &&
           [    branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

                // We already have the branch URL set up
                //DLog(@"Branch URL is already set up");
                smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo album on Suba: %@",self.spotInfo[@"spotName"],branchURLforInviteToStream];
                
                [smsComposer.navigationBar setTranslucent:NO];
                
                if (!self.presentedViewController){
                    [self presentViewController:smsComposer animated:YES completion:nil];
                }
                
            }else{
                
                Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                
                senderName = [AppHelper userName];
            }
            
            
            DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            NSDictionary *dict = @{
                                   @"$always_deeplink" : @"true",
                                   @"$desktop_url" : @"http://app.subaapp.com/streams/invite",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"numberOfPhotos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]
                                   };
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            
            [branch getShortURLWithParams:streamDetails andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE
                              andCallback:^(NSString *url,NSError *error){
                                  if (!error) {
                                      branchURLforInviteToStream = url;
                                      DLog(@"URL from Branch: %@",url);
                                      smsComposer.body = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURLforInviteToStream];
                                      
                                      [smsComposer.navigationBar setTranslucent:NO];
                                      
                                      if (!self.presentedViewController){
                                          [self presentViewController:smsComposer animated:YES completion:nil];
                                      }
                                      
                                  }else DLog(@"Branch error: %@",error.debugDescription);
                                  
            }];
            
        }
            
        }else{
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Text Message Failure"
                                  message:
                                  @"Your device doesn't support in-app sms"
                                  delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }

    }
    @catch (NSException *exception) {
        DLog(@"exception name: %@\nexception reason: %@\nException info: %@",exception.name,exception.reason,[exception.userInfo debugDescription]);
        
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Oops:)"
                              message:
                              @"Something went wrong.Please try again."
                              delegate:nil cancelButtonTitle:@"Try again" otherButtonTitles:nil];
        [alert show];
    }
}


- (IBAction)invitePeopleByEmail:(UIButton *)sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
        mailComposer.mailComposeDelegate = self;
        
        [mailComposer.navigationBar setTranslucent:NO];
        
        [mailComposer.navigationItem setTitle:@"Send Email"];
        
        [mailComposer setSubject:[NSString stringWithFormat:@"Photos from the \"%@\" photo stream",self.spotInfo[@"spotName"]]];
        
        if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

            //We already have the branch URL
            NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the \"%@\" photo stream on Suba : %@</p>",self.spotInfo[@"spotName"],branchURLforInviteToStream];
            
            
            [mailComposer setMessageBody:shareText isHTML:YES];
            [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
            
            if (!self.presentedViewController){
                [self presentViewController:mailComposer animated:YES completion:nil];
            }
            
        }else{
        
        NSString *senderName = nil;
            Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
        if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
            senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
            
        }else if([AppHelper firstName].length > 0 && ([AppHelper lastName] == NULL | [[AppHelper lastName] class]== [NSNull class] | [AppHelper lastName].length == 0)){
            
            senderName = [AppHelper firstName];
        }
        if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
            [AppHelper setProfilePhotoURL:@"-1"];
        }
        NSDictionary *dict = @{
                               @"$always_deeplink" : @"true",
                               @"$desktop_url" : @"http://app.subaapp.com/streams/invite",
                               @"streamId":self.spotID,
                               @"photos" : self.spotInfo[@"numberOfPhotos"],
                               @"streamName":self.spotInfo[@"spotName"],
                               @"sender": senderName,
                               @"streamCode" : self.spotInfo[@"spotCode"],
                               @"senderPhoto" : [AppHelper profilePhotoURL]};
        
        
        NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
        
        [branch getShortURLWithParams:streamDetails
                           andChannel:@"email"
                           andFeature:BRANCH_FEATURE_TAG_SHARE
                          andCallback:^(NSString *url,NSError *error){
                              branchURLforInviteToStream = url;
                              if (!error) {
                                  DLog(@"URL from Branch: %@",url);
                                  
                                  NSString *shareText = [NSString stringWithFormat:@"<p>See and add photos to the \"%@\" photo stream on Suba : %@</p>",self.spotInfo[@"spotName"],branchURLforInviteToStream];
                                  
                                  
                                  [mailComposer setMessageBody:shareText isHTML:YES];
                                  [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
                                  
                                  if (!self.presentedViewController){
                                      [self presentViewController:mailComposer animated:YES completion:nil];
                                  }

                              }else DLog(@"Branch error: %@",error.debugDescription);
                              
      }];
   }
    }else{
        [AppHelper showAlert:@"Configure email" message:@"Hey there:-) Do you mind configuring your Mail app to send email" buttons:@[@"OK"] delegate:nil];
    }
}


- (IBAction)invitePeopleBySMS:(id)sender
{
    [self sendSMSToRecipients:nil];
}


- (IBAction)inviteWhatsappContactsToStream:(id)sender
{
    if ([WhatsAppKit isWhatsAppInstalled]){
        if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){
            // We already have the URL
            
             NSString *message = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURLforInviteToStream];
            
                [WhatsAppKit launchWhatsAppWithMessage:message];
        }else{
            NSString *senderName = nil;
            Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                senderName = [AppHelper userName];
            }
            
            
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            
            NSDictionary *dict = @{
                                   @"$always_deeplink" : @"true",
                                   @"$desktop_url" : @"http://app.subaapp.com/streams/invite",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"numberOfPhotos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]};
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            [branch getShortURLWithParams:streamDetails andChannel:@"whatsapp_message" andFeature:BRANCH_FEATURE_TAG_SHARE
                              andCallback:^(NSString *url,NSError *error){
                if (!error){
                    
                    branchURLforInviteToStream = url;
                
                    NSString *message = [NSString stringWithFormat:@"See and add photos to the \"%@\" photo stream on Suba : %@",self.spotInfo[@"spotName"],branchURLforInviteToStream];
                    [WhatsAppKit launchWhatsAppWithMessage:message];
                    
                }else DLog(@"Branch error: %@",error.debugDescription);

            }];
        }
    }else{
        [AppHelper showAlert:@"Invite via Whatsapp" message:@"Whatsapp is not installed on your device" buttons:@[@"OK"] delegate:nil];
    }
    //[self performSegueWithIdentifier:@"InviteFriendsSegue" sender:nil];
}

- (IBAction)showOtherInviteOptions:(UIButton *)sender
{
    PhotoStreamFooterView *footerView = (PhotoStreamFooterView *)sender.superview.superview;
    
    [UIView animateWithDuration:.8 animations:^{
        
        sender.alpha = 0;
        footerView.emailTextField.alpha = 0;
        footerView.smsInviteButton.alpha = 1;
        footerView.inviteByWhatsappButton.alpha = 1;
        
        CGFloat newFrameY = footerView.smsInviteButton.frame.origin.y - (footerView.emailInviteButton.frame.size.height + 20);
        CGRect newFrame = CGRectMake(footerView.emailInviteButton.frame.origin.x, newFrameY, footerView.emailInviteButton.frame.size.width, footerView.emailInviteButton.frame.size.height);
        
        footerView.emailInviteButton.enabled = YES;
        footerView.emailInviteButton.frame = newFrame;
        [footerView.emailInviteButton setTitle:@"Invite by email" forState:UIControlStateNormal];
        
    }];
}


#pragma mark - UITextField Delegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Move the textfield up to give space for user to continue
    if (textField == self.firstNameField || textField == self.lastNameField || textField == self.usernameField)
    {
       [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
        
    }else if (textField == self.emailField || textField == self.passwordField || textField == self.reTypePasswordField)
    {
       [self.finalSignUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    /*if (textField == self.userNameOrEmailTextField) {
        [self.userNameOrEmailTextField resignFirstResponder];
        
    }else if (textField == self.loginPasswordTextField){ // if we are in the password field
        
        if (![self.loginPasswordTextField.text isEqualToString:@""] && ![self.userNameOrEmailTextField.text isEqualToString:@""]){
            self.userEmail = self.userNameOrEmailTextField.text;
            self.userPassword = self.loginPasswordTextField.text;
            
            [self performSelector:@selector(performLoginAction:)];
        }else{
            [self.loginPasswordTextField resignFirstResponder];
        }
    }else{*/
    
        if (textField == self.firstNameField)[self.lastNameField becomeFirstResponder];
        if (textField == self.lastNameField)[self.usernameField becomeFirstResponder];
        if (textField == self.usernameField)[self.usernameField resignFirstResponder];
        if (textField == self.emailField)[self.passwordField becomeFirstResponder];
        if (textField == self.passwordField)[self.reTypePasswordField becomeFirstResponder];
        if (textField == self.reTypePasswordField && ![textField.text isEqualToString:@""]) {
            if (![self.emailField.text isEqualToString:@""] && ![self.usernameField.text isEqualToString:@""]
                && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
                && ![self.passwordField.text isEqualToString:@""]){
                // Now all the fields are not empty
                //1. Let's first check whether the email is correct
                if ([AppHelper validateEmail:self.emailField.text]){
                    // If the email is correct,begin to process everything else
                    if ([self.usernameField.text isEqualToString:self.passwordField.text]){
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                        [alertView show];
                    }else{
                        self.firstName = self.firstNameField.text;
                        self.lastName = self.lastNameField.text;
                        self.userEmail = self.emailField.text;
                        self.userName = self.usernameField.text;
                        self.userPassword = self.passwordField.text;
                        NSDictionary *params = @{
                                                 @"userId" : [AppHelper userID],
                                                 @"firstName" : self.firstName,
                                                 @"lastName" : self.lastName,
                                                 @"email": self.userEmail,
                                                 @"pass":self.userPassword,
                                                 @"userName":self.userName,
                                                 @"fbLogin" : NATIVE
                                                 };
                        [AppHelper createUserAccount:params WithType:NATIVE completion:^(id results, NSError *error){
                            if (!error) {
                                [AppHelper savePreferences:results];
                                
                                [self performSelector:@selector(dismissCreateSubaAccountScreen:)];
                                
                            }else{
                                [AppHelper showAlert:@"Oops!" message:results[@"message"]
                                             buttons:@[@"I'll check again"] delegate:nil];
                            }
                        }];
                    }
                }else{
                    
                    UIAlertView *alertView = [[UIAlertView alloc]
                                              initWithTitle:@"Email check"
                                              message:@"We could not verfiy your email address format.Please check again"
                                              delegate:nil
                                              cancelButtonTitle:@"I'll check"
                                              otherButtonTitles:nil];
                    
                    [alertView show];
                }
                
                [textField resignFirstResponder];
            }
            
        }
        
        
    //}
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return YES;
}



#pragma mark - Other Actions
- (void)showDoodleVersionOfPhotoInCell:(PhotoStreamCell *)cell completion:(SBFlipDoodleCompletionHandler)completionHandler
{
    if (cell.photoCardImage.alpha == 1) {
        [UIView transitionWithView:cell.photoCardImage duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 0;
            cell.remixedImageView.alpha = 1;
        } completion:completionHandler];
    }else{
        [UIView transitionWithView:cell.remixedImageView duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
            cell.photoCardImage.alpha = 1;
            cell.remixedImageView.alpha = 0;
        } completion:completionHandler];
    }
}

- (IBAction)flipPhotoToShowRemix:(UIControl *)sender
{
    //UIButton *flipButton = (UIButton *)sender;
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    
    [self showDoodleVersionOfPhotoInCell:cell completion:nil];
}


#pragma mark - Hidden Menu Tins
- (void)showHiddenMenu:(UITapGestureRecognizer *)sender
{
    //DLog(@"Showing Hidden View with uview - %@",sender.view);
   // Get the container view and increase height
    if (sender.state == UIGestureRecognizerStateEnded){
        if (toggler % 2 == 0) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 150);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 1;
                //self.hiddenTopMenuView.hidden = NO;
            }];
        }else{
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 0;
                //self.hiddenTopMenuView.hidden = YES;
            }];
        }
        
        
    }
    
    toggler += 1;
}


- (void)showHiddenMoreOptions
{
   //[self.menuTableView reloadData];
    // Get the container view and increase height
    
        if (toggler % 2 == 0) {
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 200);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 1;
                self.dismissDropDownButton.hidden = NO;
                self.dismissDropDownButton.enabled = YES;
                
            }];
        }else{
            [UIView animateWithDuration:0.3 animations:^{
                CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
                self.hiddenTopMenuView.frame = hiddenMenuFrame;
                self.hiddenTopMenuView.alpha = 0;
                self.dismissDropDownButton.hidden = YES;
                self.dismissDropDownButton.enabled = NO;
            }];
        }
    toggler += 1;
    
}


- (IBAction)requestForPhotos:(id)sender
{
    
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;

    } completion:^(BOOL finished) {
        [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:self.spotID];
    }];
    
    toggler += 1;
}


- (IBAction)shareStream:(id)sender
{
    //DLog();
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        
    } completion:^(BOOL finished) {
        // Actual code to share Share stream
        // Present Action Sheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Share this stream via" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Facebook",@"Twitter",@"Email", nil];
        
         actionSheet.tag = 7000;
        [actionSheet showInView:self.view];
    }];
    
    toggler += 1;
}

- (IBAction)showStreamSettings:(id)sender
{
    [UIView animateWithDuration:0.2 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        
    } completion:^(BOOL finished) {
        // Actual code to show stream settings
            [self performSegueWithIdentifier:@"SpotSettingsSegue" sender:self.spotID];
    }];
    toggler += 1;
}


#pragma mark - Create Account tins
- (IBAction)signUpWithEmailOptionChosen:(id)sender
{
    // Transition from create Account View to Sign up details view with left animation
    [UIView transitionWithView:self.createAccountOptionsView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        CGRect newFrame = CGRectMake(0, 0, 320, 440);
        CGRect newFrameForCreateAccountOptionsView = CGRectMake(-340, 0, 320, 440);
        //self.createAccountOptionsView.alpha = 0;
        self.createAccountOptionsView.frame = newFrameForCreateAccountOptionsView;
        //self.signUpWithEmailView.alpha = 1;
        self.signUpWithEmailView.frame = newFrame;
        
    } completion:^(BOOL finished) {
        
        int64_t delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.firstNameField becomeFirstResponder];
            
        });
    }];
}

- (void)dismissCreateAccountPopUp
{
    [UIView animateWithDuration:.5 animations:^{
        self.createAccountView.alpha = 0;
        //self.navigationController.navigationBarHidden = NO;
    }];
}

- (IBAction)dismissCreateSubaAccountScreen:(id)sender
{
    [self dismissCreateAccountPopUp];
}

- (IBAction)dismissSignUpWithEmailView:(id)sender
{
    [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

        [UIView transitionWithView:self.signUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(320, 0, 320, 440);
            self.signUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            self.createAccountOptionsView.frame = newFrame;
        } completion:nil];
  });
}

- (IBAction)showFinalSignUpWithEmailView:(id)sender
{
    [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    [self.firstNameField resignFirstResponder];
    [self.lastNameField resignFirstResponder];
    [self.usernameField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [UIView transitionWithView:self.signUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(-320, 0, 320, 440);
            self.signUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            self.finalSignUpWithEmailView.frame = newFrame;
        
        } completion:^(BOOL finished){
        
        int64_t delayInSeconds = .5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.emailField becomeFirstResponder];
        });
            
      }];
   });
}

- (IBAction)dismissFinalSignUpView:(id)sender
{
    [self.finalSignUpWithEmailView setContentOffset:CGPointMake(0.0f, 0.0f) animated:YES];
    
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.reTypePasswordField resignFirstResponder];
    
    int64_t delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [UIView transitionWithView:self.finalSignUpWithEmailView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGRect newFrame = CGRectMake(0, 0, 320, 440);
            CGRect newFrameForSignUpWithEmailView = CGRectMake(320, 0, 320, 440);
            self.finalSignUpWithEmailView.frame = newFrameForSignUpWithEmailView;
            //self.signUpWithEmailView.alpha = 0;
            //self.createAccountOptionsView.alpha = 1;
            self.signUpWithEmailView.frame = newFrame;
            
        } completion:^(BOOL finished) {
           //self.firstNameField
        }];
        
    });
    
    
}


- (IBAction)manualSignUpDetailsDoneAction:(id)sender
{
    if (![self.reTypePasswordField.text isEqualToString:self.passwordField.text]) {
        [AppHelper showAlert:@"Oops!" message:@"Your passwords do not match" buttons:@[@"Will check again"] delegate:nil];
    }else{
        [self.signUpSpinner startAnimating];
        
        [self.passwordField resignFirstResponder];
        [self.reTypePasswordField resignFirstResponder];
        
        /*Save these in a model
         self.firstName = self.firstNameField.text;
         self.lastName = self.lastNameField.text;
         self.userEmail = self.emailField.text;
        
         self.userName = self.usernameField.text;
         self.userPasswordConfirm = self.passwordField.text;
        */
        
        [self checkAllTextFields];
    }
}


- (void)checkAllTextFields
{
    if (![self.reTypePasswordField.text isEqualToString:@""]) {
        
        if (![self.emailField.text isEqualToString:@""] && ![self.usernameField.text isEqualToString:@""]
            && ![self.firstNameField.text isEqualToString:@""] && ![self.lastNameField.text isEqualToString:@""]
            && ![self.passwordField.text isEqualToString:@""]){
            // Now all the fields are not empty
            
            //1. Let's first check whether the email is correct
            if ([AppHelper validateEmail:self.emailField.text]){
                // If the email is correct,begin to process everything else
                
                
                if ([self.usernameField.text isEqualToString:self.passwordField.text]){
                    
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Yet to sign up" message:@"Your username and password appear to be the same" delegate:nil cancelButtonTitle:@"I'll check" otherButtonTitles:nil];
                    
                    [alertView show];
                }else{
                    
                    self.firstName = [self.firstNameField.text
                                      stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.lastName = [self.lastNameField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userName = [self.usernameField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userEmail = [self.emailField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userPasswordConfirm = [self.reTypePasswordField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    self.userPassword = [self.passwordField.text stringByReplacingOccurrencesOfString:kEMPTY_STRING_WITH_SPACE withString:kEMPTY_STRING_WITHOUT_SPACE];
                    
                    NSDictionary *params = @{
                                             @"userId" : [AppHelper userID],
                                             @"firstName":self.firstName,
                                             @"lastName":self.lastName,
                                             @"email": self.userEmail,
                                             @"pass":self.userPassword,
                                             @"userName":self.userName,
                                             @"fbLogin" : NATIVE
                                             };
                    
                    
                    [AppHelper createUserAccount:params WithType:NATIVE completion:^(id results, NSError *error) {
                        if (!error) {
                            [self.signUpSpinner stopAnimating];
                            [FBAppEvents logEvent:@"Account_Confirmed_Manual"];
                            [AppHelper savePreferences:results];
                            //DLog(@"User preferences - %@",[AppHelper userPreferences]);
                            [self performSelector:@selector(dismissCreateAccountPopUp)];
                            if ([pendingActions count] > 0) {
                                int pAction = [[pendingActions lastObject] intValue];
                                [self executePendingAction:pAction];
                            }
                           
                        }else{
                            [AppHelper showAlert:@"Oops!" message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
                        }
                    }];
                    
                }
            }else{
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:@"Email check"
                                          message:@"We could not verfiy your email address format.Please check again"
                                          delegate:nil
                                          cancelButtonTitle:@"I'll check"
                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }
        
    }
}


- (void)openNativeCamera:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *nativepickerController = [[UIImagePickerController alloc] init];
    nativepickerController.delegate = self;
    nativepickerController.sourceType = sourceType;
    
    NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    
    if ([sourceTypes containsObject:@"public.image"]) {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            //DLog(@"Camera source types: %@",sourceTypes);
            nativepickerController.allowsEditing = YES;
            //nativepickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        }else{
            
            /*nativepickerController.navigationController.navigationBar.tintColor = kSUBA_APP_COLOR;
             nativepickerController.navigationController.navigationBar.translucent = YES;
             [nativepickerController.navigationController.navigationItem setTitle:@"Choose Photo"];*/
            
            [nativepickerController setNavigationBarHidden:NO];
            nativepickerController.navigationBar.barTintColor = kSUBA_APP_COLOR;
            [nativepickerController.navigationBar setTintColor:[UIColor whiteColor]];
            [nativepickerController.navigationBar setTranslucent:NO];
            [nativepickerController.navigationItem setTitle:@"Choose Photo"];
        }
    }
    
    [self presentViewController:nativepickerController animated:YES completion:nil];
}




/*#pragma mark - DBCameraViewControllerDelegate
- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    
    UIImage *fullResolutionImage = [image rotateUIImage];
    NSData *img = UIImageJPEGRepresentation(fullResolutionImage, 1.0);
    
    DLog(@"Size of image - %fKB",[img length]/1024.0f);
    [cameraViewController dismissViewControllerAnimated:YES completion:^{
        DLog(@"Lets display aviary");
        [self displayEditorForImage:fullResolutionImage];
    }];
}

- (void) dismissCamera:(id)cameraViewController{
    //DLog();
    [self dismissViewControllerAnimated:NO completion:nil];
    [cameraViewController restoreFullScreenMode];
}



- (void)openDBCamera
{
    DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self];
    
    //[cameraController setForceQuadCrop:YES];
    //[cameraController set]
    
    DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    [cameraController setUseCameraSegue:NO];
    
    [container setCameraViewController:cameraController];
    [container setFullScreenMode];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:container];
    [nav setNavigationBarHidden:YES];
    
    [self presentViewController:nav animated:YES completion:nil];
}*/


- (void)displayEditorForImage:(UIImage *)imageToEdit
{
    //dispatch_once(&onceToken, ^{
        [AVYPhotoEditorController setAPIKey:kAviaryAPIKey secret:kAviarySecret];
         AVYPhotoEditorController *editorController = [[AVYPhotoEditorController alloc] initWithImage:imageToEdit];
        [editorController setDelegate:self];
    
    if (isDoodling) {
        // Customize the tools that appear
        // Set the tools to Draw (to be displayed in that order).
        [AVYPhotoEditorCustomization setToolOrder:@[kAVYDraw,kAVYStickers]];
    }else{
        
        // Customize the tools that appear
        // Set the tools to Contrast, Brightness, Enhance, and Crop (to be displayed in that order).
        [AVYPhotoEditorCustomization setToolOrder:@[kAVYEnhance,kAVYEffects,kAVYCrop,kAVYOrientation]];
    }
        [self presentViewController:editorController animated:YES completion:nil];
}


#pragma mark - AFPhotoEditorDelegate
- (void)photoEditor:(AVYPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    //[self.library saveImage:image toAlbum:@"Suba" completion:^(NSURL *assetURL, NSError *error){} failure:nil];
    
    // Handle the result image here
    [editor dismissViewControllerAnimated:YES completion:^{
        // Upload the image after we have dismissed the editor
        if (isDoodling) {
            PhotoStreamCell *cell = (PhotoStreamCell *)[self.photoCollectionView
                                                        cellForItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPhotoIndexPath.item inSection:0]];
            
            cell.remixedImageView.alpha = 1;
            cell.remixedImageView.image = image;
            NSData *data = UIImageJPEGRepresentation(image, .8);
            //DLog(@"Uploading Doodle");
            [self uploadDoodle:data WithName:self.photos[selectedPhotoIndexPath.item][@"s3name"]];
    }else{
        //DLog(@"Upload photo");
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
        
        //[self resizePhoto:image towidth:1136.0f toHeight:640.0f
                //completon:^(UIImage *compressedPhoto, NSError *error) {
                   // if(!error){
                        imageToUpload = UIImageJPEGRepresentation(image, .8);
                        nameOfImageToUpload = trimmedString;
                        DLog(@"Size of image - %fKB",[imageToUpload length]/1024.0f);
        
                        // Update collection view with local photo
                        [self upDateCollectionViewWithLocalInfo:[self prepareLocalPhotoInfo]];
        
                        //[self uploadPhoto:imageToUpload WithName:trimmedString];
        
        }

    }];

}

- (void)photoEditorCanceled:(AVYPhotoEditorController *)editor
{
    // Handle cancellation here
    [editor dismissViewControllerAnimated:YES completion:^{
        if (isDoodling){
            isDoodling = NO;
        }
    }];
    
    //DLog();
}



- (void)imageSavedToPhotosAlbum:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (!error) {
        DLog(@"Context info - %@",contextInfo);
    }
}


-(void)uploadingPhotoView:(BOOL)flag
{
    /*DLog(@"Uploading photo");
    self.uploadingPhoto.hidden = !flag;
    if (flag == YES) {
        [self.uploadingPhotoIndicator startAnimating];
    }else [self.uploadingPhotoIndicator stopAnimating];*/
    
}


- (void)showLocalPhoto:(UIImageView *)destination withURL:(NSString *)imgURL
{
    if ([destination.subviews count] == 1) {
        // Lets remove all subviews
        [[destination subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
    // Load the UIImage from an asset URL
    NSURL* aURL = [NSURL URLWithString:imgURL];
    
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library assetForURL:aURL resultBlock:^(ALAsset *asset)
     {
         UIImage  *copyOfOriginalImage = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullScreenImage] scale:0.5 orientation:UIImageOrientationUp];
         
         destination.image = copyOfOriginalImage;
     }
            failureBlock:^(NSError *error)
     {
         // error handling
         DLog(@"failure-----");
     }];
    
   
    
    
}


- (void)downloadPhoto:(UIImageView *)destination withURL:(NSString *)imgURL
       downloadOption:(SDWebImageOptions)option placeholder:(UIImage *)placeholder
{
    if ([destination.subviews count] == 1) {
        // Lets remove all subviews
        [[destination subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    
        DACircularProgressView *progressView = [[DACircularProgressView alloc]
                                                initWithFrame:CGRectMake((destination.bounds.size.width/2) - 20, (destination.bounds.size.height/2) - 20, 40.0f, 40.0f)];
        progressView.thicknessRatio = .1f;
        progressView.roundedCorners = YES;
        progressView.trackTintColor = [UIColor lightGrayColor];
        progressView.progressTintColor = [UIColor whiteColor];
        [destination addSubview:progressView];
        
        [[S3PhotoFetcher s3FetcherWithBaseURL]
         downloadPhoto:imgURL to:destination
         placeholderImage:placeholder
         progressView:progressView 
         downloadOption:option
         completion:^(id results, NSError *error){
             
             [progressView removeFromSuperview];
             if (!error) {
                 self.albumSharePhoto = (UIImage *)results;
             }else{
                 DLog(@"error - %@",error.userInfo);
                 
                 NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imgURL]];
                 [destination setImageWithURLRequest:request placeholderImage:placeholder success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                     
                     [progressView removeFromSuperview];
                     
                     if (!error) {
                         self.albumSharePhoto = image;
                         shouldReplacePhoto = NO;
                     }
                 } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                     DLog(@"Error: %@",error.userInfo);
                 }];
            }
         }];
  }


- (void)executePendingAction:(ActionPending)pendingAction
{
    DLog("Pending request");
    if (pendingAction == kActionLike) {
        [self performSelector:@selector(likePhotoWithID:atIndexPath:) withObject:selectedPhotoId withObject:selectedPhotoIndexPath];
    }else if(pendingAction == kActionEdit){
        [self performSelector:@selector(doodlePhoto:) withObject:selectedPhotoCell];
    }
}


- (void)doodlePhoto:(PhotoStreamCell *)cell
{
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = (isFiltered) ? filteredPhotos[indexpath.item] : self.photos[indexpath.item];
    
    if (cell.remixedImageView.image){
        if (cell.photoCardImage.alpha == 1){
            [UIView transitionWithView:cell.photoCardImage duration:0.8 options:UIViewAnimationOptionTransitionFlipFromRight animations:^{
                cell.photoCardImage.alpha = 0;
                cell.remixedImageView.alpha = 1;
            } completion:^(BOOL finished) {
                selectedPhoto = cell.remixedImageView.image;
                selectedPhotoIndexPath = indexpath;
                
                [self displayEditorForImage:selectedPhoto];
            }];
            
        }else if (cell.remixedImageView.alpha == 1){
            selectedPhoto = cell.remixedImageView.image;
            selectedPhotoIndexPath = indexpath;
            [self displayEditorForImage:selectedPhoto];
            
            //[self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        }
    }else{
        
        selectedPhoto = cell.photoCardImage.image;
        selectedPhotoIndexPath = indexpath;
        [self displayEditorForImage:selectedPhoto];
        
        //[self performSegueWithIdentifier:@"DoodleSegue" sender:selectedPhoto];
        
    }
}


- (void)showDoodle:(PhotoStreamCell *)cell
{
    cell.photoCardImage.alpha = 0;
    cell.remixedImageView.alpha = 1;
}

-(void)findAndShowPhoto:(NSString *)photoToShow
{
    NSUInteger index = 0;
    
    // Go find this photo in self.photos
    for (NSDictionary *photoInfo in self.photos){
        DLog(@"s3name: %@\nPhoto to show: %@",photoInfo[@"s3name"],photoToShow);
        
        if([photoInfo[@"s3name"] isEqualToString:photoToShow]){
           // index = [self.photos indexOfObject:photoToShow];
            DLog(@"Index: %lu",(unsigned long)index);
            break;
        }
        index++;
    }
    
    // Now determine where we need o scroll to
    //int scrollPosition = (285 * index) + 5;
    //DLog(@"Scroll position - %d",scrollPosition);
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    
    
    [self.photoCollectionView scrollToItemAtIndexPath:indexPath
                                     atScrollPosition:UICollectionViewScrollPositionLeft
                                             animated:YES];
    
    if (self.shouldShowDoodle == YES){
        DLog(@"We are flipping the photo");
        PhotoStreamCell *cell =  (PhotoStreamCell *)[self.photoCollectionView cellForItemAtIndexPath:indexPath];
        
        [self performSelector:@selector(showDoodle:)
                   withObject:cell
                   afterDelay:1.5];
        
           // } completion:NULL];
    }
}


-(IBAction)showCommentsAction:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.photoInView = (isFiltered) ? filteredPhotos[indexpath.item] : self.photos[indexpath.item];

    //DLog(@"Photo selected: %@",self.photoInView);
    [self performSegueWithIdentifier:@"CommentsSegue" sender:nil];
    
}


/*- (UIImage *)fixrotation:(UIImage *)image{
    
    int kMaxResolution = 320; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();  
    
    return imageCopy;  
}*/

-(void)prepareBranchURLforInvitingFriendsToStream
{
    NSString __block *branchurl = @"";
    NSString *senderName = nil;
    
        Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
        if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
            senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
            
        }else{
            
            senderName = [AppHelper userName];
        }
        
        
       // DLog(@"Stream code: - %@\n Sender: %@\nProfile photo: %@",self.spotInfo,senderName,[[AppHelper profilePhotoURL] class]);
        
        if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
            [AppHelper setProfilePhotoURL:@"-1"];
        }
    
    
        NSDictionary *dict = @{
                               @"$always_deeplink" : @"true",
                               @"$desktop_url" : @"http://app.subaapp.com/streams/invite",
                               @"streamId":self.spotInfo[@"spotId"],
                               @"photos" : self.spotInfo[@"photos"],
                               @"streamName":self.spotInfo[@"spotName"],
                               @"sender": senderName,
                               @"streamCode" : self.spotInfo[@"spotCode"],
                               @"senderPhoto" : [AppHelper profilePhotoURL]};
        
        
        NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
    
        [branch getShortURLWithParams:streamDetails andChannel:@"text_message" andFeature:BRANCH_FEATURE_TAG_SHARE
                          andCallback:^(NSString *url,NSError *error){
                              if (!error) {
                                  //DLog(@"URL from Branch: %@",url);
                                  branchURLforInviteToStream = url;
                                  branchurl = url;

                              }else DLog(@"Branch error: %@",error.debugDescription);
                        }];
}


-(void)prepareBranchURLforSharingStream
{
    NSString *senderName = nil;
    
    Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
        
    }else{
        
        senderName = [AppHelper userName];
    }
    
    
    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
        [AppHelper setProfilePhotoURL:@"-1"];
    }
    
    NSDictionary *dict = @{
                           @"$always_deeplink" : @"true",
                           @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                           @"streamId":self.spotInfo[@"spotId"],
                           @"photos" : self.spotInfo[@"photos"],
                           @"streamName":self.spotInfo[@"spotName"],
                           @"sender": senderName,
                           @"streamCode" : self.spotInfo[@"spotCode"],
                           @"senderPhoto" : [AppHelper profilePhotoURL]};
    
    
    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
    
    [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE
                      andCallback:^(NSString *url,NSError *error){
        if (!error) {
            //DLog(@"URL from Branch: %@",url);
            branchURLforShareStream = url;
        }else DLog(@"Branch error: %@",error.debugDescription);
        
        
    }];
}


-(void)setUpRightBarButtonItems
{
    UIBarButtonItem *addPhotoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addPhoto1"] style:UIBarButtonItemStyleBordered target:self action:@selector(cameraButtonTapped:)];
    
    UIBarButtonItem *inviteFriendsIcon = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"inviteFriends1"] style:UIBarButtonItemStyleBordered target:self action:@selector(requestForPhotos:)];
    
    UIBarButtonItem *moreIcon = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"moreIcon1"] style:UIBarButtonItemStyleBordered target:self action:@selector(showHiddenMoreOptions)]; 
    
    
    [self.navigationItem setRightBarButtonItems:@[moreIcon,inviteFriendsIcon,addPhotoButton] animated:YES];
    
    
}


- (NSArray *)photoTakers
{
    NSMutableArray *photographers = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray *stackphotographers = [NSMutableArray arrayWithCapacity:1];
    
    if (self.photos) {
        for (NSDictionary *photoItem in self.photos){
            
            
            
            NSDictionary *photoTakerDetails = @{@"pictureTaker": photoItem[@"pictureTaker"],
                                                @"pictureTakerId" : photoItem[@"pictureTakerId"]
                                                };
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:photoTakerDetails];
            
            if (photoItem[@"pictureTakerPhoto"]) {
                NSDictionary *photoTakerImage = @{@"pictureTakerPhoto": photoItem[@"pictureTakerPhoto"]};
                
                [dict addEntriesFromDictionary:photoTakerImage];
            }
            
            
            if ([photographers containsObject:dict]){
                
                for (NSMutableDictionary *stackphototaker in stackphotographers) {
                    if ([stackphototaker[@"pictureTakerId"] isEqualToString:dict[@"pictureTakerId"]]) {
                       // Get number of photos
                        NSInteger photos = [stackphototaker[@"photos"] integerValue] + 1;
                        stackphototaker[@"photos"] = @(photos);
                    }
                }
                
                // Find the index of this photo item and increment photos key
                //[photographers indexOfObject:dict];
                
            }else{
                [photographers addObject:dict];
                NSMutableDictionary *stackDict = [NSMutableDictionary dictionaryWithDictionary:dict];
                [stackDict addEntriesFromDictionary:@{@"photos":@(1)}];
                [stackphotographers addObject:stackDict];
                
               
            }
        }
    }
    
    
    return stackphotographers;
}


- (void)showPhotosTakenByMemberWithId:(NSString *)memberId
{
    isFiltered = YES;
    if (self.photos){
        filteredPhotos = [NSMutableArray arrayWithCapacity:[self.photos count]];
        for (NSMutableDictionary *photoItem in self.photos) {
            if ([photoItem[@"pictureTakerId"] isEqualToString:memberId]) {
                // Add this photo to the filtered list
                [filteredPhotos addObject:photoItem];
            }
        }
        
        
        // When we are done reload the table view
        [self.photoCollectionView reloadData];
        [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionRight animated:YES];
        
    }
}


- (IBAction)dismissDropDownMenu:(id)sender
{
    DLog();
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect hiddenMenuFrame = CGRectMake(0, 0, 320, 0);
        self.hiddenTopMenuView.frame = hiddenMenuFrame;
        self.hiddenTopMenuView.alpha = 0;
        //self.dismissDropDownButton.hidden = YES;
        self.dismissDropDownButton.enabled = NO;
    }];

    toggler += 1;

}



/*- (void)prepareForPhotoUpload
{
    NSString *fullName = nil;
    if ([AppHelper firstName].length > 0  && [AppHelper lastName].length > 0) {
        fullName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
    }else{
        fullName = [AppHelper userName];
    }
    
    long timestamp = (long)[NSDate date].timeIntervalSinceNow;
    NSString *s3Name = [NSString stringWithFormat:@"%@/%ld.jpg",self.spotID,timestamp];
    
    
    
    NSDictionary *photoInfo = @{
                                @"howLong" : @"now",
                                @"id": @(0),
                                @"likes" : @(0),
                                @"pictureTaker" : fullName,
                                @"pictureTakerId" : [AppHelper userID],
                                @"pictureTakerPhoto" : [AppHelper profilePhotoURL],
                                @"s3name" : s3Name,
                                @"spot" : self.spotName,
                                @"spotId" : self.spotID,
                                @"status" : @"ok",
                                @"timestamp" : @(timestamp)
                                };
    
    
    //[FBAppEvents logEvent:@"Photo_Upload"];
    self.noPhotosView.hidden = YES;
    self.photoCollectionView.hidden = NO;
    
    if (!self.photos){
        self.photos = [NSMutableArray arrayWithObject:photoInfo];
    }else{
        [self.photos insertObject:photoInfo atIndex:0];
    }
    
    [self upDateCollectionViewWithCapturedPhoto:photoInfo];
 
}*/



- (void)sharePhotoWithButtonIndexSelected:(NSInteger)buttonIndex photo:(UIImage *)photo
{
  
    if (buttonIndex == 0) {
        //We're sharing on facebook
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
            if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

                NSString *shareText = [NSString stringWithFormat:@"Photo from my %@ group photo album on Suba. See the rest of the photos: %@",self.spotName,branchURLforInviteToStream];
                [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            DLog(@"Share stream cancelled");
                            [FBAppEvents logEvent:@"Share_Stream_Facebook_Cancelled"];
                            break;
                        case SLComposeViewControllerResultDone:
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            DLog(@"Stream Shared on Facebook");
                            [FBAppEvents logEvent:@"Share_Stream_Facebook_Done"];
                            
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
                
                
            }else{
                NSString *senderName = nil;
                Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"photos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url,NSError *error){
                    if (!error) {
                        
                   
                    branchURLforShareStream = url;
                    NSString *shareText = [NSString stringWithFormat:@"Photo from my %@ group photo album on Suba. See the rest of the photos: %@",self.spotName,branchURLforShareStream];
                    [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                    [composeVC setInitialText:shareText];
                    
                    [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                        switch (result) {
                            case SLComposeViewControllerResultCancelled:
                                DLog(@"Share stream cancelled");
                                [FBAppEvents logEvent:@"Share_Stream_Facebook_Cancelled"];
                                break;
                            case SLComposeViewControllerResultDone:
                                [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                    DLog(@"Response  - %@",results);
                                }];
                                DLog(@"Stream Shared on Facebook");
                                [FBAppEvents logEvent:@"Share_Stream_Facebook_Done"];
                                
                                break;
                            default:
                                break;
                        }
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                    
                    [self presentViewController:composeVC animated:YES completion:nil];
                   
                        
                }else DLog(@"Branch error: %@",error.debugDescription);
                    
                }];
                
            }
            
        }else{
            // User has not connected their facebook account
            if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){
                FBPhotoParams *sharePhotoParams = [[FBPhotoParams alloc] initWithPhotos:@[selectedPhoto]];
                
                BOOL canShare = [FBDialogs canPresentShareDialogWithPhotos];
                                 
                if (canShare) {
                    [FBDialogs presentShareDialogWithPhotoParams:sharePhotoParams clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                        if (!error) {
                            [FBAppEvents logEvent:@"Facebook_Share_Photo_Completed"];
                        }else if (error) {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed share" message:@"We could not share your album to your facebook contacts" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK" , nil];
                            [alert show];
                        }else if ([results[@"completionGesture"] isEqualToString:@"cancel"]){
                            //NSLog(@"Share didComplete");
                            [FBAppEvents logEvent:@"Facebook_Share_Photo_Cancelled"];
                        }
                        
                    }];
                    
                }else{
                    
                    // Facebook is not installed on the user's device, so let's use the web dialog
                    DLog(@"Facebook app is not installed");
                    
                }
                
            }
            
        }
        
    }else if (buttonIndex == 1){
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
           
         if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

                NSString *shareText = [NSString stringWithFormat:@"Photo from my %@ group photo album via @SubaPhotoApp: %@",self.spotName,branchURLforInviteToStream];
                
                [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            [FBAppEvents logEvent:@"Share_Stream_Twitter_Cancelled"];
                            DLog(@"Message cancelled.");
                            break;
                        case SLComposeViewControllerResultDone:
                            DLog(@"Message sent.");
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            [FBAppEvents logEvent:@"Share_Stream_Twitter_Done"];
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
                
                
            }else{
                
                NSString *senderName = nil;
                Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"photos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url,NSError *error){
                    if (!error){
                    
                        branchURLforShareStream = url;
                        NSString *shareText = [NSString stringWithFormat:@"Photo from my %@ group photo album via @SubaPhotoApp: %@",self.spotName,branchURLforShareStream];
                    
                        [composeVC addImage:(selectedPhoto ? selectedPhoto : nil)];
                    
                        [composeVC setInitialText:shareText];
                    
                        [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                            switch (result) {
                                case SLComposeViewControllerResultCancelled:
                                    [FBAppEvents logEvent:@"Share_Stream_Twitter_Cancelled"];
                                    DLog(@"Message cancelled.");
                                    break;
                                case SLComposeViewControllerResultDone:
                                    DLog(@"Message sent.");
                                    [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                    DLog(@"Response  - %@",results);
                                }];
                                    [FBAppEvents logEvent:@"Share_Stream_Twitter_Done"];
                                    
                                break;
                            default:
                                break;
                        }
                        
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }];
                    
                        [self presentViewController:composeVC animated:YES completion:nil];
                    
                     }else DLog(@"Branch error: %@",error.debugDescription);
                }];
                
            }
        }else{
            
            DLog(@"Twitter account is not set up");
            
            [AppHelper showAlert:@"Configure Twitter account" message:@"Hey there:) Please configure your Twitter account in Settings." buttons:@[@"OK"] delegate:nil];
            
        }
        
    }else if (buttonIndex == 2){
        if ([MFMailComposeViewController canSendMail]){
            MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
            mailComposer.mailComposeDelegate = self;
            [mailComposer setSubject:[NSString stringWithFormat:@"Photo from %@ photo album",self.spotName]];
        
        if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

            NSString *shareText = [NSString stringWithFormat:@"Here’s a photo from my %@ group photo album. See the rest of the photos on Suba: %@",self.spotName,branchURLforInviteToStream];
            
            [mailComposer setMessageBody:shareText isHTML:NO];
            if (selectedPhoto != nil) {
                NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
                [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
            }
            
            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                DLog(@"Response  - %@",results);
            }];
            
            [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
            
            [self presentViewController:mailComposer animated:YES completion:nil];
            
        }else{
            
            NSString *senderName = nil;
            Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                
                senderName = [AppHelper userName];
            }
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            
            NSDictionary *dict = @{
                                   @"$always_deeplink" : @"true",
                                   @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"photos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]};
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url,NSError *error){
                if (!error) {
                    DLog(@"URL from Branch: %@",url);
                    branchURLforShareStream = url;
                    NSString *shareText = [NSString stringWithFormat:@"All the photos in my %@ group photo stream via %@",self.spotName,branchURLforShareStream];
                
                    [mailComposer setMessageBody:shareText isHTML:NO];
                    if (selectedPhoto != nil) {
                        NSData *imageData = UIImageJPEGRepresentation(selectedPhoto, 1.0);
                        [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
                }
                
                    [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                        DLog(@"Response  - %@",results);
                    }];
                
                    [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
                
                    [self presentViewController:mailComposer animated:YES completion:nil];
                    
             }else DLog(@"Branch error: %@",error.debugDescription);
                    
            }];
            
           }
        }else{
            [AppHelper showAlert:@"Configure email" message:@"Hey there:) Do you mind configuring your Mail app to send email" buttons:@[@"OK"] delegate:nil];
        }
   
  }
}



- (void)shareStreamWithButtonIndexOptionSelected:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if ([FBDialogs canPresentShareDialog]) {
            
                if(branchURLforInviteToStream &&
                   [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){
                    
                    DLog(@"branch link: %@",branchURLforInviteToStream);
                    NSURL *shareLink = [NSURL URLWithString:branchURLforInviteToStream];
                    NSString *shareLinkName = [NSString stringWithFormat:@"Photos from %@ stream on Suba",self.spotName];
                    NSURL *linkPhoto = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/%@",self.photos[0][@"s3name"]]];
                    
                    NSString *shareStreamDescription = [NSString stringWithFormat:@"Here're all the photos from %@ on Suba",self.spotName];
                    
                    FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:shareLink name:shareLinkName caption:@"Cature shared memories together with group photo streams" description:shareStreamDescription picture:linkPhoto];
                    
                    BOOL canShare = [FBDialogs canPresentShareDialogWithParams:params];
                    
                    if (canShare) {
                        [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                            if (!error) {
                                [FBAppEvents logEvent:@"Facebook_Share_Completed"];
                            }else if (error) {
                                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed share" message:@"We could not share your album to your facebook contacts" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK" , nil];
                                [alert show];
                            }else if ([results[@"completionGesture"] isEqualToString:@"cancel"]){
                                //NSLog(@"Share didComplete");
                                [FBAppEvents logEvent:@"Facebook_Share_Cancelled"];
                            }
                            
                        }];
                        
                    }else{
                        
                        // Facebook is not installed on the user's device, so let's use the web dialog
                        DLog(@"Facebook app is not installed");
                        
                    }
                    
                }else{
                    // We need to get the link before we share
                    NSString *senderName = nil;
                    Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
                    if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                        senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                        
                    }else{
                        
                        senderName = [AppHelper userName];
                    }
                    
                    
                    if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                        [AppHelper setProfilePhotoURL:@"-1"];
                    }
                    
                    NSDictionary *dict = @{
                                           @"$always_deeplink" : @"true",
                                           @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                           @"streamId":self.spotInfo[@"spotId"],
                                           @"photos" : self.spotInfo[@"photos"],
                                           @"streamName":self.spotInfo[@"spotName"],
                                           @"sender": senderName,
                                           @"streamCode" : self.spotInfo[@"spotCode"],
                                           @"senderPhoto" : [AppHelper profilePhotoURL]};
                    
                    
                    NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                    
                    [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE
                                      andCallback:^(NSString *url,NSError *error){
                                          if (!error){
                                              
                                              DLog(@"URL from Branch: %@",url);
                                              branchURLforShareStream = url;
                                              
                                              // Now that we have branch
                                              DLog(@"branch link: %@",branchURLforInviteToStream);
                                              NSURL *shareLink = [NSURL URLWithString:branchURLforInviteToStream];
                                              NSString *shareLinkName = [NSString stringWithFormat:@"Photos from %@ stream on Suba",self.spotName];
                                              NSURL *linkPhoto = [NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/%@",self.photos[0][@"s3name"]]];
                                              
                                              NSString *shareStreamDescription = [NSString stringWithFormat:@"Here're all the photos from %@ on Suba",self.spotName];
                                              
                                              FBLinkShareParams *params = [[FBLinkShareParams alloc] initWithLink:shareLink name:shareLinkName caption:@"Cature shared memories together with group photo streams" description:shareStreamDescription picture:linkPhoto];
                                              
                                              
                                              BOOL canShare = [FBDialogs canPresentShareDialogWithParams:params];
                                              
                                              if (canShare) {
                                                  [FBDialogs presentShareDialogWithParams:params clientState:nil handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
                                                      if (!error) {
                                                          [FBAppEvents logEvent:@"Facebook_Share_Completed"];
                                                      }else if (error) {
                                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed share" message:@"We could not share your album to your facebook contacts" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK" , nil];
                                                          [alert show];
                                                      }else if ([results[@"completionGesture"] isEqualToString:@"cancel"]){
                                                          //NSLog(@"Share didComplete");
                                                          [FBAppEvents logEvent:@"Facebook_Share_Cancelled"];
                                                      }
                                                      
                                                  }];
                                                  
                                              }else{
                                                  
                                                  // Facebook is not installed on the user's device, so let's use the web dialog
                                                  DLog(@"Facebook app is not installed");
                                                  
                                              }
                                              
                                          }else DLog(@"Branch error: %@",error.debugDescription);
                                          
                                      }];
                    
                }
                
            
        }else if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
            if (branchURLforShareStream) {
                NSString *shareText = [NSString stringWithFormat:@"Here're all the photos from %@ on Suba: %@",self.spotName,branchURLforShareStream];
                
                //[composeVC setTitle:[NSString stringWithFormat:@"See all the photos from %@",self.spotName]];
                
                [composeVC addImage:(self.albumSharePhoto ? self.albumSharePhoto : nil)];
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            DLog(@"Share stream cancelled");
                            [FBAppEvents logEvent:@"Share_Stream_Facebook_Cancelled"];
                            break;
                        case SLComposeViewControllerResultDone:
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            DLog(@"Stream Shared on Facebook");
                            [FBAppEvents logEvent:@"Share_Stream_Facebook_Done"];
                            
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
                
                
            }else{
                NSString *senderName = nil;
                Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"photos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE
                                  andCallback:^(NSString *url,NSError *error){
                                      if (!error) {
                                          
                                      
                                          DLog(@"URL from Branch: %@",url);
                                          branchURLforShareStream = url;
                    
                                          NSString *shareText = [NSString stringWithFormat:@"Here're all the photos from %@ on Suba: %@",self.spotName,branchURLforShareStream];
                    
                                          [composeVC addImage:(self.albumSharePhoto ? self.albumSharePhoto : nil)];
                                          [composeVC setInitialText:shareText];
                    
                                          [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                                              switch (result) {
                                                  case SLComposeViewControllerResultCancelled:
                                                      DLog(@"Share stream cancelled");
                                                      [FBAppEvents logEvent:@"Share_Stream_Facebook_Cancelled"];
                                                      break;
                                                  case SLComposeViewControllerResultDone:
                                                      [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                                          DLog(@"Response  - %@",results);
                                                      }];
                                                      DLog(@"Stream Shared on Facebook");
                                                      [FBAppEvents logEvent:@"Share_Stream_Facebook_Done"];
                                
                                                      break;
                                                  default:
                                                      break;
                                              }
                        
                                              [self dismissViewControllerAnimated:YES completion:nil];
                                          }];
                    
                    [self presentViewController:composeVC animated:YES completion:nil];
                                          
                   }else DLog(@"Branch error: %@",error.debugDescription);
                    
                }];
                
            }
        
        }else{
            DLog(@"fb account is not set up");
            
            [AppHelper showAlert:@"Configure Facebook account" message:@"Hey there:) Please configure your Facebook account in Settings." buttons:@[@"OK"] delegate:nil];
            
        }
        
    }else if (buttonIndex == 1){
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            // Do this if twitter account is set up
            SLComposeViewController *composeVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            
            if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

                NSString *shareText = [NSString stringWithFormat:@"See all the photos from the %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforInviteToStream];
                
                [composeVC addImage:(self.albumSharePhoto ? self.albumSharePhoto : nil)];
                [composeVC setInitialText:shareText];
                
                [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                    switch (result) {
                        case SLComposeViewControllerResultCancelled:
                            [FBAppEvents logEvent:@"Share_Stream_Twitter_Cancelled"];
                            DLog(@"Message cancelled.");
                            break;
                        case SLComposeViewControllerResultDone:
                            DLog(@"Message sent.");
                            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                DLog(@"Response  - %@",results);
                            }];
                            [FBAppEvents logEvent:@"Share_Stream_Twitter_Done"];
                            break;
                        default:
                            break;
                    }
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
                
                [self presentViewController:composeVC animated:YES completion:nil];
                
                
            }else{
                
                NSString *senderName = nil;
                Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
                if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                    senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                    
                }else{
                    
                    senderName = [AppHelper userName];
                }
                
                if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                    [AppHelper setProfilePhotoURL:@"-1"];
                }
                
                NSDictionary *dict = @{
                                       @"$always_deeplink" : @"true",
                                       @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                       @"streamId":self.spotInfo[@"spotId"],
                                       @"photos" : self.spotInfo[@"photos"],
                                       @"streamName":self.spotInfo[@"spotName"],
                                       @"sender": senderName,
                                       @"streamCode" : self.spotInfo[@"spotCode"],
                                       @"senderPhoto" : [AppHelper profilePhotoURL]};
                
                
                NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
                
                [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE andCallback:^(NSString *url, NSError *error){
                    if (!error) {
                        //DLog(@"URL from Branch: %@",url);
                        branchURLforShareStream = url;
                        NSString *shareText = [NSString stringWithFormat:@"See all the photos from the %@ group photo stream via @SubaPhotoApp %@",self.spotName,branchURLforShareStream];
                        
                        [composeVC addImage:(self.albumSharePhoto ? self.albumSharePhoto : nil)];
                        
                        [composeVC setInitialText:shareText];
                        
                        [composeVC setCompletionHandler:^(SLComposeViewControllerResult result) {
                            switch (result) {
                                case SLComposeViewControllerResultCancelled:
                                    [FBAppEvents logEvent:@"Share_Stream_Twitter_Cancelled"];
                                    DLog(@"Message cancelled.");
                                    break;
                                case SLComposeViewControllerResultDone:
                                    DLog(@"Message sent.");
                                    [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                        DLog(@"Response  - %@",results);
                                    }];
                                    [FBAppEvents logEvent:@"Share_Stream_Twitter_Done"];
                                    break;
                                default:
                                    break;
                            }
                            
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }];
                        
                        [self presentViewController:composeVC animated:YES completion:nil];
                        
                    }else{
                        DLog(@"branch error: %@",error.debugDescription);
                    }
                    
                }];
                
            }
        }else{
             DLog(@"Twitter account is not set up");
            
            [AppHelper showAlert:@"Configure Twitter account" message:@"Hey there:) Please configure your Twitter account in Settings." buttons:@[@"OK"] delegate:nil];
            
        }
    }else if (buttonIndex == 2){
      if ([MFMailComposeViewController canSendMail]){
          MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
          mailComposer.mailComposeDelegate = self;
          [mailComposer setSubject:[NSString stringWithFormat:@"Photos from \"%@\" photo album",self.spotName]];
        
        if(branchURLforInviteToStream &&
           [branchURLforInviteToStream rangeOfString:@"Trouble" options:NSCaseInsensitiveSearch].location == NSNotFound){

            NSString *shareText = [NSString stringWithFormat:@"See all the photos from %@ group album on Suba: %@",self.spotName,branchURLforInviteToStream];
            
            [mailComposer setMessageBody:shareText isHTML:NO];
            if (self.albumSharePhoto != nil) {
                NSData *imageData = UIImageJPEGRepresentation(self.albumSharePhoto, 1.0);
                [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
            }
            
            [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                DLog(@"Response  - %@",results);
            }];
            
            [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
            
            [self presentViewController:mailComposer animated:YES completion:nil];
            
        }else{
            
            NSString *senderName = nil;
            Branch *branch = [Branch getTestInstance]; //:@"55726832636395855"];
            if ([AppHelper firstName].length > 0 && [AppHelper lastName].length > 0) {
                senderName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
                
            }else{
                
                senderName = [AppHelper userName];
            }
            
            if ([AppHelper profilePhotoURL] == NULL | [[AppHelper profilePhotoURL] class] == [NSNull class]) {
                [AppHelper setProfilePhotoURL:@"-1"];
            }
            
            NSDictionary *dict = @{
                                   @"$always_deeplink" : @"true",
                                   @"$desktop_url" : @"http://app.subaapp.com/streams/share",
                                   @"streamId":self.spotInfo[@"spotId"],
                                   @"photos" : self.spotInfo[@"photos"],
                                   @"streamName":self.spotInfo[@"spotName"],
                                   @"sender": senderName,
                                   @"streamCode" : self.spotInfo[@"spotCode"],
                                   @"senderPhoto" : [AppHelper profilePhotoURL]};
            
            
            NSMutableDictionary *streamDetails = [NSMutableDictionary dictionaryWithDictionary:dict];
            
            [branch getShortURLWithParams:streamDetails andChannel:@"share_stream" andFeature:BRANCH_FEATURE_TAG_SHARE
                              andCallback:^(NSString *url,NSError *error){
                                  if (!error) {
                                      DLog(@"URL from Branch: %@",url);
                                      branchURLforShareStream = url;
                                      NSString *shareText = [NSString stringWithFormat:@"See all the photos from %@ group album on Suba: %@",self.spotName,branchURLforShareStream];
                                      
                                      [mailComposer setMessageBody:shareText isHTML:NO];
                                      if (self.albumSharePhoto != nil) {
                                          NSData *imageData = UIImageJPEGRepresentation(self.albumSharePhoto, 1.0);
                                          [mailComposer addAttachmentData:imageData mimeType:@"image/jpeg" fileName:@"subapic"];
                                      }
                                      
                                      [User updateUserStat:@"STREAM_SHARED" completion:^(id results, NSError *error) {
                                          DLog(@"Response  - %@",results);
                                      }];
                                      
                                      [FBAppEvents logEvent:@"Share_Stream_Email_Done"];
                                      
                                      [self presentViewController:mailComposer animated:YES completion:nil];
                                  }else DLog(@"Branch error: %@",error.debugDescription);
                
            }];
        }
      }else{
           [AppHelper showAlert:@"Configure email" message:@"Hey there:) Do you mind configuring your Mail app to send email?" buttons:@[@"OK"] delegate:nil];
          
      }
  }
}


- (void)upDateCollectionViewWithLocalInfo:(NSDictionary *)newPhotoInfo
{
    
    self.noPhotosView.hidden = YES;
    self.photoCollectionView.hidden = NO;
    
    if (!self.photos){
        self.photos = [NSMutableArray arrayWithObject:newPhotoInfo];
    }else{
        [self.photos insertObject:newPhotoInfo atIndex:0];
    }
    
    
    [self.photoCollectionView performBatchUpdates:^{
     @try {
         [self.photoCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
         
     }@catch (NSException *exception) {
         // What to do when we have an exception
     }
        
     } completion:^(BOOL finished){
     @try{
         [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
         
         shouldReplacePhoto = YES;
         selectedPhotoCell = (PhotoStreamCell *)[self.photoCollectionView
                                                                         cellForItemAtIndexPath:[NSIndexPath indexPathForItem:selectedPhotoIndexPath.item inSection:0]];
         [self uploadPhoto:imageToUpload WithName:nameOfImageToUpload];
         
     }@catch (NSException *exception) {
         // What to do when we have an exception
        }
     }];
}


- (NSDictionary *)prepareLocalPhotoInfo
{
    NSString *fullName = nil;
    if ([AppHelper firstName].length > 0  && [AppHelper lastName].length > 0) {
        fullName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
    }else{
        fullName = [AppHelper userName];
    }
    
    
    //NSString *assetURL = [assetURL absoluteString];
    DLog(@"Uploading photo assetURL: %@",[uploadingImageAssetURL absoluteString]);
    
    //: Prepare photo info here
    NSDictionary *newLocalPhotoInfo = @{@"comments" : @(0), @"id" : @(0), @"likes" : @(0),
                                        @"pictureTaker" : fullName,
                                        @"pictureTakerId" : [AppHelper userID],
                                        @"pictureTakerPhoto" : [AppHelper profilePhotoURL],
                                        @"remixers" : @(0),
                                        @"s3name" : [uploadingImageAssetURL absoluteString],
                                        @"spot" : self.spotName,
                                        @"spotId" : @([self.spotID integerValue]),
                                        @"timestamp" : nameOfImageToUpload,
                                        @"userLikedPhoto" : @"NO",
                                        @"howLong" : @"now"};
    
    return newLocalPhotoInfo;
}



- (NSMutableArray *)prepareMWPhotos:(NSMutableArray *)photoInfo
{
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    MWPhoto *photo;
    
    
        if ([photoInfo count] > 0) { // Do we have some photos to show
            
            //DLog(@"Selected photo info: %@",photoInfo);
            
            for (NSDictionary *info in photoInfo){
                
                NSString *photoURL = nil;
                
                if (selectedPhotoCell.remixedImageView.alpha == 1) {
                    photoURL = info[@"s3RemixName"];
                    
                }else{
                   photoURL = info[@"s3name"];
                }
                
                NSURL *photoSrc = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",kS3_BASE_URL,photoURL]];
                //DLog(@"Selected photo URL: %@",photoSrc);
                
                photo  = [MWPhoto photoWithURL:photoSrc];
                
                [photos addObject:photo];
                
            }
        }
    
    
    
    return photos;
}


- (void)showFbWebDialog:(NSDictionary *)params
{
    [FBWebDialogs presentFeedDialogModallyWithSession:nil
                                           parameters:params
                                              handler:
     ^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
         if (error) {
             // Error launching the dialog or publishing a story.
             //NSLog(@"Error publishing story.");
         } else {
             
             if (result == FBWebDialogResultDialogNotCompleted) {
                 // User clicked the "x" icon
                 //NSLog(@"User canceled story publishing.");
             } else {
                 // Handle the publish feed callback
                 NSDictionary *urlParams = [self parseURLParams:[resultURL query]];
                 if (![urlParams valueForKey:@"post_id"]) {
                     // User clicked the Cancel button
                     //NSLog(@"User canceled story publishing.");
                 } else {
                     
                     // User clicked the Share button
                     /*NSString *msg = [NSString stringWithFormat:
                                      @"Posted story, id: %@",
                                      [urlParams valueForKey:@"post_id"]];
                     //NSLog(@"%@", msg);
                     // Show the result in an alert
                     [[[UIAlertView alloc] initWithTitle:@"Result"
                                                 message:msg
                                                delegate:nil
                                       cancelButtonTitle:@"OK!"
                                       otherButtonTitles:nil]
                      show];*/
                 }
             }
         }
     }];
}


#pragma mark - Facebook Feed Dialog Methods
/**
 * A function for parsing URL parameters.
 */
- (NSDictionary*)parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val =
        [kv[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        params[kv[0]] = val;
    }
    
    return params;
}


#pragma mark - Custom view controller transitions
-(id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    SBTransitionAnimator *transitioningAnimator = [SBTransitionAnimator new];
    transitioningAnimator.presenting = YES;
    CGRect frame = self.view.frame;
    transitioningAnimator.beginTransitionFrame = CGRectMake(frame.size.width/2, frame.size.height/2, 0, 0);
    transitioningAnimator.endTransitionFrame = frame;
    
    DLog(@"transtioning animator: %@",NSStringFromCGRect(transitioningAnimator.beginTransitionFrame));
    return transitioningAnimator;
}


-(id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    SBTransitionAnimator *transitioningAnimator = [SBTransitionAnimator new];
    CGRect frame = self.view.frame;
    transitioningAnimator.beginTransitionFrame = CGRectMake(frame.size.width/2, frame.size.height/2, 0, 0);
    transitioningAnimator.endTransitionFrame = frame;
    
    DLog(@"transtioning animator: %@",NSStringFromCGRect(transitioningAnimator.beginTransitionFrame));
    return transitioningAnimator;
}


#pragma mark - MWPhotoBrowser Delegate methods
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    if (selectedPhotoCell.remixedImageView.alpha == 1) {
        // if the doodle is showing
        return 1;
    }
    
    return (isFiltered) ? [filteredPhotos count] : [self.photos count];
}


- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (mwPhotos) {
        if (index < [mwPhotos count]){
            
            return [mwPhotos objectAtIndex:index];
        }
    }
    
    return nil;
}


- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    
    DLog(@"Did start viewing photo at index %lu\nFrame of page : %@", (unsigned long)index,NSStringFromCGRect([photoBrowser frameForPageAtIndex:index]));
    
    if (index == 0) {
        [UIView animateWithDuration:0 delay:0.2 options:UIViewAnimationOptionTransitionNone animations:^{
            NSArray *tags = self.photos[index][@"photoTags"];
            
            if (tags.count > 0) {
                DLog(@" Tags count: %i",tags.count);
                [self showAllTagsInPhoto:tags inView:photoBrowser.view];
            }
            
        } completion:nil];
        
    }
}



- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser showTagsForPhotoAtIndex:(NSUInteger)index
{
    //DLog();
    [UIView animateWithDuration:0 delay:0.2 options:UIViewAnimationOptionTransitionNone animations:^{
     NSArray *tags = self.photos[index][@"photoTags"];
     
     if (tags.count > 0) {
         DLog(@" Tags count: %i",tags.count);
         [self showAllTagsInPhoto:tags inView:photoBrowser.view];
       }
        
     } completion:nil];
    
}


- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser hideTagsForPhotoAtIndex:(NSUInteger)index
{
    NSArray *subvs = photoBrowser.view.subviews;
    for (UIView *subView in subvs) {
        DLog(@"Class of view - %@",[subView class]);
        
        if ([subView class] == [AMPopTip class]) {
            [subView removeFromSuperview];
        }
        
    }
}


- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    //DLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (IBAction)tagPhoto:(UIButton *)sender
{
    PhotoBrowserViewController *pVC = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoBrowserScene"];
    
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    
    pVC.transitioningDelegate = self;
    pVC.modalPresentationStyle = UIModalPresentationCustom;
    
    NSDictionary *photoInfo = (isFiltered) ? filteredPhotos[indexpath.item] : self.photos[indexpath.item];
    
    NSString *s3name = (isFiltered) ? filteredPhotos[indexpath.item][@"s3name"] :
                                  self.photos[indexpath.item][@"s3name"];
    
    pVC.imageURL = [NSString stringWithFormat:@"%@%@",kS3_BASE_URL,s3name];
    pVC.streamId = self.spotID;
    pVC.imageId = (isFiltered) ? filteredPhotos[indexpath.item][@"id"] : self.photos[indexpath.item][@"id"];
    pVC.imageInfo = photoInfo;
    
    NSArray *tags = self.photos[indexpath.row][@"photoTags"];
    pVC.tagsInPhoto = [NSMutableArray arrayWithArray:tags];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pVC];
    
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [self presentViewController:nc animated:YES completion:nil];
}


#pragma mark - Display tags in photo browser
- (void)showPopTipView:(NSString *)userName usingSubaColor:(BOOL)subaColor fromFrame:(CGRect)fromFrame tag:(NSInteger)tag inView:(UIView *)view
{
    // Change color of tag depending on whether the person being tagged is a Suba user
    if (subaColor) {
        
        [[AMPopTip appearance] setPopoverColor:kSUBA_APP_COLOR];
        [[AMPopTip appearance] setRadius:0];
        
    }else{
        
        [[AMPopTip appearance] setPopoverColor:kSUBA_TAG_COLOR];
        [[AMPopTip appearance] setRadius:0];
        
    }
    
    // Create the pop tip
    AMPopTip *popTip = [AMPopTip popTip];
    popTip.shouldDismissOnTap = NO;
    popTip.shouldDismissOnTapOutside = NO;
    popTip.fromFrame = fromFrame;
    popTip.tag = tag;

    // Show the pop tip
    [popTip showText:userName direction:AMPopTipDirectionDown maxWidth:200.0f
              inView:view fromFrame:fromFrame duration:2.0];
    
    
}




- (void)showAllTagsInPhoto:(NSArray *)tags inView:(UIView *)view
{
    
    for (NSDictionary *tagInfo in tags) {
        
        NSString *nameOfPersonTagged = tagInfo[@"personTagged"];
        BOOL isSubaUser = ( ![tagInfo[@"personTaggedId"] isEqualToString:@"-1"] );
        NSNumber *popTag = tagInfo[@"tagId"];
        NSNumber *xPos = tagInfo[@"xPosition"];
        NSNumber *yPos = tagInfo[@"yPosition"];
        
        CGRect adjustedXAndYPos = [self scaleTagFrameToFitCurrentScreenWithXPos:xPos.floatValue AndYPos:yPos.floatValue];
        
        //DLog(@"Adjusted X and Y for current screen: %@",NSStringFromCGRect(adjustedXAndYPos));
        
        CGRect fromFrame = CGRectMake(adjustedXAndYPos.origin.x, adjustedXAndYPos.origin.y, 0, 0);
        
        [self showPopTipView:nameOfPersonTagged usingSubaColor:isSubaUser
                   fromFrame:fromFrame tag:popTag.integerValue inView:view];
        
    }
}



- (CGRect)scaleTagFrameToFitCurrentScreenWithXPos:(float)xPos AndYPos:(float)yPos
{
    if (xPos < self.view.frame.size.width && yPos < self.view.frame.size.height) {
        return CGRectMake(xPos, yPos, self.view.frame.size.width, self.view.frame.size.height);
    }
    
    
    float newX  = xPos;
    float newY = yPos;
    
    if (newX >= self.view.frame.size.width) {
        newX = (xPos - self.view.frame.size.width) + 50;
    }
    
    
    if (newY >= self.view.frame.size.height) {
        newY = (yPos - self.view.frame.size.height) + 50;
    }
    
    return [self scaleTagFrameToFitCurrentScreenWithXPos:newX AndYPos:newY];
    
}




@end
