//
//  ProfileSettingsViewController.m
//  LifeSpots
//
//  Created by Agana-Nsiire Agana on 10/23/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "ProfileSettingsViewController.h"
#import "User.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import <AviarySDK/AviarySDK.h>

@interface ProfileSettingsViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate,AVYPhotoEditorControllerDelegate>

@property (strong,nonatomic) UIImage *profilePhoto;
@property (strong,nonatomic) NSString *userName;
@property (strong,nonatomic) NSString *email;
@property (strong,nonatomic) UIImage *capturedPhoto;
@property (strong,nonatomic) NSMutableDictionary *userUpdatedInfo;

//@property (weak, nonatomic) IBOutlet UILabel *changesSavedLabel;
@property (weak, nonatomic) IBOutlet UIView *savingUserChangesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *savingUserChangesIndicatorView;


@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *usernameCheck;

@property (retain, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *userChangesDoneBarButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *usrNameField;
//@property (weak, nonatomic) IBOutlet UITextField *usrEmailField;
@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UIButton *changeProfilePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *changePasswordBtn;
@property (weak, nonatomic) IBOutlet UILabel *connectedToFacebookLabel;
@property (weak, nonatomic) IBOutlet UILabel *changeProfilePhotoLabel;

- (IBAction)unWindToProfileSettings:(UIStoryboardSegue *)segue;
- (IBAction)updateUsrDetails:(id)sender;
- (IBAction)changeProfilePhotoTapped:(id)sender;
- (IBAction)dismissKeypad:(id)sender;
- (void)showPhotoOptions;
- (void)userInfo;
- (void)pickAssets;
- (void)pickPhoto:(id)sender;
- (void)accountConnectedToFacebook;

- (IBAction)passwordModalDonePresenting:(UIStoryboardSegue *)segue;
@end

@implementation ProfileSettingsViewController

-(IBAction)passwordModalDonePresenting:(UIStoryboardSegue *)segue
{
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.profilePictureView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.profilePictureView.layer.borderWidth = 2;
    self.userUpdatedInfo = [NSMutableDictionary dictionary];
    
    [self accountConnectedToFacebook];
    [self userInfo];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self accountConnectedToFacebook];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)updateUsrDetails:(id)sender{
    
    if (!self.userUpdatedInfo[@"picName"]){
        [self.userUpdatedInfo addEntriesFromDictionary:@{@"imageData": @""}];
        [self.userUpdatedInfo addEntriesFromDictionary:@{@"picName": @"UNCHANGED"}];
    }
    
    User *user = [User currentlyActiveUser];
    NSMutableDictionary *urlFormEncodedParams = [NSMutableDictionary dictionary];
    
    // First check the full name
    if ([self.firstNameField.text isEqualToString:@""] && !self.userUpdatedInfo[@"picName"] && [self.usrNameField.text isEqualToString:[AppHelper userName]]) {
        //FullName is not set so we show a notification
        
        [AppHelper showNotificationWithMessage:@"Please choose a name"
                                          type:kSUBANOTIFICATION_ERROR
                              inViewController:self
                               completionBlock:nil];
        return;
    }
    
    if ([self.userName isEqualToString:@""]) {
        //Username is not set so we show a notification
        
        [AppHelper showNotificationWithMessage:@"Please choose a username"
                                          type:kSUBANOTIFICATION_ERROR
                              inViewController:self
                               completionBlock:nil];
        return;
    }
    
    // We are here if everything is fine
    
    NSString *firstName = self.firstNameField.text;
    NSString *lastName = self.lastNameField.text;
    self.userName = self.usrNameField.text;
    //self.email = self.usrEmailField.text;
    
    //NSArray *fullNameSeparated = [fullName componentsSeparatedByString:@" "];
        //NSLog(@"Full Name is separated - %@",[fullNameSeparated debugDescription]);
        
        if (firstName.length > 0 && lastName.length <= 0){
            
            [urlFormEncodedParams addEntriesFromDictionary:@{@"firstName": firstName}];
        }else if(firstName.length > 0 && lastName.length > 0){
            
            [urlFormEncodedParams addEntriesFromDictionary:@{@"firstName": firstName}];
            [urlFormEncodedParams addEntriesFromDictionary:@{@"lastName": lastName}];
        }
        
    if (![self.userName isEqualToString:[AppHelper userName]]) {
        [urlFormEncodedParams addEntriesFromDictionary:@{@"userName": self.userName}];
     }
    
   /* if (![self.email isEqualToString:[AppHelper userEmail]]) {
        [urlFormEncodedParams addEntriesFromDictionary:@{@"email": self.email}];
    }*/
    
        [urlFormEncodedParams addEntriesFromDictionary:@{@"userId": user.userID}];
    
        [self.userUpdatedInfo addEntriesFromDictionary:@{@"form-encoded" : urlFormEncodedParams}];
        
        
       DLog(@"UserInfoBeing Sent -  %@",[self.userUpdatedInfo debugDescription]);
    
    if ([urlFormEncodedParams objectForKey:@"userName"]) {
        [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:YES];
        [AppHelper checkUserName:[urlFormEncodedParams objectForKey:@"userName"] completionBlock:^(id results, NSError *error) {
            DLog(@"Back from checking username");
            if (error) {
                DLog(@"Error - %@",error);
            }else{
                if ([results[STATUS] isEqualToString:ALRIGHT]) {
                    //Newly entered username is available so we update
                    DLog(@"Updating profile info");
                    [user updateProfileInfo:self.userUpdatedInfo completion:^(id results, NSError *error) {
                        if (error) {
                            // Analytics to show requests failing
                            DLog(@"Update ProfileInfo Error - %@",error);
                            
                    }else{
                        NSDictionary *userInfo = results;
                        if (results[@"profilePhotoURL"]) {
                            [AppHelper setProfilePhotoURL:results[@"profilePhotoURL"]];
                        }
                         [AppHelper setFirstName:results[@"firstName"]];
                         [AppHelper setLastName:results[@"lastName"]];
                         [AppHelper setUserName:results[@"userName"]];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        
                            DLog(@"User updated info from server - %@",userInfo);
                            // Unwind segue to User settings
                            [AppHelper showNotificationWithMessage:@"Profile info saved" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                        
                        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1000), dispatch_get_main_queue(), ^{
                            [self performSegueWithIdentifier:@"UNWIND_TO_USER_SETTINGS_SEGUE" sender:nil];
                       // });
                        
                        }
                        [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:NO];
                    }];
                }else{
                    // Username is not available
                    [AppHelper showNotificationWithMessage:@"Username is already taken" type:kSUBANOTIFICATION_ERROR inViewController:self completionBlock:nil];
                }
            }
            [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:NO];
        }];
    }else{
        // Just update the user info
        [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:YES];
        //DLog(@"Username is not set so we are just updating info");
        
        [user updateProfileInfo:self.userUpdatedInfo completion:^(id results, NSError *error) {
            if (error) {
                // Analytics to show requests failing
                //DLog(@"Update ProfileInfo Error - %@",error);
                
            }else{
                NSDictionary *userInfo = results;
                DLog(@"User updated info from server - %@",userInfo);
                
                if (results[@"profilePhotoURL"]) {
                    [AppHelper setProfilePhotoURL:results[@"profilePhotoURL"]];
                }
                
                // Unwind segue to User settings
                [AppHelper showNotificationWithMessage:@"Profile info saved" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                [AppHelper savePreferences:userInfo];
                
                    [self performSegueWithIdentifier:@"UNWIND_TO_USER_SETTINGS_SEGUE" sender:nil];
                
            }
            [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:NO];
        }];
    }
    
    
   
    
}


- (IBAction)changeProfilePhotoTapped:(id)sender{
    //[self openCamera];
    [self showPhotoOptions];
}


- (IBAction)dismissKeypad:(id)sender {
    [self.firstNameField resignFirstResponder];
    [self.usrNameField resignFirstResponder];
}

-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Choose Photo" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take New Photo",@"Choose Existing Photo", nil];
    
    [action showInView:self.view];
}

