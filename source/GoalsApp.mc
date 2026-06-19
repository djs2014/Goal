import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class GoalsApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {}

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {}

    //! Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        loadUserSettings();
        return [new GoalsView()];
    }

    //! Return the settings view and delegate for the app
    //! @return Array Pair [View, Delegate]
    function getSettingsView() as
        [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] or Null
    {
        return [
            new $.DataFieldSettingsView(),
            new $.DataFieldSettingsDelegate(),
        ];
    }

    function onSettingsChanged() {
        loadUserSettings();
    }

    function loadUserSettings() as Void {
        try {
            $.logInfo("Loading user settings");

            var reset = Storage.getValue("resetDefaults");
            if (reset == null || (reset as Boolean)) {
                Storage.setValue("resetDefaults", false);
                // Storage.setValue("show_labels", false);
                Storage.setValue("demo", false);
                Storage.setValue("cadence_counter", 3);

                Storage.setValue(
                    "show_one_field",
                    [
                        FLHorizontal, // layout
                        true, // show labels
                        true, // show values
                        4, // gap
                        80, // divider at
                        FTDistance,
                        FTMinutesElapsed,
                        FTCalories,
                        FTTrainingStressScore,
                        FTAverageSpeed,
                        FTAverageCadence,
                        FTAveragePower,
                        FTAverageHeartRateZone,
                        FTNormalizedPower,
                        FTIntensityFactor,

                    ] as Array<Numeric or FieldLayout or Boolean>
                );
                Storage.setValue(
                    "show_large_field",
                    [
                        FLVertical, // layout
                        false, // show labels
                        false, // show values
                        8, // gap
                        80, // divider at
                        FTDistance,
                        FTMinutesElapsed,
                        FTCalories,
                        FTTrainingStressScore,
                        FTSpeed,
                        FTCadence,
                        FTPower,
                        FTHeartRateZone,
                    ] as Array<Numeric or FieldLayout or Boolean>
                );
                Storage.setValue(
                    "show_wide_field",
                    [
                        FLVertical, // layout
                        true, // show labels
                        false, // show values
                        8, // gap
                        80, // divider at
                        FTDistance,
                        FTMinutesElapsed,
                        FTCalories,
                        FTTrainingStressScore,
                        FTSpeed,
                        FTCadence,
                        FTPower,
                        FTHeartRateZone,
                    ] as Array<Numeric or FieldLayout or Boolean>
                );
                Storage.setValue(
                    "show_small_field",
                    [
                        FLVertical, // layout
                        false, // show labels
                        false, // show values
                        1, // gap
                        80, // divider at
                        FTDistance,
                        FTMinutesElapsed,
                        FTCalories,
                        FTTrainingStressScore,
                        FTSpeed,
                        FTCadence,
                        FTPower,
                        FTHeartRateZone,
                    ] as Array<Numeric or FieldLayout or Boolean>
                );

                // Init for casual scenario 80km
                Storage.setValue("preset_distance", 80); // km
                Storage.setValue("preset_duration", 0); // minutes
                Storage.setValue("preset_suffer_factor", 1.0); // calories
                $.applyPreset("preset_casual"); 

                // Storage.setValue("target_distance", 150); // km
                // Storage.setValue("target_minutes_elapsed", 300); // minutes
                // Storage.setValue("target_calories", 2000); // calories
                // Storage.setValue("target_training_stress_score", 150); // TSS
                // Storage.setValue("target_average_power", 200); // watts
                // Storage.setValue("target_average_speed", 28); // km/h
                // Storage.setValue("target_average_cadence", 90); // rpm
                // Storage.setValue("target_average_heart_rate_zone", 2); // zone
                // Storage.setValue("target_normalized_power", 230); // watts
                // Storage.setValue("target_intensity_factor", 0.9); // IF
                // Storage.setValue("target_power", 0); // watts
                // Storage.setValue("target_speed", 30); // km/h
                // Storage.setValue("target_cadence", 90); // rpm
                // Storage.setValue("target_heart_rate_zone", 2.0f); // zone
                // Storage.setValue("target_total_ascent", 500); // meters
                // Storage.setValue("target_total_descent", 500); // meters
                
                Storage.setValue("alert_calories_window", 700); // calories loop
                Storage.setValue("alert_calories_sound", false); // sound
                Storage.setValue("alert_timeelapsed_window", 0); // minutes
                Storage.setValue("alert_timeelapsed_sound", false); // sound
                Storage.setValue("alert_displaytime_sec", 10); // seconds
            }

            // $.gDebug = $.getStorageValue("debug", $.gDebug) as Boolean;

            var show_OneField =
                $.getStorageValue("show_one_field", [$.gShowFieldsArraySize]) as
                Array<Numeric or Boolean or FieldLayout>;
            var show_LargeField =
                $.getStorageValue("show_large_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or Boolean or FieldLayout>;
            var show_WideField =
                $.getStorageValue("show_wide_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or Boolean or FieldLayout>;
            var show_SmallField =
                $.getStorageValue("show_small_field", [
                    $.gShowFieldsArraySize,
                ]) as Array<Numeric or Boolean or FieldLayout>;

            if ($.ensureArraySize(show_OneField, $.gShowFieldsArraySize, 0)) {
                $.setStorageValueOrArray("show_one_field", show_OneField);
            }
            if ($.ensureArraySize(show_LargeField, $.gShowFieldsArraySize, 0)) {
                $.setStorageValueOrArray("show_large_field", show_LargeField);
            }
            if ($.ensureArraySize(show_WideField, $.gShowFieldsArraySize, 0)) {
                $.setStorageValueOrArray("show_wide_field", show_WideField);
            }
            if ($.ensureArraySize(show_SmallField, $.gShowFieldsArraySize, 0)) {
                $.setStorageValueOrArray("show_small_field", show_SmallField);
            }

            $.gDemo = $.getStorageValue("demo", false) as Boolean;
            $.logInfo(["Demo mode:", $.gDemo]);
            if ($.gDemo) {
                Storage.setValue("demo", false);
            }

            $.gCadenceCounter =
                $.getStorageValue("cadence_counter", $.gCadenceCounter) as
                Number;

            $.gTargetDistance =
                $.getStorageValue("target_distance", $.gTargetDistance) as
                Number;
            $.gTargetCalories =
                $.getStorageValue("target_calories", $.gTargetCalories) as
                Number;
            $.gTargetPower =
                $.getStorageValue("target_power", $.gTargetPower) as Number;
            if ($.gTargetPower == 0) {
                $.gTargetPower = $.getUserFtp();
            }

            $.gTargetAveragePower =
                $.getStorageValue(
                    "target_average_power",
                    $.gTargetAveragePower
                ) as Number;
            if ($.gTargetAveragePower == 0) {
                $.gTargetAveragePower = $.getUserFtp();
            }

            $.gTargetAverageSpeed =
                $.getStorageValue(
                    "target_average_speed",
                    $.gTargetAverageSpeed
                ) as Number;
            $.gTargetSpeed =
                $.getStorageValue("target_speed", $.gTargetSpeed) as Number;
            $.gTargetAverageCadence =
                $.getStorageValue(
                    "target_average_cadence",
                    $.gTargetAverageCadence
                ) as Number;
            $.gTargetCadence =
                $.getStorageValue("target_cadence", $.gTargetCadence) as Number;
            $.gTargetNormalizedPower =
                $.getStorageValue(
                    "target_normalized_power",
                    $.gTargetNormalizedPower
                ) as Number;
            $.gTargetTotalAscent =
                $.getStorageValue(
                    "target_total_ascent",
                    $.gTargetTotalAscent
                ) as Number;
            $.gTargetTotalDescent =
                $.getStorageValue(
                    "target_total_descent",
                    $.gTargetTotalDescent
                ) as Number;
            $.gTargetMinutesElapsed =
                $.getStorageValue(
                    "target_minutes_elapsed",
                    $.gTargetMinutesElapsed
                ) as Number;
            $.gTargetHeartRateZone =
                $.getStorageValue("target_heart_rate_zone", 2.0f) as Float;
            $.gTargetAverageHeartRateZone =
                $.getStorageValue("target_average_heart_rate_zone", 2.0f) as Float;
            $.gHeartRate.initHrZones();

            $.gTargetIntensityFactor =
                $.getStorageValue(
                    "target_intensity_factor",
                    $.gTargetIntensityFactor
                ) as Float;
            $.gTargetTrainingStressScore =
                $.getStorageValue(
                    "target_training_stress_score",
                    $.gTargetTrainingStressScore
                ) as Number;

            // Alerts
            $.gAlertCaloriesWindow =
                $.getStorageValue("alert_calories_window", 300) as Number;
            $.gAlertCaloriesSound =
                $.getStorageValue("alert_calories_sound", false) as Boolean;
            $.gAlertTimeElapsedWindow =
                $.getStorageValue("alert_timeelapsed_window", 0) as Number;
            $.gAlertTimeElapsedSound =
                $.getStorageValue("alert_timeelapsed_sound", false) as Boolean;
            $.gAlertDisplayTimeMillisec =
                ($.getStorageValue("alert_displaytime_sec", 10) as Number) * 1000;

            $.logInfo(["User settings loaded"]);
        } catch (ex) {
            $.logInfo(ex.getErrorMessage());
            ex.printStackTrace();
        }
    }
}

function getApp() as GoalsApp {
    return Application.getApp() as GoalsApp;
}

var gHeartRate = new HeartRate();

// +5 for the layout and other settings
var gPreambleFieldCount as Number = 5;
var gShowFieldsArraySize as Number =
    $.gPreambleFieldCount + $.gMaxProgressColumns;

var gDemo as Boolean = false;
var gCadenceCounter as Number = 3;

// Target values for progress calculations
var gTargetDistance as Number = 150;
var gTargetMinutesElapsed as Number = 300;
var gTargetCalories as Number = 2000;
var gTargetTrainingStressScore as Number = 150;

var gTargetAveragePower as Number = 200;
var gTargetAverageSpeed as Number = 28;
var gTargetAverageCadence as Number = 90;
var gTargetAverageHeartRateZone as Float = 2.0f;
var gTargetNormalizedPower as Number = 230;
var gTargetIntensityFactor as Float = 0.9;

var gTargetPower as Number = 0; // watts, default from user profile ftp if available, otherwise 250 watts
var gTargetSpeed as Number = 30; // km/h
var gTargetCadence as Number = 90;
var gTargetHeartRateZone as Float = 2.0f;

var gTargetTotalAscent as Number = 500;
var gTargetTotalDescent as Number = 500;

// Alerts
var gAlertCaloriesWindow as Number = 300; // calories
var gAlertCaloriesSound as Boolean = false;
var gAlertTimeElapsedWindow as Number = 0; // minutes
var gAlertTimeElapsedSound as Boolean = false;
var gAlertDisplayTimeMillisec as Number = 10; // seconds