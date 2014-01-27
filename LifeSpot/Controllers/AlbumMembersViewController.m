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

@interface AlbumMembersViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *memberTableView;
@property (strong,nonatomic) NSArray *members;
@property (strong,nonatomic) NSDictionary *spotInfo;

- (void)loadAlbumMembers:(NSString *)spotId;
- (void)updateMembersData;
@end

@implementation AlbumMembersViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self loadAlbumMembers:self.spotID];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.memberTableView addPullToRefreshActionHandler:^{
        // Method to update data
        [self updateMembersData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Helpers
-(void)loadAlbumMembers:(NSString *)spotId
{
   /*[Spot fetchMembersForSpot:spotId completion:^(id results, NSError *error) {
       DLog(@"Results - %@",results); 
       self.members = results;
       [self.memberTableView reloadData];
   }];*/
    
    [Spot fetchSpotInfo:spotId User:[AppHelper userID] completion:^(id results, NSError *error) {
        DLog(@"Results - %@",results);
        self.spotInfo = results;
        self.members = results[@"members"];
        [self.memberTableView reloadData];
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




@end
