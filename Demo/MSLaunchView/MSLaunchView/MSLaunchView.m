//
//  MSLaunchView.m
//  MSLaunchView
//
//  Created by TuBo on 2018/11/8.
//  Copyright © 2018 TuBur. All rights reserved.
//

#import "MSLaunchView.h"
#import "MSLaunchOperation.h"
#import "MSPageControl.h"
#import "MSAnimatedDotView.h"

#define MSHidden_TIME 1.0
#define MSScreenW   [UIScreen mainScreen].bounds.size.width
#define MSScreenH   [UIScreen mainScreen].bounds.size.height

#define MS_LAZY(object,assignment) (object = object ?:assignment)
#define kCycleScrollViewInitialPageControlDotSize CGSizeMake(8, 8)

@interface MSLaunchView()<UIScrollViewDelegate>{
    UIImageView *launchView;//获取到最后一个imageView 添加自定义按钮
    //
    CGFloat oldlastContentOffset;
    CGFloat newlastContentOffset;
    
    CGRect guideFrame;//
    CGRect videoFrame;
    UIImage *gbgImage;//按钮背景图片
}
@property (nonatomic, strong) UIButton *skipButton;//跳过按钮
@property (nonatomic, strong) UIButton *guideButton;//立即进入按钮
@property (nonatomic, weak) UIControl *pageControl;
@property (nonatomic, strong) AVPlayerViewController  *playerController;//视频播放
@property (nonatomic, copy) NSMutableArray<NSString *> *dataImages; //图片数据
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, assign) BOOL isScrollOut;//是否左滑推出
@end

static NSString *const kAppVersion = @"appVersion";

@implementation MSLaunchView

#pragma mark - 创建对象-->>不带button 左滑动消失
+(instancetype)launchWithImages:(NSArray <NSString *>*)images{
    return [[MSLaunchView alloc] initWithVideoframe:CGRectZero guideFrame:CGRectZero images:images gImage:nil sbName:nil videoUrl:nil isScrollOut:YES];
}

#pragma mark - 创建对象-->>带button 左滑动不消失
+(instancetype)launchWithImages:(NSArray <NSString *>*)images guideFrame:(CGRect)gframe  gImage:(UIImage *)gImage{
    return [[MSLaunchView alloc] initWithVideoframe:CGRectZero guideFrame:gframe images:images gImage:gImage sbName:nil videoUrl:nil isScrollOut:NO];
}



#pragma mark - 用storyboard创建的项目时调用，不带button 左滑动消失
+(instancetype)launchWithImages:(NSArray <NSString *>*)images sbName:(NSString *)sbName{
    return [[MSLaunchView alloc] initWithVideoframe:CGRectZero guideFrame:CGRectZero images:images gImage:nil sbName:![MSLaunchView isBlankString:sbName]? sbName:@"Main" videoUrl:nil isScrollOut:YES];
}

#pragma mark - 用storyboard创建的项目时调用，带button左滑动不消失
+(instancetype)launchWithImages:(NSArray <NSString *>*)images sbName:(NSString *)sbName guideFrame:(CGRect)gframe gImage:(UIImage *)gImage{
    return [[MSLaunchView alloc] initWithVideoframe:CGRectZero guideFrame:gframe images:images gImage:nil sbName:![MSLaunchView isBlankString:sbName]? sbName:@"Main" videoUrl:nil isScrollOut:NO];
}


#pragma  mark - 关于Video引导页

#pragma mark - 创建对象，不带button 左滑动消失
+ (instancetype)launchWithVideo:(CGRect)videoFrame videoURL:(NSURL *)videoURL{
    return [[MSLaunchView alloc] initWithVideoframe:videoFrame guideFrame:CGRectZero images:nil gImage:nil sbName:nil videoUrl:videoURL isScrollOut:YES];
}

#pragma mark - 创建对象，不带button 左滑动不消失
+ (instancetype)launchWithVideo:(CGRect)videoFrame videoURL:(NSURL *)videoURL guideFrame:(CGRect)gframe gImage:(UIImage *)gImage{
    return [[MSLaunchView alloc] initWithVideoframe:videoFrame guideFrame:gframe images:nil gImage:gImage sbName:nil videoUrl:videoURL isScrollOut:NO];
}


