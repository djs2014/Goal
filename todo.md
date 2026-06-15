clearclip issue
pause distance value
duration loop bug

api level min API Level 5.2.2

??remove zeros in show fields

Preset goals:


Casual / Endurance / Short and fast

function getDefaultTargetForField(type as FieldType) as Float {
    switch (type) {
        case FTDistance:                  return 60.0f;   // 60 km
        case FTMinutesElapsed:            return 120.0f;  // 2 hours
        case FTCalories:                  return 1000.0f; // 1000 kCal
        case FTAverageSpeed:              return 30.0f;   // 30 km/h
        case FTAverageCadence:            return 90.0f;   // 90 RPM
        case FTIntensityFactor:           return 0.82f;   // 82% of FTP
        case FTTotalAscent:               return 1000.0f; // 1000m climbing
        default:                          return 1.0f;    // Avoid division by zero
    }
}


Casual:
The Goal: Socializing, recovery, coffee stops, or exploring without watching metrics intensely. The targets are kept low and relaxed, focusing purely on easy movement.
Field Type,Typical Target,Why This Value?
FTDistance,25.0 km,"A classic, relaxed 1.5-hour cruise."
FTMinutesElapsed,90.0 mins,Standard time block before hitting a café.
FTCalories,500 kcal,Enough to completely justify a coffee and pastry!
FTAverageSpeed,22.0 km/h,"Gentle, non-competitive group or solo pace."
FTAverageCadence,80.0 RPM,"A lazy, comfortable spin."
FTHeartRateZone,Zone 1 or 2,Pure active recovery; conversational breathing.
FTAveragePower,120W−150W,Very low torque on the pedals.
FTIntensityFactor,0.55−0.65,Keeping the system stress completely minimized.

Endurance Ride Profile

    The Goal: Big volume base training, structured zone 2 pacing, or preparing for an upcoming sportive. The bars will fill up very slowly, helping you meter out your energy so you don't "bonk" (run out of fuel).
Field Type,Typical Target,Why This Value?
FTDistance,80.0 km (or 100 km),A serious half-to-full century block.
FTMinutesElapsed,180.0 mins,3 solid hours in the saddle.
FTCalories,1500 kcal,Tracks significant energy output for strict fueling strategies.
FTAverageSpeed,28.0 km/h,"Efficient, steady-state cruising speed."
FTAverageCadence,90.0 RPM,The high-efficiency sweet spot to save leg muscle glycogen.
FTHeartRateZone,Zone 2,"The ""aerobic engine builder"" zone."
FTAveragePower,180W−220W,Standard Zone 2 aerobic floor (depends heavily on individual FTP).
FTIntensityFactor,0.70−0.75,Classic endurance pacing ceiling.
FTTotalAscent,800 m,Rolling terrain management.

3. Short and Fast Profile (HIIT / Criterium / Midweek Blast)

The Goal: Intense intervals, racing, or ripping a local 1-hour loop to drop your friends. The targets are incredibly high-intensity, and your bars act as a tachometer pushing you deep into the red zone.

Field Type,Typical Target,Why This Value?
FTDistance,30.0 km,"A quick, hyper-focused loop."
FTMinutesElapsed,45.0−60.0 mins,Perfect for lunchtime crits or focused midweek pain caves.
FTCalories,700 kcal,High burn rate per minute due to massive anaerobic effort.
FTAverageSpeed,34.0−38.0 km/h,"Fast pace lines, racing speeds, or heavy solo hammering."
FTAverageCadence,95.0 RPM,Quick leg speed to buffer high-power anaerobic surges.
FTHeartRateZone,Zone 4 or 5,Threshold and VO2max tracking.
FTAveragePower,260W−320W,At or above threshold power.
FTNormalizedPower,280W−340W,"Accounts for the violent, punchy spikes of short racing blocks."
FTIntensityFactor,0.90−1.05+,Racing at the absolute limit of your current physical threshold.

function applyRidingStylePresets(styleId as Number) as Void {
    switch (styleId) {
        case 1: // --- ENDURANCE PROFILE ---
            barFields = [FTDistance, FTMinutesElapsed, FTAverageCadence, FTAveragePower];
            barTargets = [80.0f, 180.0f, 90.0f, 200.0f]; 
            break;

        case 2: // --- SHORT & FAST PROFILE ---
            barFields = [FTSpeed, FTCadence, FTHeartRateZone, FTNormalizedPower];
            barTargets = [40.0f, 95.0f, 4.0f, 300.0f]; // Aiming for 40km/h sprint, 95rpm, Zone 4, 300W NP
            break;

        case 0:
        default: // --- CASUAL PROFILE ---
            barFields = [FTDistance, FTMinutesElapsed, FTCalories, FTAverageSpeed];
            barTargets = [25.0f, 90.0f, 500.0f, 22.0f];
            break;
    }
}

4. The 150 km Endurance Preset Configuration

Field Type,Target Goal,Why This Matters for 150 km
FTDistance,150.0,Scales your main progress bar slowly. Seeing that bar pass 50% (75 km) is a massive psychological boost.
FTMinutesElapsed,330.0,Set to 5.5 hours (or your personal goal time). It helps you pace your stops so you don't burn daylight.
FTCalories,2500 to 3500,"Crucial: At 150 km, you will burn massive energy. Tracking calories burned tells you exactly when to eat."
FTIntensityFactor,0.68 to 0.72,"Your hard limit. If your IF bar creeps up past 0.75 early in the ride, you will pay for it in the last 40 km."
FTAverageCadence,90.0,"Keeps your stroke light. Lower cadences (e.g., 75 RPM) shift the load to your muscles, destroying your legs over 5 hours."

