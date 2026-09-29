import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
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

//! Species name on top, photo filling the band under it. draw() runs on every scroll frame, so everything
//! that doesn't change (trimmed name, layout) is worked out on the first draw and kept.
class PhotoTitle extends WatchUi.Drawable {
    private var _name as String;
    private var _id as ResourceId;
    private var _bmp as BitmapResource?;
    private var _nameY as Number = 0;
    private var _photoY as Number = 0;       // top of the visible photo band
    private var _photoH as Number = 0;       // height of that band (photo clipped to it)

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
            layout(dc, b);
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, _nameY, SUB_FONT, _name, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setClip(0, _photoY, dc.getWidth(), _photoH);
        dc.drawBitmap((dc.getWidth() - b.getWidth()) / 2, _photoY - (b.getHeight() - _photoH) / 2, b);
        dc.clearClip();
    }

    private function layout(dc as Dc, b as BitmapResource) as Void {
        var s = System.getDeviceSettings().screenHeight;
        var fh = dc.getFontHeight(SUB_FONT);
        _nameY = s * 26 / 390;
        // Name width: the round screen's chord at the name's middle, less a margin (fonts differ per device).
        var r = s / 2;
        var dy = r - _nameY - fh / 2;
        _name = fit(dc, _name, 2 * Math.sqrt(r * r - dy * dy).toNumber() - s * 24 / 390);
        // Photos come pre-scaled to full width and may be taller than the room left under the name
        // (data/photos.py CROP): centre them in that band and clip off the top and bottom.
        var top = _nameY + fh;
        var band = dc.getHeight() - top - s * 4 / 390;
        _photoH = b.getHeight() < band ? b.getHeight() : band;
        _photoY = top + (band - _photoH) / 2;
    }
}

//! Label over sublabel, centred on the screen; the focused row is white, the rest gray, like Menu2.
//! Like PhotoTitle, the trimmed sublabel and the layout are computed on the first draw only.
class FieldItem extends WatchUi.CustomMenuItem {
    private var _label as String;
    private var _sub as String;
    private var _cx as Number = -1;
    private var _top as Number = 0;

    function initialize(id as Object, label as String, sub as String) {
        CustomMenuItem.initialize(id, {});
        _label = label;
        _sub = sub;
    }

    function draw(dc as Dc) as Void {
        var lh = dc.getFontHeight(LABEL_FONT);
        if (_cx < 0) {
            // The item dc is right-aligned and narrower than the screen (the focus bar takes the left strip),
            // so centre on the screen, not the dc, to line up with the photo.
            _cx = dc.getWidth() - System.getDeviceSettings().screenWidth / 2;
            _top = (dc.getHeight() - lh - dc.getFontHeight(SUB_FONT)) / 2;
            _sub = fit(dc, _sub, 2 * _cx - 30);
        }
        dc.setColor(isFocused() ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, _top, LABEL_FONT, _label, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(_cx, _top + lh, SUB_FONT, _sub, Graphics.TEXT_JUSTIFY_CENTER);
    }
}

//! Trim to width with "...", as Menu2 does with long sublabels. Binary search on the cut point, so a long
//! string costs ~6 text measurements, not one per character.
function fit(dc as Dc, s as String, w as Number) as String {
    if (dc.getTextWidthInPixels(s, SUB_FONT) <= w) {
        return s;
    }
    var lo = 0;                 // longest prefix known to fit (with "...")
    var hi = s.length();        // shortest prefix known not to fit
    while (hi - lo > 1) {
        var mid = (lo + hi) / 2;
        if (dc.getTextWidthInPixels(s.substring(0, mid) + "...", SUB_FONT) <= w) {
            lo = mid;
        } else {
            hi = mid;
        }
    }
    return s.substring(0, lo) + "...";
}
