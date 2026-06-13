import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class NormPowerEngine {
    // Normalized power
    hidden var mPowerDataPer30Sec as Array<Number> = [] as Array<Number>;
    hidden var mGlobalNP as Number = 0;

    // Low-memory running registers for global NP
    hidden var mSumPowerToFourth as Double = 0.0d;
    hidden var mTotalNPSamples as Long = 0l;

    function initialize() {}

    // Call 1 time per second
    function compute(power as Number) as Number {
        var power30 = calculatePower30(power);
        mGlobalNP = calculateNormalizedPower(power30);
        //$.logInfo("Power: " + power + " 30s Avg: " + power30 + " NP: " + mGlobalNP);
        return mGlobalNP;
    }

    hidden function calculatePower30(power as Number) as Number {
        if (mPowerDataPer30Sec.size() >= 30) {
            mPowerDataPer30Sec = mPowerDataPer30Sec.slice(1, 30);
        }
        mPowerDataPer30Sec.add(power);

        if (mPowerDataPer30Sec.size() == 0) {
            return 0;
        }
        return Math.mean(mPowerDataPer30Sec as Array<Numeric>).toNumber();
    }

    hidden function calculateNormalizedPower(PowerPer30 as Number) as Number {
        // Only start accumulating data once our initial 30-second buffer fills up
        if (mPowerDataPer30Sec.size() < 30) {
            return 0;
        }

        // Add the current 30s rolling average (raised to the 4th power) to our lifetime total
        mSumPowerToFourth += Math.pow(PowerPer30, 4);
        mTotalNPSamples++; // Track total seconds spent calculating NP

        // Calculate the mean over the ENTIRE ride duration
        var globalAvg = mSumPowerToFourth / mTotalNPSamples;

        // Return the 4th root
        return Math.pow(globalAvg, 0.25).toNumber();
    }
}
