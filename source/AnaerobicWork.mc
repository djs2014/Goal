import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;

// Anaerobic Work Capacity (W') Model
// Also with Aerobic depletion and recovery, but simplified.
// A typical cyclist burns roughly $600\text{--}900\text{ kJ}$ per hour.
// After the first $1,000\text{ kJ}$ (when easy-access muscle glycogen begins running lower),
//we can scale down the maximum available capacity by about $10\%$ to $15\%$ per $1,000\text{ kJ}$.
class AnaerobicWork {
    // W' represents a rider's Anaerobic Work Capacity = MAX_W_PRIME
    // Trained Amateur: $\sim 15,000 \text{ J}$ ($15 \text{ kJ}$)
    // Punchy / Sprinter / Elite: Up to $25,000\text{--}30,000 \text{ J}$ ($25\text{--}30 \text{ kJ}$)
    private var USER_CONFIGURED_MAX_W as Float = 15000.0f; // in Joules
    private var MAX_W_PRIME_CALIBRATED as Float = USER_CONFIGURED_MAX_W; // in Joules (with fatigue adjustments)
    private var MAX_W_PRIME as Float = 15000.0f; // in Joules (with fatigue adjustments and long-ride decay)

    private var wPrimeRemaining as Float = MAX_W_PRIME; // in Joules

    function initialize() {
        // Calculate Exponential Recovery Base for Skiba Model
        // Precompute (1.0 - e^(-1/TAU)) to eliminate runtime Math.pow calls
        calculateExpRecoveryBase(0.0f);
    }

    private var _userFTP as Number = 250;
    function setUserFtp(ftp as Number) as Void {
        if (ftp > 0) {
            _userFTP = ftp;
        }
    }

    private var USER_MAX_HR as Number = 0; // TODO
    function setUserMaxHeartRate(maxHR as Number) as Void {
        if (maxHR > 0) {
            USER_MAX_HR = maxHR;
        }
    }

    hidden var staminaRatio as Float = 1.0f; // Ratio of remaining W' to MAX_W_PRIME

    // Constants for Skiba W' Recovery Model
    private var TAU = 300.0f; // Recovery time in seconds (300s = 5 mins for moderate recovery)
    private var EXP_RECOVERY_BASE = 0.0033277f;
    private function calculateExpRecoveryBase(lagPenalty as Float) as Void {
        if (TAU <= 0) {
            TAU = 300.0f; // Default to 5 minutes if invalid
        }
        if (mFatigueFactor <= 0.0f) {
            mFatigueFactor = 1.0f; // Default to no fatigue if invalid
        }
        var calibratedTAU = (300.0f / mFatigueFactor).toFloat(); // Adjust recovery time based on fatigue factor
        if (lagPenalty > 0.0f) {
            calibratedTAU = calibratedTAU * lagPenalty; // Apply cardiovascular lag penalty if provided
        }

        var exponentValue = -1.0f / calibratedTAU;
        EXP_RECOVERY_BASE = 1.0f - Math.pow(Math.E, exponentValue);
    }

    function updateWPrime(info as Activity.Info) as Void {
        updateLongRideStamina(info);
        checkFreshnessSignal(info, _userFTP.toFloat(), USER_MAX_HR);

        var currentPower =
            info.currentPower != null ? info.currentPower.toFloat() : 0.0f;
        var currentHR =
            info.currentHeartRate != null
                ? info.currentHeartRate.toFloat()
                : 0.0f;

        var deltaP = currentPower - _userFTP;

        if (deltaP > 0) {
            // --- DEPLETION (Linear) ---
            // Burning energy above FTP (1 Watt-second = 1 Joule)
            wPrimeRemaining -= deltaP;
        } else {
            // --- RECOVERY (Exponential) ---
            // Riding below FTP: Recovery speed scales with how low your power is relative to FTP.
            // Riding at 50% FTP recharges MUCH faster than riding at 95% FTP.

            // Check if the heart rate is lagging near the user's maximum limits
            // e.g., if HR is still higher than 85% of Max HR despite riding easy
            if (currentHR > 0 && USER_MAX_HR > 0) {
                var hrIntensity = currentHR / USER_MAX_HR.toFloat();

                if (hrIntensity > 0.85f) {
                    // Cardiovascular lag detected. Slow down recovery speed (increase Tau)
                    // At 90% Max HR, Tau becomes 300 * 1.30 = 390 seconds.
                    var lagPenalty = 1.0f + (hrIntensity - 0.85f) * 2.0f;
                    calculateExpRecoveryBase(lagPenalty);
                }
            }

            // Skiba exponential recovery increment per second:
            // Replace Math.exp(x) with Math.pow(Math.E, x)
            var recoveryFactor = (_userFTP - currentPower) / _userFTP.toFloat();
            var recoveryJoules =
                (MAX_W_PRIME - wPrimeRemaining) *
                EXP_RECOVERY_BASE *
                recoveryFactor;

            wPrimeRemaining += recoveryJoules;
        }

        // Bound limits [0.0, MAX_W_PRIME]
        if (wPrimeRemaining > MAX_W_PRIME) {
            wPrimeRemaining = MAX_W_PRIME;
        }
        if (wPrimeRemaining < 0.0f) {
            wPrimeRemaining = 0.0f;
        }

        staminaRatio = wPrimeRemaining / MAX_W_PRIME.toFloat();
        // System.println([
        //     "AnaerobicWork.updateWPrime",
        //     "Stamina Ratio",
        //     staminaRatio
        // ]);
    }