#pragma mark - 用storyboard创建的项目时调用，不带button左滑动消失
+ (instancetype)launchWithVideo:(CGRect)videoFrame videoURL:(NSURL *)videoURL sbName:(NSString *)sbName{
    return [[MSLaunchView alloc] initWithVideoframe:videoFrame guideFrame:CGRectZero images:nil gImage:nil sbName:![MSLaunchView isBlankString:sbName]? sbName:@"Main" videoUrl:videoURL isScrollOut:YES];
}

#pragma mark - 用storyboard创建的项目时调用，带button左滑动不消失
+ (instancetype)launchWithVideo:(CGRect)videoFrame videoURL:(NSURL *)videoURL sbName:(NSString *)sbName guideFrame:(CGRect)gframe gImage:(UIImage *)gImage {
    return [[MSLaunchView alloc] initWithVideoframe:videoFrame guideFrame:gframe images:nil gImage:gImage sbName:![MSLaunchView isBlankString:sbName]? sbName:@"Main" videoUrl:videoURL isScrollOut:NO];
}


#pragma mark - 初始化
- (instancetype)initWithVideoframe:(CGRect)frame guideFrame:(CGRect)gframe images:(NSArray <NSString *>*)images gImage:(UIImage *)gImage sbName:(NSString *)sbName videoUrl:(NSURL *)videoUrl isScrollOut:(BOOL)isScrollOut{
    self = [super init];
    if (self) {
        
        
        self.frame = CGRectMake(0, 0, MSScreenW, MSScreenH);
        self.backgroundColor = [UIColor whiteColor];
        if (images.count>0) {
            self.dataImages = [NSMutableArray arrayWithArray:images];
        }
        
        //初始化默认数据
        [self initialization];
        
        self.videoUrl = videoUrl;
        videoFrame = frame;
        guideFrame = gframe;
        gbgImage = gImage;
        self.isScrollOut = isScrollOut;
        self.isPalyEndOut = YES;
        self.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        
        if ([self isFirstLauch]) {
            UIWindow *window = [UIApplication sharedApplication].windows.lastObject;
            
            if (sbName != nil) {
                UIStoryboard *story = [UIStoryboard storyboardWithName:sbName bundle:nil];
                UIViewController * vc = story.instantiateInitialViewController;
                window.rootViewController = vc;
                [vc.view addSubview:self];
            }else{
                [window addSubview:self];
            }

            if (videoUrl && images == nil) {
                [self addVideo];
            }else{
                [self addImages];
            }
        }else{
            [self removeGuidePageHUD];
        }
    }
    return self;
}

- (void)initialization{
    
    self.backgroundColor = [UIColor lightGrayColor];
    
    _showPageControl = YES;
    _pageControlDotSize = kCycleScrollViewInitialPageControlDotSize;
    _pageControlBottomOffset = 15;
    _pageControlStyle = kMSPageContolStyleClassic;
    _hidesForSinglePage = YES;
    _currentPageDotColor = [UIColor whiteColor];
    _pageDotColor = [UIColor lightGrayColor];
    _dotViewClass = [MSAnimatedDotView class];
}


#pragma mark - 判断是不是首次登录或者版本更新
-(BOOL)isFirstLauch{
    //获取当前版本号
    NSDictionary *infoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *currentAppVersion = infoDic[@"CFBundleShortVersionString"];
    //获取上次启动应用保存的appVersion
    NSString *version = [[NSUserDefaults standardUserDefaults] objectForKey:kAppVersion];
    //版本升级或首次登录
    if ([MSLaunchView isBlankString:version] || ![version isEqualToString:currentAppVersion]) {
        [[NSUserDefaults standardUserDefaults] setObject:currentAppVersion forKey:kAppVersion];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return YES;
    }else{
        return NO;
    }
}

