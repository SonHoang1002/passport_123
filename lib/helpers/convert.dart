import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:passport_photo_2/commons/constants.dart';
import 'package:passport_photo_2/commons/extension.dart';
import 'package:passport_photo_2/helpers/log_custom.dart';
import 'package:passport_photo_2/models/country_passport_model.dart';

/// [Input] is KB , [Output] is KB or MB
class FlutterConvert {
  static String convertByteUnit(double input) {
    final kToM = input / MB_TO_KB;
    if (kToM > 1) {
      return "${kToM.roundWithUnit(fractionDigits: 2)} MB";
    } else {
      return "${input.roundWithUnit(fractionDigits: 2)} KB";
    }
  }

  ///
  /// convert [inputUnit] to [targetUnit]
  ///
  static double convertUnit(Unit? inputUnit, Unit? targetUnit, double value) {
    const pointToCm = 1 / 72 * 2.54;
    const inchToCm = 2.54;
    const pointToInch = pointToCm / inchToCm;
    var result = value;
    if (inputUnit == null || targetUnit == null) {
      return value;
    }
    // inch
    if (inputUnit.title == INCH.title) {
      if (targetUnit.title == POINT.title) {
        result = value * (1 / pointToInch);
      } else if (targetUnit.title == CENTIMET.title) {
        result = value * inchToCm;
      } else if (targetUnit.title == MINIMET.title) {
        result = value * inchToCm * 10;
      } else if (targetUnit.title == PIXEL.title) {
        result = value * (1 / pointToInch) * 4 / 3;
      }
    }
    // point
    if (inputUnit.title == POINT.title) {
      if (targetUnit.title == INCH.title) {
        result = value * pointToInch;
      } else if (targetUnit.title == CENTIMET.title) {
        result = value * pointToCm;
      } else if (targetUnit.title == MINIMET.title) {
        result = value * inchToCm * 10;
      } else if (targetUnit.title == PIXEL.title) {
        consolelog("hello hello hello");
        result = value * 4 / 3;
      }
    }
    // cm
    if (inputUnit.title == CENTIMET.title) {
      if (targetUnit.title == INCH.title) {
        result = value * (1 / inchToCm);
      } else if (targetUnit.title == POINT.title) {
        result = value * (1 / pointToCm);
      } else if (targetUnit.title == MINIMET.title) {
        result = value * 10;
      } else if (targetUnit.title == PIXEL.title) {
        result = value * (1 / pointToCm) * 4 / 3;
      }
    }
    // mm
    if (inputUnit.title == MINIMET.title) {
      if (targetUnit.title == CENTIMET.title) {
        result = value / 10;
      } else if (targetUnit.title == POINT.title) {
        result = value * (1 / (pointToCm * 10));
      } else if (targetUnit.title == INCH.title) {
        result = value * (1 / (inchToCm * 10));
      } else if (targetUnit.title == PIXEL.title) {
        result = value * (1 / (pointToCm * 10)) * 4 / 3;
      }
    }
    // PIXEL
    if (inputUnit.title == PIXEL.title) {
      if (targetUnit.title == CENTIMET.title) {
        result = value * (pointToCm * 3 / 4);
      } else if (targetUnit.title == POINT.title) {
        result = value * 3 / 4;
      } else if (targetUnit.title == INCH.title) {
        result = value * pointToInch * 3 / 4;
      } else if (targetUnit.title == MINIMET.title) {
        result = value * (pointToCm * 3 / 4) * 10;
      }
    }
    return result;
  }

  /// Chuyển đổi đơn vị hiện tại sang inch  với dpi
  static double convertUnitToInchWithDPI(
    Unit inputUnit,
    double inputValue,
    double dpi,
    bool isUseForPrint,
  ) {
    double inch; 
    if (isUseForPrint) {
      if (inputUnit == PIXEL) {
        inch = inputValue / dpi;
      } else if (inputUnit == POINT) {
        inch = inputValue / 72.0;
      } else if (inputUnit == MINIMET) {
        inch = inputValue / 25.4;
      } else if (inputUnit == CENTIMET) {
        inch = inputValue / 2.54;
      } else if (inputUnit == INCH) {
        inch = inputValue;
      } else {
        throw Exception("Unsupported unit");
      }
    } else {
      // Chuyển đổi đơn vị thuần túy → inch, không dùng DPI
      inch = convertUnit(inputUnit, INCH, inputValue);
    }

    return inch;
  }

