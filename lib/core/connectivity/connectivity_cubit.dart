import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// App-wide online/offline signal (`true` = online), driven purely by real
/// request outcomes reported by [Api] — not by device-level connectivity
/// checks. OS-level checks (e.g. `connectivity_plus`) were tried first but
/// proved unreliable on some devices (falsely reporting "offline" while on
/// mobile data even though requests were succeeding), so real traffic is the
/// only source of truth here: any response (even an error one) means we're
/// online; a response-less network failure means we're offline.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit() : super(true);

  void markOnline() {
    if (!isClosed && state != true) emit(true);
  }

  void markOffline() {
    if (!isClosed && state != false) emit(false);
  }

  /// Makes a lightweight real request so the "no internet" banner's retry
  /// button can immediately re-check connectivity — [Api]'s interceptor
  /// then calls [markOnline]/[markOffline] based on the outcome.
  Future<void> retry() async {
    try {
      await Api.dio.get('/');
    } catch (_) {
      // Api's interceptor already reported the outcome; nothing else to do.
    }
  }
}
