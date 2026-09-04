// safarisettingsdd
// safari chrome options. both features off until enabled in settings.

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define SSD_ID "com.safarisettingsdd.safarisettingsdd"
#define SSD_NOTIFY "com.safarisettingsdd.safarisettingsdd/ReloadPrefs"

@interface _SFSiteIconView : UIView
- (void)setImage:(UIImage *)image;
@end
@interface SFSiteIconView : UIView
- (void)setImage:(UIImage *)image;
@end
@interface SiteIconView : UIView
- (void)setImage:(UIImage *)image;
@end
@interface _SFFaviconView : UIView
- (void)setImage:(UIImage *)image;
@end
@interface SFFaviconView : UIView
- (void)setImage:(UIImage *)image;
@end
@interface BookmarkFavoriteView : UIView
@end
@interface BookmarkFavoritesGridView : UIView
@end
@interface CompletionListTableViewCell : UITableViewCell
@end
@interface UnifiedFieldCompletionListCell : UITableViewCell
@end
@interface TabBarItemView : UIView
@end
@interface TabOverviewItemView : UIView
@end
@interface TabThumbnailView : UIView
@end
@interface SFTabOverviewItemView : UIView
@end
@interface _SFTabOverviewItemView : UIView
@end
@interface _SFWebView : WKWebView
@end
@interface TabDocument : NSObject
- (id)webView;
@end
@interface BrowserController : NSObject
@end
@interface WKWebView (SSDPrivate)
- (void)_setPullToRefreshEnabled:(BOOL)enabled;
@end

static const void *kSSDHidden = &kSSDHidden;

static BOOL gHideFavicons = NO;
static BOOL gDisablePtr = NO;
static void ssd_apply_ptr(void);

#pragma mark - prefs

static BOOL ssd_bool(NSDictionary *prefs, NSString *key) {
    id value = prefs[key];
    if (![value isKindOfClass:[NSNumber class]]) {
        return NO;
    }
    return [value boolValue];
}

static NSDictionary *ssd_prefs_disk(void) {
    NSArray<NSString *> *paths = @[
        @"/var/jb/var/mobile/Library/Preferences/" @SSD_ID @".plist",
        @"/var/jb/mobile/Library/Preferences/" @SSD_ID @".plist",
        @"/var/mobile/Library/Preferences/" @SSD_ID @".plist"
    ];
    for (NSString *path in paths) {
        NSDictionary *disk = [NSDictionary dictionaryWithContentsOfFile:path];
        if ([disk isKindOfClass:[NSDictionary class]] && disk.count > 0) {
            return disk;
        }
    }
    return nil;
}

