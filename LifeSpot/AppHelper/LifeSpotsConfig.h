//
//  LifeSpotsConfig.h
//  LifeSpot
//
//  Created by Kwame Nelson on 1/6/14.
//  Copyright (c) 2014 Eric Hackman. All rights reserved.
//

#ifndef LifeSpot_LifeSpotsConfig_h
#define LifeSpot_LifeSpotsConfig_h

//#define LifespotsAPIBaseURLString @"http://10.1.0.62:9000/"


#pragma mark - Foursquare constants

#define FOURSQUARE_BASE_URL_STRING @"https://api.foursquare.com/v2/"
#define FOURSQUARE_API_CLIENT_ID @"IMWAXAYYFEMCEUYIGPZXTLDLW4E0TTACE1PBPPWXRMXYO2SK"
#define FOURSQUARE_API_CLIENT_SECRET @"XXS0KRVUXMLJW5PVQJS24H25I2NT2EFURTLMGLZEZSVQXLFU"

// Keys for userdefaults
#define FIRST_NAME @"firstName"
#define LAST_NAME @"lastName"
#define USER_NAME @"userName"
#define EMAIL @"email"
#define SESSION @"session"
#define API_TOKEN @"token"
#define FACEBOOK_ID @"FBID"
#define NUMBER_OF_ALBUMS @"numberOfAlbums"
#define PROFILE_PHOTO_URL @"profilePictureURL"
#define SPOT_ID @"spotId"



// Other
#define PASSWORD @"pass"
#define STATUS   @"status"
#define ALRIGHT  @"ok"
#define FBLOGIN @"FBLogin"
#define NATIVE_LOGIN @"loggedIn"
#define FACEBOOK_LOGIN @"1"
#define NATIVE @"0"
#define IS_SPOT_ACTIVE @"ACTIVE_ALBUM"
#define ACTIVE_SPOT_ID @"ActiveSpotId"
#define SPOT_IS_ACTIVE_MESSAGE @"SPOT_ACTIVE_MESSAGE"
#define SPOT_BACKGROUND_IMAGE_URL @"SPOT_BACKGROUND_IMAGE_URL"
#define SPOT_CREATOR_IMAGE_URL @"creatorPhoto"
#define SPOT_FIRSTMEMBER_IMAGE_URL @"firstMemberPhoto"
#define SPOT_SECONDMEMBER_IMAGE_URL @"secondMemberPhoto"
#define SPOT_THIRDMEMBER_IMAGE_URL @"thirddMemberPhoto"
#define SPOT_CREATOR_NAME @"creatorName"
#define SPOT_NAME @"spotName"
#define NUMBER_OF_SPOT_MEMBERS @"members"
#define NUMBER_OF_PHOTOS @"photos"
#define kS3_BASE_URL @"https://s3.amazonaws.com/com.intruptiv.mypyx-photos/"
#define DECREMENT @"0"
#define INCREMENT @"1"
#define PUSH_PROVIDER_BASE_URL @"http://54.201.18.151/"
#define REGISTER_DEVICE_TOKEN_URL @"http://54.201.18.151/reporttoken"
#define ARC4RANDOM_MAX  0x100000000
#define sANYONE @"ANYONE"
#define sONLY_MEMBERS @"ONLY_MEMBERS"
#define kSUBANOTIFICATION_ERROR @"kNotficationError"
#define kSUBANOTIFICATION_SUCCESS @"kNotficationSuccess"
#define kNoInternetAccessNotification @"kNoInternetNotification"


// Notifications
#define kFBInfoWasFetchedNotification @"FbUserInfoNotification"
#define kUserInfoWasFetchedNotification @"UserInfoNotification"
#define kCameraActiveWasTappedNotification @"CameraWasTappedNotification"
#define kUserDidLoadPersonalSpotsNotification @"PersonalSpotDidLoadNotification"
#define kUserDidSignUpNotification @"kUserDidLogInNotification"
#define kUserUpdatedProfileInfoNotification @"kUserInfoWasUpdated"
#define kPhotoGalleryTappedAtIndexNotification @"kPhotoGalleryTapped"
#define kPhotoCellTappedAtIndexNotification @"kPhotoCellTapped"
#define kUserReloadStreamNotification @"kUserJoinedSpot"

#endif
