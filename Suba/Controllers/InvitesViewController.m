//
//  InvitesViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/15/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "InvitesViewController.h"
#import "SubaUsersInviteCell.h"
#import "FacebookUsersCell.h"
#import "SMSContactsCell.h"
#import "User.h"

#define PhoneContactsKey @"PhoneContactsKey"
#define FacebookUsersKey @"FacebookUsersKey"
#define SelectedSegmentKey @"SelectedSegmentKey"
#define SubaUsersKey @"SubaUsersKey"

@interface InvitesViewController ()<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>

@property (strong,nonatomic) NSMutableArray *subaUsers;
@property (strong,nonatomic) NSMutableArray *invitedSubaUsers;

@property (retain,nonatomic) NSMutableArray *subaUsersFilteredArray;
@property (retain,nonatomic) NSMutableArray *fbUsersFilteredArray;


@property (retain, nonatomic) IBOutlet UISearchBar *invitesSearchBar;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *inviteBarButtonItem;
@property (weak, nonatomic) IBOutlet UITableView *subaUsersTableView;
@property (weak, nonatomic) IBOutlet UIView *loadingDataView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingDataActivityIndicator;


- (IBAction)inviteUsers:(id)sender;
- (void)displaySubaUsers;
- (void)refreshTableView:(UITableView *)tableView;
- (IBAction)dismissViewController:(id)sender;

@end

@implementation InvitesViewController
static BOOL isFiltered = NO;

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationController.navigationBar.topItem.title = @"";
    
    self.invitedSubaUsers = [NSMutableArray array];
    
    self.subaUsersFilteredArray = [NSMutableArray arrayWithCapacity:[self.subaUsers count]];
}


-(void)viewWillAppear:(BOOL)animated
{
     __weak typeof(self) weakSelf = self;
    
    if (self.subaUsers) {
        //DLog(@"Suba Users - %@",self.subaUsers);
    }else{
        [self displaySubaUsers];
        //DLog(@"Suba is not set");
    }
    
    [self.subaUsersTableView addPullToRefreshActionHandler:^{
        [weakSelf displaySubaUsers];
    }];
    
    [self.subaUsersTableView.pullToRefreshView setImageIcon:[UIImage imageNamed:@"icon-72"]];
    [self.subaUsersTableView.pullToRefreshView setBorderWidth:6];
    
    self.navigationController.navigationBar.topItem.title = @"";
    
    [self.invitesSearchBar becomeFirstResponder];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)inviteUsers:(id)sender
{
    isFiltered = NO;
    
    NSDictionary *invitedUsers = nil;
        if ([self.invitedSubaUsers count] == 1) {
            invitedUsers = @{@"userId": (NSString *)self.invitedSubaUsers[0],@"streamId" : self.spotToInviteUserTo[@"spotId"],@"senderId" : [AppHelper userID]};
            
        }else if([self.invitedSubaUsers count] > 1){
            invitedUsers = @{@"userIds" : self.invitedSubaUsers,@"streamId" : self.spotToInviteUserTo[@"spotId"],@"senderId" : [AppHelper userID]};
        }
    
        [[SubaAPIClient sharedInstance] POST:@"spot/members/add" parameters:invitedUsers success:^(NSURLSessionDataTask *task, id responseObject) {
            //UIColor *tintColor = [UIColor colorWithRed:0.00 green:0.8 blue:0.2 alpha:1];
            if([responseObject[STATUS] isEqualToString:ALRIGHT]){
                [FBAppEvents logEvent:@"Suba_User_Invited_To_Stream"];
                //[self performSegueWithIdentifier:@"FromAddToMembersSegue" sender:nil];
                //[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
                
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Failure reason - %@",error.localizedFailureReason);
        }];
       
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
   //[self.invitesSearchBar resignFirstResponder];
 
}


#pragma mark - Helpers

-(void)refreshTableView:(UITableView *)tableView
{
    //DLog(@"Table View Bounds - %@",NSStringFromCGRect(tableView.bounds));
    
    for (NSIndexPath *indexPath in [tableView indexPathsForRowsInRect:tableView.bounds]){
        
        //NSLog(@"IndexPath.row - %i",indexPath.row);
        UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
    }
    
}

- (IBAction)dismissViewController:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



-(void)displaySubaUsers
{
    [AppHelper showLoadingDataView:self.loadingDataView indicator:self.loadingDataActivityIndicator flag:YES];
    
   [User allUsers:^(id results, NSError *error) {
       //DLog(@"Suba Users - %@",results);
       if (!error) {
           NSArray *subaUsers = results;
           
           // Filter the users in ascending order
           NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"userName" ascending:YES];
           NSArray *sortDescriptors = [NSArray arrayWithObject:firstNameDescriptor];
           NSArray *sortedUsers = [subaUsers sortedArrayUsingDescriptors:sortDescriptors];
           self.subaUsers = [NSMutableArray arrayWithArray:sortedUsers];
           DLog(@"Suba users - %@",self.subaUsers);
           NSDictionary *userToRemove = nil;
           for (NSDictionary *user in self.subaUsers){
               //DLog(@"Username class - %@ ----- %@ --- %@",[user[@"userName"] class],user[@"userName"],user[@"id"]);
               if ([user[@"userName"] class] != [NSNull class]) {
                   if ([user[@"userName"] isEqualToString:[AppHelper userName]]) {
                       userToRemove = user;
                   }
               }
               
           }
          
           [AppHelper showLoadingDataView:self.loadingDataView indicator:self.loadingDataActivityIndicator flag:NO];
           
           [self.subaUsers removeObject:userToRemove];
           //[self.subaUsersTableView reloadData];

       }else{
           DLog(@"Error - %@",error);
       }
   }];
    
}




