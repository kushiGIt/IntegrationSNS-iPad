//
//  ViewController.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/09/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "ViewController.h"
#define TIME_LANE_TABLEVIEW_TEXTVIEW_VIEWTAG 1
#define TIME_LINE_TABLEVIEW_IMAGEVIEW_VIEWTAG 2
#define TIME_LINE_TABLEVIEW_LABEL_VIEWTAG 3

@interface ViewController (){
    NSString*max_id;
    IBOutlet UITableView*mytableview;
    NSUserDefaults*defaults;
    UIRefreshControl *_refreshControl;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Set UserDefaults
    defaults=[NSUserDefaults standardUserDefaults];
    
    //Cheak Network
    Reachability *reachablity = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachablity currentReachabilityStatus];
    
    if (status==NotReachable) {
        
        NSLog(@"IOS is not connected to the Internet.");
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"ネットワークエラー" description:@"ネットワークに接続しないと更新できません。" type:TWMessageBarMessageTypeError duration:10.0f callback:^{
            
            NSLog(@"Message bar tapped.");
            [[TWMessageBarManager sharedInstance] hideAllAnimated:YES];
            
        }];
    
    }else{
        
        [self getTwitterAndFacebookTimeLineFromNSUserDefaults];
        
    }
    
//    NSLog(@"%s",[[[self getTwitterTimeLineNewly]objectForKey:@"ERROR"]boolValue] ? "YES":"NO");
    
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - TableView methods
/*- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return textArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[mytableview dequeueReusableCellWithIdentifier:@"Cell_type=TWITTER"];
    
    UITextView*textView=(UITextView*)[cell viewWithTag:TIME_LANE_TABLEVIEW_TEXTVIEW_VIEWTAG];
    textView.text=[NSString stringWithFormat:@"%@",textArray[indexPath.row]];
    
    UIImageView*imageView=(UIImageView*)[cell viewWithTag:TIME_LINE_TABLEVIEW_IMAGEVIEW_VIEWTAG];
    imageView.image=[imageDictionary objectForKey:iconArray[indexPath.row]];
    
    UILabel*label=(UILabel*)[cell viewWithTag:TIME_LINE_TABLEVIEW_LABEL_VIEWTAG];
    label.text=[NSString stringWithFormat:@"%@",dateArray[indexPath.row]];
    
    return cell;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >=textArray.count) {
        NSLog(@"Need reload (use max_id)");
    }
}*/
#pragma mark - get timeline
-(void)getTwitterAndFacebookTimeLine{
    //[[[self getTwitterTimeLineNewly] objectForKey:@"ERROR"]boolValue]
    NSDictionary*gotTimeLineDic=[[NSDictionary alloc]initWithDictionary:[self getTwitterTimeLineNewly]];
    
    if ([[gotTimeLineDic objectForKey:@"ERROR"]boolValue]==NO) {
        
    }else{
        
       NSDictionary*gotTwitterUserProfileImage=[[NSDictionary alloc]initWithDictionary:[self getTwitterProfileImage:gotTimeLineDic.mutableCopy].copy];
    
    }
    
}
-(void)getTwitterAndFacebookTimeLineFromNSUserDefaults{
    
    NSDictionary*twitterTimeLineDic=[[NSDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"TWITTER_TIME-LINE_DATA"]];
    NSDictionary*twitterUserProfileImage=[[NSDictionary alloc]initWithDictionary:[self getTwitterProfileImage:twitterTimeLineDic.mutableCopy].copy];
    NSLog(@"%@",twitterTimeLineDic);

}
#pragma mark Get facebook timeline
-(void)getFaceBookTimeLine{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    NSDictionary*readOnlyOptions=@{ ACFacebookAppIdKey : @"1695130440712382",ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,ACFacebookPermissionsKey:@[@"email"]};
    [accountStore requestAccessToAccountsWithType:accountType options:readOnlyOptions completion:^(BOOL granted, NSError *accountsError){
        if (granted) {
            NSArray *facebookAccounts = [accountStore accountsWithAccountType:accountType];
            if (facebookAccounts.count>0) {
                ACAccount *facebookAccount = [facebookAccounts lastObject];
                //Get AccessToken
                ACAccountCredential *facebookCredential = [facebookAccount credential];
                NSString *accessToken = [facebookCredential oauthToken];
                //Set GraphApi
                NSURL*url=[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/home?access_token=%@&limit=300",accessToken]];
                //Get NewsFeed
                NSError*getNewsfeedError;
                NSData*getNewsFeedJSONData=[NSData dataWithContentsOfURL:url options:NSDataReadingMapped error:&getNewsfeedError];
                if (getNewsfeedError) {
                    NSLog(@"%@",getNewsfeedError);
                }else{
                    NSLog(@"Completion of receiving NewsFeed data. Byte=%lu byte.",(unsigned long)getNewsFeedJSONData.length);
                }
                //Conversion
                NSError *jsonError;
                NSArray *newsfeed = [NSJSONSerialization JSONObjectWithData:getNewsFeedJSONData options:NSJSONReadingMutableLeaves error:&jsonError];
                if (jsonError) {
                    NSLog(@"%@",jsonError);
                }else{
                    NSLog(@"Conversion JSONData to Array.");
                }
                //                NSLog(@"%@",[[newsfeed valueForKey:@"data"]firstObject]);
                for (int i; i<[[newsfeed valueForKey:@"data"]count];i++) {
                    NSLog(@"============================Post-%d-Data============================",i);
                    //Who created
                    NSLog(@"Create by %@",[NSString stringWithFormat:@"%@",[[[newsfeed valueForKey:@"data"]valueForKey:@"from"]valueForKey:@"name"][i]]);
                    //What is main_messege
                    NSLog(@"Main_Messege=%@",[NSString stringWithFormat:@"%@",[[newsfeed valueForKey:@"data"]valueForKey:@"message"][i]]);
                    //when is the messege created
                    NSString*Original_ISO_8601_Date=[NSString stringWithFormat:@"%@",[[newsfeed valueForKey:@"data"]valueForKey:@"created_time"][i]];
                    NSDate* date_converted;
                    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                    date_converted = [formatter dateFromString:Original_ISO_8601_Date];
                    NSLog(@"convert results=%@",date_converted);
                    //How many is this messege like_count
                    if ([[[[[newsfeed valueForKey:@"data"]valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i]isEqual:[NSNull null]]==YES) {
                        NSLog(@"Not any likes");
                    }else{
                        NSLog(@"Likes_Count=%lu",(unsigned long)[[[[[newsfeed valueForKey:@"data"]valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i]count]);
                    }
                }

            }else{
                [self getFacebookTimeLineErrorAlert:accountsError];
            }
        }else{
            [self getFacebookTimeLineErrorAlert:accountsError];
        }
    }];
}
-(void)getFacebookTimeLineErrorAlert:(NSError*)error{
    if (error) {
        NSLog(@"%s,%@",__func__,error);
    }else{
        NSLog(@"========Facebook account is error========");
    }
    MODropAlertView *alert =[[MODropAlertView alloc]initDropAlertWithTitle:@"Facebook Account" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
    alert.delegate=self;
    [alert show];
}

#pragma mark - Get Twitter timeline
-(NSDictionary*)getTwitterTimeLineNewly{
    __block NSMutableArray*responsedArray=[[NSMutableArray alloc]initWithArray:[self getTwitterTimeLineNewlyFromServer]];
    __block NSDictionary*timelineDic;
    __block MODropAlertView *alert;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        if (responsedArray[0]==[NSNull null]) {
            
            dispatch_async(mainQueue, ^{
                
                if ([responsedArray[1]isEqualToString:@"RESPONSED_DATA_IS_NULL"]) {
                    
                    NSLog(@"=====DATA_ERROR=====");
                    
                }else if ([responsedArray[1]isEqualToString:@"NOT_ANY_RESPONSED_DATA"]){
                    
                    NSLog(@"=====HTTP-RESPONSE_ERRROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"サーバからの応答がありません。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }else if ([responsedArray[1]isEqualToString:@"ACCOUNT_ERROR"]){
                    
                    NSLog(@"=====ACCOUNT_ERROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Twitterアカウント" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                }else{
                    
                    NSLog(@"=====UNKNOWN_ERROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"予期しないエラーです。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }

                
            });
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"ERROR", nil];
            
            dispatch_semaphore_signal(seamphone);
            
        }else{
            timelineDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"TWITTER_TIME-LINE_DATA"]];
            NSMutableArray *textArray=[[NSMutableArray alloc]initWithArray:[timelineDic objectForKey:@"TWITTER_TEXT"]];
            NSMutableArray *nameArray=[[NSMutableArray alloc]initWithArray:[timelineDic objectForKey:@"TWITTER_USER_NAME"]];
            NSMutableArray *iconArray=[[NSMutableArray alloc]initWithArray:[timelineDic objectForKey:@"TWITTER_USER_ICON"]];
            NSMutableArray *dateArray=[[NSMutableArray alloc]initWithArray:[timelineDic objectForKey:@"TWITTER_POST_DATE"]];

            
            dispatch_semaphore_t pigeonholeObjectWait=dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                
                for (NSDictionary *tweet in responsedArray) {
                    
                    [textArray addObject:[tweet objectForKey:@"text"]];
                    
                    NSDictionary *user = tweet[@"user"];
                    [nameArray addObject:user[@"screen_name"]];
                    [iconArray addObject:user[@"profile_image_url"]];
                    
                    //TwiietrDate→NSDate Convert
                    NSDateFormatter* inFormat = [[NSDateFormatter alloc] init];
                    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                    [inFormat setLocale:locale];
                    [inFormat setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
                    NSString*original_Twitter_Date=[NSString stringWithFormat:@"%@",tweet[@"created_at"]];
                    NSDate *date =[inFormat dateFromString:original_Twitter_Date];
                    
                    NSDateComponents *comps = [[NSDateComponents alloc]init];
                    NSCalendar *calendar = [NSCalendar currentCalendar];
                    comps.hour=9;
                    date=[calendar dateByAddingComponents:comps toDate:date options:0];
                    [dateArray addObject:date];
                
                }
                
                
                dispatch_semaphore_signal(pigeonholeObjectWait);
            
            });
            
            dispatch_semaphore_wait(pigeonholeObjectWait, DISPATCH_TIME_FOREVER);
            
            NSString*since_id=[NSString stringWithFormat:@"%@",[[responsedArray valueForKey:@"id_str"]firstObject]];
            NSLog(@"got since_id=%@",since_id);
            [defaults setObject:since_id forKey:@"TWITTER_SINCE_ID"];
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:textArray,@"TWITTER_TEXT",nameArray,@"TWITTER_USER_NAME",iconArray,@"TWITTER_USER_ICON",dateArray,@"TWITTER_POST_DATE",[NSNumber numberWithBool:NO],@"ERROR",nil];
            [defaults setObject:timelineDic forKey:@"TWITTER_TIME-LINE_DATA"];
            
            dispatch_semaphore_signal(seamphone);

        }
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    return timelineDic;
}
-(NSMutableArray*)getTwitterTimeLineNewlyFromServer{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    __block NSMutableArray*timeLineArray;
    
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted,NSError *accountsError){
            if (granted==YES) {
                
                NSArray*accounts=[accountStore accountsWithAccountType:accountType];
                
                if (accounts!=nil&&accounts.count!=0) {
                    
                    ACAccount *twAccount = accounts[0];
                    
                    //set url
                    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                    
                    //set parameters
                    __block NSDictionary *parametersDic=[[NSDictionary alloc]init];
                    
                    if ([defaults stringForKey:@"TWITTER_SINCE_ID"].length==0) {
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200"};
                        NSLog(@"Parameter=%@",parametersDic);
                        
                    }else{
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200",@"since_id": [defaults stringForKey:@"TWITTER_SINCE_ID"]};
                        NSLog(@"Parameter=%@",parametersDic);
                        
                    }
                    
                    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                    request.account = twAccount;
                    
                    [request performRequestWithHandler:^(NSData*responseData,NSHTTPURLResponse*urlResponse,NSError*error){
                        
                        if (urlResponse) {
                            NSError *jsonError;
                            NSLog(@"Completion of receiving Twitter timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                            
                            NSMutableArray*responseArray=[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                            
                            if (jsonError) {
                                
                                NSLog(@"%s,%@",__func__,jsonError);
                                
                            }
                            
                            if (responseArray.count==0) {
                                
                                NSLog(@"ResponseData is NULL");
                                timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],@"RESPONSED_DATA_IS_NULL", nil];
                                dispatch_semaphore_signal(seamphone);
                                
                            }else{
                                
                                timeLineArray=[[NSMutableArray alloc]initWithArray:responseArray];
                                dispatch_semaphore_signal(seamphone);
                            
                            }
                            
                        }else{
                            
                            timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],@"NOT_ANY_RESPONSED_DATA", nil];
                            dispatch_semaphore_signal(seamphone);
                            
                        }
                        
                    }];
                    
                    
                }else{
                    
                    timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],@"ACCOUNT_ERROR", nil];
                    dispatch_semaphore_signal(seamphone);
                    
                }
                
            }else{
                
                timeLineArray=[[NSMutableArray alloc]initWithObjects:[NSNull null],@"ACCOUNT_ERROR", nil];
                dispatch_semaphore_signal(seamphone);
                
                
            }
            
        }];
    
    });
    
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    return timeLineArray;

}
#pragma mark get user orofile image and convert
-(NSMutableDictionary*)getTwitterProfileImage:(NSMutableDictionary*)timeLineDic{
    __block NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
    __block NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"]];
    
    //Get data from URL
    dispatch_semaphore_t seamphone_GetDataWait_=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            
            NSArray*iconURL_Array=[[NSArray alloc]initWithArray:[timeLineDic objectForKey:@"TWITTER_USER_ICON"]];
            
            for (NSString*imageURL in iconURL_Array) {
                
                if ([userImageDic objectForKey:imageURL]==nil) {
                    
                    NSData*imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
                    NSLog(@"Get image data. Data size is %ld",imageData.length);
                    [userImageDic setObject:imageData forKey:imageURL];
                    
                }else{
                    
                }
            }
            
            [defaults setObject:userImageDic forKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"];
            [defaults synchronize];
            
            dispatch_semaphore_signal(seamphone_GetDataWait_);
        });
    });
    
    dispatch_semaphore_wait(seamphone_GetDataWait_, DISPATCH_TIME_FOREVER);
    
    //Get Image from data
    dispatch_semaphore_t seamphone_ConvertWait_=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
            dic=[self convert_NSData_to_UIImage:userImageDic];
            
            dispatch_semaphore_signal(seamphone_ConvertWait_);
    
    });
    dispatch_semaphore_wait(seamphone_ConvertWait_, DISPATCH_TIME_FOREVER);
    
    return dic;
}
-(NSMutableDictionary*)convert_NSData_to_UIImage:(NSMutableDictionary*)userImageDic{
    
    __block NSMutableDictionary*imageDictionary=[[NSMutableDictionary alloc]init];
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
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

#pragma mark - UIAlertViewDelegate
-(void)alertViewPressButton:(MODropAlertView *)alertView buttonType:(DropAlertButtonType)buttonType{
    NSLog(@"%s",__func__);
    
    switch (buttonType) {
        
        case DropAlertButtonOK:{
            
            NSURL*url=[NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url];
            break;
            
        }default:
           
            NSLog(@"%s",__func__);
            break;
            
    }

}
/*
 dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
 dispatch_async(queue, ^{
 
 });
 
 dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
 dispatch_semaphore_signal(seamphone);
 });
 dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
 
 dispatch_queue_t mainQueue = dispatch_get_main_queue();
 dispatch_async(mainQueue, ^{
  });
 */
@end
