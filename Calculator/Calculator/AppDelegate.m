//
//  AppDelegate.m
//  Calculator
//
//  Created by Max on 2018/12/25.
//  Copyright © 2018 net.qdating. All rights reserved.
//

#import "AppDelegate.h"

#import <Firebase.h>

static NSString *_kReloadChannelName = @"reload";

@interface AppDelegate ()
@property (nonatomic, strong) FlutterPluginAppLifeCycleDelegate *lifeCycleDelegate;
@end

@implementation AppDelegate
- (instancetype)init {
    if (self = [super init]) {
        _lifeCycleDelegate = [[FlutterPluginAppLifeCycleDelegate alloc] init];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    //    [FIRApp configure];

    self.flutterEngine = [[FlutterEngine alloc] initWithName:@"io.flutter" project:nil];
    [[self.flutterEngine navigationChannel] invokeMethod:@"setInitialRoute"
                                               arguments:@"/"];
    [self.flutterEngine run];

    self.reloadMessageChannel = [[FlutterBasicMessageChannel alloc]
           initWithName:_kReloadChannelName
        binaryMessenger:self.flutterEngine.binaryMessenger
                  codec:[FlutterStringCodec sharedInstance]];

    [GeneratedPluginRegistrant registerWithRegistry:self.flutterEngine];
    
    return [_lifeCycleDelegate application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (FlutterViewController *)rootFlutterViewController {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([viewController isKindOfClass:[FlutterViewController class]]) {
        return (FlutterViewController *)viewController;
    }
    return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    // Pass status bar taps to key window Flutter rootViewController.
    if (self.rootFlutterViewController != nil) {
        [self.rootFlutterViewController handleStatusBarTouches:event];
    }
}

- (void)application:(UIApplication *)application
    didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [_lifeCycleDelegate application:application
        didRegisterUserNotificationSettings:notificationSettings];
}

- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [_lifeCycleDelegate application:application
        didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [_lifeCycleDelegate application:application
        didReceiveRemoteNotification:userInfo
              fetchCompletionHandler:completionHandler];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return [_lifeCycleDelegate application:application openURL:url options:options];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [_lifeCycleDelegate application:application handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application
              openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
           annotation:(id)annotation {
    return [_lifeCycleDelegate application:application
                                   openURL:url
                         sourceApplication:sourceApplication
                                annotation:annotation];
}

- (void)application:(UIApplication *)application
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler NS_AVAILABLE_IOS(9_0) {
    [_lifeCycleDelegate application:application
        performActionForShortcutItem:shortcutItem
                   completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application
    handleEventsForBackgroundURLSession:(nonnull NSString *)identifier
                      completionHandler:(nonnull void (^)(void))completionHandler {
    [_lifeCycleDelegate application:application
        handleEventsForBackgroundURLSession:identifier
                          completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application
    performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    [_lifeCycleDelegate application:application performFetchWithCompletionHandler:completionHandler];
}

- (void)addApplicationLifeCycleDelegate:(NSObject<FlutterPlugin> *)delegate {
    [_lifeCycleDelegate addDelegate:delegate];
}
@end
