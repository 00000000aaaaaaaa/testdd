#import "SSDRootListController.h"

@implementation SSDRootListController

- (PSSpecifier *)ssdSwitch:(NSString *)label key:(NSString *)key {
    PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:label
                                                      target:self
                                                         set:@selector(setPreferenceValue:specifier:)
                                                         get:@selector(readPreferenceValue:)
                                                      detail:Nil
                                                        cell:PSSwitchCell
                                                        edit:Nil];
    [spec setProperty:key forKey:@"key"];
    [spec setProperty:@"com.safarisettingsdd.safarisettingsdd" forKey:@"defaults"];
    [spec setProperty:@NO forKey:@"default"];
    [spec setProperty:@"com.safarisettingsdd.safarisettingsdd/ReloadPrefs" forKey:@"PostNotification"];
    return spec;
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        PSSpecifier *group = [PSSpecifier groupSpecifierWithName:@"safarisettingsdd"];
        [group setProperty:@"all options are off by default. after changing a toggle, force-quit safari." forKey:@"footerText"];
        [specs addObject:group];
        [specs addObject:[self ssdSwitch:@"hide favicons" key:@"HideFavicons"]];
        [specs addObject:[self ssdSwitch:@"disable pull to refresh" key:@"DisablePullToRefresh"]];
        _specifiers = specs;
    }
    return _specifiers;
}

@end