#pragma mark - 创建滚动视图、添加引导页图片
-(void)addImages{
    
    UIScrollView *launchScrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    launchScrollView.showsHorizontalScrollIndicator = NO;
    launchScrollView.bounces = NO;
    launchScrollView.pagingEnabled = YES;
    launchScrollView.delegate = self;
    launchScrollView.contentSize = CGSizeMake(MSScreenW * self.dataImages.count, MSScreenH);
    [self addSubview:launchScrollView];
    
    for (int i = 0; i < self.dataImages.count; i ++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * MSScreenW, 0, MSScreenW, MSScreenH)];
        if ([[MSLaunchOperation ms_contentTypeForImageData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.dataImages[i] ofType:nil]]] isEqualToString:@"gif"]) {
            NSData *localData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.dataImages[i] ofType:nil]];
            imageView = (UIImageView *)[[MSLaunchOperation alloc] initWithFrame:imageView.frame gifImageData:localData];
            [launchScrollView addSubview:imageView];
        } else {
            imageView.image = [UIImage imageNamed:self.dataImages[i]];
            [launchScrollView addSubview:imageView];
        }
        
        if (i == self.dataImages.count - 1) {
            //拿到最后一个图片，添加自定义体验按钮
            launchView = imageView;
            
            //判断要不要添加button
            if (!self.isScrollOut) {
                [imageView setUserInteractionEnabled:YES];
                [imageView addSubview:self.guideButton];
            }
        }
    }
    
    [self addSubview:self.skipButton];
    
    [self setupPageControl];
}


#pragma mark - APP视频新特性页面(新增测试模块内容)
-(void)addVideo{
    
    [self addSubview:self.playerController.view];
    [self addSubview:self.guideButton];

    [UIView animateWithDuration:MSHidden_TIME animations:^{
        [self.guideButton setAlpha:1.0];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideGuidView) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    [self addSubview:self.skipButton];

}

#pragma mark -- >> 自定义属性设置

#pragma mark - 跳过按钮的简单设置
-(void)setSkipTitle:(NSString *)skipTitle{
    [self.skipButton setTitle:skipTitle forState:UIControlStateNormal];
}

-(void)setSkipBackgroundClolr:(UIColor *)skipBackgroundClolr{
    [self.skipButton setBackgroundColor:skipBackgroundClolr];
}

-(void)setIsHiddenSkipBtn:(BOOL)isHiddenSkipBtn{
    self.skipButton.hidden = isHiddenSkipBtn;
}

-(void)skipBtnCustom:(UIButton *(^)(void))btn{
    [self.skipButton removeFromSuperview];
    [self addSubview:btn()];
}


#pragma mark - 立即体验按钮的简单设置
-(void)setGuideTitle:(NSString *)guideTitle{
    [self.guideButton setTitle:guideTitle forState:UIControlStateNormal];
}

-(void)setGuideBackgroundImage:(UIImage *)guideBackgroundImage{
    [self.guideButton setBackgroundImage:guideBackgroundImage forState:UIControlStateNormal];
}

-(void)setGuideTitleColor:(UIColor *)guideTitleColor{
    [self.guideButton setTitleColor:guideTitleColor forState:UIControlStateNormal];
}

#pragma mark - 自定义进入按钮
-(void)guideBtnCustom:(UIButton *(^)(void))btn{
    
    if(guideFrame.size.height || guideFrame.origin.x) return;
    
    //移除当前的体验按钮
    [self.guideButton removeFromSuperview];
    if (_videoUrl) {
        [self addSubview:btn()];
    }else{
        [launchView addSubview:btn()];
    }
}

#pragma mark - UIPageControl简单设置
-(void)setDotViewClass:(Class)dotViewClass{
    _dotViewClass = dotViewClass;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        pageControl.dotViewClass = dotViewClass;
    }
}

-(void)setCurrentPageDotColor:(UIColor *)currentPageDotColor{
    _currentPageDotColor = currentPageDotColor;
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        pageControl.dotColor = currentPageDotColor;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPageIndicatorTintColor = currentPageDotColor;
    }
}

-(void)setSpacingBetweenDots:(CGFloat)spacingBetweenDots{
    _spacingBetweenDots = spacingBetweenDots;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        pageControl.spacingBetweenDots = spacingBetweenDots;
    }
}

