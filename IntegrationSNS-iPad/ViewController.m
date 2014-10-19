//
//  ViewController.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/09/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "ViewController.h"
#define USER_IMAGE_VIEW_TAG 1
#define USER_NAME_VIEW_TAG 2
#define CREATED_TIME_LABEL_TAG 3
#define USER_TEXT_DATA 4
#define IMAGE_VIEW_TAG 5

@interface ViewController (){
    IBOutlet UITableView*mytableview;
    NSUserDefaults*defaults;
    NSCache*imageCache;
    NSArray*timelineArray__TABLE__;
    NSMutableDictionary*userImageData__TABLE__;
    UITapGestureRecognizer *tapGesture;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Set UserDefaults
    defaults=[NSUserDefaults standardUserDefaults];
    
    tapGesture =[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(view_Tapped)];
    
    mytableview.delegate=self;
    mytableview.dataSource=self;
    NSLog(@"%@",mytableview.delegate);
    NSLog(@"%@",mytableview.dataSource);
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"********************REMOVE********************");
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}
-(void)viewDidAppear:(BOOL)animated{//recive from server
    [super viewDidAppear:YES];
    
    //Cheak Network
    Reachability *reachablity = [Reachability reachabilityForInternetConnection];
    NetworkStatus status = [reachablity currentReachabilityStatus];
    
    if (status==NotReachable) {
        
        NSLog(@"IOS is not connected to the Internet.");
        [[TWMessageBarManager sharedInstance] showMessageWithTitle:@"ネットワークエラー" description:@"ネットワークに接続しないと更新できません。" type:TWMessageBarMessageTypeError duration:5.0f callback:^{
            
            NSLog(@"Message bar tapped.");
            [[TWMessageBarManager sharedInstance] hideAllAnimated:YES];
            
        }];
        
    }else{
        
        [self getTwitterAndFacebookTimeLine];
        
    }
}

#pragma mark - UITapGestureRecognizer methods
-(void)view_Tapped{
    NSLog(@"Tapped");
}


