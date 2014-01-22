//
//  Authenticate.h
//  Pixelfly
//
//  Created by Kwame Nelson on 8/26/13.
//  Copyright (c) 2013 Intruptiv. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^UserAuthenticatedCompletion) (id results,NSError *error);
typedef void (^UserNameCheckerCompletion) (id results,NSError *error);
typedef void (^UserLoggedInCompletion) (id results,NSError *error);
typedef void (^NotificationCompletion) ();

@interface AppHelper : NSObject

+ (void)createUserAccount:(NSDictionary *)user WithType:(NSString *)type completion:(UserAuthenticatedCompletion)completionBlock;

+ (void)checkUserName:(NSString *)userName completionBlock:(UserNameCheckerCompletion)completionBlock;

+ (void)loginUserWithEmailOrUserName:(NSString *)emailOrUserName AndPassword:(NSString *)password completionBlock:(UserLoggedInCompletion)completionBlock;


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

+(void)checkForLocation:(CLLocationManager *)locationManager delegate:(id)vc;

+ (void)showLoadingDataView:(UIView *)view indicator:(UIActivityIndicatorView *)indicator flag:(BOOL)flag;


@end