- (void)setShowPageControl:(BOOL)showPageControl
{
    _showPageControl = showPageControl;
    
    _pageControl.hidden = !showPageControl;
}


- (void)setPageControlDotSize:(CGSize)pageControlDotSize
{
    _pageControlDotSize = pageControlDotSize;
    [self setupPageControl];
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageContol = (MSPageControl *)_pageControl;
        pageContol.pageDotSize = pageControlDotSize;
    }
}

- (void)setCustomPageControlDotImage:(UIImage *)image isCurrentPageDot:(BOOL)isCurrentPageDot
{
    if (!image || !self.pageControl) return;
    
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        if (isCurrentPageDot) {
            pageControl.currentDotImage = image;
        } else {
            pageControl.dotImage = image;
        }
    }
}

-(void)setPageControlStyle:(kMSPageContolStyle)pageControlStyle{
    _pageControlStyle = pageControlStyle;
    
    [self setupPageControl];
}


#pragma mark - UIPageControl简单设置


-(void)setVideoGravity:(AVLayerVideoGravity)videoGravity{
    self.playerController.videoGravity = videoGravity;
}

-(void)setIsPalyEndOut:(BOOL)isPalyEndOut{
    if (!isPalyEndOut) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

#pragma mark - 隐藏引导页

-(void)hideGuidView{
    
    [UIView animateWithDuration:MSHidden_TIME animations:^{
        self.alpha = 0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MSHidden_TIME * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSelector:@selector(removeGuidePageHUD) withObject:nil afterDelay:1];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)removeGuidePageHUD {
    //解决第二次进入视屏不显示还能听到声音的BUG
    if (self.videoUrl) {
        self.playerController = nil;
    }
    [self removeFromSuperview];
}



#pragma mark - ScrollerView Delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    oldlastContentOffset = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    newlastContentOffset = scrollView.contentOffset.x;
    int cuttentIndex = (int)(oldlastContentOffset/MSScreenW);
    
    if (cuttentIndex == self.dataImages.count - 1) {
        if ([self isScrolltoLeft:scrollView]) {
            if (!self.isScrollOut) {
                return ;
            }
            [self hideGuidView];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    int cuttentIndex = (int)(scrollView.contentOffset.x/MSScreenW);
   
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        pageControl.currentPage = cuttentIndex;
    } else {
        UIPageControl *pageControl = (UIPageControl *)_pageControl;
        pageControl.currentPage = cuttentIndex;
    }
}



#pragma mark - 判断滚动方向
-(BOOL)isScrolltoLeft:(UIScrollView *)scrollView{
    if (oldlastContentOffset - newlastContentOffset >0 ){
        return NO;
    }
    return YES;
}

#pragma mark - prvite void
//判断字符串是否为空
+ (BOOL)isBlankString:(NSString *)string{
    
    if (string == nil || string == NULL) {
        return YES;
    }
    
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] ==0) {
        return YES;
    }
    
    return NO;
}

