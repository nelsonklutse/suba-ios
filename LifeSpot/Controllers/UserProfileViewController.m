//
//  UserProfileViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "UserProfileViewController.h"
#import "User.h"
#import "UserProfileCell.h"
#import "PhotoStreamViewController.h"
#import "UserSettingsViewController.h"
#import "StreamSettingsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NearbyStreamsHeaderView.h"
#import "CreateSpotViewController.h"
#import "TermsViewController.h"

#define UserSpotsKey @"UserSpotsKey"
#define UserProfileInfoKey @"UserProfileInfoKey"
#define UserIdKey @"UserIdKey"

@interface UserProfileViewController()<UICollectionViewDataSource,UICollectionViewDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *normalUserStreamCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *createAccountCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *noStreamCollectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *plusIconButton;

@property (strong,nonatomic) NSMutableArray *userSpots;
@property (strong,nonatomic) NSDictionary *userProfileInfo;
@property (copy,nonatomic) NSString *firstName;
@property (copy,nonatomic) NSString *lastName;
@property (copy,nonatomic) NSString *userName;
@property (copy,nonatomic) NSString *userEmail;
@property (copy,nonatomic) NSString *userPassword;
@property (copy,nonatomic) NSString *userPasswordConfirm;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *facebookLoginIndicator;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *createAccountView;
@property (weak, nonatomic) IBOutlet UIView *createAccountOptionsView;
@property (weak, nonatomic) IBOutlet UIScrollView *signUpWithEmailView;
@property (weak, nonatomic) IBOutlet UIScrollView *finalSignUpWithEmailView;

@property (weak, nonatomic) IBOutlet UIView *loadingUserStreamsIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingUserStreamsIndicator;

@property (weak, nonatomic) IBOutlet UITextField *firstNameField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *reTypePasswordField;
@property (weak, nonatomic) IBOutlet UITextField *userNameOrEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordTextField;
@property (strong,nonatomic) NSString *userProfileId;
@property (weak, nonatomic) IBOutlet UIScrollView *logInView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *fbLoginIndicator;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signUpSpinner;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginSpinner;
- (void)fetchUserStreams:(NSString *)userId;
- (void)fetchUserInfo:(NSString *)userId;
- (void)photoTappedAtIndex:(NSNotification *)aNotification;
- (void)updateUserProfile;
- (void)refreshStream;
- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates;
-(IBAction)unwindToUserProfile:(UIStoryboardSegue *)segue;

- (IBAction)showSettingsView:(id)sender;
- (void)showNoStreamsCollectionView;
- (void)showNormalCollectionView;
- (void)showCreateAccountCollectionView;
- (IBAction)createAccountAction:(id)sender;
- (IBAction)manualSignUpDetailsDoneAction:(id)sender;

- (IBAction)createStreamAction:(id)sender;

- (IBAction)facebookLoginAction:(id)sender;
- (IBAction)signUpAction:(id)sender;
- (IBAction)showTermsOfService:(id)sender;

- (IBAction)showPrivacyPolicy:(id)sender;

- (IBAction)dismissCreateAccountView:(id)sender;
- (IBAction)dismissSignUpWithEmailView:(id)sender;
- (IBAction)showFinalSignUpWithEmailView:(id)sender;
- (IBAction)dismissFinalSignUpView:(id)sender;

- (IBAction)joinNearbyStream:(id)sender;
- (IBAction)showLogInView:(id)sender;
- (IBAction)dismissLogInView:(id)sender;
- (IBAction)performLoginAction:(id)sender;

- (void)openFBSession;
- (void)dismissCreateAccountPopUp;
@end

@implementation UserProfileViewController
int counter;

-(IBAction)unwindToUserProfile:(UIStoryboardSegue *)segue
{
    StreamSettingsViewController *aVC = segue.sourceViewController;
    NSString *albumName = aVC.spotName;
    NSString *spotId = aVC.spotID;
    
    int counter = 0;
    for (NSDictionary *spotToRemove in self.userSpots){
        
        if ([spotToRemove[@"spotId"] integerValue] == [spotId integerValue]){
            
            [self.userSpots removeObject:spotToRemove];
            
            [self updateCollectionView:self.normalUserStreamCollectionView
                            withUpdate:@[[NSIndexPath indexPathForItem:counter inSection:1]]];
            
            break;
            
        }
        counter += 1;
    }
    
    UIColor *tintColor = [UIColor colorWithRed:(217.0f/255.0f)
                                         green:(77.0f/255.0f)
                                          blue:(20.0f/255.0f)
                                         alpha:1];
    
    [CSNotificationView showInViewController:self.navigationController
                                   tintColor: tintColor
                                       image:nil
                                     message:[NSString stringWithFormat:
                                              @"%@ removed from your list of streams",albumName]
                                    duration:2.0f];
    
}

- (IBAction)showSettingsView:(id)sender
{
    [self performSegueWithIdentifier:@"UserProfileToMainSettingsSegue" sender:nil];
}

