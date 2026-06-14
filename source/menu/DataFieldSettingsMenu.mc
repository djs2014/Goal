import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class DataFieldSettingsMenu extends WatchUi.Menu2 {
  function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Handles menu input and stores the menu data
class DataFieldSettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _item as MenuItem?;
  hidden var _storageKey as String = "";
  hidden var _arrayIndex as Number = -1;

  function initialize() {
    // view as DataFieldSettingsView
    Menu2InputDelegate.initialize();
    //_view = view;
  }

  function onSelect(menuItem as MenuItem) as Void {
    _item = menuItem;
    var id = _item.getId();

    // Extract selected storage key and index
    _storageKey = stringLeft(id.toString(), "|", id.toString());
    var idx = stringRight(id.toString(), "|", "").toNumber();
    if (idx == null) {
      _arrayIndex = -1;
    } else {
      _arrayIndex = idx;
    }

    if (id instanceof String && _item instanceof ToggleMenuItem) {
      $.setStorageValueOrArray(id, _item.isEnabled());
      return;
    }

    if (id instanceof String && id.equals("advanced")) {
      var advMenu = new WatchUi.Menu2({ :title => "Advanced" });

      var mi;

      mi = new WatchUi.MenuItem(
        "Cadence counter|0~5(seconds)",
        null,
        "cadence_counter",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Gap columns horizontal|0-20(pixels)",
        null,
        "gap_columns_horizontal",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Gap columns vertical|0-20(pixels)",
        null,
        "gap_columns_vertical",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      advMenu.addItem(mi);

      WatchUi.pushView(
        advMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }

    if (id instanceof String && id.equals("targets")) {
      var targetMenu = new WatchUi.Menu2({ :title => "Targets / Goals" });

      var mi;

      mi = new WatchUi.MenuItem(
        "Distance|0~ (km)",
        null,
        "target_distance",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Calories|0~(calories)",
        null,
        "target_calories",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Power, 0 is profile ftp|0~(watts)",
        null,
        "target_power",
        null
      );
      var targetPower = $.getStorageValue(mi.getId() as String, 0) as Number;
      if (targetPower == 0) {
        mi.setSubLabel(
          "profile ftp: " + $.getUserFtp().format("%d") + " watts"
        );
      } else {
        mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      }
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Average power|0~(W)",
        null,
        "target_average_power",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem("Speed|0~(km/h)", null, "target_speed", null);
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Average speed|0~(km/h)",
        null,
        "target_average_speed",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Cadence|0~(rpm)",
        null,
        "target_cadence",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Average cadence|0~(rpm)",
        null,
        "target_average_cadence",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Normalized power|0~(W)",
        null,
        "target_normalized_power",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Total ascent|0~(m)",
        null,
        "target_total_ascent",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Total descent|0~(m)",
        null,
        "target_total_descent",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Minutes elapsed|0~(min)",
        null,
        "target_minutes_elapsed",
        null
      );
      mi.setSubLabel($.getStorageNumberAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      mi = new WatchUi.MenuItem(
        "Heart rate zone",
        null,
        "target_heart_rate_zone",
        null
      );
      mi.setSubLabel(
        "zone " + $.getStorageNumberAsString(mi.getId() as String)
      );
      targetMenu.addItem(mi);

      // FTIntensityFactor
      // Common values for Intensity Factor (IF) in cycling range from less than 0.60 for recovery rides to 1.2 for very short,
      // intense efforts. Typical endurance rides score between 0.60 and 0.80, while tempo training sessions usually fall
      //between 0.75 and 0.85.
      mi = new WatchUi.MenuItem(
        "Intensity Factor|0.0~2.0(IF)",
        null,
        "target_intensity_factor",
        null
      );
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      // FTTrainingStressScore
      // Common values for Training Stress Score (TSS) in cycling are as follows: 0-50 indicates a low effort (easy recovery ride),
      // 50-100 is moderate (productive workout),
      // 100-150 is high (hard workout), and 150+ is very high (intense session requiring recovery).
      mi = new WatchUi.MenuItem(
        "Training Stress Score|0~300(TSS)",
        null,
        "target_training_stress_score",
        null
      );
      mi.setSubLabel($.getStorageFloatAsString(mi.getId() as String));
      targetMenu.addItem(mi);

      WatchUi.pushView(
        targetMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }

    if (id instanceof String && id.equals("show_fields")) {
      var label = menuItem.getLabel();
      var prefix = id.toString();
      var fieldMenu = new WatchUi.Menu2({ :title => label + " items" });

      var storageKey = id.toString();

      var array = $.getStorageValue(storageKey, []) as Array<Number or Boolean>;
      // Check size
      if (
        $.ensureArraySize(
          array as Array<Application.PropertyValueType>,
          $.gShowFieldsArraySize,
          0
        )
      ) {
        $.setStorageValueOrArray(
          storageKey,
          array as Array<Application.PropertyValueType>
        );
      }

      // Layout
      var mi = new WatchUi.MenuItem("Layout", null, prefix + "|0", null);
      mi.setSubLabel($.getLayoutByIndex(prefix, 0));
      fieldMenu.addItem(mi);

      // // Divider TODO
      // mi = new WatchUi.MenuItem("Fields", null, null, null);
      // fieldMenu.addItem(mi);

      // Bars
      for (var i = 1; i < $.gShowFieldsArraySize; i++) {
        mi = new WatchUi.MenuItem(
          "Bar " + i,
          null,
          prefix + "|" + i.format("%d"),
          null
        );
        mi.setSubLabel($.getFieldByIndex(prefix, i));
        fieldMenu.addItem(mi);
      }

      WatchUi.pushView(
        fieldMenu,
        new $.GeneralMenuDelegate(),
        WatchUi.SLIDE_UP
      );
      return;
    }

    // if (id instanceof String && menuItem instanceof ToggleMenuItem) {
    //   $.setStorageValueOrArray(id, menuItem.isEnabled());
    //   return;
    // }

    //  if (id instanceof String && item instanceof ToggleMenuItem) {
    //   Storage.setValue(id as String, item.isEnabled());
    //   item.setSubLabel($.subMenuToggleMenuItem(id as String));
    //   return;
    // }
  }

  function onSelectedSelection(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    $.setStorageValueOrArray(storageKey, value);
  }
}

class GeneralMenuDelegate extends WatchUi.Menu2InputDelegate {
  hidden var _item as MenuItem?;
  hidden var _storageKey as String = "";
  hidden var _arrayIndex as Number = -1;

  hidden var _currentPrompt as String = "";

  function initialize() {
    Menu2InputDelegate.initialize();
  }

  function onSelect(menuItem as MenuItem) as Void {
    _item = menuItem;
    var id = menuItem.getId();

    // Extract selected storage key and index
    _storageKey = stringLeft(id.toString(), "|", id.toString());
    var idx = stringRight(id.toString(), "|", "").toNumber();
    if (idx == null) {
      _arrayIndex = -1;
    } else {
      _arrayIndex = idx;
    }

    if (id instanceof String && id.find("|") != null) {
      var prefix = stringLeft(id, "|", "");
      var index = stringRight(id, "|", "").toNumber();
      if (prefix == "" || index == null) {
        return;
      }
      var idxLayout = index as Number;
      if (idxLayout == 0) {
        var sp = new selectionMenuPicker("Field layout", id as String);
        for (var i = 0; i < $.FieldLayoutCount; i++) {
          sp.add($.getFieldLayoutAsString(i as FieldLayout), null, i);
        }
        sp.setOnSelected(self, :onSelectedField, _item);
        sp.show();
        return;
      }

      var sp = new selectionMenuPicker("Field " + idx, id as String);
      for (var i = 0; i < $.FieldTypeCount; i++) {
        sp.add($.getFieldTypeAsString(i as FieldType), null, i);
      }
      sp.setOnSelected(self, :onSelectedField, _item);
      sp.show();
      return;
    }

    if (id.equals("target_heart_rate_zone")) {
      var sp = new selectionMenuPicker("Target heartrate zone", id as String);
      sp.add("Zone 1", null, 1);
      sp.add("Zone 2", null, 2);
      sp.add("Zone 3", null, 3);
      sp.add("Zone 4", null, 4);
      sp.add("Zone 5", null, 5);

      sp.setOnSelected(self, :onSelectedSelection, _item);
      sp.show();
      return;
    }

    if (id instanceof String && _item instanceof ToggleMenuItem) {
      $.setStorageValueOrArray(id, _item.isEnabled());
      return;
    }

    // Numeric input
    var prompt = _item.getLabel();
    // System.println(["Numeric input:", prompt]);
    var value = $.getStorageValue(id as String, 0) as Numeric;
    var view = $.getNumericInputView(prompt, value);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(
      view,
      new $.NumericInputDelegate(view),
      WatchUi.SLIDE_RIGHT
    );
  }

  function onAcceptNumericinput(value as Numeric, subLabel as String) as Void {
    try {
      if (_item != null) {
        // Note contains `storageKey|index` or `storageKey`
        var key = _item.getId() as String;
        $.setStorageValueOrArray(key, value);
        (_item as MenuItem).setSubLabel(subLabel);
      }
    } catch (ex) {
      ex.printStackTrace();
    }
  }

  function onNumericinput(
    editData as Array<Char>,
    cursorPos as Number,
    insert as Boolean,
    negative as Boolean,
    opt as NumericOptions
  ) as Void {
    // Hack to refresh screen
    WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    var view = new $.NumericInputView("", 0);
    view.processOptions(opt);
    view.setEditData(editData, cursorPos, insert, negative);
    view.setOnAccept(self, :onAcceptNumericinput);
    view.setOnKeypressed(self, :onNumericinput);

    Toybox.WatchUi.pushView(
      view,
      new $.NumericInputDelegate(view),
      WatchUi.SLIDE_IMMEDIATE
    );
  }

  //! Handle the back key being pressed

  function onBack() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  //! Handle the done item being selected

  function onDone() as Void {
    WatchUi.popView(WatchUi.SLIDE_DOWN);
  }

  function onSelectedSelection(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    $.setStorageValueOrArray(storageKey, value);
  }

  function onSelectedFieldLayout(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = 0;
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
    var fields =
      getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    if (idx < fields.size()) {
      fields[idx] = value as Number;
      Storage.setValue(
        key,
        fields as Lang.Array<Application.PropertyValueType>
      );
    }
  }

  function onSelectedField(
    storageKey as String,
    value as Application.PropertyValueType
  ) as Void {
    // storageKey large_field|0  (key and field index) value = 1 (field type)
    var key = stringLeft(storageKey, "|", "");
    var index = stringRight(storageKey, "|", "").toNumber();
    if (key == "" || index == null) {
      return;
    }
    var idx = index as Number;
    var fields =
      getStorageValue(key, [0, 0, 0, 0, 0, 0, 0, 0, 0]) as Array<Number>;
    if (idx < fields.size()) {
      fields[idx] = value as Number;
      Storage.setValue(
        key,
        fields as Lang.Array<Application.PropertyValueType>
      );
    }
  }
}

function addMenuItem(
  menu as WatchUi.Menu2,
  label as String,
  subLabel as String,
  id as String
) {
  var mi = new WatchUi.MenuItem(label, subLabel, id, null);
  menu.addItem(mi);
}

function addToggleMenuItem(
  menu as WatchUi.Menu2,
  label as String,
  subLabel as String?,
  id as String,
  enabled as Boolean
) {
  var tmi = new WatchUi.ToggleMenuItem(label, subLabel, id, enabled, null);
  menu.addItem(tmi);
}

function getKeyAndIndex(key as String, index as Number) as String {
  return Lang.format("$1$|$2$", [key, index.toString()]);
}

// Content array: [layout, field 1 .. field 8 ]
function getLayoutByIndex(key as String, index as Number) as String {
  var fields = getStorageValue(key, []) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }
  return $.getFieldLayoutAsString(fields[index] as FieldLayout);
}

// Content array: [layout, field 1 .. field 8 ]
function getFieldByIndex(key as String, index as Number) as String {
  var fields = getStorageValue(key, []) as Array<Number>;
  if (index < 0 || index >= fields.size()) {
    return "--";
  }

  var field = fields[index] as FieldType;
  return $.getFieldTypeAsString(field);
}

function getFieldLayoutAsString(fieldLayout as FieldLayout) as String {
  switch (fieldLayout) {
    case FLVertical:
      return "Vertical";
    case FLHorizontal:
      return "Horizontal";
    default:
      return "unknown";
  }
}

function getFieldTypeAsString(fieldType as FieldType) as String {
  switch (fieldType) {
    case FTUnknown:
      return "Unknown";
    case FTDistance:
      return "Distance";
    case FTCalories:
      return "Calories";
    case FTAverageHeartRateZone:
      return "Avg heartrate";
    case FTPower:
      return "Power";
    case FTAveragePower:
      return "Avg power";
    case FTAverageSpeed:
      return "Avg speed";
    case FTAverageCadence:
      return "Avg cadence";
    case FTNormalizedPower:
      return "Normalized power";
    case FTTotalAscent:
      return "Total ascent";
    case FTTotalDescent:
      return "Total descent";
    case FTMinutesElapsed:
      return "Minutes elapsed";
    case FTHeartRateZone:
      return "Heart rate zone";
    case FTDistanceToDestination:
      return "Dist to destination";
    case FTDistanceToNext:
      return "Distance to next";
    case FTDistanceOrNavDestination:
      return "Dist or Nav destination";
    case FTTrainingStressScore:
      return "Training stress score";
    case FTIntensityFactor:
      return "Intensity factor";
    case FTCadence:
      return "Cadence";
    case FTSpeed:
      return "Speed";
    default:
      return "Unknown";
  }
}
