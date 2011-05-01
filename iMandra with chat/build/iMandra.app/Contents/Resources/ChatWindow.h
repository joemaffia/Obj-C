//
//  ChatWindow.h
//  iMandra
//
//  Created by Joe Maffia on 09/03/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>

#import <Cocoa/Cocoa.h>

@interface ChatWindow : NSWindowController {
    IBOutlet NSTextView *textView;
    NSFileHandle *fileHandle;
    NSString *myName;
}
- (id)initWithConnection:(NSFileHandle *)aFileHandle myName:(NSString *)me;
- (IBAction)sendMessage:(id)sender;
- (void)receiveMessage:(NSNotification *)notification;
- (void)postMessage:(NSString *)message fromPerson:(NSString *)person;
- (void)windowWillClose:(NSNotification *)notification;
@end
