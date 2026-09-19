import 'dart:async';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/notifications/push_notification_service.dart';
import 'package:dental_lab_app/core/router/app_router.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/branding/logic/branding_cubit.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/offline_banner_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Api.init();
  await CacheHelper.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await setupGetIt();
  await getIt<PushNotificationService>().initialize();

  if (CacheHelper.getData(key: CacheKeys.token) != null) {
    getIt<PushNotificationService>().requestPermissionAndRegister();
  }

  Api.onSessionExpired = () async {
    await getIt<LoginRepo>().logout();
    AppRouter.router.go(Routes.loginScreen);
  };

  // Before the first frame, and deliberately not awaited-into-a-spinner: the
  // login screen has to be dressed in the laboratory's own colour rather than
  // this app's, and a brand that arrives a moment late simply repaints. The
  // call is anonymous, which is the whole point — there is no token yet.
  unawaited(getIt<BrandingCubit>().load());

  runApp(const DentalLabApp());
}

class DentalLabApp extends StatelessWidget {
  const DentalLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<FontScaleCubit>.value(value: getIt<FontScaleCubit>()),
        BlocProvider<BrandingCubit>.value(value: getIt<BrandingCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          // Rebuilt when the brand lands (and again when it is edited): the
          // laboratory's accent is part of the theme, so everything below is
          // downstream of it.
          final branding = context.watch<BrandingCubit>().state;
          final brandColor = branding.primaryColor;
          return MaterialApp.router(
            title: 'Dental Lab',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.branded(AppTheme.light, brandColor),
            darkTheme: AppTheme.branded(AppTheme.dark, brandColor),
            themeMode: themeMode,
            routerConfig: AppRouter.router,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => BlocBuilder<FontScaleCubit, FontScale>(
              builder: (context, fontScale) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(
                    textScaler: applyFontScale(media.textScaler, fontScale),
                  ),
                  child: OfflineBannerWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
