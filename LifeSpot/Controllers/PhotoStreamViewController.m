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
#import "AlbumSettingsViewController.h"
#import "AlbumMembersViewController.h"
#import <CTAssetsPickerController.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "LSPushProviderAPIClient.h"
#import "Photo.h"
#import "User.h"
#import "Spot.h"
#import "BDKNotifyHUD.h"
#import <SDWebImage/UIImageView+WebCache.h>

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);

#define SpotInfoKey @"SpotInfoKey"
#define SpotNameKey @"SpotNameKey"
#define SpotIdKey @"SpotIdKey"
#define SpotPhotosKey @"SpotPhotosKey"


@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,CTAssetsPickerControllerDelegate>{
    UIImage *photoToSave;
}

@property (strong,nonatomic) NSDictionary *reportInfo;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;
@property (weak, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;

@property (nonatomic, readwrite) CGRect likeButtonBounds;
@property (nonatomic, strong) UIDynamicAnimator *likeButtonAnimator;


@property (weak, nonatomic) IBOutlet UIView *noPhotosView;
- (IBAction)unWindToPhotoStream:(UIStoryboardSegue *)segue;
- (IBAction)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue;
- (IBAction)sharePhoto:(UIButton *)sender;
- (IBAction)likePicture:(id)sender;
- (void)savePhoto:(UIImage *)imageToSave;
- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)settingsButtonTapped:(id)sender;
- (IBAction)shareAlbumAction:(id)sender;
- (IBAction)showMoreActions:(UIButton *)sender;

- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender;
- (void)savePhotoToCustomAlbum:(UIImage *)photo;
- (void)resizeImage:(UIImage*) image
            towidth:(float) width
           toHeight:(float) height
          completon:(PhotoResizedCompletion)completion;
- (void)showPhotoOptions;
- (void)showReportOptions;
- (void)reportPhoto:(NSDictionary *)reportInfo;
- (IBAction)showMembers:(id)sender;
- (void)loadSpotInfo:(NSString *)spotId User:(NSString *)userId;
- (void)loadSpotImages:(NSString *)spotId;
- (void)updatePhotosNumberOfLikes:(NSMutableArray *)photos photoId:(NSString *)photoId update:(NSString *)likes;
@end

@implementation PhotoStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    
    self.navigationItem.title = (self.spotName) ? self.spotName : @"Spot";
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    if (!self.photos && !self.spotName && self.numberOfPhotos == 0) {
        // We are coming from an activity screen
       [self loadSpotImages:self.spotID];
    }
    DLog(@"Number of photos - %ld",(long)self.numberOfPhotos);
    
    if (!self.photos && self.numberOfPhotos > 0) {
        // We are coming from a place where spotName is not set so lets load spot info
       // DLog(@"Loading spot info");
        [self loadSpotImages:self.spotID];
    }
    
    if(self.numberOfPhotos == 0 && self.spotName){
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
    }

    
    if (self.spotID) {
        DLog(@"SpotId - %@",self.spotID);
       [self loadSpotInfo:self.spotID User:[AppHelper userID]];
    }
    
}

         
-(void)loadSpotImages:(NSString *)spotId
{
   [Spot fetchSpotImagesUsingSpotId:spotId completion:^(id results, NSError *error) {
       if (!error){
           NSArray *allPhotos = [results objectForKey:@"spotPhotos"];
           NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
           NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
           self.photos = [NSMutableArray arrayWithArray:[allPhotos sortedArrayUsingDescriptors:sortDescriptors]];
           
           if ([self.photos count] > 0) {
               DLog(@"Photos in spot - %@",self.photos);
               self.noPhotosView.hidden = YES;
               self.photoCollectionView.hidden = NO;
               [self.photoCollectionView reloadData];
           }else{
                   self.noPhotosView.hidden = NO;
                   self.photoCollectionView.hidden = YES;
             }
           
       }else{
           DLog(@"Error - %@",error);
       }
   }];
}

