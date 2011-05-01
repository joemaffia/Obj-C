/* Controller */

import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class Controller extends NSObject {

    public ControllerMath bridge; /* IBOutlet */
    public NSTextField fieldCurTempo; /* IBOutlet */
    public NSTextField fieldDesTempo; /* IBOutlet */
    public NSTextField fieldDetCents; /* IBOutlet */

    public void Convert(Object sender) { /* IBAction */
		float CurSampleTempo, DesSampleTempo;
		double DetCents;
		CurSampleTempo=fieldCurTempo.floatValue();
		DesSampleTempo=fieldDesTempo.floatValue();
		DetCents=bridge.calcola(CurSampleTempo,DesSampleTempo);
		fieldDetCents.setDoubleValue(DetCents);
		fieldCurTempo.selectText(this);
		fieldDesTempo.selectText(this);
    }

}
