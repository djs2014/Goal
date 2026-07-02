import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

enum {
    PROFILE_CASUAL,
    PROFILE_ENDURANCE,
    PROFILE_SHORT_FAST,
    PROFILE_WEIGHT_LOSS,
    PROFILE_CARDIO,
    PROFILE_RECOVERY,
}

using Toybox.Lang;
using Toybox.Math;

function getPresetSummary(profileId as String) as String {
    var distanceKm = $.getStorageValue("preset_distance", 0) as Number;
    var durationMinutes = $.getStorageValue("preset_duration", 0) as Number;

    var profileType = PROFILE_CASUAL;
    switch (profileId) {
        case "preset_casual":
            profileType = PROFILE_CASUAL;
            break;
        case "preset_endurance":
            profileType = PROFILE_ENDURANCE;
            break;
        case "preset_short_fast":
            profileType = PROFILE_SHORT_FAST;
            break;
        case "preset_weight_loss":
            profileType = PROFILE_WEIGHT_LOSS;
            break;
        case "preset_cardio":
            profileType = PROFILE_CARDIO;
            break;
        case "preset_recovery":
            profileType = PROFILE_RECOVERY;
            break;
    }

    var targets = generateProfileTargetsWithSuffer(
        distanceKm,
        durationMinutes,
        profileType
    );

    var distanceOrDuration = "";
    if (distanceKm > 0) {
        // Distance is set, show calculated duration in HH:MM format
        var calculatedDurationMinutes = targets["target_duration"] as Number;
        var hhmm = $.formatSecondsToHM(calculatedDurationMinutes * 60); // Convert minutes to HH:MM
        distanceOrDuration = hhmm;
    } else if (durationMinutes > 0) {
        var calculatedDistanceKm = targets["target_distance"] as Number;
        distanceOrDuration = calculatedDistanceKm.format("%.1f") + "km";
    }

    var info =
        distanceOrDuration +
        "," +
        // targets["target_calories"] +
        // "c," +
        targets["target_average_speed"].format("%.0f") +
        "km/h," +
        targets["target_average_power"].format("%d") +
        "w," +
        targets["target_average_cadence"].format("%d") +
        "rpm,rz " +
        targets["target_average_heart_rate_zone"].format("%.1f");
    return info;
}

function applyPreset(profileId as String) as Boolean {
    var distanceKm = $.getStorageValue("preset_distance", 0) as Number;
    var durationMinutes = $.getStorageValue("preset_duration", 0) as Number;
    var profileType = PROFILE_CASUAL;

    switch (profileId) {
        case "preset_casual":
            profileType = PROFILE_CASUAL;
            break;
        case "preset_endurance":
            profileType = PROFILE_ENDURANCE;
            break;
        case "preset_short_fast":
            profileType = PROFILE_SHORT_FAST;
            break;
        case "preset_weight_loss":
            profileType = PROFILE_WEIGHT_LOSS;
            break;
        case "preset_cardio":
            profileType = PROFILE_CARDIO;
            break;
        case "preset_recovery":
            profileType = PROFILE_RECOVERY;
            break;
    }

    var targets = generateProfileTargetsWithSuffer(
        distanceKm,
        durationMinutes,
        profileType
    );

    // Store the generated targets in persistent storage
    Storage.setValue("target_distance", targets["target_distance"]);
    Storage.setValue("target_duration", targets["target_duration"]);
    Storage.setValue("target_calories", targets["target_calories"]);
    Storage.setValue("target_power", targets["target_power"]);
    Storage.setValue("target_average_power", targets["target_average_power"]);
    Storage.setValue(
        "target_normalized_power",
        targets["target_normalized_power"]
    );
    Storage.setValue("target_speed", targets["target_speed"]);
    Storage.setValue("target_average_speed", targets["target_average_speed"]);
    Storage.setValue("target_cadence", targets["target_cadence"]);
    Storage.setValue(
        "target_average_cadence",
        targets["target_average_cadence"]
    );
    Storage.setValue(
        "target_heart_rate_zone",
        targets["target_heart_rate_zone"]
    );
    Storage.setValue(
        "target_average_heart_rate_zone",
        targets["target_average_heart_rate_zone"]
    );
    Storage.setValue(
        "target_intensity_factor",
        targets["target_intensity_factor"]
    );
    Storage.setValue(
        "target_training_stress_score",
        targets["target_training_stress_score"]
    );

    return true;
}