-(void)loadSpotInfo:(NSString *)spotId User:(NSString *)userId
{
    [Spot fetchSpotInfo:spotId User:userId completion:^(id results, NSError *error) {
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                self.spotInfo = (NSDictionary *)results;
                
                self.spotName = (self.spotName) ? self.spotName : results[@"spotName"];
                self.navigationItem.title = self.spotName;
                [self.photoCollectionView reloadData];
            }
            
        }
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)reportPhoto:(NSDictionary *)reportInfo
{
    [User reportPhoto:reportInfo completion:^(id results, NSError *error) {
        //DLog(@"Results - %@",results);
        
        BDKNotifyHUD *hud = [BDKNotifyHUD notifyHUDWithImage:[UIImage imageNamed:@"Checkmark"]
                                                       text:@"Photo Reported!"];
        
        hud.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
        
        // Animate it, then get rid of it. These settings last 1 second, takes a half-second fade.
        [self.view addSubview:hud];
        [hud presentWithDuration:2.0f speed:0.5f inView:self.view completion:^{
            [hud removeFromSuperview];
            [CSNotificationView showInViewController:self
                                           tintColor: [UIColor colorWithRed:217/255.0 green:77/255.0 blue:20/255.0 alpha:1]
                                               image:nil
                                             message:@"Thank you for your report. We will remove this photo if it violates our Community Guidelines."
                                            duration:5.0f];
        }];
        
        
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
    return [self.photos count];
}




-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DLog(@"Photos - %@",self.photos[0]);
   static NSString *cellIdentifier = @"PhotoStreamCell";
    PhotoStreamCell *photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue(),^{
            [photoCardCell.likePhotoImage setSelected:NO];
    });

    
    [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                         indicator:photoCardCell.loadingPictureIndicator
                              flag:YES];
    
    photoCardCell.pictureTakerView.image = [UIImage imageNamed:@"anonymousUser"];
    //DLog(@"Photos - %@",self.photos[indexPath.row]);
    NSString *photoURLstring = self.photos[indexPath.row][@"s3name"];
    
    if(self.photos[indexPath.row][@"pictureTakerPhoto"]){
        NSString *pictureTakerPhotoURL = self.photos[indexPath.row][@"pictureTakerPhoto"];
        
        [photoCardCell.pictureTakerView setImageWithURL: [NSURL URLWithString:pictureTakerPhotoURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"] options:SDWebImageContinueInBackground];
        
       // [photoCardCell.pictureTakerView setImageWithURL:[NSURL URLWithString:pictureTakerPhotoURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
        
    }
    
    photoCardCell.pictureTakerName.text = self.photos[indexPath.row][@"pictureTaker"];
    photoCardCell.numberOfLikesLabel.text = self.photos[indexPath.row][@"likes"];
    
    
    
    // Download photo card image
    [[S3PhotoFetcher s3FetcherWithBaseURL] downloadPhoto:photoURLstring to:photoCardCell.photoCardImage placeholderImage:[UIImage imageNamed:@"blurBg"] completion:^(id results, NSError *error) {
        
        if (!error) {
            self.albumSharePhoto = (UIImage *)results;
        }
        
        [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                             indicator:photoCardCell.loadingPictureIndicator
                                  flag:NO];
    }];
    
    return photoCardCell;
}



-(void)showMembers:(id)sender{
    [self performSegueWithIdentifier:@"AlbumMembersSegue" sender:self.spotID];
}


- (IBAction)sharePhoto:(UIButton *)sender{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    if (cell.photoCardImage.image != nil) {
        [self share:kPhoto Sender:sender];
    }else{
        [AppHelper showAlert:@"Share Image Request"
                     message:@"You can share image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
    }
}



- (IBAction)likePicture:(id)sender
{
    /*
     UIButton *likeButton = (UIButton *)sender;
    PhotoStreamCell *cell = (PhotoStreamCell *)likeButton.superview.superview.superview;
    NSIndexPath *indexPath = [self.photoCollectionView indexPathForCell:cell];
    DLog(@"Button state - %i",likeButton.state);
    NSString *picId = self.photos[indexPath.item][@"id"];
    
    if (likeButton.state == UIControlStateNormal || likeButton.state == UIControlStateHighlighted){
        //DLog(@"Like\nUserId - %@\nPicId - %@",[AppHelper userID],picId);
        
        NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : picId,@"updateFlag" :@"1"};
        
        [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error) {
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                cell.numberOfLikesLabel.text = results[@"likes"];
                
                [self updatePhotosNumberOfLikes:self.photos photoId:picId update:results[@"likes"]];
                
                BDKNotifyHUD *hud = [BDKNotifyHUD notifyHUDWithImage:[UIImage imageNamed:@"Checkmark"]
                                                                text:@"Photo Liked!"];
                
                hud.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
                
                // Animate it, then get rid of it. These settings last 1 second, takes a half-second fade.
                [self.view addSubview:hud];
                [hud presentWithDuration:2.0f speed:0.5f inView:self.view completion:^{
                    [hud removeFromSuperview];
                }];

                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue(),^{
                    [cell.likePhotoImage setSelected:YES];
                        [UIView animateWithDuration:1.8 animations:^{
                        cell.likePhotoImage.alpha = 0;
                        cell.likePhotoImage.alpha = 1;
                    }];
                });
            }

        }];
    }else{
        //DLog(@"Unlike");
       NSDictionary *params = @{@"userId": [AppHelper userID],@"pictureId" : picId,@"updateFlag" :@"0"};
        
        [[User currentlyActiveUser] likePhoto:params completion:^(id results, NSError *error){
            
            if ([results[STATUS] isEqualToString:ALRIGHT]){
                cell.numberOfLikesLabel.text = results[@"likes"];
                [self updatePhotosNumberOfLikes:self.photos photoId:picId update:results[@"likes"]];
                
                BDKNotifyHUD *hud = [BDKNotifyHUD notifyHUDWithImage:[UIImage imageNamed:@"Checkmark"]
                                                                text:@"Photo Unliked!"];
                
                hud.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
                
                // Animate it, then get rid of it. These settings last 1 second, takes a half-second fade.
                [self.view addSubview:hud];
                [hud presentWithDuration:2.0f speed:0.5f inView:self.view completion:^{
                    [hud removeFromSuperview];
                }];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 10), dispatch_get_main_queue(),^{
                    [cell.likePhotoImage setSelected:NO];
                    [UIView animateWithDuration:1.8 animations:^{
                        cell.likePhotoImage.alpha = 0;
                        cell.likePhotoImage.alpha = 1;
                    }];
                });
            }
            
        }];
    }
     */
        
}


-(void)updatePhotosNumberOfLikes:(NSMutableArray *)photos photoId:(NSString *)photoId update:(NSString *)likes
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
}



- (void)savePhoto:(UIImage *)imageToSave {
    
    if (imageToSave != nil){
        [self savePhotoToCustomAlbum:imageToSave];

    }else{
        [AppHelper showAlert:@"Save Image Request"
                     message:@"You can save image after it loads"
                     buttons:@[@"OK, I'll wait"]
                    delegate:nil];
    }
}


-(void) resizeImage:(UIImage*)image towidth:(float)width toHeight:(float)height completon:(PhotoResizedCompletion)completion
{
    dispatch_queue_t resizePhotoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(resizePhotoQueue, ^{
        
        float actualHeight = image.size.height;
        float actualWidth = image.size.width;
        float imgRatio = actualWidth/actualHeight;
        float maxRatio = width/height;
        if(imgRatio!=maxRatio){
            if(imgRatio < maxRatio){
                imgRatio = width/ actualHeight;
                actualWidth = imgRatio * actualWidth;
                actualHeight = height;
            }
            else{
                imgRatio = width / actualWidth;
                actualHeight = imgRatio * actualHeight;
                actualWidth = width;
            }
        }
        CGRect rect = CGRectMake(0.0, 0.0, actualWidth, actualHeight);
        UIGraphicsBeginImageContext(rect.size);
        [image drawInRect:rect];
        UIImage *resizedImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(),^{
            completion(resizedImg,nil);
        });
    });
    
}

- (IBAction)cameraButtonTapped:(id)sender
{
    [self showPhotoOptions];
}


- (IBAction)settingsButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"SpotSettingsSegue" sender:self.spotID];
}

