import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
import 'package:dental_lab_app/features/scan_storage/data/repos/scan_storage_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ScanStorageState {
  const ScanStorageState();
}

class ScanStorageLoading extends ScanStorageState {
  const ScanStorageLoading();
}

class ScanStorageError extends ScanStorageState {
  const ScanStorageError(this.message);
  final String message;
}

class ScanStorageLoaded extends ScanStorageState {
  const ScanStorageLoaded({
    required this.storage,
    this.pendingArchive = const [],
    this.isBusy = false,
  });

  final ScanStorageModel storage;

  /// Scans waiting to be copied to the laboratory's NAS. Loaded alongside the
  /// figures because the NAS route is the answer whenever the sweep has
  /// nothing left it may take.
  final List<PendingNasArchiveModel> pendingArchive;

  final bool isBusy;

  ScanStorageLoaded copyWith({bool? isBusy}) => ScanStorageLoaded(
    storage: storage,
    pendingArchive: pendingArchive,
    isBusy: isBusy ?? this.isBusy,
  );
}

class ScanStorageActionError extends ScanStorageState {
  const ScanStorageActionError(this.message);
  final String message;
}

/// What a run actually did, surfaced so the screen can report it honestly.
class ScanStorageRunFinished extends ScanStorageState {
  const ScanStorageRunFinished(this.result);
  final ScanRetentionRunResultModel result;
}

/// The laboratory's scan storage, and the two ways to free it.
class ScanStorageCubit extends Cubit<ScanStorageState> {
  ScanStorageCubit(this._repo) : super(const ScanStorageLoading());

  final ScanStorageRepo _repo;

  Future<void> load() async {
    emit(const ScanStorageLoading());

    final storage = await _repo.getStorage();
    if (isClosed) return;

    await storage.fold(
      (failure) async => emit(ScanStorageError(failure.errorMessage)),
      (value) async {
        // Secondary: a failed pending-archive fetch should not replace the
        // whole screen with an error, since the figures above it are what the
        // user came for.
        final pending = await _repo.getPendingArchive();
        if (isClosed) return;

        emit(
          ScanStorageLoaded(
            storage: value,
            pendingArchive: pending.fold((_) => const [], (list) => list),
          ),
        );
      },
    );
  }

  /// Runs the retention sweep now.
  Future<void> runSweep() => _run(_repo.runSweep);

  /// Deletes one file's bytes. The row stays.
  Future<void> removeFile(String scanId) =>
      _run(() => _repo.removeFile(scanId));

  /// Confirms that copies are on the NAS, which is what frees the bytes.
  ///
  /// Sent only once the lab's own tool has written and verified them —
  /// confirming ahead of the copy would lose a scan every time it failed.
  Future<void> confirmArchive(List<ConfirmNasArchiveItemModel> items) {
    if (items.isEmpty) return Future.value();
    return _run(
      () => _repo.confirmArchive(ConfirmNasArchiveRequestModel(items: items)),
    );
  }

  Future<void> _run(
    Future<Either<Failure, ScanRetentionRunResultModel>> Function() request,
  ) async {
    final current = state;
    if (current is ScanStorageLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ScanStorageActionError(failure.errorMessage));
        if (current is ScanStorageLoaded) emit(current.copyWith(isBusy: false));
      },
      (value) async {
        // The result is emitted before the reload so the screen can say what
        // the run did — a reload alone shows new numbers with no account of
        // how they got there, and `stillOverBudget` would go unsaid.
        emit(ScanStorageRunFinished(value));
        await load();
      },
    );
  }
}
