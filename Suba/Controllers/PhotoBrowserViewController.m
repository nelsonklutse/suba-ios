//
//  PhotoBrowserViewController.m
//  Suba
//
//  Created by Kwame Nelson on 2/12/15.
//  Copyright (c) 2015 Intruptiv. All rights reserved.
//

#import "PhotoBrowserViewController.h"
#import "UserProfileViewController.h"
#import "TagCell.h"
#import "Spot.h"
#import "User.h"
#import "AMPopTip.h"

@interface PhotoBrowserViewController ()<UIScrollViewDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIAlertViewDelegate>
{
    
    NSInteger selectedRow;
    CGRect frameOfTagViewBeforeKeyboardShows;
    NSMutableArray *friendsOnSuba;
    NSMutableArray *taggableContacts;
    NSArray *taggableSubaUsers;
    NSMutableSet *filteredTaggableUsers;
    CGRect tapFrame;
    NSMutableArray *popUpTips;
    NSMutableArray *mutableTagOperations;
    AMPopTip *selectedPopOverForDelete;
    UIButton *removeTagButton;
    AMPopTip *longPressTip;
}

@property (weak, nonatomic) IBOutlet UIButton *firstTagWithEmailView;

@property (weak, nonatomic) IBOutlet UIButton *otherTagWithEmailButton;
@property (weak, nonatomic) IBOutlet UILabel *tagInContactsText;

@property (weak, nonatomic) IBOutlet UILabel *tagWithEmailText;

@property (weak, nonatomic) IBOutlet UIView *findInContactsButtonView;

@property (weak, nonatomic) IBOutlet UIView *tagWithEmailButtonView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchingForUsersActivityIndicator;

@property (weak, nonatomic) IBOutlet UITextField *friendNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *friendEmailTextField;
@property (weak, nonatomic) IBOutlet UITextField *searchFriendNameTextField;

@property (weak, nonatomic) IBOutlet UIView *tagWithEmailView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *contactsActivityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tagTableView;
@property (weak, nonatomic) IBOutlet UIView *tagView;
@property (weak, nonatomic) IBOutlet UIButton *tagFriendsInContactsButton;
@property (weak, nonatomic) IBOutlet UIButton *tagWithEmailButton;
@property (weak, nonatomic) IBOutlet UIImageView *tagImage;

@property (strong,nonatomic) NSMutableArray *taggableFriends;
@property (strong,nonatomic) NSArray *phoneContacts;

- (IBAction)removeTag:(UIButton *)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *tagDoneButton;

- (IBAction)dismissTagWithEmailView:(UIButton *)sender;
- (IBAction)findFriendsInContacts:(UIButton *)sender;
- (IBAction)tagWithEmailAction:(UIButton *)sender;

- (IBAction)showTagWithEmailAction:(UIButton *)sender;

- (IBAction)tagDone:(id)sender;
- (IBAction)handleTapToShowTagView:(UITapGestureRecognizer *)tap;

- (void)getTagsForPhoto;
- (void)keyboardShouldShow:(NSNotification *)notification;
- (void)keyboardShouldHide:(NSNotification *)notification;

@end

@implementation PhotoBrowserViewController

int toggler = 0;
static BOOL isFiltered = NO;


-(void)showLongPressPopTip:(CGRect)fromFrame
{
    [[AMPopTip appearance] setPopoverColor:[UIColor whiteColor]];
    [[AMPopTip appearance] setRadius:0];
    // Create the pop tip
    longPressTip = [AMPopTip popTip];
    longPressTip.shouldDismissOnTap = YES;
    longPressTip.shouldDismissOnTapOutside = NO;
    longPressTip.fromFrame = fromFrame;
    longPressTip.tag = 5400;
    [longPressTip setTextColor:[UIColor blackColor]];
    [longPressTip showText:@"Long press to delete tag" direction:AMPopTipDirectionUp maxWidth:200.0f inView:self.view fromFrame:fromFrame duration:10.0];
    
    DLog(@"Long press pop tip");
}


/*- (void)showLongPressHint:(CGRect)frame
{
    [self.hintFingersImg setFrame:CGRectMake(frame.origin.x/2, frame.origin.y+10, 80, 80)];
    self.longPressHintView.alpha = 1;
    self.hintFingersImg.alpha = 1;
    self.longPressBackground.alpha = 1;
    
    self.longPressHintView.hidden = NO;
    self.hintFingersImg.hidden = NO;
    self.longPressBackground.hidden = NO;
    
    [self.view bringSubviewToFront:self.longPressHintView];
    
    [self.longPressHintView setFrame:CGRectMake(0, 0, self.longPressHintView.frame.size.width, self.longPressHintView.frame.size.height)];
    
    DLog(@"Hint fingers: %@\nLong press hint view: %@\nBackground: %@",NSStringFromCGRect(self.hintFingersImg.frame),NSStringFromCGRect(self.longPressHintView.frame),NSStringFromCGRect(self.longPressBackground.frame));
}


- (void)hideLongPressHint:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        // Set up hint view
        self.longPressHintView.alpha = 0;
        self.hintFingersImg.alpha = 0;
        self.longPressBackground.alpha = 0;
        
        self.longPressHintView.hidden = YES;
        self.hintFingersImg.hidden = YES;
        self.longPressBackground.hidden = YES;
        
        DLog(@"Hiding hint master");
    }
    
}


- (void)setUpLongPressHintView {
    
    // Set up hint view
    self.longPressHintView.alpha = 0;
    self.hintFingersImg.alpha = 0;
    self.longPressBackground.alpha = 0;
    
    self.longPressHintView.hidden = YES;
    self.hintFingersImg.hidden = YES;
    self.longPressBackground.hidden = YES;
    
    UITapGestureRecognizer *tapToHideHint = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideLongPressHint:)];
    
    tapToHideHint.numberOfTapsRequired = 1;
    tapToHideHint.cancelsTouchesInView = NO;
    
    [self.longPressHintView addGestureRecognizer:tapToHideHint];
}*/


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.tagDoneButton.enabled = NO;
    
    //[self setUpLongPressHintView];
    
    popUpTips = [NSMutableArray arrayWithCapacity:1];
    self.localPopUpTips = [NSMutableArray arrayWithCapacity:1];
    
    mutableTagOperations = [NSMutableArray array];
    
    selectedRow = 10000;
    //self.backgroundBlurView.alpha = 0;
    
    self.tagWithEmailButton.enabled = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShouldShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShouldHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    /*if (self.tagsInPhoto) {
        
        [self showAllTagsInPhoto:self.tagsInPhoto];
     }*/
    
    [self getTagsForPhoto];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    selectedRow = 10000;
    self.tagView.alpha = 0;
    
    if (self.streamId){
        [self loadAlbumMembers:self.streamId];
    }
    
    self.tagWithEmailView.frame = CGRectMake(self.tagView.frame.origin.x,0,
                                             self.tagView.frame.size.width,0);
    
    self.tagWithEmailView.alpha = 0;
    
    [self.tagImage setImageWithURL:[NSURL URLWithString:self.imageURL]];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    toggler = 0;
}


