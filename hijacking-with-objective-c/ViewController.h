//
//  ViewController.h
//  hijacking-with-objective-c
//
//  Created by ja on 16.06.2017.
//  Copyright © 2017 Jelko Arnds. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController{

    pid_t pid;
    
    IBOutlet NSTextField *label_app_name;
    IBOutlet NSPopUpButton *select_application;
}

@end