- (void)pickAssets
{
    
    //[self presentViewController:picker animated:YES completion:NULL];
}

#pragma mark - Assets Picker Delegate
- (void)openNativeCamera:(UIImagePickerControllerSourceType)sourceType
    {
        UIImagePickerController *nativepickerController = [[UIImagePickerController alloc] init];
        nativepickerController.delegate = self;
        nativepickerController.sourceType = sourceType;
        
        NSArray *sourceTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        
        if ([sourceTypes containsObject:@"public.image"]) {
            if (sourceType == UIImagePickerControllerSourceTypeCamera) {
                DLog(@"Camera source types: %@",sourceTypes);
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

/*- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    UIImage *fullResolutionImage = [UIImage imageWithCGImage:image.CGImage
                                                       scale:1.0f
                                                 orientation:(UIImageOrientation)ALAssetOrientationUp];
    
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];

    self.profilePictureView.image = fullResolutionImage;
    NSString *picName = [NSString stringWithFormat:@"%@_%@.jpg",[AppHelper userName],trimmedString];
    
    NSData *imageData = UIImageJPEGRepresentation(fullResolutionImage, 1);
    [self.userUpdatedInfo addEntriesFromDictionary:@{@"imageData": imageData}];
    [self.userUpdatedInfo addEntriesFromDictionary:@{@"picName": picName}];
    
    //NSLog(@"Image Data Added to the userUpdatedInfo Dictionary");
    self.userChangesDoneBarButtonItem.enabled = YES;
    
    [cameraViewController dismissViewControllerAnimated:NO completion:^{
        self.userChangesDoneBarButtonItem.enabled = YES;
    }];
}


- (void)dismissCamera:(id)cameraViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    [cameraViewController restoreFullScreenMode];
}*/


#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kTakePhotoWithCamera) {
        // Call the Camera here
        [self openNativeCamera:UIImagePickerControllerSourceTypeCamera];
        
    }else if (buttonIndex == kChooseFromGallery){
        // Choose from the Gallery
        [self openNativeCamera:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    //NSLog(@"Button Clicked is %li",(long)buttonIndex);
    [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
}




-(void)pickPhoto:(id)sourceType
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        
         if ([mediaTypes containsObject:@"public.image"]){
        
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        if ([sourceType intValue] == kTakePhotoWithCamera) {
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.delegate = self;
            //imagePicker.allowsEditing = YES;

            [self presentViewController:imagePicker animated:YES completion:nil];
        }else if([sourceType intValue] == kChooseFromGallery){
            //imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self pickAssets];
            //[self presentViewController:imagePicker animated:YES completion:nil];
        }
        
    }
        
    }else{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        
    }
}


#pragma mark - UITextFieldDelegate Methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}



-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.userChangesDoneBarButtonItem.enabled = YES;
    if (textField==self.usrNameField) {
        self.userName = self.usrNameField.text;
    }
    
    return YES;
}


#pragma mark - UIIMagePickerController Delegate methods
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    [FBAppEvents logEvent:@"Photo_Taken"];
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSData *img = UIImageJPEGRepresentation(image, 1.0);
    
    DLog(@"Size of image - %fKB",[img length]/1024.0f);
    [picker dismissViewControllerAnimated:YES completion:^{
        DLog(@"Lets display aviary");
        [self displayEditorForImage:image];
    }];
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    // Resetting the status bar here
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


-(void)userInfo
{
    [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",[AppHelper profilePhotoURL]]] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    
    //DLog(@"Profile photo URL - %@",[AppHelper profilePhotoURL]);
    
    if ([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL){
        self.firstNameField.placeholder = @"First Name";
    }else{
        //self.fullName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
        self.firstNameField.text = [AppHelper firstName];
        self.lastNameField.text = [AppHelper lastName];
    }
    
    self.usrNameField.text = [AppHelper userName];
    //self.usrEmailField.text = [AppHelper userEmail];
    //DLog(@"Name class - %@",[[AppHelper firstName] class]);
}


#pragma mark - Segues
-(void)unWindToProfileSettings:(UIStoryboardSegue *)segue
{
    
}

-(void)accountConnectedToFacebook
{
    if ([[AppHelper facebookLogin] isEqualToString:@"YES"]){
        // The user's account is connected to Facebook
        self.connectedToFacebookLabel.hidden = NO;
        self.firstNameField.enabled = NO;
        self.lastNameField.enabled = NO;
        self.usrNameField.enabled = NO;
        self.changeProfilePhotoButton.enabled = NO;
        self.changePasswordBtn.hidden = YES;
        self.changeProfilePhotoLabel.hidden = YES;
    }else{
        self.connectedToFacebookLabel.hidden = YES;
        self.firstNameField.enabled = YES;
        self.lastNameField.enabled = YES;
        self.usrNameField.enabled = YES;
        self.changeProfilePhotoButton.enabled = YES;
        self.changePasswordBtn.hidden = NO;
        self.changeProfilePhotoLabel.hidden = NO;
    }
}


#pragma mark - AFPhotoEditorDelegate
- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    
    // Handle the result image here
    [editor dismissViewControllerAnimated:YES completion:^{
        // Upload the image after we have dismissed the editor
        
        self.profilePictureView.image = image;
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
        NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
        trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
        trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];
        
        
        NSString *picName = [NSString stringWithFormat:@"%@_%@.jpg",[AppHelper userName],trimmedString];
        
        NSData *imageData = UIImageJPEGRepresentation(image, .8);
        [self.userUpdatedInfo addEntriesFromDictionary:@{@"imageData": imageData}];
        [self.userUpdatedInfo addEntriesFromDictionary:@{@"picName": picName}];
        
        //NSLog(@"Image Data Added to the userUpdatedInfo Dictionary");
        self.userChangesDoneBarButtonItem.enabled = YES;
        self.userChangesDoneBarButtonItem.enabled = YES;
    }];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    // Handle cancellation here
    [editor dismissViewControllerAnimated:YES completion:nil];
}


- (void)displayEditorForImage:(UIImage *)imageToEdit
{
    //DLog(@"Displaying aviary 1");
    
    // Define Aviary API Key and Secret
    //static dispatch_once_t onceToken;
    
    //dispatch_once(&onceToken, ^{
    [AFPhotoEditorController setAPIKey:kAviaryAPIKey secret:kAviarySecret];
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:imageToEdit];
    [editorController setDelegate:self];
    
    // Customize the tools that appear
    // Set the tools to Contrast, Brightness, Enhance, and Crop (to be displayed in that order).
    [AFPhotoEditorCustomization setToolOrder:@[kAVYEnhance,kAVYEffects,kAVYCrop,kAVYOrientation]];
    
    //DLog(@"Displaying aviary 2");
    [self presentViewController:editorController animated:YES completion:nil];
    
    // });
}

@end
