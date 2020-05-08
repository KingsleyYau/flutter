//
//  AppDelegate.h
//  Calculator
//
//  Created by Max on 2018/12/25.
//  Copyright © 2018 net.qdating. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FlutterPluginRegistrant/GeneratedPluginRegistrant.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, FlutterAppLifeCycleProvider>

@property (strong, nonatomic) UIWindow *window;
@property (strong) FlutterEngine *flutterEngine;
@property (strong) FlutterBasicMessageChannel *reloadMessageChannel;
@end

