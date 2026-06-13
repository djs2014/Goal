import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

public class HeartRate {
    var mHeartRateZones as Array<Number> = [] as Array<Number>;
    var mTargetHeartRateZone as Number = 0;
    var mTargetHeartRate as Number = 0;

    function initialize() {}

    function initHrZones(targetHrZone as Number) {
        mTargetHeartRateZone = targetHrZone;

        mHeartRateZones = UserProfile.getHeartRateZones(
            UserProfile.HR_ZONE_SPORT_BIKING
        );

        // System.println(mHeartRateZones);
        if (mHeartRateZones.size() == 0) {
            return;
        }

        if (targetHrZone > 0 and targetHrZone < mHeartRateZones.size()) {
            mTargetHeartRate =
                (mHeartRateZones[targetHrZone - 1] +
                    mHeartRateZones[targetHrZone]) /
                2;
        } else {
            mTargetHeartRate = mHeartRateZones[mHeartRateZones.size() - 1];
        }
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

    function getMaxHeartRateZone() as Number {
        return mHeartRateZones.size() - 1; // Zone 0 to 5
    }
}
