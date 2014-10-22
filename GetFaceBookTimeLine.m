//
//  GetFaceBookTimeLine.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/21.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "GetFaceBookTimeLine.h"
#import "MODropAlertView.h"

@implementation RKGetFacebookTimeLine{
    NSUserDefaults*defaults;
}
#pragma mark - Get facebook timeline
-(NSDictionary*)getFacebookTimeLineFromLocalNSUserDeafalults{
    
    __block NSDictionary*defaultsDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        defaults=[NSUserDefaults standardUserDefaults];
        
        NSData*defalultsData=[NSData dataWithData:[defaults dataForKey:@"FACEBOOK_TIME-LINE_DATA"]];
        NSLog(@"Got facebook timeline data from NSUserDeafaults. Byte=%ldbyte",(unsigned long)defalultsData.length);
        defaultsDic=[NSKeyedUnarchiver unarchiveObjectWithData:defalultsData];
        
        dispatch_semaphore_signal(seamphone);
        
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    return defaultsDic;
    
}
-(NSDictionary*)getFaceBookTimeLine{
    
    NSLog(@"=================FACEBOOK_RESULTS=================");
    NSLog(@"Start get facebook newsfeed....");
    
    __block NSMutableArray*newsfeed=[[NSMutableArray alloc]init];
    __block NSDictionary*timelineDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        newsfeed=[[NSMutableArray alloc]initWithArray:[self getFacebookTimeLineFromServer]];
        
        if (newsfeed[0]==[NSNull null]) {
            
            NSError*facebookError=[newsfeed objectAtIndex:1];
            
            if (facebookError.code==202 || facebookError.code==203) {
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             facebookError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetFacebookTimeLineErrorType_AccountError],@"RKGetTimeLineErrorType",nil];
                
            }else if (facebookError.code==201){
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             facebookError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetFacebookTimeLineErrorType_RequestError],@"RKGetTimeLineErrorType",
                             nil];
            }else if (facebookError.code==200){
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             facebookError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetFacebookTimeLineErrorType_DataIsNull],@"RKGetTimeLineErrorType",
                             nil];

            }else{
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             facebookError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetFacebookTimeLineErrorType_FacebookServerError],@"RKGetTimeLineErrorType",
                             nil];
            
            }
            
            NSLog(@"Facebook convert....Failured");
            
            dispatch_semaphore_signal(seamphone);
            
        }else{
            
            NSMutableArray*array=[[NSMutableArray alloc]initWithArray:[[self getFacebookTimeLineFromLocalNSUserDeafalults] objectForKey:@"FACEBOOK_DATA"]];
            
            
            for (int i=0; i<[newsfeed count]-1;i++) {
                
                NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                
                //user name
                [dic setObject:[[newsfeed valueForKey:@"from"]valueForKey:@"name"][i] forKey:@"USER_NAME"];
                //user id
                [dic setObject:[[newsfeed valueForKey:@"from"]valueForKey:@"id"][i] forKey:@"USER_ID"];
                
                //text data
                [dic setObject:[newsfeed valueForKey:@"message"][i] forKey:@"TEXT"];
                
                //date data
                NSString*Original_ISO_8601_Date=[NSString stringWithFormat:@"%@",[newsfeed valueForKey:@"created_time"][i]];
                NSDate* date_converted;
                NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                date_converted = [formatter dateFromString:Original_ISO_8601_Date];
                [dic setObject:date_converted forKey:@"POST_DATE"];
                NSLog(@"%@",date_converted);
                
                //like data
                if ([[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:[NSNull null] forKey:@"LIKE_DATA"];
                    
                }else{
                    
                    [dic setObject:[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] forKey:@"LIKE_DATA"];
                    
                }
                
                //newsfeed picture
                if ([[newsfeed valueForKey:@"picture"]isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:[NSNull null] forKey:@"PICTURE_DATA"];
                    
                }else{
                    
                    [dic setObject:[newsfeed valueForKey:@"picture"] forKey:@"PICTURE_DATA"];
                    
                }
                
                
                //set type Ex.)facebook,twitter
                [dic setObject:@"FACEBOOK" forKey:@"TYPE"];
                
                [array addObject:dic];
                
            }
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"ERROR",array,@"FACEBOOK_DATA", nil];
            
            NSData*data=[NSKeyedArchiver archivedDataWithRootObject:[self searchDuplicationFacebookObject:timelineDic]];
            
            NSLog(@"App is going to save data. Byte=%ldbyte.",(unsigned long)data.length);
            
            defaults=[NSUserDefaults standardUserDefaults];
            [defaults setObject:data forKey:@"FACEBOOK_TIME-LINE_DATA"];
            [defaults synchronize];
            
            dispatch_semaphore_signal(seamphone);
            
            NSLog(@"Facebook convert....Success");
            
        }
        
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    NSLog(@"=======================END========================");
    
    return timelineDic;
    
}
-(NSMutableArray*)getFacebookTimeLineFromServer{
    
    NSLog(@"Start that get facebook newsfeed from server");
    __block NSMutableArray*timeLineArray;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        
        NSDictionary*readOnlyOptions=@{ ACFacebookAppIdKey : @"1695130440712382",ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,ACFacebookPermissionsKey:@[@"email"]};
        
        
        [accountStore requestAccessToAccountsWithType:accountType options:readOnlyOptions completion:^(BOOL granted, NSError *accountsError){
            
            if (granted==YES) {
                
                NSArray *facebookAccounts = [accountStore accountsWithAccountType:accountType];
                
                if (facebookAccounts!=nil&&facebookAccounts.count!=0) {
                    
                    ACAccount *facebookAccount = [facebookAccounts lastObject];
                    
                    ACAccountCredential *facebookCredential = [facebookAccount credential];
                    NSString *accessToken = [facebookCredential oauthToken];
                    
                    NSURL*url=[NSURL URLWithString:@"https://graph.facebook.com/me/home"];
                    NSDictionary*parametersDic=[[NSDictionary alloc]initWithObjectsAndKeys:accessToken,@"access_token",@300,@"limit",nil];
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                    request.account = facebookAccount;
                    
                    [request performRequestWithHandler:^(NSData*responseData,NSHTTPURLResponse*urlResponse,NSError*error){
                        
                        if (error) {
                            NSLog(@"Facebook error==>%@",error);
                        }
                        
                        if (urlResponse) {
                            
                            NSError *jsonError;
                            NSLog(@"Completion of receiving Facebook timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                            
                            NSMutableArray*responseArray=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                            
                            if (jsonError) {
                                
                                NSLog(@"%s,%@",__func__,jsonError);
                                
                            }else{
                                
                                if ([[[responseArray valueForKey:@"error"]valueForKey:@"message"]isEqual:[NSNull null]]) {
                                    
                                    NSLog(@"facebook request...Failured");
                                    NSString*errorCode=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"code"][0]];
                                    NSString*errorMessege=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"message"][0]];
                                    NSLog(@"%@",errorCode);
                                    NSLog(@"%@",errorMessege);
                                    
                                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                    [errDetails setValue:errorMessege forKey:NSLocalizedDescriptionKey];
                                    NSError*twitterError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:[errorCode integerValue] userInfo:errDetails];
                                    
                                    timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                                    
                                    NSLog(@"facebook results (error)==>%@",timeLineArray);
                                    
                                }else{
                                    
                                    if ([[responseArray valueForKey:@"data"]count]==0) {
                                        
                                        NSLog(@"There is no new data.");
                                        
                                        NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                        [errDetails setValue:@"There is no new data." forKey:NSLocalizedDescriptionKey];
                                        NSError*twitterError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:200 userInfo:errDetails];
                                        
                                        timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                                        
                                        NSLog(@"twitter results (error)==>%@",timeLineArray);
                                        
                                        NSLog(@"twitter request...Failured(Success)");
                                        
                                        dispatch_semaphore_signal(seamphone);
                                        
                                    }else{
                                        
                                        timeLineArray=[[NSMutableArray alloc]initWithArray:[responseArray valueForKey:@"data"]];
                                        NSLog(@"facebook request...Success");
                                        dispatch_semaphore_signal(seamphone);
                                        
                                    }
                                    
                                }
                                
                            }
                            
                            
                        }else{
                            
                            NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                            [errDetails setValue:@"There was no response from the server." forKey:NSLocalizedDescriptionKey];
                            NSError*twitterError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:201 userInfo:errDetails];
                            
                            timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                            
                            NSLog(@"facebook results (error)==>%@",timeLineArray);
                            
                            NSLog(@"facebook request...Failured");
                            
                            dispatch_semaphore_signal(seamphone);
                            
                        }
                        
                    }];
                }else{
                    
                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                    [errDetails setValue:@"App does not have a valid facebook account." forKey:NSLocalizedDescriptionKey];
                    NSError*twitterError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:202 userInfo:errDetails];
                    
                    timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                    
                    NSLog(@"facebook results (error)==>%@",timeLineArray);
                    
                    NSLog(@"facebook request...Failured");
                    
                    dispatch_semaphore_signal(seamphone);
                    
                }
            }else{
                
                NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                [errDetails setValue:@"The user did not accept the permission of the account of app." forKey:NSLocalizedDescriptionKey];
                NSError*twitterError = [NSError errorWithDomain:@"https://graph.facebook.com/me/home" code:203 userInfo:errDetails];
                
                timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                
                NSLog(@"facebook results (error)==>%@",timeLineArray);
                
                NSLog(@"facebook request...Failured");
                
                dispatch_semaphore_signal(seamphone);
                
            }
            
        }];
    });
    
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    NSLog(@"Completed get facebook newsfeed from server");
    
    return timeLineArray;
    
}
#pragma mark get facebook newsfeed picture
#warning I must verify this code....
-(NSMutableDictionary*)getFacebookNewsFeedPicture_withImageDic:(NSDictionary*)imageDic{
    
    NSLog(@"=====GET_FACEBOOK_NEWSFEED_IMEGE_RESULTS=====");
    NSCache*imageCache;
    __block NSMutableDictionary*convertedNewsfeedImage=[[NSMutableDictionary alloc]init];
    __block NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[imageCache objectForKey:@"IMAGE_CACHE"]];
    
    //Get data from URL
    dispatch_semaphore_t seamphone_GetDataWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_sync(queue, ^{
            
            BOOL isNeed=YES;
            
            NSArray*iconURL_Array=[[NSArray alloc]initWithArray:[imageDic objectForKey:@"PICTURE_DATA"]];
            
            for (NSString*urlStr in iconURL_Array) {
                
                if ([userImageDic objectForKey:urlStr]==nil) {
                    
                    NSData*imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",urlStr]]];
                    NSLog(@"Get facebook newsfeed image data. Data size is %ld",(unsigned long)imageData.length);
                    if (imageData.length==0) {
                        
                        NSLog(@"This image data id is incorrect....%@",urlStr);
                        
                    }else{
                        
                        [userImageDic setObject:imageData forKey:urlStr];
                        
                    }
                    
                }else{
                    
                    isNeed=NO;
                    
                }
            }
            
            if (isNeed==NO) {
                NSLog(@"Not needed to get facebook newsfeed image.");
            }
            
            [imageCache setObject:userImageDic forKey:@"IMAGE_CACHE"];
            
            convertedNewsfeedImage=[[NSMutableDictionary alloc]initWithDictionary:[self convert_NSData_to_UIImage__FACEBOOK:userImageDic]];
            
            dispatch_semaphore_signal(seamphone_GetDataWait_);
        });
    });
    NSLog(@"======================END=======================");
    return convertedNewsfeedImage;
}
#pragma mark get facebook user icon and convert
-(NSMutableDictionary*)getfacebookProfileImage:(NSArray*)timeLineArray{
    
    defaults=[NSUserDefaults standardUserDefaults];
    
    NSLog(@"=====GET_FACEBOOK_USER-PROFILE_IMEGE_RESULTS=====");
    __block NSMutableDictionary*convertedUserImageDic=[[NSMutableDictionary alloc]init];
    
    __block NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA__FACEBOOK"]];
    
    //Get data from URL
    dispatch_semaphore_t seamphone_GetDataWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_sync(queue, ^{
            
            NSMutableArray*iconURL_Array=[[NSMutableArray alloc]init];
            
            for (NSDictionary*dic in timeLineArray) {
                
                [iconURL_Array addObject:[dic objectForKey:@"USER_ID"]];
                
            }
            
            int i=0;
            
            for (NSString*user_id in iconURL_Array) {
                
                if ([userImageDic objectForKey:user_id]==nil) {
                    
                    NSData*imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",user_id]]];
                    NSLog(@"Get facebook user profile image data. Data size is %ld",(unsigned long)imageData.length);
                    if (imageData.length==0) {
                        
                        NSLog(@"This image data id is incorrect....%@",user_id);
                        
                    }else{
                        
                        [userImageDic setObject:imageData forKey:user_id];
                        
                    }
                    
                }else{
                    
                    i=1;
                    
                }
            }
            
            if (i==1) {
                NSLog(@"Not needed to get facebook user profile image.");
            }
            
            [defaults setObject:userImageDic forKey:@"USER_PROFILE-IMAGE_URL_AND_DATA__FACEBOOK"];
            [defaults synchronize];
            
            dispatch_semaphore_signal(seamphone_GetDataWait_);
        });
    });
    
    dispatch_semaphore_wait(seamphone_GetDataWait_, DISPATCH_TIME_FOREVER);
    
    //Get Image from data
    dispatch_semaphore_t seamphone_ConvertWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        convertedUserImageDic=[self convert_NSData_to_UIImage__FACEBOOK:userImageDic];
        
        dispatch_semaphore_signal(seamphone_ConvertWait_);
        
    });
    dispatch_semaphore_wait(seamphone_ConvertWait_, DISPATCH_TIME_FOREVER);
    
    NSLog(@"======================END=======================");
    
    return convertedUserImageDic;
}
-(NSMutableDictionary*)convert_NSData_to_UIImage__FACEBOOK:(NSMutableDictionary*)userImageDic{
    
    __block NSMutableDictionary*imageDictionary=[[NSMutableDictionary alloc]init];
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        NSArray*userImageDic_All_Keys=[userImageDic allKeys];
        
        for (NSString*key in userImageDic_All_Keys) {
            
            UIImage*image=[[UIImage alloc]initWithData:[userImageDic objectForKey:key]];
            [imageDictionary setObject:image forKey:key];
            
        }
        
        dispatch_semaphore_signal(seamphone);
        
    });
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    return imageDictionary;
}
#pragma mark Search duplication Facebook object
-(NSDictionary*)searchDuplicationFacebookObject:(NSDictionary*)timelineDic{
    
    __block NSMutableArray*timelineArray=[[NSMutableArray alloc]initWithArray:[timelineDic objectForKey:@"FACEBOOK_DATA"]];
    __block NSMutableDictionary*timelineMutableDic=[[NSMutableDictionary alloc]initWithDictionary:timelineDic.mutableCopy];
    __block NSMutableIndexSet*duplicateIndex=[[NSMutableIndexSet alloc]init];
    __block NSMutableSet*set=[[NSMutableSet alloc]init];
    
    __block int setCountForComparison=0;
    __block int index=0;
    
    dispatch_semaphore_t wait_createNSSet=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        for (NSMutableDictionary*dic in timelineArray) {
            
            [dic removeObjectForKey:@"LIKE_DATA"];
            [dic removeObjectForKey:@"PICTURE_DATA"];
            [dic removeObjectForKey:@"POST_DATE"];
            [set addObject:dic];
            
            index++;
            
            if (setCountForComparison==set.count) {
                
                [duplicateIndex addIndex:index];
                NSLog(@"duplicate index=%d",index);
                
            }else{
                
                setCountForComparison=(int)set.count;
                
            }
            
        }
        
        [timelineArray removeObjectsAtIndexes:duplicateIndex];
        [timelineMutableDic setObject:timelineArray forKey:@"FACEBOOK_DATA"];
        
        dispatch_semaphore_signal(wait_createNSSet);
        
    });
    
    dispatch_semaphore_wait(wait_createNSSet, DISPATCH_TIME_FOREVER);
    
    return timelineMutableDic.copy;
}
@end
