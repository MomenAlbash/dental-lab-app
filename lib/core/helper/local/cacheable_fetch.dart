import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';

/// Reads a list cached via [CacheHelper.saveJson] (raw JSON, as cached by
/// `ApiService` right after a successful fetch) and decodes it with
/// [fromJson]. Returns `null` if nothing has been cached yet.
List<T>? readCachedList<T>(
  String cacheKey,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = CacheHelper.getJson(key: cacheKey);
  if (raw is! List) return null;
  return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

/// Falls back to the last cached copy of a list instead of surfacing
/// [onFailure] — so a screen keeps showing its last data while offline. If
/// no cache exists yet, returns [onFailure]'s failure unchanged (today's
/// behavior).
Either<Failure, List<T>> fallbackToCache<T>({
  required String cacheKey,
  required T Function(Map<String, dynamic>) fromJson,
  required Failure Function() onFailure,
}) {
  final cached = readCachedList(cacheKey, fromJson);
  if (cached != null) return right(cached);
  return left(onFailure());
}
