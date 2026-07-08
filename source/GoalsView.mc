import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Math;

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
    hidden var mDemoMode as Boolean = false;
    hidden var mPauseExtendedCounter as Number = 10;
    hidden var mShowDetailsOnPause as Boolean = false;
    hidden var mShowDetailsOn0Cadence as Boolean = false;

    hidden var mHasCadence as Boolean = false;
    hidden var mCadenceZeroCounter as Number = $.gCadenceCounter;

    hidden var mProgressFields as Array<FieldType> = new Array<
        FieldType
    >[$.gMaxProgressColumns];
    hidden var mProgressRatios as Array<Float> = new Array<
        Float
    >[$.gMaxProgressColumns];
    hidden var mProgressColors as Array<Graphics.ColorType> = new Array<
        Graphics.ColorType
    >[$.gMaxProgressColumns];

    // Used when D2D is null on pause
    hidden var mProgressFieldValueDistance as Float = 0.0f;

    hidden var mProgress as Progress = new Progress();
    hidden var mNormPowerEngine as NormPowerEngine = new NormPowerEngine();
    hidden var mHasCourseNavigation as Boolean = false;

    hidden var mFonts as Array = [
        Graphics.FONT_XTINY,
        Graphics.FONT_TINY,
        Graphics.FONT_SYSTEM_SMALL,
        Graphics.FONT_SYSTEM_MEDIUM,
        Graphics.FONT_SYSTEM_LARGE,
    ];
    hidden var mFontsNumbers as Array = [
        Graphics.FONT_XTINY,
        Graphics.FONT_TINY,
        Graphics.FONT_SYSTEM_SMALL,
        Graphics.FONT_SYSTEM_MEDIUM,
        Graphics.FONT_SYSTEM_LARGE,
        Graphics.FONT_NUMBER_MILD,
        Graphics.FONT_NUMBER_MEDIUM,
        Graphics.FONT_NUMBER_HOT,
        Graphics.FONT_NUMBER_THAI_HOT,
    ];
    function initialize() {
        DataField.initialize();
        initializeArrays();
    }

    function initializeArrays() as Void {
        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            mProgressFields[i] = 0;
            mProgressRatios[i] = 0.0f;
            mProgressColors[i] = Graphics.COLOR_BLACK;
        }
    }

    hidden var mCurrentEdgeField as EdgeField = EfLarge;
    hidden var mFieldShowLabels as Boolean = false;
    hidden var mFieldShowValues as Boolean = false;
    hidden var mFieldColumnGap as Number = 8;
    hidden var mFieldDivider as Number = 80;
    hidden var mFieldShowFocus as Boolean = false;
    hidden var mFieldShowStamina as StaminaBar = SBNone;

    function onLayout(dc as Graphics.Dc) as Void {
        mCurrentEdgeField = $.getEdgeField(dc);

        var showFields = [] as Array<Numeric or FieldLayout or Boolean>;
        if (mCurrentEdgeField == EfOne) {
            showFields =
                $.getStorageValue("show_one_field", [$.gShowFieldsArraySize]) as
                Array<Numeric or FieldLayout or Boolean or StaminaBar>;
        } else if (mCurrentEdgeField == EfLarge) {
            showFields =
                $.getStorageValue("show_large_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean or StaminaBar>;
        } else if (mCurrentEdgeField == EfWide) {
            showFields =
                $.getStorageValue("show_wide_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean or StaminaBar>;
        } else if (mCurrentEdgeField == EfSmall) {
            showFields =
                $.getStorageValue("show_small_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or FieldLayout or Boolean or StaminaBar>;
        } else {
            showFields =
                $.getStorageValue("show_one_field", [$.gShowFieldsArraySize]) as
                Array<Numeric or FieldLayout or Boolean or StaminaBar>;
        }

        // $.logInfo(["edgeField:", mCurrentEdgeField, "showFields:", showFields]);

        mFieldLayout = showFields[0] as FieldLayout;
        mFieldShowLabels = showFields[1] == true;
        mFieldShowValues = showFields[2] == true;
        mFieldColumnGap = showFields[3] as Number;
        mFieldDivider = showFields[4] as Number;
        mFieldShowFocus = showFields[5] == true && $.gFocusFieldCount > 0;
        mFieldShowStamina = SBNone;
        if ($.gStaminaBarHeight > 0) {
            mFieldShowStamina = showFields[6] as StaminaBar;
        }

        mProgressFields =
            showFields.slice($.gPreambleFieldCount, null) as Array<FieldType>;

        // Remove the entries `where no field is assigned (value of 0)
        mProgressFields = $.removeZeros(mProgressFields);
        // Add to maximum size to match mProgressRatios size
        $.ensureArraySize(mProgressFields, $.gMaxProgressColumns, 0);
        // $.logInfo(["onLayout: mProgressFields:", mProgressFields]);

        mColorScheme = $.gColorScheme;

        if (mFieldLayout == FLBubbles) {
            initBubbleLayout(dc);
        }
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
            mShowDetailsOnPause = true;
            mPauseExtendedCounter = 10;
        } else if (mPauseExtendedCounter <= 0) {
            mPauseExtendedCounter = 0;
            mShowDetailsOnPause = false;
        } else {
            mPauseExtendedCounter -= 1;
        }

        // Check if we have course navigation data available by checking if distanceToDestination is non-zero
        mHasCourseNavigation =
            ($.getActivityValue(info, :distanceToDestination, 0.0f) as Float) >
            0.0f;

        // $.logInfo(["Compute: Demo mode:", $.gDemo, "Paused:", mPaused]);
        mDemoMode = $.gDemo and mPaused; // Only allow demo mode when paused
        if (mDemoMode) {
            SimulateProgress(info);
        } else {
            mDemoStartTime = 0; // reset demo time so it starts from the beginning when toggled on
            $.gDemo = false; // reset demo flag so it doesn't keep simulating when paused

            $.gPowerPerSec.compute(info);
            var power = $.getActivityValue(info, :currentPower, 0) as Number;
            var np = mNormPowerEngine.compute(power);
            mProgress.setNormalizedPower(np);

            $.gAnaerobicWork.updateWPrime(info);

            // Calculate for all fieldTypes the value
            mProgress.updateProgressFieldValues(info);

            // TODO - use mProgressFieldValues in getProgressForField -> define it in mProgress class

            // Update progress values
            for (var i = 0; i < mProgressFields.size(); i++) {
                var fieldType = mProgressFields[i];
                mProgressRatios[i] = mProgress.getProgressForField(
                    info,
                    fieldType
                );
            }
            // System.println("Compute: mProgressRatios: " + mProgressRatios);

            if (!mPaused) {
                var cadence =
                    $.getActivityValue(info, :currentCadence, 0) as Number;
                if (!mHasCadence) {
                    mHasCadence = cadence > 0;
                } else {
                    // If cadence is zero for x consecutive updates, then show details
                    if (cadence == 0) {
                        if (mCadenceZeroCounter <= 0) {
                            mShowDetailsOn0Cadence = true;
                            mCadenceZeroCounter = 0;
                        } else {
                            mCadenceZeroCounter -= 1;
                        }
                    } else {
                        // Count towards the gCadenceCounter threshold to reset the counter and hide details
                        if (mCadenceZeroCounter < $.gCadenceCounter) {
                            mCadenceZeroCounter += 1;
                        } else if (mShowDetailsOn0Cadence) {
                            mShowDetailsOn0Cadence = false;
                            mCadenceZeroCounter = $.gCadenceCounter; // reset counter
                        }
                    }
                }
            }
        }

        // Update the focus fields based on the current progress ratios and user-defined settings
        setFocusFieldsCount($.gFocusFieldCount, $.gFocusFieldStartAt);
        if (mFocusFieldsCount > 0) {
            // Update focus fields based on the current progress ratios
            updateFocusFields();
        }

        var numBars = mProgressRatios.size();
        for (var i = 0; i < numBars; i++) {
            mProgressColors[i] = getDynamicColor(
                mProgressRatios[i],
                mColorScheme
            );
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
        mDemoCounter6 = (mDemoCounter6 + 7).toNumber() % 300;
        mDemoCounter7 = (mDemoCounter7 + 8).toNumber() % 150;
        mDemoCounter8 = (mDemoCounter8 + 9).toNumber() % 150;
        mDemoCounter9 = (mDemoCounter9 + 10).toNumber() % 190;
        mDemoCounter10 = (mDemoCounter10 + 11).toNumber() % 150;

        mProgressRatios =
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

    function getDemoValue(idx as Number) as Float {
        var ratio = 0.0f;
        if (idx >= 0 && idx < mProgressRatios.size()) {
            ratio = mProgressRatios[idx];
        }
        return ratio * 100.0f; // Return as percentage
    }

    hidden var mFocusFieldsCount as Number = 3;
    hidden var mFocusStartAt as Float = 0.8f;
    hidden var mFocusFields as Array<FieldType> = new Array<
        FieldType
    >[mFocusFieldsCount];
    hidden var mFocusIndices as Array<Number> = new Array<
        Number
    >[$.gMaxProgressColumns];

    function setFocusFieldsCount(count as Number, startAt as Float) as Void {
        var size = mProgressFields.size();
        if (count > size) {
            count = size;
        }
        mFocusStartAt = startAt;
        if (count != mFocusFieldsCount) {
            // Only reallocate if the count has changed
            mFocusFieldsCount = count;
            mFocusFields = new Array<FieldType>[mFocusFieldsCount];
        }
    }
    // Get mFocusFieldsCount number of fieldTypes with the highest progress ratios
    // Only fields that have ratio > mFocusStartAt will be considered for focus
    // Create a tiny primitive array of indices [0, 1, 2, ...] and sort that
    // based on the values in mProgressRatios. This keeps the original data intact
    // and avoids allocating complex objects.Using a simple Insertion Sort for the index map
    // perfect for $N \le 10$):
    hidden function updateFocusFields() as Void {
        // Initialize index map
        var size = $.gMaxProgressColumns;
        for (var i = 0; i < size; i++) {
            mFocusIndices[i] = i;
        }

        // Simple Insertion Sort (descending based on ratios)
        for (var i = 1; i < size; i++) {
            var keyIndex = mFocusIndices[i];
            var keyValue = mProgressRatios[keyIndex];
            var j = i - 1;

            while (j >= 0 && mProgressRatios[mFocusIndices[j]] < keyValue) {
                mFocusIndices[j + 1] = mFocusIndices[j];
                j--;
            }
            mFocusIndices[j + 1] = keyIndex;
        }

        // mFocusStartAt = 0.0f;
        // Extract the top mFocusFieldsCount field types
        // If value is below mFocusStartAt, then skip it and fill the rest with 0
        for (var i = 0; i < mFocusFieldsCount; i++) {
            if (mProgressRatios[mFocusIndices[i]] < mFocusStartAt) {
                mFocusFields[i] = 0;
            } else {
                mFocusFields[i] = mProgressFields[mFocusIndices[i]];
            }
        }

        // System.println([
        //     "mFieldShowFocus:",
        //     mFieldShowFocus,
        //     "mFocusStartAt:",
        //     mFocusStartAt,
        //     "mFocusFieldsCount:",
        //     mFocusFieldsCount,
        //     "mFocusFields:",
        //     mFocusFields,
        //     "mProgressRatios:",
        //     mProgressRatios
        // ]);
    }

    hidden function isFocusField(fieldType as FieldType) as Boolean {
        if (
            !mFieldShowFocus ||
            mFocusFieldsCount <= 0 ||
            mFocusFields.size() < mFocusFieldsCount
        ) {
            return false;
        }

        for (var i = 0; i < mFocusFieldsCount; i++) {
            if (mFocusFields[i] == fieldType) {
                return true;
            }
        }
        return false;
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc as Graphics.Dc) as Void {
        // Force reset the hardware clipping mask back to full canvas size
        if (dc has :clearClip) {
            dc.clearClip();
        }
        if ($.gExitedMenu) {
            onLayout(dc);
            $.gExitedMenu = false;
        }

        var backgroundColor = getBackgroundColor();
        mDarkBackground = backgroundColor == Graphics.COLOR_BLACK;
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();

        var screenW = dc.getWidth();
        var screenH = dc.getHeight(); 
        if (mFieldShowStamina != SBNone) {
            // Reserve space for the stamina bar at the bottom of the screen
            screenH -= $.gStaminaBarHeight;
        }

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
                        mProgressRatios[i],
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
                        mProgressRatios[i],
                        mProgressColors[i],
                        mProgressFields[i]
                    );
                }
                break;

            case FLProportional:
                drawProportionalGrid(dc, 1, 1, screenW - 2, screenH - 2);
                break;
            case FLBubbles:
                drawBubbleLayout(dc, 1, 1, screenW - 2, screenH - 2);
                break;
        }
        if (mFieldShowStamina != SBNone) {
            drawStaminaProgressBar(
                dc,
                0,
                screenH, // already subtracted the height of the stamina bar from screenH above
                screenW,
                $.gStaminaBarHeight,
                mFieldShowStamina
            );
        }
    }

    //! Render the proportional layout inside a specified bounding box
    //! @param dc The device context
    //! @param x Starting X coordinate of the container rectangle
    //! @param y Starting Y coordinate of the container rectangle
    //! @param width Total width of the container
    //! @param height Total height of the container
    //! @param ratios Array of Float values (0.0 to 1.0), max 10 elements
    //! @param labels Array of Strings corresponding to each ratio
    public function drawProportionalGrid(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        width as Number,
        height as Number
    ) as Void {
        // ratios as Array<Float>,
        // barColors as Array<Graphics.ColorType>,
        // fieldTypes as Array<FieldType>
        var ratios = mProgressRatios;
        var barColors = mProgressColors;
        var fieldTypes = mProgressFields;

        // TODO: if all ratios are between .9 and 1.0, then ..
        //ratios = [2.99f, 0.93f, 0.92f, 0.93f, 0.98f, 0.91f];

        var totalRatio = 0.0f;
        var validIndices = [] as Array<Number>;

        // 1. Filter out zeros and calculate total active weight
        for (var i = 0; i < ratios.size(); i++) {
            if (ratios[i] > 0.0) {
                totalRatio += ratios[i];
                validIndices.add(i);
            }
        }

        var count = validIndices.size();
        if (count == 0 || width <= 0 || height <= 0) {
            var colors = getThemeColor(mDarkBackground);
            dc.setColor(colors[:text], Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                x + width / 2,
                y + height / 2,
                Graphics.FONT_TINY,
                "No Data",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return; // Nothing to draw
        }

        var currentX = x;
        var currentY = y;
        var remainingWidth = width;
        var remainingHeight = height;
        var remainingRatio = totalRatio;

        var minWidth = dc.getTextWidthInPixels("888", Graphics.FONT_XTINY) + 4;
        var minHeight = dc.getFontHeight(Graphics.FONT_XTINY) + 4;
        var showLabels =
            mFieldShowLabels || mShowDetailsOnPause || mShowDetailsOn0Cadence;
        var showValues =
            mFieldShowValues || mShowDetailsOnPause || mShowDetailsOn0Cadence;

        // 2. Iterate and carve out segments
        for (var i = 0; i < count; i++) {
            var index = validIndices[i];
            var currentWeight = ratios[index];
            var fieldType = fieldTypes[index];
            var focusField = isFocusField(fieldType);
            var label =
                showLabels || focusField ? getFieldLabel(fieldType) : "";
            var color = barColors[index];
            var valueText = "";
            if (showValues || focusField) {
                if (mDemoMode) {
                    valueText = getDemoValue(index).format("%.0f") + " %";
                } else {
                    valueText = getFormattedValue(
                        mProgress.getProgressFieldValue(fieldType),
                        fieldType,
                        true
                    );
                }
            }

            // If it's the last element, consume all remaining space to avoid rounding gaps
            if (i == count - 1) {
                drawSegment(
                    dc,
                    currentX,
                    currentY,
                    remainingWidth,
                    remainingHeight,
                    label,
                    color,
                    valueText
                );
                break;
            }

            // Determine orientation dynamically based on aspect ratio to favor squares
            if (remainingWidth >= remainingHeight) {
                // Slice Horizontally (Columns)
                var allocatedWidth = (
                    (currentWeight / remainingRatio) *
                    remainingWidth
                ).toNumber();

                // Enforce minimum width constraint
                if (allocatedWidth < minWidth) {
                    allocatedWidth = minWidth;
                }
                if (
                    allocatedWidth >
                    remainingWidth - (count - 1 - i) * minWidth
                ) {
                    allocatedWidth =
                        remainingWidth - (count - 1 - i) * minWidth;
                }

                drawSegment(
                    dc,
                    currentX,
                    currentY,
                    allocatedWidth,
                    remainingHeight,
                    label,
                    color,
                    valueText
                );

                currentX += allocatedWidth;
                remainingWidth -= allocatedWidth;
            } else {
                // Slice Vertically (Rows)
                var allocatedHeight = (
                    (currentWeight / remainingRatio) *
                    remainingHeight
                ).toNumber();

                // Enforce minimum height constraint
                if (allocatedHeight < minHeight) {
                    allocatedHeight = minHeight;
                }
                if (
                    allocatedHeight >
                    remainingHeight - (count - 1 - i) * minHeight
                ) {
                    allocatedHeight =
                        remainingHeight - (count - 1 - i) * minHeight;
                }

                drawSegment(
                    dc,
                    currentX,
                    currentY,
                    remainingWidth,
                    allocatedHeight,
                    label,
                    color,
                    valueText
                );

                currentY += allocatedHeight;
                remainingHeight -= allocatedHeight;
            }

            remainingRatio -= currentWeight;
        }
    }

    //! Helper method to draw the single rectangle and its centered label
    private function drawSegment(
        dc as Graphics.Dc,
        sx as Number,
        sy as Number,
        sw as Number,
        sh as Number,
        label as String?,
        color as Graphics.ColorType,
        valueText as String?
    ) as Void {
        // Draw the bounding box border
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(sx, sy, sw, sh);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(sx + 1, sy + 1, sw - 2, sh - 2);

        var hasLabel = label != null && label.length() > 0;
        var hasValue = valueText != null && valueText.length() > 0;
        if (!hasLabel && !hasValue) {
            return; // Nothing to draw
        }

        if ($.isColorLight(color)) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }
        if ($.gHspShowValue) {
            // place the HSP value in the top right corner of the rectangle
            var hsp = $.calculateHSP(color);
            dc.drawText(
                sx + sw - 2,
                sy + 2,
                Graphics.FONT_XTINY,
                hsp.format("%.1f"),
                Graphics.TEXT_JUSTIFY_RIGHT
            );
        }

        if (valueText == null) {
            valueText = "";
        }

        // Draw the text label centered inside the allocated rectangle
        var font = Graphics.FONT_XTINY;
        var centerX = sx + sw / 2;
        var centerY = sy + sh / 2;
        if (!hasValue) {
            // Only label to show, center it vertically and horizontally
            dc.drawText(
                centerX,
                centerY,
                font,
                label,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
            return;
        }

        // label and valueText (with units)
        var startY = centerY;
        var isPortrait = sh >= sw;
        var labelHeight = 0;
        var unitHeight = 0;
        if (hasLabel) {
            labelHeight = dc.getFontHeight(font);
        }

        var fontValue = Graphics.FONT_TINY;
        var widthUnits = 0;
        var units = "";
        var hasUnits = false;
        var valueOnly = valueText;
        // split to allow for different font sizes
        // number<space>units
        var posSpace = valueText.find(" ");
        if (posSpace != null) {
            font = Graphics.FONT_XTINY;
            valueOnly = valueText.substring(0, posSpace);
            units = valueText.substring(posSpace + 1, null);
            widthUnits = dc.getTextWidthInPixels(units, font);
            unitHeight = dc.getFontHeight(font);
            hasUnits = units != null && units.length() > 0;
        }
        if (isPortrait) {
            // Draw label, value and units stacked vertically
            // Match value font without units
            fontValue =
                $.getMatchingFont(
                    dc,
                    mFontsNumbers,
                    sw - 4,
                    sh - 4 - labelHeight - unitHeight,
                    valueOnly
                ) as Graphics.FontType;
        } else {
            // Landscape
            // Draw label above value and units, centered horizontally
            // Match value font with units
            fontValue =
                $.getMatchingFont(
                    dc,
                    mFontsNumbers,
                    sw - 4,
                    sh - 4 - labelHeight,
                    valueText
                ) as Graphics.FontType;
        }

        var valueHeight = dc.getFontHeight(fontValue);

        if (isPortrait) {
            // Draw label, value and units stacked vertically
            startY = centerY - (labelHeight + valueHeight + unitHeight) / 2;
            if (sh < labelHeight + valueHeight + unitHeight) {
                // Label doesn't fit, so remove it and center the value and units text vertically
                label = null;
                labelHeight = 0;
                hasLabel = false;
                startY = centerY - (valueHeight + unitHeight) / 2;
            }
            if (sh < valueHeight + unitHeight) {
                // Units don't fit, so remove them and center the value text vertically
                units = null;
                unitHeight = 0;
                hasUnits = false;
                startY = centerY - valueHeight / 2;
            }
        } else {
            // Landscape
            startY = centerY - (labelHeight + valueHeight) / 2;
            if (sh < labelHeight + valueHeight) {
                // Label doesn't fit, so remove it and center the value text vertically
                label = null;
                labelHeight = 0;
                hasLabel = false;
                startY = centerY - (valueHeight - 4) / 2;
            }
        }

        var widthValue = dc.getTextWidthInPixels(valueOnly, fontValue);

        if (isPortrait) {
            // Draw value and units stacked vertically
            // and only if it fits within the rectangle width:
            // label+value+unit | label | label+value | value+unit | value

            // First do the checks
            if (widthValue >= sw - 4) {
                // Truncate the value text to fit within the available width
                valueOnly = truncateDecimals(dc, valueOnly, fontValue, sw - 4);
                widthValue = dc.getTextWidthInPixels(valueOnly, fontValue);
            }
            // Will value fit?
            hasValue = widthValue < sw - 4;
            // Will units fit?
            hasUnits = hasValue && hasUnits && widthUnits < sw - 4;
            // Adjust the label position based on whether value and units were drawn
            valueHeight = hasValue ? valueHeight : 0;
            unitHeight = hasUnits ? unitHeight : 0;
            startY = centerY - (labelHeight + valueHeight + unitHeight) / 2;

            if (hasLabel) {
                dc.drawText(
                    centerX,
                    startY,
                    font,
                    label,
                    Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            if (hasValue) {
                dc.drawText(
                    centerX,
                    startY + labelHeight,
                    fontValue,
                    valueOnly,
                    Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
                );
                if (hasUnits) {
                    dc.drawText(
                        centerX,
                        startY + labelHeight + valueHeight,
                        font,
                        units,
                        Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
                    );
                }
            }
            return;
        } else {
            // Landscape
            if (label != null && label.length() > 0) {
                dc.drawText(
                    centerX,
                    startY,
                    font,
                    label,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            }

            // value and units exceed width -> remove units.
            if (widthValue + widthUnits > sw - 4) {
                widthUnits = 0;
                units = "";

                // Truncate the value text to fit within the available width
                valueOnly = truncateDecimals(dc, valueOnly, fontValue, sw - 4);
                widthValue = dc.getTextWidthInPixels(valueOnly, fontValue);
            }
            // Draw value + units centered horizontally
            var totalWidth = widthValue + widthUnits;
            var startX = centerX - totalWidth / 2;
            dc.drawText(
                startX,
                startY + labelHeight,
                fontValue,
                valueOnly,
                Graphics.TEXT_JUSTIFY_LEFT
            );
            if (widthUnits > 0) {
                dc.drawText(
                    startX + widthValue,
                    startY +
                        labelHeight + // label and unit same fonts
                        valueHeight -
                        unitHeight -
                        dc.getFontDescent(fontValue) +
                        dc.getFontDescent(font),
                    font,
                    units,
                    Graphics.TEXT_JUSTIFY_LEFT
                );
            }
        }
    }

    // Helper function to truncate the value text to fit within the available width
    function truncateDecimals(
        dc as Graphics.Dc,
        text as String?,
        font as Graphics.FontType,
        maxWidth as Number
    ) as String {
        var truncatedText = text;
        if (truncatedText == null || truncatedText.length() == 0) {
            return "";
        }

        var widthValue = dc.getTextWidthInPixels(truncatedText, font);
        if (widthValue > maxWidth) {
            var posDot = truncatedText.find(".");
            if (posDot == null) {
                return ""; // No dot found, return an empty string
            }

            truncatedText = truncatedText.substring(0, posDot);
        }

        return truncatedText;
    }

    //}

    // Configuration Constants
    private const NUM_BUBBLES = 6;
    private const EASING_FACTOR = 0.15f; // Smoothness of movement (0.0 - 1.0)
    private const REPULSION_FACTOR = 0.40f; // Strength of push
    private var MIN_RADIUS = 8.0f;
    private var MAX_RADIUS = 28.0f;

    private var currentX as Array<Float> =
        new [$.gMaxProgressColumns] as Array<Float>;
    private var currentY as Array<Float> =
        new [$.gMaxProgressColumns] as Array<Float>;
    private var currentRadius as Array<Float> =
        new [$.gMaxProgressColumns] as Array<Float>;

    // Animation timer to force screen refreshes
    private var animationTimer as Toybox.Timer.Timer? = null;
    private var bubblesInitialized as Boolean = false;
    hidden function initBubbleLayout(dc as Graphics.Dc) as Void {
        var screenH = dc.getHeight();
        if (mFieldShowStamina != SBNone) {
            // Reserve space for the stamina bar at the bottom of the screen
            screenH -= $.gStaminaBarHeight;
        }
        MIN_RADIUS =
            (dc.getTextWidthInPixels("888", Graphics.FONT_XTINY) + 4) / 2.0f;
        MAX_RADIUS = (screenH / 3.0f).toFloat();
        if (bubblesInitialized) {
            return;
        }

        // Seed initial positions so they don't all pop in at (0,0)
        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            currentX[i] = 0.0f;
            currentY[i] = screenH - MIN_RADIUS; // Start near bottom assuming standard screen
            currentRadius[i] = MIN_RADIUS;
        }
        bubblesInitialized = true;
        // if (animationTimer == null) {

        // Start a fast timer (e.g., ~30 FPS / 33ms) to drive fluid animation.
        // Note: Check Garmin device compatibility; some older devices restrict background animation rates.
        // animationTimer = new Toybox.Timer.Timer();
        // animationTimer.start(method(:onTimerTick), 33, true);
        // }
    }

    // Force a redraw on every timer tick
    // function onTimerTick() as Void {
    //     WatchUi.requestUpdate();
    // }
    function drawBubbleLayout(
        dc as Graphics.Dc,
        x as Number,
        y as Number,
        w as Number,
        h as Number
    ) as Void {
        var width = w.toFloat();
        var height = h.toFloat();

        // --- CROWD SCALING PRE-PASS ---
        // Dynamically shrink ALL bubbles when multiple circles have high ratios
        var totalTargetRadius = 0.0f;
        var activeCount = 0;

        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            if (mProgressFields[i] != FTUnknown) {
                var ratio = mProgressRatios[i];
                var baseTargetRad =
                    MIN_RADIUS + ratio * (MAX_RADIUS - MIN_RADIUS);
                totalTargetRadius += baseTargetRad;
                activeCount++;
            }
        }

        // Vertical space budget (e.g., 65% of screen height) to trigger group shrinking
        var verticalBudget = height * 0.65f;
        var scaleModifier = 1.0f;

        if (totalTargetRadius > verticalBudget && activeCount > 1) {
            scaleModifier = verticalBudget / totalTargetRadius;
            if (scaleModifier < 0.45f) {
                scaleModifier = 0.45f; // Protect minimum text readability bounds
            }
        }

        // --- STEP 1: RESOLVE SIZE & HORIZONTAL HOME / VERTICAL BUOYANCY ARCS ---
        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            if (mProgressFields[i] == FTUnknown) {
                currentRadius[i] =
                    currentRadius[i] +
                    (0.0f - currentRadius[i]) * EASING_FACTOR;
                currentY[i] =
                    currentY[i] + (height - currentY[i]) * EASING_FACTOR;
                continue;
            }

            var ratio = mProgressRatios[i];

            // 1a. Calculate current frame allowed dynamic radius
            var allowedMaxRadius =
                MIN_RADIUS + scaleModifier * (MAX_RADIUS - MIN_RADIUS);
            var targetRad =
                MIN_RADIUS + ratio * (allowedMaxRadius - MIN_RADIUS);
            currentRadius[i] =
                currentRadius[i] +
                (targetRad - currentRadius[i]) * EASING_FACTOR;

            // 1b. Guide X to its native horizontal home lane
            var spreadWidth = width * 0.85f;
            var leftBound = (width - spreadWidth) / 2.0f;
            var homeX =
                leftBound +
                (i.toFloat() / ($.gMaxProgressColumns - 1).toFloat()) *
                    spreadWidth;
            currentX[i] = currentX[i] + (homeX - currentX[i]) * 0.05f; // Mild tracking speed lets physics take over

            // 1c. Upward Buoyancy Force (Instead of rigid target assignment)
            // Instead of overriding Y completely, we see where it wants to sit based on ratio,
            // and gently float it up or down toward that zone, allowing collisions to alter the true path.
            var targetY = height - ratio * height;
            if (ratio > 1.0f) {
                targetY = currentRadius[i]; // Stay capped at the top boundary
            } else if (ratio == 0.0f) {
                targetY = height - currentRadius[i]; // Bottom floor
            }

            // Apply buoyancy vector drift rather than snapping
            currentY[i] = currentY[i] + (targetY - currentY[i]) * 0.08f;
        }

        // --- STEP 2: MULTI-PASS 2D VECTOR REPULSION (Solves Grouping) ---
        // Running physics twice per render frame completely eliminates grouping deadlocks
        // and instantly flings smaller circles downwards or outwards from behind large ones.
        for (var pass = 0; pass < 2; pass++) {
            for (var i = 0; i < $.gMaxProgressColumns; i++) {
                if (mProgressFields[i] == FTUnknown) {
                    continue;
                }

                for (var j = i + 1; j < $.gMaxProgressColumns; j++) {
                    if (mProgressFields[j] == FTUnknown) {
                        continue;
                    }

                    var dx = currentX[i] - currentX[j];
                    var dy = currentY[i] - currentY[j];

                    var distanceSq = dx * dx + dy * dy;
                    var combinedRadius = currentRadius[i] + currentRadius[j];
                    var combinedRadiusSq = combinedRadius * combinedRadius;

                    if (distanceSq < combinedRadiusSq) {
                        var distance = Math.sqrt(distanceSq);

                        // Symmetry breaker if circles share exact identical positions
                        if (distance == 0.0f) {
                            distance = 1.0f;
                            dx = i % 2 == 0 ? 2.0f : -2.0f;
                            dy = 1.0f;
                        }

                        var overlap = combinedRadius - distance;

                        // Calculate directional physics impact vectors
                        var forceX =
                            (dx / distance) * overlap * REPULSION_FACTOR;
                        var forceY =
                            (dy / distance) * overlap * REPULSION_FACTOR;

                        // Distribute the pushing forces cleanly across both coordinates
                        currentX[i] += forceX;
                        currentY[i] += forceY;

                        currentX[j] -= forceX;
                        currentY[j] -= forceY;
                    }
                }
            }

            // Enforce screen border boundaries *during* physics loops so circles don't bounce out of view
            for (var i = 0; i < $.gMaxProgressColumns; i++) {
                if (mProgressFields[i] == FTUnknown) {
                    continue;
                }
                var rad = currentRadius[i];

                if (currentX[i] < rad) {
                    currentX[i] = rad;
                }
                if (currentX[i] > width - rad) {
                    currentX[i] = width - rad;
                }
                if (currentY[i] < rad) {
                    currentY[i] = rad;
                }
                if (currentY[i] > height - rad) {
                    currentY[i] = height - rad;
                }
            }
        }

        // --- STEP 3: DUAL PASS RENDER ARCHITECTURE ---
        // Background layer: Draw big dominant circles first
        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            if (mProgressRatios[i] < 0.6f) {
                continue;
            }
            drawSingleBubble(dc, i, width.toNumber(), height.toNumber());
        }

        // Foreground layer: Draw smaller fields floating clearly on top
        for (var i = 0; i < $.gMaxProgressColumns; i++) {
            if (mProgressRatios[i] >= 0.6f) {
                continue;
            }
            drawSingleBubble(dc, i, width.toNumber(), height.toNumber());
        }
    }

    function drawSingleBubble(
        dc as Graphics.Dc,
        index as Number,
        width as Number,
        height as Number
    ) as Void {
        if (
            mProgressFields[index] == FTUnknown &&
            currentRadius[index] < 1.0f
        ) {
            return; // Skip empty bubbles
        }

        var bubbleRadius = currentRadius[index];
        var bubbleX = currentX[index];
        var bubbleY = currentY[index];

        // Bound containment
        if (bubbleX < bubbleRadius) {
            bubbleX = bubbleRadius;
        }
        if (bubbleX > width - bubbleRadius) {
            bubbleX = width - bubbleRadius;
        }
        if (bubbleY < bubbleRadius) {
            bubbleY = bubbleRadius;
        }
        if (bubbleY > height - bubbleRadius) {
            bubbleY = height - bubbleRadius;
        }

        // Draw bubble body
        var bubbleColor = mProgressColors[index];
        dc.setColor(bubbleColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(
            bubbleX.toNumber(),
            bubbleY.toNumber(),
            bubbleRadius.toNumber()
        );

        // Accent ring
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(
            bubbleX.toNumber(),
            bubbleY.toNumber(),
            bubbleRadius.toNumber()
        );

        var fieldType = mProgressFields[index];
        var focusField = isFocusField(fieldType);
        var showLabels =
            mFieldShowLabels ||
            mShowDetailsOnPause ||
            mShowDetailsOn0Cadence ||
            focusField;
        var showValues =
            mFieldShowValues ||
            mShowDetailsOnPause ||
            mShowDetailsOn0Cadence ||
            focusField;
        if (!showLabels && !showValues) {
            return; // No text to render
        }
        var label = showLabels ? getFieldLabel(fieldType) : "";
        var valueText = "";
        if (showValues) {
            if (mDemoMode) {
                valueText = getDemoValue(index).format("%.0f") + " %";
            } else {
                valueText = getFormattedValue(
                    mProgress.getProgressFieldValue(fieldType),
                    fieldType,
                    true
                );
            }
        }

        var hasLabel = label.length() > 0;
        var hasValue = valueText.length() > 0;
        if (!hasLabel && !hasValue) {
            return; // Nothing to draw
        }

        if ($.isColorLight(bubbleColor)) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        }

        var font = Graphics.FONT_XTINY;
        var centerX = bubbleX.toNumber();
        var centerY = bubbleY.toNumber();
        if (!hasValue) {
            if (bubbleRadius > 12.0f) {
                // Render text only if the bubble is big enough to display it cleanly
                // Only label to show, center it vertically and horizontally
                dc.drawText(
                    centerX,
                    centerY,
                    font,
                    label,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            return;
        }

        // label and valueText (with units)
        var startY = centerY;

        var labelHeight = 0;
        var unitHeight = 0;
        if (hasLabel) {
            labelHeight = dc.getFontHeight(font);
        }

        var widthUnits = 0;
        var units = "";
        var hasUnits = false;
        var valueOnly = valueText;
        // split to allow for different font sizes
        // number<space>units
        var posSpace = valueText.find(" ");
        if (posSpace != null) {
            font = Graphics.FONT_XTINY;
            valueOnly = valueText.substring(0, posSpace);
            units = valueText.substring(posSpace + 1, null);
            widthUnits = dc.getTextWidthInPixels(units, font);
            unitHeight = dc.getFontHeight(font);
            hasUnits = units != null && units.length() > 0;
        }

        // Same logic as drawSegment portrait.
        var bubbleHeight = (2 * bubbleRadius - 4).toNumber();
        var bubbleWidth = (2 * bubbleRadius - 4).toNumber();
        var fontValue =
            $.getMatchingFont(
                dc,
                mFontsNumbers,
                bubbleHeight - 4 - labelHeight - unitHeight,
                bubbleWidth - 4,
                valueText
            ) as Graphics.FontType;
        var valueHeight = dc.getFontHeight(fontValue);

        // Draw label, value and units stacked vertically
        startY = centerY - (labelHeight + valueHeight + unitHeight) / 2;
        if (bubbleHeight < labelHeight + valueHeight + unitHeight) {
            // Label doesn't fit, so remove it and center the value and units text vertically
            label = null;
            labelHeight = 0;
            hasLabel = false;
            startY = centerY - (valueHeight + unitHeight) / 2;
        }
        if (bubbleHeight < valueHeight + unitHeight) {
            // Units don't fit, so remove them and center the value text vertically
            units = null;
            unitHeight = 0;
            hasUnits = false;
            startY = centerY - valueHeight / 2;
        }

        var widthValue = dc.getTextWidthInPixels(valueOnly, fontValue);

        // Draw value and units stacked vertically
        // and only if it fits within the rectangle width:
        // label+value+unit | label | label+value | value+unit | value

        // First do the checks
        if (widthValue >= bubbleWidth - 4) {
            // Truncate the value text to fit within the available width
            valueOnly = truncateDecimals(
                dc,
                valueOnly,
                fontValue,
                bubbleWidth - 4
            );
            widthValue = dc.getTextWidthInPixels(valueOnly, fontValue);
        }
        // Will value fit?
        hasValue = widthValue < bubbleWidth - 4;
        // Will units fit?
        hasUnits = hasValue && hasUnits && widthUnits < bubbleWidth - 4;
        // Adjust the label position based on whether value and units were drawn
        valueHeight = hasValue ? valueHeight : 0;
        unitHeight = hasUnits ? unitHeight : 0;
        startY = centerY - (labelHeight + valueHeight + unitHeight) / 2;

        if (hasLabel) {
            dc.drawText(
                centerX,
                startY,
                font,
                label,
                Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
        if (hasValue) {
            dc.drawText(
                centerX,
                startY + labelHeight,
                fontValue,
                valueOnly,
                Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
            );
            if (hasUnits) {
                dc.drawText(
                    centerX,
                    startY + labelHeight + valueHeight,
                    font,
                    units,
                    Graphics.TEXT_JUSTIFY_CENTER //| Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    // Inside your View class...
    // function drawRadialGauges(dc) {
    //     var centerX = dc.getWidth() / 2;
    //     var centerY = dc.getHeight() / 2;

    //     // 1. Define your array of ratios (e.g., 5 metrics)
    //     // var ratios = [0.85, 0.42, 1.0, 0.15, 0.67];
    //     var ratios = mProgressRatios; // Use the actual progress values from mProgressRatios
    //     var numMetrics = ratios.size();

    //     // 2. Center hub styling
    //     var hubRadius = 15;
    //     dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    //     dc.fillCircle(centerX, centerY, hubRadius);

    //     // 3. Spacing setup
    //     var baseRadius = hubRadius + 12; // Start just outside the hub
    //     var ringSpacing = 16; // Distance between each arc layer
    //     var dotRadius = 4; // Size of the indicator circle at the end

    //     // Define the sweep direction (e.g., from 180° clockwise to 0°)
    //     var startAngleDeg = 180;
    //     var maxSweepDeg = 180; // A half-circle gauge. Change to 360 for full circles.

    //     for (var i = 0; i < numMetrics; i++) {
    //         var colorRatio = mProgressColors[i]; // Use the color corresponding to this metric
    //         var ratio = ratios[i];

    //         // Ensure ratio stays within bounds
    //         if (ratio > 1.0) {
    //             ratio = 1.0;
    //         }
    //         if (ratio < 0.0) {
    //             ratio = 0.0;
    //         }

    //         // Calculate the unique radius for this specific layer
    //         var currentRadius = baseRadius + i * ringSpacing;

    //         // Calculate the end angle in degrees for dc.drawArc
    //         // Because Garmin arcs go counter-clockwise, subtracting the sweep
    //         // makes the arc grow clockwise from the left (180°).
    //         var endAngleDeg = startAngleDeg - ratio * maxSweepDeg;

    //         // --- Step A: Draw the Arc ---
    //         dc.setPenWidth(2); // Adjust thickness as needed
    //         dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
    //         // Optional: Draw a faint background track for context
    //         dc.drawArc(
    //             centerX,
    //             centerY,
    //             currentRadius,
    //             Graphics.ARC_CLOCKWISE,
    //             startAngleDeg,
    //             startAngleDeg - maxSweepDeg
    //         );

    //         dc.setPenWidth(4); // Adjust thickness as needed
    //         dc.setColor(colorRatio, Graphics.COLOR_TRANSPARENT); // Use the color corresponding to this metric
    //         if (ratio > 0) {
    //             dc.drawArc(
    //                 centerX,
    //                 centerY,
    //                 currentRadius,
    //                 Graphics.ARC_CLOCKWISE,
    //                 startAngleDeg,
    //                 endAngleDeg
    //             );
    //         }
    //         dc.setPenWidth(1); // Reset pen width to default

    //         // --- Step B: Calculate and Draw the Terminal Dot ---
    //         // Convert the final degree angle to Radians for standard Math functions
    //         var angleRad = endAngleDeg * (Math.PI / 180.0);

    //         // Calculate X and Y offsets (negating Y because screen coordinates go down)
    //         var dotX = centerX + currentRadius * Math.cos(angleRad);
    //         var dotY = centerY - currentRadius * Math.sin(angleRad);

    //         // Draw the small circle at the end of the arc
    //         dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    //         dc.fillCircle(dotX.toNumber(), dotY.toNumber(), dotRadius);
    //     }
    // }

    // function drawTriangleGauges(dc) {
    //     var width = dc.getWidth();
    //     var height = dc.getHeight();
    //     var centerX = width / 2;
    //     var centerY = height / 2;

    //     // 1. Setup your metrics (0.0 to 1.0)
    //     // var ratios = [0.8, 0.5, 0.9, 0.3, 0.7, 0.4, 1.0, 0.2, 0.6, 0.95];
    //     var ratios = mProgressRatios; // Use the actual progress values from mProgressRatios
    //     var numMetrics = ratios.size();

    //     System.println(["drawTriangleGauges: ratios:", ratios]);
    //     // Calculate the angular width of each slice (in Radians)
    //     var angleStep = (2 * Math.PI) / numMetrics;

    //     // 2. Loop through each metric segment
    //     for (var i = 0; i < numMetrics; i++) {
    //         var colorRatio = mProgressColors[i]; // Use the color corresponding to this metric
    //         var ratio = ratios[i];

    //         // Target angles for the boundaries of this specific slice
    //         var startAngle = i * angleStep;
    //         var endAngle = (i + 1) * angleStep;

    //         // 3. Find the maximum rectangular boundary distance for both angles
    //         // This scales the circular distribution into a perfect outer rectangle.
    //         var maxRadiusStart = getRectRadius(startAngle, width, height);
    //         var maxRadiusEnd = getRectRadius(endAngle, width, height);

    //         // Scale the radius dynamically by the metric's ratio
    //         var currentRadiusStart = maxRadiusStart * ratio;
    //         var currentRadiusEnd = maxRadiusEnd * ratio;

    //         // 4. Calculate the two outer vertex points of the triangle
    //         var pt1X = centerX + currentRadiusStart * Math.cos(startAngle);
    //         var pt1Y = centerY - currentRadiusStart * Math.sin(startAngle); // Negate Y

    //         var pt2X = centerX + currentRadiusEnd * Math.cos(endAngle);
    //         var pt2Y = centerY - currentRadiusEnd * Math.sin(endAngle); // Negate Y

    //         // 5. Draw the metric triangle
    //         // Vertex 0 is always the center hub (centerX, centerY)
    //         dc.setColor(colorRatio, Graphics.COLOR_TRANSPARENT);
    //         dc.fillPolygon([
    //             [centerX, centerY],
    //             [pt1X.toNumber(), pt1Y.toNumber()],
    //             [pt2X.toNumber(), pt2Y.toNumber()],
    //         ]);

    //         // Optional: Draw a thin wireframe border around the slices for definition
    //         dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
    //         dc.drawLine(centerX, centerY, pt1X.toNumber(), pt1Y.toNumber());
    //         dc.drawLine(
    //             pt1X.toNumber(),
    //             pt1Y.toNumber(),
    //             pt2X.toNumber(),
    //             pt2Y.toNumber()
    //         );
    //     }
    // }

    // --- Helper: Intersection of an angle with a bounding rectangle ---
    // This projects a circle outward until it flush-fits a rectangle
    // function getRectRadius(angle, w, h) {
    //     var absCos = Math.cos(angle).abs();
    //     var absSin = Math.sin(angle).abs();

    //     // Determine if the ray hits the top/bottom or left/right walls first
    //     if ((w / 2.0) * absSin <= (h / 2.0) * absCos) {
    //         return w / 2.0 / absCos;
    //     } else {
    //         return h / 2.0 / absSin;
    //     }
    // }

    // --- Helper: Cycle colors for visual distinction ---
    function getMetricColor(index) {
        var colors = [
            Graphics.COLOR_RED,
            Graphics.COLOR_BLUE,
            Graphics.COLOR_GREEN,
            Graphics.COLOR_YELLOW,
            Graphics.COLOR_ORANGE,
            Graphics.COLOR_PURPLE,
            Graphics.COLOR_PINK,
            Graphics.COLOR_DK_GREEN,
            Graphics.COLOR_LT_GRAY,
            Graphics.COLOR_DK_BLUE,
        ];
        return colors[index % colors.size()];
    }

    hidden var mColorScheme as ColorScheme = SCHEME_CLASSIC;

    function getDynamicColor(
        progress as Float?,
        scheme as ColorScheme
    ) as Graphics.ColorType {
        if (progress == null) {
            progress = 0.0f;
        }

        // Exact milestone snap-points for a clean 0.5-second glance on the bike
        if (progress >= 0.98f && progress <= 1.02f) {
            switch (scheme) {
                case SCHEME_INFRARED:
                    return 0x00ff00; // Solid Bright Green at target
                case SCHEME_CYBERPUNK:
                    return 0x00ffd2; // Solid Electric Cyan at target
                case SCHEME_PODIUM:
                    return 0xffd700; // Solid Gold at target
                case SCHEME_PASTEL:
                    return 0xf4f4f6; // Clean, soft off-white
                default:
                    return 0xffd700; // Classic Gold
            }
        }

        // --- PHASE 1: 0% to 50% ---
        if (progress <= 0.5f) {
            var factor = progress / 0.5f;
            switch (scheme) {
                case SCHEME_INFRARED:
                    // Charcoal/Dark Grey [70, 73, 76] to Teal Blue [0, 140, 160]
                    return $.transitionFromTo(
                        255,
                        70,
                        73,
                        76,
                        0,
                        140,
                        160,
                        factor
                    );
                case SCHEME_CYBERPUNK:
                    // Deep Midnight Navy [10, 25, 60] to Electric Cyan [0, 210, 255]
                    return $.transitionFromTo(
                        255,
                        10,
                        25,
                        60,
                        0,
                        210,
                        255,
                        factor
                    );
                case SCHEME_PODIUM:
                    // Dull Copper [120, 70, 45] to Bright Bronze/Copper [190, 115, 65]
                    return $.transitionFromTo(
                        255,
                        120,
                        70,
                        45,
                        190,
                        115,
                        65,
                        factor
                    );
                case SCHEME_PASTEL:
                    // Soft Slate Grey [215, 218, 222] to Powder Blue [190, 210, 230]
                    return $.transitionFromTo(
                        255,
                        215,
                        218,
                        222,
                        190,
                        210,
                        230,
                        factor
                    );
                default: // CLASSIC
                    // Blue [0, 0, 255] to Green [0, 255, 0]
                    return $.transitionFromTo(
                        255,
                        0,
                        0,
                        255,
                        0,
                        255,
                        0,
                        factor
                    );
            }
        }

        // --- PHASE 2: 50% to 100% ---
        else if (progress <= 1.0f) {
            var factor = (progress - 0.5f) / 0.5f;
            switch (scheme) {
                case SCHEME_INFRARED:
                    // Teal Blue [0, 140, 160] to Pure Green [0, 255, 0]
                    return $.transitionFromTo(
                        255,
                        0,
                        140,
                        160,
                        0,
                        255,
                        0,
                        factor
                    );
                case SCHEME_CYBERPUNK:
                    // Electric Cyan [0, 210, 255] to Acid Lime Green [150, 255, 0]
                    return $.transitionFromTo(
                        255,
                        0,
                        210,
                        255,
                        150,
                        255,
                        0,
                        factor
                    );
                case SCHEME_PODIUM:
                    // Bronze [190, 115, 65] to Sleek Chrome/Silver [210, 215, 220]
                    return $.transitionFromTo(
                        255,
                        190,
                        115,
                        65,
                        210,
                        215,
                        220,
                        factor
                    );
                case SCHEME_PASTEL:
                    // Powder Blue [190, 210, 230] to Pale Mint/Sage [190, 225, 205]
                    return $.transitionFromTo(
                        255,
                        190,
                        210,
                        230,
                        190,
                        225,
                        205,
                        factor
                    );
                default: // CLASSIC
                    // Green [0, 255, 0] to Bright Gold/Yellow [255, 215, 0]
                    return $.transitionFromTo(
                        255,
                        0,
                        255,
                        0,
                        255,
                        215,
                        0,
                        factor
                    );
            }
        }

        // --- PHASE 3: 100% to 200% ---
        else if (progress <= 2.0f) {
            var factor = (progress - 1.0f) / 1.0f;
            if (factor > 1.0f) {
                factor = 1.0f;
            }

            switch (scheme) {
                case SCHEME_INFRARED:
                    // Pure Green [0, 255, 0] to Neon Safety Orange [255, 110, 0]
                    return $.transitionFromTo(
                        255,
                        0,
                        255,
                        0,
                        255,
                        110,
                        0,
                        factor
                    );
                case SCHEME_CYBERPUNK:
                    // Acid Lime Green [150, 255, 0] to Neon Hot Pink [255, 0, 130]
                    return $.transitionFromTo(
                        255,
                        150,
                        255,
                        0,
                        255,
                        0,
                        130,
                        factor
                    );
                case SCHEME_PODIUM:
                    // Silver [210, 215, 220] to Bright Trophy Gold [255, 215, 0]
                    return $.transitionFromTo(
                        255,
                        210,
                        215,
                        220,
                        255,
                        215,
                        0,
                        factor
                    );
                case SCHEME_PASTEL:
                    // Pale Mint [190, 225, 205] to Creamy Peach/Chalky Coral [245, 205, 190]
                    return $.transitionFromTo(
                        255,
                        190,
                        225,
                        205,
                        245,
                        205,
                        190,
                        factor
                    );
                default: // CLASSIC
                    // Gold [255, 215, 0] to Dark Red [139, 0, 0]
                    return $.transitionFromTo(
                        255,
                        255,
                        215,
                        0,
                        139,
                        0,
                        0,
                        factor
                    );
            }
        }

        // --- PHASE 4: Beyond 200% ---
        else {
            var factor = (progress - 2.0f) / 1.0f;
            if (factor > 1.0f) {
                factor = 1.0f;
            }

            switch (scheme) {
                case SCHEME_INFRARED:
                    // Neon Safety Orange [255, 110, 0] to Deep Violet/Burnt Magenta [90, 0, 80]
                    return $.transitionFromTo(
                        255,
                        255,
                        110,
                        0,
                        90,
                        0,
                        80,
                        factor
                    );
                case SCHEME_CYBERPUNK:
                    // Neon Hot Pink [255, 0, 130] to Hyper White [255, 255, 255]
                    return $.transitionFromTo(
                        255,
                        255,
                        0,
                        130,
                        255,
                        255,
                        255,
                        factor
                    );
                case SCHEME_PODIUM:
                    // Trophy Gold [255, 215, 0] to Diamond Mint/Electric Ice [160, 245, 220]
                    return $.transitionFromTo(
                        255,
                        255,
                        215,
                        0,
                        160,
                        245,
                        220,
                        factor
                    );
                case SCHEME_PASTEL:
                    // Creamy Peach [245, 205, 190] to Muted Lavender/Lilac [220, 200, 230]
                    return $.transitionFromTo(
                        255,
                        245,
                        205,
                        190,
                        220,
                        200,
                        230,
                        factor
                    );
                default: // CLASSIC
                    // Dark Red [139, 0, 0] to Maroon Black [40, 0, 5]
                    return $.transitionFromTo(255, 139, 0, 0, 40, 0, 5, factor);
            }
        }
    }

    function getDynamicColorDefault(progress as Float?) as Graphics.ColorType {
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
        var hasAttention = mProgress.hasActiveAlert(fieldType);

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

        if (mFieldDivider > 0) {
            // Draw a horizontal divider line at the specified height from the bottom
            var dividerY = y + h - ((h * mFieldDivider) / 100).toNumber();
            if (fillHeight != dividerY - y) {
                // Only draw the divider if it is not exactly at the fill height
                dc.setColor(colors[:divider], Graphics.COLOR_TRANSPARENT);
                dc.drawLine(x, dividerY, x + w, dividerY);
            }
        }

        // draw a border around the bar for better visibility
        if (hasAttention) {
            dc.setColor(colors[:borderAttention], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
        } else {
            dc.setColor(colors[:border], Graphics.COLOR_TRANSPARENT);
        }
        dc.drawRoundedRectangle(x, y, w, h, 4);
        dc.setPenWidth(1);

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
            dc.setPenWidth(1);
        }

        // For now only showing label
        if (
            mFieldShowLabels ||
            mShowDetailsOnPause ||
            mShowDetailsOn0Cadence ||
            hasAttention ||
            isFocusField(fieldType)
        ) {
            // Label centered at the bottom of the bar when paused
            var tx = x + w / 2;
            var ty = y + h - dc.getFontHeight(Graphics.FONT_XTINY) - 2;
            var textLabel = getFieldLabel(fieldType);
            if (hasAttention) {
                textLabel = "EAT";
            }

            var maxBarTextWidth = w - 4; // Leave a 2px padding buffer on each side
            var fitCount = $.getMaxCharactersThatFit(
                dc,
                textLabel,
                Graphics.FONT_XTINY,
                maxBarTextWidth
            );

            if (textLabel.length() <= fitCount) {
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
                    textLabel,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else {
                // Draw text vertical
                drawStackedVerticalLabel(
                    dc,
                    textLabel,
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

    hidden var mMaxPower as Float = 0.0f; // Store the maximum power value for the power gauge
    hidden var mMaxSpeed as Float = 0.0f; // Store the maximum speed value for the speed gauge

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
        var hasAttention = mProgress.hasActiveAlert(fieldType);

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

        if (mFieldDivider > 0) {
            // Draw a vertical divider line at the specified position from the left
            var dividerX = x + ((w * mFieldDivider) / 100).toNumber();
            if (fillRightX != dividerX) {
                // Only draw the divider if it is not exactly at the fill width
                dc.setColor(colors[:divider], Graphics.COLOR_TRANSPARENT);
                dc.drawLine(dividerX, y, dividerX, y + h);
            }
        }

        // draw a border around the bar for better visibility
        if (hasAttention) {
            dc.setColor(colors[:borderAttention], Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
        } else {
            dc.setColor(colors[:border], Graphics.COLOR_TRANSPARENT);
        }
        dc.drawRoundedRectangle(x, y, w, h, 4);
        dc.setPenWidth(1);

        var showLabel =
            mFieldShowLabels ||
            mShowDetailsOnPause ||
            mShowDetailsOn0Cadence ||
            hasAttention;
        var showValues =
            (mFieldShowValues &&
                (mShowDetailsOnPause || mShowDetailsOn0Cadence)) ||
            isFocusField(fieldType);

        // 5. Inline Checkmark (Rendered at the far right edge of the bar)
        // Only when not showing values.
        if (progress >= 1.0 && !showValues) {
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
            dc.setPenWidth(1);
        }

        if (showLabel) {
            var textLabel = getFieldLabelWide(fieldType);
            if (hasAttention) {
                textLabel += " EAT!";
            }
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

                if ($.isColorLight(underlyingColor)) {
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

            // Show values
            if (showValues) {
                var textValue = getFormattedValue(
                    mProgress.getProgressFieldValue(fieldType),
                    fieldType,
                    false
                );

                // Position text: Centered vertically inside the bar height, with a 6px right margin
                var fontValue = Graphics.FONT_XTINY;
                var fontValueHeight = dc.getFontHeight(fontValue);
                var textValueY = y + (h - fontValueHeight) / 2;
                var startValueX = x + w - 6; // Right-align with a 6px margin from the right edge

                // Draw the value text character-by-character from right to left
                for (var i = textValue.length() - 1; i >= 0; i--) {
                    var charStr = textValue.substring(i, i + 1);
                    var charWidth = dc.getTextWidthInPixels(charStr, fontValue);

                    // Determine the horizontal midpoint of this specific letter
                    var charMidX = startValueX - charWidth / 2;

                    // Contrast Check: Is this letter's midpoint inside the filled color block?
                    var underlyingColor = trackColor;
                    if (fillWidth > 0 && charMidX <= fillRightX) {
                        underlyingColor = barColor; // Letter is sitting on top of the color fill
                    }

                    if ($.isColorLight(underlyingColor)) {
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
                //}
            }
        } // mFieldShowLabels || mShowDetailsOnPause)
    }

    hidden function drawStaminaProgressBar(
        dc as Graphics.Dc,
        barX as Number,
        barY as Number,
        barWidth as Number,
        barHeight as Number,
        staminaBar as StaminaBar
    ) as Void {
        var ratio;
        var gaugeColor = 0;
        if (staminaBar == SBShowStamina) {
            ratio = $.gAnaerobicWork.getStaminaRatio();
            gaugeColor = transitionFromTo(
                255,          // Alpha
                255, 23, 68,  // Red at 0.0 percent
                0, 230, 118,  // Green at 1.0 percent
                ratio
            );
        } else if (staminaBar == SBShowFatigue) {
            ratio = $.gAnaerobicWork.getFatigueRatio();
            gaugeColor = transitionFromTo(
                255,           // Alpha
                40, 160, 220,  // Cool Slate at 0.0 percent
                255, 50, 0,    // Fiery Red at 1.0 percent
                ratio
            );
        } else {
            return;
        }
                
        // 2. Draw Trough / Background Track (Dark Gray or Translucent)
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barWidth, barHeight);
        
        // 4. Calculate Inner Fill Width
        var fillWidth = (barWidth * ratio).toNumber();

        // 5. Draw Active Fill Bar
        if (fillWidth > 0) {
            dc.setColor(gaugeColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, fillWidth, barHeight);
        }

        // 6. Draw Subtle Separator/Border line across top of the bar
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(barX, barY, barX + barWidth, barY);

        // 7. Optional Text Centering (If bar height is large enough, e.g. >= 14px)
        if (barHeight >= 14) {
            var ratioPercent = (ratio * 100).toNumber().format("%d") + " %";
            var textWidth = dc.getTextWidthInPixels(ratioPercent, Graphics.FONT_XTINY);
            // Check if gaugeColor hitting the start of the text
            var textStartX = barX + (barWidth - textWidth) / 2;
            if (textStartX < barX + fillWidth) {
                // Text is overlapping the filled portion, so we need to ensure contrast
                if ($.isColorLight(gaugeColor)) {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                } else {
                    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                }
            } else {
                // Text is fully on the empty portion, so use default text color
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            }
            
            dc.drawText(
                barX + barWidth / 2,
                barY + barHeight / 2,
                Graphics.FONT_XTINY,
                ratioPercent,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    hidden var rad2degFactor as Float = 180 / Math.PI; // Conversion factor from radians to degrees

    // Parameters:
    // dc - The device context
    // cx, cy - Center coordinates of the gauge
    // r - Radius of the circle
    // currentSpeed - Current speed value
    // avgSpeed - Average speed value
    // maxSpeed - Maximum speed value
    // targetSpeed - The target speed (acts as the 100% mark at 90 degrees right)
    function drawSpeedGauge(
        dc,
        cx,
        cy,
        baseRadius,
        currentSpeed,
        avgSpeed,
        maxSpeed,
        targetSpeed
    ) {
        if (targetSpeed == null || targetSpeed <= 0) {
            targetSpeed = 1.0;
        }

        // --- Dynamic Radius Scaling ---
        var currentRadius = baseRadius;
        var percentage = currentSpeed / targetSpeed;

        if (percentage > 1.0) {
            // Calculate how far past the target they are (e.g., 1.08 means 8% over)
            var excessPercentage = percentage - 1.0;

            // Scale factor: grows the radius by 50% of the excess percentage.
            // (An 8% over-speed will grow the radius by 4%)
            var scaleFactor = 1.0 + excessPercentage * 0.5;

            currentRadius = baseRadius * scaleFactor;
        }

        System.println(
            "drawSpeedGauge: currentSpeed=" +
                currentSpeed +
                ", avgSpeed=" +
                avgSpeed +
                ", maxSpeed=" +
                maxSpeed +
                ", targetSpeed=" +
                targetSpeed
        );
        // 1. Draw the base semi-circle (from 180 degrees to 0 degrees)
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        // Draw arc: cx, cy, radius, graphics_arc_direction, start_angle, end_angle
        // In Connect IQ, 0deg is right, 90deg is top. We draw from left (180) to right (0) clockwise.
        dc.drawArc(cx, cy, currentRadius, Graphics.ARC_CLOCKWISE, 180, 0);

        // Draw AVERAGE Speed Indication
        if (avgSpeed > 0) {
            drawAverageArc(dc, cx, cy, currentRadius, avgSpeed, targetSpeed);
        }
        // Draw MAXIMUM Speed Indication (A small tick mark or dot)
        if (maxSpeed > 0) {
            drawMaxSpeedIndicator(
                dc,
                cx,
                cy,
                currentRadius,
                maxSpeed,
                targetSpeed
            );
        }

        // Draw CURRENT Speed (Arrow/line from center to circle)
        var curDegrees = speedToDegrees(currentSpeed, targetSpeed);

        dc.setPenWidth(10);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(
            cx,
            cy,
            currentRadius - 10,
            Graphics.ARC_CLOCKWISE,
            180,
            curDegrees
        ); // Convert radians to degrees for drawArc

        var curPoint = point2DOnCircle(cx, cy, currentRadius, curDegrees);
        var curLeft = point2DOnCircle(
            cx,
            cy,
            currentRadius * 0.9,
            curDegrees - 2
        );
        var curRight = point2DOnCircle(
            cx,
            cy,
            currentRadius * 0.9,
            curDegrees + 2
        );
        var centerPoint = [cx, cy];
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.fillPolygon([centerPoint, curLeft, curPoint, curRight]);
        //dc.drawLine(cx, cy, curPoint[0], curPoint[1]);

        // Optional: Draw a small center hub to clean up the line origin
        dc.fillCircle(cx, cy, 5);
    }

    // keep in mind that Garmin's drawing system natively uses degrees, but its 0° starts at the 3 o'clock position (pointing right)
    // and goes counter-clockwise. Since your code maps 180° down to 0°, your gauge will correctly sweep clockwise from the left side to the right side!
    // --- Helper to convert speed to angles (in Degrees) ---
    // 0 speed = 180 deg
    // Target speed = 0 deg
    function speedToDegrees(speed, target) {
        if (target == null || target <= 0) {
            target = 1.0;
        }
        var percentage = speed / target;
        if (percentage > 1.1) {
            percentage = 1.1;
        } // Cap slightly past target so it doesn't spin infinitely
        else if (percentage < 0) {
            percentage = 0;
        }

        // Map 0 -> 1 to 180 -> 0 degrees (Clockwise)
        return 180.0 - percentage * 180.0;
    }

    function drawMaxSpeedIndicator(dc, cx, cy, r, maxSpeed, targetSpeed) {
        var maxDegrees = speedToDegrees(maxSpeed, targetSpeed);
        var maxPoint = point2DOnCircle(cx, cy, r, maxDegrees);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(maxPoint[0], maxPoint[1], 5);
    }

    function drawAverageArc(dc, cx, cy, r, avgSpeed, targetSpeed) {
        var avgDegrees = speedToDegrees(avgSpeed, targetSpeed);

        dc.setPenWidth(20);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r - 20, Graphics.ARC_CLOCKWISE, 180, avgDegrees); // Convert radians to degrees for drawArc
        // dc.setPenWidth(18);
        // dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        // dc.drawArc(
        //     cx,
        //     cy,
        //     r - 20,
        //     Graphics.ARC_CLOCKWISE,
        //     180,
        //     avgAngle * rad2degFactor
        // );
    }

    function drawTenColumnTargetRing(
        dc,
        cX as Number,
        cY as Number,
        outerRadius as Number,
        progressArray as Array<Float>
    ) as Void {
        var numColumns = 10;
        var columnThickness = 4; // Thin, high-density professional lines
        var columnSpacing = 2; // 2-pixel gap between data lanes

        // 360-degree full circles look spectacular for clean column charts.
        // We start at the top (90°) and draw clockwise.
        var startAngle = 90;

        // Loop from index 0 (innermost column) to index 9 (outermost column)
        for (var i = 0; i < numColumns; i++) {
            // Calculate radius moving from inside out
            var currentRadius =
                outerRadius -
                (numColumns - 1 - i) * (columnThickness + columnSpacing);

            // 1. Draw the underlying muted column track (0% track)
            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT); // Very dark subtle gray track
            dc.setPenWidth(columnThickness);
            dc.drawCircle(cX, cY, currentRadius);

            // 2. Fetch progress state and clamp safely
            var progress = progressArray[i];
            if (progress == null || progress < 0.0f) {
                progress = 0.0f;
            } else if (progress > 1.0f) {
                progress = 1.0f;
            }

            if (progress > 0.001f) {
                // Calculate exact sweeping angle based on percentage
                var sweepAngle = (progress * 360).toNumber();
                var endAngle = startAngle - sweepAngle;

                // Set dynamic color based on progress tier or a column palette array
                dc.setColor(
                    getColumnColorPalette(i),
                    Graphics.COLOR_TRANSPARENT
                );
                dc.drawArc(
                    cX,
                    cY,
                    currentRadius,
                    Graphics.ARC_CLOCKWISE,
                    startAngle,
                    endAngle
                );
            }
        }

        dc.setPenWidth(1); // Reset standard pen width
    }

    // A clean cyber-grid color array going from deep blues to bright neon accents
    function getColumnColorPalette(index as Number) as Number {
        var palette = [
            0x0055ff, // 0: Innermost
            0x00aaff, // 1
            0x00ffbb, // 2
            0x00ff55, // 3
            0x55ff00, // 4
            0xaaff00, // 5
            0xffff00, // 6
            0xffaa00, // 7
            0xff5500, // 8
            0xff0055, // 9: Outermost
        ];
        return palette[index];
    }

    using Toybox.Graphics;
    using Toybox.Math;

    function drawSpokeDashboard(
        dc,
        cX as Number,
        cY as Number,
        maxRadius as Number,
        numSpokes as Number,
        progressArray as Array<Float>
    ) as Void {
        var angleStep = (360 / numSpokes).toNumber(); // 360 degrees / 10 columns
        var minRadius = 25; // Leaving a hollow hub in the middle for your text/speed!

        dc.setPenWidth(20); // Makes the columns chunky and highly visible while riding

        for (var i = 0; i < numSpokes; i++) {
            // Calculate the direction angle for this specific column in radians
            var degrees = i * angleStep;
            var rad = degrees * (Math.PI / 180.0f);

            var cosVal = Math.cos(rad);
            var sinVal = Math.sin(rad);

            // 1. Calculate where the column starts (the inner hub border)
            var startX = (cX + minRadius * cosVal).toNumber();
            var startY = (cY + minRadius * sinVal).toNumber();

            // 2. Draw the background track (representing the 100% goal line)
            var maxTargetX = (cX + maxRadius * cosVal).toNumber();
            var maxTargetY = (cY + maxRadius * sinVal).toNumber();

            dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT); // Subtle dark track
            dc.drawLine(startX, startY, maxTargetX, maxTargetY);

            // 3. Calculate and overlay the active progress column length
            var progress = progressArray[i];
            if (progress == null || progress < 0.0f) {
                progress = 0.0f;
            } else if (progress > 1.0f) {
                progress = 1.0f;
            }

            if (progress > 0.01f) {
                // Calculate current length between the inner hub and max radius
                var activeRange = maxRadius - minRadius;
                var currentRadius = minRadius + activeRange * progress;

                var progressX = (cX + currentRadius * cosVal).toNumber();
                var progressY = (cY + currentRadius * sinVal).toNumber();

                // Apply your custom styling color to the active column spoke
                dc.setColor(getSpokeColor(i), Graphics.COLOR_TRANSPARENT);
                dc.drawLine(startX, startY, progressX, progressY);
            }
        }

        dc.setPenWidth(1); // Reset canvas line settings
    }

    function getSpokeColor(index as Number) as Number {
        var colors = [
            0x00aaff, 0x00ff55, 0xffff00, 0xff5500, 0xaa00ff, 0x0055ff,
            0x00ffbb, 0x55ff00, 0xffaa00, 0xff0055,
        ];
        return colors[index];
    }

    hidden function getFormattedValue(
        value as Float or Number or Null,
        fieldType as FieldType,
        zeroIsEmpty as Boolean
    ) as String {
        if (value == null) {
            value = 0.0f;
        }
        if (zeroIsEmpty && value == 0.0f) {
            return "";
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
                // System.println(["getFormattedValue: Heart Rate Zone:", value]);
                return value.format("%.1f");
            case FTPower:
            case FTAveragePower:
            case FTNormalizedPower:
                return value.format("%.0f") + " W"; // Power is already in watts
            case FTSpeed:
            case FTAverageSpeed:
                return value.format("%.1f") + " KM/H";
            case FTAverageCadence:
            case FTCadence:
                return value.format("%.0f") + " RPM"; // Cadence is already in rpm
            case FTTotalAscent:
            case FTTotalDescent:
                return value.format("%.0f") + " M"; // Ascent/Descent is already in meters
            case FTMinutesElapsed:
                // value is in minutes, convert to seconds for HH:MM:SS formatting
                return $.formatSecondsToHMS((value * 60).toNumber()); // Convert minutes to HH:MM:SS
            case FTIntensityFactor:
                return value.format("%.2f"); // Intensity Factor is unitless
            case FTTrainingStressScore:
                return value.format("%.0f"); // TSS is unitless
            case FTStamina:
                return value.format("%.0f") + " %"; // Stamina is a percentage
            case FTFatigue:
                return value.format("%.0f") + " %"; // Fatigue is a percentage
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

        var xP = x + radius.toFloat() * cos;
        // In computer graphics, the Y-axis is inverted (increasing Y goes down), so we subtract the sine component
        var yP = y - radius.toFloat() * sin;

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
                // if ($.gHeartRate.getIsInWarmUp()) {
                //     return "RZ0";
                // }
                return "Z" + $.gTargetHeartRateZone.format("%0.1f");
            case FTAverageHeartRateZone:
                // if ($.gHeartRate.getIsInWarmUp()) {
                //     return "øZ0";
                // }
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
            case FTStamina:
                return "STA";
            case FTFatigue:
                return "FAT";
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
                return "TIME ELAPSED";
            case FTAverageHeartRateZone:
                // if ($.gHeartRate.getIsInWarmUp()) {
                //     return "AVG HRZ WARMUP";
                // }
                return (
                    "AVG HEARTRATEZONE " +
                    $.gTargetAverageHeartRateZone.format("%0.1f")
                );
            case FTHeartRateZone:
                // if ($.gHeartRate.getIsInWarmUp()) {
                //     return "HRZ WARMUP";
                // }
                return "HEARTRATEZONE " + $.gTargetHeartRateZone.format("%.1f");
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
            case FTStamina:
                return "STAMINA";
            case FTFatigue:
                return "FATIGUE";
            default:
                return "";
        }
    }

    // --- Premium Edge 1050 Bright Grays ---
    const COLOR_ALABASTER = 0xf2f2f2; // 95% Brightness - Incredibly clean, barely-there gray
    const COLOR_PLATINUM = 0xe5e5e5; // 90% Brightness - Premium tech track look (Highly Recommended)
    const COLOR_GAINSBORO = 0xdcdcdc; // 86% Brightness - Safe, solid background track
    const COLOR_SILVER_LIGHT = 0xd3d3d3; // 83% Brightness - Noticeably lighter than standard Garmin Lt Gray

    const COLOR_ELECTRIC_BLUE = 0x00a8ff;
    function getThemeColor(darkBackground) as Dictionary {
        return {
            :border => darkBackground
                ? COLOR_SILVER_LIGHT
                : Graphics.COLOR_DK_GRAY,
            :track => darkBackground ? Graphics.COLOR_DK_GRAY : COLOR_PLATINUM,
            :divider => darkBackground
                ? Graphics.COLOR_BLACK
                : Graphics.COLOR_WHITE,
            :borderAttention => darkBackground
                ? COLOR_ALABASTER
                : COLOR_ELECTRIC_BLUE,
            :text => darkBackground
                ? Graphics.COLOR_WHITE
                : Graphics.COLOR_BLACK,
        };
    }
}
