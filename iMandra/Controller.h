/* Controller */

#import <Cocoa/Cocoa.h>

@interface Controller : NSObject
{
    IBOutlet id DataView;
    IBOutlet id ipField;
    IBOutlet id portField;
    IBOutlet id RemoteWindow;
    IBOutlet id SaveOnButton;
    IBOutlet id serviceList;
    IBOutlet id textField;
	
	NSNetService * netService;
    NSFileHandle * listeningSocket;
	NSNetServiceBrowser * browser;
	NSNetServiceBrowser * domainBrowser;
    NSMutableArray * discoveredServices;
    NSNetService * serviceBeingResolved;
}
- (IBAction)publishService:(id)sender;
- (IBAction)serviceClicked:(id)sender;
- (IBAction)StartStopRendButton:(id)sender;
- (void)setupBrowser;
- (void)setupService;
- (void)stopService;
@end

@interface Controller (NSNetServiceDelegation)
// Publication Specific
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
- (void)netServiceWillPublish:(NSNetService *)sender;
- (void)netServiceDidStop:(NSNetService *)sender;

// Resolution Specific
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netServiceWillResolve:(NSNetService *)sender;
@end

@interface Controller (NSNetServiceBrowserDelegation)
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didNotSearch:(NSDictionary *)errorDict;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didFindDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser 
	    didRemoveDomain:(NSString *)domainString 
	    moreComing:(BOOL)moreComing;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser;
@end

@interface Controller (ContactListDataSource)
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView 
	    objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
@end
