import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

var gMaxProgressColumns as Number = 10;

class GoalsView extends WatchUi.DataField {
    hidden var mDemoStartTime as Number = 0;
    hidden var mDemoCounter1 as Number = 0;
    hidden var mDemoCounter2 as Number = 0;
    hidden var mDemoCounter3 as Number = 0;
    hidden var mDemoCounter4 as Number = 0;
    hidden var mDemoCounter5 as Number = 0;
    hidden var mDemoCounter6 as Number = 0;
    hidden var mDemoCounter7 as Number = 0;
    hidden var mDemoCounter8 as Number = 0;
    hidden var mDemoCounter9 as Number = 0;
    hidden var mDemoCounter10 as Number = 0;

    hidden var mDarkBackground as Boolean = false;
    hidden var mFieldLayout as FieldLayout = FLVertical;
    hidden var mPaused as Boolean = true;
    hidden var mPauseExtendedCounter as Number = 10;
    hidden var mPausedShowDetails as Boolean = true;

    hidden var mProgressFields as Array<FieldType> = new Array<
        FieldType
    >[$.gMaxProgressColumns];
    hidden var mProgressArray as Array<Float> = new Array<
        Float
    >[$.gMaxProgressColumns];
    hidden var mProgressColors as Array<Graphics.ColorType> = new Array<
        Graphics.ColorType
    >[$.gMaxProgressColumns];

    hidden var mProgress as Progress = new Progress();
    hidden var mNormPowerEngine as NormPowerEngine = new NormPowerEngine();
    hidden var mHasCourseNavigation as Boolean = false;

