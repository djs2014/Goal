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
                Storage.setValue("show_labels", true);
                Storage.setValue("demo", false);

                Storage.setValue(
                    "show_fields",
                    [
                        FLVertical,
                        FTDistance,
                        FTCalories,
                        FTMinutesElapsed,
                        FTTotalAscent,
                        FTAverageSpeed,
                        FTAverageCadence,
                        FTNormalizedPower,
                        FTHeartRateZone,
                    ] as Array<Numeric or FieldLayout>
                );

                Storage.setValue("target_distance", 150); // km
                Storage.setValue("target_calories", 2000); // calories
                Storage.setValue("target_average_heartrate", 120); // bpm
                Storage.setValue("target_average_power", 200); // watts
                Storage.setValue("target_average_speed", 28); // km/h
                Storage.setValue("target_average_cadence", 90); // rpm
                Storage.setValue("target_normalized_power", 220); // watts
                Storage.setValue("target_total_ascent", 300); // meters
                Storage.setValue("target_total_descent", 300); // meters
                Storage.setValue("target_minutes_elapsed", 300); // minutes
                Storage.setValue("target_heart_rate_zone", 3); // zone
            }

            // $.gDebug = $.getStorageValue("debug", $.gDebug) as Boolean;

            var showFields =
                $.getStorageValue("show_fields", [$.gShowFieldsArraySize]) as
                Array<Numeric or FieldLayout>;
            
            if ($.ensureArraySize(showFields, $.gShowFieldsArraySize, 0)) {
                $.setStorageValueOrArray("show_fields", showFields);
            }
            $.gShowLabels = $.getStorageValue("show_labels", $.gShowLabels) as Boolean;
            
            $.gDemo = $.getStorageValue("demo", false) as Boolean;
            $.logInfo(["Demo mode:", $.gDemo]);
            if ($.gDemo) {
                Storage.setValue("demo", false);
            }

            $.gTargetDistance =
                $.getStorageValue("target_distance", $.gTargetDistance) as
                Number;
            $.gTargetCalories =
                $.getStorageValue("target_calories", $.gTargetCalories) as
                Number;
            $.gTargetAverageHeartRate =
                $.getStorageValue(
                    "target_average_heartrate",
                    $.gTargetAverageHeartRate
                ) as Number;
            $.gTargetAveragePower =
                $.getStorageValue(
                    "target_average_power",
                    $.gTargetAveragePower
                ) as Number;
            $.gTargetAverageSpeed =
                $.getStorageValue(
                    "target_average_speed",
                    $.gTargetAverageSpeed
                ) as Number;
            $.gTargetAverageCadence =
                $.getStorageValue(
                    "target_average_cadence",
                    $.gTargetAverageCadence
                ) as Number;
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
                $.getStorageValue(
                    "target_heart_rate_zone",
                    $.gTargetHeartRateZone
                ) as Number;

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

// +1 for the layout option
var gShowFieldsArraySize as Number = $.gMaxProgressColumns + 1;
var gDemo as Boolean = false;
var gShowLabels as Boolean = true;

var gTargetDistance as Number = 150;
var gTargetCalories as Number = 2000;
var gTargetAverageHeartRate as Number = 120;
var gTargetAveragePower as Number = 200;
var gTargetAverageSpeed as Number = 28;
var gTargetAverageCadence as Number = 90;
var gTargetNormalizedPower as Number = 220;
var gTargetTotalAscent as Number = 300;
var gTargetTotalDescent as Number = 300;
var gTargetMinutesElapsed as Number = 300;
var gTargetHeartRateZone as Number = 3;