- (void)showNoStreamsCollectionView
{
    DLog();
    self.noStreamCollectionView.alpha = 1;
    self.normalUserStreamCollectionView.alpha = 0;
    self.createAccountCollectionView.alpha = 0;
    
    [self.noStreamCollectionView reloadData];
}

- (void)showNormalCollectionView
{
    //DLog();
    self.normalUserStreamCollectionView.alpha = 1;
    self.noStreamCollectionView.alpha = 0;
    self.createAccountCollectionView.alpha = 0;
    
    [self.normalUserStreamCollectionView reloadData];
}

- (void)showCreateAccountCollectionView
{
    DLog();
    self.createAccountCollectionView.alpha = 1;
    self.noStreamCollectionView.alpha = 0;
    self.normalUserStreamCollectionView.alpha = 0;
    
    [self.createAccountCollectionView reloadData];
}

- (IBAction)createStreamAction:(id)sender
{
    CreateSpotViewController *createStreamVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CREATESTREAM_VC"];
    
    [self presentViewController:createStreamVC animated:YES completion:nil];
}


- (IBAction)showTermsOfService:(id)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/terms.html"];
    [self.navigationController pushViewController:termsVC animated:YES];

}


- (IBAction)showPrivacyPolicy:(id)sender
{
    TermsViewController *termsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TERMS_SCENE"];
    termsVC.urlToLoad = [NSURL URLWithString:@"http://www.subaapp.com/privacy.html"];
    [self.navigationController pushViewController:termsVC animated:YES];
 
}

- (IBAction)createAccountAction:(id)sender
{
    DLog(@"Create Account Options View");
    // Show create Account Options View
    [UIView animateWithDuration:0.5 animations:^{
        self.createAccountView.alpha = 1;
        self.logInView.alpha = 0;
    }];
}


- (void)dismissCreateAccountPopUp
{
    [UIView animateWithDuration:0.5 animations:^{
        self.createAccountView.alpha = 0;
        self.logInView.alpha = 0;
    }];
}

- (IBAction)dismissCreateAccountView:(id)sender
{
    [self dismissCreateAccountPopUp];
}


- (IBAction)manualSignUpDetailsDoneAction:(id)sender
{
    if (![self.reTypePasswordField.text isEqualToString:self.passwordField.text]){
        
        [AppHelper showAlert:@"Password Error" message:@"Your passwords do not match"
                     buttons:@[@"Try again"] delegate:nil];
        
   }else{
       
       [self.signUpSpinner startAnimating];
       
        //Save these in a model
        self.firstName = self.firstNameField.text;
        self.lastName = self.lastNameField.text;
        self.userEmail = self.emailField.text;
        self.userName = self.usernameField.text;
        self.userPasswordConfirm = self.passwordField.text;
        
        [self checkAllTextFields];
    }
}


- (IBAction)facebookLoginAction:(id)sender
{
    [self.fbLoginIndicator startAnimating];
    [self.facebookLoginIndicator startAnimating];
    [AppHelper openFBSession:^(id results, NSError *error) {
        [self.fbLoginIndicator stopAnimating];
        [self.facebookLoginIndicator stopAnimating];
        [Flurry logEvent:@"Account_Confirmed_Facebook"];
        self.userProfileInfo = [AppHelper userPreferences];
        DLog(@"User Profile Info - %@",[self.userProfileInfo description]);
        [self performSelector:@selector(dismissCreateAccountPopUp)];
        
        // Update user info
        [self fetchUserStreams:[AppHelper userID]];
    }];
}

- (IBAction)signUpAction:(id)sender
{
    // Transition from create Account View to Sign up details view with left animation
    [UIView transitionWithView:self.createAccountOptionsView duration:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        CGRect newFrame = CGRectMake(0, 0, 320, 440);
        CGRect newFrameForCreateAccountOptionsView = CGRectMake(-320, 0, 320, 440);
        self.createAccountOptionsView.frame = newFrameForCreateAccountOptionsView;
        self.signUpWithEmailView.frame = newFrame;
    } completion:^(BOOL finished) {
        
        int64_t delayInSeconds = .5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            [self.firstNameField becomeFirstResponder];
        });
    }];
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
            
        }completion:^(BOOL finished) {
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
            self.signUpWithEmailView.frame = newFrame;
        
        } completion:nil];
    });
}

- (IBAction)joinNearbyStream:(id)sender
{
    [self.tabBarController setSelectedIndex:0];
}

- (IBAction)showLogInView:(id)sender
{
    // Show a login View
    [UIView animateWithDuration:0.5 animations:^{
        self.createAccountView.alpha = 1;
        self.logInView.alpha = 1;
        self.createAccountOptionsView.alpha = 0;
        self.signUpWithEmailView.alpha = 0;
        self.finalSignUpWithEmailView.alpha = 0;
    }];
}

- (IBAction)dismissLogInView:(id)sender
{
    [UIView animateWithDuration:0.5 animations:^{
        self.createAccountView.alpha = 0;
        self.logInView.alpha = 0;
        self.createAccountOptionsView.alpha = 1;
        self.signUpWithEmailView.alpha = 1;
        self.finalSignUpWithEmailView.alpha = 1;
    }];
}

