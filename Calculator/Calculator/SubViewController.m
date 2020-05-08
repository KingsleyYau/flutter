//
//  SubViewController.m
//  Calculator
//
//  Created by Max on 2019/1/28.
//  Copyright © 2019 net.qdating. All rights reserved.
//

#import "SubViewController.h"
#import "PushViewController.h"

@interface SubViewController ()

@end

@implementation SubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pushAction:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PushViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"PushViewController"];
    [self.nvc pushViewController:vc animated:YES];
}

- (IBAction)internalPushAction:(id)sender {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    PushViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"PushViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
