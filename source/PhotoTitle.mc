import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// A species with a photo gets a CustomMenu instead of Menu2: Menu2's title is only 211x87 on a 390 px
// screen, too small to ID a fish. CustomMenu's title is everything above the centred focused row
// (screen/2 - row/2); the price is drawing the rows ourselves. Sizes are tuned on 390 px and scale
// with the screen; photos are pre-scaled per device by the compiler (photos.xml, scaleRelativeTo="screen").

const LABEL_FONT = Graphics.FONT_SMALL;
const SUB_FONT = Graphics.FONT_XTINY;

function photoMenu(name as String, p as Array) as CustomMenu {
    var h = System.getDeviceSettings().screenHeight;
    var fonts = Graphics.getFontHeight(LABEL_FONT) + Graphics.getFontHeight(SUB_FONT);
    var row = h * 64 / 390;
    if (row < fonts + 6) {
        row = fonts + 6;      // small MIP screens: fonts don't shrink with the screen
    }
    return new CustomMenu(row, Graphics.COLOR_BLACK,
        {:title => new PhotoTitle(name, p), :titleItemHeight => h / 2 - row / 2});
}

//! Species name on top, photo filling the band under it.
class PhotoTitle extends WatchUi.Drawable {
    private var _name as String;
    private var _id as ResourceId;
    private var _bmp as BitmapResource?;

    function initialize(name as String, p as Array) {
        Drawable.initialize({});
        _name = name;
        _id = p[0] as ResourceId;
    }

    function draw(dc as Dc) as Void {
        var b = _bmp;
        if (b == null) {
            b = WatchUi.loadResource(_id) as BitmapResource;
            _bmp = b;
        }
        var s = System.getDeviceSettings().screenHeight;
        var nameY = s * 26 / 390;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, nameY, SUB_FONT, fit(dc, _name, s * 200 / 390), Graphics.TEXT_JUSTIFY_CENTER);
        // Photos come pre-scaled to full width and may be taller than the room left under the name
        // (data/photos.py CROP): centre them in that band and clip off the top and bottom.
        var top = nameY + dc.getFontHeight(SUB_FONT);
        var band = dc.getHeight() - top - s * 4 / 390;
        var bh = b.getHeight() < band ? b.getHeight() : band;
        top += (band - bh) / 2;
        dc.setClip(0, top, dc.getWidth(), bh);
        dc.drawBitmap((dc.getWidth() - b.getWidth()) / 2, top - (b.getHeight() - bh) / 2, b);
        dc.clearClip();
    }
}

//! Label over sublabel, centred on the screen; the focused row is white, the rest gray, like Menu2.
class FieldItem extends WatchUi.CustomMenuItem {
    private var _label as String;
    private var _sub as String;

    function initialize(id as Object, label as String, sub as String) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        _sub = sub;
    }

    function draw(dc as Dc) as Void {
        // The item dc is right-aligned and narrower than the screen (the focus bar takes the left strip),
        // so centre on the screen, not the dc, to line up with the photo.
        var cx = dc.getWidth() - System.getDeviceSettings().screenWidth / 2;
        var lh = dc.getFontHeight(LABEL_FONT);
        var top = (dc.getHeight() - lh - dc.getFontHeight(SUB_FONT)) / 2;
        dc.setColor(isFocused() ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, top, LABEL_FONT, _label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, top + lh, SUB_FONT, fit(dc, _sub, 2 * cx - 30), Graphics.TEXT_JUSTIFY_CENTER);
    }
}

//! Trim to width with "...", as Menu2 does with long sublabels.
function fit(dc as Dc, s as String, w as Number) as String {
    if (dc.getTextWidthInPixels(s, SUB_FONT) <= w) {
        return s;
    }
    var n = s.length();
    while (n > 0 && dc.getTextWidthInPixels(s.substring(0, n) + "...", SUB_FONT) > w) {
        n--;
    }
    return s.substring(0, n) + "...";
}
