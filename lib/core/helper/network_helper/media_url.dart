/// Host the API serves uploaded media (doctor images, attachments) from. The
/// API base is `.../api/clinic/`, but stored `imagePath` / `filePath` values
/// are relative to the site root.
const String _mediaBaseUrl = 'https://dental-lab.runasp.net/';

/// Resolves a stored media [path] into an absolute URL. Returns `null` for a
/// null/empty path, and passes through values that are already absolute.
String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$_mediaBaseUrl${path.startsWith('/') ? path.substring(1) : path}';
}