- (IBAction)shareAlbumAction:(id)sender
{
    [self share:kSpot Sender:sender];
}

-(void)showReportOptions
{
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Why are you reporting photo?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@" This photo is sexually explicit",@"This is photo is unrelated",nil];
    actionsheet.tag = 2000;
    //actionsheet.destructiveButtonIndex = 1;
    [actionsheet showInView:self.view];
  
}


- (IBAction)showMoreActions:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    NSIndexPath *indexpath = [self.photoCollectionView indexPathForCell:cell];
    self.reportInfo = self.photos[indexpath.row];
    photoToSave = cell.photoCardImage.image;
    
    
    
    //DLog(@"Cell - selected - %@\nPhotoInfo - %@",cell.pictureTakerName,self.photos[indexpath.row]);
    
    UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"More Actions"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Save Photo",@"Report Photo", nil];
    actionsheet.tag = 1000;
    actionsheet.destructiveButtonIndex = 1;
    [actionsheet showInView:self.view];
    
}


-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Choose Photo" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose From Gallery", nil];
    
    [action showInView:self.view];
}

#pragma mark - Helpers for Social Media
- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender
{
    NSArray *activityItems = nil;
    NSString *shareText = nil;
    if (objectOfInterest == kSpot) {
        DLog(@"SpotId - %@",self.spotID);
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared album %@ with Suba for iOS @ http://www.subaapp.com/albums?%@",self.navigationItem.title,self.spotID];
        
        
        activityItems = @[self.albumSharePhoto,shareText];
    }else if (objectOfInterest == kPhoto){
        //DLog(@"Photo Cell - %@",sender.superview.superview.superview);
        PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared spot %@ with Suba for iOS.",self.navigationItem.title];
        
        activityItems = @[cell.photoCardImage.image,shareText];
    }
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    [self presentViewController:activityVC animated:YES completion:nil];
  
}


