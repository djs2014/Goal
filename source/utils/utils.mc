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

function removeZeros(sourceArray as Array<Numeric>) as Array<Numeric> {
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


// Returns true if the color is light (needs black text), false if dark (needs white text)
function isColorLight(garminColor as Graphics.ColorType) as Boolean {
    // 1. Bit-shift to extract RGB channels
    var r = (garminColor >> 16) & 0xFF;
    var g = (garminColor >> 8) & 0xFF;
    var b = garminColor & 0xFF;

    // 2. Square the channels to match your HSP formula
    var rSq = (r * r).toFloat();
    var gSq = (g * g).toFloat();
    var bSq = (b * b).toFloat();

    // 3. Apply standard perceptual weights
    var hsp = Math.sqrt(0.299 * rSq + 0.587 * gSq + 0.114 * bSq);
    
    // 4. Return true if light, false if dark
    return (hsp > 127.5);
}