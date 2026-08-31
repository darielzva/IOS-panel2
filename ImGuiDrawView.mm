// Code By VanNghia (Updated for Reference UI Structure)
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

#include "Helper/Obfuscate.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <unistd.h>

#define kWidth  [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale  [UIScreen mainScreen].scale

static const CGFloat kSidebarWidth     = 96;
static const CGFloat kTabItemHeight    = 48;
static const CGFloat kTabSpacing       = 4;
static const CGFloat kContentPadding   = 12;

typedef NS_ENUM(NSInteger, MenuTab) {
    MenuTabInfo = 0,
    MenuTabESP,
    MenuTabAimbot,
    MenuTabSkin,
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
@property (nonatomic, assign) CGFloat panelWidth;
@property (nonatomic, assign) CGFloat panelHeight;

@end

@implementation ImGuiDrawView

ImFont *_espFont;

#pragma mark - Theme & Colors

- (UIColor *)backgroundColor {
    return isDarkMode ? [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:1.0] : [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0];
}

- (UIColor *)textColor {
    return isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
}

- (UIColor *)secondaryTextColor {
    return [UIColor colorWithWhite:0.6 alpha:1.0];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.18 green:0.42 blue:0.75 alpha:1.0];
}

- (UIColor *)pillColor {
    return isDarkMode ? [UIColor colorWithRed:0.11 green:0.12 blue:0.16 alpha:1.0] : [UIColor colorWithWhite:0.92 alpha:1.0];
}

- (UIColor *)sidebarBackgroundColor {
    return isDarkMode ? [UIColor colorWithRed:0.09 green:0.10 blue:0.14 alpha:1.0] : [UIColor colorWithRed:0.90 green:0.90 blue:0.92 alpha:1.0];
}

- (UIColor *)sidebarButtonColor:(BOOL)selected {
    if (isDarkMode) {
        return selected ? [UIColor colorWithRed:0.13 green:0.31 blue:0.58 alpha:1.0] : [UIColor colorWithRed:0.09 green:0.10 blue:0.14 alpha:1.0];
    } else {
        return selected ? [[self accentColor] colorWithAlphaComponent:0.15] : [UIColor whiteColor];
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
    ImFont* mainFont = io.Fonts->AddFontFromMemoryTTF((void*)NotoSansViet, (int)sizeof(NotoSansViet), 16.0f, &cfg, gVietRanges.Data);
    ImFont* bigFont = io.Fonts->AddFontFromMemoryTTF((void*)NotoSansViet, (int)sizeof(NotoSansViet), 32.0f, &cfg, gVietRanges.Data);

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
    
    self.panelWidth  = 460;
    self.panelHeight = 310;
    self.currentTab = MenuTabESP;
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
    self.floatingPanel = [[UIView alloc] initWithFrame:CGRectMake(30, 40, self.panelWidth, self.panelHeight)];
    self.floatingPanel.backgroundColor = [self backgroundColor];
    self.floatingPanel.clipsToBounds = YES;
    self.floatingPanel.layer.masksToBounds = NO;
    self.floatingPanel.layer.borderWidth = 1.0;
    self.floatingPanel.layer.borderColor = [UIColor colorWithRed:0.22 green:0.32 blue:0.5 alpha:0.6].CGColor;
    
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
    self.sidebarBg = [[UIView alloc] initWithFrame:CGRectMake(0, 40, kSidebarWidth, self.panelHeight - 40)];
    self.sidebarBg.backgroundColor = [self sidebarBackgroundColor];
    [self.floatingPanel addSubview:self.sidebarBg];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(kSidebarWidth - 0.5, 0, 0.5, self.panelHeight - 40)];
    sep.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    [self.sidebarBg addSubview:sep];

    NSArray *titles = @[@"Info", @"ESP", @"AimBot", @"Skin", @"Extra"];
    NSArray *icons  = @[@"info.circle", @"scope", @"target", @"person.crop.rectangle", @"square.grid.2x2"];
    NSInteger count = titles.count;

    self.sidebarView = [[UIView alloc] initWithFrame:CGRectMake(0, 8, kSidebarWidth, self.panelHeight - 48)];
    [self.sidebarBg addSubview:self.sidebarView];

    for (int i = 0; i < (int)count; i++) {
        CGFloat btnY = i * (kTabItemHeight + kTabSpacing);
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(6, btnY, kSidebarWidth - 12, kTabItemHeight)];
        btn.backgroundColor = [self sidebarButtonColor:(i == self.currentTab)];
        btn.layer.cornerRadius = 8;
        btn.tag = i;

        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(12, 8, 18, 18)];
        iv.image = [[UIImage systemImageNamed:icons[i]] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:14 weight:UIImageSymbolWeightMedium]];
        iv.tintColor = (i == self.currentTab) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.tag = 100;
        [btn addSubview:iv];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 26, kSidebarWidth - 20, 16)];
        lbl.text = titles[i];
        lbl.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        lbl.textColor = (i == self.currentTab) ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.tag = 101;
        [btn addSubview:lbl];

        [btn addTarget:self action:@selector(tabButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebarView addSubview:btn];
        [self.tabButtons addObject:btn];
    }
}

