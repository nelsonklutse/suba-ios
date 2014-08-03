//
//  ActivityViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 1/29/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "ActivityViewController.h"
#import "LSPushProviderAPIClient.h"
#import "PhotoStreamViewController.h"

@interface ActivityViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong,nonatomic) NSArray *notifications;
@property (weak, nonatomic) IBOutlet UIView *notRegisteredForRemoteNotificationsView;
@property (weak, nonatomic) IBOutlet UIView *noRemoteNotificationsView;
@property (weak, nonatomic) IBOutlet UITableView *notificationsTableView;
@property (weak, nonatomic) IBOutlet UIView *loadingActivityIndicatorView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivityIndicator;
- (IBAction)turnOnNotifications:(id)sender;

- (void)userRegisteredForPushNotification:(NSNotification *)aNotification;
@end

@implementation ActivityViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.notRegisteredForRemoteNotificationsView.alpha = 0;
    self.noRemoteNotificationsView.alpha = 0;
    UIImageView *navImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 40)];
    navImageView.contentMode = UIViewContentModeScaleAspectFit;
    navImageView.image = [UIImage imageNamed:@"logo"];
    
    self.navigationItem.titleView = navImageView;
    
    NSInteger remoteNotificationType = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (remoteNotificationType == 0) {
        // Show give us notifications
        self.notRegisteredForRemoteNotificationsView.alpha = 1;
        self.noRemoteNotificationsView.alpha = 0;
        self.notificationsTableView.alpha = 0;
    }else{
        self.notRegisteredForRemoteNotificationsView.alpha = 0;
        self.noRemoteNotificationsView.alpha = 0;
        self.notificationsTableView.alpha = 1;
        [self.notificationsTableView reloadData];
       [self fetchNotificationsFromProvider];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRegisteredForPushNotification:) name:kUserRegisterForPushNotification object:nil];
    
    DLog(@"Notification enabled for app - %u",[[UIApplication sharedApplication] enabledRemoteNotificationTypes]);
}


-(void)viewDidAppear:(BOOL)animated
{
    NSInteger remoteNotificationType = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    if (remoteNotificationType == 0) {
        // Show give us notifications
        self.notRegisteredForRemoteNotificationsView.alpha = 1;
        self.noRemoteNotificationsView.alpha = 0;
        self.notificationsTableView.alpha = 0;
    }else{
        self.notRegisteredForRemoteNotificationsView.alpha = 0;
        self.noRemoteNotificationsView.alpha = 0;
        self.notificationsTableView.alpha = 1;
        [self.notificationsTableView reloadData];
        [self fetchNotificationsFromProvider];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Remote Notifications methods
-(void)fetchNotificationsFromProvider
{
    //DLog(@"Fetch notifications");
    
    [AppHelper showLoadingDataView:self.loadingActivityIndicatorView indicator:self.loadingActivityIndicator flag:YES];
    
    [[LSPushProviderAPIClient sharedInstance] GET:@"fetchnotifications"
                                       parameters:@{@"userId": [AppHelper userID]}
                                          success:^(NSURLSessionDataTask *task, id responseObject){
                
                [AppHelper showLoadingDataView:self.loadingActivityIndicatorView indicator:self.loadingActivityIndicator flag:NO];
                
                NSArray *attachments = [responseObject objectForKey:@"notifs"];
                                              self.notifications = attachments;
                if ([attachments count] > 0) {
                    DLog(@"Notifications - %@",attachments);
                                                  
                    NSString *badgeValue = ([[responseObject[@"badgeCount"] stringValue] isEqualToString:@"0"]) ? nil : [responseObject[@"badgeCount"] stringValue] ;
                   
                      [self.tabBarController.tabBar.items[2] setBadgeValue:badgeValue];
                      self.noRemoteNotificationsView.alpha = 0;
                      self.notificationsTableView.alpha = 1;
                      [self.notificationsTableView reloadData];
                    
                    }else{
                        DLog(@"There are no notifications for this user");
                        self.noRemoteNotificationsView.alpha = 1;
                        self.notificationsTableView.alpha = 0;
                    }
                                              
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    DLog(@"Error - %@",error);
                    self.noRemoteNotificationsView.alpha = 1;
                    self.notificationsTableView.alpha = 0;
            }];
}




#pragma mark - TableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;   //@"ACTIVITY_CELL";
    
    UITableViewCell *cell = nil;
    
    if ([self.notifications[indexPath.row][@"readStatus"] isEqualToString:@"unread"]){
       cellIdentifier = @"ACTIVITY_CELL_COLORED";
    }else{
        cellIdentifier = @"ACTIVITY_CELL";
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = self.notifications[indexPath.row][@"payload"];
    
    return cell;
}



#pragma mark - TableView Delegate methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.backgroundView.backgroundColor = [UIColor whiteColor];
    selectedCell.backgroundColor = [UIColor whiteColor];
    
    NSString *spotID = self.notifications[indexPath.row][@"spotId"];
    
    if ([self.notifications[indexPath.row][@"readStatus"] isEqualToString:@"unread"]) {
        
        [[LSPushProviderAPIClient sharedInstance] POST:@"updatenotification" parameters:@{@"userId": [AppHelper userID], @"notificationId" : self.notifications[indexPath.row][@"id"]} success:^(NSURLSessionDataTask *task, id responseObject){
            DLog(@"Response - %@",responseObject);
            NSString *badgeValue = ([[responseObject[@"badgeCount"] stringValue] isEqualToString:@"0"]) ? nil : [responseObject[@"badgeCount"] stringValue] ;
            
            [self.tabBarController.tabBar.items[2] setBadgeValue:badgeValue];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Error - %@",error);
        }];

    }
    
    [self performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM" sender:spotID];

}


#pragma mark - Segue Methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([segue.identifier isEqualToString:@"ACTIVITY_PHOTO_STREAM"]) {
        PhotoStreamViewController *pvc = segue.destinationViewController;
        pvc.spotID = sender;
    }
}


- (IBAction)turnOnNotifications:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserDidSignUpNotification object:nil];
}


-(void)userRegisteredForPushNotification:(NSNotification *)aNotification
{
    self.notRegisteredForRemoteNotificationsView.alpha = 0;
    self.noRemoteNotificationsView.alpha = 0;
    self.notificationsTableView.alpha = 1;
    [self.notificationsTableView reloadData];
    [self fetchNotificationsFromProvider];
}

@end