- (IBAction)performLoginAction:(id)sender
{
    [self.loginPasswordTextField resignFirstResponder];
    [self.userNameOrEmailTextField resignFirstResponder];
    
    self.userEmail = self.userNameOrEmailTextField.text;
    self.userPassword = self.loginPasswordTextField.text;
    
    [self.loginSpinner startAnimating];
    
    [AppHelper loginUserWithEmailOrUserName:self.userEmail
                                Password:self.userPassword
                                AndGuestId:[AppHelper userID]
                            completionBlock:^(id results, NSError *error) {
                                
                                [self.loginSpinner stopAnimating];
                                
                                if (!error) {
                                    if ([results[STATUS] isEqualToString:ALRIGHT]) {
                                        [[NSNotificationCenter defaultCenter] postNotificationName:kUserReloadStreamNotification object:nil];
                                        [AppHelper savePreferences:results];
                                        self.userProfileInfo = nil;
                                        self.userProfileInfo = [AppHelper userPreferences];
                                        [AppHelper setUserStatus:kSUBA_USER_STATUS_CONFIRMED];
                                        //DLog(@"user preferences - %@",self.userProfileInfo);
                                        [self performSelector:@selector(dismissCreateAccountPopUp)];
                                        // Update user info
                                        [self fetchUserStreams:[AppHelper userID]];
                                    }else{
                                        [AppHelper showAlert:results[STATUS] message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
                                    }
                                    
                                    
                                }else{
                                    DLog(@"Error localizedDescription - %@\nError Description - %@\nError localizedFailureReason - %@",error.localizedDescription,error.description,error.localizedFailureReason);
                                    
                                    [AppHelper showAlert:@"Login Failure" message:error.localizedDescription buttons:@[@"OK"] delegate:nil];
                                }
            }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.createAccountView.alpha = 0;
    //self.createAccountOptionsView.alpha = 0;
    //self.signUpWithEmailView.alpha = 0;
    
    //UIImage *settingsIcon = [IonIcons imageWithIcon:icon_gear_b size:32 color:[UIColor whiteColor]];
    //self.settingsButton.image = settingsIcon;
    
    UIImageView *navImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    navImageView.contentMode = UIViewContentModeScaleAspectFit;
    navImageView.image = [UIImage imageNamed:@"logo"];
    self.navigationItem.titleView = navImageView;
    
    //NSString *userId = ( self.userId ) ? self.userId : [User currentlyActiveUser].userID;
    
    //If user id is -1 and user has not yet entered a stream, show no stream view
    
    //[self figureOutWhichCollectionViewToShow];
    
    //DLog(@"UserId - %@",userId);
    
    [self figureOutWhichCollectionViewToShow];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStream) name:kUserReloadStreamNotification object:nil];

}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoTappedAtIndex:) name:kPhotoGalleryTappedAtIndexNotification object:nil];
    
    /*[self.normalUserStreamCollectionView addPullToRefreshActionHandler:^{
        [self updateUserProfile];
    }];
    
    [self.createAccountCollectionView addPullToRefreshActionHandler:^{
        [self updateUserProfile];
    }];
    
    [self.normalUserStreamCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.normalUserStreamCollectionView.pullToRefreshView setBorderWidth:6];

    [self.normalUserStreamCollectionView.pullToRefreshView setBorderColor:[UIColor redColor]];
    
   
    [self.createAccountCollectionView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.createAccountCollectionView.pullToRefreshView setBorderWidth:6];
    
    [self.createAccountCollectionView.pullToRefreshView setBorderColor:[UIColor redColor]];*/
    
    
    [self figureOutWhichCollectionViewToShow];
    
    
       /* [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photoTappedAtIndex:) name:kPhotoGalleryTappedAtIndexNotification object:nil];*/
}


- (void)showMainSettings
{
    
    [self performSegueWithIdentifier:@"UserProfileToMainSettingsSegue" sender:@(1)];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    DLog();
    if (self.shouldAutoInvite == YES){
        self.shouldAutoInvite = NO;
        [self performSelector:@selector(showMainSettings) withObject:nil afterDelay:0];
        
    }else{
    
    
    
    NSString  *userId = ( self.userId ) ? self.userId : [AppHelper userID];
    DLog(@" Crrent UserId -%@\nApp user - %@",userId,[AppHelper userID]);
    if (![userId isEqualToString:[AppHelper userID]]){
        DLog(@"UserId to load -%@\nApp user - %@",userId,[AppHelper userID]);
        [self fetchUserStreams:userId];
        [self fetchUserInfo:userId];
    }else{
        //DLog(@"fetching streams of user with ID - %@",userId);
        [self fetchUserStreams:[AppHelper userID]];
        [self fetchUserInfo:[AppHelper userID]];
    }
        
     [self figureOutWhichCollectionViewToShow];
    }
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:kPhotoGalleryTappedAtIndexNotification
     object:nil];
}


