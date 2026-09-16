import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// All regulation data lives in resources/jsonData/regs.json; this file is the only place it is read.
// ponytail: whole file held in memory (~30 KB of strings on a 768 KB budget). Split per group if it ever grows past that.
var gRegs as Dictionary<String, Object>?;

function regs() as Dictionary<String, Object> {
    var r = gRegs;
    if (r == null) {
        r = WatchUi.loadResource(Rez.JsonData.regs) as Dictionary<String, Object>;
        gRegs = r;
    }
    return r;
}

function fish() as Array<Dictionary<String, String>> {
    return regs()["fish"] as Array<Dictionary<String, String>>;
}

class FishRegsApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [groupMenu(), new GroupDelegate()];
    }
}
