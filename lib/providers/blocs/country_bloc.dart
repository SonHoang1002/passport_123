import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passport_photo_2/providers/events/country_event.dart';
import 'package:passport_photo_2/providers/states/country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  CountryBloc() : super(InitCountryState()) {
    on<UpdateCountryEvent>((event, emit) {
      emit(UpdateCountryState(listCountry: event.listCountry));
    });
  }
}