function generateProfileTargetsWithSuffer(
    distanceKm as Number,
    durationMinutes as Number,
    profileType as Number
) as Dictionary {
    var sufferFactor = $.getStorageValue("preset_suffer_factor", 1.0f) as Float;

    // 1. Generate your standard base targets first (using our previous function)
    var targets = generateProfileTargets(
        distanceKm,
        durationMinutes,
        profileType
    );

    if (sufferFactor == 1.0f) {
        // No adjustment needed, return the original targets
        return targets;
    }

    // Ensure the modifier stays within your clean 0.5 to 2.0 guardrails
    if (sufferFactor < 0.5f) {
        sufferFactor = 0.5f;
    }
    if (sufferFactor > 2.0f) {
        sufferFactor = 2.0f;
    }

    // 2. Adjust Speed & Recalculate Duration

    // Metrics tracking the time spent on the road handle distance inversely.
    // If you are riding with a high suffer factor (1.5), you will ride faster,
    // meaning Duration drops for a fixed-distance route.
    if (distanceKm > 0) {
        // Distance fixed
        var baseSpeed = targets["target_average_speed"];
        var adjustedSpeed = baseSpeed * sufferFactor;
        if (adjustedSpeed == 0.0f) {
            return targets;
        }
        // Clamp speed to realistic human cycling realities (e.g., max 45 km/h average)
        if (adjustedSpeed > 45.0f) {
            adjustedSpeed = 45.0f;
        }
        targets["target_average_speed"] = adjustedSpeed;
        targets["target_speed"] = adjustedSpeed;
        var adjustedDurationHrs = distanceKm / adjustedSpeed;
        targets["target_duration"] = adjustedDurationHrs * 60; // Convert to minutes
    } else if (durationMinutes > 0) {
        // Duration fixed
        var baseDistance = targets["target_distance"];
        var adjustedDistance = baseDistance * sufferFactor;
        // Clamp distance to realistic human cycling realities (e.g., max 200 km for a single ride)
        // if (adjustedDistance > 200.0f) { adjustedDistance = 200.0f; }
        targets["target_distance"] = adjustedDistance;
        var durationHrs = durationMinutes / 60.0f;
        if (durationHrs == 0.0f) {
            return targets;
        }
        var adjustedSpeed = adjustedDistance / durationHrs;
        // Clamp speed to realistic human cycling realities (e.g., max 45 km/h average)
        if (adjustedSpeed > 45.0f) {
            adjustedSpeed = 45.0f;
        }
        targets["target_average_speed"] = adjustedSpeed;
        targets["target_speed"] = adjustedSpeed;
    }

    // 3. Apply Linear Adjustments to Power & Energy
    targets["target_average_power"] =
        targets["target_average_power"] * sufferFactor;
    targets["target_power"] = targets["target_power"] * sufferFactor;
    targets["target_normalized_power"] =
        targets["target_normalized_power"] * sufferFactor;
    targets["target_intensity_factor"] =
        targets["target_intensity_factor"] * sufferFactor;

    // Calories scale directly with the adjusted intensity and duration
    targets["target_calories"] = (
        targets["target_calories"] * sufferFactor
    ).toNumber();

    // 4. Apply Exponential Adjustment to TSS
    // Double the effort yields roughly 4x the stress accumulation over time
    targets["target_training_stress_score"] = (
        targets["target_training_stress_score"] *
        (sufferFactor * sufferFactor)
    ).toNumber();

    // 5. Adjust Heart Rate Zone securely (Clamped between Z1 and Z5)
    var adjustedHRZone =
        targets["target_average_heart_rate_zone"] * sufferFactor;
    if (adjustedHRZone > 5.0f) {
        adjustedHRZone = 5.0f;
    }
    if (adjustedHRZone < 1.0f) {
        adjustedHRZone = 1.0f;
    }

    targets["target_average_heart_rate_zone"] = adjustedHRZone;
    targets["target_heart_rate_zone"] = adjustedHRZone * 1.15f;
    if (targets["target_heart_rate_zone"] > 5.0f) {
        targets["target_heart_rate_zone"] = 5.0f;
    }

    // Leave cadence un-multiplied so your pedaling biomechanics stay natural!

    return targets;
}

