//
//  GetTwitterTimeline.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/10/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "GetTwitterTimeline.h"

@implementation RKGetTwitterTimeline{
    NSUserDefaults*defaults;
}

#pragma mark - data remove

-(NSMutableArray*)twitterDataRemove:(NSMutableArray*)soretedArray{
    
    
    dispatch_semaphore_t semaphone=dispatch_semaphore_create(0);
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        NSLog(@"=====REMOVE_TWIITER_TIMELINE_DATA_RESULTS=====");
        
        if (soretedArray.count<=200) {
            
            NSLog(@"No need for data erasure.");
            
        }else{
            
            NSUInteger arrayIndex=soretedArray.count-1;
            NSUInteger location=200;
            NSUInteger length=arrayIndex-location+1;
            
            NSRange range=NSMakeRange(location, length);
            
            [soretedArray removeObjectsInRange:range];
            
            NSDictionary *toSaveDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"ERROR",soretedArray,@"TWITTER_DATA",nil];
            NSData*data=[NSKeyedArchiver archivedDataWithRootObject:toSaveDic];
            defaults=[NSUserDefaults standardUserDefaults];
            [defaults setObject:data forKey:@"TWITTER_TIME-LINE_DATA"];
            [defaults synchronize];
            
            NSLog(@"The size of the data after erasing.==> %ld byte",(unsigned long)data.length);
            NSLog(@"befor=%lu after=%ld",arrayIndex+1,(unsigned long)soretedArray.count);
            
        }
        
        NSLog(@"======================END======================");
        
        dispatch_semaphore_signal(semaphone);
        
    });
    
    dispatch_semaphore_wait(semaphone,DISPATCH_TIME_FOREVER);
    
    return soretedArray;
}

#pragma mark - Get Twitter timeline

-(NSDictionary*)getTwitterTimeLineFromLocalNSUserDeafalults{
    defaults=[NSUserDefaults standardUserDefaults];
    NSData*defalultsData=[NSData dataWithData:[defaults dataForKey:@"TWITTER_TIME-LINE_DATA"]];
    NSLog(@"Got twitter timeline data from NSUserDeafaults. Byte=%ldbyte",(unsigned long)defalultsData.length);
    NSDictionary*defaultsDic=[NSKeyedUnarchiver unarchiveObjectWithData:defalultsData];
    return defaultsDic;
}

-(NSDictionary*)getTwitterTimeLineNewly{
    
    NSLog(@"=================TWITTER_RESULTS==================");
    NSLog(@"Start get twitter timeline....");
    
    __block NSMutableArray*responsedArray=[[NSMutableArray alloc]initWithArray:[self getTwitterTimeLineNewlyFromServer]];
    __block NSDictionary*timelineDic;
    
    NSLog(@"timeline=%@",responsedArray);
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        if (responsedArray[0]==[NSNull null]) {
            
            
            NSError*twitterError=responsedArray[1];
            
            if (twitterError.code==102 || twitterError.code==103) {
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             twitterError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetTwiiterTimeLineErrorType_AccountError],@"RKGetTimeLineErrorType",
                             nil];
                
            }else if (twitterError.code==101){
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             twitterError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetTwiiterTimeLineErrorType_RequestError],@"RKGetTimeLineErrorType",
                             nil];
                
            }else if (twitterError.code==100){
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             twitterError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetTwiiterTimeLineErrorType_DataIsNull],@"RKGetTimeLineErrorType",
                             nil];
                
            }else{
                
                timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],@"ERROR",
                             twitterError,@"ERROR_MESSEGE_CODE",
                             [NSNumber numberWithInt:RKGetTwiiterTimeLineErrorType_TwitterServerError],@"RKGetTimeLineErrorType",
                             nil];
                
            }
            NSLog(@"Twitter convert....Failured");
            
            dispatch_semaphore_signal(seamphone);
            
        }else{
            
            NSMutableArray*array=[[NSMutableArray alloc]initWithArray:[[self getTwitterTimeLineFromLocalNSUserDeafalults]objectForKey:@"TWITTER_DATA"]];
            
            dispatch_semaphore_t convertWait=dispatch_semaphore_create(0);
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                
                for (NSDictionary *tweet in responsedArray) {
                    
                    NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                    
                    NSString*twitterTextStr=[NSString stringWithFormat:@"%@",[tweet objectForKey:@"text"]];
                    [dic setObject:twitterTextStr forKey:@"TEXT"];
                    
                    NSDictionary *user = tweet[@"user"];
                    [dic setObject:user[@"screen_name"] forKey:@"USER_NAME"];
                    [dic setObject:user[@"profile_image_url"] forKey:@"USER_ICON"];
                    
                    //TwiietrDate→NSDate Convert
                    NSDateFormatter* inFormat = [[NSDateFormatter alloc] init];
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                    [inFormat setLocale:locale];
                    [inFormat setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
                    NSString*original_Twitter_Date=[NSString stringWithFormat:@"%@",tweet[@"created_at"]];
                    NSDate *date =[inFormat dateFromString:original_Twitter_Date];
                    
                    //                    NSDateComponents *comps = [[NSDateComponents alloc]init];
                    //                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    //                    comps.hour=9;
                    //                    date=[calendar dateByAddingComponents:comps toDate:date options:0];
                    [dic setObject:date forKey:@"POST_DATE"];
                    
                    [dic setObject:@"TWITTER" forKey:@"TYPE"];
                    
                    [array addObject:dic];
                    
                }
                
                
                dispatch_semaphore_signal(convertWait);
                
            });
            
            dispatch_semaphore_wait(convertWait, DISPATCH_TIME_FOREVER);
            
            defaults=[NSUserDefaults standardUserDefaults];
            
            NSString*since_id=[NSString stringWithFormat:@"%@",[[responsedArray valueForKey:@"id_str"]firstObject]];
            NSLog(@"got since_id result =%@",since_id);
            [defaults setObject:since_id forKey:@"TWITTER_SINCE_ID"];
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"ERROR",array,@"TWITTER_DATA",nil];
            NSData*data=[NSKeyedArchiver archivedDataWithRootObject:timelineDic];
            NSLog(@"App is going to save data. Byte=%ldbyte.",(unsigned long)data.length);
            [defaults setObject:data forKey:@"TWITTER_TIME-LINE_DATA"];
            [defaults synchronize];
            
            dispatch_semaphore_signal(seamphone);
            
            NSLog(@"Twitter convert....Success");
            
        }
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    NSLog(@"=======================END========================");
    
    return timelineDic;
}