-(void)refreshStream
{
    if (self != nil) {
      [self fetchUserStreams:[AppHelper userID]];
   }
}


- (void)updateCollectionView:(UICollectionView *)collectionView withUpdate:(NSArray *)updates{
    //DLog(@"user spots - %@",self.allSpots);
    
        [collectionView performBatchUpdates:^{
            [collectionView deleteItemsAtIndexPaths:updates];
        } completion:nil];
}


-(void)photoTappedAtIndex:(NSNotification *)aNotification
{
    NSDictionary *notifInfo = [aNotification valueForKey:@"userInfo"];
    NSMutableDictionary *photoInfo = notifInfo[@"spotInfo"];
    
    [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue" sender:photoInfo];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)fetchUserStreams:(NSString *)userId
{
   [AppHelper showLoadingDataView:self.loadingUserStreamsIndicatorView
                         indicator:self.loadingUserStreamsIndicator
                              flag:YES];
    
    User *user = [User userWithID:userId];
    [user loadPersonalSpotsWithCompletion:^(id results, NSError *error) {
        
        [AppHelper showLoadingDataView:self.loadingUserStreamsIndicatorView
                             indicator:self.loadingUserStreamsIndicator flag:NO];
        
        //DLog(@"Results - %@",results);
        
        if (error) {
            DLog(@"Error - %@",error);
        }else{
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                NSArray *userStreams = results[@"spots"];
                if ([userStreams count] > 0){
                    
                    //DLog(@"Number of streams user is a member of - %lu",(unsigned long)[userStreams count]);
                    
                    //NSArray *createdSpots = userStreams;
                    
                    NSSortDescriptor *timestampDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreated" ascending:NO];
                    NSArray *sortDescriptors = [NSArray arrayWithObject:timestampDescriptor];
                    NSArray *sortedSpots = [userStreams sortedArrayUsingDescriptors:sortDescriptors];
                    if (self.userSpots){
                        //DLog(@"We already have some streams loaded previously");
                        [self.userSpots removeAllObjects];
                    }
                    self.userSpots = [NSMutableArray arrayWithArray:sortedSpots];
                    
                    [self figureOutWhichCollectionViewToShow];
                    
                }

            }
            
        }
    }];
    
}


- (void)figureOutWhichCollectionViewToShow
{
    if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS] &&
        [AppHelper numberOfPhotoStreamEntries] == 0){
        
        [self showNoStreamsCollectionView];
        
    }else if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_CONFIRMED] &&
              [AppHelper numberOfPhotoStreamEntries] >= 0){
        
        [self showNormalCollectionView];
        
    }else if([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS] && [AppHelper numberOfPhotoStreamEntries] > 0){
        [self showCreateAccountCollectionView];
    }
}

-(void)fetchUserInfo:(NSString *)userId
{
    [User fetchUserProfileInfoCompletion:userId completion:^(id results, NSError *error){
        if (error) {
            //Log the error
            DLog(@"Error -  %@",error);
        }else{
            DLog(@"User info - %@",results);
            if ([results[STATUS] isEqualToString:ALRIGHT]) {
                self.userProfileInfo = (NSDictionary *)results;
                
                [self figureOutWhichCollectionViewToShow];

                //[self.normalUserStreamCollectionView reloadData];
            }else{
                // There was a problem on the server
                DLog(@"Issues on the server - %@",results);
            }
        }
    }];
}


-(void)updateUserProfile
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakSelf fetchUserStreams:( self.userId ) ? self.userId : [User currentlyActiveUser].userID];
        [weakSelf fetchUserInfo:( self.userId ) ? self.userId : [User currentlyActiveUser].userID];
        
        if (self.noStreamCollectionView.alpha == 1) {
           [weakSelf.normalUserStreamCollectionView stopRefreshAnimation];
        }else{
            [weakSelf.createAccountCollectionView stopRefreshAnimation];
        }
        
    });
}


#pragma mark - UICollectionViewDatasource
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    DLog(@"how many spots to display - %i",[self.userSpots count]);
    return [self.userSpots count];
}



