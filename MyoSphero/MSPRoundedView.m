//
//  MSPRoundedView.m
//  MyoSphero
//
//  Created by Mark DiFranco on 2015-04-29.
//  Copyright (c) 2015 Thalmic Labs. All rights reserved.
//

#import "MSPRoundedView.h"

@implementation MSPRoundedView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.layer.cornerRadius = self.frame.size.height/2.0;
    self.layer.masksToBounds = YES;
}

@end
