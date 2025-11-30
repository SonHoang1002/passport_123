import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pdf/pdf.dart';

PdfPageFormat? getPdfPageFormat(PassportModel currentPassport) {
  PdfPageFormat? pageFormat = PdfPageFormat.a4;
  double heightPassport = FlutterConvert.convertUnit(
      currentPassport.unit, POINT, currentPassport.height);
  double widthPassport = FlutterConvert.convertUnit(
      currentPassport.unit, POINT, currentPassport.width);
  consolelog(
      "heightPassport: ${heightPassport}, widthPassport: ${widthPassport} ");
  if (heightPassport > PdfPageFormat.a4.height ||
      widthPassport > PdfPageFormat.a4.width) {
    pageFormat = PdfPageFormat.a3;
    if (heightPassport > PdfPageFormat.a3.height ||
        widthPassport > PdfPageFormat.a3.width) {
      pageFormat = A2;
      if (heightPassport > A2.height || widthPassport > A2.width) {
        pageFormat = A1;
        if (heightPassport > A1.height || widthPassport > A1.width) {
          pageFormat = A1;
          if (heightPassport > A0.height || widthPassport > A0.width) {
            pageFormat = null;
          }
        }
      }
    }
  }
  return pageFormat;
}
