//
//  AppDelegate.m
//  MacOSMath
//
//  Created by 安志钢 on 17-01-08.
//  Copyright © 2017年 安志钢. All rights reserved.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "AppDelegate.h"
#import "MTMathUILabel.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet MTMathUILabel *screen;
@property (weak) IBOutlet NSTextField *inputTextField;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Insert code here to tear down your application
}

- (IBAction)clickUpdateButton:(NSButton *)sender
{
    self.screen.latex = self.inputTextField.stringValue;
}

@end