- (void)didReceiveMemoryWarning{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)dismissViewController:(id)sender{
    
    [self dismissViewControllerAnimated:NO completion:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    self.navigationController.navigationBar.translucent = NO;
    if ([segue.identifier isEqualToString:@"TAGGED_USER_PROFILE_SEGUE"]) {
        UserProfileViewController *uVC = segue.destinationViewController;
        uVC.userId = sender;
        
    }
}



- (IBAction)findFriendsInContacts:(UIButton *)sender
{
    isFiltered = NO;
    
    if ([sender.titleLabel.text isEqualToString:@"Find in Contacts"]) {
        [self showEmailContacts];
    }else if([sender.titleLabel.text isEqualToString:@"Find on Suba"]){
        
        [self.tagFriendsInContactsButton setTitle:@"Find in Contacts" forState:UIControlStateNormal];
        self.taggableFriends = friendsOnSuba;
        
        DLog(@"Friends on Suba - %@",friendsOnSuba);
        
        [self.tagTableView reloadData];
        
    }else if([sender.titleLabel.text isEqualToString:@"TAG WITH EMAIL"]){
        // Tag with email
        [self showTagWithEmailView];
    }
}


- (void)showTagWithEmailView
{
    // Hide the tag view and show 'tag with email" view
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect tagFrame = self.tagView.frame;
        
        //[self shrinkTagViewHeight];
        
        //self.tagView.alpha = 0;
        self.tagWithEmailView.frame = CGRectMake(0,0,self.tagView.frame.size.width,0);
        
        self.tagWithEmailView.frame = CGRectMake(0, 0,
                                                 tagFrame.size.width, tagFrame.size.height);
        
        self.tagWithEmailView.alpha = 1;
    } completion:^(BOOL finished) {
        [self.friendNameTextField becomeFirstResponder];
    }];
}


// Tag with email
- (IBAction)tagWithEmailAction:(UIButton *)sender
{
    // Show the pop tip view
    [self showPopTipViewForTagWithSubaColor:NO AndName:self.friendNameTextField.text];
    
    NSDictionary *params = @{@"taggerId" : [AppHelper userID],
                             @"taggerName" : [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]],
                             @"personTaggedName" : self.friendNameTextField.text,
                             @"personTaggedId" :  @"-1",
                             @"personTaggedEmail" : self.friendEmailTextField.text,
                             @"photoId" : self.imageId,
                             @"photoURL" : self.imageURL,
                             @"xPosition" : @((int)tapFrame.origin.x),
                             @"yPosition" : @((int)tapFrame.origin.y)
                             };
    
    [self addTagOperation:params];
}


-(IBAction)showTagWithEmailAction:(UIButton *)sender
{
    if ([sender.titleLabel.text isEqualToString:@"Find in Contacts"]) {
        [self showEmailContacts];
    }else{
       [self showTagWithEmailView];
    }
   
}


- (IBAction)tagDone:(id)sender
{
    NSArray *operations = [AFURLConnectionOperation batchOfRequestOperations:mutableTagOperations progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations){
        
        DLog(@"%lu of %lu complete", (unsigned long)numberOfFinishedOperations, (unsigned long)totalNumberOfOperations);
        
    } completionBlock:^(NSArray *operations) {
        DLog(@"All operations in batch complete");
        [FBAppEvents logEvent:@"Photo_Tagged" parameters:@{@"stream" : self.streamId}];
    }];
    
    [[NSOperationQueue mainQueue] addOperations:operations waitUntilFinished:NO];

    //[self dismissViewControllerAnimated:YES completion:nil];
    
    // perform unwind segue
    [self performSegueWithIdentifier:@"PhotoTagDoneSegue" sender:nil];
}




-(void)dismissTagWithEmailView:(UIButton *)sender
{
    [self.friendNameTextField resignFirstResponder];
    [self.friendEmailTextField resignFirstResponder];
    [self.searchFriendNameTextField resignFirstResponder];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        //self.tagView.alpha = 0;
        self.tagWithEmailView.alpha = 0;
        //[self shrinkTagViewHeight];
    } completion:^(BOOL finished) {
        //[self resetTagViewFrame];
        //toggler += 1;
    }];
}


- (IBAction)handleTapToShowTagView:(UITapGestureRecognizer *)tap
{
    
    if (toggler % 2 == 0) {
        self.navigationController.navigationBarHidden = YES;
        CGPoint tagLocation = [tap locationInView:self.tagImage];
        
        tapFrame = CGRectMake(tagLocation.x, tagLocation.y, 0 , 0);
        
        self.tagView.frame = [self updateTagViewFrame:tagLocation];
        
        frameOfTagViewBeforeKeyboardShows = self.tagView.frame;
        
        DLog(@"SELF.TAGVIEW.FRAME: %@\nframeOfTagViewBeforeKeyboardShows: %@",
             NSStringFromCGRect(self.tagView.frame), NSStringFromCGRect(frameOfTagViewBeforeKeyboardShows));
        self.tagWithEmailView.alpha = 0;
        self.tagView.alpha = 1;
        
       /*[UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            //[self shrinkTagViewHeight];
           
            //[self inflateTagViewHeight];
           
        } completion:^(BOOL finished) {
            
            //[self.navigationController setNavigationBarHidden:YES animated:NO];
        }];*/
        
        
    }else{
        
        /*[UIView animateWithDuration:0.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{*/
            self.tagView.alpha = 0;
            self.tagWithEmailView.alpha = 0;
            //[self shrinkTagViewHeight];
        //} completion:^(BOOL finished) {
            //[self resetTagViewFrame];
        
            [self.friendNameTextField resignFirstResponder];
            [self.friendEmailTextField resignFirstResponder];
            [self.searchFriendNameTextField resignFirstResponder];
        
            isFiltered = NO;
            [self.tagTableView reloadData];
        
        //}];
        
        self.navigationController.navigationBarHidden = NO;
    }
    
    toggler += 1;
    
    [self.view bringSubviewToFront:self.tagView];
    //[self.view layoutIfNeeded];
}