#pragma mark - UITableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    numberOfRows = [self.subaUsersFilteredArray count];

    return numberOfRows;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        static NSString *cellIdentifier = nil;
        
        
        NSString *userName = nil;
        NSString *photoURL = nil;
        NSString *userId = nil;
        cellIdentifier = @"SubaInvitesCell";
        
        SubaUsersInviteCell *subaUserCell = (SubaUsersInviteCell *)[self.subaUsersTableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if (isFiltered){
            
            photoURL = (NSString *)[self.subaUsersFilteredArray[indexPath.row] objectForKey:@"photo"];
            if ([self.subaUsersFilteredArray[indexPath.row] objectForKey:@"firstName"] && [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"lastName"]){
                
                NSString *firstName = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"firstName"];
                NSString *lastName = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"lastName"];
                userName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                
                if (photoURL) {
                    [subaUserCell fillView:subaUserCell.subaUserImageView WithImage:photoURL];
                }else{
                    if (firstName && lastName) {
                        [subaUserCell makeInitialPlaceholderView:subaUserCell.subaUserImageView name:userName];
                    }else{
                        userName = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"userName"];
                        [subaUserCell makeInitialPlaceholderView:subaUserCell.subaUserImageView name:userName];
                    }
                }
                
            }else{
                userName = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"userName"];
            }
            
        }else{
            photoURL = (NSString *)[self.subaUsers[indexPath.row] objectForKey:@"photo"];
            
            if ([self.subaUsers[indexPath.row] objectForKey:@"firstName"] && [self.subaUsers[indexPath.row] objectForKey:@"lastName"]){
                
                NSString *firstName = [self.subaUsers[indexPath.row] objectForKey:@"firstName"];
                NSString *lastName = [self.subaUsers[indexPath.row] objectForKey:@"lastName"];
                userName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                
            }else{
                userName = [self.subaUsers[indexPath.row] objectForKey:@"userName"];
            }
            
            
            userId = [self.subaUsers[indexPath.row] objectForKey:@"id"];
        }
        
        // Check whether this cell is contained in last selected indexPaths
        if ([self.invitedSubaUsers containsObject:userId]){
            //DLog(@"%@ is part of invites",userName);
            subaUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else if(![self.invitedSubaUsers containsObject:userId]){
            //DLog(@"%@ has not been invited so removing the checkmark",userName);
            subaUserCell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        subaUserCell.userNameLabel.text = userName;
        [subaUserCell.userNameLabel sizeToFit];
        
        return subaUserCell;

    }
    @catch (NSException *exception) {}
    @finally {}
}


#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.inviteBarButtonItem.enabled = YES;
    
   
        SubaUsersInviteCell *subaUserCell = (SubaUsersInviteCell *)[self.subaUsersTableView cellForRowAtIndexPath:indexPath];
        subaUserCell.accessoryType = UITableViewCellAccessoryCheckmark;
        NSString *recipientSelectedId = nil;
        
        if (isFiltered){
            recipientSelectedId = [self.subaUsersFilteredArray[indexPath.row] objectForKey:@"id"];
        }else{
            recipientSelectedId = [self.subaUsers[indexPath.row] objectForKey:@"id"];
        }
        [self.invitedSubaUsers addObject:(NSString *)recipientSelectedId];
        DLog(@"Invited suba users - %@",self.invitedSubaUsers);

}


-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    
        SubaUsersInviteCell *cell = (SubaUsersInviteCell *)[tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryNone;
        NSString *recipientSelectedId = [self.subaUsers[indexPath.row] objectForKey:@"id"];
        [self.invitedSubaUsers removeObject:recipientSelectedId];
        self.inviteBarButtonItem.enabled = ([self.invitedSubaUsers count] != 0);
}




#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.subaUsersFilteredArray removeAllObjects];
        // Filter the array using NSPredicate
   
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userName = %@ OR firstName = %@ OR lastName = %@",searchText,searchText,searchText];
    
        self.subaUsersFilteredArray = [NSMutableArray arrayWithArray:[self.subaUsers filteredArrayUsingPredicate:predicate]];
    
        [self.subaUsersTableView reloadData];
}


#pragma mark - UISearchBar Delegate
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    DLog(@"searchBar.text - %@",searchBar.text);
    
   if (searchBar.text == 0) {
        isFiltered = NO;
    }else{
        
        isFiltered = YES;
        [self filterContentForSearchText:searchBar.text
                                   scope:[[self.invitesSearchBar scopeButtonTitles]
                                          objectAtIndex:[self.invitesSearchBar selectedScopeButtonIndex]]];
    }
  
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}


-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
    
    return YES;
}


-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //[searchBar resignFirstResponder];

    searchBar.showsCancelButton = NO;
    [self.subaUsersFilteredArray removeAllObjects];
    [self.subaUsersTableView reloadData];
    
    isFiltered = NO;
}



#pragma mark - State Preservation and Restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];

    [coder encodeObject:self.subaUsers forKey:SubaUsersKey];
}


-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
        self.subaUsers = [coder decodeObjectForKey:SubaUsersKey];
}

-(void)applicationFinishedRestoringState
{
    
    [self performSelector:@selector(displaySubaUsers)];
}



@end
