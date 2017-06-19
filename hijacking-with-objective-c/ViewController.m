//
//  ViewController.m
//  hijacking-with-objective-c
//
//  Created by ja on 16.06.2017.
//  Copyright © 2017 Jelko Arnds. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import <dlfcn.h>

static CFStringRef launchServicesKey(const char *symbol)
{
    CFStringRef *keyPtr = dlsym(RTLD_DEFAULT, symbol);
    return keyPtr ? *keyPtr : NULL;
}

@implementation ViewController

static OSStatus (*_LSSetApplicationInformationItem)(int, CFTypeRef asn, CFStringRef key, CFStringRef value, CFDictionaryRef *info) = NULL;
static CFStringRef _kLSApplicationTypeKey = NULL;
static CFStringRef _kLSApplicationForegroundTypeKey = NULL;
static CFStringRef _kLSApplicationUIElementTypeKey = NULL;
static CFStringRef _kLSApplicationBackgroundOnlyTypeKey = NULL;

extern CFTypeRef _LSASNCreateWithPid(CFAllocatorRef, pid_t);


NSRunningApplication* app;
NSMutableArray<NSRunningApplication *> *apps;

- (void)viewDidLoad {
    _LSSetApplicationInformationItem = dlsym(RTLD_DEFAULT, "_LSSetApplicationInformationItem");
    _kLSApplicationTypeKey = launchServicesKey("_kLSApplicationTypeKey");
    _kLSApplicationForegroundTypeKey = launchServicesKey("_kLSApplicationForegroundTypeKey");
    _kLSApplicationUIElementTypeKey = launchServicesKey("_kLSApplicationUIElementTypeKey");
    _kLSApplicationBackgroundOnlyTypeKey = launchServicesKey("_kLSApplicationBackgroundOnlyTypeKey");
    
    NSArray<NSRunningApplication *> *all_apps = [NSWorkspace sharedWorkspace].runningApplications;
    apps = [[NSMutableArray alloc] init];
    
    [select_application removeAllItems];
    for(NSRunningApplication *app in all_apps){
        if(app.activationPolicy == NSApplicationActivationPolicyRegular
           && app.processIdentifier != [NSRunningApplication currentApplication].processIdentifier
           && [app.bundleIdentifier compare:@"com.apple.finder"]){
            [apps addObject: app];
            [select_application addItemWithTitle:[NSString stringWithFormat:@"%@ %@ (%d)", app.localizedName, app.bundleIdentifier, (int)app.processIdentifier]];
        }
    }
    
    [select_application setAction:@selector(popUpSelectionChanged:)];
    [select_application setTarget:self];
}


- (void)makeApplicationForegroundApplicationWithApp: (NSRunningApplication*) app {
    CFTypeRef asn;
    pid_t pid = app.processIdentifier;
    asn = _LSASNCreateWithPid(kCFAllocatorDefault, pid);
    OSStatus status = _LSSetApplicationInformationItem(-2, asn, _kLSApplicationTypeKey, _kLSApplicationForegroundTypeKey, NULL);
}

- (void)makeApplicationBackgroundApplicationWithApp: (NSRunningApplication*) app {
    CFTypeRef asn;
    pid_t pid = app.processIdentifier;
    asn = _LSASNCreateWithPid(kCFAllocatorDefault, pid);
    OSStatus status = _LSSetApplicationInformationItem(-2, asn, _kLSApplicationTypeKey, _kLSApplicationBackgroundOnlyTypeKey, NULL);
}

// CONNECT TO UI

- (IBAction)btn_hide:(id)sender {
    [app hide];
}
- (IBAction)btn_remove:(id)sender {
    [self makeApplicationBackgroundApplicationWithApp:app];
}
- (IBAction)btn_full_hide:(id)sender {
}
- (IBAction)btn_show:(id)sender {
    [app unhide];
}
- (IBAction)btn_add:(id)sender {
    [self makeApplicationForegroundApplicationWithApp:app];
}
- (IBAction)btn_full_show:(id)sender {
}

- (IBAction)btn_hide_all:(id)sender {
    // TODO alternative: NSWorkspace hideAllOther
    for(NSRunningApplication *app in apps){
        [app hide];
    }
}
- (IBAction)btn_show_all:(id)sender {
    for(NSRunningApplication *app in apps){
        [app unhide];
    }
}
- (IBAction)btn_add_all:(id)sender {
    for(NSRunningApplication *app in apps){
        [self makeApplicationForegroundApplicationWithApp:app];
    }
}
- (IBAction)btn_remove_all:(id)sender {
    for(NSRunningApplication *app in apps){
        [self makeApplicationBackgroundApplicationWithApp:app];
    }
}

- (void)popUpSelectionChanged:(id)sender {
    app = [apps objectAtIndex:[select_application indexOfSelectedItem]];
    if(app == nil){
        label_app_name.stringValue = @"no application found";
        return;
    }
    label_app_name.stringValue = app.localizedName;
}


@end