// distanceKm or durationhrs is set to 0;
function generateProfileTargets(
    distanceKm as Number,
    durationMinutes as Number,
    profileType as Number
) as Dictionary {
    // Initialize our configuration container
    var targets = {
        "target_distance" => distanceKm,
        "target_duration" => durationMinutes,
        "target_calories" => 0,
        "target_power" => 0.0f,
        "target_average_power" => 0.0f,
        "target_speed" => 0.0f, // in km/h
        "target_average_speed" => 0.0f, // in km/h
        "target_cadence" => 0.0f,
        "target_average_cadence" => 0.0f,
        "target_normalized_power" => 0.0f,
        "target_heart_rate_zone" => 0.0f,
        "target_average_heart_rate_zone" => 0.0f,
        "target_intensity_factor" => 0.0f,
        "target_training_stress_score" => 0,
    };

    // Baseline FTP and Max HR
    var userFTP = $.getUserFtp(); // Fetch the user's Functional Threshold Power
    var myFTP = userFTP > 0 ? userFTP : 220.0f; // Default to 220W if FTP is not set
    var durationHrs = durationMinutes / 60.0f;

    switch (profileType) {
        case PROFILE_CASUAL:
            targets["target_speed"] = 22.0f;
            targets["target_average_speed"] = 20.0f;
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.50f;
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.1f;
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.02f;
            targets["target_calories"] = (durationHrs * 400).toNumber(); // Lower burn rate
            targets["target_cadence"] = 85.0f;
            targets["target_average_cadence"] = 80.0f;
            targets["target_heart_rate_zone"] = 1.8f;
            targets["target_average_heart_rate_zone"] = 1.5f;
            targets["target_training_stress_score"] = (
                durationHrs * 25
            ).toNumber(); // Low strain
            break;

        case PROFILE_ENDURANCE:
            // Designed to handle your big 150km rides smoothly
            targets["target_speed"] = 28.0f;
            targets["target_average_speed"] = 26.0f;
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.68f; // Classic Zone 2 pacing
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.2f;
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.05f;
            targets["target_calories"] = (durationHrs * 650).toNumber(); // Heavy cumulative burn
            targets["target_cadence"] = 90.0f;
            targets["target_average_cadence"] = 88.0f;
            targets["target_heart_rate_zone"] = 2.5f;
            targets["target_average_heart_rate_zone"] = 2.2f;
            targets["target_training_stress_score"] = (
                durationHrs * 46
            ).toNumber(); // ~46 TSS per hour at 0.68 IF
            break;

        case PROFILE_SHORT_FAST:
            targets["target_speed"] = 32.0f;
            targets["target_average_speed"] = 32.0f; // High-velocity pace
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.90f; // Threshold / Sweetspot pacing
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.3f; // High sprint targets
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.10f;
            targets["target_calories"] = (durationHrs * 900).toNumber(); // Aggressive carbohydrate expenditure
            targets["target_cadence"] = 96.0f;
            targets["target_average_cadence"] = 92.0f;
            targets["target_heart_rate_zone"] = 4.2f;
            targets["target_average_heart_rate_zone"] = 3.8f;
            targets["target_training_stress_score"] = (
                durationHrs * 81
            ).toNumber(); // Heavy strain per hour
            break;

        case PROFILE_WEIGHT_LOSS:
            // Locked specifically into optimal lipid/fat oxidation thresholds
            targets["target_speed"] = 22.0f;
            targets["target_average_speed"] = 22.0f;
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.60f; // Pure fat burning ceiling
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.05f; // Keep intervals flat
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.02f;
            targets["target_calories"] = (durationHrs * 500).toNumber();
            targets["target_cadence"] = 85.0f;
            targets["target_average_cadence"] = 82.0f;
            targets["target_heart_rate_zone"] = 2.2f; // Dead center Zone 2
            targets["target_average_heart_rate_zone"] = 2.0f;
            targets["target_training_stress_score"] = (
                durationHrs * 36
            ).toNumber();
            break;

        case PROFILE_CARDIO:
            // Aerobic capacity development / Stroke volume optimization
            targets["target_speed"] = 28.0f;
            targets["target_average_speed"] = 28.0f;
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.78f; // Tempo / Zone 3 boundary
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.25f;
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.07f;
            targets["target_calories"] = (durationHrs * 750).toNumber();
            targets["target_cadence"] = 94.0f; // High cadence target to unload muscles onto cardiovascular system
            targets["target_average_cadence"] = 90.0f;
            targets["target_heart_rate_zone"] = 3.5f; // Solid Zone 3
            targets["target_average_heart_rate_zone"] = 3.2f;
            targets["target_training_stress_score"] = (
                durationHrs * 60
            ).toNumber();
            break;
        case PROFILE_RECOVERY:
            // Pacing is gentle to ensure zero cardiovascular accumulation
            targets["target_speed"] = 18.0f;
            targets["target_average_speed"] = 18.0f; // Soft, easy cruising speed
            if (distanceKm > 0) {
                durationHrs = distanceKm / targets["target_average_speed"];
            } else if (durationHrs > 0) {
                distanceKm = durationHrs * targets["target_average_speed"];
            }

            targets["target_intensity_factor"] = 0.45f; // Strictly below the Zone 1 recovery ceiling (0.55)
            targets["target_average_power"] =
                myFTP * targets["target_intensity_factor"];
            targets["target_power"] = targets["target_average_power"] * 1.05f; // Flat, cap any surges
            targets["target_normalized_power"] =
                targets["target_average_power"] * 1.01f; // Zero variability
            targets["target_calories"] = (durationHrs * 300).toNumber(); // Low energy cost

            // Cadence is kept relatively high to avoid muscular straining
            targets["target_cadence"] = 90.0f;
            targets["target_average_cadence"] = 85.0f;

            targets["target_heart_rate_zone"] = 1.4f; // Bottom half of Zone 1
            targets["target_average_heart_rate_zone"] = 1.2f;
            targets["target_training_stress_score"] = (
                durationHrs * 20
            ).toNumber(); // Minimal TSS load
            break;
    }

    // Update calculated values
    targets["target_distance"] = distanceKm;
    targets["target_duration"] = durationHrs * 60;

    System.println(targets);
    return targets;
}

class PresetsMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _item as MenuItem?;
    hidden var _storageKey as String = "";
    hidden var _arrayIndex as Number = -1;

    hidden var _currentPrompt as String = "";
    hidden var _parentMenu as WatchUi.Menu2;
    hidden var _maxMenuItemIdx as Number = 0;

    function initialize(parentMenu as WatchUi.Menu2, maxMenuItemIdx as Number) {
        Menu2InputDelegate.initialize();
        _parentMenu = parentMenu;
        _maxMenuItemIdx = maxMenuItemIdx;
    }

    function onSelect(menuItem as MenuItem) as Void {
        _item = menuItem;
        var id = menuItem.getId();

        // Extract selected storage key and index
        _storageKey = stringLeft(id.toString(), "|", id.toString());
        var idx = stringRight(id.toString(), "|", "").toNumber();
        if (idx == null) {
            _arrayIndex = -1;
        } else {
            _arrayIndex = idx;
        }

        // Handle menuitem preset selection
        if (
            id instanceof String &&
            (id.equals("preset_casual") ||
                id.equals("preset_endurance") ||
                id.equals("preset_short_fast") ||
                id.equals("preset_weight_loss") ||
                id.equals("preset_cardio") ||
                id.equals("preset_recovery"))
        ) {
            var summary = $.getPresetSummary(id as String);
            menuItem.setSubLabel(summary);
            var label = menuItem.getLabel();
            if (label.find(" - ") == null) {
                menuItem.setLabel(label + " - click to apply");
            } else {
                // remove " - " and everything after it
                var cleanLabel = stringLeft(label, " - ", label);
                if ($.applyPreset(id as String)) {
                    menuItem.setLabel(cleanLabel + " - applied!");
                    // clear other presets' sublabels
                    for (var i = 0; i < _maxMenuItemIdx; i++) {
                        var otherItem = _parentMenu.getItem(i);
                        var otherId = otherItem.getId();
                        if (
                            otherItem != menuItem &&
                            (otherId.equals("preset_casual") ||
                                otherId.equals("preset_endurance") ||
                                otherId.equals("preset_short_fast") ||
                                otherId.equals("preset_weight_loss") ||
                                otherId.equals("preset_cardio") ||
                                otherId.equals("preset_recovery"))
                        ) {
                            label = otherItem.getLabel();
                            if (label.find(" - ") != null) {
                                // remove " - " and everything after it
                                otherItem.setLabel(
                                    stringLeft(label, " - ", label)
                                );
                            }
                        }
                    }
                }
            }
            return;
        }

        // if (id instanceof String && _item instanceof ToggleMenuItem) {
        //     $.setStorageValueOrArray(id, _item.isEnabled());
        //     return;
        // }

        // Numeric input
        var prompt = _item.getLabel();
        // System.println(["Numeric input:", prompt]);
        var value = $.getStorageValue(id as String, 0) as Numeric;
        var view = $.getNumericInputView(prompt, value);
        view.setOnAccept(self, :onAcceptNumericinput);
        view.setOnKeypressed(self, :onNumericinput);

        Toybox.WatchUi.pushView(
            view,
            new $.NumericInputDelegate(view),
            WatchUi.SLIDE_RIGHT
        );
    }

    function onAcceptNumericinput(
        value as Numeric,
        subLabel as String
    ) as Void {
        try {
            if (_item != null) {
                // Note contains `storageKey|index` or `storageKey`
                var key = _item.getId() as String;
                $.setStorageValueOrArray(key, value);
                (_item as MenuItem).setSubLabel(subLabel);

                // if preset_distance set then clear preset_duration
                var clearSubLabel = "";
                if (key.equals("preset_distance")) {
                    $.setStorageValueOrArray("preset_duration", 0);
                    clearSubLabel = "preset_duration";
                } else if (key.equals("preset_duration")) {
                    $.setStorageValueOrArray("preset_distance", 0);
                    clearSubLabel = "preset_distance";
                }
                if (clearSubLabel != "") {
                    for (var i = 0; i < _maxMenuItemIdx; i++) {
                        var otherItem = _parentMenu.getItem(i);
                        var otherId = otherItem.getId();
                        if (otherId.equals(clearSubLabel)) {
                            otherItem.setSubLabel("0");
                        }
                    }
                }
            }
        } catch (ex) {
            ex.printStackTrace();
        }
    }

    function onNumericinput(
        editData as Array<Char>,
        cursorPos as Number,
        insert as Boolean,
        negative as Boolean,
        opt as NumericOptions
    ) as Void {
        // Hack to refresh screen
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var view = new $.NumericInputView("", 0);
        view.processOptions(opt);
        view.setEditData(editData, cursorPos, insert, negative);
        view.setOnAccept(self, :onAcceptNumericinput);
        view.setOnKeypressed(self, :onNumericinput);

        Toybox.WatchUi.pushView(
            view,
            new $.NumericInputDelegate(view),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    //! Handle the back key being pressed

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    //! Handle the done item being selected

    function onDone() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
