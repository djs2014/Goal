import Toybox.Lang;
import Toybox.System;

const FieldLayoutCount = 2;
enum FieldLayout {
    FLVertical = 0,
    FLHorizontal = 1
}

var FieldTypeCount = 18; // incl the 0
enum FieldType {
    FTUnknown = 0,
    FTDistance = 1,
    FTCalories = 2,
    FTAverageHeartRateZone = 3,
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
    FTDistanceOrNavDestination = 14, 
    FTTrainingStressScore = 15,
    FTIntensityFactor = 16,
    FTCadence = 17,    
}