-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    counter++;
    static NSString *cellIdentifier = @"USER_STREAMS_CELL";
    
    UserProfileCell *userStreamsCell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (userStreamsCell.pGallery.hidden) {
        userStreamsCell.pGallery.hidden = NO;
    }
    NSArray *spotsToDisplay = self.userSpots;
    
    NSString *spotCode = spotsToDisplay[indexPath.item][@"spotCode"];
    if ([spotCode isEqualToString:@"NONE"] || [spotCode class] == [NSNull class]){
        userStreamsCell.privateStreamImageView.hidden = YES;
    }else{
        userStreamsCell.privateStreamImageView.hidden = NO;
    }
    
    // Set up cell separator
    CGColorRef coloref = [UIColor colorWithRed:156/255.0f green:150/255.0f blue:129/255.0f alpha:1.0f].CGColor;
    [userStreamsCell setUpBorderWithColor:coloref AndThickness:.5f];

     
    [[userStreamsCell.photoGalleryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *photos = spotsToDisplay[indexPath.row][@"photos"];
    NSString *imageSrc = spotsToDisplay[indexPath.row][@"creatorPhoto"];
    
    if (imageSrc){
        [userStreamsCell fillView:userStreamsCell.userNameView WithImage:imageSrc];
    }else{
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.userNameView name:personString];
            
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.userNameView name:userName];
        }
        
    }

    
    userStreamsCell.streamNameLabel.text = spotsToDisplay[indexPath.item][@"spotName"];
    userStreamsCell.streamNameLabel.adjustsFontSizeToFitWidth = YES;
    
    userStreamsCell.streamVenueLabel.text = spotsToDisplay[indexPath.item][@"venue"];
    userStreamsCell.streamVenueLabel.adjustsFontSizeToFitWidth = YES;
    
    NSInteger members = [spotsToDisplay[indexPath.item][@"members"] integerValue] - 1;
    
    if (members == 0){
       
        userStreamsCell.firstMemberPhoto.hidden = YES;
        userStreamsCell.secondMemberPhoto.hidden = YES;
        userStreamsCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [AppHelper initialStringForPersonString:lastName].uppercaseString;
           
            userStreamsCell.userNameLabel.text = [NSString stringWithFormat:@"%@ %@.",firstName,lastNameInitial];
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            userStreamsCell.userNameLabel.text = userName;
        }
        
    }else if (members == 1){
        userStreamsCell.firstMemberPhoto.hidden = NO;
        userStreamsCell.secondMemberPhoto.hidden = YES;
        userStreamsCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [AppHelper initialStringForPersonString:lastName].uppercaseString;
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li other",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li other",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }
        
        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            //DLog(@"FirstMemberPhotoURL - %@",firstMemberPhotoURL);
            [userStreamsCell fillView:userStreamsCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
            
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.firstMemberPhoto name:personString];
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0f
                                                     view:userStreamsCell.firstMemberPhoto
                                                     name:personString];*/
        }
        
    }else if (members == 2){
        //personalSpotCell.numberOfMembers.text = [NSString stringWithFormat:@"and %i others",members];
        userStreamsCell.firstMemberPhoto.hidden = NO;
        userStreamsCell.secondMemberPhoto.hidden = NO;
        userStreamsCell.thirdMemberPhoto.hidden = YES;
        userStreamsCell.thirdMemberPhoto.hidden = YES;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [AppHelper initialStringForPersonString:lastName].uppercaseString;
            
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }
        
        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            //DLog(@"FirstMemberPhotoURL - %@",firstMemberPhotoURL);
            [userStreamsCell fillView:userStreamsCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            // Construct Initials
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.firstMemberPhoto name:personString];
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0
                                                     view:userStreamsCell.firstMemberPhoto
                                                     name:personString];*/
        }
        if (spotsToDisplay[indexPath.item][@"secondMemberPhoto"]) {
            // If we have a pic to show
            NSString *secondMemberPhotoURL = spotsToDisplay[indexPath.item][@"secondMemberPhoto"];
            //DLog(@"SecondMemberPhotoURL - %@",secondMemberPhotoURL);
            [userStreamsCell fillView:userStreamsCell.secondMemberPhoto WithImage:secondMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"secondMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"secondMember"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.secondMemberPhoto name:personString];
            
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0
                                                     view:userStreamsCell.secondMemberPhoto
                                                     name:personString];*/
        }
        
    }else if(members >= 3){
        
        userStreamsCell.firstMemberPhoto.hidden = NO;
        userStreamsCell.secondMemberPhoto.hidden = NO;
        userStreamsCell.thirdMemberPhoto.hidden = NO;
        
        if (spotsToDisplay[indexPath.item][@"creatorFirstName"] && spotsToDisplay[indexPath.item][@"creatorLastName"]){
            NSString *firstName = spotsToDisplay[indexPath.item][@"creatorFirstName"];
            NSString *lastName = spotsToDisplay[indexPath.item][@"creatorLastName"];
            NSString *lastNameInitial = [AppHelper initialStringForPersonString:lastName].uppercaseString;
            
            
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ %@. ",firstName,lastNameInitial]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }else{
            NSString *userName = spotsToDisplay[indexPath.row][@"creatorName"];
            NSMutableAttributedString *userNametext = [[NSMutableAttributedString alloc]
                                                       initWithString:[NSString stringWithFormat:@"%@ ",userName]
                                                       attributes:@{NSForegroundColorAttributeName: [UIColor colorWithRed:217/255.0f green:77/255.0f blue:20/255.0f alpha:1.0]}];
            
            NSString *participants = [NSString stringWithFormat:@"and %li others",(long)members];
            NSMutableAttributedString *others = [[NSMutableAttributedString alloc]
                                                 initWithString:participants attributes:@{NSForegroundColorAttributeName: [UIColor grayColor]}];
            
            // Add both texts
            [userNametext appendAttributedString:others];
            userStreamsCell.userNameLabel.attributedText = userNametext;
        }
        
        
        if (spotsToDisplay[indexPath.item][@"firstMemberPhoto"]){
            NSString *firstMemberPhotoURL = spotsToDisplay[indexPath.item][@"firstMemberPhoto"];
            //DLog(@"FirstMemberPhotoURL - %@",firstMemberPhotoURL);
            [userStreamsCell fillView:userStreamsCell.firstMemberPhoto WithImage:firstMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"firstMember"]){
            NSString *personString = spotsToDisplay[indexPath.item][@"firstMember"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.firstMemberPhoto name:personString];
            
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0
                                                     view:userStreamsCell.firstMemberPhoto
                                                     name:personString];*/
            
        }
        if (spotsToDisplay[indexPath.item][@"secondMemberPhoto"]) {
            
            NSString *secondMemberPhotoURL = spotsToDisplay[indexPath.item][@"secondMemberPhoto"];
            //DLog(@"secondMemberPhotoURL - %@",secondMemberPhotoURL);
            [userStreamsCell fillView:userStreamsCell.secondMemberPhoto WithImage:secondMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"secondMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"secondMember"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.secondMemberPhoto name:personString];
            
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0
                                                     view:userStreamsCell.secondMemberPhoto
                                                     name:personString];*/
            
            //[userStreamsCell makeInitialPlaceholderView:userStreamsCell.secondMemberPhoto name:personString];
            
        }if (spotsToDisplay[indexPath.item][@"thirdMemberPhoto"]){
            NSString *thirdMemberPhotoURL = spotsToDisplay[indexPath.item][@"thirdMemberPhoto"];
            [userStreamsCell fillView:userStreamsCell.thirdMemberPhoto WithImage:thirdMemberPhotoURL];
        }else if(spotsToDisplay[indexPath.item][@"thirdMember"]){
            
            NSString *personString = spotsToDisplay[indexPath.item][@"thirdMember"];
            [userStreamsCell makeInitialPlaceholderView:userStreamsCell.thirdMemberPhoto name:personString];
            
            /*[AppHelper makeInitialPlaceholderViewWithSize:15.0
                                                     view:userStreamsCell.thirdMemberPhoto
                                                     name:personString];*/
        }
    }
    
    
    userStreamsCell.numberOfPhotosLabel.text = photos;
    
    if ([photos integerValue] > 0) {  // If there are photos to display
        
        [userStreamsCell prepareForGallery:spotsToDisplay[indexPath.row] index:indexPath];
        
        if ([userStreamsCell.pGallery superview]) {
            [userStreamsCell.pGallery removeFromSuperview];
        }
        userStreamsCell.photoGalleryView.backgroundColor = [UIColor clearColor];
        [userStreamsCell.photoGalleryView addSubview:userStreamsCell.pGallery];
        
        
    }else{
        
        UIImageView *noPhotosImageView = [[UIImageView alloc] initWithFrame:userStreamsCell.photoGalleryView.bounds];
        noPhotosImageView.image = [UIImage imageNamed:@"newaddFirstPhoto"];
        noPhotosImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        if ([noPhotosImageView superview]){
            [noPhotosImageView removeFromSuperview];
        }
        
        [userStreamsCell.photoGalleryView addSubview:noPhotosImageView];
    }
    
    DLog(@"counter - %i",counter);
    return userStreamsCell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
     UICollectionReusableView *reusableview = nil;
     NearbyStreamsHeaderView *headerView = nil;

     if (kind == UICollectionElementKindSectionHeader) {
         headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"ProfileHeaderView" forIndexPath:indexPath];
         
         if ([headerView.userProfileView.subviews count] > 0) {
             [[headerView.userProfileView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
         }
         
         NSURL *profilePhotoURL = nil;
         
         if (self.userProfileInfo){
        
             NSString *userName = self.userProfileInfo[@"userName"];
             if (self.userProfileInfo[@"firstName"] && self.userProfileInfo[@"lastName"]) {
             NSString *userFullName = [NSString stringWithFormat:@"%@ %@",self.userProfileInfo[@"firstName"],self.userProfileInfo[@"lastName"]];
             
             headerView.userFullName.text = userFullName;
             
             [headerView makeInitialPlaceholderViewWithSize:30.0
                                                       view:headerView.userProfileView
                                                       name:userFullName];
         }else if (self.userProfileInfo[@"firstName"]) {
             NSString *userFullName = [NSString stringWithFormat:@"%@",self.userProfileInfo[@"firstName"]];
             headerView.userFullName.text = userFullName;
             [headerView makeInitialPlaceholderViewWithSize:30.0
                                                       view:headerView.userProfileView
                                                       name:userFullName];
         }
         if ([[AppHelper userStatus] isEqualToString:kSUBA_USER_STATUS_ANONYMOUS]) {
             headerView.userUserName.text = @"(Guest Account)";
         }else{
             headerView.userUserName.text = [NSString stringWithFormat:@"@%@",userName];
         }
  
        NSString *numberOfSpots = [self.userProfileInfo[@"numberOfSpots"] stringValue];
             
        if (self.userProfileInfo[@"profilePicURL"]){
            if (![[profilePhotoURL absoluteString] isEqualToString:kSUBA_GUEST_USER_ID]) {
                profilePhotoURL = [NSURL URLWithString:self.userProfileInfo[@"profilePicURL"]];
                DLog(@"Profile Photo URL - %@",[profilePhotoURL absoluteString]);
                [AppHelper fillView:headerView.userProfileView
                               WithImage:[profilePhotoURL absoluteString]];
                     
                 }
             }
             
             headerView.userNumberOfStreamsLabel.text = numberOfSpots;
             headerView.streamsLabel.text = ([numberOfSpots integerValue] == 1) ? @"Stream" : @"Streams";
             headerView.numberOfPhotosLabel.text = [self.userProfileInfo[@"photos"] stringValue];
             headerView.photosLabel.text = ([self.userProfileInfo[@"photos"] integerValue] == 1) ? @"Photo" : @"Photos";
             
        }

         reusableview = headerView;
         
     }
     return reusableview;
 }