#pragma mark - UITableView Datasource Methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSMutableArray *datasource = nil;
    
    if (isFiltered) {
        datasource = [NSMutableArray arrayWithArray:[filteredTaggableUsers allObjects]];
    }else{
        datasource = self.taggableFriends;
    }
    
    NSInteger rows = [datasource count];
    
    if (isFiltered){
        if (rows <= 0) {
            self.tagTableView.alpha = 0;
            self.firstTagWithEmailView.alpha = 0;
            if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
                // If the user could not find a friend on Suba
                [self.otherTagWithEmailButton setTitle:@"Find in Contacts" forState:UIControlStateNormal];
                [self.tagFriendsInContactsButton setTitle:@"TAG WITH EMAIL" forState:UIControlStateNormal];
                [self.tagWithEmailText setText:@"Looks like your friend is not on Suba."];
                
            }else if([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find on Suba"]){
                // If the user did not find a friend in contacts
                [self.tagWithEmailText setText:@"Looks like your friend is not in your contacts."];
                [self.otherTagWithEmailButton setTitle:@"TAG WITH EMAIL" forState:UIControlStateNormal];
                [self.tagFriendsInContactsButton setTitle:@"Find on Suba" forState:UIControlStateNormal];
                
            }
            
            self.tagWithEmailButtonView.alpha = 1;
            
            
        }else if(rows > 0){
            //DLog(@"Number of rows to change TAG WITH EMAIL: %i",rows);
            if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"TAG WITH EMAIL"]) {
                [self.tagFriendsInContactsButton setTitle:@"Find in Contacts" forState:UIControlStateNormal];
            }
            self.tagTableView.alpha = 1;
            self.tagWithEmailButtonView.alpha = 0;
            self.firstTagWithEmailView.alpha = 1;
        }
        
    }else{
        self.tagTableView.alpha = 1;
        self.tagWithEmailButtonView.alpha = 0;
        self.firstTagWithEmailView.alpha = 1;
        //DLog(@"Number of rows to change TAG WITH EMAIL: %i",rows);
        if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"TAG WITH EMAIL"]) {
            [self.tagFriendsInContactsButton setTitle:@"Find in Contacts" forState:UIControlStateNormal];
        }
    }
    
    //DLog(@"Number of rows: %i",rows);
    
    return rows;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TagCell";
    
    TagCell *tagCell = [self.tagTableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    NSString *imageURL = nil;
    
    NSMutableArray *datasource = nil;
    
    if (isFiltered) {
        datasource = [NSMutableArray arrayWithArray:[filteredTaggableUsers allObjects]];
    }else{
        datasource = self.taggableFriends;
    }
    
    if (datasource[indexPath.row][@"photoURL"] != nil){
        
        if ([datasource[indexPath.row][@"source"] isEqualToString:@"device"]) {
            
            if ([datasource[indexPath.row][@"imageExists"] isEqualToString:@"YES"]) {
                
                UIImage *userImage = (UIImage *)datasource[indexPath.row][@"photoURL"];
                [tagCell fillView:tagCell.friendImageView WithImage:userImage];
                
            }else{
                
                if (((NSString *)datasource[indexPath.item][@"firstName"]).length > 0 &&
                    ((NSString *)datasource[indexPath.item][@"lastName"]).length > 0){
                    
                    NSString *firstName = datasource[indexPath.item][@"firstName"];
                    NSString *lastName = datasource[indexPath.item][@"lastName"];
                    NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                    
                    tagCell.friendName.text = personString;
                    
                    if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
                        tagCell.friendUserName.text = @"";
                    }else{
                        DLog(@"We'll now search for users");
                        NSString *userName = datasource[indexPath.row][@"userName"];
                        tagCell.friendUserName.text = userName;
                    }
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:personString];
                    
                }else if(((NSString *)datasource[indexPath.item][@"firstName"]).length > 0 &&
                         ((NSString *)datasource[indexPath.item][@"lastName"]).length == 0){
                    
                    NSString *firstName = datasource[indexPath.item][@"firstName"];
                    tagCell.friendName.text = firstName;
                    
                    if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
                        tagCell.friendUserName.text = @"";
                    }else{
                        DLog(@"We'll now search for users");
                        NSString *userName = datasource[indexPath.row][@"userName"];
                        tagCell.friendUserName.text = userName;
                    }
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:firstName];
                    
                }else if(((NSString *)datasource[indexPath.item][@"firstName"]).length == 0 &&
                         ((NSString *)datasource[indexPath.item][@"lastName"]).length > 0){
                    
                    NSString *lastName = datasource[indexPath.item][@"firstName"];
                    tagCell.friendName.text = lastName;
                    
                    if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
                        tagCell.friendUserName.text = @"";
                    }else{
                        DLog(@"We'll now search for users");
                        NSString *userName = datasource[indexPath.row][@"userName"];
                        tagCell.friendUserName.text = userName;
                    }
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:lastName];
                    
                }else{
                    NSString *userName = datasource[indexPath.row][@"userName"];
                    tagCell.friendUserName.text = userName;
                    
                    [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:userName];
                }

            }
            
            
        }else{
            imageURL = datasource[indexPath.row][@"photoURL"];
            
            [tagCell fillView:tagCell.friendImageView WithImageURL:imageURL
                  placeholder:[UIImage imageNamed:@"anonymousUser"]];
            
            //[tagCell.friendImage setImageWithURL:[NSURL URLWithString:imageURL]];
        }
        
    }else{
        
        if (datasource[indexPath.item][@"firstName"] && datasource[indexPath.item][@"lastName"]){
            
            NSString *firstName = datasource[indexPath.item][@"firstName"];
            NSString *lastName = datasource[indexPath.item][@"lastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            
            tagCell.friendName.text = personString;
            
            if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
                tagCell.friendUserName.text = @"";
            }else{
                DLog(@"We'll now search for users");
                NSString *userName = datasource[indexPath.row][@"userName"];
                tagCell.friendUserName.text = userName;
            }
            
            [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:personString];
            
        }else{
            NSString *userName = datasource[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
            
            [tagCell makeInitialPlaceholderView:tagCell.friendImageView name:userName];
        }
    }
    
    
    if (datasource[indexPath.item][@"firstName"] && datasource[indexPath.item][@"lastName"]){
        
            NSString *firstName = datasource[indexPath.item][@"firstName"];
            NSString *lastName = datasource[indexPath.item][@"lastName"];
            NSString *personString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        
            tagCell.friendName.text = personString;
        
        if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]){
            tagCell.friendUserName.text = @"";
        }else{
            DLog(@"We'll now search for users");
            NSString *userName = datasource[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
        }
        
    }else{
            NSString *userName = datasource[indexPath.row][@"userName"];
            tagCell.friendUserName.text = userName;
        }
    
    
        // Remove the checkmark as a result of dequeuing
    //DLog(@"Selected row: %i\nCurrent index path row: %i",selectedRow,indexPath.row);
    if (indexPath.row == selectedRow){
        DLog(@"Setting accessory to None");
        tagCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }else tagCell.accessoryType = UITableViewCellAccessoryNone;
    

    return tagCell;
}