The Ultra-Endurance Coding Hack: The "Nutrition Alert"

On a 150 km ride, you need to consume roughly 60–90 grams of carbohydrates (around 240–360 calories) every single hour, regardless of how good you feel.

You can make your FTCalories progress bar reset or flash every time you hit a 300-calorie burning milestone, turning it into a smart "Time to Eat!" indicator:


1. Weight Loss Profile (Fat Oxidation)

The Strategic Goal: Maximize lipid metabolism (burning fat for fuel). To do this, you want to keep your intensity low enough that your body doesn't panic and shift over to burning purely stored carbohydrates (glycogen).

Field Type,Target Configuration,The Science / Logic
FTHeartRateZone,Zone 2 (2.0),"The classic ""Fat Burning Zone."" Fat oxidation peaks between 60% to 70% of your max heart rate."
FTMinutesElapsed,120.0 mins,"Fat metabolism kicks into high gear after the first 30–40 minutes of steady-state riding. Long, slow duration is king here."
FTCalories,800 kcal,Gives you a clean accumulation target to see the total energy deficit you are building.
FTIntensityFactor,0.60−0.65,"Keeping it under 0.65 prevents extreme hunger spikes after the ride, making it much easier to stick to your dietary goals."

2. Cardio Fitness Profile (Aerobic Capacity / Stroke Volume)

The Strategic Goal: Strengthen the heart muscle, increase capillary density, and improve how efficiently your muscles clear lactic acid. This requires a "tempo" or "sweet spot" workload.

Field Type,Target Configuration,The Science / Logic
FTHeartRateZone,Zone 3 (3.0),Aerobic conditioning zone. Pushes your stroke volume (the amount of blood your heart pumps per beat) to its physical maximum.
FTAverageCadence,92.0 RPM,High cadences shift the stress away from your muscles and put it directly onto your cardiovascular/aerobic system.
FTAveragePower,75%−85% of FTP,"Classic ""Tempo"" power. It forces the body to adapt to sustained, fast-paced breathing without completely exhausting you."
FTTrainingStressScore,100 TSS,A solid metric to track the cardiovascular workload dose for the day.

3. Sports Performance Profile (VO2max / Power)

The Strategic Goal: Increase your absolute top-end speed, raise your functional threshold power (FTP), and build raw anaerobic capacity for racing, group rides, or climbing steep hills.

Field Type,Target Configuration,The Science / Logic
FTHeartRateZone,Zone 4 to 5 (4.5),Threshold and VO2max zones. This is where you increase your body's ability to handle high cellular acidity.
FTPower,110%−120% of FTP,"Set this to your specific Interval Target Power (e.g., 350W) so your progress bar stays at 100% only when you are completely hammering."
FTNormalizedPower,95%−105% of FTP,"Tracks your true physiological output, ensuring you kept the session high-octane despite coasting between intervals."
FTIntensityFactor,0.92−1.05,"Signals a high-performance, maximum-effort workout block."

4. Nutrition / Fueling Profile

The Strategic Goal: Prevent the dreaded "bonk" on ultra-endurance rides (like your 150 km loops) by treating the bicycle computer as an active fueling manager.

Field Type,Target Configuration,The Science / Logic
FTCalories,300 (Repeating Window),"As we coded, this acts as your rolling countdown timer. Every time it fills to 100% and plays your audio beep, you consume 30−40g of carbs."
FTDistance,150.0 km,"Tracks total distance to align your hydration strategy (e.g., matching bottle consumption to kilometers covered)."
FTMinutesElapsed,45.0 mins (Window),"Alternatively, you can use a repeating time window target instead of a calorie target to trigger a nutrition alert precisely every 45 minutes."

// An elegant configuration router for your target profiles
function loadFitnessProfile(profileType) {
    switch(profileType) {
        case PROFILE_WEIGHT_LOSS:
            setFieldTarget(FTHeartRateZone, 2.0f);   // Zone 2
            setFieldTarget(FTMinutesElapsed, 120.0f); // 2 hours
            setFieldTarget(FTIntensityFactor, 0.62f); // Easy fat oxidation
            break;
            
        case PROFILE_CARDIO_FITNESS:
            setFieldTarget(FTHeartRateZone, 3.2f);   // Zone 3 sweet spot
            setFieldTarget(FTAverageCadence, 92.0f);  // Aerobic spin
            setFieldTarget(FTTrainingStressScore, 100.0f);
            break;
            
        case PROFILE_SPORTS_PERF:
            setFieldTarget(FTHeartRateZone, 4.5f);   // High intensity VO2
            setFieldTarget(FTAverageCadence, 95.0f);  // Racing leg speed
            setFieldTarget(FTIntensityFactor, 0.95f); // Race pace
            break;
    }
}


layout: bricks ?

arc layout
Divider perc 80%
Configuratie per edgefield
Endurance/Current stuff
autoupdate targets -> use reached values of last as goal

The Mathematical Average Symbol ( ∅ or ∅ )
the Overline / Macron Accent ( Ā )

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