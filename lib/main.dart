import 'dart:io';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_image_filters/flutter_image_filters.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/extension.dart';
import 'package:pass1_/commons/shaders/black_to_transparent_shader.dart';
import 'package:pass1_/commons/shaders/custom_exposure_shader.dart';
import 'package:pass1_/commons/shaders/brightness_custom.dart';
import 'package:pass1_/commons/shaders/combine_shader.dart';
import 'package:pass1_/commons/shaders/custom_constrast_shader.dart';
import 'package:pass1_/commons/shaders/custom_highlight_shader.dart';
import 'package:pass1_/commons/shaders/custom_saturation_shader.dart';
import 'package:pass1_/commons/shaders/custom_shadow_shader.dart';
import 'package:pass1_/commons/shaders/custom_sharpen_shader.dart';
import 'package:pass1_/helpers/firebase_helpers.dart';
import 'package:pass1_/helpers/share_preferences_helpers.dart';
import 'package:pass1_/material_with_them.dart';
import 'package:pass1_/providers/blocs/adjust_subject_bloc.dart';
import 'package:pass1_/providers/blocs/country_bloc.dart';
import 'package:pass1_/providers/blocs/device_platform_bloc.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); //options: DefaultFirebasePlatform.currentPlatform
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  // ignore: unused_local_variable
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  await FlutterDisplayMode.setHighRefreshRate();
  // ignore: unused_local_variable
  final DisplayMode m = await FlutterDisplayMode.active;

  FlutterImageFilters.register<CombineShaderCustomConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/combine_shaders.frag'),
  );
  FlutterImageFilters.register<CustomSharpenShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_sharpen.frag'),
  );
  FlutterImageFilters.register<BlackToTransparentConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/black_to_transparent.frag'),
  );
  // FlutterImageFilters.register<BrightnessBackgroundShaderConfiguration>(
  //     () => FragmentProgram.fromAsset('shaders/brightness_background.frag'));
  FlutterImageFilters.register<CustomContrastShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_constrast.frag'),
  );
  // FlutterImageFilters.register<CustomWhiteBalanceShaderConfiguration>(
  //     () => FragmentProgram.fromAsset('shaders/custom_white_balance.frag'));
  FlutterImageFilters.register<CustomBrightnessShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_brightness.frag'),
  );
  FlutterImageFilters.register<CustomHighlightShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_highlight.frag'),
  );
  FlutterImageFilters.register<CustomShadowShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_shadow.frag'),
  );
  // FlutterImageFilters.register<CustomHighlightShadowShaderConfiguration>(
  //     () => FragmentProgram.fromAsset('shaders/custom_highlight_shadow.frag'));
  FlutterImageFilters.register<CustomExposureShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_exposure.frag'),
  );
  FlutterImageFilters.register<CustomSaturationShaderConfiguration>(
    () => ui.FragmentProgram.fromAsset('shaders/custom_saturation.frag'),
  );

  runApp(MyApp(isOnBoard: await _isOnBoard()));
  // check dark mode
  Brightness themeMode =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  bool darkMode = themeMode == Brightness.dark;
  redoSystemStyle(darkMode);
  // add new user who are using this app
  await FirebaseHelpers().sendFirebaseAndroidId();
}

Future<bool> _isOnBoard() async {
  final data = MediaQueryData.fromView(
    ui.PlatformDispatcher.instance.views.first,
  );
  if (data.size.shortestSide < 550) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  bool isOnBoard = true;
  if (await SharedPreferencesHelper().getGetStarted() == true) {
    isOnBoard = false;
  }
  return isOnBoard;
}

class MyApp extends StatelessWidget {
  final bool isOnBoard;
  const MyApp({super.key, required this.isOnBoard});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: ((context) => ThemeBloc())),
        BlocProvider<AdjustSubjectBloc>(
          create: ((context) => AdjustSubjectBloc()),
        ),
        BlocProvider<CountryBloc>(create: ((context) => CountryBloc())),
        BlocProvider<DevicePlatformCubit>(
          create: ((context) => DevicePlatformCubit()),
        ),
      ],
      child: MaterialWithTheme(isOnBoard: isOnBoard),
    );
  }
}

Future<void> redoSystemStyle(bool darkMode) async {
  if (Platform.isAndroid) {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    final bool edgeToEdge = androidInfo.version.sdkInt >= 29;
    // The commented out check below isn't required anymore since https://github.com/flutter/engine/pull/28616 is merged
    // if (edgeToEdge)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: darkMode ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: edgeToEdge
            ? Colors.transparent
            : darkMode
            ? Colors.black
            : Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: darkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  } else {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }
}

class TestSharpenWidget extends StatefulWidget {
  const TestSharpenWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TestSharpenWidgetState createState() => _TestSharpenWidgetState();
}

class _TestSharpenWidgetState extends State<TestSharpenWidget> {
  late CustomSharpenShaderConfiguration _customSharpenShaderConfiguration;
  late TextureSource _textureSource;
  bool _isLoading = true;
  bool? _isGenerating = null;
  ui.Image? _generatedRawImage = null;
  double sliderMin = -4;
  double sliderMax = 4;

  double get sharpen => _customSharpenShaderConfiguration.sharpen;
  String? tempPath = null;
  @override
  void initState() {
    _customSharpenShaderConfiguration = CustomSharpenShaderConfiguration()
      ..sharpen = 0.0;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _textureSource = await TextureSource.fromAsset(
        'assets/images/meo_cau_co.jpg',
      );
      tempPath =
          "${(await getExternalStorageDirectory())!.path}/temp_sharpen.png";
      _isLoading = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    sliderMin = -10;
    sliderMax = 10;

    return Scaffold(
      appBar: AppBar(title: const Text('Sharpen Test')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ImageShaderPreview(
                  configuration: _customSharpenShaderConfiguration,
                  texture: _textureSource,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sharpen:',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            sharpen.roundWithUnit(fractionDigits: 2),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Slider(
                        value: sharpen,
                        min: sliderMin,
                        max: sliderMax,
                        onChanged: (value) {
                          setState(() {
                            _customSharpenShaderConfiguration.sharpen = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    _isGenerating = true;
                    setState(() {});
                    _generatedRawImage = await _customSharpenShaderConfiguration
                        .export(_textureSource, _textureSource.size);
                    Uint8List uint8listBg =
                        (await _generatedRawImage!.toByteData(
                          format: ui.ImageByteFormat.png,
                        ))!.buffer.asUint8List();
                    if (tempPath != null) {
                      await File(tempPath!).writeAsBytes(uint8listBg);
                    }
                    _isGenerating = false;
                    setState(() {});
                  },
                  child: Container(
                    height: 100,
                    width: 120,
                    color: red,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Center(
                      child: _isGenerating != null
                          ? _isGenerating!
                                ? const CircularProgressIndicator()
                                :
                                  //  RawImage(
                                  //     image: _generatedRawImage!,
                                  Image.file(File(tempPath!), fit: BoxFit.cover)
                          : const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