#pragma mark - UITableView Delegate Methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *datasource = nil;
    
    if (isFiltered) {
        datasource = [NSMutableArray arrayWithArray:[filteredTaggableUsers allObjects]];
    }else{
        datasource = self.taggableFriends;
    }

    TagCell *cell = (TagCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    NSUInteger index = indexPath.row;
    selectedRow = index;
    
    BOOL subaUser = ([datasource[selectedRow][@"source"] isEqualToString:@"device"]) ? NO : YES;
    NSString *name = cell.friendName.text;
    
    // Show the pop tip view
    [self showPopTipViewForTagWithSubaColor:subaUser AndName:name];
    
    NSInteger dateTagged = (long)[[NSDate date] timeIntervalSinceReferenceDate];
    NSURL *photoTaggedURL = [NSURL URLWithString:self.imageURL];
    NSArray *imagePathComponents = photoTaggedURL.pathComponents;
    
    NSString *imageSrc = [NSString stringWithFormat:@"%@/%@",self.streamId,[imagePathComponents lastObject]];
    
    DLog(@"Path components: %@\nPath: %@\nImageSRC: %@",[photoTaggedURL.pathComponents debugDescription],photoTaggedURL.path,imageSrc);
    
    NSDictionary *params = @{
                             @"taggerId" : [AppHelper userID],
                             @"taggerName" : [NSString stringWithFormat:@"%@ %@",[AppHelper firstName],[AppHelper lastName]],
                             @"personTaggedName" : cell.friendName.text,
                             @"height" : @(50),
                             @"width" : @(50),
                             @"personTagged" : cell.friendName.text,
                             @"isTaggedUserASubaUser" : (datasource[index][@"id"]) ? @(1) : @"0",
                             @"personTaggedId" : (datasource[index][@"id"]) ? datasource[index][@"id"] : @"-1",
                             @"personTaggedEmail" : datasource[index][@"userEmail"],
                             @"photoId" : self.imageId,
                             @"photoURL" : imageSrc,
                             @"xPosition" : @((int)tapFrame.origin.x),
                             @"yPosition" : @((int)tapFrame.origin.y),
                             @"taggerPhotoURL" : [AppHelper profilePhotoURL],
                             @"dateTagged" : @(dateTagged)
                            };
    
    
    if (!self.localTags) {
        self.localTags = [NSMutableArray array];
    }
    
    [self.localTags addObject:params];
    [self addTagOperation:params];
}



/*-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *datasource = nil;
    
    if (isFiltered) {
        datasource = filteredTaggableUsers;
    }else{
        datasource = self.taggableFriends;
    }
}*/


#pragma mark - View Controller Methods
-(void)loadAlbumMembers:(NSString *)spotId
{
    
    [Spot fetchSpotInfo:spotId completion:^(id results, NSError *error) {
        
        if (!error) {
            self.taggableFriends = [NSMutableArray arrayWithArray:results[@"members"]];
            [self.tagTableView reloadData];
        }
    }];
}

-(CGRect)updateTagViewFrame:(CGPoint)tapLocationInView
{
    CGRect newFrameForTagView;
    CGFloat xPos;CGFloat yPos;
    
    if (tapLocationInView.x >= 100) {
        
         xPos = ( (tapLocationInView.x - self.tagView.frame.origin.x) / 2.0);
        
        if ( (xPos + self.tagView.frame.size.width) > self.view.frame.size.width) {
            xPos = ( (tapLocationInView.x - self.tagView.frame.origin.x) / 4.0);
        }
        
        DLog(@"Tap location is greater than 100. New xpos = %f",xPos);
    }else{
        xPos = tapLocationInView.x / 2.0;
        
        if ( (xPos + self.tagView.frame.size.width) > self.view.frame.size.width) {
            xPos = tapLocationInView.x / 3.0;;
        }
        
        DLog(@"Tap location is less than 100. New xpos = %f",xPos);

    }
    
   
    yPos = tapLocationInView.y;
    if ((yPos + self.tagView.frame.size.height) > self.view.frame.size.height){
        DLog(@"ypos is taller than view: %f\nTag view height: %f\nroot view height: %f\nDifference: %f",yPos,self.tagView.frame.size.height,self.view.frame.size.height,(yPos + self.tagView.frame.size.height) - self.view.frame.size.height);
        
        NSUInteger diff = (yPos + self.tagView.frame.size.height) - self.view.frame.size.height;
            //yPos = self.view.frame.size.height - (yPos+30.0f);
        yPos = (yPos - diff);
      }
    
    
    newFrameForTagView = CGRectMake(xPos, yPos, self.tagView.frame.size.width, self.tagView.frame.size.height);
    
    DLog(@"xPos for tag: %f\nyPos for tag: %f\nNew frame: %@",xPos,yPos,NSStringFromCGRect(newFrameForTagView));
    
    // Update tag with email view frame
    self.tagWithEmailView.frame = CGRectMake(self.tagView.frame.origin.x, (self.tagView.frame.size.height-220),
                                             self.tagView.frame.size.width, 220);
    
    return newFrameForTagView;
}


-(CGRect)resetTagViewFrame
{
    self.tagView.frame = CGRectMake(0, 170, 236, 330);
    self.tagWithEmailView.alpha = 0;
    DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
    
    return self.tagView.frame;
}


-(CGRect)shrinkTagViewHeight
{
    self.tagView.frame = CGRectMake(self.tagView.frame.origin.x, self.tagView.frame.origin.y,
                                    self.tagView.frame.size.width, 0);
    
    DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
    
    return self.tagView.frame;
}


-(CGRect)inflateTagViewHeight
{
    if (self.tagFriendsInContactsButton.hidden == YES) {
        
        self.tagTableView.frame = CGRectMake(self.tagTableView.frame.origin.x, self.tagTableView.frame.origin.y, self.tagTableView.frame.size.width, self.tagTableView.frame.size.height + self.tagFriendsInContactsButton.frame.size.height + 20);
        
    }
        
        self.tagView.frame = CGRectMake(self.tagView.frame.origin.x, self.tagView.frame.origin.y,
                                        self.tagView.frame.size.width, 330);
        
        DLog(@"Tag view frame reset: %@",NSStringFromCGRect(self.tagView.frame));
 
    [self.tagTableView setNeedsLayout];
    [self.tagTableView setNeedsDisplay];
    
    return self.tagView.frame;
}


#pragma mark - Helper methods to read user's contacts
- (void)fetchPhoneContacts:(TagType)inviteChannel completion:(void (^)(NSArray *contacts))success failure:(void (^)(NSError *error))failure {
    if (ABAddressBookRequestAccessWithCompletion) {
        
        CFErrorRef err;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &err);
        
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            // ABAddressBook doesn't gaurantee execution of this block on main thread, but we want our callbacks to be
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!granted) {
                    //failure((__bridge NSError *)error);
                    DLog(@"Access to contacts refused");
                    [AppHelper showAlert:@"Contacts Access Denied"
                                 message:@"We do not have access to your contacts. To allow us to access your contacts,please go to Settings->Privacy->Contacts"
                                 buttons:@[@"OK"] delegate:nil];
                } else {
                    
                    readAddressBookContacts(addressBook,inviteChannel, success);
                }
                CFRelease(addressBook);
            });
        });
    }
}