#pragma mark - TableView methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    return 1;

}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSLog(@"timeline.count=%lu",(unsigned long)timelineArray__TABLE__.count);
    return timelineArray__TABLE__.count;

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell=[mytableview dequeueReusableCellWithIdentifier:@"MyCell"];
    
    UIImageView*userImage=(UIImageView*)[cell viewWithTag:USER_IMAGE_VIEW_TAG];
    UILabel*userNameTextView=(UILabel*)[cell viewWithTag:USER_NAME_VIEW_TAG];
    UILabel*created_time=(UILabel*)[cell viewWithTag:CREATED_TIME_LABEL_TAG];
    UITextView*userTextData=(UITextView*)[cell viewWithTag:USER_TEXT_DATA];
    UIImageView*imageData=(UIImageView*)[cell viewWithTag:IMAGE_VIEW_TAG];
    
    NSDictionary*timelineDic=[[NSDictionary alloc]initWithDictionary:[timelineArray__TABLE__ objectAtIndex:indexPath.row]];
    
    
    if ([[timelineDic objectForKey:@"TYPE"]isEqualToString:@"FACEBOOK"]) {
        
        UIImage*profileImage=[userImageData__TABLE__ objectForKey:[timelineDic objectForKey:@"USER_ID"]];
        userImage.image=profileImage;
        
        userNameTextView.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"USER_NAME"]];
        
        NSString*dateStr=[self dateToString:[timelineDic objectForKey:@"POST_DATE"] formatString:@"yyyy-MM-dd"];
        created_time.text=dateStr;
        
        userTextData.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"TEXT"]];
        
        [imageData addGestureRecognizer:tapGesture];
    
    }else if ([[timelineDic objectForKey:@"TYPE"]isEqualToString:@"TWITTER"]){
        
        UIImage*profileImage=[userImageData__TABLE__ objectForKey:[timelineDic objectForKey:@"USER_ICON"]];
        userImage.image=profileImage;
        
        userNameTextView.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"USER_NAME"]];
        
        NSString*dateStr=[self dateToString:[timelineDic objectForKey:@"POST_DATE"] formatString:@"yyyy-MM-dd"];
        created_time.text=dateStr;
        
        userTextData.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"TEXT"]];
        
        [imageData addGestureRecognizer:tapGesture];
    
    }else{
        
        NSLog(@"Not found this type...%@",[timelineDic valueForKey:@"TYPE"]);
    
    }
    
    return cell;
}
#pragma mark - convert date to string
-(NSString*)dateToString:(NSDate *)baseDate formatString:(NSString *)formatString{
    
    NSDate *now = [NSDate date];
    
    NSTimeInterval differenceTimeInterval=[now timeIntervalSinceDate:baseDate];
    NSInteger originTime=(NSInteger)differenceTimeInterval;
    
    NSInteger seconds = originTime % 60;
    NSInteger minutes = (originTime / 60) % 60;
    NSInteger hours = (originTime / 3600);
    NSInteger day=hours/24;
    
    NSString*intervalTimeStr;
    
    if (day>=1) {
        
        intervalTimeStr=[NSString stringWithFormat:@"%ld日前",day];
    
    }else if (hours>=1){
        
        intervalTimeStr=[NSString stringWithFormat:@"%ld時間前",hours];
    
    }else if (minutes>=1) {
        
        intervalTimeStr=[NSString stringWithFormat:@"%ld分前",minutes];
    
    }else if (seconds>=1){
        
        intervalTimeStr=[NSString stringWithFormat:@"%ld秒前",seconds];
    
    }
    
    return intervalTimeStr;
}
#pragma mark - prepare reload tableview data
-(void)prepareForReloadTableViewDataForGetNewlyFromServer:(NSArray*)timelineArray facebookProfileImage:(NSMutableDictionary*)facebookProfileImageDic twitterProfileImage:(NSMutableDictionary*)twitterProfileImageDic reloadData:(Boolean)isReload{
    
    NSLog(@"*****PREPARE_RELOAD-DATA_GET_FROM_SERVER*****");
    
    switch (isReload) {
        case true:{
            
            dispatch_semaphore_t semaphone =dispatch_semaphore_create(0);
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                
                dispatch_semaphore_signal(semaphone);
                
                
                NSLog(@"Start reload tableview....YES");
                
                //Set timeline
                timelineArray__TABLE__=[[NSArray alloc]initWithArray:timelineArray];
                
                //Set user image
                userImageData__TABLE__=[[NSMutableDictionary alloc]init];
                [userImageData__TABLE__ addEntriesFromDictionary:facebookProfileImageDic];
                [userImageData__TABLE__ addEntriesFromDictionary:twitterProfileImageDic];
                
            });
            
            dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
            
            NSLog(@"Reload....");
            [mytableview reloadData];
            
            break;
            
        }case false:{
            
            NSLog(@"Start reload tableview....NO");
            
            break;
        }}
    
}

-(void)prepareForReloadTableViewDataForGetFromNSUserDefaults:(NSArray*)timelineArray facebookProfileImage:(NSMutableDictionary*)facebookProfileImageDic twitterProfileImage:(NSMutableDictionary*)twitterProfileImageDic reloadData:(Boolean)isReload{
    
    NSLog(@"*****PREPARE_RELOAD-DATA_GET_FROM_NSUERDEFAULTS*****");
    
    switch (isReload) {
        case true:{
            
            dispatch_semaphore_t semaphone =dispatch_semaphore_create(0);
            dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
                
                dispatch_semaphore_signal(semaphone);
                
                
                NSLog(@"Start reload tableview....YES");
                
                //Set timeline
                timelineArray__TABLE__=[[NSArray alloc]initWithArray:timelineArray];
                
                //Set user image
                userImageData__TABLE__=[[NSMutableDictionary alloc]init];
                [userImageData__TABLE__ addEntriesFromDictionary:facebookProfileImageDic];
                [userImageData__TABLE__ addEntriesFromDictionary:twitterProfileImageDic];
                
            });
            
            dispatch_semaphore_wait(semaphone, DISPATCH_TIME_FOREVER);
            
            
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                
                [mytableview reloadData];
                
            });
            
            break;
            
        }case false:{
            
            NSLog(@"Start reload tableview....NO");
            
            break;
        }}
}

#pragma mark - get timeline

