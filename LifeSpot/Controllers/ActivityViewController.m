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
@property (weak, nonatomic) IBOutlet UITableView *notificationsTableView;
@end

@implementation ActivityViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self fetchNotificationsFromProvider];
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
    [[LSPushProviderAPIClient sharedInstance] GET:@"fetchnotifications" parameters:@{@"userId": [AppHelper userID]}
                                          success:^(NSURLSessionDataTask *task, id responseObject){
                                              
                NSArray *attachments = [responseObject objectForKey:@"notifs"];
                                              self.notifications = attachments;
                if ([attachments count] > 0) {
                    DLog(@"Notifications - %@",attachments);
                                                  
                    NSString *badgeValue = ([[responseObject[@"badgeCount"] stringValue] isEqualToString:@"0"]) ? nil : [responseObject[@"badgeCount"] stringValue] ;
                    
                    [self.tabBarController.tabBar.items[2] setBadgeValue:badgeValue];
                    [self.notificationsTableView reloadData];
                    }else{
                        DLog(@"There are no notifications for this user");
                    }
                                              
                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    DLog(@"Error - %@",error);
            }];
}




#pragma mark - TableView Datasource
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = nil;//@"ACTIVITY_CELL";
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


@end
