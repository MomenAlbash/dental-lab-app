import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/router/app_router.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/offline_banner_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Api.init();
  await CacheHelper.init();
  await setupGetIt();
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
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Dental Lab',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
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