static void ssd_reload_prefs(void) {
    NSDictionary *prefs = ssd_prefs_disk();
    if (![prefs isKindOfClass:[NSDictionary class]]) {
        prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:@SSD_ID];
    }
    if (![prefs isKindOfClass:[NSDictionary class]]) {
        CFArrayRef keys = CFPreferencesCopyKeyList(CFSTR(SSD_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        if (keys) {
            CFDictionaryRef dict = CFPreferencesCopyMultiple(keys, CFSTR(SSD_ID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
            CFRelease(keys);
            if (dict) {
                prefs = [(__bridge_transfer NSDictionary *)dict copy];
            }
        }
    }
    gHideFavicons = ssd_bool(prefs, @"HideFavicons");
    gDisablePtr = ssd_bool(prefs, @"DisablePullToRefresh");
    dispatch_async(dispatch_get_main_queue(), ^{
        ssd_apply_ptr();
    });
}

#pragma mark - favicon helpers

static BOOL ssd_icon_class(NSString *name) {
    if (name.length == 0) {
        return NO;
    }
    NSString *lower = name.lowercaseString;
    return [lower containsString:@"favicon"]
        || [lower containsString:@"siteicon"]
        || [lower containsString:@"websiteicon"]
        || [lower containsString:@"touchicon"]
        || [lower containsString:@"bookmarkicon"]
        || [lower containsString:@"favoriteicon"]
        || [lower containsString:@"startpageicon"]
        || [lower containsString:@"tabicon"]
        || [lower containsString:@"pageicon"];
}

static BOOL ssd_icon_container(NSString *name) {
    if (name.length == 0) {
        return NO;
    }
    NSString *lower = name.lowercaseString;
    return ssd_icon_class(name)
        || [lower containsString:@"bookmarkfavoriteview"]
        || [lower containsString:@"bookmarkfavoritesgrid"]
        || [lower containsString:@"completionlist"]
        || [lower containsString:@"unifiedfieldcompletion"];
}

static BOOL ssd_tab_card(NSString *name) {
    if (name.length == 0) {
        return NO;
    }
    NSString *lower = name.lowercaseString;
    BOOL family = [lower containsString:@"taboverview"]
        || [lower containsString:@"tabthumbnail"]
        || [lower containsString:@"tabexpose"]
        || [lower containsString:@"tabgrid"]
        || [lower containsString:@"tabswitcher"]
        || [lower containsString:@"tabbaritem"];
    if (!family) {
        return NO;
    }
    return [lower containsString:@"item"]
        || [lower containsString:@"card"]
        || [lower containsString:@"cell"]
        || [lower containsString:@"view"];
}

static BOOL ssd_close_control(id object, UIView *root) {
    UIView *cursor = [object isKindOfClass:[UIView class]] ? (UIView *)object : nil;
    NSInteger depth = 0;
    while (cursor && depth < 6) {
        NSString *lower = NSStringFromClass(object_getClass(cursor)).lowercaseString;
        if ([lower containsString:@"closebutton"] || [lower containsString:@"tabclose"] || [lower containsString:@"closeitem"]) {
            return YES;
        }
        if (cursor == root) {
            break;
        }
        cursor = cursor.superview;
        depth++;
    }
    return NO;
}

static BOOL ssd_in_container(id object) {
    UIView *cursor = [object isKindOfClass:[UIView class]] ? (UIView *)object : nil;
    NSInteger depth = 0;
    while (cursor && depth < 8) {
        if (ssd_icon_container(NSStringFromClass(object_getClass(cursor)))) {
            return YES;
        }
        cursor = cursor.superview;
        depth++;
    }
    return NO;
}

static void ssd_hide(id object) {
    if (!gHideFavicons || ![object isKindOfClass:[UIView class]]) {
        return;
    }
    UIView *view = (UIView *)object;
    view.hidden = YES;
    view.alpha = 0.0;
    view.userInteractionEnabled = NO;
    if (objc_getAssociatedObject(view, kSSDHidden)) {
        return;
    }
    objc_setAssociatedObject(view, kSSDHidden, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if ([view isKindOfClass:[UIImageView class]]) {
        ((UIImageView *)view).image = nil;
    } else if ([view respondsToSelector:@selector(setImage:)]) {
        ((void (*)(id, SEL, id))objc_msgSend)(view, @selector(setImage:), nil);
    }
}

static void ssd_hide_tab_favicon(id object) {
    if (!gHideFavicons || ![object isKindOfClass:[UIView class]]) {
        return;
    }
    UIView *root = (UIView *)object;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
    NSMutableArray<UIView *> *images = [NSMutableArray array];
    NSMutableArray<UIView *> *labels = [NSMutableArray array];
    while (stack.count) {
        UIView *view = stack.lastObject;
        [stack removeLastObject];
        if (ssd_icon_class(NSStringFromClass(object_getClass(view)))) {
            ssd_hide(view);
        }
        if ([view isKindOfClass:[UIImageView class]]) {
            [images addObject:view];
        } else if ([view isKindOfClass:[UILabel class]] && ((UILabel *)view).text.length > 0) {
            [labels addObject:view];
        }
        [stack addObjectsFromArray:view.subviews];
    }
    for (UIView *image in images) {
        if (ssd_close_control(image, root)) {
            continue;
        }
        CGSize size = image.bounds.size;
        if (size.width < 8.0 || size.width > 44.0 || size.height < 8.0 || size.height > 44.0) {
            continue;
        }
        CGRect img = [image convertRect:image.bounds toView:root];
        for (UIView *label in labels) {
            CGRect lab = [label convertRect:label.bounds toView:root];
            BOOL sameRow = fabs(CGRectGetMidY(img) - CGRectGetMidY(lab)) <= 22.0;
            BOOL leftOfTitle = CGRectGetMaxX(img) <= CGRectGetMinX(lab) + 12.0;
            if (sameRow && leftOfTitle) {
                ssd_hide(image);
                break;
            }
        }
    }
}

static void ssd_walk_icons(id object) {
    if (!gHideFavicons || ![object isKindOfClass:[UIView class]]) {
        return;
    }
    UIView *root = (UIView *)object;
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
    while (stack.count) {
        UIView *view = stack.lastObject;
        [stack removeLastObject];
        NSString *name = NSStringFromClass(object_getClass(view));
        if (ssd_icon_class(name) || ([view isKindOfClass:[UIImageView class]] && ssd_in_container(view))) {
            ssd_hide(view);
        }
        [stack addObjectsFromArray:view.subviews];
    }
}

#pragma mark - pull to refresh helpers

static BOOL ssd_web_scroll(UIScrollView *scroll) {
    NSString *name = NSStringFromClass(object_getClass(scroll));
    if ([name containsString:@"WKScroll"] || [name containsString:@"WKWeb"]) {
        return YES;
    }
    return [scroll.superview isKindOfClass:[WKWebView class]];
}

static BOOL ssd_is_pulling(WKWebView *web) {
    if (![web isKindOfClass:[WKWebView class]]) {
        return NO;
    }
    return web.scrollView.contentOffset.y < -24.0;
}

static void ssd_kill_refresh(id object) {
    if (!gDisablePtr) {
        return;
    }
    UIScrollView *scroll = nil;
    WKWebView *web = nil;
    if ([object isKindOfClass:[WKWebView class]]) {
        web = (WKWebView *)object;
        scroll = web.scrollView;
    } else if ([object isKindOfClass:[UIScrollView class]]) {
        scroll = (UIScrollView *)object;
    } else if ([object isKindOfClass:[UIView class]] && [object respondsToSelector:@selector(scrollView)]) {
        id maybe = ((id (*)(id, SEL))objc_msgSend)(object, @selector(scrollView));
        if ([maybe isKindOfClass:[UIScrollView class]]) {
            scroll = maybe;
        }
    }
    if (scroll.refreshControl) {
        [scroll.refreshControl endRefreshing];
        scroll.refreshControl = nil;
    }
    if (web && [web respondsToSelector:@selector(_setPullToRefreshEnabled:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(web, @selector(_setPullToRefreshEnabled:), NO);
    }
}

static void ssd_apply_ptr_tree(UIView *root) {
    if (!root) {
        return;
    }
    NSMutableArray<UIView *> *stack = [NSMutableArray arrayWithObject:root];
    while (stack.count) {
        UIView *view = stack.lastObject;
        [stack removeLastObject];
        ssd_kill_refresh(view);
        [stack addObjectsFromArray:view.subviews];
    }
}

static void ssd_apply_ptr(void) {
    if (!gDisablePtr) {
        return;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            ssd_apply_ptr_tree(window);
        }
    }
}

#pragma mark - favicon hooks

%hook _SFSiteIconView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;
    ssd_hide(self);
}
- (void)didMoveToWindow {
    %orig;
    ssd_hide(self);
}
%end

%hook SFSiteIconView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;
    ssd_hide(self);
}
%end

%hook SiteIconView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;
    ssd_hide(self);
}
%end

%hook _SFFaviconView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;
    ssd_hide(self);
}
%end

%hook SFFaviconView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
- (void)layoutSubviews {
    %orig;
    ssd_hide(self);
}
%end

%hook BookmarkFavoriteView
- (void)layoutSubviews {
    %orig;
    ssd_walk_icons(self);
}
%end

%hook BookmarkFavoritesGridView
- (void)layoutSubviews {
    %orig;
    ssd_walk_icons(self);
}
%end

%hook CompletionListTableViewCell
- (void)layoutSubviews {
    %orig;
    ssd_walk_icons(self);
    if (gHideFavicons && self.imageView) {
        ssd_hide(self.imageView);
    }
}
%end

%hook UnifiedFieldCompletionListCell
- (void)layoutSubviews {
    %orig;
    ssd_walk_icons(self);
}
%end

%hook TabBarItemView
- (void)layoutSubviews {
    %orig;
    ssd_walk_icons(self);
    ssd_hide_tab_favicon(self);
}
%end

%hook TabOverviewItemView
- (void)layoutSubviews {
    %orig;
    ssd_hide_tab_favicon(self);
}
%end

%hook TabThumbnailView
- (void)layoutSubviews {
    %orig;
    ssd_hide_tab_favicon(self);
}
%end

%hook SFTabOverviewItemView
- (void)layoutSubviews {
    %orig;
    ssd_hide_tab_favicon(self);
}
%end

%hook _SFTabOverviewItemView
- (void)layoutSubviews {
    %orig;
    ssd_hide_tab_favicon(self);
}
%end

%hook UIImageView
- (void)setImage:(UIImage *)image {
    if (gHideFavicons && image && ssd_in_container(self)) {
        %orig(nil);
        ssd_hide(self);
        return;
    }
    %orig;
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if (!gHideFavicons || !self.window) {
        return;
    }
    NSString *name = NSStringFromClass(object_getClass(self));
    if (ssd_icon_class(name)) {
        ssd_hide(self);
    } else if (ssd_tab_card(name)) {
        ssd_hide_tab_favicon(self);
    }
}
- (void)layoutSubviews {
    %orig;
    if (!gHideFavicons) {
        return;
    }
    NSString *name = NSStringFromClass(object_getClass(self));
    if (ssd_icon_class(name)) {
        ssd_hide(self);
    } else if (ssd_tab_card(name)) {
        ssd_hide_tab_favicon(self);
    }
}
%end

#pragma mark - pull to refresh hooks

%hook UIScrollView
- (void)setRefreshControl:(UIRefreshControl *)control {
    if (gDisablePtr) {
        %orig(nil);
        return;
    }
    %orig;
}
- (void)setContentOffset:(CGPoint)offset {
    if (gDisablePtr && offset.y < 0.0 && ssd_web_scroll(self)) {
        offset.y = 0.0;
    }
    %orig(offset);
}
- (void)didMoveToWindow {
    %orig;
    ssd_kill_refresh(self);
}
%end

%hook UIRefreshControl
- (void)didMoveToWindow {
    %orig;
    if (!gDisablePtr || !self.window) {
        return;
    }
    self.enabled = NO;
    [self endRefreshing];
    self.hidden = YES;
}
- (void)beginRefreshing {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
- (void)sendActionsForControlEvents:(UIControlEvents)events {
    if (gDisablePtr && (events & UIControlEventValueChanged)) {
        [self endRefreshing];
        return;
    }
    %orig;
}
%end

%hook WKWebView
- (void)didMoveToWindow {
    %orig;
    ssd_kill_refresh(self);
}
- (void)layoutSubviews {
    %orig;
    ssd_kill_refresh(self);
}
- (void)_setPullToRefreshEnabled:(BOOL)enabled {
    if (gDisablePtr) {
        %orig(NO);
        return;
    }
    %orig;
}
- (WKNavigation *)reload {
    if (gDisablePtr && ssd_is_pulling(self)) {
        return nil;
    }
    return %orig;
}
- (WKNavigation *)reloadFromOrigin {
    if (gDisablePtr && ssd_is_pulling(self)) {
        return nil;
    }
    return %orig;
}
%end

%hook _SFWebView
- (void)didMoveToWindow {
    %orig;
    ssd_kill_refresh(self);
}
- (void)layoutSubviews {
    %orig;
    ssd_kill_refresh(self);
}
%end

%hook TabDocument
- (void)reload {
    if (gDisablePtr) {
        id web = [self respondsToSelector:@selector(webView)] ? [self webView] : nil;
        if ([web isKindOfClass:[WKWebView class]] && ssd_is_pulling((WKWebView *)web)) {
            return;
        }
    }
    %orig;
}
- (BOOL)isPullToRefreshEnabled {
    return gDisablePtr ? NO : %orig;
}
- (void)setPullToRefreshEnabled:(BOOL)enabled {
    %orig(gDisablePtr ? NO : enabled);
}
- (void)_pullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
- (void)pullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
- (void)_refreshFromPullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
- (void)handlePullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
%end

%hook BrowserController
- (void)_pullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
- (void)pullToRefresh {
    if (gDisablePtr) {
        return;
    }
    %orig;
}
%end

#pragma mark - ctor

%ctor {
    ssd_reload_prefs();
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)ssd_reload_prefs,
        CFSTR(SSD_NOTIFY),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
    %init;
}