-(void)getTwitterAndFacebookTimeLine{
    
    __block NSDictionary*gotFacebookTimeLineDic;
    __block NSDictionary*gotTwitterTimeLineDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        gotTwitterTimeLineDic=[[NSDictionary alloc]initWithDictionary:[self getTwitterTimeLineNewly]];
        
        gotFacebookTimeLineDic=[[NSDictionary alloc]initWithDictionary:[self getFaceBookTimeLine]];
        
        dispatch_semaphore_signal(seamphone);
        
    });
    dispatch_semaphore_wait(seamphone, DISPATCH_TIME_FOREVER);
    
    
    __block NSMutableArray*array=[[NSMutableArray alloc]init];
    __block NSMutableArray*twitterArray=[[NSMutableArray alloc]init];
    __block NSMutableArray*facebookArray=[[NSMutableArray alloc]init];
    
    dispatch_semaphore_t wait_Sort=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if ([[gotFacebookTimeLineDic objectForKey:@"ERROR"]boolValue]==NO) {
            
            [facebookArray addObjectsFromArray:[gotFacebookTimeLineDic objectForKey:@"FACEBOOK_DATA"]];
        
        }else{
            
            NSError*facebookError=[gotFacebookTimeLineDic objectForKey:@"ERROR_MESSEGE_CODE"];
            if (facebookError.code==200 || facebookError.code==201) {
                
                [facebookArray addObjectsFromArray:[[self getFacebookTimeLineFromLocalNSUserDeafalults]objectForKey:@"FACEBOOK_DATA"]];
            
            }
        
        }
        //add
        [array addObjectsFromArray:facebookArray];
        
        if ([[gotTwitterTimeLineDic objectForKey:@"ERROR"]boolValue]==NO) {
            
            [twitterArray addObjectsFromArray:[gotTwitterTimeLineDic objectForKey:@"TWITTER_DATA"]];
        
        }else{
            
            NSError*twitterError=[gotTwitterTimeLineDic objectForKey:@"ERROR_MESSEGE_CODE"];
            
            if (twitterError.code==100 || twitterError.code==101) {
                
                [twitterArray addObjectsFromArray:[[self getTwitterTimeLineFromLocalNSUserDeafalults]objectForKey:@"TWITTER_DATA"]];
            
            }
            
        }
        
        //for get twitter profile image
        NSMutableDictionary*twitterProfileImageDic=[[NSMutableDictionary alloc]initWithDictionary:[self getTwitterProfileImage:twitterArray]];
        //for get facebook profile image
        NSMutableDictionary*facebookProfileImageDic=[[NSMutableDictionary alloc]initWithDictionary:[self getfacebookProfileImage:facebookArray]];
        
        //for twitter data remove
        NSSortDescriptor *sortDescNumber_TWITTER;
        sortDescNumber_TWITTER=[[NSSortDescriptor alloc] initWithKey:@"POST_DATE" ascending:NO];
        NSArray*sortDescArray_TWITTER=[[NSArray alloc]initWithObjects:sortDescNumber_TWITTER, nil];
        NSArray*twitterSortedArray=[twitterArray sortedArrayUsingDescriptors:sortDescArray_TWITTER];
        NSArray*twitterRemovedArray=[[NSArray alloc]initWithArray:[self twitterDataRemove:twitterSortedArray.mutableCopy].copy];
        
        [array addObjectsFromArray:twitterRemovedArray];
        
        
        //twiiter and facebook sort
        NSSortDescriptor *sortDescNumber_TWITTER_AND_FACEBOOK;
        sortDescNumber_TWITTER_AND_FACEBOOK = [[NSSortDescriptor alloc] initWithKey:@"POST_DATE" ascending:NO];
        NSArray*sortDescArray_TWITTER_AND_FACEBOOK=[[NSArray alloc]initWithObjects:sortDescNumber_TWITTER_AND_FACEBOOK, nil];
        NSArray *twitterAndFacebookSortedArray=[array sortedArrayUsingDescriptors:sortDescArray_TWITTER_AND_FACEBOOK];
        
        NSLog(@"Recive data from server.....finish!");
        
        dispatch_semaphore_signal(wait_Sort);
        
        //reload data
        [self prepareForReloadTableViewDataForGetNewlyFromServer:twitterAndFacebookSortedArray facebookProfileImage:facebookProfileImageDic twitterProfileImage:twitterProfileImageDic reloadData:true];
    
    });
    
    dispatch_semaphore_wait(wait_Sort, DISPATCH_TIME_FOREVER);
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
    __block MODropAlertView *alert;
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    NSLog(@"timeline=%@",responsedArray);
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
        if (responsedArray[0]==[NSNull null]) {
            
            NSLog(@"Stert twitter alert view.");
            
            __block NSError*twitterError=responsedArray[1];
            
            dispatch_async(mainQueue, ^{
                
                if ([twitterError code]==(102|103)) {
                    
                    //account error
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Twitterアカウントエラー" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                
                }else if ([twitterError code]==101){
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"リクエストエラー" description:@"サーバからの応答がありません。時間を置いてから試してみてください。" okButtonTitle:@"OK"];
                    [alert show];
                
                }else if ([twitterError code]==100){
                    
                    SJNotificationViewController*_notificationController = [[SJNotificationViewController alloc] initWithNibName:@"SJNotificationViewController" bundle:nil];
                    [_notificationController setParentView:self.view];
                    [_notificationController setTapTarget:self selector:nil];                   
                    [_notificationController setNotificationLevel:SJNotificationLevelMessage];
                    [_notificationController setNotificationPosition:SJNotificationPositionBottom];
                    [_notificationController setNotificationTitle:@"新しいツイートはありません。"];
                    [_notificationController showFor:5];
                
                }else{
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:[NSString stringWithFormat:@"エラー%ld",(long)twitterError.code] description:twitterError.localizedDescription okButtonTitle:@"OK"];
                    [alert show];
                    
                }

                
            });
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"ERROR",twitterError,@"ERROR_MESSEGE_CODE",nil];
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

