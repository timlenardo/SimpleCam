//
//  FocusIndicatorView.m
//  SimpleCam
//
//  Created by Timothy Lenardo on 6/17/16.
//  Copyright © 2016 Upcast, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FocusIndicatorView.h"

#define kIndicatorLoopingPeriod 400

@interface FocusIndicatorView() {
    double _startTime;
    double _animationPosition;
    NSTimer *_animationTimer;
    BOOL _isLocked;
}
@end

@implementation FocusIndicatorView

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    [self setBackgroundColor:[UIColor clearColor]];
    self.alpha = 0.0;
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (_isLocked) {
        CGContextSetStrokeColorWithColor(context, [UIColor blueColor].CGColor);
    } else {
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    }
    
    CGFloat lineWidth = 1;
    CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
    
    // Confusing logic here. '_animationPositon' increments from 0->2 and then resets.
    // This translates that into an oscilation between 4 and 5 (radius for outer ring).
    CGFloat multiple;
    if (_animationPosition > 1.0) {
        multiple = 5.5 - (_animationPosition / 2);
    } else {
        multiple = 4.5 + (_animationPosition / 2);
    }
    
    CGFloat radius = center.x * multiple / 5 - lineWidth * 0.5;
    CGFloat startAngle = -((float)M_PI / 2);
    CGFloat endAngle = startAngle + (2 * ((float)M_PI));
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextAddArc(context, center.x, center.y, radius, startAngle, endAngle, 0);
    CGContextStrokePath(context);
    
    CGFloat innerLineWidth = 4;
    CGFloat innerRadius = center.x * 3 / 5 - innerLineWidth * 0.5;
    CGContextSetLineWidth(context, innerLineWidth);
    CGContextAddArc(context, center.x, center.y, innerRadius, startAngle, endAngle, 0);
    CGContextStrokePath(context);
}

#pragma animation

- (void)startAnimation {
    self.alpha = 1.0;
    _startTime = [[NSDate date] timeIntervalSince1970];
    _animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(updateRing) userInfo:nil repeats:YES];
}

- (void)updateRing {
    double currentTime = [[NSDate date] timeIntervalSince1970];
    double diff = (currentTime - _startTime) * 1000;
    int diff_ms = floor(diff);
    _animationPosition = (double)(diff_ms % kIndicatorLoopingPeriod * 2) / kIndicatorLoopingPeriod;
    [self setNeedsDisplay];
}

- (void)reset {
    [_animationTimer invalidate];
    _startTime = 0;
    _animationPosition = 0;
    _isLocked = NO;
    [self setNeedsDisplay];
}

#pragma api

- (void)showAtPoint:(CGPoint)location {
    CGRect frame = self.frame;
    CGRect newFrame = CGRectMake(location.x - frame.size.width / 2, location.y - frame.size.height / 2, frame.size.width, frame.size.height);
    self.frame = newFrame;
    [self startAnimation];
}

- (void)lock {
    _isLocked = YES;
}

- (void)finishAnimation {
    // Let the indicator show for a bit.
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [UIView animateWithDuration:0.50 animations:^{
            self.alpha = 0;
        }
                         completion:^(BOOL finished) {
                             [self reset];
                         }];
    });
}

@end
