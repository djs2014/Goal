To Fix
Groen is ook donker -> hsp werkt niet?

Check avg heartzone -> maak vloeiend / en met zone lines?
Divider perc 80%
Configuratie per edgefield
Endurance/Current stuff



Color Scheme
0% to 50%: Blue → Green
50% to 100%: Green → Gold/Yellow (or straight to a bright Goal Green, depending on your palette preference)
100% to 200%: Achieved Goal → Dark Red (Overdrive)

dark/white/auto background

Abbreviations:

Field Type,Abbreviation,Alternative,Why it works
FTDistance,DST,KM / MI,Standard cycling shorthand.
FTCalories,CAL,KCAL,Universally recognized.
FTAverageHeartRateZone,AHR,AVG ♥,Distinguishes from live HR.
FTAveragePower,APW,AV W,Clean and professional.
FTAverageSpeed,AVS,SPD,"Keeps the ""Average"" context."
FTAverageCadence,CAD,RPM,Cyclists instantly recognize RPM.
FTNormalizedPower,NP,NP W,Standardized industry acronym.
FTTotalAscent,ASC,▲,Great for climbers.
FTTotalDescent,DSC,▼,Keeps symmetry with Ascent.
FTMinutesElapsed,TIM,MIN,Direct and simple.
FTHeartRateZone,HRZ,ZON,"Clearly indicates it's the Zone, not the BPM."


----------------TODO
Show values -> when paused to right if checked then no value.

1. Training Load & Intensity Targets

For performance-minded riders, tracking accumulation metrics ensures they don't over- or under-train during a specific block.

FTIntensityFactor (IF)

    Abbreviation: IF

    The Target: Usually set to a decimal target (e.g., target 0.85 for a hard tempo ride). Progress climbs from 0.0 to 1.0+.

    Garmin API: info.intensityFactor

FTTrainingStressScore (TSS)

    Abbreviation: TSS

    The Target: A total score target for the ride (e.g., aiming for 150 TSS on a long Sunday endurance block).

    Garmin API: info.trainingStressScore

2. Time & Duration Targets

You already have minutes elapsed, but these two targets completely change how you pace an endurance event or a timed interval.


FTTimeOfDay (TOD)

    Abbreviation: TOD or CLK

    The Target: A specific "curfew" or drop-dead time (e.g., “I need to be home by 12:00 PM”). The bar fills up as the clock ticks closer to your deadline.

    Garmin API: System.getClockTime()

FTTimeAheadBehind (TAB)

    Abbreviation: A/B or GAP

    The Target: If riding a Garmin Course with a "Virtual Partner," this target bar acts as a visual tug-of-war. 50% means you are perfectly tied with your ghost racer. Over 50% means you are pulling away into the "overdrive" midnight red!

    Garmin API: info.timeAheadWithVirtualPartner

3. Advanced Navigation & Climbing Targets

Since you've cracked the navigation tracking code, these are massive for alpine climbing or long gravel events.

FTElevation (ALT)

    Abbreviation: ALT or ELE

    The Target: Hitting the summit of a known mountain pass (e.g., target is 2,000m). The bar climbs as you scale the mountain.

    Garmin API: info.altitude

FTRemainingAscent (VAM / REM)

    Abbreviation: ASC or REM

    The Target: Setting a countdown bar for total vertical feet/meters left until the climbing is over. (The bar empties or fills based on how close you are to finishing the route's total vertical profile).

    Garmin API: info.totalAscentRemaining

FTTimeToDestination (ETA)

    Abbreviation: ETA or ETE

    The Target: Pacing against your expected duration (e.g., a target of 4 hours).

    Garmin API: info.timeToDestination



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