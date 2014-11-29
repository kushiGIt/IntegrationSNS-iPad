//
//  ViewController.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/09/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "ViewController.h"
#import "GetFaceBookTimeLine.h"
#import "GetTwitterTimeline.h"
#define USER_IMAGE_VIEW_TAG 1
#define USER_NAME_VIEW_TAG 2
#define CREATED_TIME_LABEL_TAG 3
#define USER_TEXT_DATA 4
#define IMAGE_VIEW_TAG 5

@interface ViewController (){
    IBOutlet UITableView*mytableview;
    NSUserDefaults*defaults;
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
        
        NSMutableDictionary*facebookNewsfeedImage=[[NSMutableDictionary alloc]initWithDictionary:[[[RKGetFacebookTimeLine alloc]init]getFacebookNewsFeedPicture_withImageDic:timelineDic]];
        NSString*urlKeyStr=[NSString stringWithFormat:@"%@",[[timelineDic objectForKey:@"PICTURE_DATA"]firstObject]];
        UIImage*facebookNewsFeedImageFromNSData=[[UIImage alloc]initWithData:[facebookNewsfeedImage objectForKey:urlKeyStr]];
        imageData.image=facebookNewsFeedImageFromNSData;//test
        [imageData addGestureRecognizer:tapGesture];
    
    }else if ([[timelineDic objectForKey:@"TYPE"]isEqualToString:@"TWITTER"]){
        
        UIImage*profileImage=[userImageData__TABLE__ objectForKey:[timelineDic objectForKey:@"USER_ICON"]];
        userImage.image=profileImage;
        
        userNameTextView.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"USER_NAME"]];
        
        NSString*dateStr=[self dateToString:[timelineDic objectForKey:@"POST_DATE"] formatString:@"yyyy-MM-dd"];
        created_time.text=dateStr;
        
        userTextData.text=[NSString stringWithFormat:@"%@",[timelineDic objectForKey:@"TEXT"]];
        
        imageData.image=[UIImage imageNamed:@"icon-success"];//test
        [imageData addGestureRecognizer:tapGesture];
    
    }else{
        
        NSLog(@"Not found this type...%@",[timelineDic valueForKey:@"TYPE"]);
    
    }
    
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 948;
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
        
        gotTwitterTimeLineDic=[[NSDictionary alloc]initWithDictionary:[[[RKGetTwitterTimeline alloc]init]getTwitterTimeLineNewly]];
        
        gotFacebookTimeLineDic=[[NSDictionary alloc]initWithDictionary:[[[RKGetFacebookTimeLine alloc]init]getFaceBookTimeLine]];
        
        NSError*facebookError=[gotFacebookTimeLineDic objectForKey:@"ERROR_MESSEGE_CODE"];
        
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_async(mainQueue, ^{
            
            MODropAlertView*alert;
            
            //facebook
            switch ([[gotFacebookTimeLineDic objectForKey:@"RKGetTimeLineErrorType"]intValue]) {
                case RKGetFacebookTimeLineErrorType_AccountError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Facebookアカウントエラー" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                    break;
                }case RKGetFacebookTimeLineErrorType_DataIsNull:{
                    
                    SJNotificationViewController*_notificationController = [[SJNotificationViewController alloc] initWithNibName:@"SJNotificationViewController" bundle:nil];
                    [_notificationController setParentView:self.view];
                    [_notificationController setTapTarget:self selector:nil];
                    //[_notificationController setNotificationTitle:@"新しい投稿はありません。"];
                    [_notificationController show];
                    
                    break;
                }case RKGetFacebookTimeLineErrorType_RequestError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"リクエストエラー" description:@"サーバからの応答がありません。時間を置いてから試してみてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                    break;
                }case RKGetFacebookTimeLineErrorType_FacebookServerError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:[NSString stringWithFormat:@"エラー%ld",(long)facebookError.code] description:facebookError.localizedDescription okButtonTitle:@"OK"];
                    [alert show];
                    
                    break;
                    
                }case RKGetFacebookTimeLineErrorType_Success:{
                    
                    break;
                
                }
            }
            
            //twitter
            switch ([[gotTwitterTimeLineDic objectForKey:@"RKGetTimeLineErrorType"]intValue]) {
                case RKGetTwiiterTimeLineErrorType_AccountError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"Twitterアカウントエラー" description:@"アカウントに問題があるようです。今すぐ設定を確認しますか？" okButtonTitle:@"はい" cancelButtonTitle:@"いいえ"];
                    alert.delegate=self;
                    [alert show];
                    
                    break;
                
                }
                case RKGetTwiiterTimeLineErrorType_DataIsNull:{
                    
                    SJNotificationViewController*_notificationController = [[SJNotificationViewController alloc] initWithNibName:@"SJNotificationViewController" bundle:nil];
                    [_notificationController setParentView:self.view];
                    [_notificationController setTapTarget:self selector:nil];
                    [_notificationController setNotificationLevel:SJNotificationLevelMessage];
                    [_notificationController setNotificationPosition:SJNotificationPositionBottom];
                    [_notificationController setNotificationTitle:@"新しいツイートはありません。"];
                    [_notificationController showFor:5];
                    
                    break;
                
                }
                case RKGetTwiiterTimeLineErrorType_RequestError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"リクエストエラー" description:@"サーバからの応答がありません。時間を置いてから試してみてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                    break;
                
                }
                case RKGetTwiiterTimeLineErrorType_TwitterServerError:{
                    
                    alert=[[MODropAlertView alloc]initDropAlertWithTitle:@"リクエストエラー" description:@"サーバからの応答がありません。時間を置いてから試してみてください。" okButtonTitle:@"OK"];
                    [alert show];
                    
                    break;
                
                }case RKGetTwiiterTimeLineErrorType_Success:{
                    
                    break;
                    
                }
            }
            
        });
        
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
                
                [facebookArray addObjectsFromArray: [[[[RKGetFacebookTimeLine alloc]init]getFacebookTimeLineFromLocalNSUserDeafalults]objectForKey:@"FACEBOOK_DATA"]];
            
            }
        
        }
        //add
        [array addObjectsFromArray:facebookArray];
        
        if ([[gotTwitterTimeLineDic objectForKey:@"ERROR"]boolValue]==NO) {
            
            [twitterArray addObjectsFromArray:[gotTwitterTimeLineDic objectForKey:@"TWITTER_DATA"]];
        
        }else{
            
            NSError*twitterError=[gotTwitterTimeLineDic objectForKey:@"ERROR_MESSEGE_CODE"];
            
            if (twitterError.code==100 || twitterError.code==101) {
                
                [twitterArray addObjectsFromArray:[[[[RKGetTwitterTimeline alloc]init]getTwitterTimeLineFromLocalNSUserDeafalults]objectForKey:@"TWITTER_DATA"]];
            
            }
            
        }
        
        //for get twitter profile image
        NSMutableDictionary*twitterProfileImageDic=[[NSMutableDictionary alloc]initWithDictionary:[[[RKGetTwitterTimeline alloc]init]getTwitterProfileImage:twitterArray]];
        //for get facebook profile image
        NSMutableDictionary*facebookProfileImageDic=[[NSMutableDictionary alloc]initWithDictionary:[[[RKGetFacebookTimeLine alloc]init]getfacebookProfileImage:facebookArray]];
        
        //for twitter data remove
        NSSortDescriptor *sortDescNumber_TWITTER;
        sortDescNumber_TWITTER=[[NSSortDescriptor alloc] initWithKey:@"POST_DATE" ascending:NO];
        NSArray*sortDescArray_TWITTER=[[NSArray alloc]initWithObjects:sortDescNumber_TWITTER, nil];
        NSArray*twitterSortedArray=[twitterArray sortedArrayUsingDescriptors:sortDescArray_TWITTER];
        NSArray*twitterRemovedArray=[[NSArray alloc]initWithArray:[[[RKGetTwitterTimeline alloc]init]twitterDataRemove:twitterSortedArray.mutableCopy].copy];
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
