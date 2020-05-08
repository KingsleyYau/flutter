//
//  ViewController.m
//  Calculator
//
//  Created by Max on 2018/12/25.
//  Copyright © 2018 net.qdating. All rights reserved.
//

#import "ViewController.h"
#import "SubViewController.h"
#import "PushViewController.h"

#import "AppDelegate.h"
//#import <Firebase.h>

@interface ViewController ()
@property (strong) UINavigationController *nvc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    FlutterEngine *flutterEngine = delegate.flutterEngine;
    
    FlutterMethodChannel *testChannel =
        [FlutterMethodChannel methodChannelWithName:@"samples.flutter.dev/goToNativePage"
                                    binaryMessenger:flutterEngine.binaryMessenger];
    [testChannel setMethodCallHandler:^(FlutterMethodCall *call, FlutterResult result) {
//        NSLog(@"FlutterMethodChannel(), %@", call.arguments[@"param"]);
        if ([@"goToNativePage" isEqualToString:call.method]) {
            //实现跳转的代码
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            result(FlutterMethodNotImplemented);
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 随机生成20内的ScreenName
    int rand = arc4random() % 20;
    NSString *screenName = [NSString stringWithFormat:@"ViewController%i", (int)rand];
    NSString *screenClass = [self.classForCoder description];
    //    [FIRAnalytics setScreenName:screenName screenClass:screenClass];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)registerAction:(id)sender {
    //    [FIRAnalytics logEventWithName:@"register"
    //                        parameters:@{
    //                                     @"Category":@"CategoryRegister",
    //                                     @"Action":@"ActionRegister",
    //                                     @"Label":@"LabelRegister"
    //                                     }];
}

- (IBAction)loginAction:(id)sender {
    //    [FIRAnalytics logEventWithName:@"login"
    //                        parameters:@{
    //                                     @"Category":@"CategoryLogin",
    //                                     @"Action":@"ActionLogin",
    //                                     @"Label":@"LabelLogin"
    //                                     }];
}

- (IBAction)clickAction:(id)sender {
    //    [FIRAnalytics logEventWithName:@"normal_click"
    //                        parameters:@{
    //                                     @"Category":@"CategoryNormal_click",
    //                                     @"Action":@"ActionNormal_click",
    //                                     @"Label":@"ActionNormal_click"
    //                                     }];
}

- (IBAction)categoryAction:(id)sender {
    //    [FIRAnalytics logEventWithName:kFIREventSelectContent
    //                        parameters:@{
    //                                     kFIRParameterItemCategory:@"item_category_api",
    //                                     kFIRParameterItemID:@"item_id_123456",
    //                                     kFIRParameterItemName:@"item_id_123456_hardy",
    //                                     kFIRParameterContentType:@"item_id_123456_content_hello"
    //                                     }];
}

- (IBAction)userIdAction:(id)sender {
    //    [FIRAnalytics setUserID:@"userId_abcdefg_tag"];
}

- (IBAction)userPropertyAction:(id)sender {
    //    [FIRAnalytics setUserPropertyString:@"apple" forName:@"favorite_food"];
}

- (IBAction)showAction:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    SubViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"SubViewController"];
    vc.nvc = self.navigationController;

    [self.nvc removeFromParentViewController];
    self.nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    self.nvc.view.frame = CGRectMake(0, self.view.frame.size.height - 300, self.view.frame.size.width, 300);
    [self.view addSubview:self.nvc.view];
    [self addChildViewController:self.nvc];
}

- (IBAction)hideAction:(id)sender {
    [self.nvc.view removeFromSuperview];
    [self.nvc removeFromParentViewController];
}

- (IBAction)mainAction:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    FlutterEngine *flutterEngine = delegate.flutterEngine;
    FlutterBasicMessageChannel *reloadMessageChannel = delegate.reloadMessageChannel;

    [flutterEngine.navigationChannel invokeMethod:@"setInitialRoute"
                                        arguments:@"/main"];
    [reloadMessageChannel sendMessage:@"/main"];

    FlutterViewController *flutterVC = [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
    //    FlutterViewController *flutterVC = [[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
    //    [flutterVC setInitialRoute:@"firstVC"];
    [self.navigationController pushViewController:flutterVC animated:YES];
}

- (IBAction)secondAction:(id)sender {
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    FlutterEngine *flutterEngine = delegate.flutterEngine;
    FlutterBasicMessageChannel *reloadMessageChannel = delegate.reloadMessageChannel;

    [flutterEngine.navigationChannel invokeMethod:@"setInitialRoute"
                                        arguments:@"/second"];
    [reloadMessageChannel sendMessage:@"/second"];

    FlutterViewController *flutterVC = [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
    //    FlutterViewController *flutterVC = [[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
    //    [flutterVC setInitialRoute:@"firstVC"];
    [self.navigationController pushViewController:flutterVC animated:YES];
}
@end
