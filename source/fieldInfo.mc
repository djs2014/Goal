import Toybox.Lang;
import Toybox.System;

const FieldLayoutCount = 3;
enum FieldLayout {
    FLVertical = 0,
    FLHorizontal = 1,
    FLProportional = 2,
    FLCircle = 3,
    FL2Circles = 4,   
    FLRadialGauge = 5, 
}

var FieldTypeCount = 20; // incl the 0
enum FieldType {
    FTUnknown = 0,
    // Duration related fields
    FTDistance = 1,
    FTDistanceToDestination = 2,  
    FTDistanceToNext = 3,  
    FTDistanceOrNavDestination = 4, 
    FTMinutesElapsed = 5, 
    FTCalories = 6,
    FTTrainingStressScore = 7,
    // Average related fields
    FTAverageSpeed = 8,
    FTAverageCadence = 9,
    FTAveragePower = 10,
    FTAverageHeartRateZone = 11,
    FTNormalizedPower = 12,   
    FTIntensityFactor = 13,
    // Current related fields
    FTSpeed = 14,  
    FTCadence = 15,  
    FTPower = 16, 
    FTHeartRateZone = 17,  
    // Other
    FTTotalAscent = 18,
    FTTotalDescent = 19,

}
