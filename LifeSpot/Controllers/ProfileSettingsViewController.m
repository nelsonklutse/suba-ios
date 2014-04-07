//
//  ProfileSettingsViewController.m
//  LifeSpots
//
//  Created by Agana-Nsiire Agana on 10/23/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "ProfileSettingsViewController.h"
#import "User.h"
#import <CTAssetsPickerController.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
//#import <CXAlertView/CXAlertView.h>

@interface ProfileSettingsViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate,UITextFieldDelegate,CTAssetsPickerControllerDelegate>

@property (strong,nonatomic) UIImage *profilePhoto;
@property (strong,nonatomic) NSString *fullName;
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
@property (weak, nonatomic) IBOutlet UITextField *usrFullNameField;
@property (weak, nonatomic) IBOutlet UIImageView *profilePictureView;
@property (weak, nonatomic) IBOutlet UIButton *changeProfilePhotoButton;

- (IBAction)unWindToProfileSettings:(UIStoryboardSegue *)segue;
- (IBAction)updateUsrDetails:(id)sender;
- (IBAction)changeProfilePhotoTapped:(id)sender;
- (IBAction)dismissKeypad:(id)sender;
- (void)showPhotoOptions;
- (void)userInfo;
- (void)pickAssets;
- (void)pickPhoto:(id)sender;
@end

@implementation ProfileSettingsViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.profilePictureView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.userUpdatedInfo = [NSMutableDictionary dictionary];
    
    
    [self userInfo];
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
    if ([self.usrFullNameField.text isEqualToString:@""] && !self.userUpdatedInfo[@"picName"] && [self.usrNameField.text isEqualToString:[AppHelper userName]]) {
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
    
    self.fullName = self.usrFullNameField.text;
    self.userName = self.usrNameField.text;
    //self.email = self.usrEmailField.text;
    
    NSArray *fullNameSeparated = [self.fullName componentsSeparatedByString:@" "];
        //NSLog(@"Full Name is separated - %@",[fullNameSeparated debugDescription]);
        
        if ([fullNameSeparated count] == 1) {
            NSString *firstName = fullNameSeparated[0];
            
            [urlFormEncodedParams addEntriesFromDictionary:@{@"firstName": firstName}];
        }else{
            NSString *firstName = fullNameSeparated[0];
            NSString *lastName = fullNameSeparated[1];
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
        
        
       // DLog(@"UserInfoBeing Sent -  %@",[self.userUpdatedInfo debugDescription]);
    
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
                // Unwind segue to User settings
                [AppHelper showNotificationWithMessage:@"Profile info saved" type:kSUBANOTIFICATION_SUCCESS inViewController:self completionBlock:nil];
                [AppHelper savePreferences:userInfo];
                
                    [self performSegueWithIdentifier:@"UNWIND_TO_USER_SETTINGS_SEGUE" sender:nil];
                
            }
            [AppHelper showLoadingDataView:self.savingUserChangesView indicator:self.savingUserChangesIndicatorView flag:NO];
        }];
    }
    
    
   
    
}


- (IBAction)changeProfilePhotoTapped:(id)sender {
    [self showPhotoOptions];
}


- (IBAction)dismissKeypad:(id)sender {
    [self.usrFullNameField resignFirstResponder];
    [self.usrNameField resignFirstResponder];
}

-(void)showPhotoOptions
{
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Choose Photo" delegate:self cancelButtonTitle:@"Not Now" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo",@"Choose From Gallery", nil];
    
    [action showInView:self.view];
}

- (void)pickAssets
{
    
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.navigationBar.translucent = NO;
    picker.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
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
    UIImage *fullResolutionImage = [UIImage imageWithCGImage:representation.fullScreenImage                                                       scale:1.0f
                                                 orientation:(UIImageOrientation)ALAssetOrientationUp];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //dateFormatter se
    
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
    [picker dismissViewControllerAnimated:NO completion:^{
        self.userChangesDoneBarButtonItem.enabled = YES;
    }];
}


#pragma mark - UIActionSheet Delegate Methods
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kTakePhotoWithCamera) {
        // Call the Camera here
        //[self pickPhoto:kTakePhotoWithCamera];
        [self performSelector:@selector(pickPhoto:) withObject:@(kTakePhotoWithCamera) afterDelay:0.5];
    }else if (buttonIndex == kChooseFromGallery){
        // Choose from the Gallery
        //[self pickPhoto:kChooseFromGallery];
        
        [self performSelector:@selector(pickPhoto:) withObject:@(kChooseFromGallery) afterDelay:0.5];
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
    //DLog(@"media info - %@",info);
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    self.profilePictureView.image = image;
    
    //NSDictionary *imageMetaData = info[UIImagePickerControllerMediaMetadata];
    //NSDictionary *imageInfo = [imageMetaData valueForKey:@"{TIFF}"];
    //NSString *photoTimestamp = imageInfo[@"DateTime"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //dateFormatter se
    
    [dateFormatter setDateFormat:@"yyyy:MM:dd HH:mm:ss.SSSSSS"];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString *trimmedString = [timeStamp stringByReplacingOccurrencesOfString:@" " withString:@""];
    trimmedString = [trimmedString stringByReplacingOccurrencesOfString:@"-" withString:@":"];
    trimmedString = [trimmedString stringByReplacingCharactersInRange:NSMakeRange([trimmedString length]-7, 7) withString:@""];

    
    NSString *picName = [NSString stringWithFormat:@"%@_%@.jpg",[AppHelper userName],trimmedString];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1);
    [self.userUpdatedInfo addEntriesFromDictionary:@{@"imageData": imageData}];
    [self.userUpdatedInfo addEntriesFromDictionary:@{@"picName": picName}];
    
    //NSLog(@"Image Data Added to the userUpdatedInfo Dictionary");
    self.userChangesDoneBarButtonItem.enabled = YES;
    [picker dismissViewControllerAnimated:NO completion:^{
        self.userChangesDoneBarButtonItem.enabled = YES;
    }];

}



-(void)userInfo
{
    [self.profilePictureView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",[AppHelper profilePhotoURL]]] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    
    //DLog(@"Profile photo URL - %@",[AppHelper profilePhotoURL]);
    
    if ([[AppHelper firstName] isEqualToString:@""] || [AppHelper firstName] == NULL){
        self.usrFullNameField.placeholder = @"Full Name";
    }else{
        self.fullName = [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]];
        self.usrFullNameField.text = self.fullName;
    }
    
    self.usrNameField.text = [AppHelper userName];
    //self.usrEmailField.text = [AppHelper userEmail];
    DLog(@"Name class - %@",[[AppHelper firstName] class]);
}


#pragma mark - Segues
-(void)unWindToProfileSettings:(UIStoryboardSegue *)segue
{
    
}



@end