#pragma mark - CollectionView Delegate
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
   
    if ([self.userSpots[indexPath.item][@"photos"] integerValue] == 0){
            
            NSString *spotID = self.userSpots[indexPath.item][@"spotId"];
            NSString *spotName = self.userSpots[indexPath.item][@"spotName"];
            NSInteger numberOfPhotos = [self.userSpots[indexPath.item][@"photos"] integerValue];
            NSDictionary *dataPassed = @{@"spotId": spotID,@"spotName":spotName,@"photos" : @(numberOfPhotos)};
            [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue" sender:dataPassed];
    }else{
        
        [self performSegueWithIdentifier:@"FromUserSpotsToPhotosStreamSegue"
                                  sender:self.userSpots[indexPath.item]];
    }

}
    


#pragma mark - Segue Methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FromUserSpotsToPhotosStreamSegue"]){
        DLog(@"Preparing Segue");
        if ([segue.destinationViewController isKindOfClass:[PhotoStreamViewController class]]){
            
            PhotoStreamViewController *photosVC = segue.destinationViewController;
            if (sender[@"photoURLs"]) {
                
                photosVC.photos = [NSMutableArray arrayWithArray:(NSArray *) sender[@"photoURLs"]];
            }
            
            photosVC.spotName = sender[@"spotName"];
            photosVC.spotID = sender[@"spotId"];
            photosVC.numberOfPhotos = [sender[@"photos"] integerValue];
            
            DLog(@"sender - %@",[sender description]);
        }
    }else if ([segue.identifier isEqualToString:@"UserProfileToMainSettingsSegue"]){
        
        if ([sender  isEqual: @(1)]) {
            //DLog(@"Sender class - %@",[sender class]);
            UserSettingsViewController *userSettingsVC = segue.destinationViewController;
            userSettingsVC.autoInvite = YES;
            //DLog();
        }
        
        
    }
}



