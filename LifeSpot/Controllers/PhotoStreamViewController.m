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
#import "Photo.h"
#import "User.h"
#import "Spot.h"

typedef void (^PhotoResizedCompletion) (UIImage *compressedPhoto,NSError *error);

@interface PhotoStreamViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,CTAssetsPickerControllerDelegate>

@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong,atomic) ALAssetsLibrary *library;
@property (strong,nonatomic) UIImage *albumSharePhoto;
@property (weak, nonatomic) IBOutlet UIProgressView *imageUploadProgressView;
@property (weak, nonatomic) IBOutlet UICollectionView *photoCollectionView;

@property (weak, nonatomic) IBOutlet UIView *noPhotosView;
- (IBAction)unWindToPhotoStream:(UIStoryboardSegue *)segue;
- (IBAction)unWindToPhotoStreamWithWithInfo:(UIStoryboardSegue *)segue;
- (IBAction)sharePhoto:(UIButton *)sender;
- (IBAction)likePicture:(UIButton *)sender;
- (IBAction)savePhoto:(UIButton *)sender;
- (IBAction)cameraButtonTapped:(id)sender;
- (IBAction)settingsButtonTapped:(id)sender;
- (IBAction)shareAlbumAction:(id)sender;

- (void)share:(Mutant)objectOfInterest Sender:(UIButton *)sender;
- (void)savePhotoToCustomAlbum:(UIImage *)photo sender:(UIButton *)sender;
- (void)resizeImage:(UIImage*) image
            towidth:(float) width
           toHeight:(float) height
          completon:(PhotoResizedCompletion)completion;
- (void)showPhotoOptions;
- (void)showMembers;
- (void)loadSpotInfo:(NSString *)spotId User:(NSString *)userId;
- (void)loadSpotImages:(NSString *)spotId;
@end

@implementation PhotoStreamViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.noPhotosView.hidden = YES;
    
    self.navigationItem.title = (self.spotName) ? self.spotName : @"Spot";
    UIBarButtonItem *membersButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@""
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(showMembers)];
    [membersButton setImage:[UIImage imageNamed:@"members"]];
    self.navigationItem.rightBarButtonItem = membersButton;
   
    //self.navigationItem.rightBarButtonItem
    self.library = [[ALAssetsLibrary alloc] init];
    
    if (!self.photos && self.numberOfPhotos > 0) {
        // We are coming from a place where spotName is not set so lets load spot info
        DLog(@"Loading spot info");
        [self loadSpotImages:self.spotID];
    }
    
    if(self.numberOfPhotos == 0){
        self.noPhotosView.hidden = NO;
        self.photoCollectionView.hidden = YES;
    }
}

         
-(void)loadSpotImages:(NSString *)spotId
{
   [Spot fetchSpotImagesUsingSpotId:spotId completion:^(id results, NSError *error) {
       if (!error){
           self.photos = [results objectForKey:@"spotPhotos"];
           if ([self.photos count] > 0) {
               [self.photoCollectionView reloadData];
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
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                self.spotInfo = (NSDictionary *)results;
                //[self updateSpotView:self.spotInfo];
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


#pragma mark - UICollectionView Datasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.photos count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *cellIdentifier = @"PhotoStreamCell";
    PhotoStreamCell *photoCardCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //DLog(@"Photos - %@",self.photos[indexPath.row]);
    NSString *photoURLstring = self.photos[indexPath.row][@"s3name"];
    
    if(self.photos[indexPath.row][@"pictureTakerPhoto"]){
        NSString *pictureTakerPhotoURL = self.photos[indexPath.row][@"pictureTakerPhoto"];
        [photoCardCell.pictureTakerView setImageWithURL:[NSURL URLWithString:pictureTakerPhotoURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    }
    
    photoCardCell.pictureTakerName.text = self.photos[indexPath.row][@"pictureTaker"];
    photoCardCell.numberOfLikesLabel.text = self.photos[indexPath.row][@"likes"];
    
    [AppHelper showLoadingDataView:photoCardCell.loadingPictureView
                         indicator:photoCardCell.loadingPictureIndicator
                              flag:YES];
    
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


-(void)showMembers{
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



- (IBAction)likePicture:(UIButton *)sender {
}

- (IBAction)savePhoto:(UIButton *)sender {
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    if (cell.photoCardImage.image != nil) {
        [AppHelper showLoadingDataView:cell.loadingPictureView
                             indicator:cell.loadingPictureIndicator
                                  flag:YES];
        [self savePhotoToCustomAlbum:cell.photoCardImage.image sender:sender];

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
        shareText = [NSString stringWithFormat:@"Check out all the photos in my shared spot %@ with Suba for iOS @ http://www.subaapp.com",self.navigationItem.title];
        
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


-(void)savePhotoToCustomAlbum:(UIImage *)photo sender:(UIButton *)sender
{
    PhotoStreamCell *cell = (PhotoStreamCell *)sender.superview.superview.superview;
    [self.library saveImage:photo toAlbum:@"Suba" completion:^(NSURL *assetURL, NSError *error) {
        [AppHelper showLoadingDataView:cell.loadingPictureView
                             indicator:cell.loadingPictureIndicator
                                  flag:NO];
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
    UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullResolutionImage
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
        }else if(sourceType == kGallery){
            [self pickAssets];
        }
        
        imagePicker.delegate = self;
        imagePicker.allowsEditing = NO;
        
        [self presentViewController:imagePicker animated:YES completion:nil];
       
        
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}



#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kTakeCamera) {
        // Call the Camera here
        [self pickPhoto:kTakeCamera];
        
    }else if (buttonIndex == kGallery){
        // Choose from the Gallery
        [self pickPhoto:kGallery];
    }
    //NSLog(@"Button Clicked is %li",(long)buttonIndex);
    [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
    
}


#pragma mark - UIImagePickerController Delegate
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
   
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self resizeImage:image towidth:320.0f toHeight:320.0f
            completon:^(UIImage *compressedPhoto, NSError *error) {
                
                NSDictionary *imageMetaData = info[UIImagePickerControllerMediaMetadata];
                NSDictionary *imageInfo = [imageMetaData valueForKey:@"{TIFF}"];
                NSString *photoTimestamp = imageInfo[@"DateTime"];
                
                NSString *trimmedString = [photoTimestamp stringByReplacingOccurrencesOfString:@" " withString:@""];
                //NSLog(@"Timestamp - %@",trimmedString);
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
        
        self.imageUploadProgressView.progress = (float) totalBytesWritten / totalBytesExpectedToWrite;
        if (self.imageUploadProgressView.progress == 1.0) {
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
                DLog(@"PhotoInfo - %@",photoInfo);
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

@end