static void readAddressBookContacts(ABAddressBookRef addressBook, TagType inviteChannel, void (^completion)(NSArray *contacts)) {
    CFArrayRef people =  ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
                                                               kCFAllocatorDefault,
                                                               CFArrayGetCount(people),
                                                               people
                                                               );
    long numberOfRecords = ABAddressBookGetPersonCount(addressBook);
    CFArraySortValues(
                      peopleMutable,
                      CFRangeMake(0, CFArrayGetCount(peopleMutable)),
                      (CFComparatorFunction) ABPersonComparePeopleByName,
                      (void *) ABPersonGetSortOrdering()
                      );
    
    
    NSMutableArray *contacts = [NSMutableArray arrayWithCapacity:numberOfRecords];
    
    for (int x = 0; x < numberOfRecords; x++){
        
        ABRecordRef person = CFArrayGetValueAtIndex(peopleMutable, x);
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonFirstNameProperty);
        NSString *lastName = ( (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) == nil) ? @"" : (__bridge_transfer NSString*)ABRecordCopyValue(person,kABPersonLastNameProperty) ;
        
        NSString *email = nil;
        NSString *phone = nil;
        ABMultiValueRef contactInfo =  nil;
        ABMultiValueRef  phoneNumber = nil;
        
        if (inviteChannel == kEmail) {
            contactInfo = ABRecordCopyValue(person,kABPersonEmailProperty);
            phoneNumber = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }else{
            contactInfo = ABRecordCopyValue(person, kABPersonPhoneProperty);
        }
        
        //DLog(@"Copy value: %@",);
        
        if (ABMultiValueGetCount(phoneNumber) > 0) {
            
            email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(contactInfo, 0);
            phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumber, 0);
            
            UIImage* image;
            
            NSDictionary *singleContact = @{@"firstName": ( (firstName== nil) ? @"" : firstName ),
                                            @"lastName" : ( (lastName==nil) ? @"" :lastName ),
                                            @"userName" :  ( (email == nil) ? phone : email ),
                                            @"userEmail" : ( (email == nil) ? phone : email ),
                                            @"phone" : ( (phone == nil) ? @"" : phone ),
                                            @"source" : @"device"};
            
            NSMutableDictionary *userContact = [NSMutableDictionary dictionaryWithDictionary:singleContact];
            
            if(ABPersonHasImageData(person)){
                image = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageData(person)];
                [userContact setValue:@"YES" forKey:@"imageExists"];
                
            }else{
                image = [UIImage imageNamed:@"anonymousUser"];
                [userContact setValue:@"NO" forKey:@"imageExists"];
            }
            
            [userContact setValue:image forKey:@"photoURL"];
            
            [contacts addObject:userContact];
            
        } else {
            
            phone = @"[None]";
        }
    }
    
    completion(contacts);
}


- (void)showEmailContacts{
    
    [self.contactsActivityIndicator startAnimating];
    
    [self fetchPhoneContacts:kEmail completion:^(NSArray *contacts) {
        
        [self.tagFriendsInContactsButton setTitle:@"Find on Suba" forState:UIControlStateNormal];
        
        //DLog(@"Tag friends Btn text: %@",self.tagFriendsInContactsButton.titleLabel.text);
        
        [self.contactsActivityIndicator stopAnimating];
        
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            
            DLog(@"Contacts - %@",sortedContacts);
            friendsOnSuba = self.taggableFriends;
            
            self.taggableFriends = [NSMutableArray arrayWithArray:sortedContacts];
            
            self.tagTableView.frame = CGRectMake(self.tagTableView.frame.origin.x, self.tagTableView.frame.origin.y, self.tagTableView.frame.size.width, self.tagTableView.frame.size.height + self.tagFriendsInContactsButton.frame.size.height + 20);
            
            [self.tagTableView setNeedsLayout];
            [self.tagTableView setNeedsDisplay];
            
            isFiltered = NO;
            [self.tagTableView reloadData];
            
            DLog("Tag table view: %@",NSStringFromCGRect(self.tagTableView.frame));
            
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}



- (void)showPhoneContacts{
    [self.contactsActivityIndicator startAnimating];
    
    [self fetchPhoneContacts:kContacts completion:^(NSArray *contacts) {
        
        [self.contactsActivityIndicator stopAnimating];
        
        // We are sorting the contacts here
        if ([contacts count] > 0){
            
            NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:YES];
            NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
            NSArray *sortedContacts = [contacts sortedArrayUsingDescriptors:sortDescriptors];
            self.phoneContacts = sortedContacts;
            
            [self.taggableFriends addObjectsFromArray:sortedContacts];
            
            [self.tagTableView reloadData];
        }
        
    } failure:^(NSError *error) {
        DLog(@"Error - %@",error);
    }];
}


#pragma mark - UITextField Delegate
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [textField becomeFirstResponder];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *searchString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    DLog(@"What is the search string");
    
    if(textField == self.searchFriendNameTextField){
    
    
        if (searchString.length == 0) {
            isFiltered = NO;
            [self.tagTableView reloadData];
        
        }else if (searchString.length >  0){
            [self filterContentForSearchText:searchString];
        }
    
    
        if ([self.tagFriendsInContactsButton.titleLabel.text isEqualToString:@"Find in Contacts"]
            && searchString.length > 1) {
            DLog(@"We'll now search for users");
            [self showResultsForUsersMatchingName:searchString];
        }
    
    }else{
        
        // It is the other textfields
        if (textField == self.friendNameTextField && searchString.length > 0) {
            
            
            if([AppHelper validateEmail:self.friendEmailTextField.text]) {
                self.tagWithEmailButton.enabled = YES;
                [self.tagWithEmailButton setTitle:[NSString stringWithFormat:@"TAG %@",searchString.uppercaseString] forState:UIControlStateNormal];
            }else{
                
                [self.tagWithEmailButton setTitle:@"TAG WITH EMAIL" forState:UIControlStateNormal];
                self.tagWithEmailButton.enabled = NO;
            }
            
        }else if( textField == self.friendEmailTextField && searchString.length > 0 ) {
            
            if([AppHelper validateEmail:searchString]) {
                self.tagWithEmailButton.enabled = YES;
                [self.tagWithEmailButton setTitle:[NSString stringWithFormat:@"TAG %@",self.friendNameTextField.text.uppercaseString] forState:UIControlStateNormal];
            }else{
                
                [self.tagWithEmailButton setTitle:@"TAG WITH EMAIL" forState:UIControlStateNormal];
                self.tagWithEmailButton.enabled = NO;
            }
        }else{
            [self.tagWithEmailButton setTitle:@"TAG WITH EMAIL" forState:UIControlStateNormal];
            self.tagWithEmailButton.enabled = NO;
        }
            
    }
    
    return YES;
}



