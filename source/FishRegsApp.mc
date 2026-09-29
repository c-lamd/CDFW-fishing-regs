import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Regulation data: edit resources/jsonData/regs.json; data/split.py (run by build.sh) splits it into index.json
// and one g<N>.json per group. This file is the only place they are read. Only the index and the open group are
// held in memory, so the app fits the Descent G1's 96 KB.
var gIndex as Dictionary<String, Object>?;
var gGroup as Number = -1;
var gFish as Array<Dictionary<String, String>>?;

//! asof, group names and per-group counts.
function index() as Dictionary<String, Object> {
    var r = gIndex;
    if (r == null) {
        r = WatchUi.loadResource(Rez.JsonData.index) as Dictionary<String, Object>;
        gIndex = r;
    }
    return r;
}

//! The entries of group g; loading one group drops the previous one.
function groupFish(g as Number) as Array<Dictionary<String, String>> {
    var f = gFish;
    if (f == null || g != gGroup) {
        gFish = null;      // release the old group before the new one loads, so peak memory is one group
        f = WatchUi.loadResource(groupData(g)) as Array<Dictionary<String, String>>;
        gFish = f;
        gGroup = g;
    }
    return f;
}

class FishRegsApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [groupMenu(), new GroupDelegate()];
    }
}
