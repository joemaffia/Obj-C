/* Controller */

#import <Cocoa/Cocoa.h>

@interface Controller : NSObject
{
    IBOutlet id bridge;
    IBOutlet id fieldCurrTempo;
    IBOutlet id fieldDesTempo;
    IBOutlet id fieldDetCents;
}
- (IBAction)Convert:(id)sender;
@end