- (void)keyboardShouldShow:(NSNotification *)notification{
    //Store frame of tag view before keyboard shows
    //frameOfTagViewBeforeKeyboardShows = self.tagView.frame;
    self.tagView.frame = frameOfTagViewBeforeKeyboardShows;
    DLog(@"Tag view frame before keyboard shows: %@",NSStringFromCGRect(self.tagView.frame));
    
    NSDictionary* userInfo = [notification userInfo];
    
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    
    DLog(@"Start Frame: %@\nEnd frame: %@",NSStringFromCGRect(startFrame),NSStringFromCGRect(endFrame));
    
    CGFloat sumOfTagViewAndHeight = frameOfTagViewBeforeKeyboardShows.origin.y + frameOfTagViewBeforeKeyboardShows.size.height;
    CGFloat yPosOfKeyboardFrame = endFrame.origin.y - (64.0f + 5.0f);
    CGFloat yChangeOfTagViewFrame = (sumOfTagViewAndHeight > yPosOfKeyboardFrame) ? sumOfTagViewAndHeight-yPosOfKeyboardFrame : 0 ;
   
    DLog(@"sumOfTagViewAndHeight: %f\nyPosOfKeyboardFrame: %f\nyChangeOfTagViewFrame: %f",sumOfTagViewAndHeight,yPosOfKeyboardFrame,yChangeOfTagViewFrame);
    
    CGRect newContainerFrame = CGRectMake(frameOfTagViewBeforeKeyboardShows.origin.x,
                            (frameOfTagViewBeforeKeyboardShows.origin.y - yChangeOfTagViewFrame) + 64,
                            self.tagView.frame.size.width, self.tagView.frame.size.height);
    
    DLog(@"Tag view frame: %@\nNew frame: %@",NSStringFromCGRect(self.tagView.frame),NSStringFromCGRect(newContainerFrame));
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [self.tagView setFrame:newContainerFrame];
                     }
                     completion:NULL];
}



- (void)keyboardShouldHide:(NSNotification *)notification{
    NSDictionary* userInfo = [notification userInfo];
    
    NSTimeInterval duration;
    UIViewAnimationCurve animationCurve;
    CGRect startFrame;
    CGRect endFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&duration];
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]    getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey]        getValue:&startFrame];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]          getValue:&endFrame];
    
    
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:(animationCurve << 16)|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         
                         [self.tagView setFrame:frameOfTagViewBeforeKeyboardShows];
                     }
                     completion:NULL];
}





/*- (IBAction)tagUserInPhoto:(UIButton *)sender
{
    self.backgroundBlurView.alpha = 0;
}*/


-(void)filterContentForSearchText:(NSString*)searchText {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    
    [filteredTaggableUsers removeAllObjects];
    
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"firstName contains[c] %@ OR lastName contains[c] %@",searchText,searchText];
    
    NSArray *sortedTaggableFriends = [NSMutableArray arrayWithArray:[self.taggableFriends filteredArrayUsingPredicate:predicate]];
    
    filteredTaggableUsers = [NSMutableSet setWithArray:sortedTaggableFriends];
    
    isFiltered = YES;
    
    [self.tagTableView reloadData];
    
}


- (void)showResultsForUsersMatchingName:(NSString *)name
{
    [self.searchingForUsersActivityIndicator startAnimating];
    
    [User searchUserMatchingNames:@{@"userId" : [AppHelper userID],@"searchText": name} completion:^(id results, NSError *error) {
        
        [self.searchingForUsersActivityIndicator stopAnimating];
        
        if (!error) {
            // we've got results
            taggableSubaUsers = results[@"users"];
            
            [filteredTaggableUsers addObjectsFromArray:taggableSubaUsers];
            
            
        }else{
            DLog(@"There was an error");
        }
        
        [self.tagTableView reloadData];
    }];
}



- (void)handleTapOnTag:(__weak AMPopTip *)weakPopTip
{
    
    // Check whether this tag is a suba user and got to profile
    if (weakPopTip.tag > 0) { //From the server
        selectedPopOverForDelete = weakPopTip;
        NSUInteger indexOfPopTipToRemove = [popUpTips indexOfObject:selectedPopOverForDelete];
        
        NSDictionary *tagInfo = [self.tagsInPhoto objectAtIndex:indexOfPopTipToRemove];
        DLog(@"Person tagged - %@",tagInfo);
        NSString *userId = tagInfo[@"personTaggedId"];
        //self.navigationController.navigationBar.translucent = NO;
        [self performSegueWithIdentifier:@"TAGGED_USER_PROFILE_SEGUE" sender:userId];
        
    }else if(weakPopTip.popoverColor == kSUBA_APP_COLOR && weakPopTip.tag == 0){ //Not yet on server
        // Look for tag info
    }
}



- (void)showRemoveTagButton:(__weak AMPopTip *)weakPopTip
{
    UIImage *icon = [IonIcons imageWithIcon:icon_close size:15 color:[UIColor whiteColor]];
    
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1.5
                        options:UIViewAnimationOptionCurveEaseInOut animations:^{
                            CGRect initialButtonFrame = CGRectZero;
                            CGRect buttonFrame = CGRectZero;
                            
                            CGFloat totalWidth = weakPopTip.frame.origin.x + weakPopTip.frame.size.width + 30.0f;
                            
                            if ( totalWidth < (self.view.frame.size.width - 5) ){
                                // If the total width does not exceed the width of the root view
                                
                                initialButtonFrame = CGRectMake((weakPopTip.frame.origin.x + weakPopTip.frame.size.width) - 1.0f,
                                                                weakPopTip.frame.origin.y + 7.5f,
                                                                0, weakPopTip.frame.size.height - 8.0f);
                                
                                buttonFrame = CGRectMake((weakPopTip.frame.origin.x + weakPopTip.frame.size.width) - 1.0f,
                                                         weakPopTip.frame.origin.y + 7.5f,
                                                         30, weakPopTip.frame.size.height - 8.0f);
                                
                            }else{
                                initialButtonFrame = CGRectMake( (weakPopTip.frame.origin.x - 30) + 1.0f,
                                                                weakPopTip.frame.origin.y + 7.5f,
                                                                0, weakPopTip.frame.size.height - 8.0f);
                                
                                buttonFrame = CGRectMake((weakPopTip.frame.origin.x - 30) + 1.0f,
                                                         weakPopTip.frame.origin.y + 7.5f,
                                                         30, weakPopTip.frame.size.height - 8.0f);
                            }
                            
                            
                            UIButton *myButton = [[UIButton alloc] initWithFrame:initialButtonFrame];
                            
                            [myButton setBackgroundColor:kSUBA_TAG_COLOR];
                            [myButton setImage:icon forState:UIControlStateNormal];
                            [myButton setImage:icon forState:UIControlStateHighlighted];
                            
                            [myButton addTarget:self action:@selector(removeTag:) forControlEvents:UIControlEventTouchUpInside];
                            
                            myButton.tag = 1;
                            [self.view addSubview:myButton];
                            
                            myButton.frame = buttonFrame;
                            
                        } completion:nil];
}



