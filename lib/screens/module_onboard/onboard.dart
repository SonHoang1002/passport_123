import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pass1_/helpers/share_preferences_helpers.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/navigator_route.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/screens/module_home/home.dart';
import 'package:pass1_/screens/module_onboard/widgets/w_carousel_indicator.dart';
import 'package:pass1_/widgets/w_button.dart';
import 'package:pass1_/widgets/w_instruction_item.dart';

class OnBoardPage extends StatefulWidget {
  const OnBoardPage({super.key});

  @override
  State<OnBoardPage> createState() => _OnBoardPageState();
}

class _OnBoardPageState extends State<OnBoardPage> {
  int _indexCurrentCarousel = 0;
  final CarouselSliderController _carouselSliderController =
      CarouselSliderController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        BlocProvider.of<ThemeBloc>(context, listen: true).isDarkMode;
    return Scaffold(
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            bottom: MediaQuery.of(context).padding.bottom + 20),
        alignment: Alignment.center,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CarouselSlider.builder(
                  itemCount: LIST_INSTRUCTION_MODEL.length,
                  itemBuilder: (context, currentIndex, afterIndex) {
                    return InstructionItem(
                      index: currentIndex,
                      model: LIST_INSTRUCTION_MODEL[currentIndex],
                    );
                  },
                  carouselController: _carouselSliderController,
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 1.2,
                    initialPage: _indexCurrentCarousel,
                    enableInfiniteScroll: false,
                    autoPlayCurve: CUBIC_CURVE,
                    onPageChanged: (index, reason) {
                      _onPageChanged(index);
                    },
                    scrollDirection: Axis.horizontal,
                  ),
                ),
                WCarouselIndicator(
                  currentIndex: _indexCurrentCarousel,
                  listInstructionModel: LIST_INSTRUCTION_MODEL,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: WButtonFilled(
                width: 287,
                message: _indexCurrentCarousel != 2 ? "Next" : "Get Started",
                backgroundColor: isDarkMode ? primaryDark1 : primaryLight1,
                height: 56,
                textColor: white,
                textSize: 15,
                textLineHeight: 18.75,
                borderRadius: 999,
                onPressed: () async {
                  if (_indexCurrentCarousel == 2) {
                    pushAndReplaceToNextScreen(context, const HomePageMain());
                    // final countryModels =
                    //     await FlutterConvert.convertCountryToModel();
                    // if (countryModels != null) {
                    //   // ignore: use_build_context_synchronously
                    //   BlocProvider.of<CountryBloc>(context)
                    //       .add(UpdateCountryEvent(listCountry: countryModels));
                    // }
                    // // ignore: use_build_context_synchronously
                    SharedPreferencesHelper().updateGetStarted(true);
                  } else {
                    _onPageChanged(_indexCurrentCarousel + 1);
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _indexCurrentCarousel = index;
      _carouselSliderController.animateToPage(_indexCurrentCarousel,
          curve: CUBIC_CURVE);
    });
  }
}