  /// Chuyển đổi đơn vị hiện tại sang điểm point (IN ẤN) với dpi
  static double convertUnitToPrintPointWithDPI(
    Unit inputUnit,
    double inputValue,
    double dpi,
  ) {
    double inch;

    if (inputUnit == PIXEL) {
      inch = inputValue / dpi; // px → inch
    } else if (inputUnit == POINT) {
      inch = inputValue / 72.0; // pt → inch
    } else if (inputUnit == MINIMET) {
      inch = inputValue / 25.4; // mm → inch
    } else if (inputUnit == CENTIMET) {
      inch = inputValue / 2.54; // cm → inch
    } else if (inputUnit == INCH) {
      inch = inputValue; // inch → inch
    } else {
      throw Exception("Unsupported unit");
    }

    return inch * 72.0; // inch → point
  }

  static Unit getUnitByTitle(String value) {
    switch (value) {
      case "mm":
        return MINIMET;
      case "cm":
        return CENTIMET;
      case "inch":
        return INCH;
      case "px":
      case "pixel":
        return PIXEL;
      case "point":
      case "pt":
        return POINT;
      default:
        throw Exception("KHONG CO UNIT TUONG UNNG");
    }
  }

  static Future<List<CountryModel>?> convertCountryToModel() async {
    try {
      // cach 1
      // final List<String> list= json.decode(response).cast<String>().toList();
      // cach 2

      //// get country list
      final String responseCountry =
          await rootBundle.loadString('assets/datas/country_list.json');
      final List<String> listCountry =
          json.decode(responseCountry).cast<String>();

      // get passport list
      final String responsePassport =
          await rootBundle.loadString('assets/datas/passport_list.json');
      final List<Map<String, dynamic>> listPassportData =
          json.decode(responsePassport).cast<Map<String, dynamic>>().toList();

      // get flags list
      final String responseFlags =
          await rootBundle.loadString('assets/datas/flags.json');
      final List<Map<String, dynamic>> listFlagsData =
          json.decode(responseFlags).cast<Map<String, dynamic>>().toList();

      List<CountryModel> results = [];

      for (int i = 0; i < listCountry.length; i++) {
        CountryModel countryModel =
            CountryModel(id: i, title: listCountry[i], listPassportModel: []);
        List<PassportModel> listPassport = [];
        for (int y = 0; y < listPassportData.length; y++) {
          final item = listPassportData[y];
          if (listPassportData[y]["country"] == listCountry[i]) {
            Unit unit = getUnitByTitle(item["sizeUnit"]);
            listPassport.add(
              PassportModel(
                id: y,
                title: item["name"],
                height: double.parse((item["size"][1]).toString()),
                width: double.parse((item["size"][0]).toString()),
                ratioHead: double.parse((item["upper"]).toString()),
                ratioEyes: (item["lower"] + item["upper"]) / 2,
                ratioChin: double.parse((item["lower"]).toString()),
                unit: unit,
              ),
            );
          }
        }
        countryModel.listPassportModel = listPassport;
        results.add(countryModel);
      }

      for (int i = 0; i < results.length; i++) {
        for (int y = 0; y < listFlagsData.length; y++) {
          if (results[i].title == listFlagsData[y]["name"]) {
            results[i].emoji = listFlagsData[y]["emoji"];
          }
        }
      }
      return results;
    } catch (e) {
      print("convertCountryToModel error ${e}");
      consolelog("convertCountryToModel error ${e}");
      return null;
    }
  }

  static double convertMappingRange(
    double progress,
    double minSrc,
    double maxSrc,
    double minDst,
    double maxDst,
  ) {
    return (progress - minSrc) / (maxSrc - minSrc) * (maxDst - minDst) + minDst;
  }
}