#pragma mark - Get facebook timeline

-(NSDictionary*)getFacebookTimeLineFromLocalNSUserDeafalults{
    
    __block NSDictionary*defaultsDic;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        
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
    __block MODropAlertView *alert;
    
    dispatch_semaphore_t seamphone=dispatch_semaphore_create(0);
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        newsfeed=[[NSMutableArray alloc]initWithArray:[self getFacebookTimeLineFromServer]];
        
        if (newsfeed[0]==[NSNull null]) {
            
            NSLog(@"Stert twitter alert view.");
            
            NSError*facebookError=[newsfeed objectAtIndex:1];
            
            dispatch_queue_t mainQueue = dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                
                if ([facebookError code]==(202|203)) {
                    
                    //account error
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Facebookアカウントエラー" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                }else if ([facebookError code]==201){
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"リクエストエラー" description:@"サーバからの応答がありません。時間を置いてから試してみてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                }else if ([facebookError code]==200){
                    
                    SJNotificationViewController*_notificationController = [[SJNotificationViewController alloc] initWithNibName:@"SJNotificationViewController" bundle:nil];
                    [_notificationController setParentView:self.view];
                    [_notificationController setTapTarget:self selector:nil];
                    [_notificationController setNotificationLevel:SJNotificationLevelMessage];
                    [_notificationController setNotificationPosition:SJNotificationPositionBottom];
                    [_notificationController setNotificationTitle:@"新しい投稿はありません。"];
                    [_notificationController show];
                    
                }else{
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:[NSString stringWithFormat:@"エラー%ld",(long)facebookError.code] description:facebookError.localizedDescription okButtonTitle:@"OK"];
                    [alert show];
                    
                }
                
            });
            
            timelineDic=[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"ERROR",facebookError,@"ERROR_MESSEGE_CODE", nil];
            
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
                
                //like data
                if ([[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:@"NOT_ANY_LIKE" forKey:@"LIKE_DATA"];
                    
                }else{
                    
                    [dic setObject:[[[newsfeed valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i] forKey:@"LIKE_DATA"];
                    
                }
                
                //newsfeed picture
                if ([[newsfeed valueForKey:@"picture"]isEqual:[NSNull null]]==YES) {
                    
                    [dic setObject:@"NOT_ANY_PICTURE" forKey:@"PICTURE_DATA"];
                
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

#pragma mark get facebook user icon and convert

-(NSMutableDictionary*)getfacebookProfileImage:(NSArray*)timeLineArray{
    
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
                
                [duplicateIndex addIndex:index-1];
                NSLog(@"duplicate index=%d",index-1);
                
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

@end