-(void)savePhotoToCustomAlbum:(UIImage *)photo
{
    [self.library saveImage:photo toAlbum:@"Suba Photos" completion:^(NSURL *assetURL, NSError *error) {
        [AppHelper showNotificationWithMessage:@"Image saved in camera roll" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
    }failure:^(NSError *error){
        [AppHelper showAlert:@"Save image error"
                     message:@"There was an error saving the photo"
                     buttons:@[@"OK"]
                    delegate:nil];
    }];
}


- (void)pickAssets
{
    
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.maximumNumberOfSelection = 1;
    picker.assetsFilter = [ALAssetsFilter allPhotos];
    picker.delegate = self;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Assets Picker Delegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    //[self.assets addObjectsFromArray:assets];
    ALAsset *asset = (ALAsset *)assets[0];
    ALAssetRepresentation *representation = asset.defaultRepresentation;
    UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage
                                                       scale:1.0f
                                                 orientation:(UIImageOrientation)representation.orientation];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //dateFormatter se
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
    
    //NSLog(@"Asset  Picked - %@ at time - %@",[asset debugDescription],trimmedString);
    [self resizeImage:fullResolutionImage towidth:320.0f toHeight:320.0f
            completon:^(UIImage *compressedPhoto, NSError *error) {
                
                UIImage *newImage = compressedPhoto;
                NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
                
                [self uploadPhoto:imageData WithName:trimmedString];
                
            }];
}



