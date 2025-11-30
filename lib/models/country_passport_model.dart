import 'package:flutter/rendering.dart';
import 'package:pass1_/commons/constants.dart';

class Unit {
  final int id;
  final String title;
  final String value;
  Unit({required this.id, this.title = "", this.value = ""});
  @override
  String toString() {
    return "Unit: (title: $title, value: $value)";
  }
}

///
/// ratioHead, ratioEyes, ratioChinr: Căn theo cạnh cuối cùng của ảnh
///
class PassportModel {
  int id;
  String title;
  double height;
  double width;
  double ratioHead;
  double ratioEyes;
  double ratioChin;
  Unit unit;

  PassportModel({
    required this.id,
    required this.title,
    required this.height,
    required this.width,
    required this.ratioHead,
    required this.ratioEyes,
    required this.ratioChin,
    required this.unit,
  });

  Size get size => Size(width, height);

  PassportModel copyWith({
    String? title,
    double? height,
    double? width,
    double? ratioHead,
    double? ratioEyes,
    double? ratioChin,
    Unit? unit,
  }) {
    return PassportModel(
      id: id,
      title: title ?? this.title,
      height: height ?? this.height,
      width: width ?? this.width,
      ratioHead: ratioHead ?? this.ratioHead,
      ratioEyes: ratioEyes ?? this.ratioEyes,
      ratioChin: ratioChin ?? this.ratioChin,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return "id: $id, title: $title, height: $height, width: $width, ratioHead: $ratioHead, ratioEyes: $ratioEyes, ratioChin: $ratioChin, unit: ${unit}";
  }
}

class CountryModel {
  int id;
  String title;
  List<PassportModel> listPassportModel;
  int indexSelectedPassport;
  String emoji;

  CountryModel({
    required this.id,
    required this.title,
    required this.listPassportModel,
    this.emoji = "",
    this.indexSelectedPassport = 0,
  });

  CountryModel copyWith({
    int? indexSelectedPassport,
    List<PassportModel>? listPassportModel,
  }) {
    return CountryModel(
      id: id,
      title: title,
      listPassportModel: listPassportModel ?? this.listPassportModel,
      emoji: emoji,
      indexSelectedPassport:
          indexSelectedPassport ?? this.indexSelectedPassport,
    );
  }

  PassportModel get currentPassport => listPassportModel[indexSelectedPassport];

  @override
  String toString() {
    return "CountryModel(id: $id, title: $title, listPassportModel.length: ${listPassportModel.length}, selectedPassport: $indexSelectedPassport)";
  }

  String getInfor() {
    return "id: $id, title: $title, listPassportModel.length: ${listPassportModel.length}, selectedPassport: $indexSelectedPassport";
  }

  static CountryModel createCustomCountryModel({
    required double width,
    required double height,
    required double ratioHead,
    required double ratioEyes,
    required double ratioChin,
    required Unit currentUnit,
  }) {
    return CountryModel(
      id: ID_CUSTOM_COUNTRY_MODEL,
      title: "Country",
      listPassportModel: [
        PassportModel(
          id: ID_CUSTOM_COUNTRY_MODEL,
          title: "Custom ${width}x$height${currentUnit.title}",
          height: height,
          width: width,
          ratioHead: ratioHead,
          ratioEyes: ratioEyes,
          ratioChin: ratioChin,
          unit: currentUnit,
        ),
      ],
    );
  }
}
