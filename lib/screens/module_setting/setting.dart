import 'package:android_id/android_id.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pass1_/commons/colors.dart';
import 'package:pass1_/commons/constants.dart';
import 'package:pass1_/helpers/log_custom.dart';
import 'package:pass1_/widgets/bottom_sheet/show_bottom_sheet.dart';
import 'package:pass1_/providers/blocs/theme_bloc.dart';
import 'package:pass1_/providers/states/theme_state.dart';
import 'package:pass1_/screens/module_instruction/instruction.dart';
import 'package:pass1_/widgets/w_button.dart';
import 'package:pass1_/widgets/w_spacer.dart';
import 'package:pass1_/widgets/w_text.dart';
import 'package:share_plus/share_plus.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  State<Setting> createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  late Size _size;
  final double _padding = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {});
  }

  void _onFeedback() async {
    try {
      var id = await const AndroidId().getId();
      final Email email = Email(
        subject: 'Passport Photo 2.0 Android Feedback: $id',
        recipients: ['tapuniverse@gmail.com'],
        isHTML: false,
      );
      await FlutterEmailSender.send(email);
    } catch (e) {
      debugPrint("_onFeedback error: ${e}");
    }
  }

  void _onShare() async {
    try {
      await SharePlus.instance.share(
        ShareParams(uri: Uri.parse(SHARE_APP_LINK)),
      );
    } catch (e) {
      debugPrint("_onShare error: ${e}");
    }
  }

  void _onPassportInstruction() async {
    showCustomBottomSheetWithClose(
      context: context,
      child: const Instructions(),
      height: _size.height * 0.94,
    );
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.sizeOf(context);
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        bool isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          height: _size.height * 0.9,
          child: Column(
            children: [
              // title
              // change themes
              // upgrade passport photo
              // instruction
              // feedback, share
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _padding),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// title
                          WTextContent(
                            value: "Settings",
                            textSize: 32,
                            textLineHeight: 38,
                            textColor: Theme.of(
                              context,
                            ).textTheme.displayLarge!.color,
                            textAlign: TextAlign.start,
                          ),
                          // const SizedBox()

                          // // change themes
                          // GestureDetector(
                          //     onTap: () async {
                          //       context.read<ThemeBloc>().add(UpdateThemeEvent());
                          //     },
                          //     child: Container(
                          //         height: 30,
                          //         width: 30,
                          //         decoration: BoxDecoration(
                          //             borderRadius: BorderRadius.circular(15),
                          //             color: Theme.of(context).canvasColor),
                          //         child: Icon(
                          //             isDarkMode
                          //                 ? FontAwesomeIcons.sun
                          //                 : FontAwesomeIcons.moon,
                          //             size: 15,
                          //             color: Colors.red))),
                        ],
                      ),
                    ),
                    WSpacer(height: 30),
                    // upgrade passport photo
                    // Container(
                    //   decoration: BoxDecoration(
                    //     border: Border.all(
                    //       width: 3,
                    //       color: isDarkMode ? primaryDark1 : primaryLight1,
                    //     ),
                    //     color: !isDarkMode ? primaryLight01 : primaryDark01,
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: GestureDetector(
                    //     onTap: _onPassportInstruction,
                    //     child: Container(
                    //       color: transparent,
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 15,
                    //         vertical: 15,
                    //       ),
                    //       child: _buildSettingUpgrade(
                    //         context: context,
                    //         subTitle: "Save high quality photo, remove ads,...",
                    //         title: "Passport Photo+",
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // WSpacer(height: 30),
                    //instruction
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: Theme.of(context)
                              .tabBarTheme
                              .unselectedLabelColor!, //isDarkMode ? white005 : black005,
                        ),
                        color: isDarkMode ? white003 : black003,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: GestureDetector(
                        onTap: _onPassportInstruction,
                        child: Container(
                          color: transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: _buildSettingItem(
                            // context: context,
                            prefixMediaSrc:
                                PATH_PREFIX_ICON +
                                (isDarkMode
                                    ? "icon_instruction_dark.png"
                                    : "icon_instruction_light.png"),
                            iconColor: isDarkMode ? white05 : black05,
                            title: "Passport photo instruction",
                          ),
                        ),
                      ),
                    ),
                    WSpacer(height: 30),
                    // feedback, share
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 1,
                          color: Theme.of(context)
                              .tabBarTheme
                              .unselectedLabelColor!, // isDarkMode ? white005 : black005,
                        ),
                        color: isDarkMode ? white003 : black003,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _onFeedback,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: _buildSettingItem(
                                // context: context,
                                prefixMediaSrc:
                                    PATH_PREFIX_ICON +
                                    (isDarkMode
                                        ? "icon_feedback_dark.png"
                                        : "icon_feedback_light.png"),
                                iconColor: isDarkMode ? white05 : black05,
                                title: "Write a feedback",
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _onShare,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Container(
                                child: _buildSettingItem(
                                  // context: context,
                                  prefixMediaSrc:
                                      PATH_PREFIX_ICON +
                                      (isDarkMode
                                          ? "icon_share_dark.png"
                                          : "icon_share_light.png"),
                                  iconColor: isDarkMode ? white05 : black05,
                                  title: "Share this app",
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingUpgrade({
    required BuildContext context,
    required String title,
    required String subTitle,
    Key? key,
  }) {
    bool isDarkMode = BlocProvider.of<ThemeBloc>(context).isDarkMode;
    return Row(
      key: key,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WTextContent(
                value: title,
                textSize: 17,
                textLineHeight: 20.29,
                textFontWeight: FontWeight.w600,
                textColor: isDarkMode ? primaryDark1 : primaryLight1,
              ),
              WSpacer(width: 10),
              AutoSizeText(
                subTitle,
                maxFontSize: 13,
                minFontSize: 8,
                maxLines: 2,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? white05 : black05,
                  height: 15.51 / 13,
                  fontFamily: FONT_GOOGLESANS,
                ),
              ),
            ],
          ),
        ),
        WButtonFilled(
          message: "Upgrade",
          height: 36,
          width: 85,
          textSize: 13,
          textLineHeight: 15.51,
          backgroundColor: isDarkMode ? primaryDark1 : primaryLight1,
          borderRadius: 10,
          onPressed: () {
            consolelog("Upgrade");
          },
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    // required BuildContext context,
    required String prefixMediaSrc,
    required String title,
    Key? key,
    String? content,
    Function()? onTapContent,
    Color? colorContent,
    Color? iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(prefixMediaSrc, height: 40, width: 40),
            WSpacer(width: 10),
            WTextContent(
              value: title,
              textSize: 15,
              textLineHeight: 20,
              textFontWeight: FontWeight.w500,
              textColor: Theme.of(context).textTheme.displayLarge!.color,
            ),
          ],
        ),
        content != null && key != null
            ? GestureDetector(
                onTap: onTapContent,
                child: WTextContent(
                  key: key,
                  value: content,
                  textSize: 15,
                  textLineHeight: 20,
                  textFontWeight: FontWeight.w500,
                  textColor:
                      colorContent ??
                      Theme.of(context).textTheme.displayLarge!.color,
                ),
              )
            : Icon(FontAwesomeIcons.chevronRight, size: 15, color: iconColor),
      ],
    );
  }
}