#pragma mark - Create Account Shenanigans
- (void)openFBSession{
    [self.fbLoginIndicator startAnimating];
    
    
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info",@"email",@"user_birthday"] allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState status, NSError *error){
        
        
        DLog(@"Opening FB Session with token - %@\nSession - %@",session.accessTokenData.expirationDate,[session debugDescription]);
        
        if (error) {
            DLog(@"Facebook Error - %@\nFriendly Error - %@",[error debugDescription],error.localizedDescription);
        }else if (session.isOpen){
            [AppHelper setFacebookSession:@"YES"];
            [self.fbLoginIndicator stopAnimating];
            
            
            NSDictionary *parameters = [NSDictionary dictionaryWithObject:@"first_name,last_name,username,email,picture.type(large)" forKey:@"fields"];
            
            [FBRequestConnection startWithGraphPath:@"me" parameters:parameters HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                DLog(@"FB Auth Result - %@\nError - %@",result,error);
                if (!error) {
                    NSDictionary<FBGraphUser> *user = result;
                    
                    NSString *userEmail = [user valueForKey:@"email"];
                    if (userEmail == NULL) {
                        [AppHelper showAlert:@"Facebook Error"
                                     message:@"There was an issue retrieving your facebook email address."
                                     buttons:@[@"OK"] delegate:nil];
                        
                        /*[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                        self.connectingToFacebookView.alpha = 0;*/
                        
                    }else{
                        NSString *pictureURL = [[[result valueForKey:@"picture"] valueForKey:@"data"] valueForKey:@"url"];
                        
                        [AppHelper setProfilePhotoURL:pictureURL];
                        
                        DLog(@"ID - %@\nfirst_name - %@\nLast_name - %@\nEmail - %@\nUsername - %@\nPicture - %@\n",user.id,user.first_name,user.last_name,[user valueForKey:@"email"],user.username,pictureURL);
                        
                        
                        
                        NSDictionary *fbSignUpDetails = @{
                                                          @"id" :user.id,
                                                          FIRST_NAME: user.first_name,
                                                          LAST_NAME : user.last_name,
                                                          EMAIL :  userEmail,
                                                          USER_NAME : user.username,
                                                          @"pass" : @"",
                                                          PROFILE_PHOTO_URL : pictureURL
                                                          };
                        
                        
                        [AppHelper createUserAccount:fbSignUpDetails WithType:FACEBOOK_LOGIN completion:^(id results, NSError *error) {
                            
                            /*[AppHelper showLoadingDataView:self.connectingToFacebookView indicator:self.connectingToFacebookIndicator flag:NO];
                            self.connectingToFacebookView.alpha = 0;*/
                            
                            if (!error && [results[status] isEqualToString:ALRIGHT]) {
                                DLog(@"Response - %@",result);
                                
                            }else{
                                DLog(@"Error - %@",error);
                                [AppHelper showAlert:@"Authentication Error"
                                             message:@"There was a problem authentication you on our servers. Please wait a minute and try again"
                                             buttons:@[@"OK"]
                                            delegate:nil];
                                
                            }
                        }];
                    }
                }
            }];
        }
        
    }];
    
}







