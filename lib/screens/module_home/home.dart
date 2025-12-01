import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/convert.dart';
import 'package:pass1_/helpers/file_helpers.dart';
import 'package:pass1_/helpers/share_preferences_helpers.dart';
import 'package:pass1_/models/country_passport_model.dart';
import 'package:pass1_/models/project_model.dart';
import 'package:pass1_/providers/blocs/country_bloc.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/events/country_event.dart';
import 'package:pass1_/screens/module_home/platforms/home_phone.dart';
import 'package:pass1_/screens/module_home/platforms/home_tablet.dart';
import 'package:pass1_/widgets/w_text.dart';

class HomePageMain extends StatefulWidget {
  const HomePageMain({super.key});

  @override
  State<HomePageMain> createState() => _HomePageMainState();
}

class _HomePageMainState extends State<HomePageMain> {
  bool _isWillPopClicked = false;

  late ProjectModel _projectModel;
  Future<bool> _onWillPop() async {
    if (_isWillPopClicked) return true;
    _isWillPopClicked = true;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: WTextContent(value: "Click again to exit!!"),
        margin: const EdgeInsets.only(bottom: 30, right: 10, left: 10),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isWillPopClicked = false;
      });
    });
    return false;
  }

  @override
  void initState() {
    super.initState();
    _projectModel = ProjectModel();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _initSelectedCountry();
      setState(() {});
      deleteAllTempFile();
    });
  }

  Future<void> _initSelectedCountry() async {
    final stopWatch = Stopwatch();
    stopWatch.start();
    // final countryModels =
    //     await FlutterConvert.convertCountryToModel();
    // if (countryModels != null) {
    //   // ignore: use_build_context_synchronously
    //   BlocProvider.of<CountryBloc>(context)
    //       .add(UpdateCountryEvent(listCountry: countryModels));
    // }
    // // ignore: use_build_context_synchronously
    // SharedPreferencesHelper().updateGetStarted(true);
    List<CountryModel>? listCountryModel =
        await FlutterConvert.convertCountryToModel();

    if (listCountryModel != null) {
      // ignore: use_build_context_synchronously
      BlocProvider.of<CountryBloc>(
        context,
        listen: false,
      ).add(UpdateCountryEvent(listCountry: listCountryModel));
      List<String>? country = await SharedPreferencesHelper()
          .getCountryPassport();
      if (country == null) {
        _projectModel.countryModel = listCountryModel
            .where((element) => element.title == DEFAULT_PASSPORT_COUNTRY)
            .toList()
            .first;
      } else {
        // custom case + normal case
        if (country[0] == ID_CUSTOM_COUNTRY_MODEL.toString()) {
          Unit currentUnit;
          //  INCH: 0, CENTIMET:1, MINIMET: 2, POINT: 3, PIXEL: 4
          switch ((int.parse(country[7]))) {
            case 0:
              currentUnit = INCH;
              break;
            case 1:
              currentUnit = CENTIMET;
              break;
            case 2:
              currentUnit = MINIMET;
              break;
            case 3:
              currentUnit = POINT;
              break;
            default:
              currentUnit = PIXEL;
              break;
          }
          _projectModel.countryModel = CountryModel.createCustomCountryModel(
            width: (double.parse(country[2])),
            height: (double.parse(country[3])),
            ratioHead: (double.parse(country[4])),
            ratioEyes: (double.parse(country[5])),
            ratioChin: (double.parse(country[6])),
            currentUnit: currentUnit,
          );
        } else {
          for (int i = 0; i < listCountryModel.length; i++) {
            if (listCountryModel[i].id == int.parse(country[0])) {
              _projectModel.countryModel = listCountryModel[i];
              for (
                int y = 0;
                y < _projectModel.countryModel!.listPassportModel.length;
                y++
              ) {
                if (_projectModel.countryModel!.listPassportModel[y].id ==
                    int.parse(country[1])) {
                  _projectModel.countryModel!.indexSelectedPassport = y;
                }
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DeviceType deviceType = BlocProvider.of<DevicePlatformCubit>(
      context,
      listen: true,
    ).getPlatform;
    Widget body = const SizedBox();
    switch (deviceType) {
      case DeviceType.Phone:
        if (1 == 1) {
          body = HomePagePhone(project: _projectModel);
        } else {
          // body = const WTestScreen();
        }
      case DeviceType.Tablet:
        body = HomePageTablet(project: _projectModel);
    }
    return WillPopScope(
      onWillPop: () async {
        return await _onWillPop();
      },
      child: body,
    );
  }
}
