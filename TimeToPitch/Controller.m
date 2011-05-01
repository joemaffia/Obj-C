#import "Controller.h"
#import "ConvController.h"

@implementation Controller

- (IBAction)Convert:(id)sender
{
	float CurTempo, DesTempo, DetCents;
	CurTempo=[fieldCurrTempo floatValue];
	DesTempo=[fieldDesTempo floatValue];
	DetCents=[bridge Calculate:CurTempo:DesTempo];
	[fieldDetCents setFloatValue:DetCents];
	[fieldCurrTempo selectText:self];
	[fieldDesTempo selectText:self];
}

@end
