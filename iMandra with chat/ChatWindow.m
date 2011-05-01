//
//  ChatWindow.m
//  iMandra
//
//  Created by Joe Maffia on 09/03/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "ChatWindow.h"


@implementation ChatWindow
- (id)initWithConnection:(NSFileHandle *)aFileHandle myName:(NSString *)me 
{
    self = [super initWithWindowNibName:@"ChatWindow"];
    
    if ( self ) {
	fileHandle = [aFileHandle retain];
        myName = [me copy];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self 
	       selector:@selector(receiveMessage:)
	           name:NSFileHandleReadCompletionNotification
		 object:fileHandle];

	[fileHandle readInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fileHandle closeFile];
    [fileHandle release];
    [myName release];
    
    [super dealloc];
}

- (void)postMessage:(NSString *)message fromPerson:(NSString *)person
{
    NSString *str = [NSString stringWithFormat:@"%@: %@\n", person, message];
    NSAttributedString *aStr = [[NSAttributedString alloc] initWithString:str];
    
    [[textView textStorage] appendAttributedString:aStr];
    [aStr release];
}

- (IBAction)sendMessage:(id)sender
{
    NSString *message = [NSString stringWithFormat:@"_imandrashare_:%@:%@", myName, [sender stringValue]];
    NSData *messageData = [NSData dataWithBytes:[message UTF8String]
				         length:[message length]];
    [fileHandle writeData:messageData];

    [self postMessage:[sender stringValue] fromPerson:@"Me"];
    [sender setStringValue:@""];
}

- (void)receiveMessage:(NSNotification *)notification
{
    NSData *messageData = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if ( [messageData length] == 0 ) {
        [fileHandle readInBackgroundAndNotify];
        return;
    }
    
    NSString *message = [NSString stringWithUTF8String:[messageData bytes]];
    NSArray *msgComponents = [message componentsSeparatedByString:@":"];
    
    if ( [msgComponents count] != 3 ) {
        [fileHandle readInBackgroundAndNotify];
        return;
    }
    
    if ( ![[msgComponents objectAtIndex:0] isEqualToString:@"_imandrashare_"] ) {
        [fileHandle readInBackgroundAndNotify];
        return;
    }

    if ( ![[self window] isVisible] )
        [self showWindow:nil];

    [self postMessage:[msgComponents objectAtIndex:2] 
           fromPerson:[msgComponents objectAtIndex:1]];
    
    [fileHandle readInBackgroundAndNotify];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self release];
}


@end