    // Aerobic decay model for long rides: After the first 1000kJ, we start to lose aerobic capacity.
    // Hour 1 ($0\text{--}700\text{ kJ}$): The rider stays entirely below FTP. The bar stays solidly locked at $100\%$ Green. They feel fresh.
    // Hour 3 ($\sim 2000\text{ kJ}$): Even though they never went over FTP, the aerobic decay drops their capacity factor down to $\sim88\%$. The progress bar now shows $88\%$ Yellow, perfectly visualizing that "heavy leg" endurance fatigue.
    // Hour 5 ($\sim 3500\text{ kJ}$): The capacity ceiling has dropped to $\sim70\%$. If they try to launch a hard acceleration now, their $W'$ battery starts draining from a max capacity of $70\%$ instead of $100\%$, and they will hit the red zone much faster.
    function updateLongRideStamina(info as Activity.Info) as Void {
        // mTotalJoules accumulates info.currentPower every second
        var totalJoules = $.gPowerPerSec.getTotalJoules();
        // 1. Calculate total work done in Kilojoules (Joules / 1000)
        var totalKJ = totalJoules / 1000.0f;

        // 2. Calculate Aerobic Decay Factor
        var aerobicDecay = 1.0f;
        if (totalKJ > 1000.0f) {
            // Lose roughly 12% of maximum capacity per 1000kJ past the first 1000kJ
            aerobicDecay = 1.0f - 0.12f * ((totalKJ - 1000.0f) / 1000.0f);

            // Clamp the decay so stamina capacity never drops below 25% purely from duration
            if (aerobicDecay < 0.25f) {
                aerobicDecay = 0.25f;
            }
        }

        // 3. Dynamic Ceilings
        // Scale today's calibrated maximum by the long-ride aerobic decay
        var currentMaxCapacity = MAX_W_PRIME_CALIBRATED * aerobicDecay;
        // Update the global MAX_W_PRIME to reflect the decayed ceiling
        MAX_W_PRIME = currentMaxCapacity;
    }

    // Joules
    function getWPrimeRemaining() as Float {
        return wPrimeRemaining;
    }

    // 0.0 - 1.0
    function getStaminaRatio() as Float {
        return staminaRatio;
    }

    function getFatigueRatio() as Float {
        return 1.0f - staminaRatio;
    }

    function resetWPrime() as Void {
        wPrimeRemaining = MAX_W_PRIME;
        staminaRatio = 1.0f;
        mSecondsAboveFTP = 0;
        mHasAppliedFatiguePenalty = false;
    }

    function setMaxWPrime(maxWPrime as Float) as Void {
        if (maxWPrime <= 0.0f) {
            maxWPrime = 15000.0f; // Default W' if not available
        }
        USER_CONFIGURED_MAX_W = maxWPrime;
        MAX_W_PRIME = maxWPrime;
        MAX_W_PRIME_CALIBRATED = maxWPrime;
    }
    function getuserMaxWPrime() as Float {
        return USER_CONFIGURED_MAX_W;
    }

    hidden var mFatigueFactor as Float = 1.0f; // 1.0 = no fatigue, <1.0 = fatigued

    function applyFatiguePenalty(fatigueFactor as Float) as Void {
        if (fatigueFactor <= 0.0f) {
            return;
        }
        mFatigueFactor = fatigueFactor;

        // // Adjust W' Max and slow down recovery speed (Tau)
        MAX_W_PRIME_CALIBRATED = USER_CONFIGURED_MAX_W * fatigueFactor;
        MAX_W_PRIME = MAX_W_PRIME_CALIBRATED;
        calculateExpRecoveryBase(0.0f); // Recalculate EXP_RECOVERY_BASE based on new TAU

        // Recalculate remaining W' dynamically
        if (wPrimeRemaining > MAX_W_PRIME) {
            wPrimeRemaining = MAX_W_PRIME;
        }
    }

    // (Normal/Fresh): Power is at $120\%$ FTP. At second 10, HR is low (lag). At second 60, HR has climbed comfortably into Zone 4 or Zone 5. $\rightarrow$ System Status: Healthy.
    // (Deeply Fatigued): Power is at $120\%$ FTP. At second 10, HR is low. At second 60, HR is still trapped in Zone 2 or low Zone 3. The rider is pushing hard, but their central nervous system is too tired to drive the heart rate up. $\rightarrow$ System Status: Under-recovered.
    private var mSecondsAboveFTP = 0;
    private var mHasAppliedFatiguePenalty = false;

    function checkFreshnessSignal(
        info as Activity.Info,
        userFTP as Float,
        maxHR as Number
    ) as Void {
        if (
            info.currentPower == null ||
            info.currentHeartRate == null ||
            maxHR == 0
        ) {
            return;
        }

        var currentPower = info.currentPower.toFloat();
        var currentHR = info.currentHeartRate.toFloat();

        // 1. Is the rider pushing significantly above FTP?
        if (currentPower > userFTP * 1.15f) {
            mSecondsAboveFTP++; // Increment our lag-window timer
        } else {
            mSecondsAboveFTP = 0; // Reset if they back off
        }

        // 2. Evaluate ONLY after the 60-second lag window has passed
        if (mSecondsAboveFTP >= 60 && !mHasAppliedFatiguePenalty) {
            // Calculate their current HR intensity relative to Max HR
            var hrIntensity = currentHR / maxHR.toFloat();

            // If they have been smashing it for a full minute, but HR is still below 75% of Max HR
            if (hrIntensity < 0.75f) {
                mHasAppliedFatiguePenalty = true;

                // Trigger an immediate 15% reduction in available W' capacity
                applyInRideFatiguePenalty(0.85f);
            }
        }
    }

    private function applyInRideFatiguePenalty(factor as Float) as Void {
        MAX_W_PRIME = MAX_W_PRIME * factor;
        if (wPrimeRemaining > MAX_W_PRIME) {
            wPrimeRemaining = MAX_W_PRIME;
        }
        // System updates the bottom progress bar to reflect the smaller tank size
    }
}
