import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class Progress {
    function initialize() {}

    function getProgressForField(
        info as Activity.Info,
        fieldType as FieldType
    ) as Float {
        switch (fieldType) {
            // Distance related fields
            case FTDistance:
            case FTDistanceToDestination:
            case FTDistanceToNext:
            case FTDistanceOrToDestination:
                return getProgressForDistance(info, fieldType);
            // heart rate related fields
            case FTAverageHeartRateZone:
            case FTHeartRateZone:
                return getProgressForHeartRate(info, fieldType);
        }

        // Other fields
        var targetValue = getTargetValueForField(fieldType);
        if (targetValue == 0) {
            return 0.0f;
        }

        switch (fieldType) {
            case FTUnknown:
                return 0.0f;           
            case FTCalories:
                return (
                    ($.getActivityValue(info, :calories, 0) as Number) /
                    targetValue.toFloat()
                );          
            case FTAveragePower:
                return (
                    ($.getActivityValue(info, :averagePower, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTAverageSpeed:
                // convert meters/second to km/h by multiplying by 3.6
                return (
                    (($.getActivityValue(info, :averageSpeed, 0) as Float) *
                        3.6) /
                    targetValue.toFloat()
                );
            case FTAverageCadence:
                return (
                    ($.getActivityValue(info, :averageCadence, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTNormalizedPower:
                return mNormalizedPower / targetValue.toFloat();
            case FTTotalAscent:
                return (
                    ($.getActivityValue(info, :totalAscent, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTTotalDescent:
                return (
                    ($.getActivityValue(info, :totalDescent, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTMinutesElapsed:
                // convert milliseconds to minutes
                return (
                    ($.getActivityValue(info, :elapsedTime, 0) as Number) /
                    60000.0 /
                    targetValue.toFloat()
                );            
            default:
                $.logInfo(["Unknown field type:", fieldType]);
                return 0.0f;
        }
    }

 
    hidden function getProgressForHeartRate( info as Info,
        fieldType as FieldType
    ) as Float {
        var targetValue = getTargetValueForField(fieldType);
        if (targetValue == 0) {
            return 0.0f;
        }
        
        var heartRate = new HeartRate();
        heartRate.initHrZones(3);
        var currentHeartRate = $.getActivityValue(info, :currentHeartRate, 0) as Number;
        var maxHeartRate = heartRate.mTargetHeartRate;
        var zone = heartRate.getHeartRateZone(currentHeartRate);
        System.println("Current HR: " + currentHeartRate + ", Max HR: " + maxHeartRate + ", Zone: " + zone);

        switch (fieldType) {
            case FTAverageHeartRateZone:
                return (
                    ($.getActivityValue(info, :averageHeartRate, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTHeartRateZone:
                return (
                    ($.getActivityValue(info, :currentHeartRate, 0) as Number) /
                    targetValue.toFloat()
                );
            default:
                $.logInfo(["Unknown field type:", fieldType]);
                return 0.0f;
        }
    }

    hidden function getProgressForDistance(
        info as Info,
        fieldType as FieldType
    ) as Float {
        var targetValue = 0.0f;
        var elapsedDistance =
            $.getActivityValue(info, :elapsedDistance, 0.0f) as Float; // in meters

        switch (fieldType) {
            case FTDistance:
                // Target is in kilometers, but Connect IQ distance is in meters
                targetValue =
                    getTargetValueForField(FTDistanceOrToDestination) * 1000.0f; // convert to meters
                elapsedDistance =
                    $.getActivityValue(info, :elapsedDistance, 0.0f) as Float;
                break;
            case FTDistanceToDestination:
                targetValue =
                    $.getActivityValue(info, :distanceToDestination, 0.0f) as
                    Float; // in meters
                break;
            case FTDistanceToNext:
                targetValue =
                    $.getActivityValue(info, :distanceToNextPoint, 0.0f) as
                    Float; // in meters
                break;
            case FTDistanceOrToDestination:
                targetValue =
                    $.getActivityValue(info, :distanceToDestination, 0.0f) as
                    Float;
                if (targetValue == 0) {
                    targetValue =
                        getTargetValueForField(FTDistanceOrToDestination) *
                        1000.0f; // convert to meters
                }
                break;
        }

        if (targetValue == 0) {
            return 0.0f;
        }
        return elapsedDistance / targetValue.toFloat();
    }

    hidden function getTargetValueForField(fieldType as FieldType) as Number {
        switch (fieldType) {
            case FTUnknown:
                return 0;
            case FTDistance:
                return $.gTargetDistance;
            case FTCalories:
                return $.gTargetCalories;
            case FTAveragePower:
                return $.gTargetAveragePower;
            case FTAverageSpeed:
                return $.gTargetAverageSpeed;
            case FTAverageCadence:
                return $.gTargetAverageCadence;
            case FTNormalizedPower:
                return $.gTargetNormalizedPower;
            case FTTotalAscent:
                return $.gTargetTotalAscent;
            case FTTotalDescent:
                return $.gTargetTotalDescent;
            case FTMinutesElapsed:
                return $.gTargetMinutesElapsed;
            case FTAverageHeartRateZone:
            case FTHeartRateZone:
                // Target based on max heart rate for the selected zone
                return $.gTargetAverageHeartRate;
            default:
                $.logInfo(["Unknown field type:", fieldType]);
                return 0;
        }
    }

    hidden var mNormalizedPower as Number = 0;
    function setNormalizedPower(np as Number) as Void {
        mNormalizedPower = np;
    }

}
