import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

public class HeartRate {
    var mHeartRateZones as Array<Number> = [] as Array<Number>;
    var mWarmUpHeartRate as Number = 60; // bpm

    function initialize() {
        mIsInWarmUp = false;
    }

    function initHrZones() as Void {
        // Array of heart rate zones for biking, in beats per minute (BPM)
        // [minzone1, maxzone1, maxzone2, maxzone3, maxzone4, maxzone5]
        mHeartRateZones = UserProfile.getHeartRateZones(
            UserProfile.HR_ZONE_SPORT_BIKING
        );
        $.logInfo(["Heart rate zones initialized:", mHeartRateZones]);
    }

    function getHeartRateZone(heartRate as Number) as Number {
        if (mHeartRateZones.size() == 0) {
            return 0;
        }

        if (heartRate < mHeartRateZones[0]) {
            return 0;
        }

        for (var i = 1; i < mHeartRateZones.size(); i++) {
            if (heartRate < mHeartRateZones[i]) {
                return i;
            }
        }

        return mHeartRateZones.size();
    }

    // Returns a smooth float from 0.0 to 1.0+ representing progress *inside* a targeted zone
    function calculateZoneProgress(
        liveHeartRate as Number,
        targetZone as Number
    ) as Float {
        if (mHeartRateZones.size() < 6 || targetZone < 1 || targetZone > 5) {
            return 0.0f;
        }

        // 1. Get the floor and ceiling bounds for this exact targeted zone
        // 6:48:40 - [Heart rate zones initialized:, [128, 153, 179, 204, 230, 255]]
        var zoneFloor = mHeartRateZones[targetZone - 1]; // e.g., if targetZone=2, floor is index 1 (153)
        var zoneCeiling = mHeartRateZones[targetZone]; // e.g., if targetZone=2, ceiling is index 2 (179)
       
        if (mWarmUpHeartRate > 0 && liveHeartRate < mHeartRateZones[0]) {
            // get a "Warmup" bar before the real intervals start
            zoneFloor = mWarmUpHeartRate;
            zoneCeiling = mHeartRateZones[0];            
            mIsInWarmUp = true;
            // System.println("HeartRate: In Warmup Zone! liveHR=" + liveHeartRate + " warmupHR=" + mWarmUpHeartRate + " zoneFloor=" + zoneFloor + " zoneCeiling=" + zoneCeiling);
        } else {
            mIsInWarmUp = false;
            // System.println("HeartRate: In Normal Zone! liveHR=" + liveHeartRate + " zoneFloor=" + zoneFloor + " zoneCeiling=" + zoneCeiling);
        }

        // 2. Handle the edge case if your live HR hasn't even reached the zone yet
        if (liveHeartRate < zoneFloor) {
            return 0.0f;
        }

        // 3. Perform standard linear normalization: (Value - Min) / (Max - Min)
        var range = (zoneCeiling - zoneFloor).toFloat();
        if (range <= 0.0f) {
            return 0.0f;
        }

        var progressInZone = (liveHeartRate - zoneFloor).toFloat() / range;

        return progressInZone; // e.g., if HR is 166 in Zone 2: (166-153)/(179-153) = 13/26 = 0.5f (Perfectly 50% filled!)
    }

    function setWarmUpHeartRate(warmUpHeartRate as Number) as Void {
        mWarmUpHeartRate = warmUpHeartRate;
    }

    hidden var mIsInWarmUp as Boolean = false;
    function getIsInWarmUp() as Boolean {
        return mIsInWarmUp;
    }
}
