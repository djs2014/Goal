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
    hidden var mShowDetails as Boolean = false;

    hidden var mHasCadence as Boolean = false;
    hidden var mCadenceZeroCounter as Number = $.gCadenceCounter;

    hidden var mProgressFields as Array<FieldType> = new Array<
        FieldType
    >[$.gMaxProgressColumns];
    hidden var mProgressArray as Array<Float> = new Array<
        Float
    >[$.gMaxProgressColumns];
    hidden var mProgressColors as Array<Graphics.ColorType> = new Array<
        Graphics.ColorType
    >[$.gMaxProgressColumns];
    hidden var mProgressFieldValues as Array<Float> = new Array<
        Float
    >[$.gMaxProgressColumns];

    hidden var mProgress as Progress = new Progress();
    hidden var mNormPowerEngine as NormPowerEngine = new NormPowerEngine();
    hidden var mHasCourseNavigation as Boolean = false;

    function initialize() {
        DataField.initialize();
    }

    hidden var mCurrentEdgeField as EdgeField = EfLarge;
    hidden var mFieldShowLabels as Boolean = false;
    hidden var mFieldShowValues as Boolean = false;
    hidden var mFieldColumnGap as Number = 8;
    hidden var mFieldDivider as Number = 80;
    function onLayout(dc as Graphics.Dc) as Void {
        mCurrentEdgeField = $.getEdgeField(dc);

        var showFields = [] as Array<Numeric or FieldLayout or Boolean>;
        if (mCurrentEdgeField == EfOne) {
            showFields =
                $.getStorageValue("show_one_field", [$.gShowFieldsArraySize]) as
                Array<Numeric or FieldLayout or Boolean>;
        } else if (mCurrentEdgeField == EfLarge) {
            showFields =
                $.getStorageValue("show_large_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean>;
        } else if (mCurrentEdgeField == EfWide) {
            showFields =
                $.getStorageValue("show_wide_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean>;
        } else if (mCurrentEdgeField == EfSmall) {
            showFields =
                $.getStorageValue("show_small_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean>;
        } else {
            showFields =
                $.getStorageValue("show_one_field", [$.gShowFieldsArraySize]) as
                Array<Numeric or FieldLayout or Boolean>;
        }
        
        $.logInfo(["onLayout: showFields:", showFields]);

        mFieldLayout = showFields[0] as FieldLayout;
        mFieldShowLabels = showFields[1] == true;
        mFieldShowValues = showFields[2] == true;
        mFieldColumnGap = showFields[3] as Number;
        mFieldDivider = showFields[4] as Number;

        mProgressFields =
            showFields.slice($.gPreambleFieldCount, null) as Array<FieldType>;

        // Remove the entries `where no field is assigned (value of 0)
        mProgressFields = $.removeZeros(mProgressFields);
        // Add to maximum size to match mProgressArray size
        $.ensureArraySize(mProgressFields, $.gMaxProgressColumns, 0);
        $.logInfo(["onLayout: mProgressFields:", mProgressFields]);
        $.logInfo(["onLayout: mProgressFieldValues:", mProgressFieldValues]);
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
            mShowDetails = true;
            mPauseExtendedCounter = 10;
        } else if (mPauseExtendedCounter <= 0) {
            mPauseExtendedCounter = 0;
            mShowDetails = false;
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

                    //if ($.gShowValues) {
                    mProgressFieldValues[i] = mProgress.getValueForField(
                        info,
                        fieldType
                    );
                    //}
                }

                var cadence =
                    $.getActivityValue(info, :currentCadence, 0) as Number;
                if (!mHasCadence) {
                    mHasCadence = cadence > 0;
                } else {
                    // If cadence is zero for x consecutive updates, then show details.do {
                    if (cadence == 0) {
                        mCadenceZeroCounter -= 1;
                        if (mCadenceZeroCounter <= 0) {
                            mShowDetails = true;
                        }
                    } else {
                        mCadenceZeroCounter = $.gCadenceCounter; // reset counter
                        mShowDetails = false;
                    }
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
                gap = mFieldColumnGap; // Use user-defined gap for vertical layout
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
                gap = mFieldColumnGap; // Use user-defined gap for horizontal layout
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

        if (mFieldDivider>0) {
            // Draw a horizontal divider line at the specified height from the bottom
            var dividerY = y + h - (h * mFieldDivider/100).toNumber();
            if (fillHeight != dividerY - y) {
                // Only draw the divider if it is not exactly at the fill height
                dc.setColor(colors[:divider], Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x, dividerY, x + w, dividerY);
            }
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
        if (mFieldShowLabels || mShowDetails) {
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

        if (mFieldDivider>0) {
            // Draw a vertical divider line at the specified position from the left
            var dividerX = x + (w * mFieldDivider/100).toNumber();
            if (fillRightX != dividerX) {
                // Only draw the divider if it is not exactly at the fill width
                dc.setColor(colors[:divider], Graphics.COLOR_TRANSPARENT);
                dc.drawLine(dividerX, y, dividerX, y + h);
            }
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

        if (mFieldShowLabels || mShowDetails) {
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

        // Only show values if the progress is less than 100% and the user has requested to show values
        if (progress < 1.0 && mFieldShowValues && mShowDetails) {
            var idxField = mProgressFields.indexOf(fieldType);
            if (idxField >= 0 && idxField < mProgressFieldValues.size()) {
                var textValue = getFormattedValue(
                    mProgressFieldValues[idxField],
                    fieldType
                );
                // Position text: Centered vertically inside the bar height, with a 6px right margin
                var fontValue = Graphics.FONT_XTINY;
                var fontValueHeight = dc.getFontHeight(fontValue);
                var textValueY = y + (h - fontValueHeight) / 2;
                var startValueX = x + w - 6; // Right-align with a 6px margin from the right edge

                // Draw the value text character-by-character from right to left
                for (var i = textValue.length()-1; i >= 0; i--) {
                    var charStr = textValue.substring(i, i + 1);
                    var charWidth = dc.getTextWidthInPixels(charStr, fontValue);

                    // Determine the horizontal midpoint of this specific letter
                    var charMidX = startValueX - charWidth / 2;

                    // Contrast Check: Is this letter's midpoint inside the filled color block?
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
                        startValueX - charWidth,
                        textValueY,
                        fontValue,
                        charStr,
                        Graphics.TEXT_JUSTIFY_LEFT
                    );

                    // Move the starting X position leftward for the next character
                    startValueX -= charWidth;
                }
            }
        }
        } // mFieldShowLabels || mShowDetails)

        // TODO fix color contrast for the value text when it is over the filled part of the bar
        // if (progress < 1.0 && mFieldShowValues && mShowDetails) {
        //     // Show actual values for the fieldType if requested using the same color as last character for the label text
        //     var idxField = mProgressFields.indexOf(fieldType);
        //     if (idxField >= 0 && idxField < mProgressFieldValues.size()) {
        //         var textValue = getFormattedValue(
        //             mProgressFieldValues[idxField],
        //             fieldType
        //         );

        //         var font = Graphics.FONT_XTINY;
        //         var fontHeight = dc.getFontHeight(font);
        //         var textY = y + (h - fontHeight) / 2;
        //         var textX = x + w - 6; // Right-align with a 6px margin from the right edge
        //         // TODO: get background color at this position to determine contrast for the value text


        //         dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        //         dc.drawText(
        //             textX,
        //             textY,
        //             font,
        //             getFormattedValue(
        //                 mProgressFieldValues[idxField],
        //                 fieldType
        //             ),
        //             Graphics.TEXT_JUSTIFY_RIGHT
        //         );
        //     }
        // }
    }
    hidden function getFormattedValue(
        value as Float or Number or Null,
        fieldType as FieldType
    ) as String {
        if (value == null) {
            value = 0.0f;
        }

        switch (fieldType) {
            case FTDistance:
            case FTDistanceToDestination:
            case FTDistanceToNext:
            case FTDistanceOrNavDestination:
                return (value / 1000.0f).format("%.1f") + " KM"; // Convert meters to kilometers
            case FTCalories:
                return value.format("%.0f") + " KCAL"; // Calories are already in kcal
            case FTAverageHeartRateZone:
            case FTHeartRateZone:
                return value.format("%.0f"); // Number
            case FTPower:
            case FTAveragePower:
            case FTNormalizedPower:
                return value.format("%.0f") + " W"; // Power is already in watts
            case FTSpeed:
            case FTAverageSpeed:
                return (value * 3.6f).format("%.1f") + " KM/H"; // Convert m/s to km/h
            case FTAverageCadence:
            case FTCadence:
                return value.format("%.0f") + " RPM"; // Cadence is already in rpm
            case FTTotalAscent:
            case FTTotalDescent:
                return value.format("%.0f") + " M"; // Ascent/Descent is already in meters
            case FTMinutesElapsed:
                // TODO convert to HH:MM:SS
                return (value / 60.0f).format("%.1f") + " MIN"; // Convert seconds to minutes
            case FTIntensityFactor:
                return value.format("%.2f"); // Intensity Factor is unitless
            case FTTrainingStressScore:
                return value.format("%.0f"); // TSS is unitless
            default:
                return value.format("%.2f"); // Default: no conversion
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

    // ø == Average symbol.
    // Keep is 3 characters.
    hidden function getFieldLabel(fieldType as FieldType) as String {
        switch (fieldType) {
            case FTDistance:
                return "DST";
            case FTCalories:
                return "CAL";
            case FTHeartRateZone:
                if ($.gHeartRate.getIsInWarmUp()) {
                    return "RZ0";
                }
                return "RZ" + $.gTargetHeartRateZone.format("%d");
            case FTAverageHeartRateZone:
                if ($.gHeartRate.getIsInWarmUp()) {
                    return "øZ0";
                }
                return "øZ" + $.gTargetAverageHeartRateZone.format("%d");
            case FTPower:
                return "PWR";
            case FTAveragePower:
                return "øPW";
            case FTSpeed:
                return "SPD";
            case FTAverageSpeed:
                return "øSP";
            case FTAverageCadence:
                return "øCD"; // Do not use "ØCD" -> wont fit in 3 characters on small screens
            case FTCadence:
                return "CAD";
            case FTNormalizedPower:
                return "NP";
            case FTTotalAscent:
                return "ASC";
            case FTTotalDescent:
                return "DSC";
            case FTMinutesElapsed:
                return "TIM";
            case FTDistanceToDestination:
                return "D2D";
            case FTDistanceToNext:
                return "D2N";
            case FTDistanceOrNavDestination:
                // Check if the user is currently navigating a course
                if (mHasCourseNavigation) {
                    return "D2D"; // Distance to Destination
                } else {
                    return "DST"; // Standard Total Distance
                }
            case FTIntensityFactor:
                return "IF";
            case FTTrainingStressScore:
                return "TSS";
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
            case FTAverageHeartRateZone:
                return "AVG HEART RATE ZONE";
            case FTPower:
                return "POWER";
            case FTAveragePower:
                return "AVG POWER";
            case FTSpeed:
                return "SPEED";
            case FTAverageSpeed:
                return "AVG SPEED";
            case FTAverageCadence:
                return "AVG CADENCE";
            case FTCadence:
                return "CADENCE";
            case FTNormalizedPower:
                return "NORMALIZED POWER";
            case FTTotalAscent:
                return "TOTAL ASCENT";
            case FTTotalDescent:
                return "TOTAL DESCENT";
            case FTMinutesElapsed:
                return "MINUTES ELAPSED";
            case FTAverageHeartRateZone:
                if ($.gHeartRate.getIsInWarmUp()) {
                    return "AVG HRZ WARMUP";
                }
                return (
                    "AVG HEARTRATEZONE " + $.gTargetAverageHeartRateZone.format("%0d")
                );
            case FTHeartRateZone:
                if ($.gHeartRate.getIsInWarmUp()) {
                    return "HRZ WARMUP";
                }
                return "HEARTRATEZONE " + $.gTargetHeartRateZone.format("%0d");
            case FTDistanceToDestination:
                return "DISTANCE TO DEST";
            case FTDistanceToNext:
                return "DISTANCE TO NEXT";
            case FTDistanceOrNavDestination:
                if (mHasCourseNavigation) {
                    return "DISTANCE TO DEST";
                } else {
                    return "DISTANCE";
                }
            case FTIntensityFactor:
                return "INTENSITY FACTOR";
            case FTTrainingStressScore:
                return "TRAINING STRESSSCORE";
            default:
                return "";
        }
    }

    // --- Premium Edge 1050 Bright Grays ---
    const COLOR_ALABASTER = 0xf2f2f2; // 95% Brightness - Incredibly clean, barely-there gray
    const COLOR_PLATINUM = 0xe5e5e5; // 90% Brightness - Premium tech track look (Highly Recommended)
    const COLOR_GAINSBORO = 0xdcdcdc; // 86% Brightness - Safe, solid background track
    const COLOR_SILVER_LIGHT = 0xd3d3d3; // 83% Brightness - Noticeably lighter than standard Garmin Lt Gray

    function getThemeColor(darkBackground) as Dictionary {
        return {
            :border => darkBackground
                ? COLOR_SILVER_LIGHT
                : Graphics.COLOR_DK_GRAY,
            :track => darkBackground ? Graphics.COLOR_DK_GRAY : COLOR_PLATINUM,
            :divider => darkBackground ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE,
        };
    }
}