-(void)pickPhoto:(PhotoSourceType)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
       
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        if (sourceType == kTakeCamera) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = NO;
        }else if(sourceType == kGallery){
            [self pickAssets];
        }
        
        
        
        [self presentViewController:imagePicker animated:YES completion:nil];
       
        
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}



#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DLog(@"photo info - %@",self.reportInfo);
    if (actionSheet.tag == 1000) {
        if(buttonIndex == 0){
            //User wants to save photo
            [self savePhoto:photoToSave];
        }
           
    }else if(actionSheet.tag == 2000){
        // User is reporting a photo
        NSString *reportType = nil;
        if (buttonIndex == kSexuallyExplicit){
            reportType = kSEXUALLY_EXPLICIT;
            
            
        }else{
            reportType = kUNRELATED_PHOTO;
           DLog(@"Photo is unrelated");
        }
        
        // form report photo info
        NSDictionary *params = @{
                                 @"photoId":self.reportInfo[@"id"],
                                 @"spotId" : self.reportInfo[@"spotId"],
                                 @"pictureTakerName" : self.reportInfo[@"pictureTaker"],
                                 @"reporterId" : [AppHelper userID],
                                 @"reportType" : reportType
                                 };
        [self reportPhoto:params];
    }
    
    else{
    
    if (buttonIndex == kTakeCamera) {
        // Call the Camera here
        [self pickPhoto:kTakeCamera];
        
    }else if (buttonIndex == kGallery){
        // Choose from the Gallery
        [self pickPhoto:kGallery];
    }
}
    //NSLog(@"Button Clicked is %li",(long)buttonIndex);
    //[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
}


-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1000) {
        if (buttonIndex == 1) {
            [self showReportOptions];
        }
    }
}


#pragma mark - UIImagePickerController Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
   
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //dateFormatter se
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];

    [self resizeImage:image towidth:320.0f toHeight:320.0f
           completon:^(UIImage *compressedPhoto, NSError *error) {
                
                UIImage *newImage = compressedPhoto;
               NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
               
               [self uploadPhoto:imageData WithName:trimmedString];
        }];
    
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)uploadPhoto:(NSData *)imageData WithName:(NSString *)name
{
    NSString *userId = [User currentlyActiveUser].userID;
    NSString *spotId = self.spotID;
    
    NSDictionary *params = @{@"userId": userId,@"spotId": spotId};
    AFHTTPSessionManager *manager = [LifespotsAPIClient manager];
    
    NSURL *baseURL = (NSURL *)[LifespotsAPIClient lifespotsAPIBaseURL];
    
    NSString *urlPath = [[NSURL URLWithString:@"spot/picture/add" relativeToURL:baseURL] absoluteString];
    
    NSMutableURLRequest *request = [manager.requestSerializer
                                    multipartFormRequestWithMethod:@"POST"
                                    URLString:urlPath
                                    parameters:params
                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData){
                                        
                                        [formData appendPartWithFileData:imageData name:@"picture" fileName:[NSString stringWithFormat:@"%@.jpg",name] mimeType:@"image/jpeg"];
                                    }];
    
    
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:request];
    __weak AFURLConnectionOperation *woperation = operation;
    
    self.imageUploadProgressView.hidden = NO;
    
    [operation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        //DLog(@"Upload progress value -  %f",(float) totalBytesWritten / totalBytesExpectedToWrite);
        self.imageUploadProgressView.progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
        if (self.imageUploadProgressView.progress == 1.0){
            self.imageUploadProgressView.hidden = YES; // or remove from superview
            
        }
    }];
    
    [operation setCompletionBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //NSLog(@"response - %@",woperation.responseData);
            NSError *error = nil;
            // Check for when we are getting a nil data parameter back
            NSDictionary *photoInfo = [NSJSONSerialization JSONObjectWithData:woperation.responseData options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                DLog(@"Error serializing %@", error);
            }else{
                //DLog(@"PhotoInfo - %@",photoInfo);
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                self.noPhotosView.hidden = YES;
                self.photoCollectionView.hidden = NO;
                if (!self.photos) {
                    
                    self.photos = [NSMutableArray arrayWithObject:photoInfo];
                }else [self.photos insertObject:photoInfo atIndex:0];
                
                [self upDateCollectionViewWithCapturedPhoto:photoInfo];
            }
    });
        
        //[self.photos insertObject:image atIndex:0];
        
    }];
    
    [operation start];
}

