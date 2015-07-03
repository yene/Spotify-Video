//
//  AppDelegate.m
//  Spotify Video
//
//  Created by Yannick Weiss on 03/07/15.
//  Copyright © 2015 Yannick Weiss. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
  [self spotifyData];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (void)spotifyData {
  NSString* path = [[NSBundle mainBundle] pathForResource:@"spotify" ofType:@"scpt"];
  NSURL* url = [NSURL fileURLWithPath:path];
  NSDictionary* errors;
  NSAppleEventDescriptor* returnDescriptor = NULL;
  NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
  returnDescriptor = [appleScript executeAndReturnError: &errors];
  NSString *result = [returnDescriptor stringValue];
  NSString *arr = [result componentsSeparatedByString:@","];
  
  //[[returnDescriptor descriptorForKeyword:"form"] stringValue]
  

  
}

@end
