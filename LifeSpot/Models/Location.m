//
//  Location.m
//  LifeSpots
//
//  Created by Kwame Nelson on 11/2/13.
//  Copyright (c) 2013 Agana-Nsiire Agana. All rights reserved.
//

#import "Location.h"

@implementation Location

-(id)initWithLat:(NSString *)latitude Lng:(NSString *)longitude{
    if (self = [super init]) {
        self.latitude = latitude;
        self.longitude = longitude;
    }
    
    return self;
}


-(id)initWithLat:(NSString *)latitude Lng:(NSString *)longitude PrettyName:(NSString *)place
{
    self = [self initWithLat:latitude Lng:longitude];
    if (self) {
        self.placeName = place;
    }
    
    return self;
}

-(id)initWithLat:(NSString *)latitude Lng:(NSString *)longitude PlaceName:(NSString *)place Address:(NSString *)address City:(NSString *)city Country:(NSString *)country
{
    self = [self initWithLat:latitude Lng:longitude];
    if (self) {
        self.placeName = place;
        self.address = address;
        self.city = city;
        self.country = country;
    }
    
    return self;
}

+(void)fetchNearbySpots:(NSDictionary *)location completionBlock:(NearbySpotsLoadedCompletionBlock)completion
{
    [[LifespotsAPIClient sharedInstance] GET:@"spot/nearby" parameters:location success:^(NSURLSessionDataTask *task, id responseObject){
        
        completion(responseObject,nil);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error){ 
        
        completion(nil,error);
        
    }];
}


+ (void)searchFourquareWithSearchTerm:(NSString *)searchText completionBlock:(MatchingLocationsCompletionBlock)completion
{
    DLog(@"Search text - %@",searchText);
        NSString *radius = @"800";
    NSString *requestURL = [NSString stringWithFormat:@"%@venues/search",FOURSQUARE_BASE_URL_STRING];
    
    AFHTTPRequestOperationManager *manager =[AFHTTPRequestOperationManager manager];
    [manager GET:requestURL parameters:@{@"client_id": FOURSQUARE_API_CLIENT_ID,
                                         @"client_secret": FOURSQUARE_API_CLIENT_SECRET,
                                         @"near" : searchText,
                                         @"radius" : radius,
                                         @"limit" : @"50",
                                         @"v" : @"20140107"
                                         }
     
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
            // DLog(@"Response - %@",[responseObject debugDescription]);
             // self.locations = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             completion(responseObject,nil);
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             completion(nil,error);
         }];
}


- (void)showBestMatchingFoursquareVenueCriteria:(NSString *)searchType completion:(ExactFoursquareLocationFoundCompletionBlock)completion{
    
    DLog(@"Latitiude - %@\nLongitude - %@",self.latitude,self.longitude);
    NSString *near = [NSString stringWithFormat:@"%@,%@",self.latitude,self.longitude];
    NSString *radius = @"1000";
    
    NSString *requestURL = [NSString stringWithFormat:@"%@venues/search",FOURSQUARE_BASE_URL_STRING];
    
    AFHTTPRequestOperationManager *manager =[AFHTTPRequestOperationManager manager];
    [manager GET:requestURL parameters:@{@"client_id": FOURSQUARE_API_CLIENT_ID,
                                         @"client_secret": FOURSQUARE_API_CLIENT_SECRET,
                                         searchType : near,
                                         @"radius" : radius,
                                         @"limit" : @"50",
                                         @"v" : @"20140107"
                                      }
     
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //DLog(@"Response - %@",[responseObject debugDescription]);
            // self.locations = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             completion(responseObject,nil);
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             completion(nil,error);
         }];

}


-(NSString *)description{
    return
    [NSString stringWithFormat:@"Latitide - %@\nLongitude - %@\nPlace - %@\nAddress - %@\nCity - %@\nCountry - %@",
          self.latitude,self.longitude,self.placeName,self.address,self.city,self.country];
}

@end
