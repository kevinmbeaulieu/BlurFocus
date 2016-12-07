//
//  BFAnimation.h
//  BlurFocus
//
//  Created by Kevin Beaulieu on 12/6/16.
//  Copyright © 2016 Kevin Beaulieu. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface BFAnimation : NSAnimation

@property (nonatomic, retain) NSWindow *window;
@property (nonatomic, retain) NSWindow *overlayWindow;
@property (nonatomic) BOOL reverse;

- (instancetype)initBlurWithWindow:(NSWindow *)window duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve;
- (instancetype)initClearWithWindow:(NSWindow *)window overlayWindow:(NSWindow *)overlayWindow duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve;

@end
