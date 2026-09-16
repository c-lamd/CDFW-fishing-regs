import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Three native Menu2 screens deep: group -> species -> field, then one text view.
// Native menus give scrolling, touch, fonts and the round-screen layout for free.

const FIELDS = ["bag", "size", "season", "spear", "notes", "src"] as Array<String>;
const LABELS = ["Bag", "Size", "Season", "Spear", "Notes", "Source"] as Array<String>;

//! Top level: one item per group, in first-seen order, then About.
function groupMenu() as Menu2 {
    var menu = new Menu2({:title => "Fish Regs"});
    var all = fish();
    var groups = [] as Array<String>;
    var counts = {} as Dictionary<String, Number>;
    for (var i = 0; i < all.size(); i++) {
        var g = all[i]["group"] as String;
        if (!counts.hasKey(g)) {
            groups.add(g);
            counts[g] = 0;
        }
        counts[g] = (counts[g] as Number) + 1;
    }
    for (var i = 0; i < groups.size(); i++) {
        var g = groups[i];
        menu.addItem(new MenuItem(g, (counts[g] as Number).toString() + " entries", g, null));
    }
    menu.addItem(new MenuItem("About", "Regs as of " + (regs()["asof"] as String), :about, null));
    return menu;
}

class GroupDelegate extends Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();
        if (id == :about) {
            var v = new FieldView("About", aboutText());
            pushView(v, new FieldDelegate(v), SLIDE_LEFT);
        } else {
            pushView(speciesMenu(id as String), new SpeciesDelegate(), SLIDE_LEFT);
        }
    }
}

//! One item per entry in the group. Sublabel is the glanceable pair: bag and size.
function speciesMenu(group as String) as Menu2 {
    var menu = new Menu2({:title => group});
    var all = fish();
    for (var i = 0; i < all.size(); i++) {
        var f = all[i];
        if (!(f["group"] as String).equals(group)) {
            continue;
        }
        var sub = glance(f);
        menu.addItem(new MenuItem(f["name"] as String, sub.equals("") ? null : sub, i, null));
    }
    return menu;
}

function glance(f as Dictionary<String, String>) as String {
    var bag = f["bag"] as String;
    var size = f["size"] as String;
    if (bag.equals("")) {
        return "";
    }
    return size.equals("") ? bag : bag + " | " + size;
}

class SpeciesDelegate extends Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as MenuItem) as Void {
        var f = fish()[item.getId() as Number];
        if (glance(f).equals("")) {
            // A rule, not a species: nothing but notes, so skip straight to the text.
            var v = new FieldView(f["name"] as String, (f["notes"] as String) + "\n" + (f["src"] as String));
            pushView(v, new FieldDelegate(v), SLIDE_LEFT);
        } else {
            pushView(detailMenu(f), new DetailDelegate(f), SLIDE_LEFT);
        }
    }
}

//! One item per non-empty field; select any to read it in full.
function detailMenu(f as Dictionary<String, String>) as Menu2 {
    var menu = new Menu2({:title => f["name"] as String});
    for (var i = 0; i < FIELDS.size(); i++) {
        var v = f[FIELDS[i]] as String;
        if (!v.equals("")) {
            menu.addItem(new MenuItem(LABELS[i], v, i, null));
        }
    }
    return menu;
}

class DetailDelegate extends Menu2InputDelegate {
    private var _f as Dictionary<String, String>;

    function initialize(f as Dictionary<String, String>) {
        Menu2InputDelegate.initialize();
        _f = f;
    }

    function onSelect(item as MenuItem) as Void {
        var i = item.getId() as Number;
        var v = new FieldView(LABELS[i], _f[FIELDS[i]] as String);
        pushView(v, new FieldDelegate(v), SLIDE_LEFT);
    }
}

function aboutText() as String {
    return "California recreational ocean sport fishing regs, Southern Management Area (Pt Conception to Mexico), as of "
        + (regs()["asof"] as String)
        + ". Compiled from CDFW and 14 CCR. Not legal advice: regs change in-season and MPAs are not listed. Verify at wildlife.ca.gov before you dive.";
}
