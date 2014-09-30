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
    /*NZAlertView *alert = [[NZAlertView alloc] initWithStyle:NZAlertStyleSuccess
                                                      title:@"Alert View"
                                                    message:@"This is an alert example."
                                                   delegate:nil];
    
    [alert setTextAlignment:NSTextAlignmentCenter];
    [alert show];*/
    
    //Set up create "Reload view"
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [mytableview addSubview:_refreshControl];
    
    //Set up NSUserDefaults
    defaults=[NSUserDefaults standardUserDefaults];
    
    //Set up Twitter data
    [self setupTewitterData];
    [self convert_NSData_to_UIImage];
    
    //Set up delegate and dataSource
    mytableview.delegate=self;
    mytableview.dataSource=self;

    //Call Twitter and Facebook "Get Methods"
    [self getTwitterTimeLineNewly];
    //[self twitterDataRemove];
    
}
-(void)setupTewitterData{
    textTweetArray=[[NSMutableArray alloc]initWithArray:[[defaults dictionaryForKey:@"TWITTER_TIMELINE_DATA"]objectForKey:@"TWITTER_TEXT"]];
    nameTweetArray=[[NSMutableArray alloc]initWithArray:[[defaults dictionaryForKey:@"TWITTER_TIMELINE_DATA"] objectForKey:@"TWITTER_USER_NAME"]];
    tweetIconArray=[[NSMutableArray alloc]initWithArray:[[defaults dictionaryForKey:@"TWITTER_TIMELINE_DATA"] objectForKey:@"TWITTER_USER_ICON"]];
    dateArray=[[NSMutableArray alloc]initWithArray:[[defaults dictionaryForKey:@"TWITTER_TIMELINE_DATA"] objectForKey:@"TWITTER_POST_DATE"]];
    since_id=[defaults stringForKey:@"TWITTER_SINCE_ID"];
    max_id=[defaults stringForKey:@"TWITTER_MAX_ID"];
    NSLog(@"since_id = %@",since_id);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Refresh Controller
- (void)refresh
{
    NSLog(@"refresh");
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
        dispatch_semaphore_signal(seamphone);
        [self setupTewitterData];
        [self getTwitterTimeLineNewly];
    });
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    [self endRefresh];
}

