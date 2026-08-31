// Code By VanNghia (Complete, Fixed & Updated with Layout from Reference)
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include <iostream>
#import <UIKit/UIKit.h>
#include <vector>
#import "pthread.h"
#include <array>
#import <os/log.h>
#include <cmath>
#include <deque>
#include <fstream>
#include <algorithm>
#include <string>
#include <sstream>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cstdint>
#include <cinttypes>
#include <cerrno>
#include <cctype>
#import <objc/message.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

#pragma clang diagnostic ignored "-Wunguarded-availability-new"
#pragma clang diagnostic ignored "-Wavailability"

#import "IMGUI/imgui.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/imgui_impl_metal.h"
#include "oxorany/oxorany_include.h"
#import "Helper/Vector3.h"
#import "Helper/Vector2.h"
#import "Helper/Quaternion.h"
#import "Helper/Monostring.h"
#include "Helper/font.h"
#include "Helper/data.h"

ImFont* verdana_smol;
ImFont* pixel_big = {};
ImFont* pixel_smol = {};

#import "Helper/Obfuscate.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <unistd.h>

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale  [UIScreen mainScreen].scale

static const CGFloat kSidebarWidth     = 64;
static const CGFloat kTabItemHeight    = 44;
static const CGFloat kTabSpacing       = 6;

// Declaración de variables globales del menú
static BOOL isDarkMode = YES;
static BOOL MenDeal = YES;
static float menuAlpha = 1.0f;
static float menuScale = 1.0f;

// Declaración de la clase principal
@interface ImGuiDrawView : UIViewController
+ (void)showChange:(BOOL)open;
@end

typedef NS_ENUM(NSInteger, MenuTab) {
    MenuTabAimbot = 0,
    MenuTabESP,
    MenuTabWorld,
    MenuTabSettings,
    MenuTabProfile,
    MenuTabExtra
};

@interface ImGuiDrawView () <MTKViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@property (nonatomic, strong) UIView *floatingPanel;
@property (nonatomic, strong) UIView *sidebarView;
@property (nonatomic, strong) UIView *sidebarBg;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, assign) MenuTab currentTab;
@property (nonatomic, strong) NSMutableArray *tabButtons;
@property (nonatomic, strong) NSMutableDictionary *checkboxStates;
@property (nonatomic, strong) UIButton *headerButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *themeButton;
@property (nonatomic, assign) CGFloat panelWidth;
@property (nonatomic, assign) CGFloat panelHeight;
@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UIImageView *headerIconView;

@end

@implementation ImGuiDrawView

ImFont *_espFont;

#pragma mark - Theme & Colors

- (UIColor *)backgroundColor {
    return isDarkMode ? [UIColor colorWithRed:0.09 green:0.09 blue:0.11 alpha:0.95] : [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:0.95];
}

- (UIColor *)textColor {
    return isDarkMode ? [UIColor colorWithWhite:0.92 alpha:1.0] : [UIColor blackColor];
}

- (UIColor *)secondaryTextColor {
    return [UIColor colorWithWhite:0.6 alpha:1.0];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.85 green:0.18 blue:0.22 alpha:1.0];
}

- (UIColor *)sidebarBackgroundColor {
    return isDarkMode ? [UIColor colorWithRed:0.07 green:0.07 blue:0.09 alpha:1.0] : [UIColor colorWithRed:0.90 green:0.90 blue:0.92 alpha:1.0];
}

- (UIColor *)sidebarButtonColor:(BOOL)selected {
    if (isDarkMode) {
        return selected ? [UIColor colorWithRed:0.14 green:0.14 blue:0.18 alpha:1.0] : [UIColor clearColor];
    } else {
        return selected ? [[self accentColor] colorWithAlphaComponent:0.15] : [UIColor clearColor];
    }
}

#pragma mark - Setup & Lifecycle

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    if (!self.device) abort();

    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.IniFilename = nullptr;

    static ImVector<ImWchar> gVietRanges;
    {
        ImFontGlyphRangesBuilder builder;
        builder.AddRanges(io.Fonts->GetGlyphRangesDefault());
        builder.AddRanges(io.Fonts->GetGlyphRangesVietnamese());
        builder.BuildRanges(&gVietRanges);
    }
    ImFontConfig cfg;
    cfg.OversampleH = 2; cfg.OversampleV = 2;
    
