import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/providers/events/country_event.dart';
import 'package:pass1_/providers/states/country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  CountryBloc() : super(InitCountryState()) {
    on<UpdateCountryEvent>((event, emit) {
      emit(UpdateCountryState(listCountry: event.listCountry));
    });
  }
}
