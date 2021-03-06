//
//  AppDelegate.m
//  MSLaunchView
//
//  Created by TuBo on 2018/11/8.
//  Copyright © 2018 TuBur. All rights reserved.
//

#import "AppDelegate.h"
#import "MSLaunchView.h"
#import "MSExampleDotView.h"
#define MSScreenW   [UIScreen mainScreen].bounds.size.width
#define MSScreenH   [UIScreen mainScreen].bounds.size.height
@interface AppDelegate (){
    MSLaunchView *_launchView;
}

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor redColor];

    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    //用StoryBoard创建的项目
    NSArray *imageNameArray = @[@"Untitled-4.gif",@"Untitled-6.gif",@"Untitled-7.gif"];

//    MSLaunchView *launchView = [MSLaunchView launchWithImages:imageNameArray sbName:@"" guideFrame:CGRectMake(MSScreenW*0.3, MSScreenH*0.8, MSScreenW*0.4, MSScreenH*0.08) gImage:[UIImage imageNamed:@""]];
    
    //没有立即进入按钮
    MSLaunchView *launchView = [MSLaunchView launchWithImages:imageNameArray];
    
    launchView.pageControlStyle = kMSPageContolStyleCustomer;
//
//    NSString *path  = [[NSBundle mainBundle]  pathForResource:@"测试" ofType:@"mp4"];
//    NSURL *url = [NSURL fileURLWithPath:path];
//    MSLaunchView *launchView = [MSLaunchView launchWithVideo:CGRectMake(0, 0, MSScreenW, MSScreenH) videoURL:url];
//    launchView.videoGravity = AVLayerVideoGravityResize;
    
    launchView.pageDotColor = [UIColor lightGrayColor];
    launchView.currentPageDotColor = [UIColor orangeColor];
    
//    launchView.guideTitle = @"进入当前界面";
//    launchView.guideTitleColor = [UIColor redColor];
//    launchView.showPageControl = NO;
    launchView.dotViewClass = [MSExampleDotView class];
    //pageControl的间距大小
//    launchView.spacingBetweenDots = 15;
//    launchView.pageControlBottomOffset += 20;
    _launchView = launchView;
//    launchView.isPalyEndOut = NO;
    
    
    [launchView guideBtnCustom:^UIButton * _Nonnull{
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(60, 60, 130, 60);
        [btn setBackgroundColor:[UIColor redColor]];
        [btn setTitle:@"立即体验" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(hidde) forControlEvents:UIControlEventTouchUpInside];
        return btn;
    }];
    
//    [launchView skipBtnCustom:^UIButton * _Nonnull{
//        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        btn.frame = CGRectMake(60, 200, 120, 120);
//        [btn setBackgroundColor:[UIColor blueColor]];
//        [btn addTarget:self action:@selector(hidde) forControlEvents:UIControlEventTouchUpInside];
//        return btn;
//    }];
    
    return YES;
}

-(void)hidde{
    [_launchView hideGuidView];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
