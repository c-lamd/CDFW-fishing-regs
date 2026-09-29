import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

//! Full-screen text for one field, paged with UP/DOWN. Own word wrap rather than TextArea:
//! TextArea truncates once the smallest font overflows, and a 300-char rule does overflow.
//! Each row is wrapped to the chord of the round screen at that height, so nothing clips.
class FieldView extends WatchUi.View {
    private const FONT = Graphics.FONT_XTINY;
    private const EDGE = 12;          // px kept clear of the bezel on every row
    private const TOP  = 0.72;        // rows span cy -/+ TOP*r

    private var _label as String;
    private var _text as String;
    private var _rowY as Array<Number> = [] as Array<Number>;      // one page of row geometry
    private var _rowW as Array<Number> = [] as Array<Number>;
    private var _lines as Array<String> = [] as Array<String>;     // wrapped; line i sits on row i % rows
    private var _labelLines as Number = 0;
    private var _page as Number = 0;

    function initialize(label as String, text as String) {
        View.initialize();
        _label = label.toUpper();
        _text = text;
    }

    function onLayout(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cy = h / 2;
        var r = (w < h ? w : h) / 2;
        var lh = dc.getFontHeight(FONT);
        _rowY = [] as Array<Number>;
        _rowW = [] as Array<Number>;
        var top = cy - (r * TOP).toNumber();
        if (WatchUi has :getSubscreen) {
            // Descent G1 (Instinct-style): a round sub-screen sits in the top-right corner; start rows below it.
            var sub = WatchUi.getSubscreen();
            if (sub != null && sub.y + sub.height > top) {
                top = sub.y + sub.height;
            }
        }
        for (var y = top; y + lh <= cy + (r * TOP).toNumber(); y += lh) {
            var dy = (y + lh / 2 - cy).abs();
            var half = Math.sqrt((r * r - dy * dy).toFloat()).toNumber() - EDGE;
            _rowY.add(y);
            _rowW.add(2 * half);
        }
        _lines = [] as Array<String>;
        wrap(dc, _label);
        _labelLines = _lines.size();
        wrap(dc, _text);
        _page = 0;
    }

    //! Greedy word wrap onto the row sequence, cycling through the page's rows.
    private function wrap(dc as Dc, text as String) as Void {
        var words = split(text);
        var line = "";
        for (var i = 0; i < words.size(); i++) {
            var word = words[i];
            if (word.equals("\n")) {
                if (!line.equals("")) {
                    _lines.add(line);
                    line = "";
                }
                continue;
            }
            var cand = line.equals("") ? word : line + " " + word;
            var width = _rowW[_lines.size() % _rowW.size()];
            if (dc.getTextWidthInPixels(cand, FONT) <= width || line.equals("")) {
                line = cand;      // ponytail: a single word wider than the row just overhangs
            } else {
                _lines.add(line);
                line = word;
            }
        }
        if (!line.equals("")) {
            _lines.add(line);
        }
    }

    private function split(text as String) as Array<String> {
        var out = [] as Array<String>;
        var chars = text.toCharArray();
        var word = "";
        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            if (c == ' ' || c == '\n') {
                if (!word.equals("")) {
                    out.add(word);
                    word = "";
                }
                if (c == '\n') {
                    out.add("\n");
                }
            } else {
                word += c.toString();
            }
        }
        if (!word.equals("")) {
            out.add(word);
        }
        return out;
    }

    function pages() as Number {
        return (_lines.size() + _rowY.size() - 1) / _rowY.size();
    }

    function turn(delta as Number) as Void {
        var p = _page + delta;
        if (p >= 0 && p < pages()) {
            _page = p;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        // On the real G2 the menu this opens from leaves its title-band clip on the dc; without this, only that band
        // gets drawn and the rest of the screen keeps showing the old menu. (The simulator resets it.)
        dc.clearClip();
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var cx = dc.getWidth() / 2;
        var rows = _rowY.size();
        for (var i = _page * rows; i < (_page + 1) * rows && i < _lines.size(); i++) {
            dc.setColor(i < _labelLines ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, _rowY[i % rows], FONT, _lines[i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (pages() > 1) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);   // DK_GRAY is black on the 1-bit G1
            dc.drawText(cx, dc.getHeight() - (dc.getFontHeight(FONT) * 3) / 2, FONT,
                        (_page + 1).toString() + "/" + pages().toString(), Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}

class FieldDelegate extends WatchUi.BehaviorDelegate {
    private var _view as FieldView;

    function initialize(view as FieldView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        _view.turn(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.turn(-1);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
