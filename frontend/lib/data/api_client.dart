import 'package:dio/dio.dart';

import '../config.dart';
import 'token_store.dart';

/// An error the UI can show directly. Mirrors the backend's ApiError body.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fieldErrors = const {}, this.isNetwork = false});

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  /// True when the server couldn't be reached at all (offline, backend down).
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final fields = (data['fieldErrors'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? const <String, String>{};
        final message = data['message']?.toString();
        return ApiException(
          fields.isNotEmpty && (message == null || message.isEmpty) ? fields.values.first : (message ?? 'Something went wrong'),
          statusCode: error.response?.statusCode,
          fieldErrors: fields,
        );
      }
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return const ApiException('Can’t reach STAMS. Check your connection and try again.', isNetwork: true);
        default:
          return ApiException('Something went wrong (${error.response?.statusCode ?? 'no response'})',
              statusCode: error.response?.statusCode);
      }
    }
    return ApiException(error.toString());
  }
}

/// Thin wrapper around Dio: adds the bearer token and turns every failure into [ApiException].
class ApiClient {
  ApiClient(this._tokens, {void Function()? onUnauthorized})
      : _dio = Dio(BaseOptions(
          baseUrl: kApiBaseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 15),
          contentType: Headers.jsonContentType,
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokens.read();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 && !error.requestOptions.path.startsWith('/api/auth')) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;
  final TokenStore _tokens;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) => _run(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) => _run(() => _dio.put<T>(path, data: body));

  Future<T> patch<T>(String path, {Object? body}) => _run(() => _dio.patch<T>(path, data: body));

  /// GET that may answer 204 No Content (e.g. /api/me/room before a student is housed) - returns null then.
  Future<T?> getOrNull<T>(String path) => _run(() => _dio.get<T?>(path));

  /// Uploads one image as multipart/form-data under the field "file".
  Future<T> upload<T>(String path, List<int> bytes, {required String filename}) => _run(() => _dio.post<T>(
        path,
        data: FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: filename, contentType: _imageType(bytes))}),
        options: Options(contentType: 'multipart/form-data'),
      ));

  /// Sniffs JPEG/PNG/WebP from the first bytes so the backend accepts the upload.
  static DioMediaType _imageType(List<int> b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return DioMediaType('image', 'png');
    if (b.length > 11 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) return DioMediaType('image', 'webp');
    return DioMediaType('image', 'jpeg');
  }

  Future<void> delete(String path) => _run(() => _dio.delete<void>(path));

  /// DELETE that returns a body (e.g. removing a student returns the updated room).
  Future<T> deleteWithBody<T>(String path) => _run(() => _dio.delete<T>(path));

  Future<T> _run<T>(Future<Response<T>> Function() call) async {
    try {
      final response = await call();
      return response.data as T;
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
