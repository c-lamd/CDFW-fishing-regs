import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Three native Menu2 screens deep: group -> species -> field, then one text view.
// Native menus give scrolling, touch, fonts and the round-screen layout for free.

const FIELDS = ["bag", "size", "season", "spear", "notes", "src"] as Array<String>;
const LABELS = ["Bag", "Size", "Season", "Spear", "Notes", "Source"] as Array<String>;

//! Top level: one item per group, in first-seen order, then About.
function groupMenu() as Menu2 {
    var menu = new Menu2({:title => WatchUi.loadResource(Rez.Strings.AppName) as String});
    var groups = index()["groups"] as Array<String>;
    var counts = index()["counts"] as Array<Number>;
    for (var i = 0; i < groups.size(); i++) {
        menu.addItem(new MenuItem(groups[i], counts[i].toString() + " entries", i, null));
    }
    menu.addItem(new MenuItem("About", "Regs as of " + (index()["asof"] as String), :about, null));
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
            pushView(speciesMenu(id as Number), new SpeciesDelegate(id as Number), SLIDE_LEFT);
        }
    }
}

//! One item per entry in the group. Sublabel is the glanceable pair: bag and size.
function speciesMenu(g as Number) as Menu2 {
    var menu = new Menu2({:title => (index()["groups"] as Array<String>)[g]});
    var all = groupFish(g);
    for (var i = 0; i < all.size(); i++) {
        var f = all[i];
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
    private var _g as Number;

    function initialize(g as Number) {
        Menu2InputDelegate.initialize();
        _g = g;
    }

    function onSelect(item as MenuItem) as Void {
        var f = groupFish(_g)[item.getId() as Number];
        if (glance(f).equals("")) {
            // A rule, not a species: nothing but notes, so skip straight to the text.
            var v = new FieldView(f["name"] as String, (f["notes"] as String) + "\n" + (f["src"] as String));
            pushView(v, new FieldDelegate(v), SLIDE_LEFT);
        } else {
            pushView(detailMenu(f), new DetailDelegate(f), SLIDE_LEFT);
        }
    }
}

//! Titled with the species photo when there is one (see PhotoTitle.mc), else its name. One item per non-empty field;
//! select any to read it in full.
function detailMenu(f as Dictionary<String, String>) as Menu2 {
    var p = photo(f["name"] as String);
    var menu = p != null ? photoMenu(f["name"] as String, p) : new Menu2({:title => f["name"] as String});
    for (var i = 0; i < FIELDS.size(); i++) {
        var v = f[FIELDS[i]] as String;
        if (!v.equals("")) {
            menu.addItem(p != null ? new FieldItem(i, LABELS[i], v) : new MenuItem(LABELS[i], v, i, null));
        }
    }
    if (p != null) {
        menu.addItem(new FieldItem(:credit, "Photo credit", p[1] as String));
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
        if (item.getId() == :credit) {
            var c = new FieldView("Photo credit", photo(_f["name"] as String)[1] as String);
            pushView(c, new FieldDelegate(c), SLIDE_LEFT);
            return;
        }
        var i = item.getId() as Number;
        var v = new FieldView(LABELS[i], _f[FIELDS[i]] as String);
        pushView(v, new FieldDelegate(v), SLIDE_LEFT);
    }
}

function aboutText() as String {
    return "Unofficial guide to California recreational ocean sport fishing regs, Southern Management Area (Pt Conception to Mexico), as of "
        + (index()["asof"] as String)
        + ". Compiled from CDFW and 14 CCR and kept current with CDFW rules; not affiliated with CDFW. Photos from Wikimedia Commons; credit and license under each species. Not legal advice: regs change in-season and MPAs are not listed. Verify at wildlife.ca.gov before you dive.";
}