- (void)setupPageControl
{
    if (_pageControl) [_pageControl removeFromSuperview]; // 重新加载数据时调整
    
    if (!self.showPageControl) return;
    
    if (self.dataImages.count == 0) return;
//
    if ((self.dataImages.count == 1) && self.hidesForSinglePage) return;
    
    switch (self.pageControlStyle) {
        case kMSPageContolStyleAnimated:
        {
            MSPageControl *pageControl = [[MSPageControl alloc] init];
            pageControl.numberOfPages = self.dataImages.count;
            pageControl.dotColor = self.currentPageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = 0;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
            
        case kMSPageContolStyleClassic:
        {
            UIPageControl *pageControl = [[UIPageControl alloc] init];
            pageControl.numberOfPages = self.dataImages.count;
            pageControl.currentPageIndicatorTintColor = self.currentPageDotColor;
            pageControl.pageIndicatorTintColor = self.pageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = 0;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
        case kMSPageContolStyleCustomer:
        {
            MSPageControl *pageControl = [[MSPageControl alloc] init];
            pageControl.numberOfPages = self.dataImages.count;
            pageControl.dotColor = self.currentPageDotColor;
            pageControl.userInteractionEnabled = NO;
            pageControl.currentPage = 0;
            pageControl.dotViewClass = self.dotViewClass;
            [self addSubview:pageControl];
            _pageControl = pageControl;
        }
            break;
        default:
            break;
    }
    
    // 重设pagecontroldot图片
    if (self.currentPageDotImage) {
        self.currentPageDotImage = self.currentPageDotImage;
    }
    if (self.pageDotImage) {
        self.pageDotImage = self.pageDotImage;
    }
}

- (void)layoutSubviews{
    
    [super layoutSubviews];
    
    CGSize size = CGSizeZero;
    
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        if (!(self.pageDotImage && self.currentPageDotImage && CGSizeEqualToSize(kCycleScrollViewInitialPageControlDotSize, self.pageControlDotSize))) {
            pageControl.pageDotSize = self.pageControlDotSize;
        }
        size = [pageControl sizeForNumberOfPages:self.dataImages.count];
    } else {
        size = CGSizeMake(self.dataImages.count * self.pageControlDotSize.width * 1.5, self.pageControlDotSize.height);
    }
    CGFloat x = (self.frame.size.width - size.width) * 0.5;
//    if (self.pageControlAliment == kMSPageContolAlimentRight) {
//        x = self.mainView.sd_width - size.width - 10;
//    }
    CGFloat y = self.frame.size.height - size.height - 10;
    
    if ([self.pageControl isKindOfClass:[MSPageControl class]]) {
        MSPageControl *pageControl = (MSPageControl *)_pageControl;
        [pageControl sizeToFit];
    }
    
    CGRect pageControlFrame = CGRectMake(x, y, size.width, size.height);
    pageControlFrame.origin.y -= self.pageControlBottomOffset;
//    pageControlFrame.origin.x -= self.pageControlRightOffset;
    self.pageControl.frame = pageControlFrame;
    self.pageControl.hidden = !_showPageControl;
    
}

#pragma mark - >> 懒加载部分

#pragma mark - 跳过按钮
-(UIButton *)skipButton{
    return MS_LAZY(_skipButton, ({
        // 设置引导页上的跳过按钮
        UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeCustom];
        skipButton.frame = CGRectMake(MSScreenW*0.8, MSScreenW*0.1, 50, 25);
        [skipButton setTitle:@"跳过" forState:UIControlStateNormal];
        [skipButton.titleLabel setFont:[UIFont systemFontOfSize:14.0]];
        [skipButton setBackgroundColor:[UIColor grayColor]];
        [skipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [skipButton.layer setCornerRadius:(skipButton.frame.size.height * 0.5)];
        [skipButton addTarget:self action:@selector(hideGuidView) forControlEvents:UIControlEventTouchUpInside];
        skipButton;
    }));
}

#pragma mark - 进入按钮
-(UIButton *)guideButton{
    return MS_LAZY(_guideButton, ({
        // 设置引导页上的跳过按钮
        //CGRectMake(MSScreenW*0.3, MSScreenH*0.8, MSScreenW*0.4, MSScreenH*0.08)
        UIButton *guideButton = [UIButton buttonWithType:UIButtonTypeCustom];
        guideButton.frame = guideFrame;
        [guideButton setTitle:@"开始体验" forState:UIControlStateNormal];
        [guideButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [guideButton setBackgroundImage:gbgImage forState:UIControlStateNormal];
        [guideButton.titleLabel setFont:[UIFont systemFontOfSize:21]];
        [guideButton addTarget:self action:@selector(hideGuidView) forControlEvents:UIControlEventTouchUpInside];
        guideButton;
    }));
}


#pragma mark - 视频播放VC
-(AVPlayerViewController *)playerController{
    return MS_LAZY(_playerController, ({
        AVPlayerViewController *playerController = [[AVPlayerViewController alloc] init];
        playerController.view.frame = videoFrame;
        playerController.view.backgroundColor = [UIColor whiteColor];
        [playerController.view setAlpha:1.0];
        playerController.player = [[AVPlayer alloc] initWithURL:self.videoUrl];
        playerController.videoGravity = self.videoGravity;
        playerController.showsPlaybackControls = NO;
        [playerController.player play];
        playerController;
    }));
}

@end


