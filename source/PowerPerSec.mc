import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Activity;

class PowerPerSec {
    private var _powerPerSec as Number = 3;
    private var _powerBuffer = [0, 0, 0];
    private var _bufferIndex = 0;
    private var _samplesCount = 0;

    private var _lastComputedPower as Number = 0;

    function initialize() {}

    function setPowerPerSec(value as Number) {
        if (value < 1) {
            value = 1;
        } else if (value > 60) {
            value = 60;
        }
        _powerPerSec = value;
        _powerBuffer = [];
        while (_powerBuffer.size() < _powerPerSec) {
            _powerBuffer.add(0);
        }

        _bufferIndex = 0;
        _samplesCount = 0;
        _lastComputedPower = 0;
    }

    function getLastComputedPower() as Number {
        return _lastComputedPower;
    }
    function compute(info as Activity.Info) as Number {
        var rawPower = 0;

        if (info has :currentPower && info.currentPower != null) {
            rawPower = info.currentPower;
        }

        // Overwrite the oldest sample in our rolling buffer
        _powerBuffer[_bufferIndex] = rawPower;
        _bufferIndex = (_bufferIndex + 1) % _powerPerSec;

        if (_samplesCount < _powerPerSec) {
            _samplesCount++;
        }

        // Calculate the average based on available samples
        var sum = 0;
        for (var i = 0; i < _samplesCount; i++) {
            sum += _powerBuffer[i];
        }

        _lastComputedPower = (sum / _samplesCount).toNumber();
        System.println(["PowerPerSec.compute", _lastComputedPower, _powerBuffer, _samplesCount]);
        return _lastComputedPower;
    }
}
