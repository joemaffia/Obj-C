#import "Controller.h"
#import "ChatWindow.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>


@implementation Controller

- (void)awakeFromNib {
    // Set up a default name for the picture service
    [textField setStringValue:NSFullUserName()];// stringByAppendingString:@"'s Desktop"]];
	//[[NSApplication sharedApplication] setDelegate:self];
	[serviceList setTarget:self];
   // [serviceList setDoubleAction:@selector(openNewChatWindowAsChatInitiator:)];
}

- (void)setupService
{
    struct sockaddr_in addr;
    int sockfd;
    
    // Create a socket
    sockfd = socket( AF_INET, SOCK_STREAM, 0 );

    // Setup its address structure
    bzero( &addr, sizeof(struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl( INADDR_ANY );	// Bind to any of the system addresses
    addr.sin_port = htons( 0 );			// Let the system choose a port for us

    // Bind it to an address and port
    bind( sockfd, (struct sockaddr *)&addr, sizeof(struct sockaddr));

    // Set it listening for connections
    listen( sockfd, 5 );
    
    // Find out the port number so we can pass it to the net service initializer
    int namelen = sizeof(struct sockaddr_in);
    getsockname( sockfd, (struct sockaddr *)&addr, &namelen );

    // Create NSFileHandle to communicate with socket
    listeningSocket = [[NSFileHandle alloc] initWithFileDescriptor:sockfd];

    // Register for NSFileHandle socket-related Notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self 
	selector:@selector(openNewChatWindowAsMessageReceiver:/*connectionReceived:*/) 
	name:NSFileHandleConnectionAcceptedNotification 
	object:listeningSocket];

    // Accept connections in background and notify
    [listeningSocket acceptConnectionInBackgroundAndNotify];

    // Configure and publish the Rendezvous service
    netService = [[NSNetService alloc] initWithDomain:@""
				    type:@"_imandrashare._tcp."
				    name:[textField stringValue]
				    port:addr.sin_port];
    [netService setDelegate:self];
    [netService publish];
}

- (void)setupBrowser
{
    if ( !browser ) {
	browser = [[NSNetServiceBrowser alloc] init];
	[browser setDelegate:self];
    }
    
    if ( !domainBrowser ) {
	domainBrowser = [[NSNetServiceBrowser alloc] init];
	[domainBrowser setDelegate:self];
    }
    
    if ( !discoveredServices )
	discoveredServices = [[NSMutableArray alloc] init];
	
    [domainBrowser searchForAllDomains];
    [browser searchForServicesOfType:@"_imandrashare._tcp." inDomain:@""];
}


- (void)stopService
{
    [netService stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleConnectionAcceptedNotification object:listeningSocket];

    [listeningSocket closeFile];
    [listeningSocket release];
}

- (IBAction)serviceClicked:(id)sender 
{/*
   // The row that was clicked corresponds to the object in services we wish to contact.
     row = [sender selectedRow];
	
    // cancel any previous resolves.
    if (serviceBeingResolved) {
        [serviceBeingResolved stop];
        [serviceBeingResolved release];
        serviceBeingResolved = nil;
    }
    
    [DataView setImage:nil];
  
    if(-1 == row) {
        [ipField setStringValue:@""];
        [portField setStringValue:@""];
    } else {
        serviceBeingResolved = [discoveredServices objectAtIndex:row];
		[serviceBeingResolved retain];
        [serviceBeingResolved setDelegate:self];
        [serviceBeingResolved resolve];
	}*/
}

- (IBAction)openNewChatAsChatInitiator:(id)sender
{
}

- (IBAction)publishService:(id)sender 
{
switch ( [sender state] ) {
		case NSOnState:
			[self setupService];
			[textField setEnabled:NO];
			break;
		case NSOffState:
			[self stopService];
            [ipField setStringValue:@""];
            [portField setStringValue:@""];
			[DataView setImage:nil];
			[textField setEnabled:YES];
			break;
	}
}

- (IBAction)StartStopRendButton:(id)sender 
{
switch ( [sender state] ) {
	case NSOnState:
	    [self setupBrowser];
        break;
	
	case NSOffState:
	    [browser stop];
	    [domainBrowser stop];
		break;
    }
}

@end

@implementation Controller (ChatFunctionality)
/*
 * This method could also be called openNewChatWindowAsClient
 */
- (void)openNewChat:(id)sender
{
    // Obtain remote service based on selected name in list
    NSNetService *remoteService = [discoveredServices objectAtIndex:0/*[sender selectedRow]*/];

    // Get the socket address structure for the remote service
    NSData *address = [[remoteService addresses] objectAtIndex:0];

    // Create a socket that will be used to connect to the other chat client.
    int s = socket( AF_INET, SOCK_STREAM, 0 );
    connect( s, [address bytes], [address length] );

    // Create a file handle for the socket used to connect to the other chat client.
    NSFileHandle *remoteFH;
    remoteFH = [[[NSFileHandle alloc] initWithFileDescriptor:s] autorelease];
    [remoteFH autorelease];
    
    // Open a window with a connection to the remote client.
    ChatWindow *chatWC;
    chatWC = [[ChatWindow alloc] initWithConnection:remoteFH
                                           myName:[textField stringValue]];
    [chatWC showWindow:nil];
}

/*
 * This method could also be called openNewChatWindowAsServer
 */
- (void)openNewChatWindowAsMessageReceiver:(NSNotification *)notification
{
    NSFileHandle *remoteFH = [[notification userInfo] 
					objectForKey:NSFileHandleNotificationFileHandleItem];
    
    ChatWindow *chatWC;
    chatWC = [[ChatWindow alloc] initWithConnection:remoteFH
                                            myName:[textField stringValue]];
}

@end

//////////////////////////////////// Publication Risolution & Log ///////////////////////////////////////////////////

@implementation Controller (NSNetServiceDelegation)
// Publication Specific
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    NSLog( @"Could not publish the service %@. Error dictionary follows...", [sender name] );
    NSLog( [errorDict description] );
}

