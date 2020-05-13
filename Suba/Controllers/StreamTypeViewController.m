//
//  StreamTypeViewController.m
//  LifeSpot
//
//  Created by Kwame Nelson on 5/24/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#import "StreamTypeViewController.h"
#import "CreateStreamViewController.h"

@interface StreamTypeViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (strong,nonatomic) NSArray *tableRows;

-(IBAction)unwindToStreamType:(UIStoryboard *)segue;
@end

@implementation StreamTypeViewController

-(IBAction)unwindToStreamType:(UIStoryboard *)segue
{
    //DLog(@"Wants to unwind");
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.tableRows = @[@"Party",@"Group Trip",@"Close Friends",@"Workplace Shenanigans",
                       @"Concert",@"Sports Event",@"Reunion",@"Other Type of Event"];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog();
    self.navigationItem.title = @"Create Stream";
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView Datasource Methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.0f;
}

-(NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableRows count];
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StreamTypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.text = self.tableRows[indexPath.row];
    
    return cell;
}


#pragma mark - TableView Delegate Methods
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.row == ([self.tableRows count] -1)) {
        // It is the last row
        [self performSegueWithIdentifier:@"FirstStreamToCreateStream" sender:@""];
    }else{
        [self performSegueWithIdentifier:@"FirstStreamToCreateStream" sender:cell.textLabel.text];
    }
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"FirstStreamToCreateStream"]) {
        //UINavigationController *nav = segue.destinationViewController;
        CreateStreamViewController *streamVC = segue.destinationViewController;
        if ([sender isKindOfClass:[NSString class]] && [sender isEqualToString:@""]) {
            streamVC.streamName = @"";
        }else{
          streamVC.streamName = [NSString stringWithFormat:@"%@%@ %@",[AppHelper firstName],@"'s",sender];
        }
        
        
    }
}


@end
