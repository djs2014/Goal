import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;
import Toybox.Activity;

class EfficiencyFactorTracker {
    private var sumPower = 0.0f;
    private var sumHR = 0.0f;
    private var sampleCount = 0;

    private var baseEF = 0.0f;
    private var hasCalculatedWarmup = false;

    function initialize() {
        loadSettings();
    }

    function loadSettings() as Void {
        // Load the stored Base EF from previous rides (default to 0.0 if not set)
        var storedEF = getStorageValue("stamina_base_ef", 0.0f) as Float;
        if (storedEF != null) {
            baseEF = storedEF.toFloat();
        }
        warmupStartSeconds =
            getStorageValue("warmup_start_seconds", 180) as Number;
        if (warmupStartSeconds <= 0) {
            warmupStartSeconds = 180; // Default to 3 minutes
        }
        warmupEndSeconds = getStorageValue("warmup_end_seconds", 480) as Number;
        if (warmupEndSeconds <= 0) {
            warmupEndSeconds = 480; // Default to 8 minutes
        }
        if (warmupEndSeconds <= warmupStartSeconds) {
            warmupEndSeconds = warmupStartSeconds + 300; // Ensure at least 5 minutes
        }
    }

    private var minimumPower = 50 as Number; // Minimum power to consider for warm-up EF calculation
    private var warmupStartSeconds = 180; // 3 minutes
    private var warmupEndSeconds = 480; // 8 minutes
    private var warmupRatio = 0.0f; // Ratio of warm-up EF to Base EF

    function setWarmupWindow(
        startSeconds as Number,
        endSeconds as Number
    ) as Void {
        warmupStartSeconds = startSeconds;
        warmupEndSeconds = endSeconds;
    }

    function getHasCalculatedWarmup() as Boolean {
        return hasCalculatedWarmup;
    }
    function getWarmupRatio() as Float {
        return warmupRatio;
    }

    function processWarmup(
        info as Activity.Info,
        elapsedSeconds as Number
    ) as Void {
        warmupRatio = elapsedSeconds / warmupEndSeconds.toFloat();   
        // Only run during the 3 to 8 minute window (180s to 480s)
        if (
            elapsedSeconds >= warmupStartSeconds &&
            elapsedSeconds <= warmupEndSeconds
        ) {
            if (
                info.currentPower != null &&
                info.currentHeartRate != null &&
                info.currentPower > minimumPower
            ) {
                sumPower += info.currentPower.toFloat();
                sumHR += info.currentHeartRate.toFloat();
                sampleCount++;
            }
        }
        // Right at the end of the warm-up window, evaluate the result once
        else if (elapsedSeconds > warmupEndSeconds && !hasCalculatedWarmup) {
            hasCalculatedWarmup = true;

            if (sampleCount > 60 && sumHR > 0) {
                // Ensure we got at least 1 minute of valid data
                var currentEF = sumPower / sampleCount / (sumHR / sampleCount);
                // System.println([
                //     "EfficiencyFactorTracker.processWarmup",
                //     "Warm-up EF",
                //     currentEF,
                //     "Base EF",
                //     baseEF
                // ]);
                // Read user setting: "Auto-record new Base EF" - only once per ride.
                var autoRecordMode =
                    getStorageValue("auto_record_new_base_ef", false) as
                    Boolean;
                if (autoRecordMode == true) {
                    Storage.setValue("auto_record_new_base_ef", false);
                }
                
                if (baseEF == 0.0f || autoRecordMode) {
                    // First time running OR user specified today is a "Fresh Base Ride"
                    baseEF = currentEF;
                    Storage.setValue("stamina_base_ef", baseEF);

                    // Full capacity!
                    applyFatiguePenalty(1.0f);
                } else {
                    // Compare today's warm-up EF against stored Base EF
                    var efRatio = currentEF / baseEF.toFloat();
                    // // Adjust W' Max and slow down recovery speed (Tau)
                    // MAX_W_PRIME = USER_CONFIGURED_MAX_W * factor;

                    // // Recalculate remaining W' dynamically
                    // if (wPrimeRemaining > MAX_W_PRIME) {
                    //     wPrimeRemaining = MAX_W_PRIME;
                    // }
                    if (efRatio < 0.88f) {
                        // Severe fatigue (EF is > 12% lower than normal)
                        applyFatiguePenalty(0.75f); // 75% W' capacity
                    } else if (efRatio < 0.95f) {
                        // Moderate fatigue (EF is 5-12% lower)
                        applyFatiguePenalty(0.85f); // 85% W' capacity
                    } else {
                        // Fresh or better!
                        applyFatiguePenalty(1.0f);

                        // If today's EF is noticeably better than old base, update it
                        if (currentEF > baseEF * 1.03f) {
                            baseEF = currentEF;
                            Storage.setValue("stamina_base_ef", baseEF);
                        }
                    }
                }
            }
        }
    }

    // :onselect(value)
    var _cbTargetRef as Lang.WeakReference?;
    var _onApplyMethodName as Symbol?;
    function setOnApplyFatiguePenalty(
        target as Object,
        methodName as Symbol
    ) as Void {
        _cbTargetRef = target.weak();
        _onApplyMethodName = methodName;
    }

    private function applyFatiguePenalty(fatigueFactor as Float) as Void {
        Storage.setValue("stamina_fatigue_factor", fatigueFactor);

        if (_onApplyMethodName == null) {
            return;
        }

        if (_cbTargetRef == null || !_cbTargetRef.stillAlive()) {
            return;
        }

        var target = _cbTargetRef.get();
        if (target != null && _onApplyMethodName != null) {
            // Dynamically look up the method on the live parent object
            var callback = target.method(_onApplyMethodName);

            callback.invoke(fatigueFactor);
        }

        // // Adjust W' Max and slow down recovery speed (Tau)
        // MAX_W_PRIME = USER_CONFIGURED_MAX_W * factor;

        // // Recalculate remaining W' dynamically
        // if (wPrimeRemaining > MAX_W_PRIME) {
        //     wPrimeRemaining = MAX_W_PRIME;
        // }
    }

    function getStorageValue(
        key as Application.PropertyKeyType,
        dflt as Application.PropertyValueType
    ) as Application.PropertyValueType {
        try {
            var val = Toybox.Application.Storage.getValue(key);
            if (val != null) {
                return val;
            }
            return dflt;
        } catch (ex) {
            return dflt;
        }
        return dflt;
    }
}
