#import "ConvController.h"

@implementation ConvController

- (float)Calculate:(float)a:(float)b
{
	return ( (1200/(log(2)))*(log(b/a)) );
}

@end