    function initialize() {
        DataField.initialize();
    }

    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Graphics.Dc) as Void {
        var showFields =
            $.getStorageValue("show_fields", [$.gShowFieldsArraySize]) as
            Array<Numeric or FieldLayout>;
        if ($.ensureArraySize(showFields, $.gShowFieldsArraySize, 0)) {
            $.setStorageValueOrArray("show_fields", showFields);
        }
        // Layout
        mFieldLayout = showFields[0] as FieldLayout;
        mProgressFields = showFields.slice(1, null) as Array<FieldType>;
        // Remove the entries `where no field is assigned (value of 0)
        mProgressFields = $.removeZeros(mProgressFields);
        // Add to maximum size to match mProgressArray size
        $.ensureArraySize(mProgressFields, $.gMaxProgressColumns, 0);
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        if (info has :timerState) {
            mPaused =
                info.timerState == Activity.TIMER_STATE_PAUSED or
                info.timerState == Activity.TIMER_STATE_OFF;
        } else {
            mPaused = true;
            mPauseExtendedCounter = 10;
        }

        if (mPaused) {
            mPausedShowDetails = true;
            mPauseExtendedCounter = 10;
        } else if (mPauseExtendedCounter <= 0) {
            mPauseExtendedCounter = 0;
            mPausedShowDetails = false;
        } else {
            mPauseExtendedCounter -= 1;
        }
        // $.logInfo(["Compute: Demo mode:", $.gDemo, "Paused:", mPaused]);
        if (mPaused && $.gDemo) {
            SimulateProgress(info);
        } else {
            mDemoStartTime = 0; // reset demo time so it starts from the beginning when toggled on
            $.gDemo = false; // reset demo flag so it doesn't keep simulating when paused

            var power = $.getActivityValue(info, :currentPower, 0) as Number;
            var np = mNormPowerEngine.compute(power);
            mProgress.setNormalizedPower(np);

            if (!mPaused) {
                // Update progress values
                for (var i = 0; i < mProgressFields.size(); i++) {
                    var fieldType = mProgressFields[i];
                    mProgressArray[i] = mProgress.getProgressForField(
                        info,
                        fieldType
                    );
                }
            }
        }
        // Check if we have course navigation data available by checking if distanceToDestination is non-zero
        mHasCourseNavigation =
            ($.getActivityValue(info, :distanceToDestination, 0.0f) as Float) >
            0.0f;

        var numBars = mProgressArray.size();
        for (var i = 0; i < numBars; i++) {
            mProgressColors[i] = getDynamicColor(mProgressArray[i]);
        }
    }

    hidden function getValidFieldCount() as Number {
        var count = 0;
        for (var i = 0; i < mProgressFields.size(); i++) {
            if (mProgressFields[i] != null && mProgressFields[i] != 0) {
                count++;
            }
        }
        return count;
    }
    hidden function SimulateProgress(info as Activity.Info) as Void {
        if (mDemoStartTime == 0) {
            mDemoStartTime = 1;
        } else {
            mDemoStartTime = mDemoStartTime + 1;
            if (mDemoStartTime > 120) {
                // 2 minutes max demo
                mDemoStartTime = 1;
            }
        }

        mDemoCounter1 = (mDemoCounter1 + 2) % 200; // Loop from 0 to 199
        mDemoCounter2 = (mDemoCounter2 + 3).toNumber() % 200;
        mDemoCounter3 = (mDemoCounter3 + 4).toNumber() % 250;
        mDemoCounter4 = (mDemoCounter4 + 5).toNumber() % 200;
        mDemoCounter5 = (mDemoCounter5 + 6).toNumber() % 200;
        mDemoCounter6 = (mDemoCounter6 + 7).toNumber() % 200;
        mDemoCounter7 = (mDemoCounter7 + 8).toNumber() % 150;
        mDemoCounter8 = (mDemoCounter8 + 9).toNumber() % 150;
        mDemoCounter9 = (mDemoCounter9 + 10).toNumber() % 150;
        mDemoCounter10 = (mDemoCounter10 + 11).toNumber() % 150;

        mProgressArray =
            [
                mDemoCounter1 / 100.0,
                mDemoCounter2 / 100.0,
                mDemoCounter3 / 100.0,
                mDemoCounter4 / 100.0,
                mDemoCounter5 / 100.0,
                mDemoCounter6 / 100.0,
                mDemoCounter7 / 100.0,
                mDemoCounter8 / 100.0,
                mDemoCounter9 / 100.0,
                mDemoCounter10 / 100.0,
            ] as Array<Float>;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Graphics.Dc) as Void {
        if ($.gExitedMenu) {
            // fix for leaving menu, draw complete screen, large field
            dc.clearClip();
            $.gExitedMenu = false;
        }

        var backgroundColor = getBackgroundColor();
        mDarkBackground = backgroundColor == Graphics.COLOR_BLACK;
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();

        var screenW = dc.getWidth();
        var screenH = dc.getHeight();

        // Only defined fields
        var numBars = getValidFieldCount();
        if (numBars == 0) {
            return;
        }

        var margin = 10; // Padding from screen edges
        var gap = 8; // Space between individual bars

        // 3. Render based on orientation setting
        switch (mFieldLayout) {
            case FLVertical:
                // Calculate dynamic width for vertical pillars side-by-side
                var availableWidth = screenW - margin * 2;
                var totalGapWidth = (numBars - 1) * gap;
                var barWidthVertical = (
                    (availableWidth - totalGapWidth) /
                    numBars
                ).toNumber();

                var barHeightVertical = screenH - margin * 2;

                for (var i = 0; i < numBars; i++) {
                    // Calculate individual starting X position for each bar
                    var barX = margin + i * (barWidthVertical + gap);
                    var barY = margin;

                    drawVerticalProgressBar(
                        dc,
                        barX,
                        barY,
                        barWidthVertical,
                        barHeightVertical,
                        mProgressArray[i],
                        mProgressColors[i],
                        mProgressFields[i]
                    );
                }
                break;
            default:
            case FLHorizontal:
                // Calculate dynamic height for horizontal rows stacked vertically
                var availableHeight = screenH - margin * 2;
                var totalGapHeight = (numBars - 1) * gap;
                var barHeightHorizontal = (
                    (availableHeight - totalGapHeight) /
                    numBars
                ).toNumber();

                var barWidthHorizontal = screenW - margin * 2;

                for (var i = 0; i < numBars; i++) {
                    // Calculate individual starting Y position for each bar
                    var barX = margin;
                    var barY = margin + i * (barHeightHorizontal + gap);
                    drawHorizontalProgressBar(
                        dc,
                        barX,
                        barY,
                        barWidthHorizontal,
                        barHeightHorizontal,
                        mProgressArray[i],
                        mProgressColors[i],
                        mProgressFields[i]
                    );
                }
                break;
        }
    }

    function getDynamicColor(progress as Float?) as Graphics.ColorType {
        if (progress == null) {
            progress = 0.0f;
        }
        // 1. Blue to Green (0% to 50%)
        if (progress <= 0.5) {
            // Map 0.0-0.5 progress to a 0.0-1.0 factor
            var factor = progress / 0.5;
            // Pure Blue [0, 0, 255] to Pure Green [0, 255, 0]
            return $.transitionFromTo(255, 0, 0, 255, 0, 255, 0, factor);
        }
        // 2. Green to Bright Yellow/Gold (50% to 100%)
        else if (progress <= 1.0) {
            // Map 0.5-1.0 progress to a 0.0-1.0 factor
            var factor = (progress - 0.5) / 0.5;
            // Pure Green [0, 255, 0] to Bright Gold/Yellow [255, 215, 0]
            return $.transitionFromTo(255, 0, 255, 0, 255, 215, 0, factor);
        }
        // 3. Gold to Dark Red (100% to 200%+)
        else if (progress <= 2.0) {
            // Map 1.0-2.0 progress to a 0.0-1.0 factor. Cap it at 1.0 so it doesn't break past 200%
            var factor = (progress - 1.0) / 1.0;
            if (factor > 1.0) {
                factor = 1.0;
            }

            // Gold [255, 215, 0] to Dark Red [139, 0, 0]
            return $.transitionFromTo(255, 255, 215, 0, 139, 0, 0, factor);
        } else {
            // Dark Red [139, 0, 0] to maroon black as it goes beyond 200%
            var factor = (progress - 2.0) / 1.0;
            if (factor > 1.0) {
                factor = 1.0;
            }
            return $.transitionFromTo(255, 139, 0, 0, 40, 0, 5, factor);
        }
    }

    hidden function drawVerticalProgressBar(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        w as Number,
        h as Number,
        progress as Float?,
        barColor as Graphics.ColorType,
        fieldType as FieldType
    ) as Void {
        if (progress == null) {
            progress = 0.0f;
        }
        var colors = getThemeColor(mDarkBackground);
        var visualProgress =
            progress > 1.0 ? 1.0 : progress < 0.0 ? 0.0 : progress;

        dc.setPenWidth(1);
        // Draw the background "Empty" track
        var trackColor = colors[:track];
        dc.setColor(trackColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);

        // Fill (from bottom up)
        var fillHeight = (h * visualProgress).toNumber();
        if (fillHeight > 0) {
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y + h - fillHeight, w, fillHeight, 4);
        }

        // draw a border around the bar for better visibility
        dc.setColor(colors[:border], Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, 4);

        // Embedded Checkmark Overlay (If Goal is met/exceeded)
        if (progress >= 1.0) {
            // We will position the checkmark near the top of the bar
            // Centered horizontally within the width 'w'

            // Set line properties for a crisp, tiny vector checkmark
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // White pops best on colors
            dc.setPenWidth(2);

            // Micro-coordinates scaled nicely to fit a 14px-20px wide bar
            var checkSize = (w * 0.25).toNumber(); // Scales the checkmark to the bar width
            if (checkSize < 4) {
                checkSize = 4;
            } // Safety for ultra-thin configurations

            var cx = x + w / 2;
            var cy = y + w / 2 + 2;
            dc.drawLine(cx - checkSize, cy, cx - checkSize / 3, cy + checkSize);
            dc.drawLine(
                cx - checkSize / 3,
                cy + checkSize,
                cx + checkSize,
                cy - checkSize
            );
        }
        if (mPausedShowDetails || $.gShowLabels) {
            // Label centered at the bottom of the bar when paused
            var tx = x + w / 2;
            var ty = y + h - dc.getFontHeight(Graphics.FONT_XTINY) - 2;
            var label = getFieldLabel(fieldType);

            var maxBarTextWidth = w - 4; // Leave a 2px padding buffer on each side
            var fitCount = $.getMaxCharactersThatFit(
                dc,
                label,
                Graphics.FONT_XTINY,
                maxBarTextWidth
            );

            if (label.length() <= fitCount) {
                var currentUnderlyingColor = trackColor; // Default track background
                // Check if the text is submerged in the filled part of the bar
                if (
                    fillHeight > 0 &&
                    ty + dc.getFontHeight(Graphics.FONT_XTINY) / 2 >=
                        y + h - fillHeight
                ) {
                    currentUnderlyingColor = barColor; // It's submerged in the progress bar fill!
                }
                // Automatically choose the best contrasting text color
                if ($.isColorLight(currentUnderlyingColor)) {
                    dc.setColor(
                        Graphics.COLOR_BLACK,
                        Graphics.COLOR_TRANSPARENT
                    ); // Dark text on light backgrounds
                } else {
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    ); // Light text on dark backgrounds
                }

                dc.drawText(
                    tx,
                    ty,
                    Graphics.FONT_XTINY,
                    label,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else {
                // Draw text vertical
                drawStackedVerticalLabel(
                    dc,
                    label,
                    Graphics.FONT_XTINY,
                    x,
                    w,
                    y,
                    h,
                    fillHeight,
                    barColor,
                    trackColor
                );
            }
        }
    }

    hidden function drawStackedVerticalLabel(
        dc as Graphics.Dc,
        text as String,
        font as Graphics.FontType,
        barX as Number,
        barWidth as Number,
        barY as Number,
        barHeight as Number,
        fillHeight as Number, // Pass the current physical pixel height of the color fill
        barColor as ColorType, // Pass the current dynamic color of the bar
        trackColor as ColorType // Pass the default background color of the track for contrast calculations
    ) as Void {
        var fontHeight = dc.getFontHeight(font);
        var totalTextHeight = text.length() * fontHeight;
        var centerX = barX + barWidth / 2;
        var startY = barY + (barHeight - totalTextHeight) / 2;

        // Calculate the absolute Y pixel where the color fill ends
        var fillTopY = barY + barHeight - fillHeight;

        // Determine what color is currently underneath this specific letter

        for (var i = 0; i < text.length(); i++) {
            var charStr = text.substring(i, i + 1);
            var charY = startY + i * fontHeight;
            var currentUnderlyingColor = trackColor; // Default track background

            // Check if this specific character is inside the filled part of the bar
            if (fillHeight > 0 && charY + fontHeight / 2 >= fillTopY) {
                currentUnderlyingColor = barColor; // It's submerged in the progress bar fill!
            }
            // Automatically choose the best contrasting text color
            if ($.isColorLight(currentUnderlyingColor)) {
                dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT); // Dark text on light backgrounds
            } else {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT); // Light text on dark backgrounds
            }

            dc.drawText(
                centerX,
                charY,
                font,
                charStr,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    hidden function drawHorizontalProgressBar(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        w as Number,
        h as Number,
        progress as Float?,
        barColor as Graphics.ColorType,
        fieldType as FieldType
    ) as Void {
        if (progress == null) {
            progress = 0.0f;
        }
        var colors = getThemeColor(mDarkBackground);
        var visualProgress =
            progress > 1.0 ? 1.0 : progress < 0.0 ? 0.0 : progress;

        // 1. Draw the empty background track
        var trackColor = colors[:track];
        dc.setColor(trackColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, w, h);

        // 2. Calculate the color fill width and its absolute right X boundary
        var fillWidth = (w * visualProgress).toNumber();
        var fillRightX = x + fillWidth;

        if (fillWidth > 0) {
            dc.setColor(barColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, fillWidth, h, 4);
        }

        // draw a border around the bar for better visibility
        dc.setColor(colors[:border], Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x, y, w, h, 4);

        // 5. Inline Checkmark (Rendered at the far right edge of the bar)
        // Inline Checkmark (Centered at the far right edge of the horizontal bar)
        if (progress >= 1.0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            var checkSize = (h * 0.25).toNumber();
            if (checkSize < 4) {
                checkSize = 4;
            }

            // Anchor checkmark right inside the completed end of the track
            var cx = x + w - h / 2;
            var cy = y + h / 2;
            dc.drawLine(cx - checkSize, cy, cx - checkSize / 3, cy + checkSize);
            dc.drawLine(
                cx - checkSize / 3,
                cy + checkSize,
                cx + checkSize,
                cy - checkSize
            );
        }
        if (mPausedShowDetails || $.gShowLabels) {
            var textLabel = getFieldLabelWide(fieldType);
            var font = Graphics.FONT_XTINY;

            // 3. Draw the horizontal text character-by-character
            var fontHeight = dc.getFontHeight(font);

            // Position text: Centered vertically inside the bar height, with a 6px left margin
            var startX = x + 6;
            var textY = y + (h - fontHeight) / 2;

            var currentX = startX;

            for (var i = 0; i < textLabel.length(); i++) {
                var charStr = textLabel.substring(i, i + 1);
                var charWidth = dc.getTextWidthInPixels(charStr, font);

                // Determine the horizontal midpoint of this specific letter
                var charMidX = currentX + charWidth / 2;

                // 4. Contrast Check: Is this letter's midpoint inside the filled color block?
                var underlyingColor = trackColor;
                if (fillWidth > 0 && charMidX <= fillRightX) {
                    underlyingColor = barColor; // Letter is sitting on top of the color fill
                }

                // Apply your HSP formula logic
                if (isColorLight(underlyingColor)) {
                    dc.setColor(
                        Graphics.COLOR_BLACK,
                        Graphics.COLOR_TRANSPARENT
                    );
                } else {
                    dc.setColor(
                        Graphics.COLOR_WHITE,
                        Graphics.COLOR_TRANSPARENT
                    );
                }

                // Draw the single character (use Left justification so they chain properly)
                dc.drawText(
                    currentX,
                    textY,
                    font,
                    charStr,
                    Graphics.TEXT_JUSTIFY_LEFT
                );

                // Advance the X cursor forward by the letter's width for the next character
                currentX += charWidth;
            }
        }
    }

    hidden var SIN_TABLE as Array<Float> = new Array<Float>[360];
    hidden var COS_TABLE as Array<Float> = new Array<Float>[360];
    hidden function point2DOnCircle(
        x as Number,
        y as Number,
        radius as Lang.Numeric,
        angleInDegrees as Lang.Numeric
    ) as Point2D {
        // Check if the first element is null to see if we need to initialize
        if (SIN_TABLE[0] == null) {
            var DEG_TO_RAD = Math.PI / 180;
            for (var angle = 0; angle < 360; angle++) {
                // Assign directly to the index instead of using .add()
                SIN_TABLE[angle] = Math.sin(angle * DEG_TO_RAD).toFloat();
                COS_TABLE[angle] = Math.cos(angle * DEG_TO_RAD).toFloat();
            }
        }

        var angleInt = angleInDegrees.toNumber() % 360;
        if (angleInt < 0) {
            angleInt = angleInt + 360;
        }

        // The compiler now knows 100% that these return Floats
        var sin = SIN_TABLE[angleInt] as Float;
        var cos = COS_TABLE[angleInt] as Float;

        var xP = radius.toFloat() * cos + x;
        var yP = radius.toFloat() * sin + y;

        return [xP.toNumber(), yP.toNumber()] as Point2D;
    }

    hidden function getFieldLabel(fieldType as FieldType) as String {
        switch (fieldType) {
            case FTDistance:
                return "DST";
            case FTCalories:
                return "CAL";
            case FTAverageHeartRate:
                return "AHR";
            case FTAveragePower:
                return "APW";
            case FTAverageSpeed:
                return "AVS";
            case FTAverageCadence:
                return "RPM";
            case FTNormalizedPower:
                return "NP";
            case FTTotalAscent:
                return "ASC";
            case FTTotalDescent:
                return "DSC";
            case FTMinutesElapsed:
                return "TIM";
            case FTHeartRateZone:
                return "HRZ";
            case FTDistanceToDestination:
                return "D2D";
            case FTDistanceToNext:
                return "D2N";
            case FTDistanceOrToDestination:
                // Check if the user is currently navigating a course
                if (mHasCourseNavigation) {
                    return "D2D"; // Distance to Destination
                } else {
                    return "DST"; // Standard Total Distance
                }
            default:
                return "";
        }
    }

    hidden function getFieldLabelWide(fieldType as FieldType) as String {
        switch (fieldType) {
            case FTDistance:
                return "DISTANCE";
            case FTCalories:
                return "CALORIES";
            case FTAverageHeartRate:
                return "AVG HEART RATE";
            case FTAveragePower:
                return "AVG POWER";
            case FTAverageSpeed:
                return "AVG SPEED";
            case FTAverageCadence:
                return "AVG CADENCE";
            case FTNormalizedPower:
                return "NORMALIZED POWER";
            case FTTotalAscent:
                return "TOTAL ASCENT";
            case FTTotalDescent:
                return "TOTAL DESCENT";
            case FTMinutesElapsed:
                return "MINUTES ELAPSED";
            case FTHeartRateZone:
                return "HEART RATE ZONE";
            case FTDistanceToDestination:
                return "DISTANCE TO DEST";
            case FTDistanceToNext:
                return "DISTANCE TO NEXT";
            case FTDistanceOrToDestination:
                return "DISTANCE OR DESTINATION";
            default:
                return "";
        }
    }

    function getThemeColor(darkBackground) as Dictionary {
        return {
            :border => darkBackground
                ? Graphics.COLOR_LT_GRAY
                : Graphics.COLOR_DK_GRAY,
            :track => darkBackground
                ? Graphics.COLOR_DK_GRAY
                : Graphics.COLOR_LT_GRAY,
        };
    }
}
