//
//  TestCollectionViewCell.h
//  Calculator
//
//  Created by Max on 2019/1/28.
//  Copyright © 2019 net.qdating. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSHighlightedButton.h"

@interface TestCollectionViewCell : UICollectionViewCell
@property IBOutlet LSHighlightedButton *button;

+ (NSString *)cellIdentifier;
+ (NSInteger)cellWidth;
@end
