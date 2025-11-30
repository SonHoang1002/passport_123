// import 'package:color_picker_android/commons/constants.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  SharedPreferences? pref;

  ///
  /// Luu vao share theo dang sau:
  /// 
  /// [0]: id country
  /// 
  /// [1]: id passport
  /// 
  /// [2]: passport width,
  /// 
  /// [3]: passport height,
  /// 
  /// [4]: passport ratioHead,
  /// 
  /// [5]: passport ratioEyes,
  /// 
  /// [6]: passport ratioChin,
  /// 
  /// [7]: id unit
  /// 
  /// CHU Y: TRONG TRUONG HOP PASSPORT LA CUSTOM THI BAT BUOC PHAI CO THUOC TINH TU [2]->[7]
  /// 
  Future<bool> updateCountryPassport(CountryModel countryModel) async {
    pref ??= await SharedPreferences.getInstance();
    List<String> listData = [
      countryModel.id.toString(),
      countryModel.currentPassport.id.toString(),
    ];
    if (countryModel.id == ID_CUSTOM_COUNTRY_MODEL &&
        countryModel.currentPassport.id == ID_CUSTOM_COUNTRY_MODEL) {
      listData.add(countryModel.currentPassport.width.toString());
      listData.add(countryModel.currentPassport.height.toString());
      listData.add(countryModel.currentPassport.ratioHead.toString());
      listData.add(countryModel.currentPassport.ratioEyes.toString());
      listData.add(countryModel.currentPassport.ratioChin.toString());
      listData.add(countryModel.currentPassport.unit.id.toString());
    }
    final result = await pref!.setStringList(SHARE_PREF_KEY_COUNTRY, listData);
    return result;
  }
  ///
  /// [0]: id country
  /// 
  /// [1]: id passport
  /// 
  /// [2]: passport width,
  /// 
  /// [3]: passport height,
  /// 
  /// [4]: passport ratioHead,
  /// 
  /// [5]: passport ratioEyes,
  /// 
  /// [6]: passport ratioChin,
  /// 
  /// [7]: id unit
  /// 
  /// CHU Y: TRONG TRUONG HOP PASSPORT LA CUSTOM THI BAT BUOC SE CO THUOC TINH TU [2]->[7]
  /// 
  Future<List<String>?> getCountryPassport() async {
    pref ??= await SharedPreferences.getInstance();
    final result = pref!.getStringList(SHARE_PREF_KEY_COUNTRY);
    return result;
  }

  Future<bool> updateColorSaved(List<String> listColor) async {
    pref ??= await SharedPreferences.getInstance();
    final result =
        await pref!.setStringList("PREFERENCE_SAVED_COLOR_KEY", listColor);
    return result;
  }

  Future<List<String>> getColorSaved() async {
    pref ??= await SharedPreferences.getInstance();
    final result = pref!.getStringList("PREFERENCE_SAVED_COLOR_KEY");
    return result ?? [];
  }

  Future<bool> updateGetStarted(bool isGetStarted) async {
    pref ??= await SharedPreferences.getInstance();
    final result = await pref!.setBool(SHARE_PREF_KEY_GET_STATED, isGetStarted);
    return result;
  }

  Future<bool?> getGetStarted() async {
    pref ??= await SharedPreferences.getInstance();
    final result = pref!.getBool(SHARE_PREF_KEY_GET_STATED);
    return result;
  }
}