- (void)netServiceWillPublish:(NSNetService *)sender
{
    NSLog( @"Publishing service %@", [sender name] );
}

- (void)netServiceDidStop:(NSNetService *)sender
{
    NSLog( @"Stopping service %@", [sender name] );
}

// Resolution Specific
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    NSLog( @"There was an error while attempting to resolve address for %@",
			[sender name] );
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {

    NSLog( @"Successfully resolved address for %@.", [sender name] );
	/*
	if ([[sender addresses] count] > 0) {
        NSData * address;
		struct sockaddr * socketAddress;
        NSString * ipAddressString = nil;
        NSString * portString = nil;
        int socketToRemoteServer;
        char buffer[256];
        int index;
        
        // Iterate through addresses until we find an IPv4 address
        for (index = 0; index < [[sender addresses] count]; index++) {
            address = [[sender addresses] objectAtIndex:index];
            socketAddress = (struct sockaddr *)[address bytes];
            
            if (socketAddress->sa_family == AF_INET)
                break;
        }
        
        if (socketAddress) {
            switch(socketAddress->sa_family) {
                case AF_INET:
                    if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer)))
                        ipAddressString = [NSString stringWithCString:buffer];
                    portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
                    
                    // Cancel the resolve now that we have an IPv4 address.
                    [sender stop];
                    [sender release];
                    serviceBeingResolved = nil;
                    
                    break;
                case AF_INET6:
                    //doesn't support IPv6
                    return;
            }
        }   
             
        if (ipAddressString)
            [ipField setStringValue:ipAddressString];
        
        if (portString)
            [portField setStringValue:portString];

        socketToRemoteServer = socket(AF_INET, SOCK_STREAM, 0);
        if(socketToRemoteServer > 0) {
            /*NSFileHandle * remoteConnection = [[NSFileHandle alloc] initWithFileDescriptor:socketToRemoteServer closeOnDealloc:YES];
            if(remoteConnection) {
				NSLog( @"notifica" );
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readAllTheData:) name:NSFileHandleReadToEndOfFileCompletionNotification object:remoteConnection];
                if(connect(socketToRemoteServer, (struct sockaddr *)socketAddress, sizeof(*socketAddress)) == 0) {
                [remoteConnection readToEndOfFileInBackgroundAndNotify];
                }
            } else {
                close(socketToRemoteServer);
            }
        }
    }*/
}