#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.userSpots forKey:UserSpotsKey];
    [coder encodeObject:self.userProfileInfo forKey:UserProfileInfoKey];
    [coder encodeObject:self.userId forKey:UserIdKey];
    
    //DLog();
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.userSpots = [coder decodeObjectForKey:UserSpotsKey];
    self.userProfileInfo = [coder decodeObjectForKey:UserProfileInfoKey];
    self.userId = [coder decodeObjectForKey:UserIdKey];
    
    //DLog();
}

-(void)applicationFinishedRestoringState
{
    
    if (self.userSpots && self.userProfileInfo) {
        [self.normalUserStreamCollectionView reloadData];
    }else{
        if (self.userId) {
            [self fetchUserStreams:self.userId];
        }
    }
    
    //DLog(@"UserId decoded - %@",self.userId);
}


-(void)checkAllTextFields
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
                    
                 
                    [self.firstNameField resignFirstResponder];
                    [self.lastNameField resignFirstResponder];
                    [self.usernameField resignFirstResponder];
                    [self.emailField resignFirstResponder];
                    [self.passwordField resignFirstResponder];
                    [self.reTypePasswordField resignFirstResponder];
                    
                    [AppHelper createUserAccount:params WithType:NATIVE completion:^(id results, NSError *error) {
                        if (!error) {
                            [self.signUpSpinner stopAnimating];
                            
                            [AppHelper savePreferences:results];
                            self.userProfileInfo = nil;
                            self.userProfileInfo = [AppHelper userPreferences];
                            
                            DLog(@"user preferences - %@",self.userProfileInfo);
                            [Flurry logEvent:@"Account_Confirmed_Manual"];
                            [self performSelector:@selector(dismissCreateAccountPopUp)];
                            
                            // Update user info
                            [self fetchUserStreams:[AppHelper userID]];
                        }else{
                            [AppHelper showAlert:results[STATUS] message:results[@"message"] buttons:@[@"I'll check again"] delegate:nil];
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




#pragma mark - Textfield delegate method
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // Move the textfield up to give space for user to continue
    if (textField == self.firstNameField || textField == self.lastNameField || textField == self.usernameField)
    {
        [self.signUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
        
    }else if (textField == self.emailField || textField == self.passwordField || textField == self.reTypePasswordField)
    {
        [self.finalSignUpWithEmailView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
    }else if(textField == self.userNameOrEmailTextField || textField == self.loginPasswordTextField)
    {
        [self.logInView setContentOffset:CGPointMake(0.0f, 100.0f) animated:YES];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.userNameOrEmailTextField) {
        [self.userNameOrEmailTextField resignFirstResponder];
        
    }else if (textField == self.loginPasswordTextField){ // if we are in the password field
        
        if (![self.loginPasswordTextField.text isEqualToString:@""] && ![self.userNameOrEmailTextField.text isEqualToString:@""]){
            self.userEmail = self.userNameOrEmailTextField.text;
            self.userPassword = self.loginPasswordTextField.text;
            
            [self performSelector:@selector(performLoginAction:)];
        }else{
            [self.loginPasswordTextField resignFirstResponder];
        }
    }else{
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
                                self.userProfileInfo = nil;
                                self.userProfileInfo = [AppHelper userPreferences];
                                
                                DLog(@"user preferences - %@",self.userProfileInfo);
                                [self performSelector:@selector(dismissCreateAccountPopUp)];
                                // Update user info
                                [self fetchUserStreams:[AppHelper userID]];
                            }else{
                                [AppHelper showAlert:results[STATUS] message:results[@"message"]
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

        
    }
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if (textField == self.loginPasswordTextField) {
        if (![self.userNameOrEmailTextField.text isEqualToString:@""] && ![self.loginPasswordTextField.text isEqualToString:@""]) {
            self.loginBtn.enabled = YES;
        }else{
           self.loginBtn.enabled = NO;
        }
    }
    return YES;
}




@end
