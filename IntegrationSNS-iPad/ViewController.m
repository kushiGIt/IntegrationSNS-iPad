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
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewDidAppear:(BOOL)animated{//recive from server
    [super viewDidAppear:YES];
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
        
        [self getTwitterAndFacebookTimeLine];
        
    }
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
    
    __block NSDictionary*gotFacebookTimeLineDic;
    __block NSDictionary*gotTwitterTimeLineDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        //gotTwitterTimeLineDic=[[NSDictionary alloc]initWithDictionary:[self getTwitterTimeLineNewly]];
        gotFacebookTimeLineDic=[[NSDictionary alloc]initWithDictionary:[self getFaceBookTimeLine]];
        
        dispatch_semaphore_signal(seamphone);
        
    });
    
//    NSMutableArray*array=[[NSMutableArray alloc]init];
//    
//    [array addObject:[gotTwitterTimeLineDic objectForKey:@"TWITTER_DATA"]];
//    [array addObject:[gotFacebookTimeLineDic objectForKey:@"FACEBOOK_DATA"]];
//    
//    NSSortDescriptor *sortDescNumber;
//    sortDescNumber = [[NSSortDescriptor alloc] initWithKey:@"POST_DATE" ascending:YES];
//    
//    NSArray*sortDescArray=[[NSArray alloc]initWithObjects:sortDescNumber, nil];
//    
//    NSArray *sortArray=[array sortedArrayUsingDescriptors:sortDescArray];
//    
//    NSLog(@"%@",sortArray);
}
#pragma mark - Get Twitter timeline
-(NSDictionary*)getTwitterTimeLineFromLocalNSUserDeafalults{
    NSData*defalultsData=[NSData dataWithData:[defaults dataForKey:@"TWITTER_TIME-LINE_DATA"]];
    NSLog(@"Got twitter timeline data from NSUserDeafaults. Byte=%ldbyte",defalultsData.length);
    NSDictionary*defaultsDic=[NSKeyedUnarchiver unarchiveObjectWithData:defalultsData];
    return defaultsDic;
}

