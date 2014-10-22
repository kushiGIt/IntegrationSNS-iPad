//
//  GetFaceBookTimeLine.h
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/21.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import "Reachability.h"
#import "MODropAlertView.h"
#import "TWMessageBarManager.h"
#import "SJNotificationViewController.h"

typedef NS_ENUM(NSInteger, RKGetFacebookTimeLineError){
    RKGetFacebookTimeLineErrorType_AccountError,
    RKGetFacebookTimeLineErrorType_RequestError,
    RKGetFacebookTimeLineErrorType_DataIsNull,
    RKGetFacebookTimeLineErrorType_FacebookServerError
};



@class RKGetFacebookTimeLine;

@protocol RKGetFacebookDelegate;

@interface RKGetFacebookTimeLine : NSObject

@property(nonatomic,weak)id<RKGetFacebookDelegate>delegate;


-(NSDictionary*)getFacebookTimeLineFromLocalNSUserDeafalults;
-(NSDictionary*)getFaceBookTimeLine;
-(NSMutableArray*)getFacebookTimeLineFromServer;
-(NSMutableDictionary*)getFacebookNewsFeedPicture_withImageDic:(NSDictionary*)imageDic;
-(NSMutableDictionary*)getfacebookProfileImage:(NSArray*)timeLineArray;
-(NSMutableDictionary*)convert_NSData_to_UIImage__FACEBOOK:(NSMutableDictionary*)userImageDic;
-(NSDictionary*)searchDuplicationFacebookObject:(NSDictionary*)timelineDic;


@end

