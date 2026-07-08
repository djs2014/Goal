import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.UserProfile;

class AnaerobicWork {
    private var _userFtp as Number = 250;

    // W' represents a rider's Anaerobic Work Capacity = MAX_W_PRIME
    // Trained Amateur: $\sim 15,000 \text{ J}$ ($15 \text{ kJ}$)
    // Punchy / Sprinter / Elite: Up to $25,000\text{--}30,000 \text{ J}$ ($25\text{--}30 \text{ kJ}$)
    private var MAX_W_PRIME as Float = 15000.0f; // in Joules
    private var wPrimeRemaining as Float = MAX_W_PRIME; // in Joules

    function initialize() {
        var userFtp = UserProfile.getFunctionalThresholdPower(
            Activity.SPORT_CYCLING
        );
        if (userFtp != null) {
            _userFtp = userFtp as Number;
        }
        if (_userFtp <= 0) {
            _userFtp = 250; // Default FTP if not available
        }

        // Calculate Exponential Recovery Base for Skiba Model
        // Precompute (1.0 - e^(-1/TAU)) to eliminate runtime Math.pow calls
        var exponentValue = -1.0f / TAU;
        EXP_RECOVERY_BASE = 1.0f - Math.pow(Math.E, exponentValue);
    }

    hidden var staminaRatio as Float = 1.0f; // Ratio of remaining W' to MAX_W_PRIME

    // Constants for Skiba W' Recovery Model
    private const TAU = 300.0f; // Recovery time constant in seconds (300s = 5 mins for moderate recovery)
    private var EXP_RECOVERY_BASE = 0.0033277f;

    function updateWPrime(info as Activity.Info) as Void {
        var currentPower = $.getActivityValue(info, :currentPower, 0) as Number;
        currentPower = currentPower.toFloat();

        var deltaP = currentPower - _userFtp;

        if (deltaP > 0) {
            // --- DEPLETION (Linear) ---
            // Burning energy above FTP (1 Watt-second = 1 Joule)
            wPrimeRemaining -= deltaP;
        } else {
            // --- RECOVERY (Exponential) ---
            // Riding below FTP: Recovery speed scales with how low your power is relative to FTP.
            // Riding at 50% FTP recharges MUCH faster than riding at 95% FTP.

            // Skiba exponential recovery increment per second:
            // Replace Math.exp(x) with Math.pow(Math.E, x)
            var recoveryFactor = (_userFtp - currentPower) / _userFtp;
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

        staminaRatio = wPrimeRemaining / MAX_W_PRIME;
    }
    
    function getWPrimeRemaining() as Float {
        return wPrimeRemaining;
    }

    function getStaminaRatio() as Float {
        return staminaRatio;
    }

    function getFatigueRatio() as Float {
        return 1.0f - staminaRatio;
    }

    function resetWPrime() as Void {
        wPrimeRemaining = MAX_W_PRIME;
        staminaRatio = 1.0f;
    }

    function setMaxWPrime(maxWPrime as Float) as Void {
        MAX_W_PRIME = maxWPrime;
    }
}