-(NSDictionary*)getTwitterTimeLineNewly{
    
    __block NSMutableArray*responsedArray=[[NSMutableArray alloc]initWithArray:[self getTwitterTimeLineNewlyFromServer]];
    __block NSDictionary*timelineDic;
    //__block MODropAlertView *alert;
    //dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        if (responsedArray[0]==[NSNull null]) {
            
            NSError*twitterError=responsedArray[1];
            
            /*dispatch_async(mainQueue, ^{
                
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

                
            });*/
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"ERROR", nil];
            NSLog(@"Twitter convert Failured");
            
            dispatch_semaphore_signal(seamphone);
            
        }else{
            
            NSMutableArray*array=[[NSMutableArray alloc]initWithArray:[[self getTwitterTimeLineFromLocalNSUserDeafalults]objectForKey:@"TWITTER_DATA"]];

            dispatch_semaphore_t convertWait=dispatch_semaphore_create(0);
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                
                for (NSDictionary *tweet in responsedArray) {
                    
                    NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                    
                    NSString*twitterTextStr=[NSString stringWithFormat:@"%@",[tweet objectForKey:@"text"]];
                    [dic setObject:twitterTextStr forKey:@"TWITTER_TEXT"];
                    
                    NSDictionary *user = tweet[@"user"];
                    [dic setObject:user[@"screen_name"] forKey:@"TWITTER_USER_NAME"];
                    [dic setObject:user[@"profile_image_url"] forKey:@"TWITTER_USER_ICON"];
                    
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
                    [dic setObject:date forKey:@"POST_DATE"];
                    
                    [array addObject:dic];
                
                }
                
                
                dispatch_semaphore_signal(convertWait);
            
            });
            
            dispatch_semaphore_wait(convertWait, DISPATCH_TIME_FOREVER);
            
            NSString*since_id=[NSString stringWithFormat:@"%@",[[responsedArray valueForKey:@"id_str"]firstObject]];
            NSLog(@"got since_id=%@",since_id);
            [defaults setObject:since_id forKey:@"TWITTER_SINCE_ID"];
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"ERROR",array,@"TWITTER_DATA",nil];
            NSData*data=[NSKeyedArchiver archivedDataWithRootObject:timelineDic];
            [defaults setObject:data forKey:@"TWITTER_TIME-LINE_DATA"];
            
            dispatch_semaphore_signal(seamphone);
            
            NSLog(@"Twitter convert Success");

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
    
    return timeLineArray;
    
}
#pragma mark get user profile image and convert
-(NSMutableDictionary*)getTwitterProfileImage:(NSMutableDictionary*)timeLineDic{
    __block NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
    __block NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"]];
    
    //Get data from URL
    dispatch_semaphore_t seamphone_GetDataWait_=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_sync(queue, ^{
            
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
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
            dic=[self convert_NSData_to_UIImage:userImageDic];
            
            dispatch_semaphore_signal(seamphone_ConvertWait_);
    
    });
    dispatch_semaphore_wait(seamphone_ConvertWait_, DISPATCH_TIME_FOREVER);
    
    return dic;
}
-(NSMutableDictionary*)convert_NSData_to_UIImage:(NSMutableDictionary*)userImageDic{
    
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
#pragma mark - Get facebook timeline
-(NSDictionary*)getFacebookTimeLineFromLocalNSUserDeafalults{
    
    __block NSDictionary*defaultsDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        NSData*defalultsData=[NSData dataWithData:[defaults dataForKey:@"FACEBOOK_TIME-LINE_DATA"]];
        NSLog(@"Got facebook timeline data from NSUserDeafaults. Byte=%ldbyte",defalultsData.length);
        defaultsDic=[NSKeyedUnarchiver unarchiveObjectWithData:defalultsData];
        
        dispatch_semaphore_signal(seamphone);
    
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    return defaultsDic;

}

-(NSDictionary*)getFaceBookTimeLine{
    
    __block NSMutableArray*newsfeed=[[NSMutableArray alloc]init];
    __block NSDictionary*timelineDic;
    //__block MODropAlertView *alert;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        newsfeed=[[NSMutableArray alloc]initWithArray:[self getFacebookTimeLineFromServer]];
        
        if (newsfeed[0]==[NSNull null]) {
            
            /*dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                
                if ([newsfeed[1]isEqualToString:@"RESPONSED_DATA_IS_NULL"]) {
                    
                    NSLog(@"=====DATA_ERROR=====");
                    
                }else if ([newsfeed[1]isEqualToString:@"NOT_ANY_RESPONSED_DATA"]){
                    
                    NSLog(@"=====HTTP-RESPONSE_ERRROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"Facebookのサーバにアクセスしましたが応答がありませんでした。時間が経ってから、もう一度アクセスしてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }else if ([newsfeed[1]isEqualToString:@"ACCOUNT_ERROR"]){
                    
                    NSLog(@"=====ACCOUNT_ERROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Facebookアカウント" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                }else{
                    
                    NSLog(@"=====UNKNOWN_ERROR=====");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"予期しないエラーです。時間を置いてからリトライしてみてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }
            
            });*/
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"ERROR", nil];
            
            dispatch_semaphore_signal(seamphone);
            
        }else{
            
            NSMutableArray*array=[[NSMutableArray alloc]initWithArray:[[self getFacebookTimeLineFromLocalNSUserDeafalults] objectForKey:@"FACEBOOK_DATA"]];
            
            for (int i=0; i<[newsfeed count]-1;i++) {
                
                NSMutableDictionary*dic=[[NSMutableDictionary alloc]init];
                
                [dic setObject:[[newsfeed valueForKey:@"from"]valueForKey:@"name"][i] forKey:@"FACEBOOK_USER_NAME"];
                
                [dic setObject:[newsfeed valueForKey:@"message"][i] forKey:@"FACEBOOK_TEXT"];
                
                NSString*Original_ISO_8601_Date=[NSString stringWithFormat:@"%@",[newsfeed valueForKey:@"created_time"][i]];
                NSDate* date_converted;
                NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                date_converted = [formatter dateFromString:Original_ISO_8601_Date];
                [dic setObject:date_converted forKey:@"POST_DATE"];
                
                if ([[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:@"NOT_ANY_LIKE" forKey:@"FACEBOOK_LIKE_DATA"];
                    
                }else{
                    
                    [dic setObject:[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] forKey:@"FACEBOOK_LIKE_DATA"];
                    
                }
                
                [array addObject:dic];
                
            }
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:NO],@"ERROR",array,@"FACEBOOK_DATA", nil];
            NSData*data=[NSKeyedArchiver archivedDataWithRootObject:[self searchDuplicationFacebookObject:timelineDic]];
            NSLog(@"App is going to save data. Byte=%ldbyte.",data.length);
            
            [defaults setObject:data forKey:@"FACEBOOK_TIME-LINE_DATA"];
            
            dispatch_semaphore_signal(seamphone);
            
        }
        
    });
    
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);

    return timelineDic;
    
}

-(NSMutableArray*)getFacebookTimeLineFromServer{
    
    NSLog(@"Start that get facebook timeline from server");
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
    
    return timeLineArray;
    
}
#pragma mark - Search duplication Facebook object
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
            
            [dic removeObjectForKey:@"FACEBOOK_LIKE_DATA"];
            [set addObject:dic];
            
            index++;
            
            if (setCountForComparison==set.count) {
                
                [duplicateIndex addIndex:index-1];
                
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
 dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
 dispatch_semaphore_signal(seamphone);
 });
 dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
 
 dispatch_queue_t mainQueue = dispatch_get_main_queue();
 dispatch_async(mainQueue, ^{
  });
 */
@end
