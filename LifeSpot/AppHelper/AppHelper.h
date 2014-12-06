//
//  Authenticate.h
//  Pixelfly
//
//  Created by Kwame Nelson on 8/26/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SBRefreshCompletionHandler) (BOOL didReceiveNewStreams);
typedef void (^GeneralCompletion) (id results,NSError *error);
typedef void (^UserNameCheckerCompletion) (id results,NSError *error);
typedef void (^UserLoggedInCompletion) (id results,NSError *error);
typedef void (^NotificationCompletion) ();

@interface AppHelper : NSObject

+ (void)createUserAccount:(NSDictionary *)user WithType:(NSString *)type completion:(GeneralCompletion)completionBlock;

+ (void)checkUserName:(NSString *)userName completionBlock:(UserNameCheckerCompletion)completionBlock;

+ (void)loginUserWithEmailOrUserName:(NSString *)emailOrUserName
                         AndPassword:(NSString *)password
                     completionBlock:(UserLoggedInCompletion)completionBlock;

+ (void)loginUserWithEmailOrUserName:(NSString *)emailOrUserName
                         Password:(NSString *)password
                          AndGuestId:(NSString *)guestId
                     completionBlock:(UserLoggedInCompletion)completionBlock;

+ (NSString *)kindOfDeviceScreen;
+ (void)savePreferences:(NSDictionary *)prefs;
+ (void)saveSessionWithOptions:(NSArray *)options;
+ (NSDictionary *)userPreferences;
+ (BOOL)validateEmail:(NSString *)string;
+ (BOOL)CheckPasswordMinLength:(NSInteger *)length password:(NSString *)string;
+ (NSString *)firstName;
+ (NSString *)lastName;
+ (NSString *)userName;
+ (NSString *)userID;
+ (NSString *)userEmail;
+ (NSString *)facebookID;
+ (NSString *)placesCoachMarkSeen;
+ (NSString *)nearbyCoachMarkSeen;
+ (NSString *)myStreamsCoachMarkSeen;
+ (NSString *)createSpotCoachMarkSeen;
+ (NSString *)exploreCoachMarkSeen;
+ (NSString *)watchLocationCoachMarkSeen;
+ (NSString *)shareStreamCoachMarkSeen;

+ (void)setFacebookID:(NSString *)fid;
+ (void)logout;
+ (NSInteger)numberOfAlbums;
+ (void) updateNumberOfAlbums:(NSInteger)update;
+ (void)setProfilePhotoURL:(NSString *)photoURL;
+ (NSString *)profilePhotoURL;
+ (void)setSpotActive:(NSString *)active message:(NSString *)cameraActiveMessage;
+ (NSString *)spotActive;
+ (NSString *)activeSpotId;
+ (void)setActiveSpotID:(NSString *)spotId;

+ (NSString *)facebookLogin;
+ (void)setFacebookLogin:(NSString *)fbLogin;

+ (NSString *)facebookSession;
+ (void)setFacebookSession:(NSString *)flag;

+ (BOOL)showFirstTimeView;
+ (void)setShowFirstTimeView:(BOOL)flag;

+ (NSString *)userSession;
+ (void)setUserSession:(NSString *)flag;

+ (NSInteger)appSessions;
+ (void)increaseAppSessions;

+ (NSString *)userCountry;
+ (void)setUserCountry:(NSString *)country;

+ (NSString *)userStatus;
+ (void)setUserStatus:(NSString *)status;

+ (NSDictionary *)inviteCodeDetails; 
+ (void)saveInviteCodeDetails:(NSDictionary *)code;

+ (NSString *)hasUserInvited;
+ (void)userHasInvited:(NSString *)flag;

+ (void)setPlacesCoachMark:(NSString *)flag;
+ (void)setNearbyCoachMark:(NSString *)flag;
+ (void)setMyStreamCoachMark:(NSString *)flag;
+ (void)setCreateSpotCoachMark:(NSString *)flag;
+ (void)setExploreCoachMark:(NSString *)flag;
+ (void)setWatchLocation:(NSString *)flag;
+ (void)setShareStreamCoachMark:(NSString *)flag;

+ (void)setFirstName:(NSString *)firstName;
+ (void)setLastName:(NSString *)lastName;
+ (void)setEmail:(NSString *)email;
+ (void)setUserName:(NSString *)userName;
+ (void)showNotificationWithMessage:(NSString *)msg
                               type:(NSString *)type
                   inViewController:(UIViewController *)vc
                    completionBlock:(NotificationCompletion)completion;


#pragma mark - Convenience Methods
+ (void)showAlert:(NSString *)title message:(NSString *)message buttons:(NSArray *)alertButtons delegate:(UIViewController *)delegate;

+(CLLocationManager *)checkForLocation:(CLLocationManager *)locationManager delegate:(id)vc;

+ (void)showLoadingDataView:(UIView *)view indicator:(UIActivityIndicatorView *)indicator flag:(BOOL)flag;
+ (void)showLikeImage:(UIImageView *)imgView imageNamed:(NSString *)imageName;


#pragma mark - General Helpers
+ (void)makeInitialPlaceholderViewWithSize:(NSInteger)labelSize view:(UIView *)contextView name:(NSString *)person;
+ (UIColor *)circleColor;
+ (NSString *)initialStringForPersonString:(NSString *)personString;
+ (void)fillView:(UIView *)view WithImage:(NSString *)imageURL;

+ (NSInteger)numberOfPhotoStreamEntries;
+ (void)increasePhotoStreamEntries;

+ (void)openFBSession:(GeneralCompletion)completion;
+ (void)saveInviteParams:(NSDictionary *)referringParams;
+ (NSMutableArray *)getInviteParams;
+ (BOOL)inviteParamsExists:(NSDictionary *)referringParams;
+ (void)clearPendingInvites:(NSDictionary *)referringParams;
@end





