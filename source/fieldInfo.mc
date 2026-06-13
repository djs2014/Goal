import Toybox.Lang;
import Toybox.System;

const FieldLayoutCount = 2;
enum FieldLayout {
    FLVertical = 0,
    FLHorizontal = 1
}

var FieldTypeCount = 15; // incl the 0
enum FieldType {
    FTUnknown = 0,
    FTDistance = 1,
    FTCalories = 2,
    FTAverageHeartRate = 3,
    FTAveragePower = 4,
    FTAverageSpeed = 5,
    FTAverageCadence = 6,
    FTNormalizedPower = 7,   
    FTTotalAscent = 8,
    FTTotalDescent = 9,
    FTMinutesElapsed = 10, 
    FTHeartRateZone = 11,  
    FTDistanceToDestination = 12,
    FTDistanceToNext = 13, 
    FTDistanceOrToDestination = 14, 
    // TODO
    FTTrainingStressScore = 15,
    FTIntensityFactor = 16,
    FTElevation = 17,
    FTTimeToDestination = 18,
    FTTimeOfDay = 19
}
