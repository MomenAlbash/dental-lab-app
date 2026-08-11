import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/home/ui/home_page.dart';
import 'package:flutter/material.dart';

/// The app's main screen after login — the home dashboard.
///
/// Navigation happens through the drawer (and the dashboard's own shortcut
/// cards), not a bottom bar: every feature in the app is a plain list screen
/// reached that way, and cases used to be the odd one out with its own tabbed
/// shell.
class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
      appBar: GlassAppBar(
        title: Text(
          'الرئيسية',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: const SafeArea(child: HomeBody()),
    );
  }
}
