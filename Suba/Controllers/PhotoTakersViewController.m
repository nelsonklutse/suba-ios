//
//  PhotoTakersViewController.m
//  Suba
//
//  Created by Kwame Nelson on 12/15/14.
//  Copyright (c) 2014 Intruptiv. All rights reserved.
//

#import "PhotoTakersViewController.h"
#import "PhotoTakerCell.h"

@interface PhotoTakersViewController ()<UITableViewDataSource,UITableViewDelegate>
- (IBAction)seeAllPhotos:(id)sender;
@end


@implementation PhotoTakersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return [self.phototakers count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 22;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PhotoTakerCell";
    PhotoTakerCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell.photoTakerImage setImageWithURL:[NSURL URLWithString:self.phototakers[indexPath.row][@"pictureTakerPhoto"]]placeholderImage:[UIImage imageNamed:@"anonymousUser"]];
    cell.photoTakerName.text = self.phototakers[indexPath.row][@"pictureTaker"];
    
    if ([self.phototakers[indexPath.row][@"photos"] integerValue] == 1){
         cell.photosLabel.text = [NSString stringWithFormat:@"%@ photo",self.phototakers[indexPath.row][@"photos"]];
    }else{
         cell.photosLabel.text = [NSString stringWithFormat:@"%@ photos",self.phototakers[indexPath.row][@"photos"]];
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedPhotoTaker = self.phototakers[indexPath.row];
    [self performSegueWithIdentifier:@"PhotoTakerSelectedSegue" sender:nil];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)seeAllPhotos:(id)sender
{
   [self performSegueWithIdentifier:@"PhotoTakerSelectedSegue" sender:nil]; 
}







@end
