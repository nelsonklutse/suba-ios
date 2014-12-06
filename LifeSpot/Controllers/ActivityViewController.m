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
#import "NotificationCell.h"
#import "User.h"

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
    
    DLog();
    DLog(@"System ios version: %f",[[[UIDevice currentDevice] systemVersion] floatValue]);
    if (IS_OS_8_OR_LATER){
        //DLog(@"We're using ios 8");
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // We register differently on iOS 8
        
        UIUserNotificationSettings *notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        //DLog(@"User Notification Settings: %u",[notificationSettings types]);
        if (notificationSettings == 0) {
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
    
    } else  if(IS_OS_7_OR_BEFORE){
        DLog(@"We're using ios 7");
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
    


    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userRegisteredForPushNotification:) name:kUserRegisterForPushNotification object:nil];
    
    
}


-(void)viewDidAppear:(BOOL)animated
{
    /*NSInteger remoteNotificationType = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
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
    }*/

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Remote Notifications methods
-(void)fetchNotificationsFromProvider
{
    DLog(@"Fetch notifications");
    
    [AppHelper showLoadingDataView:self.loadingActivityIndicatorView indicator:self.loadingActivityIndicator flag:YES];
    
    [[SubaAPIClient sharedInstance] GET:@"user/notifications/fetch"
                                       parameters:@{@"userId": [AppHelper userID]}
                                          success:^(NSURLSessionDataTask *task, id responseObject){
                
                [AppHelper showLoadingDataView:self.loadingActivityIndicatorView indicator:self.loadingActivityIndicator flag:NO];
                
                NSArray *attachments = [responseObject objectForKey:@"notifications"];
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
    return 80;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;
    NotificationCell *cell = nil;
    
    if ([self.notifications[indexPath.row][@"status"] isEqualToString:@"UNREAD"]){
       cellIdentifier = @"ACTIVITY_CELL_COLORED";
    }else{
        cellIdentifier = @"ACTIVITY_CELL";
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.senderImageView.clipsToBounds = YES;
    cell.senderImageView.layer.cornerRadius = 25;
    cell.senderImageView.layer.borderWidth = 1;
    cell.senderImageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    //cell.senderImageView.image = nil;
    cell.notificationMessage.text = self.notifications[indexPath.row][@"message"];
    [cell.notificationMessage sizeToFit];
    
    DLog(@"Notification Message: %@",cell.notificationMessage.text);
    
    if (self.notifications[indexPath.row][@"senderPhoto"]){
        NSString *senderPhoto = self.notifications[indexPath.row][@"senderPhoto"];
        NSURL *senderPhotoURL = [NSURL URLWithString:senderPhoto];
        
        [cell.senderImageView setImageWithURL:senderPhotoURL
                       placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    }else{
        [cell.senderImageView setImage:[UIImage imageNamed:@"anonymousUser"]];
    }

    return cell;
}


#pragma mark - TableView Delegate methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NotificationCell *selectedCell = (NotificationCell *)[tableView cellForRowAtIndexPath:indexPath];
    selectedCell.backgroundView.backgroundColor = [UIColor whiteColor];
    selectedCell.backgroundColor = [UIColor whiteColor];
    
    NSString *streamID = self.notifications[indexPath.row][@"streamId"];
    
    if ([self.notifications[indexPath.row][@"status"] isEqualToString:@"UNREAD"]) {
        
        [[SubaAPIClient sharedInstance] POST:@"user/notification/update"
                                  parameters:@{@"userId": [AppHelper userID], @"notificationId" : self.notifications[indexPath.row][@"id"]}
                                     success:^(NSURLSessionDataTask *task, id responseObject){
              
            NSString *badgeValue = ([[responseObject[@"badgeCount"] stringValue] isEqualToString:@"0"]) ? nil : [responseObject[@"badgeCount"] stringValue] ;
            
            [self.tabBarController.tabBar.items[2] setBadgeValue:badgeValue];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            DLog(@"Error - %@",error);
        }];

    }
    
    [self performSegueWithIdentifier:@"ACTIVITY_PHOTO_STREAM" sender:@{@"streamId":streamID}];
 
}


#pragma mark - Segue Methods
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    if ([segue.identifier isEqualToString:@"ACTIVITY_PHOTO_STREAM"]){
        PhotoStreamViewController *pvc = segue.destinationViewController;
        
        if(sender[@"photoURL"] && !sender[@"doodledPhotoURL"]){
            pvc.photoToShow = sender[@"photoURL"];
            pvc.shouldShowPhoto = YES;
            
        }else if(sender[@"doodledPhotoURL"]){
            pvc.photoToShow = sender[@"photoURL"];
            pvc.shouldShowDoodle = YES;
        }
        
        pvc.spotID = sender[@"streamId"];
    }
}


- (IBAction)turnOnNotifications:(id)sender
{
    //DLog(@"Turning on notifications by firing kUserDidSignUpNotification");
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



-(void)joinSpot:(NSString *)spotCode data:(NSDictionary *)data completion:(GeneralCompletion)completionBlock
{
    [[User currentlyActiveUser] joinSpotCompletionCode:spotCode completion:^(id results, NSError *error){
        if (!error) {
            [Flurry logEvent:@"Join_Stream_With_Code"];
            completionBlock(results,nil);
        }else{
            completionBlock(nil,error);
        }
    }];
}





@end