- (void)readAllTheData:(NSNotification *)aNotification {
	NSLog( @"legge data" );
    NSImage * theImage = [[NSImage alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem]];
	[DataView setImage:theImage];
	if ([SaveOnButton state] == NSOnState) {
	[[theImage TIFFRepresentation] writeToFile:
            [[NSString stringWithFormat:@"~/Desktop/%@ ScreenShot.tiff", [[discoveredServices objectAtIndex:[serviceList selectedRow]] name]]
                stringByExpandingTildeInPath]
                                        atomically:NO];
	}
	[theImage release];
	
}

// This object is also listening for notifications from its NSFileHandle.
// When an incoming connection is seen by the listeningSocket object, we get the NSFileHandle representing the near end of the connection. 
//We write the thumbnail image to this NSFileHandle instance.

- (void)connectionReceived:(NSNotification *)aNotification {
    NSFileHandle * incomingConnection = [[aNotification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
	
    
    NSRect screenRect = [[NSScreen mainScreen] frame];
    NSImage *screenImg = [[NSImage alloc] initWithSize:NSMakeSize(screenRect.size.width, screenRect.size.height)];
    [screenImg setScalesWhenResized:YES];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:screenRect
                                                   styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained
                                                       defer:NO];
    NSView *myView = [[NSView alloc] initWithFrame:screenRect];
    [window setLevel:NSScreenSaverWindowLevel + 100];
    [window setHasShadow:NO];
    [window setAlphaValue:0.0];
    [window setContentView:myView];
    [window orderFront:self];
    [myView lockFocus];
    NSBitmapImageRep *screenRep= [[NSBitmapImageRep alloc] initWithFocusedViewRect:screenRect];
    [screenImg addRepresentation:screenRep];
    [myView unlockFocus];
    [window orderOut:self];
    [window close];

    NSImage *scaledImage = [[NSImage alloc] initWithSize:NSMakeSize([screenImg size].width, [screenImg size].height)];
    [scaledImage lockFocus];
    [screenImg drawInRect:NSMakeRect(0,0,[scaledImage size].width,[scaledImage size].height)
                        fromRect:NSMakeRect(0,0,[screenImg size].width,[screenImg size].height)
                       operation:NSCompositeCopy fraction:1.0];
    [scaledImage unlockFocus];

    // Compress the TIFF using LZW, since uncompressed screenshots are huge.
    NSData *representationToSend = [scaledImage TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:10.0];
    
		
    [[aNotification object] acceptConnectionInBackgroundAndNotify];
    [incomingConnection writeData:representationToSend];
    [incomingConnection closeFile];
	NSLog( @"Connect" );
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    NSLog( @"Attempting to resolve address for %@...", [sender name] );
}
@end

@implementation Controller (NSNetServiceBrowserDelegation)
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing
{
    NSLog( @"Found service named %@.", [aNetService name] );

    [discoveredServices addObject:aNetService];
	[aNetService setDelegate:self];
    [aNetService resolve];
    
    if ( !moreComing )
	[serviceList reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveService:(NSNetService *)aNetService 
	    moreComing:(BOOL)moreComing
{
    [discoveredServices removeObject:aNetService];
    
    if ( !moreComing )
	[serviceList reloadData];
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    if ( aNetServiceBrowser == browser ) {
	[discoveredServices removeAllObjects];
	[serviceList reloadData];
    }    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didNotSearch:(NSDictionary *)errorDict
{
    NSLog(@"There was an error in searching. Error Dictionary follows...");
    NSLog( [errorDict description] );
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    if ( aNetServiceBrowser == domainBrowser ) 
	NSLog(@"We're about to start searching for domains..." );
    else
	NSLog(@"We're about to start searching for services..." );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing
{
    NSLog( @"Found domain %@.", domainString );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing
{
    NSLog( @"Removed domain %@.", domainString );
}

@end
// NSTableView servicesList 

@implementation Controller (ContactListDataSource)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [discoveredServices count];
}

- (id)tableView:(NSTableView *)aTableView 
	    objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	    row:(int)rowIndex
{
    return [[discoveredServices objectAtIndex:rowIndex] name];
}
@end