- (void)handleLongPressOnTag:(__weak AMPopTip *)weakPopTip
{
    // Let's check whether this user has the right to delete a tag
    //1. First, we check the user added this photo.
    //2. Second, we check the user tagged this photo.
    //3. Third, we check the user is the person tagged in this photo.
    
    DLog(@"Image info: %@",self.imageInfo);
    
    NSString *personTaggedId = nil;
    NSString *taggerId = nil;
    NSString *picTakerId = self.imageInfo[@"pictureTakerId"];
    
    if (weakPopTip.tag > 0) { // Tag is from the server
        DLog(@"Tag is a server tag");
        NSUInteger indexOfPopTipToRemove = [popUpTips indexOfObject:weakPopTip];
        
        if (indexOfPopTipToRemove != NSNotFound) {
            NSDictionary *tagInfo = [self.tagsInPhoto objectAtIndex:indexOfPopTipToRemove];
            DLog(@"Person tagged - %@",tagInfo);
            personTaggedId = tagInfo[@"personTaggedId"];
            taggerId = tagInfo[@"taggerId"];
        }
        
    }else{
        taggerId = [AppHelper userID];
    }
    
    
    if ( [ [User currentlyActiveUser].userID isEqualToString:picTakerId] || [taggerId isEqualToString:[AppHelper userID]]
        || [personTaggedId isEqualToString:[AppHelper userID]]) {
    
        // We can only delete the tag if the user satisfies any of the above conditions
        if ([self.view viewWithTag:1] && [self.view viewWithTag:1].class == [UIButton class]){
            
            UIButton *button = (UIButton *)[self.view viewWithTag:1];
            [button removeFromSuperview];
        }
        
        selectedPopOverForDelete = weakPopTip;
       
        UIAlertView *confirmTagDelete = [[UIAlertView alloc] initWithTitle:@"" message:@"Do you want to delete this tag?" delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
        
        confirmTagDelete.tag = 200;
        [confirmTagDelete show];
        
    }
}




- (void)showPopTipViewForTagWithSubaColor:(BOOL)subaUser AndName:(NSString *)name
{
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:1.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        self.tagView.alpha = 0;
        self.tagWithEmailView.alpha = 0;
        //[self shrinkTagViewHeight];
        
        [self.friendNameTextField resignFirstResponder];
        [self.friendEmailTextField resignFirstResponder];
        [self.searchFriendNameTextField resignFirstResponder];
        
    } completion:^(BOOL finished) {
        
        DLog(@"show tag hint: %i",[AppHelper showTagHint]);
        
        if ([AppHelper showTagHint] == YES){
            DLog(@"Showing the tag hint for the first time");
            [self showLongPressPopTip:tapFrame];
            [AppHelper setshowTagHint:NO];
        }
        
        //[self resetTagViewFrame];
        [self showPopTipView:name usingSubaColor:subaUser fromFrame:tapFrame tag:0];
        toggler += 1;
        
    }];
}



- (void)showPopTipView:(NSString *)userName usingSubaColor:(BOOL)subaColor fromFrame:(CGRect)fromFrame tag:(NSInteger)tag
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
    
        DLog(@"Hash of this pop tip: %@", @(popTip.hash));
    
        __weak typeof(popTip) weakPopTip = popTip;
    
        // Handle long press on the pop tip
        popTip.longPressHandler = ^{
            [self handleLongPressOnTag:weakPopTip];
       };
    
        // Handle tap of the pop tip
        popTip.tapHandler = ^{
        // Go to the profile of the user who was tapped
            DLog("tap to go to profile");
            [self handleTapOnTag:weakPopTip];
        };
    
    
        // Show the pop tip
        [popTip showText:userName direction:AMPopTipDirectionDown maxWidth:200.0f
              inView:self.view fromFrame:fromFrame];
    
    
    
        // Check and delete this later
        [self.view bringSubviewToFront:self.tagView];
    
        DLog(@"Pop tip frame: %@",NSStringFromCGRect(popTip.frame));
        //[self.view bringSubviewToFront:self.longPressHintView];
    
    if (popTip.tag == 0) {
        if (self.self.self.localPopUpTips) {
            [self.self.self.localPopUpTips addObject:popTip];
        }else{
            self.self.localPopUpTips = [NSMutableArray arrayWithCapacity:1];
            [self.self.localPopUpTips addObject:popTip];
        }
        
        self.tagDoneButton.enabled = YES;
        
    }else{
    
        if (popUpTips) {
            [popUpTips addObject:popTip];
        }else{
            popUpTips = [NSMutableArray arrayWithCapacity:1];
            [popUpTips addObject:popTip];
        }
    }
}


- (void)addTapGestureRecognizerToView:(UIView *)view
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandPopTip:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.cancelsTouchesInView = NO;
    
    [view addGestureRecognizer:tapRecognizer];
}


- (void)expandPopTip:(AMPopTip *)popTip
{
    DLog(@"Tap recognized in pop tip: %@",NSStringFromCGRect(popTip.superview.frame));
}


- (IBAction)removeTag:(UIButton *)sender
{
    self.tagDoneButton.enabled = YES;
    
    [popUpTips removeObject:selectedPopOverForDelete];
    NSString *personTaggedName = selectedPopOverForDelete.text;
    
    for (NSDictionary *localTag in self.localTags) {
        if ([localTag[@"personTaggedName"] isEqualToString:personTaggedName]) {
            // Removing tag from local tags
            [self.localTags removeObject:localTag];
        }
    }
    
    // Let's check if we have some tags to from the server
    if (self.tagsInPhoto) {
        NSInteger tag = selectedPopOverForDelete.tag;
        
        // Now let's check if the tag to be removed is from the server
        for (NSDictionary *tagInfo in self.tagsInPhoto) {
            NSNumber *popTag = tagInfo[@"tagId"];
            
            if (tag == popTag.integerValue){
                
                DLog(@"Tag selected to remove: %@",tagInfo);
                
                [User removTag:@{@"tagId" : @(tag),@"taggerId" : tagInfo[@"taggerId"]}
                    completion:^(id results, NSError *error) {
                    if (error) {
                        DLog(@"Error - %@",error.description);
                    }
                }];
                
                break;
            }
        }
    }
    
    
    DLog(@"Pop tips are now: %@",popUpTips.description);
    
    
    // If there's a queued operation, then it means this tag is yet to be saved on the server
    if (mutableTagOperations.count > 0) {
        NSUInteger popTipIndex = [self.localPopUpTips indexOfObject:selectedPopOverForDelete];
        
        if (popTipIndex != NSNotFound) {
            [mutableTagOperations removeObjectAtIndex:popTipIndex];
            [self.localPopUpTips removeObject:selectedPopOverForDelete];
        }
        
    }
    
    [selectedPopOverForDelete hide];
    [selectedPopOverForDelete removeFromSuperview];
    
    [sender removeFromSuperview];
}