-(NSMutableArray*)getTwitterTimeLineNewlyFromServer{
    
    NSLog(@"Start get twitter timeline from server.");
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block NSMutableArray*timeLineArray;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted,NSError *accountsError){
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
            
            if (granted==YES) {
                
                NSArray*accounts=[accountStore accountsWithAccountType:accountType];
                
                if (accounts!=nil&&accounts.count!=0) {
                    
                    ACAccount *twAccount = accounts[0];
                    
                    //set url
                    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                    
                    //set parameters
                    __block NSDictionary *parametersDic=[[NSDictionary alloc]init];
                    
                    defaults=[NSUserDefaults standardUserDefaults];
                    
                    if ([defaults stringForKey:@"TWITTER_SINCE_ID"].length==0) {
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200"};
                        NSLog(@"request parameters don't have since_id");
                        
                    }else{
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200",@"since_id": [defaults stringForKey:@"TWITTER_SINCE_ID"]};
                        NSLog(@"request parameters have since_id");
                        
                    }
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                    request.account = twAccount;
                    
                    [request performRequestWithHandler:^(NSData*responseData,NSHTTPURLResponse*urlResponse,NSError*error){
                        
                        if (error) {
                            NSLog(@"%@",error);
                        }
                        
                        if (urlResponse) {
                            NSError *jsonError;
                            NSLog(@"Completion of receiving Twitter timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                            
                            NSMutableArray*responseArray=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                            
                            if (jsonError) {
                                
                                NSLog(@"%s,%@",__func__,jsonError);
                                
                            }else{
                                
                                if ([[[responseArray valueForKey:@"errors"]valueForKey:@"message"]isEqual:[NSNull null]]) {
                                    
                                    NSLog(@"twitter request...Failured");
                                    NSString*errorCode=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"code"][0]];
                                    NSString*errorMessege=[NSString stringWithFormat:@"%@",[[responseArray valueForKey:@"errors"]valueForKey:@"message"][0]];
                                    NSLog(@"%@",errorCode);
                                    NSLog(@"%@",errorMessege);
                                    
                                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                    [errDetails setValue:errorMessege forKey:NSLocalizedDescriptionKey];
                                    NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:[errorCode integerValue] userInfo:errDetails];
                                    
                                    timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                                    
                                    NSLog(@"twitter results (error)==>%@",timeLineArray);
                                    
                                    
                                }else{
                                    
                                    if (responseArray.count==0) {
                                        
                                        NSLog(@"There is no new data.");
                                        
                                        NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                                        [errDetails setValue:@"There is no new data." forKey:NSLocalizedDescriptionKey];
                                        NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:100 userInfo:errDetails];
                                        
                                        timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                                        
                                        NSLog(@"twitter results (error)==>%@",timeLineArray);
                                        
                                        NSLog(@"twitter request...Failured(Success)");
                                        
                                        dispatch_semaphore_signal(seamphone);
                                        
                                    }else{
                                        
                                        timeLineArray=[[NSMutableArray alloc]initWithArray:responseArray];
                                        NSLog(@"twitter request...Success");
                                        dispatch_semaphore_signal(seamphone);
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }else{
                            
                            NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                            [errDetails setValue:@"There was no response from the server." forKey:NSLocalizedDescriptionKey];
                            NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:101 userInfo:errDetails];
                            
                            timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                            
                            NSLog(@"twitter results (error)==>%@",timeLineArray);
                            
                            NSLog(@"twitter request...Failured");
                            
                            dispatch_semaphore_signal(seamphone);
                            
                        }
                        
                    }];
                    
                    
                }else{
                    
                    NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                    [errDetails setValue:@"App does not have a valid Twitter account." forKey:NSLocalizedDescriptionKey];
                    NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:102 userInfo:errDetails];
                    
                    timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                    
                    NSLog(@"twitter results (error)==>%@",timeLineArray);
                    
                    NSLog(@"twitter request...Failured");
                    
                    dispatch_semaphore_signal(seamphone);
                    
                }
                
            }else{
                
                NSMutableDictionary*errDetails = [NSMutableDictionary dictionary];
                [errDetails setValue:@"The user did not accept the permission of the account of app." forKey:NSLocalizedDescriptionKey];
                NSError*twitterError = [NSError errorWithDomain:@"https://api.twitter.com/1.1/statuses/home_timeline.json" code:103 userInfo:errDetails];
                
                timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],twitterError, nil];
                
                NSLog(@"twitter results (error)==>%@",timeLineArray);
                
                NSLog(@"twitter request...Failured");
                
                dispatch_semaphore_signal(seamphone);
                
            }
            
        });
        
    }];
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    NSLog(@"Completed get twitter timeline from server");
    
    return timeLineArray;
    
}