- (void)endRefresh
{
    [_refreshControl endRefreshing];
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
#pragma mark - Button methods
#pragma mark BackBt
-(IBAction)backToTop{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Get timeline
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
-(void)getTwitterTimeLineNewly{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *accountsError) {
        if(granted==YES){
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts != nil && [accounts count] != 0) {
                ACAccount *twAccount = accounts[0];
                
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                
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
                
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (urlResponse){
                        NSError *jsonError;
                        NSLog(@"Completion of receiving Twitter timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
                        
                        NSArray *timeline = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                        
//                        [self getTwitterMAX_id:[[timeline valueForKey:@"id_str"]lastObject]];
                        
                        if(timeline){
                            dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                                
                                for (NSDictionary *tweet in timeline) {
                                    
                                    [textTweetArray addObject:[tweet valueForKey:@"text"]];
                                    
                                    NSDictionary *user = tweet[@"user"];
                                    [nameTweetArray addObject:user[@"screen_name"]];
                                    [tweetIconArray addObject:user[@"profile_image_url"]];
                                    
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
                                
                                dispatch_semaphore_signal(seamphone);
                            });
                            dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
                            
                            since_id=[[timeline valueForKey:@"id_str"]firstObject];
                            if (since_id.length==0) {
                                NSLog(@"Could not get since_id");
                            }else{
                                NSLog(@"get since_id = %@",since_id);
                                [defaults setObject:since_id forKey:@"TWITTER_SINCE_ID"];

                            }
                            twitterDataDic=[[NSDictionary alloc]initWithObjectsAndKeys:textTweetArray,@"TWITTER_TEXT",nameTweetArray,@"TWITTER_USER_NAME",tweetIconArray,@"TWITTER_USER_ICON",dateArray,@"TWITTER_POST_DATE", nil];
                            [defaults setObject:twitterDataDic forKey:@"TWITTER_TIMELINE_DATA"];
                            [defaults synchronize];
                            NSLog(@"Complete get Twitter timeline.");
                            
                            [self getTwitterProfileImage];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [mytableview reloadData];
                                NSLog(@"tableview reload data");
                            });
                            
                        }else{
                            NSLog(@"error: %@",jsonError);
                        }
                    }
                }];
                
            }else{
                [self getTwitterTimeLineErrorAlert:accountsError];
            }
        }else{
            [self getTwitterTimeLineErrorAlert:accountsError];
        }
    }];

}
-(void)getTwitterTimeLineOldly{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *accountsError) {
        if(granted==YES){
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts != nil && [accounts count] != 0) {
                ACAccount *twAccount = accounts[0];
                
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                NSDictionary *parametersDic=@{@"include_entities": @"1",@"count": @"200",@"max_id": max_id};//count min:20 max:200
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                request.account = twAccount;
                [self getTwitterTimeLine:request];
            }else{
                [self getTwitterTimeLineErrorAlert:accountsError];
            }
        }else{
            [self getTwitterTimeLineErrorAlert:accountsError];
        }
    }];
}
#pragma mark get timeline
-(void)getTwitterTimeLine:(SLRequest*)request{
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        if (urlResponse){
            NSError *jsonError;
            NSLog(@"Completion of receiving Twitter timeline data. Byte=%lu byte.",(unsigned long)responseData.length);
            //TODO:fix options
            NSArray *timeline = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
            
            [self getTwitterSince_id:[[timeline valueForKey:@"id_str"]firstObject]];
            [self getTwitterMAX_id:[[timeline valueForKey:@"id_str"]lastObject]];
            
            if(timeline){
                dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                    
                    for (NSDictionary *tweet in timeline) {
                        
                        [textTweetArray addObject:[tweet valueForKey:@"text"]];
                        
                        NSDictionary *user = tweet[@"user"];
                        [nameTweetArray addObject:user[@"screen_name"]];
                        [tweetIconArray addObject:user[@"profile_image_url"]];
                        
                        //TwiietrDate→NSDate Convert
                        NSDateFormatter* inFormat = [[NSDateFormatter alloc] init];
                        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                        [inFormat setLocale:locale];
                        [inFormat setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
                        NSString*original_Twitter_Date=[NSString stringWithFormat:@"%@",tweet[@"created_at"]];
                        NSDate *date =[inFormat dateFromString:original_Twitter_Date];
                        [dateArray addObject:date];
                    }
                    dispatch_semaphore_signal(seamphone);
                });
                dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
                
                twitterDataDic=[[NSDictionary alloc]initWithObjectsAndKeys:textTweetArray,@"TWITTER_TEXT",nameTweetArray,@"TWITTER_USER_NAME",tweetIconArray,@"TWITTER_USER_ICON",dateArray,@"TWITTER_POST_DATE", nil];
                [defaults setObject:twitterDataDic forKey:@"TWITTER_TIMELINE_DATA"];
                [defaults synchronize];
                NSLog(@"Complete get Twitter timeline.");
                [self getTwitterProfileImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mytableview reloadData];
                });
            }else{
                NSLog(@"error: %@",jsonError);
            }
        }
    }];
}
-(void)getTwitterSince_id:(NSString*)sinceID{
    NSLog(@"since_id=%@",sinceID);
    [defaults setObject:sinceID forKey:@"TWITTER_SINCE_ID"];
}
-(void)getTwitterMAX_id:(NSString*)maxID{
    NSLog(@"max_id=%@",maxID);
    [defaults setObject:maxID forKey:@"TWITTER_MAX_ID"];
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
#pragma mark remove data
-(void)twitterDataRemove{
//    [self setupTewitterData];
//    [textTweetArray removeObjectsInRange:NSMakeRange(200,textTweetArray.count-200)];
//    [nameTweetArray removeObjectsInRange:NSMakeRange(200,nameTweetArray.count-200)];
//    [tweetIconArray removeObjectsInRange:NSMakeRange(200,tweetIconArray.count-200)];
//    [dateArray removeObjectsInRange:NSMakeRange(200,dateArray.count-200)];
//
//#ifdef DEBUG
//    NSLog(@"textTweetArray=%lu",textTweetArray.count);
//    NSLog(@"nameTweetArray=%lu",nameTweetArray.count);
//    NSLog(@"tweetIconArray=%lu",tweetIconArray.count);
//    NSLog(@"dateArray=%lu",dateArray.count);
//#endif
//    
    twitterDataDic=[[NSDictionary alloc]initWithObjectsAndKeys:textTweetArray,@"TWITTER_TEXT",nameTweetArray,@"TWITTER_USER_NAME",tweetIconArray,@"TWITTER_USER_ICON",dateArray,@"TWITTER_POST_DATE", nil];
    [defaults setObject:twitterDataDic forKey:@"TWITTER_TIMELINE_DATA"];
    [defaults synchronize];
    NSLog(@"Complete delete twitter timeline data.");
}
#pragma mark show alert
-(void)getTwitterTimeLineErrorAlert:(NSError*)error{
    if (error) {
        NSLog(@"%s,%@",__func__,error);
    }else{
        NSLog(@"========Twitter account is error========");
    }
    MODropAlertView *alert =[[MODropAlertView alloc]initDropAlertWithTitle:@"Twitter Account" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
    alert.delegate=self;
    [alert show];
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