#ifdef DEF_FONT_SIZE
    ImFont* mainFont = io.Fonts->AddFontFromMemoryTTF((void*)DefaultFontData, (int)DefaultFontSize, 16.0f, &cfg, gVietRanges.Data);
    ImFont* bigFont  = io.Fonts->AddFontFromMemoryTTF((void*)DefaultFontData, (int)DefaultFontSize, 32.0f, &cfg, gVietRanges.Data);
#else
    ImFont* mainFont = io.Fonts->AddFontDefault();
    ImFont* bigFont  = io.Fonts->AddFontDefault();
#endif

    verdana_smol = mainFont;
    pixel_big    = bigFont;
    pixel_smol   = mainFont;

    ImGui_ImplMetal_Init(_device);
    return self;
}

+ (void)showChange:(BOOL)open {
    MenDeal = open;
}

- (MTKView *)mtkView { return (MTKView *)self.view; }

- (void)loadView {
    CGFloat w = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.width;
    CGFloat h = [UIApplication sharedApplication].windows[0].rootViewController.view.frame.size.height;
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
}

#pragma mark - Touch Forwarding to ImGui

- (void)updateIOWithTouchEvent:(UIEvent *)event {
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event { [self updateIOWithTouchEvent:event]; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mtkView.device          = self.device;
    self.mtkView.delegate        = self;
    self.mtkView.clearColor      = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor clearColor];
    self.mtkView.clipsToBounds   = YES;
    
    self.panelWidth  = 480;
    self.panelHeight = 270;
    self.currentTab = MenuTabAimbot;
    self.tabButtons = [NSMutableArray array];
    self.checkboxStates = [NSMutableDictionary dictionary];
    
    [self setupFloatingPanel];
    [self setupSidebar];
    [self setupHeaderBar];
    [self setupContentArea];
    
    [self loadTabContent:self.currentTab];
    [self updateSidebarForTab:self.currentTab];
}

#pragma mark - UIKit Setup

- (void)setupFloatingPanel {
    self.floatingPanel = [[UIView alloc] initWithFrame:CGRectMake(40, 40, self.panelWidth, self.panelHeight)];
    self.floatingPanel.backgroundColor = [self backgroundColor];
    self.floatingPanel.clipsToBounds = YES;
    self.floatingPanel.layer.cornerRadius = 14;
    self.floatingPanel.layer.masksToBounds = NO;
    self.floatingPanel.layer.borderWidth = 1.0;
    self.floatingPanel.layer.borderColor = [UIColor colorWithRed:0.25 green:0.12 blue:0.14 alpha:0.8].CGColor;
    
    self.floatingPanel.alpha = 1.0f;
    self.floatingPanel.transform = CGAffineTransformMakeScale(1.0f, 1.0f);

    [self.view addSubview:self.floatingPanel];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    [self.floatingPanel addGestureRecognizer:pan];
}

- (void)handleDrag:(UIPanGestureRecognizer *)g {
    UIView *v = g.view;
    CGPoint t = [g translationInView:v.superview];
    v.center = CGPointMake(v.center.x + t.x, v.center.y + t.y);
    [g setTranslation:CGPointZero inView:v.superview];
}

- (void)setupSidebar {
    self.sidebarBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kSidebarWidth, self.panelHeight)];
    self.sidebarBg.backgroundColor = [self sidebarBackgroundColor];
    [self.floatingPanel addSubview:self.sidebarBg];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(kSidebarWidth - 0.5, 0, 0.5, self.panelHeight)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    [self.sidebarBg addSubview:sep];

    NSArray *icons = @[@"scope", @"eye", @"cube", @"gearshape", @"person", @"square.and.arrow.down"];
    NSInteger count = icons.count;

    self.sidebarView = [[UIView alloc] initWithFrame:CGRectMake(0, 12, kSidebarWidth, self.panelHeight - 12)];
    [self.sidebarBg addSubview:self.sidebarView];

    for (int i = 0; i < (int)count; i++) {
        CGFloat btnY = i * (kTabItemHeight + kTabSpacing);
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(8, btnY, kSidebarWidth - 16, kTabItemHeight)];
        btn.backgroundColor = [self sidebarButtonColor:(i == self.currentTab)];
        btn.layer.cornerRadius = 10;
        btn.tag = i;

        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake((kSidebarWidth - 16 - 20)/2.0, (kTabItemHeight - 20)/2.0, 20, 20)];
        iv.image = [[UIImage systemImageNamed:icons[i]] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightMedium]];
        iv.tintColor = (i == self.currentTab) ? [UIColor colorWithRed:0.95 green:0.25 blue:0.28 alpha:1.0] : [UIColor colorWithWhite:0.5 alpha:1.0];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.tag = 100;
        [btn addSubview:iv];

        [btn addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebarView addSubview:btn];
        [self.tabButtons addObject:btn];
    }
}

