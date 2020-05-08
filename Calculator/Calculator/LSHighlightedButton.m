//
//  LSHighlightedButton.m
//  livestream
//
//  Created by Max on 2018/5/17.
//  Copyright © 2018年 net.qdating. All rights reserved.
//

#import "LSHighlightedButton.h"

@implementation LSHighlightedButton
- (void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"LSHighlightedButton::awakeFromNib : %p", self);
    [self addObserver:self forKeyPath:@"highlighted" options:0 context:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"LSHighlightedButton::touchesBegan");
    self.highlighted = YES;
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"LSHighlightedButton::touchesEnded");
    self.highlighted = NO;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"LSHighlightedButton::touchesCancelled");
    self.highlighted = NO;
    [super touchesCancelled:touches withEvent:event];
}

//- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event {
//    NSLog(@"LSHighlightedButton::beginTrackingWithTouch");
//    return YES;
//}
//- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event {
//    NSLog(@"LSHighlightedButton::continueTrackingWithTouch");
//    return YES;
//}
//- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event {
//    NSLog(@"LSHighlightedButton::endTrackingWithTouch");
//}
//- (void)cancelTrackingWithEvent:(nullable UIEvent *)event {
//    NSLog(@"LSHighlightedButton::cancelTrackingWithEvent");
//}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    NSLog(@"LSHighlightedButton::drawRect : %p", self);
}

- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    //    NSLog(@"LSHighlightedButton::layoutIfNeeded : %p", self);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    //    NSLog(@"LSHighlightedButton::layoutSubviews : %p", self);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"highlighted"]) {
        NSLog(@"LSHighlightedButton::observeValueForKeyPath : %p, self.highlighted : %d", self, self.highlighted);
        if( self.highlighted ) {
            self.layer.borderWidth = 3;
            self.layer.borderColor = [UIColor blueColor].CGColor;
        } else {
            self.layer.borderWidth = 0;
            self.layer.borderColor = [UIColor blueColor].CGColor;
        }

        [self setNeedsDisplay];
    }
}
@end