- (void)removeTag
{
    self.tagDoneButton.enabled = YES;
    
    [popUpTips removeObject:selectedPopOverForDelete];
    NSString *personTaggedName = selectedPopOverForDelete.text;
    
    for (NSDictionary *localTag in self.localTags) {
        if ([localTag[@"personTaggedName"] isEqualToString:personTaggedName]) {
            // Removing tag from local tags
            [self.localTags removeObject:localTag];
        }
    }
    
    // Let's check if we have some tags to from the server
    if (self.tagsInPhoto) {
        NSInteger tag = selectedPopOverForDelete.tag;
        
        // Now let's check if the tag to be removed is from the server
        for (NSDictionary *tagInfo in self.tagsInPhoto) {
            NSNumber *popTag = tagInfo[@"tagId"];
            
            if (tag == popTag.integerValue){
                
                DLog(@"Tag selected to remove: %@",tagInfo);
                
                [User removTag:@{@"tagId" : @(tag),@"taggerId" : tagInfo[@"taggerId"]}
                    completion:^(id results, NSError *error) {
                        if (error) {
                            DLog(@"Error - %@",error.description);
                        }
                    }];
                
                break;
            }
        }
    }
    
    
    DLog(@"Pop tips are now: %@",popUpTips.description);
    
    
    // If there's a queued operation, then it means this tag is yet to be saved on the server
    if (mutableTagOperations.count > 0) {
        NSUInteger popTipIndex = [self.localPopUpTips indexOfObject:selectedPopOverForDelete];
        
        if (popTipIndex != NSNotFound) {
            [mutableTagOperations removeObjectAtIndex:popTipIndex];
            [self.localPopUpTips removeObject:selectedPopOverForDelete];
        }
        
    }
    
    [selectedPopOverForDelete hide];
    [selectedPopOverForDelete removeFromSuperview];
}



- (void)tagUser:(NSDictionary *)params
{
  [User tagUser:params completion:^(id results, NSError *error) {
      if(error)DLog(@"Tag error: %@",error);
          else DLog(@"Tag results: %@",results);
  }];
}


- (void)hideTags
{
    for (AMPopTip *popUpView in popUpTips) {
        //DLog(@"Pop tip gestures are: %i",[popUpView.gestureRecognizers count]);
        for (UIGestureRecognizer *gr in popUpView.gestureRecognizers) {
            [popUpView removeGestureRecognizer:gr];
        }
    }
    
}


// We show the tags from the pop up tips
- (void)showTags
{
    for (AMPopTip *popUpView in popUpTips) {
        //[popUpView setAlpha:1];
        
        [popUpView showText:popUpView.text direction:AMPopTipDirectionDown maxWidth:200.0f inView:self.view fromFrame:popUpView.fromFrame];
        
    }
    
    DLog(@"Tag shown");
}


- (void)clearTextField:(UITextField *)textField
{
    isFiltered = NO;
    
    [self.tagTableView reloadData];
}


- (void)addTagOperation:(NSDictionary *)params
{
    AFHTTPSessionManager *manager = [SubaAPIClient sharedInstance];
    [manager setRequestSerializer:[AFJSONRequestSerializer new]];
    AFHTTPRequestSerializer *requestSerializer = manager.requestSerializer;
    NSURL *baseURL = (NSURL *)[SubaAPIClient subaAPIBaseURL];
    
    [requestSerializer setValue:@"com.suba.subaapp-ios" forHTTPHeaderField:@"x-suba-api-token"];
    
    NSString *urlPath = [[NSURL URLWithString:kTAG_PHOTO_PATH relativeToURL:baseURL] absoluteString];
    NSError *error  = nil;
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:kHTTP_METHOD_POST URLString:urlPath parameters:params error:&error];
    
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    [mutableTagOperations addObject:operation];
}



- (void)getTagsForPhoto
{
    [User getTagsForPhoto:@{ @"userId" : [AppHelper userID], @"photoId" : self.imageId } completion:^(id results, NSError *error) {
        if (!error) {
            if (self.tagsInPhoto) {
                [self.tagsInPhoto removeAllObjects];
            }
            
            self.tagsInPhoto = [NSMutableArray arrayWithArray:results[@"tags"]];
            
            DLog(@"Tags from server: %@",[self.tagsInPhoto description]);
            
            [self showAllTagsInPhoto:self.tagsInPhoto];
        }
    }];
}



- (void)showAllTagsInPhoto:(NSArray *)tags
{
    if (popUpTips.count > 0) {
        for (AMPopTip *tip in popUpTips) {
            if (tip.tag > 0) {
                // This is a tag from the server. Let's remove all of thm from the root view
                [tip removeFromSuperview];
            }
        }
        
        [popUpTips removeAllObjects];
    }
    
    for (NSDictionary *tagInfo in tags) {
        NSString *nameOfPersonTagged = tagInfo[@"personTagged"];
        BOOL isSubaUser = ( ![tagInfo[@"personTaggedId"] isEqualToString:@"-1"] );
        NSNumber *popTag = tagInfo[@"tagId"];
        NSNumber *xPos = tagInfo[@"xPosition"];
        NSNumber *yPos = tagInfo[@"yPosition"];
        
        CGRect adjustedXAndYPos = [self scaleTagFrameToFitCurrentScreenWithXPos:xPos.floatValue AndYPos:yPos.floatValue];
        
        DLog(@"Adjusted X and Y for current screen: %@",NSStringFromCGRect(adjustedXAndYPos));
        
        CGRect fromFrame = CGRectMake(adjustedXAndYPos.origin.x, adjustedXAndYPos.origin.y, 0, 0);
        
        [self showPopTipView:nameOfPersonTagged usingSubaColor:isSubaUser
                   fromFrame:fromFrame tag:popTag.integerValue];
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



#pragma mark - uialertview delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    DLog(@"alert view clicked %ld",(long)buttonIndex);
    
    if (buttonIndex == 1) {
        [self removeTag];
    }
}





@end
