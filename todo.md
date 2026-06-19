api level min API Level 5.2.2
d2d d2n niet ok?
??remove zeros in show fields


todo readme for profiles
pause values ?? cache values
pause distance to test == distance value?
get HRZ as float based on actual HR
show values vertical if possible
calc all values -> for show diff data on diff fields

fancy layout -> rings / arc / 8


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



layout: bricks ?

arc layout


Color Scheme
Abbreviations:




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