- (void)setupHeaderBar {
    CGFloat hdrH = 44.0f;
    UIView *headerBar = [[UIView alloc] initWithFrame:CGRectMake(kSidebarWidth, 0, self.panelWidth - kSidebarWidth, hdrH)];
    headerBar.backgroundColor = [UIColor clearColor];
    [self.floatingPanel addSubview:headerBar];

    self.headerIconView = [[UIImageView alloc] initWithFrame:CGRectMake(12, (hdrH - 18)/2.0, 18, 18)];
    self.headerIconView.image = [[UIImage systemImageNamed:@"scope"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold]];
    self.headerIconView.tintColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.28 alpha:1.0];
    self.headerIconView.contentMode = UIViewContentModeScaleAspectFit;
    [headerBar addSubview:self.headerIconView];

    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, 150, hdrH)];
    self.headerTitleLabel.text = @"AIMBOT";
    self.headerTitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    self.headerTitleLabel.textColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.28 alpha:1.0];
    [headerBar addSubview:self.headerTitleLabel];

    CGFloat btnSize = 26.0f;
    CGFloat rightSpacing = 12.0f;
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(headerBar.frame.size.width - btnSize - rightSpacing, (hdrH - btnSize)/2.0f, btnSize, btnSize);
    self.closeButton.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.20 alpha:1.0];
    self.closeButton.layer.cornerRadius = btnSize / 2.0;
    [self.closeButton setImage:[[UIImage systemImageNamed:@"xmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [self.closeButton addTarget:self action:@selector(animateClose) forControlEvents:UIControlEventTouchUpInside];
    [headerBar addSubview:self.closeButton];

    self.themeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.themeButton.frame = CGRectMake(self.closeButton.frame.origin.x - btnSize - 8, (hdrH - btnSize)/2.0f, btnSize, btnSize);
    self.themeButton.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.20 alpha:1.0];
    self.themeButton.layer.cornerRadius = btnSize / 2.0;
    [self.themeButton setImage:[[UIImage systemImageNamed:@"moon.fill"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightMedium]] forState:UIControlStateNormal];
    self.themeButton.tintColor = [UIColor colorWithRed:0.95 green:0.25 blue:0.28 alpha:1.0];
    [self.themeButton addTarget:self action:@selector(toggleTheme) forControlEvents:UIControlEventTouchUpInside];
    [headerBar addSubview:self.themeButton];
}

- (void)setupContentArea {
    CGFloat hdrH = 44.0f;
    CGFloat h = self.panelHeight - hdrH;
    CGFloat w = self.panelWidth - kSidebarWidth;

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(kSidebarWidth, hdrH, w, h)];
    self.contentScrollView.showsVerticalScrollIndicator = YES;
    self.contentScrollView.alwaysBounceVertical = YES;
    [self.floatingPanel addSubview:self.contentScrollView];

    self.contentContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    [self.contentScrollView addSubview:self.contentContainer];
}

#pragma mark - Tab Logic

- (void)tabButtonTapped:(UIButton *)sender {
    if (sender.tag == self.currentTab) return;
    self.currentTab = (MenuTab)sender.tag;
    
    [self updateSidebarForTab:self.currentTab];
    [self loadTabContent:self.currentTab];
}

