//
//  BlurFocus.m
//  BlurFocus
//
//  Created by Wolfgang Baird on 4/30/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//
//  Modified by Kevin Beaulieu on 12/6/16.
//

@import AppKit;
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "BFAnimation.h"

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

static void                     *isActive = &isActive;
static void                     *overlayWindow = &overlayWindow;
static const float              duration = 0.1;
static const NSAnimationCurve   animationCurve = NSAnimationEaseInOut;

+ (void)load
{
    NSArray *blacklist = @[@"com.apple.notificationcenterui", @"com.google.chrome", @"com.google.chrome.canary"];
    NSString *appID = [[NSBundle mainBundle] bundleIdentifier];
    if (![blacklist containsObject:appID])
    {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_clearWindow:) name:NSWindowDidBecomeMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_clearWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
        [center addObserver:self selector:@selector(BF_clearWindow:) name:NSWindowDidEnterFullScreenNotification object:nil];
        [center addObserver:self selector:@selector(BF_spaceChanged:) name:NSWorkspaceActiveSpaceDidChangeNotification object:nil];
    }
}

+ (void)BF_blurWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if (![objc_getAssociatedObject(win, isActive) boolValue] // Already blurred
            && !([win styleMask] & NSWindowStyleMaskFullScreen) // Don't blur full-/split-screen windows
            && win.level <= NSNormalWindowLevel // Only blur normal windows & desktop icons
            && win.attachedSheet == nil // Don't blur if it would cover up a modal dialog
            && ![win isKindOfClass:[NSPanel class]] // Dont' blur if panel (e.g., emojis, fonts)
            ) {
        BFAnimation *anim = [[BFAnimation alloc] initBlurWithWindow:win duration:duration animationCurve:animationCurve];
        objc_setAssociatedObject(win, overlayWindow, anim.overlayWindow, OBJC_ASSOCIATION_RETAIN);
        [anim startAnimation];
        
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)BF_clearWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if ([objc_getAssociatedObject(win, isActive) boolValue]) {
        NSWindow *savedOverlayWindow = objc_getAssociatedObject(win, overlayWindow);
        BFAnimation *anim = [[BFAnimation alloc] initClearWithWindow:win overlayWindow:savedOverlayWindow duration:duration animationCurve:animationCurve];
        [anim startAnimation];
        
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)BF_spaceChanged:(NSNotification *)note
{
    [NSApplication sharedApplication];
    
    // If active application's key window is in a different space, give focus to Finder
    if (NSApp.isActive && !NSApp.keyWindow.isOnActiveSpace) {
        NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
        for (NSRunningApplication *app in apps) {
            if([app.bundleIdentifier.lowercaseString isEqualToString:@"com.apple.finder"]) {
                [app activateWithOptions:NSApplicationActivateAllWindows|NSApplicationActivateIgnoringOtherApps];
                break;
            }
        }
    }
}

@end
