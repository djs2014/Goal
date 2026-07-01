import Toybox.System;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Graphics;
import Toybox.Time;
import Toybox.Time.Gregorian;

var gCreateColors as Boolean = false;
var gUseSetFillStroke as Boolean = false;

function checkFeatures() as Void {
    $.gCreateColors = Graphics has :createColor;
    try {
        $.gUseSetFillStroke = Graphics.Dc has :setStroke;
        if ($.gUseSetFillStroke) {
            $.gUseSetFillStroke = Graphics.Dc has :setFill;
        }
    } catch (ex) {
        ex.printStackTrace();
    }
}

function transitionFromTo(
    alpha as Number,
    redFrom as Numeric,
    greenFrom as Numeric,
    blueFrom as Numeric,
    redTo as Numeric,
    greenTo as Numeric,
    blueTo as Numeric,
    percent as Float // 0.0-1.0
) as Graphics.ColorType {
    var factor = percent;
    var red = Math.round(redFrom + (redTo - redFrom) * factor);
    var green = Math.round(greenFrom + (greenTo - greenFrom) * factor);
    var blue = Math.round(blueFrom + (blueTo - blueFrom) * factor);

    // System.println(["transitionFromTo", alpha, redFrom, greenFrom, blueFrom, redTo, greenTo, blueTo, percent, "%", red, green, blue]);

    return Graphics.createColor(
        alpha,
        red.toNumber(),
        green.toNumber(),
        blue.toNumber()
    );
}

function logInfo(info) as Void {
    var clockTime = System.getClockTime();

    var timeString = Lang.format("$1$:$2$:$3$ - $4$", [
        clockTime.hour.format("%02d"),
        clockTime.min.format("%02d"),
        clockTime.sec.format("%02d"),
        info,
    ]);

    System.println(timeString);
}

function formatSecondsToHMS(totalSeconds as Number?) as String {
    if (totalSeconds == null) {
        return "00:00:00";
    }
    totalSeconds = totalSeconds.toNumber();

    // 1. Extract the individual time components using integer division and modulo
    var hours = totalSeconds / 3600;
    var minutes = (totalSeconds % 3600) / 60;
    var seconds = totalSeconds % 60;

    // 2. Format into hh:mm:ss with zero-padding
    // "%02d" means: print as a decimal integer, at least 2 digits wide, padding with 0 if needed
    return Lang.format("$1$:$2$:$3$", [
        hours.format("%02d"),
        minutes.format("%02d"),
        seconds.format("%02d"),
    ]);
}
function formatSecondsToHM(totalSeconds as Number?) as String {
    if (totalSeconds == null) {
        return "00:00";
    }
    totalSeconds = totalSeconds.toNumber();
    // 1. Extract the individual time components using integer division and modulo
    var hours = totalSeconds / 3600;
    var minutes = (totalSeconds % 3600) / 60;

    // 2. Format into hh:mm:ss with zero-padding
    // "%02d" means: print as a decimal integer, at least 2 digits wide, padding with 0 if needed
    return Lang.format("$1$:$2$", [
        hours.format("%02d"),
        minutes.format("%02d"),
    ]);
}

// TODO add start index
function removeZeros(
    sourceArray as Array<Numeric or FieldType>
) as Array<Numeric or FieldType> {
    var size = sourceArray.size();

    // 1. First pass: Count how many non-zero elements exist
    // This lets us allocate the perfect size immediately (no fragmentation)
    var nonZeroCount = 0;
    for (var i = 0; i < size; i++) {
        if (sourceArray[i] != 0 && sourceArray[i] != null) {
            nonZeroCount++;
        }
    }

    // 2. Allocate the exact clean array size
    var cleanArray = new Array<Numeric>[nonZeroCount];
    var targetIndex = 0;

    // 3. Second pass: Populate the clean array
    for (var i = 0; i < size; i++) {
        var val = sourceArray[i];
        if (val != 0 && val != null) {
            cleanArray[targetIndex] = val;
            targetIndex++;
        }
    }

    return cleanArray;
}

// Returns the maximum number of characters from the string that can fit in the available pixels
function getMaxCharactersThatFit(
    dc as Graphics.Dc,
    text as String,
    font as Graphics.FontType,
    maxAvailablePixels as Number
) as Number {
    // If the entire string already fits, return its full length
    if (dc.getTextWidthInPixels(text, font) <= maxAvailablePixels) {
        return text.length();
    }

    // Binary search or loop backward to find the exact cutoff point
    var testString = "";
    for (var i = 0; i < text.length(); i++) {
        testString = text.substring(0, i + 1);
        var currentWidth = dc.getTextWidthInPixels(testString, font);

        // If adding this character overflows the bar space, stop here
        if (currentWidth > maxAvailablePixels) {
            return i; // Returns the index count of characters that safely fit
        }
    }

    return text.length();
}

var gHspDarklightBreakpoint as Float = 127.5;
// Returns true if the color is light (needs black text), false if dark (needs white text)
// HSP 0 is darkest (black), 255 is lightest (white). The threshold is set at 127.5 by default, but can be adjusted via settings.
function isColorLight(garminColor as Graphics.ColorType) as Boolean {
    // 1. Bit-shift to extract RGB channels
    var r = (garminColor >> 16) & 0xff;
    var g = (garminColor >> 8) & 0xff;
    var b = garminColor & 0xff;

    // 2. Square the channels to match your HSP formula
    var rSq = (r * r).toFloat();
    var gSq = (g * g).toFloat();
    var bSq = (b * b).toFloat();

    // 3. Apply standard perceptual weights
    var hsp = Math.sqrt(0.299 * rSq + 0.587 * gSq + 0.114 * bSq);

    // 4. Return true if light, false if dark
    // 127.5 is the midpoint of the 0-255 range, which is a common threshold for determining light vs dark colors
    if ($.gHspDarklightBreakpoint == null || $.gHspDarklightBreakpoint < 0 || $.gHspDarklightBreakpoint > 255) {
        $.gHspDarklightBreakpoint = 127.5; // Default to midpoint if not set
    }
    return hsp > $.gHspDarklightBreakpoint;
}

function calculateHSP(garminColor as Graphics.ColorType) as Float {
    // 1. Bit-shift to extract RGB channels
    var r = (garminColor >> 16) & 0xff;
    var g = (garminColor >> 8) & 0xff;
    var b = garminColor & 0xff;

    // 2. Square the channels to match your HSP formula
    var rSq = (r * r).toFloat();
    var gSq = (g * g).toFloat();
    var bSq = (b * b).toFloat();

    // 3. Apply standard perceptual weights
    return Math.sqrt(0.299 * rSq + 0.587 * gSq + 0.114 * bSq);
}

function getMatchingFont(
  dc as Dc,
  fontList as Array<FontType>,
  maxWidth as Number,
  maxHeight as Number,
  text as String
) as FontType {
  var index = fontList.size() - 1;
  var font = fontList[index] as FontType;
  // System.println(Lang.format("text[$1$] max w[$2$]h[$3$]",[text, maxWidth, maxHeight]));
  // wxh
  var dimensions = dc.getTextDimensions(text, font);
  // System.println(Lang.format(" dim w[$1$]h[$2$]",dimensions));
  // while height or width of font too big, find another font
  while ((dimensions[0] > maxWidth || dimensions[1] > maxHeight) && index > 0) {
    index = index - 1;
    font = fontList[index] as FontType;
    dimensions = dc.getTextDimensions(text, font);
    // System.println(Lang.format(" dim w[$1$]h[$2$]",dimensions));
  }
  // System.println("font index: " + index);
  return font;
}