#pragma mark get user profile image and convert

-(NSMutableDictionary*)getTwitterProfileImage:(NSArray*)timeLineArray{
    
    defaults=[NSUserDefaults standardUserDefaults];
    
    NSLog(@"=====GET_TWITTER_USER-PROFILE_IMEGE_RESULTS=====");
    __block NSMutableDictionary*convertedUserImageDic=[[NSMutableDictionary alloc]init];
    __block NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA__TWITTER"]];
    
    //Get data from URL
    dispatch_semaphore_t seamphone_GetDataWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_sync(queue, ^{
            
            NSMutableArray*iconURL_Array=[[NSMutableArray alloc]init];
            
            for (NSDictionary*dic in timeLineArray) {
                
                [iconURL_Array addObject:[dic objectForKey:@"USER_ICON"]];
                
            }
            
            BOOL isNeed=YES;
            
            for (NSString*imageURL in iconURL_Array) {
                
                if ([userImageDic objectForKey:imageURL]==nil) {
                    
                    NSData*imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
                    NSLog(@"Get twitter user profile image data. Data size is %ld",(unsigned long)imageData.length);
                    [userImageDic setObject:imageData forKey:imageURL];
                    
                }else{
                    
                    isNeed=NO;
                    
                }
            }
            
            if (isNeed==NO) {
                
                NSLog(@"Not needed to get twitter user profile image.");
                
            }
            
            [defaults setObject:userImageDic forKey:@"USER_PROFILE-IMAGE_URL_AND_DATA__TWITTER"];
            [defaults synchronize];
            
            dispatch_semaphore_signal(seamphone_GetDataWait_);
        });
    });
    
    dispatch_semaphore_wait(seamphone_GetDataWait_, DISPATCH_TIME_FOREVER);
    
    //Get Image from data
    dispatch_semaphore_t seamphone_ConvertWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        convertedUserImageDic=[self convert_NSData_to_UIImage__TWITTER:userImageDic];
        
        dispatch_semaphore_signal(seamphone_ConvertWait_);
        
    });
    dispatch_semaphore_wait(seamphone_ConvertWait_, DISPATCH_TIME_FOREVER);
    
    NSLog(@"======================END=======================");
    
    return convertedUserImageDic;
}

-(NSMutableDictionary*)convert_NSData_to_UIImage__TWITTER:(NSMutableDictionary*)userImageDic{
    
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


@end
