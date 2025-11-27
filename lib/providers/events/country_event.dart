import 'package:passport_photo_2/models/country_passport_model.dart';

abstract class CountryEvent {
  CountryEvent();
}

class UpdateCountryEvent extends CountryEvent {
  final List<CountryModel> listCountry;

  UpdateCountryEvent({required this.listCountry});
}
