import 'package:passport_photo_2/models/country_passport_model.dart';

abstract class CountryState {
  final List<CountryModel> listCountry;

  CountryState({
    required this.listCountry,
  });
}

class InitCountryState extends CountryState {
  InitCountryState() : super(listCountry: []);
}

class UpdateCountryState extends CountryState {
  final List<CountryModel> listCountry;

  UpdateCountryState({required this.listCountry})
      : super(listCountry: listCountry);
}
