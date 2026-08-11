import 'package:dental_lab_app/core/connectivity/connectivity_cubit.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wraps the whole app and overlays a slim "no internet" banner above
/// [child] whenever [ConnectivityCubit] flips offline — a passive, app-wide
/// indicator instead of interrupting any single screen.
class OfflineBannerWrapper extends StatelessWidget {
  const OfflineBannerWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<ConnectivityCubit>(),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: BlocBuilder<ConnectivityCubit, bool>(
                builder: (context, isOnline) {
                  if (isOnline) return const SizedBox.shrink();
                  return const _OfflineBanner();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatefulWidget {
  const _OfflineBanner();

  @override
  State<_OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<_OfflineBanner> {
  bool _isRetrying = false;

  Future<void> _onRetry() async {
    setState(() => _isRetrying = true);
    await context.read<ConnectivityCubit>().retry();
    if (mounted) setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    // A Material ancestor is required here since this banner is injected
    // above the routed page (via MaterialApp.router's builder), outside any
    // Scaffold — InkWell below needs it to paint its tap feedback.
    return Material(
      color: AppColorsManger.error,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _isRetrying ? null : _onRetry,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRetrying)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.refresh, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'إعادة المحاولة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
