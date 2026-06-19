api level min API Level 5.2.2
d2d d2n niet ok?
??remove zeros in show fields


todo readme for profiles
x pause values ?? cache values
x pause distance to test == distance value?
get HRZ as float based on actual HR
show values vertical if possible
x calc all values -> for show diff data on diff fields

fancy layout -> rings / arc / 8



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