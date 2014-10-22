//
//  GetTwitterTimeline.h
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

typedef enum{
    RKGetTwiiterTimeLineErrorType_Success=0,
    RKGetTwiiterTimeLineErrorType_AccountError=1,
    RKGetTwiiterTimeLineErrorType_RequestError=2,
    RKGetTwiiterTimeLineErrorType_DataIsNull=3,
    RKGetTwiiterTimeLineErrorType_TwitterServerError=4
}RKGetTwitterTimeLineError;


@class RKGetTwitterTimeline;

@protocol RKGetTwitterDelegate;

@interface RKGetTwitterTimeline : NSObject

@property(nonatomic,weak)id<RKGetTwitterDelegate>delegate;


-(NSDictionary*)getTwitterTimeLineFromLocalNSUserDeafalults;
-(NSDictionary*)getTwitterTimeLineNewly;
-(NSMutableArray*)getTwitterTimeLineNewlyFromServer;
-(NSMutableDictionary*)getTwitterProfileImage:(NSArray*)timeLineArray;
-(NSMutableDictionary*)convert_NSData_to_UIImage__TWITTER:(NSMutableDictionary*)userImageDic;
-(NSMutableArray*)twitterDataRemove:(NSMutableArray*)soretedArray;

@end