- (void)updateSidebarForTab:(MenuTab)tab {
    for (UIButton *btn in self.tabButtons) {
        UIImageView *iv = [btn viewWithTag:100];
        BOOL sel = (btn.tag == tab);
        iv.tintColor = sel ? [UIColor colorWithRed:0.95 green:0.25 blue:0.28 alpha:1.0] : [UIColor colorWithWhite:0.5 alpha:1.0];
        btn.backgroundColor = [self sidebarButtonColor:sel];
    }
    
    NSArray *titles = @[@"AIMBOT", @"ESP", @"WORLD", @"SETTINGS", @"PROFILE", @"EXTRA"];
    NSArray *icons = @[@"scope", @"eye", @"cube", @"gearshape", @"person", @"square.and.arrow.down"];
    if (tab < titles.count) {
        self.headerTitleLabel.text = titles[tab];
        self.headerIconView.image = [[UIImage systemImageNamed:icons[tab]] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightBold]];
    }
}

- (void)loadTabContent:(MenuTab)tab {
    for (UIView *v in self.contentContainer.subviews) [v removeFromSuperview];
    
    CGFloat w = self.contentScrollView.frame.size.width;
    CGFloat y = 8;
    
    switch (tab) {
        case MenuTabAimbot:
            y = [self addAimbotContent:y width:w];
            break;
        case MenuTabESP:
            y = [self addESPContent:y width:w];
            break;
        case MenuTabWorld:
            y = [self addPlaceholderContent:@"World & Visual Options" atY:y width:w];
            break;
        case MenuTabSettings:
            y = [self addPlaceholderContent:@"Menu Settings & Configs" atY:y width:w];
            break;
        case MenuTabProfile:
            y = [self addPlaceholderContent:@"Profile & License Info" atY:y width:w];
            break;
        case MenuTabExtra:
            y = [self addPlaceholderContent:@"Extra Utilities & Tools" atY:y width:w];
            break;
    }
    
    self.contentContainer.frame = CGRectMake(0, 0, w, y + 16);
    self.contentScrollView.contentSize = self.contentContainer.bounds.size;
}

#pragma mark - Content Builders

- (CGFloat)addAimbotContent:(CGFloat)y width:(CGFloat)w {
    y = [self addNoticeBanner:@"Hack Do MinhiOS Phát Triển. Cảm Ơn Đã Sử Dụng Phiên Bản Này" atY:y width:w];
    
    NSArray *options = @[@"Bật Aimbot", @"ab_silent", @"Không Aim Sau Tường", @"Kiểm Tra Địch", @"Bỏ qua địch gục"];
    
    CGFloat itemW = w - 24;
    CGFloat currentY = y;
    
    for (NSString *title in options) {
        CGFloat rowH = 34;
        [self addToggleItem:title atFrame:CGRectMake(12, currentY, itemW, rowH)];
        currentY += rowH + 6;
    }
    return currentY;
}

- (CGFloat)addESPContent:(CGFloat)y width:(CGFloat)w {
    NSArray *options = @[@"Enable Cheats", @"Box ESP", @"Line ESP", @"Name ESP", @"Skeleton ESP", @"Distance"];
    CGFloat itemW = w - 24;
    CGFloat currentY = y;
    
    for (NSString *title in options) {
        CGFloat rowH = 34;
        [self addToggleItem:title atFrame:CGRectMake(12, currentY, itemW, rowH)];
        currentY += rowH + 6;
    }
    return currentY;
}

- (CGFloat)addNoticeBanner:(NSString *)text atY:(CGFloat)y width:(CGFloat)w {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, y, w - 24, 28)];
    lbl.text = text;
    lbl.font = [UIFont fontWithName:@"Helvetica" size:10] ?: [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    lbl.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    lbl.numberOfLines = 1;
    [self.contentContainer addSubview:lbl];
    return y + 32;
}


- (CGFloat)addPlaceholderContent:(NSString *)text atY:(CGFloat)y width:(CGFloat)w {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(12, y + 20, w - 24, 40)];
    lbl.text = text;
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lbl.textColor = [self secondaryTextColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    [self.contentContainer addSubview:lbl];
    return y + 70;
}

