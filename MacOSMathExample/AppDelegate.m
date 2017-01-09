//
//  AppDelegate.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-08.
//  Copyright © 2017年 安志钢. All rights reserved.
//

#import "AppDelegate.h"
#import "MTMathUILabel.h"
#import "MTFont.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet MTMathUILabel *screen;
@property (weak) IBOutlet NSTextField *inputTextField;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)clickUpdateButton:(NSButton *)sender
{
    
}

@end