-(void)upDateCollectionViewWithCapturedPhoto:(NSDictionary *)photoInfo{
    
    //[self.photos insertObject:photo atIndex:0];
    //[self updateNumberOfPhotoLabel];
    [self.photoCollectionView performBatchUpdates:^{
        [self.photoCollectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
    } completion:^(BOOL finished) {
        [self.photoCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
    }];
    
    // Tell push provider to send
    
    
    
    NSArray *members = self.spotInfo[@"members"];
    
    NSMutableArray *memberIds = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *member in members) {
        [memberIds addObject:member[@"id"]];
    }
    
    NSDictionary *params = @{@"spotId": self.spotID,
                             @"spotName" : self.spotName,
                             @"memberIds" : [memberIds description]};
    
    //DLog(@"Params - %@",params);
    
    [[LSPushProviderAPIClient sharedInstance] POST:@"photosadded"
                                        parameters:params
                         constructingBodyWithBlock:nil
                                           success:^(NSURLSessionDataTask *task, id responseObject) {
        DLog(@"From push provider - %@",responseObject);
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        DLog(@"Error - %@",error);
    }];
    
}


#pragma mark - Segues
-(void)unWindToPhotoStream:(UIStoryboardSegue *)segue
{
    
}

-(void)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue
{
    AlbumSettingsViewController *albumVC = segue.sourceViewController;
    self.navigationItem.title = albumVC.spotName;
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SpotSettingsSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[AlbumSettingsViewController class]]) {
            AlbumSettingsViewController *albumVC = segue.destinationViewController;
            albumVC.spotID = (NSString *)sender;
        }
    }
    
    if ([segue.identifier isEqualToString:@"AlbumMembersSegue"]) {
        if ([segue.destinationViewController isKindOfClass:[AlbumMembersViewController class]]) {
            AlbumMembersViewController *membersVC = segue.destinationViewController;
            membersVC.spotID = sender;
            DLog(@"SpotID of %@ sent",membersVC.spotID);
        }
    }
}




#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    [coder encodeObject:self.spotName forKey:SpotNameKey];
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.photos forKey:SpotPhotosKey];
    //[coder encodeObject:@(selectedButton) forKey:SelectedButtonKey];
    DLog();
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.spotInfo = [coder decodeObjectForKey:SpotInfoKey];
    self.spotName = [coder decodeObjectForKey:SpotNameKey];
    self.spotID = [coder decodeObjectForKey:SpotIdKey];
    self.photos = [coder decodeObjectForKey:SpotPhotosKey];
    
    DLog(@"SpotId - %@",self.spotID);
    
}

-(void)applicationFinishedRestoringState
{
    //1. Update photos
    if (self.photos) {
        [self.photoCollectionView reloadData];
    }
    
    if (self.spotID) {
        [self loadSpotImages:self.spotID];
    }
    
    if (self.spotName) {
        //DLog(@"SpotName - %@\nSpotId - %@",self.spotName,self.spotID);
        self.navigationItem.title = self.spotName;
    }
    
    //2. If spotInfo is nil,loadspotInfo
    if (self.spotID && !self.spotInfo) {
        [self loadSpotInfo:self.spotID User:[AppHelper userID]];
    }
    
    DLog();
}







@end
