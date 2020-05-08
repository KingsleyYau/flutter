//
//  TestCollectionViewCell.m
//  Calculator
//
//  Created by Max on 2019/1/28.
//  Copyright © 2019 net.qdating. All rights reserved.
//

#import "TestCollectionViewCell.h"

@implementation TestCollectionViewCell
+ (NSString *)cellIdentifier {
    return @"TestCollectionViewCell";
}

+ (NSInteger)cellWidth {
    return 66;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.button setBackgroundImage:[UIImage imageNamed:@"TestButton"] forState:UIControlStateNormal];
//    [self.button setBackgroundImage:[UIImage imageNamed:@"TestButtonHighlighted"] forState:UIControlStateHighlighted];
    
//    [self.button addTarget:self action:@selector(downAction:) forControlEvents:UIControlEventTouchDown];
//    [self.button addTarget:self action:@selector(releaseAction:) forControlEvents:UIControlEventTouchUpInside];
//    [self.button addTarget:self action:@selector(releaseAction:) forControlEvents:UIControlEventTouchUpOutside];
}

- (void)layoutSubviews {
}

- (IBAction)downAction:(id)sender {
//    NSLog(@"LSHighlightedButton::downAction : %p", self);
//    self.buttonBG.hidden = NO;
}

- (IBAction)releaseAction:(id)sender {
//    NSLog(@"LSHighlightedButton::releaseAction : %p", self);
    
//    self.buttonBG.hidden = YES;
}

@end
