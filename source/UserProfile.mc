import Toybox.Application;
import Toybox.Lang;
import Toybox.Activity;
import Toybox.UserProfile;

function getUserFtp() as Number {
    var thresholdPower = UserProfile.getFunctionalThresholdPower(
        Activity.SPORT_CYCLING
    );
    if (thresholdPower == null) {
        return 0;
    }
    return thresholdPower as Number;
}