- (void)setupHeaderBar {
    CGFloat hdrH = 40.0f;
    UIView *headerBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.panelWidth, hdrH)];
    headerBar.backgroundColor = [UIColor colorWithRed:0.12 green:0.24 blue:0.44 alpha:1.0];
    [self.floatingPanel addSubview:headerBar];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.panelWidth - 60, hdrH)];
    titleLabel.text = @"VN TOOL IPA VIP";
    titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
    titleLabel.textColor = [UIColor whiteColor];
    [headerBar addSubview:titleLabel];

    CGFloat closeBtnSize = 24.0f;
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(self.panelWidth - 32, (hdrH - closeBtnSize)/2.0f, closeBtnSize, closeBtnSize];
    [self.closeButton setImage:[[UIImage systemImageNamed:@"xmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor whiteColor];
    [self.closeButton addTarget:self action:@selector(animateClose) forControlEvents:UIControlEventTouchUpInside];
    [headerBar addSubview:self.closeButton];
}

- (void)setupContentArea {
    CGFloat hdrH = 40.0f;
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
        UILabel *lbl = [btn viewWithTag:101];
        BOOL sel = (btn.tag == tab);
        iv.tintColor = sel ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
        lbl.textColor = sel ? [UIColor whiteColor] : [UIColor colorWithWhite:0.6 alpha:1.0];
        btn.backgroundColor = [self sidebarButtonColor:sel];
    }
}

- (void)loadTabContent:(MenuTab)tab {
    for (UIView *v in self.contentContainer.subviews) [v removeFromSuperview];
    
    CGFloat w = self.contentScrollView.frame.size.width;
    CGFloat y = 14;
    
    switch (tab) {
        case MenuTabInfo:
            y = [self addInfoContent:y width:w];
            break;
        case MenuTabESP:
            y = [self addESPContent:y width:w];
            break;
        case MenuTabAimbot:
            y = [self addPlaceholderContent:@"AimBot Options" atY:y width:w];
            break;
        case MenuTabSkin:
            y = [self addPlaceholderContent:@"Skin Options" atY:y width:w];
            break;
        case MenuTabExtra:
            y = [self addPlaceholderContent:@"Extra Options" atY:y width:w];
            break;
    }
    
    self.contentContainer.frame = CGRectMake(0, 0, w, y + 20);
    self.contentScrollView.contentSize = self.contentContainer.bounds.size;
}

#pragma mark - Content Builders

- (CGFloat)addESPContent:(CGFloat)y width:(CGFloat)w {
    NSArray *leftColumn = @[@"Enable Cheats", @"Line", @"Name", @"3D Circle", @"Count"];
    NSArray *rightColumn = @[@"Box", @"Skeleton", @"Outline"];
    
    CGFloat colWidth = (w - 30) / 2.0;
    CGFloat leftX = 12;
    CGFloat rightX = leftX + colWidth + 10;
    
    CGFloat currentY = y;
    NSInteger maxRows = MAX(leftColumn.count, rightColumn.count);
    
    for (int i = 0; i < maxRows; i++) {
        CGFloat rowH = 32;
        if (i < leftColumn.count) {
            [self addCheckboxItem:leftColumn[i] atFrame:CGRectMake(leftX, currentY, colWidth, rowH)];
        }
        if (i < rightColumn.count) {
            [self addCheckboxItem:rightColumn[i] atFrame:CGRectMake(rightX, currentY, colWidth, rowH)];
        }
        currentY += rowH + 8;
    }
    return currentY;
}

- (CGFloat)addInfoContent:(CGFloat)y width:(CGFloat)w {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, y, w - 28, 60)];
    lbl.text = @"Welcome to VN TOOL IPA VIP.\nSelect a category from the sidebar to configure options.";
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lbl.textColor = [self textColor];
    lbl.numberOfLines = 0;
    [self.contentContainer addSubview:lbl];
    return y + 70;
}

- (CGFloat)addPlaceholderContent:(NSString *)text atY:(CGFloat)y width:(CGFloat)w {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, y, w - 28, 40)];
    lbl.text = text;
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    lbl.textColor = [self secondaryTextColor];
    [self.contentContainer addSubview:lbl];
    return y + 50;
}

- (void)addCheckboxItem:(NSString *)title atFrame:(CGRect)frame {
    UIView *container = [[UIView alloc] initWithFrame:frame];
    
    BOOL isOn = [self.checkboxStates[title] boolValue];
    
    UIButton *boxBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, (frame.size.height - 22)/2.0, 22, 22)];
    boxBtn.backgroundColor = isOn ? [UIColor colorWithRed:0.18 green:0.42 blue:0.75 alpha:1.0] : [UIColor colorWithRed:0.15 green:0.16 blue:0.22 alpha:1.0];
    boxBtn.layer.cornerRadius = 6;
    boxBtn.layer.borderWidth = 1.0;
    boxBtn.layer.borderColor = [UIColor colorWithRed:0.25 green:0.35 blue:0.55 alpha:1.0].CGColor;
    
    if (isOn) {
        [boxBtn setImage:[[UIImage systemImageNamed:@"checkmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
        boxBtn.tintColor = [UIColor whiteColor];
    }
    
    boxBtn.tag = 999;
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(30, 0, frame.size.width - 30, frame.size.height)];
    titleLbl.text = title;
    titleLbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    titleLbl.textColor = [self textColor];
    
    UIButton *hitBox = [[UIButton alloc] initWithFrame:container.bounds];
    hitBox.accessibilityLabel = title;
    [hitBox addTarget:self action:@selector(checkboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [container addSubview:boxBtn];
    [container addSubview:titleLbl];
    [container addSubview:hitBox];
    
    [self.contentContainer addSubview:container];
}

- (void)checkboxTapped:(UIButton *)sender {
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
        
        boxBtn.backgroundColor = newState ? [UIColor colorWithRed:0.18 green:0.42 blue:0.75 alpha:1.0] : [UIColor colorWithRed:0.15 green:0.16 blue:0.22 alpha:1.0];
        if (newState) {
            [boxBtn setImage:[[UIImage systemImageNamed:@"checkmark"] imageByApplyingSymbolConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightBold]] forState:UIControlStateNormal];
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
