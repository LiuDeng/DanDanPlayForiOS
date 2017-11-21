//
//  UIImageView+Tools.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 17/2/18.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "UIImageView+Tools.h"

@implementation UIImageView (Tools)
- (void)jh_setImageWithURL:(NSURL *)imageURL {
    [self yy_setImageWithURL:imageURL placeholder:[UIImage imageNamed:@"comment_place_holder"] options:YY_WEB_IMAGE_DEFAULT_OPTION completion:nil];
}

- (void)jh_setImageWithURL:(NSURL *)imageURL placeholder:(UIImage *)placeholder {
    [self yy_setImageWithURL:imageURL placeholder:placeholder options:YY_WEB_IMAGE_DEFAULT_OPTION completion:nil];
}

- (void)jh_setImageWithFadeType:(UIImage *)image {
    self.image = nil;
    [self.layer removeAllAnimations];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.layer addAnimation:transition forKey:@"JHImageFadeAnimationKey"];
    self.image = image;
}

@end