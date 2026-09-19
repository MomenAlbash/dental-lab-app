import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class BroadcastState {
  const BroadcastState();
}

class BroadcastIdle extends BroadcastState {
  const BroadcastIdle();
}

class BroadcastSending extends BroadcastState {
  const BroadcastSending();
}

class BroadcastSent extends BroadcastState {
  const BroadcastSent(this.audience);
  final BroadcastAudience audience;
}

class BroadcastFailed extends BroadcastState {
  const BroadcastFailed(this.message);
  final String message;
}

/// Pushes one notification to many people at once.
///
/// **The one write in this app with no undo** — there is no recall endpoint,
/// and the push has left the server by the time the response arrives. That is
/// why the send is a single explicit call with no optimistic state: nothing
/// here should ever make a user think a send is reversible.
class BroadcastCubit extends Cubit<BroadcastState> {
  BroadcastCubit(this._repo) : super(const BroadcastIdle());

  final NotificationsRepo _repo;

  Future<void> send(BroadcastNotificationRequestModel body) async {
    // Refused here as well as in the form: "specific users" with nobody chosen
    // would reach whatever the server makes of an empty list — possibly
    // nobody, which looks like a delivery failure rather than a mistake.
    if (!body.isValid) {
      emit(const BroadcastFailed('أكمل العنوان والنص واختر المستلمين'));
      emit(const BroadcastIdle());
      return;
    }

    emit(const BroadcastSending());

    final result = await _repo.broadcast(body);
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(BroadcastFailed(failure.errorMessage));
        emit(const BroadcastIdle());
      },
      (_) => emit(BroadcastSent(body.audience)),
    );
  }
}
