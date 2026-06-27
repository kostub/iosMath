//
//  SceneDelegate.m
//  iosMath
//
//  Created by Jan de Vries on 22/06/2026.
//

#import "SceneDelegate.h"
#import "ViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    if (![windowScene isKindOfClass:[UIWindowScene class]]) return;
    
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor systemBackgroundColor];
    ViewController *rootVC = [[ViewController alloc] initWithNibName:@"View" bundle:nil];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
}

@end
