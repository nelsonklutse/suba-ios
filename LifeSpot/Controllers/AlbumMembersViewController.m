//
//  AlbumMembersViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "AlbumMembersViewController.h"
#import "AlbumMembersCell.h"
#import "UserProfileViewController.h"
#import "InvitesViewController.h"
#import "Spot.h"


#define MembersKey @"MembersKey"
#define SpotInfoKey @"SpotInfoKey"
#define SpotIdKey @"SpotIdKey"

@interface AlbumMembersViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *memberTableView;
@property (strong,nonatomic) NSArray *members;
@property (strong,nonatomic) NSDictionary *spotInfo;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addMembersButton;
@property (weak, nonatomic) IBOutlet UIView *loadingMembersIndicatorView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingMembersIndicator;

- (void)loadAlbumMembers:(NSString *)spotId;
- (void)updateMembersData;
- (void)showAddMembersButton:(BOOL)flag;

- (IBAction)unWindToMembersFromCancel:(UIStoryboardSegue *)segue;
- (IBAction)unWindToMembersFromAdd:(UIStoryboardSegue *)segue;
@end

@implementation AlbumMembersViewController

-(IBAction)unWindToMembersFromCancel:(UIStoryboardSegue *)segue
{
    
}

-(IBAction)unWindToMembersFromAdd:(UIStoryboardSegue *)segue
{
    [CSNotificationView showInViewController:self
                                       style:CSNotificationViewStyleSuccess message:@"Participants added"];
   
    [self loadAlbumMembers:self.spotID];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (self.spotID){
        [self loadAlbumMembers:self.spotID];
    }
    
    [self showAddMembersButton:NO];
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.memberTableView addPullToRefreshActionHandler:^{
        // Method to update data
        [self updateMembersData];
    }];
    
    [self.memberTableView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.memberTableView.pullToRefreshView setBorderWidth:6];
    [self.memberTableView.pullToRefreshView setBackgroundColor:[UIColor redColor]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers
-(void)loadAlbumMembers:(NSString *)spotId
{
    [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:YES];
    
    [Spot fetchSpotInfo:spotId User:[AppHelper userID] completion:^(id results, NSError *error) {
        
        [AppHelper showLoadingDataView:self.loadingMembersIndicatorView indicator:self.loadingMembersIndicator flag:NO];
        
        if (!error) {
            //DLog(@"Results - %@",results);
            self.spotInfo = results;
            //DLog(@"Spot Info - %@",self.spotInfo);
            
            if (![self.spotInfo[@"userName"] isEqualToString:[AppHelper userName]]){
                // If user is not creator,we need to check whether he/she can invite users
                BOOL canUserAddMembers = ([self.spotInfo[@"memberInvitePrivacy"] isEqualToString:@"ONLY_MEMBERS"])?NO:YES;
                if (canUserAddMembers) {
                    [self showAddMembersButton:YES];
                }else [self showAddMembersButton:NO];
                
            }else [self showAddMembersButton:YES];
            //[self showAddMembersButton:YES];
            self.members = results[@"members"];
            [self.memberTableView reloadData];
        }else{
            [AppHelper showAlert:@"Network error" message:@"Sorry we could not load the members of this stream" buttons:@[@"Try Later"] delegate:nil];
        }
        
    }];
}


-(void)updateMembersData
{
    __weak typeof(self) weakSelf = self;
    
    int64_t delayInSeconds = 1.2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [weakSelf loadAlbumMembers:self.spotID];
        [weakSelf.memberTableView stopRefreshAnimation];
        
    });
}


-(void)showAddMembersButton:(BOOL)flag
{
    NSMutableArray *navbarButtons = [self.navigationItem.rightBarButtonItems mutableCopy];
    
    if (flag) {
        if ([navbarButtons count] != 1) {
            [navbarButtons addObject:self.addMembersButton];
        }
        
    }else{
        [navbarButtons removeObject:self.addMembersButton];
    }
   
    [self.navigationItem setRightBarButtonItems:navbarButtons animated:YES];
}


#pragma mark - UITableViewDatasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.members count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AlbumMembersCell";
    AlbumMembersCell *memberCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    memberCell.memberImageView.image = [UIImage imageNamed:@"anonymousUser"];
    
    memberCell.memberUserNameLabel.text = self.members[indexPath.row][@"userName"];
    memberCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (self.members[indexPath.row][@"photoURL"] != nil) {
        NSString *photoURL = self.members[indexPath.row][@"photoURL"];
        
        [memberCell.memberImageView setImageWithURL:[NSURL URLWithString:photoURL] placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
        
    }
    
    return memberCell;
    
}


#pragma mark - UITableView Delegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlbumMembersCell *cell = (AlbumMembersCell *)[tableView cellForRowAtIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    NSString *userId = self.members[indexPath.row][@"id"];
    //DLog(@"UserID of Participant - %@",userId);
    
    [self performSegueWithIdentifier:@"PARTICIPANTS_PROFILE_SEGUE" sender:userId];
}


#pragma mark - Segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"PARTICIPANTS_PROFILE_SEGUE"]) {
        UserProfileViewController *uVC = segue.destinationViewController;
        uVC.userId = sender;
        
    }
    
    if ([segue.identifier isEqualToString:@"InviteFriendsSegue"]) {
        InvitesViewController *iVC = segue.destinationViewController;
        iVC.spotToInviteUserTo = self.spotInfo;
    }
}


#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.spotID forKey:SpotIdKey];
    [coder encodeObject:self.members forKey:MembersKey];
    [coder encodeObject:self.spotInfo forKey:SpotInfoKey];
    DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.spotID = [coder decodeObjectForKey:SpotIdKey];
    self.members = [coder decodeObjectForKey:MembersKey];
    self.spotInfo = [coder decodeObjectForKey:SpotInfoKey];
    DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);

}

-(void)applicationFinishedRestoringState
{
    if (self.members) {
        [self.memberTableView reloadData];
    }else if(self.spotID){
        [self loadAlbumMembers:self.spotID];
    }
    
    DLog(@"Self.spotID -%@\nself.members - %@\nself.spotInfo - %@",self.spotID,self.members,self.spotInfo);

}

@end
