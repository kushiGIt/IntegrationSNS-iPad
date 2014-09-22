//
//  ViewController.m
//  IntegrationSNS-iPad
//
//  Created by RyousukeKushihata on 2014/09/22.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import "ViewController.h"

@interface ViewController (){
    NSMutableArray *textTweetArray;
    NSMutableArray *nameTweetArray;
    NSMutableArray *tweetIconArray;
    NSMutableArray *dateArray;
    UITableView *tableView;
    int alertOpe;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    tableView.delegate=self;
    tableView.dataSource=self;
    textTweetArray=[[NSMutableArray alloc]init];
    nameTweetArray=[[NSMutableArray alloc]init];
    tweetIconArray=[[NSMutableArray alloc]init];
    dateArray=[[NSMutableArray alloc]init];
    //[self getTwitterTimeline];
    [self getFaceBookTimeLine];
    //[self getTwitterTimeline];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - TableView methods
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return textTweetArray.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    UILabel*label=(UILabel*)[cell viewWithTag:94];
    label.text=[NSString stringWithFormat:@"%@",textTweetArray[indexPath.row]];
    return cell;
}
#pragma mark - Button methods
#pragma mark BackBt
-(IBAction)backToTop{
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark --------
-(void)getFaceBookTimeLine{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{ ACFacebookAppIdKey : @"1695130440712382",ACFacebookAudienceKey : ACFacebookAudienceOnlyMe,ACFacebookPermissionsKey:@[@"email",@"like",@"read_stream"]};
    
    [accountStore requestAccessToAccountsWithType:accountType options:options completion:^(BOOL granted, NSError *error) {
        if (granted==YES) {
            NSArray *facebookAccounts = [accountStore accountsWithAccountType:accountType];
            if (facebookAccounts.count > 0) {
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
                    
                    NSCalendar*calendar=[NSCalendar currentCalendar];
                    NSDateComponents*components=[[NSDateComponents alloc]init];
                    //originalString to NSInterger
                    NSString*originalDateString=[NSString stringWithFormat:@"%@",[[newsfeed valueForKey:@"data"]valueForKey:@"created_time"][i]];
                    NSLog(@"%@",originalDateString);
                    components.year=[[originalDateString substringWithRange:NSMakeRange(0,4)]integerValue];
                    components.month=[[originalDateString substringWithRange:NSMakeRange(5,2)]integerValue];
                    components.day=[[originalDateString substringWithRange:NSMakeRange(8,2)]integerValue];
                    components.hour=[[originalDateString substringWithRange:NSMakeRange(11,2)]integerValue];
                    components.minute=[[originalDateString substringWithRange:NSMakeRange(14,2)]integerValue];
                    components.second=[[originalDateString substringWithRange:NSMakeRange(17,2)]integerValue];
                    NSLog(@"Convert results ==> %ld-%ld-%ld-%ld-%ld-%ld",components.year,components.month,components.day,components.hour,components.minute,components.second);
                    //NSInterger to NSDate
                    NSDate*date=[calendar dateFromComponents:components];
                    NSLog(@"nsdate==>%@",date);
                    
                    //How many is this messege like_count
                    if ([[[[[newsfeed valueForKey:@"data"]valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i]isEqual:[NSNull null]]==YES) {
                        NSLog(@"Not any likes");
                    }else{
                        NSLog(@"Likes_Count=%lu",(unsigned long)[[[[[newsfeed valueForKey:@"data"]valueForKey:@"likes"]valueForKey:@"data"]objectAtIndex:i]count]);
                    }
                }
                
            }else{
                
                 NSLog(@"a %@",error);
                UIAlertView*noAccountAlert=[[UIAlertView alloc]initWithTitle:@"Facebook account" message:@"アカウントを見つけることができませんでした。今すぐ「設定」でアカウントを設定しますか？" delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
                [noAccountAlert show];
                alertOpe=10;
            }
        } else {
            NSLog(@"b %@",error);
            UIAlertView*noGrantedAlert=[[UIAlertView alloc]initWithTitle:@"Facebook account" message:@"アカウントアクセスが拒否になってます。今すぐ「設定」でアカウントを再設定しますか？" delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
            [noGrantedAlert show];
            alertOpe=10;
        }
        
    }];
}

-(void)getTwitterTimeline{
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        
        if(granted==YES){
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts != nil && [accounts count] != 0) {
                ACAccount *twAccount = accounts[0];
                NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
                NSLog(@"%@",[url absoluteString]);
                NSDictionary *parametersDic=@{@"include_entities": @"1",@"count": @"200"};
                SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:parametersDic];
                request.account = twAccount;
                [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    if (urlResponse){
                        NSError *jsonError;
                        NSArray *timeline = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
                        if(timeline){
                            //                            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld",(long)[urlResponse statusCode]];
                            //                            NSLog(@"%@", output);
                            //                            NSLog(@"%@",timeline);
                            for (NSDictionary *tweet in timeline) {
                                [textTweetArray addObject:[tweet valueForKey:@"text"]];
                                NSDictionary *user = tweet[@"user"];
                                [nameTweetArray addObject:user[@"screen_name"]];
                                [tweetIconArray addObject:user[@"profile_image_url"]];
                                [dateArray addObject:tweet[@"created_at"]];
                            }
                            //===============test=================
                            for (int i=0; i<textTweetArray.count; i++) {
                                NSLog(@"\n number==%d \n text==%@ \n user-screen_name==%@ \n user-profile_image_url==%@ \n created_at==%@ \n\n\n\n",i,textTweetArray[i],nameTweetArray[i],tweetIconArray[i],dateArray[i]);
                            }
                            //===============end==================
                            [tableView reloadData];
                        }else{
                            NSLog(@"error: %@",jsonError);
                        }
                    }
                }];
            }else{
                UIAlertView*noAccountAlert=[[UIAlertView alloc]initWithTitle:@"Twitter account" message:@"アカウントを見つけることができませんでした。今すぐ「設定」でアカウントを設定しますか？" delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
                [noAccountAlert show];
                alertOpe=20;
            }
        }else{
            UIAlertView*noGrantedAlert=[[UIAlertView alloc]initWithTitle:@"Twitter account" message:@"アカウントアクセスが拒否になってます。今すぐ「設定」でアカウントを再設定しますか？" delegate:self cancelButtonTitle:@"いいえ" otherButtonTitles:@"はい", nil];
            [noGrantedAlert show];
            alertOpe=20;
        }
    }];
    
}
#pragma mark - UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{switch (alertOpe) {
    case 10:{
        switch (buttonIndex) {
            case 0:
                break;
            case 1:
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"prefs:root=General"]];
                break;
        }
    }
        break;
    case 20:{
        switch (buttonIndex) {
            case 0:
                break;
            case 1:
                [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
                
                break;
        }
    }
        break;
}
}


@end
