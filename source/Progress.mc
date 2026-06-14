import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.UserProfile;

class Progress {
    function initialize() {
        mUserFTP = $.getUserFtp();
    }

    function getProgressForField(
        info as Activity.Info,
        fieldType as FieldType
    ) as Float {
        switch (fieldType) {
            // Distance related fields
            case FTDistance:
            case FTDistanceToDestination:
            case FTDistanceToNext:
            case FTDistanceOrNavDestination:
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
            case FTPower:
                return (
                    ($.getActivityValue(info, :currentPower, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTAveragePower:
                return (
                    ($.getActivityValue(info, :averagePower, 0) as Number) /
                    targetValue.toFloat()
                );
            case FTSpeed:
                return (
                    (($.getActivityValue(info, :currentSpeed, 0) as Float) *
                        3.6) /
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
            case FTCadence:
                return (
                    ($.getActivityValue(info, :currentCadence, 0) as Number) /
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
            case FTIntensityFactor:
                return getIntensityFactor() / targetValue.toFloat();
            case FTTrainingStressScore:
                return (
                    getTrainingStressScore(
                        $.getActivityValue(info, :elapsedTime, 0) as Number
                    ) / targetValue.toFloat()
                );
            default:
                $.logInfo([
                    "getProgressForField Unknown field type:",
                    fieldType,
                ]);
                return 0.0f;
        }
    }

    // Target values based on target heart rate zone, which is set by the user in the settings menu
    // Returns a smooth float from 0.0 to 1.0+ representing progress *inside* a targeted zone
    hidden function getProgressForHeartRate(
        info as Info,
        fieldType as FieldType
    ) as Float {
        switch (fieldType) {
            case FTAverageHeartRateZone:
                return $.gHeartRate.calculateZoneProgress(
                    $.getActivityValue(info, :averageHeartRate, 0) as Number,
                    $.gTargetHeartRateZone
                );
            case FTHeartRateZone:
                return $.gHeartRate.calculateZoneProgress(
                    $.getActivityValue(info, :currentHeartRate, 0) as Number,
                    $.gTargetHeartRateZone
                );
            default:
                $.logInfo([
                    "getProgressForHeartRate Unknown field type:",
                    fieldType,
                ]);
                return 0.0f;
        }
    }

    // Target values for each field type, based on user settings or calculated from active course data (e.g., distance to destination)
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
                targetValue = $.gTargetDistance * 1000.0f; // convert to meters
                break;
            case FTDistanceToDestination:
                return calculateDistanceToDestinationProgress(info);
            case FTDistanceToNext:
                return calculateDistanceToNextProgress(info);
            case FTDistanceOrNavDestination:
                var progressToDestination =
                    calculateDistanceToDestinationProgress(info);
                if (progressToDestination > 0) {
                    return progressToDestination;
                }
                targetValue = $.gTargetDistance * 1000.0f; // convert to meters
                break;
        }

        if (targetValue == 0) {
            return 0.0f;
        }
        return elapsedDistance / targetValue.toFloat();
    }

    // Fixed target values for each field type, based on user settings
    hidden function getTargetValueForField(
        fieldType as FieldType
    ) as Number or Float {
        switch (fieldType) {
            case FTUnknown:
                return 0;
            case FTDistance:
                return $.gTargetDistance;
            case FTCalories:
                return $.gTargetCalories;
            case FTPower:
                return $.gTargetPower;
            case FTAveragePower:
                return $.gTargetAveragePower;
            case FTSpeed:
                return $.gTargetSpeed;
            case FTAverageSpeed:
                return $.gTargetAverageSpeed;
            case FTAverageCadence:
                return $.gTargetAverageCadence;
            case FTCadence:
                return $.gTargetCadence;
            case FTNormalizedPower:
                return $.gTargetNormalizedPower;
            case FTTotalAscent:
                return $.gTargetTotalAscent;
            case FTTotalDescent:
                return $.gTargetTotalDescent;
            case FTMinutesElapsed:
                return $.gTargetMinutesElapsed;
            case FTIntensityFactor:
                return $.gTargetIntensityFactor;
            case FTTrainingStressScore:
                return $.gTargetTrainingStressScore;
            default:
                $.logInfo([
                    "getTargetValueForField Unknown field type:",
                    fieldType,
                ]);
                return 0;
        }
    }

    hidden var mNormalizedPower as Number = 0;
    function setNormalizedPower(np as Number) as Void {
        mNormalizedPower = np;
    }

    hidden var mUserFTP as Number = 0;
    function setFTP(ftp as Number) as Void {
        mUserFTP = ftp;
    }

    function getIntensityFactor() as Float {
        if (mUserFTP == 0) {
            return 0.0f;
        }
        return mNormalizedPower / mUserFTP.toFloat();
    }

    // return $.getActivityValue(a_info, :timerTime, 0) as Number;
    function getTrainingStressScore(timerTime as Number) as Float {
        if (mUserFTP == 0) {
            return 0.0f;
        }
        // TSS = (sec × NP × IF) / (FTP × 3600) × 100
        var seconds = timerTime / 1000.0;
        var fraction = mUserFTP.toFloat() * 3600.0f;
        if (fraction == 0) {
            return 0.0f;
        }

        return (
            ((seconds * mNormalizedPower * getIntensityFactor()) / fraction) *
            100.0f
        );
    }

    private var mMaxDistanceToDestination = 0.0f;
    function calculateDistanceToDestinationProgress(
        info as Activity.Info
    ) as Float {
        var currentDistance =
            $.getActivityValue(info, :distanceToDestination, 0.0f) as Float;
        if (currentDistance == null || currentDistance == 0.0f) {
            mMaxDistanceToDestination = 0.0f; // Reset if data is lost
            return 0.0f;
        }

        // 1. Detect if we just passed a waypoint or if distance suddenly jumped up
        if (currentDistance > mMaxDistanceToDestination) {
            mMaxDistanceToDestination = currentDistance; // This is our new 100% starting line
        }

        // 2. Prevent division by zero
        if (mMaxDistanceToDestination <= 0.0f) {
            return 0.0f;
        }

        // 3. Inverse Progress Formula: As currentDistance shrinks, progress grows!
        var progress =
            (mMaxDistanceToDestination - currentDistance) /
            mMaxDistanceToDestination;

        // Safety clamp between 0.0 and 1.0
        if (progress < 0.0f) {
            progress = 0.0f;
        }
        if (progress > 1.0f) {
            progress = 1.0f;
        }

        return progress;
    }
    private var mMaxDistanceToNext = 0.0f;
    function calculateDistanceToNextProgress(info as Activity.Info) as Float {
        var currentDistance =
            $.getActivityValue(info, :distanceToNextPoint, 0.0f) as Float;
        if (currentDistance == null || currentDistance == 0.0f) {
            mMaxDistanceToNext = 0.0f; // Reset if data is lost
            return 0.0f;
        }

        // 1. Detect if we just passed a waypoint or if distance suddenly jumped up
        if (currentDistance > mMaxDistanceToNext) {
            mMaxDistanceToNext = currentDistance; // This is our new 100% starting line
        }

        // 2. Prevent division by zero
        if (mMaxDistanceToNext <= 0.0f) {
            return 0.0f;
        }

        // 3. Inverse Progress Formula: As currentDistance shrinks, progress grows!
        var progress =
            (mMaxDistanceToNext - currentDistance) / mMaxDistanceToNext;

        // Safety clamp between 0.0 and 1.0
        if (progress < 0.0f) {
            progress = 0.0f;
        }
        if (progress > 1.0f) {
            progress = 1.0f;
        }

        return progress;
    }

    function getValueForField(
        info as Activity.Info,
        fieldType as FieldType
    ) as Float or Number {
        switch (fieldType) {
            case FTDistance:
                return (
                    (
                        $.getActivityValue(info, :elapsedDistance, 0.0f) as
                            Float
                    ) / 1000.0f
                ); // convert to km
            case FTDistanceToDestination:
                return (
                    (
                        $.getActivityValue(
                            info,
                            :distanceToDestination,
                            0.0f
                        ) as Float
                    ) / 1000.0f
                ); // convert to km
            case FTDistanceToNext:
                return (
                    (
                        $.getActivityValue(info, :distanceToNextPoint, 0.0f) as
                            Float
                    ) / 1000.0f
                ); // convert to km
            case FTDistanceOrNavDestination:
                var distToDest =
                    (
                        $.getActivityValue(
                            info,
                            :distanceToDestination,
                            0.0f
                        ) as Float
                    ) / 1000.0f; // convert to km
                if (distToDest > 0.0f) {
                    return distToDest;
                } else {
                    return (
                        (
                            $.getActivityValue(info, :elapsedDistance, 0.0f) as
                                Float
                        ) / 1000.0f
                    ); // convert to km
                }
            case FTCalories:
                return $.getActivityValue(info, :calories, 0) as Number;
            case FTAverageHeartRateZone:
                return $.gHeartRate.getHeartRateZone(
                    $.getActivityValue(info, :averageHeartRate, 0) as Number
                );
            case FTHeartRateZone:
                return $.gHeartRate.getHeartRateZone(
                    $.getActivityValue(info, :currentHeartRate, 0) as Number
                );
            case FTPower:
                return $.getActivityValue(info, :currentPower, 0) as Number;
            case FTAveragePower:
                return $.getActivityValue(info, :averagePower, 0) as Number;
            case FTSpeed:
                return $.getActivityValue(info, :currentSpeed, 0) as Float;
            case FTAverageSpeed:
                return $.getActivityValue(info, :averageSpeed, 0) as Float;
            case FTAverageCadence:
                return $.getActivityValue(info, :averageCadence, 0) as Number;
            case FTCadence:
                return $.getActivityValue(info, :currentCadence, 0) as Number;
            case FTNormalizedPower:
                return mNormalizedPower;
            case FTTotalAscent:
                return $.getActivityValue(info, :totalAscent, 0) as Number;
            case FTTotalDescent:
                return $.getActivityValue(info, :totalDescent, 0) as Number;
            case FTMinutesElapsed:
                return (
                    ($.getActivityValue(info, :elapsedTime, 0) as Number) /
                    60000.0
                ); // convert milliseconds to minutes
            case FTIntensityFactor:
                return getIntensityFactor();
            case FTTrainingStressScore:
                return getTrainingStressScore(
                    $.getActivityValue(info, :elapsedTime, 0) as Number
                );
            default:
                return 0.0f;
        }
    }
}
