//
//  BFAnimation.m
//  BlurFocus
//
//  Created by Kevin Beaulieu on 12/6/16.
//  Copyright © 2016 Kevin Beaulieu. All rights reserved.
//

#import "BFAnimation.h"
#import <QuartzCore/QuartzCore.h>

#define MACOS_WINDOW_CORNER_RADIUS 7.0f

static NSString                 *blurType = @"CIGaussianBlur";
static const double              blurRadius = 4.0;
static const float               refreshRate = 0.06;

@interface BFAnimation ()

@property (nonatomic, retain) NSImageView *blurImageView;

@end

@implementation BFAnimation

- (instancetype)initBlurWithWindow:(NSWindow *)window duration:(NSTimeInterval)duration
            animationCurve:(NSAnimationCurve)animationCurve {
    if (self = [super initWithDuration:duration animationCurve:animationCurve]) {
        _window = window;
        
        
        
        // Create window with blurred image on top of target window
        _overlayWindow = [[NSWindow alloc] initWithContentRect:_window.frame
                styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        _overlayWindow.backgroundColor = [NSColor clearColor];
        _overlayWindow.opaque = NO;
        _overlayWindow.alphaValue = 0.0f;
        _overlayWindow.ignoresMouseEvents = YES;
        _overlayWindow.contentView.wantsLayer = YES;
        _overlayWindow.contentView.layer.opaque = NO;
        _overlayWindow.contentView.layer.masksToBounds = YES;
        _overlayWindow.contentView.layer.cornerRadius = MACOS_WINDOW_CORNER_RADIUS;
        [_window addChildWindow:_overlayWindow ordered:NSWindowAbove];
        
        [self renderBlur];
        
        [NSTimer scheduledTimerWithTimeInterval:refreshRate target:self selector:@selector(renderBlur)
                userInfo:nil repeats:YES];

    }
    return self;
}

- (instancetype)initClearWithWindow:(NSWindow *)window overlayWindow:(NSWindow *)overlayWindow
            duration:(NSTimeInterval)duration animationCurve:(NSAnimationCurve)animationCurve {
    if (self = [super initWithDuration:duration animationCurve:animationCurve]) {
        _reverse = YES;
        _window = window;
        _overlayWindow = overlayWindow;
    }
    return self;
}

- (void)setCurrentProgress:(NSAnimationProgress)currentProgress {
    [super setCurrentProgress:currentProgress];

    if (_reverse) {
        _overlayWindow.alphaValue = 1.0 - currentProgress;
        
        if (currentProgress >= 1.0) {
            [_overlayWindow orderOut:nil];
        }
    } else {
        _overlayWindow.alphaValue = currentProgress;
    }
}

- (void)renderBlur {
    // Grab snapshot of window
    CGImageRef windowImageRef = CGWindowListCreateImage(
                                                        CGRectNull, kCGWindowListOptionIncludingWindow,
                                                        (CGWindowID)[_window windowNumber], kCGWindowImageBoundsIgnoreFraming);
    CIImage *windowImage = [CIImage imageWithCGImage:windowImageRef];
    
    // Blur snapshot, scale to fit
    CIImage *blurredImage = [[windowImage imageByApplyingGaussianBlurWithSigma:blurRadius]
                             imageByCroppingToRect:CGRectMake(blurRadius, blurRadius,
                                                              windowImage.extent.size.width - blurRadius * 2,
                                                              windowImage.extent.size.height - blurRadius * 2)
                             ];
    NSBitmapImageRep *blurredImageRep = [[NSBitmapImageRep alloc] initWithCIImage:blurredImage];
    NSData *blurredImageData = [blurredImageRep representationUsingType:NSBitmapImageFileTypePNG
                                                             properties:@{}];
    NSImage *blurredNSImage = [[NSImage alloc] initWithData:blurredImageData];
    
    // Update display
    if (_blurImageView == nil) {
        _blurImageView = [NSImageView imageViewWithImage:blurredNSImage];
        _blurImageView.frame = NSMakeRect(0, 0, _overlayWindow.frame.size.width,
                                          _overlayWindow.frame.size.height);
        [_overlayWindow.contentView addSubview:_blurImageView];
    } else {
        _blurImageView.image = blurredNSImage;
        _blurImageView.frame = NSMakeRect(0, 0, _overlayWindow.frame.size.width,
                                         _overlayWindow.frame.size.height);
    }
}

@end
