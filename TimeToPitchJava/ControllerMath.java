/* ControllerMath */

import java.math.*;
import com.apple.cocoa.foundation.*;
import com.apple.cocoa.application.*;

public class ControllerMath extends NSObject {
    public double calcola(float a, float b) { /* IBAction */
		return ( (1200/(Math.log(2)))*(Math.log(b/a)) );
    }
}
