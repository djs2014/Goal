api level min API Level 5.2.2

To Fix
Groen is ook donker -> hsp werkt niet?

arc layout
Divider perc 80%
Configuratie per edgefield
Endurance/Current stuff
autoupdate targets -> use reached values of last as goal


Color Scheme
0% to 50%: Blue → Green
50% to 100%: Green → Gold/Yellow (or straight to a bright Goal Green, depending on your palette preference)
100% to 200%: Achieved Goal → Dark Red (Overdrive)

dark/white/auto background

Abbreviations:



----------------TODO
Show values -> when paused to right if checked then no value.

1. Training Load & Intensity Targets

For performance-minded riders, tracking accumulation metrics ensures they don't over- or under-train during a specific block.

x FTIntensityFactor (IF)

    Abbreviation: IF

    The Target: Usually set to a decimal target (e.g., target 0.85 for a hard tempo ride). Progress climbs from 0.0 to 1.0+.

    Garmin API: info.intensityFactor

x FTTrainingStressScore (TSS)

    Abbreviation: TSS

    The Target: A total score target for the ride (e.g., aiming for 150 TSS on a long Sunday endurance block).

    Garmin API: info.trainingStressScore




The target becomes your peak baseline VO2Max (or a target interval score like 50, 60, etc.), and the bar climbs as your heart rate and power output sustain those high-intensity thresholds.

HIIT & Intensity Target Additions

    FTIntervalPerformanceScore (VO2 / SCR)

        Abbreviation: SCR (Score) or VO2

        The Target: Your target interval score or baseline VO2Max.

        Why it works: It acts as a real-time quality check for your high-intensity blocks. If the bar is hitting gold or midnight red, you know your anaerobic/aerobic system is being fully stimulated.

FTHeartRate (HR)

    Abbreviation: HR or BPM

    The Target: Your maximum heart rate (MaxHR) or the threshold for a specific anaerobic interval.

    Why it works: Unlike Average HR, mapping your live HR to a bar gives you a visual tachometer of how close you are to redlining during an interval.

FTCurrentCadence (CAD)

    Abbreviation: CAD or RPM

    The Target: A target cadence ceiling or floor (e.g., trying to spin at 110 RPM for a high-cadence leg-speed interval).

// --- HIIT & Real-Time Performance Additions ---
    FTIntervalPerformanceScore = 15,
    FTHeartRate = 16,
    FTCurrentCadence = 17


Config profiles: or add new ones + save current target values

<settings>
    <setting propertyKey="@Properties.PROP_LayoutProfile" title="Dashboard Profile">
        <settingConfig type="list">
            <listEntry value="0">Endurance / Navigation</listEntry>
            <listEntry value="1">HIIT / Intervals</listEntry>
            <listEntry value="2">Climbing / Alpine</listEntry>
        </settingConfig>
    </setting>
</settings>

/ Call this to dynamically build the dashboards based on the profile
    function loadProfileLayout() as Void {
        try {
            mProfileId = Application.Properties.getValue("PROP_LayoutProfile");
        } catch(e) {
            mProfileId = 0; // Fallback to safe default
        }

        switch (mProfileId) {
            case 1: // --- HIIT / INTERVALS PROFILE ---
                barFields = [FTHeartRate, FTCurrentCadence, FTIntervalPerformanceScore, FTMinutesElapsed];
                barTargets = [185.0f, 110.0f, 60.0f, 45.0f]; // Targets: Target Max HR, Target RPM, Target HIIT Score, Total Duration
                break;

            case 2: // --- CLIMBING PROFILE ---
                barFields = [FTTotalAscent, FTElevation, FTDistanceOrNavDestination, FTAveragePower];
                barTargets = [1200.0f, 1800.0f, 60.0f, 240.0f]; // Targets: 1200m Climbing, 1800m Peak, 60km route, 240W pacing
                break;

            case 0:
            default: // --- ENDURANCE / DEFAULT PROFILE ---
                barFields = [FTDistance, FTCalories, FTMinutesElapsed, FTAverageSpeed];
                barTargets = [50.0f, 800.0f, 120.0f, 30.0f]; 
                break;
        }
    }



HRZ warmup bar
1. The "Zone 0" Warmup Buffer

When you first roll out of your driveway, your actual heart rate will be lower than your Zone 1 floor (e.g., lower than 128 bpm).
With the code written as-is, calculateZoneProgress safely returns 0.0f (an empty track), which is perfect.

However, if you want some visual feedback during your warmup, you can add a tiny fallback: if your heart rate is below Zone 1, you can calculate your progress from a resting heart rate (e.g., 60 bpm) up to your Zone 1 floor. That way, you get a "Warmup" bar before the real intervals start!



1. The Dial / Gauge Layout (Semi-Circular Arc)

Instead of a straight line, your progress fills up an arc or a semi-circle. This is the ultimate "tachometer" look for real-time metrics like Heart Rate or Current Power.
How it works in Monkey C:

You use dc.drawArc() to draw the empty track, and then overlay a colored arc using your dynamic progress math.

    The Math: A circle is 360∘. A gorgeous dashboard gauge usually spans from 210∘ (bottom left) to −30∘ (bottom right), giving you a sweeping 240∘ active tracking zone.

    Progress Formula: Multiply your progress fraction by the total arc angle.
    Current Angle=Start Angle−(Progress×240)
// Draws a curving dashboard dial
var startAngle = 210;
var totalSweep = 240;
var currentSweep = (progress > 1.0 ? 1.0 : progress) * totalSweep;
var endAngle = startAngle - currentSweep;

// Track
dc.setColor(trackColor, Gfx.COLOR_TRANSPARENT);
dc.drawArc(centerX, centerY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startAngle, startAngle - totalSweep);

// Fill
dc.setColor(barColor, Gfx.COLOR_TRANSPARENT);
dc.drawArc(centerX, centerY, radius, Gfx.ARC_COUNTER_CLOCKWISE, startAngle, endAngle);