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
    NSMutableArray *textTweetArray;
    NSMutableArray *nameTweetArray;
    NSMutableArray *tweetIconArray;
    NSMutableArray *dateArray;
    NSString*since_id;
    NSString*max_id;
    IBOutlet UITableView*mytableview;
    NSUserDefaults*defaults;
    NSDictionary*twitterDataDic;
    NSMutableDictionary*imageDictionary;
    UIRefreshControl *_refreshControl;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    NSLog(@"%lu",(unsigned long)[self getTwitterTimeLineNewly].count);
    NSLog(@"%@",[self getTwitterTimeLineNewly]);
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - TableView methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return textTweetArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[mytableview dequeueReusableCellWithIdentifier:@"Cell_type=TWITTER"];
    
    UITextView*textView=(UITextView*)[cell viewWithTag:TIME_LANE_TABLEVIEW_TEXTVIEW_VIEWTAG];
    textView.text=[NSString stringWithFormat:@"%@",textTweetArray[indexPath.row]];
    
    UIImageView*imageView=(UIImageView*)[cell viewWithTag:TIME_LINE_TABLEVIEW_IMAGEVIEW_VIEWTAG];
    imageView.image=[imageDictionary objectForKey:tweetIconArray[indexPath.row]];
    
    UILabel*label=(UILabel*)[cell viewWithTag:TIME_LINE_TABLEVIEW_LABEL_VIEWTAG];
    label.text=[NSString stringWithFormat:@"%@",dateArray[indexPath.row]];
    
    return cell;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row >=textTweetArray.count) {
        NSLog(@"Need reload (use max_id)");
    }
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
#pragma mark set Request and alert
-(NSMutableDictionary*)getTwitterTimeLineNewly{
    __block NSMutableArray*responsedArray=[[NSMutableArray alloc]initWithArray:[self getTwitterTimeLineNewlyFromServer]];
    __block NSMutableDictionary*timelineDic;
    __block MODropAlertView *alert;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        if (responsedArray[0]==[NSNull null]) {
            
            dispatch_async(mainQueue, ^{
                
                if ([responsedArray[1]isEqualToString:@"RESPONSED_DATA_IS_NULL"]) {
                    
                    NSLog(@"Not any get twitter data");
                    
                }else if ([responsedArray[1]isEqualToString:@"NOT_ANY_RESPONSED_DATA"]){
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"サーバからの応答がありません。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }else if ([responsedArray[1]isEqualToString:@"ACCOUNT_ERROR"]){
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Twitterアカウント" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                }else{
                    
                    NSLog(@"Unknown error");
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"エラー" description:@"予期しないエラーです。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }

                
            });
            
            timelineDic=[[NSMutableDictionary alloc]init];
            dispatch_semaphore_signal(seamphone);
            
        }else{
            
            dispatch_async(mainQueue, ^{
                
                
                
            });
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted,NSError *accountsError){
            if (granted==YES) {
                
                NSArray*accounts=[accountStore accountsWithAccountType:accountType];
                
                if (accounts!=nil&&accounts.count!=0) {
                    
                    ACAccount *twAccount = accounts[0];
                    
                    //set url
                    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                    
                    //set parameters
                    NSDictionary *parametersDic=[[NSDictionary alloc]init];
                    
                    if ([defaults stringForKey:@"TWITTER_SINCE_ID"].length==0) {
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200"};
                        NSLog(@"Parameter=%@",parametersDic);
                        
                    }else{
                        
                        parametersDic=@{@"include_entities": @"1",@"count": @"200",@"since_id": since_id};
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
-(void)getTwitterProfileImage{
    NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"]];
    tweetIconArray=[[NSMutableArray alloc]initWithArray:[[defaults dictionaryForKey:@"TWITTER_TIMELINE_DATA"] objectForKey:@"TWITTER_USER_ICON"]];
    
    for (NSString*imageURL in tweetIconArray) {
        if ([userImageDic objectForKey:imageURL]==nil) {
            NSData*imageData=[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]];
            NSLog(@"Get image data. Data size is %ld",imageData.length);
            [userImageDic setObject:imageData forKey:imageURL];
        }else{
        }
    }
    [defaults setObject:userImageDic forKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"];
    
    [self convert_NSData_to_UIImage];
}
-(void)convert_NSData_to_UIImage{
    NSMutableDictionary*userImageDic=[[NSMutableDictionary alloc]initWithDictionary:[defaults dictionaryForKey:@"USER_PROFILE-IMAGE_URL_AND_DATA"]];
    NSArray*userImageDic_All_Keys=[userImageDic allKeys];
    
    imageDictionary=[[NSMutableDictionary alloc]init];
    
    for (NSString*key in userImageDic_All_Keys) {
        UIImage*image=[[UIImage alloc]initWithData:[userImageDic objectForKey:key]];
        [imageDictionary setObject:image forKey:key];
    }
    
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
 */
@end