- (void)addToggleItem:(NSString *)title atFrame:(CGRect)frame {
    UIView *container = [[UIView alloc] initWithFrame:frame];
    container.backgroundColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.16 alpha:1.0];
    container.layer.cornerRadius = 8;
    
    BOOL isOn = [self.checkboxStates[title] boolValue];
    
    CGFloat switchSize = 20.0f;
    UIButton *boxBtn = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - switchSize - 12, (frame.size.height - switchSize)/2.0, switchSize, switchSize)];
    boxBtn.backgroundColor = isOn ? [UIColor colorWithRed:0.85 green:0.18 blue:0.22 alpha:1.0] : [UIColor colorWithRed:0.22 green:0.22 blue:0.26 alpha:1.0];
    boxBtn.layer.cornerRadius = switchSize / 2.0;
    
    if (isOn) {
        [boxBtn setImage:[[UIImage systemImageNamed:@"checkmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:9 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
        boxBtn.tintColor = [UIColor whiteColor];
    }
    
    boxBtn.tag = 999;
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, frame.size.width - 50, frame.size.height)];
    titleLbl.text = title;
    titleLbl.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    titleLbl.textColor = [self textColor];
    
    UIButton *hitBox = [[UIButton alloc] initWithFrame:container.bounds];
    hitBox.accessibilityLabel = title;
    [hitBox addTarget:self action:@selector(toggleTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [container addSubview:titleLbl];
    [container addSubview:boxBtn];
    [container addSubview:hitBox];
    
    [self.contentContainer addSubview:container];
}

- (void)toggleTapped:(UIButton *)sender {
    UIView *container = sender.superview;
    UILabel *titleLbl = nil;
    UIButton *boxBtn = nil;
    
    for (UIView *sub in container.subviews) {
        if ([sub isKindOfClass:[UILabel class]]) titleLbl = (UILabel *)sub;
        if ([sub isKindOfClass:[UIButton class]] && sub.tag == 999) boxBtn = (UIButton *)sub;
    }
    
    if (titleLbl) {
        NSString *key = titleLbl.text;
        BOOL current = [self.checkboxStates[key] boolValue];
        BOOL newState = !current;
        self.checkboxStates[key] = @(newState);
        
        boxBtn.backgroundColor = newState ? [UIColor colorWithRed:0.85 green:0.18 blue:0.22 alpha:1.0] : [UIColor colorWithRed:0.22 green:0.22 blue:0.26 alpha:1.0];
        if (newState) {
            [boxBtn setImage:[[UIImage systemImageNamed:@"checkmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:9 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
            boxBtn.tintColor = [UIColor whiteColor];
        } else {
            [boxBtn setImage:nil forState:UIControlStateNormal];
        }
    }
}

#pragma mark - Actions

- (void)animateClose {
    MenDeal = false;
}

- (void)toggleTheme {
    isDarkMode = !isDarkMode;
    self.floatingPanel.backgroundColor = [self backgroundColor];
    self.sidebarBg.backgroundColor = [self sidebarBackgroundColor];
    [self updateSidebarForTab:self.currentTab];
    [self loadTabContent:self.currentTab];
}

#pragma mark - Render Loop

- (void)drawInMTKView:(MTKView*)view {
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    CGFloat fbScale  = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    io.DisplayFramebufferScale = ImVec2(fbScale, fbScale);
    io.DeltaTime = 1.0f / float(view.preferredFramesPerSecond ?: 60);

    static BOOL lastMenDeal = YES;
    if ((BOOL)MenDeal != lastMenDeal) {
        lastMenDeal = (BOOL)MenDeal;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.floatingPanel.hidden        = !MenDeal;
            self.view.userInteractionEnabled =  MenDeal;
        });
    }

    id<MTLCommandBuffer> cmdBuf = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor* rpd = view.currentRenderPassDescriptor;

    if (rpd != nil) {
        id<MTLRenderCommandEncoder> enc = [cmdBuf renderCommandEncoderWithDescriptor:rpd];
        [enc pushDebugGroup:@"ImGui"];

        ImGui_ImplMetal_NewFrame(rpd);
        ImGui::NewFrame();

        ImGui::GetBackgroundDrawList();

        ImGui::Render();
        ImDrawData* dd = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(dd, cmdBuf, enc);

        [enc popDebugGroup];
        [enc endEncoding];
        [cmdBuf presentDrawable:view.currentDrawable];
    }
    [cmdBuf commit];
}

- (void)mtkView:(MTKView*)view drawableSizeWillChange:(CGSize)size {}

@end
