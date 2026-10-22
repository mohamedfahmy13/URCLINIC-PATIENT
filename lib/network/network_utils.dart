import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../api/auth_apis.dart';
import '../configs.dart';
import '../main.dart';
import '../utils/api_end_points.dart';
import '../utils/app_common.dart';
import '../utils/common_base.dart';

const Duration _requestTimeout = Duration(seconds: 20);
const int _maxRequestAttempts = 2;
bool _isHandlingUnauthorizedSession = false;

Map<String, String> buildHeaderTokens({
  Map? extraKeys,
  String? endPoint,
}) {
  /// Initialize & Handle if key is not present
  if (extraKeys == null) {
    extraKeys = {};
    extraKeys.putIfAbsent('isFlutterWave', () => false);
    extraKeys.putIfAbsent('isAirtelMoney', () => false);
  }
  final Map<String, String> header = {
    HttpHeaders.cacheControlHeader: 'no-cache',
    'Access-Control-Allow-Headers': '*',
    'Access-Control-Allow-Origin': '*',
    'global-localization': selectedLanguageCode.value,
  };

  if (endPoint == APIEndPoints.register) {
    header.putIfAbsent(HttpHeaders.acceptHeader, () => 'application/json');
  }
  header.putIfAbsent(
      HttpHeaders.contentTypeHeader, () => 'application/json; charset=utf-8');

  if (isLoggedIn.value &&
      extraKeys.containsKey('isFlutterWave') &&
      extraKeys['isFlutterWave']) {
    header.putIfAbsent(HttpHeaders.authorizationHeader,
        () => "Bearer ${extraKeys!['flutterWaveSecretKey']}");
  } else if (isLoggedIn.value &&
      extraKeys.containsKey('isAirtelMoney') &&
      extraKeys['isAirtelMoney']) {
    header.putIfAbsent(
        HttpHeaders.contentTypeHeader, () => 'application/json; charset=utf-8');
    header.putIfAbsent(HttpHeaders.authorizationHeader,
        () => 'Bearer ${extraKeys!['access_token']}');
    header.putIfAbsent('X-Country', () => '${extraKeys!['X-Country']}');
    header.putIfAbsent('X-Currency', () => '${extraKeys!['X-Currency']}');
  } else if (isLoggedIn.value) {
    header.putIfAbsent(HttpHeaders.authorizationHeader,
        () => 'Bearer ${loginUserData.value.apiToken}');
  }

  // log(jsonEncode(header));
  return header;
}

Uri buildBaseUrl(String endPoint) {
  if (!endPoint.startsWith('http')) {
    return Uri.parse('$BASE_URL$endPoint');
  } else {
    return Uri.parse(endPoint);
  }
}

Future<Response> buildHttpResponse(
  String endPoint, {
  HttpMethodType method = HttpMethodType.GET,
  Map? request,
  Map? extraKeys,
  Map<String, String>? header,
}) async {
  final headers =
      header ?? buildHeaderTokens(extraKeys: extraKeys, endPoint: endPoint);
  final Uri url = buildBaseUrl(endPoint);
  final bool isInternalRequest = !endPoint.startsWith('http');

  try {
    final Response response = await _executeWithTimeoutAndRetry(
      url: url,
      method: method,
      request: request,
      headers: headers,
    );

    apiPrint(
      url: url.toString(),
      endPoint: endPoint,
      headers: jsonEncode(_redactHeaderMap(headers)),
      hasRequest: method == HttpMethodType.POST || method == HttpMethodType.PUT,
      request: _redactMessage(jsonEncode(request)),
      statusCode: response.statusCode,
      responseBody:
          _summarizeResponseBody(_redactMessage(response.body.trim())),
      methodtype: method.name,
    );

    // Sessions never time out on the device: only a token the server no longer accepts
    // (signed out on this device, or the account was removed) ends one.
    if (isLoggedIn.value && response.statusCode == 401 && isInternalRequest) {
      await _handleUnauthorizedSession();
      throw 'Session expired. Please sign in again.';
    }

    return response;
  } on Exception catch (_) {
    if (!kReleaseMode) {
      log('buildHttpResponse failed');
    }
    throw errorInternetNotAvailable;
  }
}

Future<void> _handleUnauthorizedSession() async {
  if (_isHandlingUnauthorizedSession) return;
  _isHandlingUnauthorizedSession = true;

  try {
    await AuthServiceApis.clearData();
    isLoggedIn(false);
  } catch (_) {
    // Keep unauthorized handling non-fatal.
  } finally {
    _isHandlingUnauthorizedSession = false;
  }
}

Future<Response> _executeWithTimeoutAndRetry({
  required Uri url,
  required HttpMethodType method,
  required Map? request,
  required Map<String, String> headers,
}) async {
  Object? lastError;

  for (int attempt = 0; attempt < _maxRequestAttempts; attempt++) {
    try {
      if (method == HttpMethodType.POST) {
        return await http
            .post(url, body: jsonEncode(request), headers: headers)
            .timeout(_requestTimeout);
      } else if (method == HttpMethodType.DELETE) {
        return await delete(url, headers: headers).timeout(_requestTimeout);
      } else if (method == HttpMethodType.PUT) {
        return await put(url, body: jsonEncode(request), headers: headers)
            .timeout(_requestTimeout);
      } else {
        return await get(url, headers: headers).timeout(_requestTimeout);
      }
    } on SocketException catch (e) {
      lastError = e;
    } on TimeoutException catch (e) {
      lastError = e;
    }
  }

  throw lastError ?? Exception('Request failed');
}

Map<String, String> _redactHeaderMap(Map<String, String> header) {
  final Map<String, String> sanitized = Map<String, String>.from(header);
  if (sanitized.containsKey(HttpHeaders.authorizationHeader)) {
    sanitized[HttpHeaders.authorizationHeader] = 'Bearer ***';
  }
  return sanitized;
}

String _redactMessage(String raw) {
  return raw
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-\._]+'), 'Bearer ***')
      .replaceAll(RegExp(r'"api_token"\s*:\s*"[^"]+"'), '"api_token":"***"')
      .replaceAll(RegExp(r'"password"\s*:\s*"[^"]*"'), '"password":"***"')
      .replaceAll(
          RegExp(r'"old_password"\s*:\s*"[^"]*"'), '"old_password":"***"')
      .replaceAll(
          RegExp(r'"new_password"\s*:\s*"[^"]*"'), '"new_password":"***"');
}

String _summarizeResponseBody(String raw) {
  final String body = raw.trim();
  if (body.isEmpty) return body;

  final String lower = body.toLowerCase();
  final bool isHtmlResponse =
      lower.startsWith('<!doctype html') || lower.contains('<html');

  if (isHtmlResponse) {
    const int previewLength = 400;
    final String preview =
        body.length > previewLength ? body.substring(0, previewLength) : body;
    final String singleLinePreview =
        preview.replaceAll(RegExp(r'\s+'), ' ').trim();
    return '[HTML error response omitted] '
        '$singleLinePreview'
        '${body.length > previewLength ? ' ...' : ''}';
  }

  const int maxLength = 1800;
  if (body.length <= maxLength) return body;

  final int truncatedCount = body.length - maxLength;
  return '${body.substring(0, math.min(maxLength, body.length))} '
      '...[truncated $truncatedCount chars]';
}

Future handleResponse(Response response,
    {HttpResponseType httpResponseType = HttpResponseType.JSON,
    bool? avoidTokenError,
    bool? isFlutterWave}) async {
  if (!await isNetworkAvailable()) {
    throw errorInternetNotAvailable;
  }

  if (response.statusCode.isSuccessful()) {
    if (response.body.trim().isJson()) {
      final Map body = jsonDecode(response.body.trim());

      if (body.containsKey('status')) {
        if (isFlutterWave.validate()) {
          if (body['status'] == 'success') {
            return body;
          } else {
            throw body['message'] ?? errorSomethingWentWrong;
          }
        } else {
          if (body['status'] == true) {
            return body;
          } else {
            if (body.containsKey("is_deleted") && body["is_deleted"] == true) {
              await AuthServiceApis.clearData(isFromDeleteAcc: true);
              throw body['message'] ?? errorSomethingWentWrong;
            } else {
              throw body['message'] ?? errorSomethingWentWrong;
            }
          }
        }
      } else {
        return body;
      }
    } else {
      throw errorSomethingWentWrong;
    }
  } else if (response.statusCode == 400) {
    throw locale.value.badRequest;
  } else if (response.statusCode == 401) {
    final String bodyText = response.body.trim();
    if (bodyText.isJson()) {
      final Map body = jsonDecode(bodyText);
      final dynamic message = body['message'] ?? body['error'];
      if (message is String && message.trim().isNotEmpty) {
        throw message;
      }
    }
    throw 'Session expired. Please sign in again.';
  } else if (response.statusCode == 403) {
    throw locale.value.forbidden;
  } else if (response.statusCode == 404) {
    throw locale.value.pageNotFound;
  } else if (response.statusCode == 429) {
    throw locale.value.tooManyRequests;
  } else if (response.statusCode == 500) {
    throw locale.value.internalServerError;
  } else if (response.statusCode == 502) {
    throw locale.value.badGateway;
  } else if (response.statusCode == 503) {
    throw locale.value.serviceUnavailable;
  } else if (response.statusCode == 504) {
    throw locale.value.gatewayTimeout;
  } else {
    final String bodyText = response.body.trim();
    if (!bodyText.isJson()) {
      if (response.statusCode >= 500) {
        throw locale.value.internalServerError;
      }
      throw errorSomethingWentWrong;
    }

    final Map body = jsonDecode(bodyText);

    if (body.containsKey('status') && body['status']) {
      return body;
    } else {
      throw body['message'] ?? errorSomethingWentWrong;
    }
  }
}

//region CommonFunctions
Future<Map<String, String>> getMultipartFields(
    {required Map<String, dynamic> val}) async {
  final Map<String, String> data = {};

  val.forEach((key, value) {
    data[key] = '$value';
  });

  return data;
}

Future<MultipartRequest> getMultiPartRequest(String endPoint,
    {String? baseUrl}) async {
  final String url = baseUrl ?? buildBaseUrl(endPoint).toString();
  // log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future<void> sendMultiPartRequest(MultipartRequest multiPartRequest,
    {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  try {
    final streamedResponse =
        await multiPartRequest.send().timeout(_requestTimeout);
    final http.Response response =
        await http.Response.fromStream(streamedResponse)
            .timeout(_requestTimeout);

    apiPrint(
      url: multiPartRequest.url.toString(),
      headers: jsonEncode(multiPartRequest.headers),
      request: jsonEncode(multiPartRequest.fields),
      hasRequest: true,
      statusCode: response.statusCode,
      responseBody: _summarizeResponseBody(response.body.trim()),
      methodtype: "MultiPart",
    );

    if (response.statusCode.isSuccessful()) {
      onSuccess?.call(response.body.trim());
    } else {
      if (isLoggedIn.value && response.statusCode == 401) {
        await _handleUnauthorizedSession();
        onError?.call('Session expired. Please sign in again.');
      } else {
        onError?.call(_extractMultipartErrorMessage(response));
      }
    }
  } on TimeoutException {
    onError?.call(locale.value.gatewayTimeout);
  } on SocketException {
    onError?.call(errorInternetNotAvailable);
  } catch (_) {
    onError?.call(errorSomethingWentWrong);
  }
}

String _extractMultipartErrorMessage(http.Response response) {
  try {
    final String body = response.body.trim();
    if (body.isNotEmpty && body.isJson()) {
      final Map<String, dynamic> decoded =
          Map<String, dynamic>.from(jsonDecode(body));
      final dynamic message = decoded['message'] ?? decoded['error'];

      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }

      if (message is Map && message.isNotEmpty) {
        return message.values.first.toString();
      }
    }
  } catch (_) {
    // Keep fallback path non-fatal for unexpected payloads.
  }

  final String reason = response.reasonPhrase?.trim() ?? '';
  return reason.isNotEmpty ? reason : errorSomethingWentWrong;
}

Future buildMultiPartResponse({
  required String endPoint,
  required Map<String, dynamic> request,
  Map<String, String>? header,
  List<File>? files,
  String? fileKey,
  bool isKeyRequireIndexing = false,
}) async {
  try {
    final MultipartRequest multiPartRequest =
        await getMultiPartRequest(endPoint);
    multiPartRequest.headers.addAll(buildHeaderTokens());
    multiPartRequest.fields.addAll(await getMultipartFields(val: request));
    if (files != null && files.isNotEmpty) {
      files.removeWhere((element) => element.path.isEmpty);
      if (files.length > 1) {
        files.forEachIndexed(
          (element, index) async {
            multiPartRequest.files.add(await MultipartFile.fromPath(
                '${fileKey}_$index', element.path));
          },
        );
      } else if (files.length == 1) {
        files.forEachIndexed(
          (element, index) async {
            if (isKeyRequireIndexing) {
              multiPartRequest.files.add(await MultipartFile.fromPath(
                  '${fileKey}_$index', element.path));
            } else {
              multiPartRequest.files
                  .add(await MultipartFile.fromPath('$fileKey', element.path));
            }
          },
        );
      }
    }

    final Response response =
        await Response.fromStream(await multiPartRequest.send());

    apiPrint(
      url: multiPartRequest.url.toString(),
      headers: jsonEncode(multiPartRequest.headers),
      request: jsonEncode(multiPartRequest.fields),
      hasRequest: true,
      statusCode: response.statusCode,
      responseBody: _summarizeResponseBody(response.body),
      methodtype: "MultiPart",
    );

    return await handleResponse(response);
  } on SocketException catch (e) {
    if (!kReleaseMode) {
      log(e.toString());
    }
    rethrow;
  } on Exception catch (e) {
    if (!kReleaseMode) {
      log(e.toString());
    }
    rethrow;
  }
}

Future<List<MultipartFile>> getMultipartImages(
    {required List<PlatformFile> files, required String name}) async {
  final List<MultipartFile> multiPartRequest = [];

  await Future.forEach<PlatformFile>(files, (element) async {
    final int i = files.indexOf(element);

    multiPartRequest.add(
        await MultipartFile.fromPath('$name[$i]', element.path.validate()));
  });

  return multiPartRequest;
}

Future<List<MultipartFile>> getMultipartImages2(
    {required List<XFile> files, required String name}) async {
  final List<MultipartFile> multiPartRequest = [];

  await Future.forEach<XFile>(files, (element) async {
    final int i = files.indexOf(element);

    multiPartRequest.add(
        await MultipartFile.fromPath('$name[$i]', element.path.validate()));
  });

  return multiPartRequest;
}

String parseStripeError(String response) {
  try {
    final body = jsonDecode(response);
    return parseHtmlString(body['error']['message']);
  } on Exception catch (_) {
    if (!kReleaseMode) {
      log('parseStripeError failed');
    }
    throw errorSomethingWentWrong;
  }
}

void apiPrint({
  String url = "",
  String endPoint = "",
  String headers = "",
  String request = "",
  int statusCode = 0,
  String responseBody = "",
  String methodtype = "",
  bool hasRequest = false,
  bool fullLog = false,
  String responseHeader = '',
}) {
  if (kReleaseMode) return;

  if (fullLog) {
    debugPrint(
        "┌───────────────────────────────────────────────────────────────────────────────────────────────────────");
    debugPrint("\u001b[93m Url: \u001B[39m $url");
    debugPrint("\u001b[93m endPoint: \u001B[39m \u001B[1m$endPoint\u001B[22m");
    debugPrint(
        "\u001b[93m header: \u001B[39m \u001b[96m${_redactMessage(headers)}\u001B[39m");
    if (hasRequest) {
      debugPrint(
          '\u001b[93m Request: \u001B[39m \u001b[95m${_redactMessage(request)}\u001B[39m');
    }
    debugPrint(statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m");
    debugPrint(
        "\u001b[93m Response header: \u001B[39m \u001b[96m$responseHeader\u001B[39m");
    debugPrint(
        '\u001b[93m MethodType ($methodtype) | StatusCode ($statusCode)\u001B[39m');
    debugPrint('Response : ');
    debugPrint('\x1B[32m${formatJson(_redactMessage(responseBody))}\x1B[0m');
    debugPrint("\u001B[0m");
    debugPrint(
        "└───────────────────────────────────────────────────────────────────────────────────────────────────────");
  } else {
    debugPrint(
        "┌───────────────────────────────────────────────────────────────────────────────────────────────────────");
    debugPrint("\u001b[93m Url: \u001B[39m $url");
    debugPrint("\u001b[93m endPoint: \u001B[39m \u001B[1m$endPoint\u001B[22m");
    debugPrint(
        "\u001b[93m header: \u001B[39m \u001b[96m${_redactMessage(headers).split(',').join(',\n')}\u001B[39m");
    if (hasRequest) {
      debugPrint(
          '\u001b[93m Request: \u001B[39m \u001b[95m${_redactMessage(request)}\u001B[39m');
    }
    debugPrint(statusCode.isSuccessful() ? "\u001b[32m" : "\u001b[31m");
    debugPrint(
        '\u001b[93m MethodType ($methodtype) | statusCode: ($statusCode)\u001B[39m');
    debugPrint(
        "\u001b[93m Response header: \u001B[39m \u001b[96m$responseHeader\u001B[39m");
    debugPrint('\u001b[93m Response \u001B[39m');
    debugPrint(_redactMessage(responseBody));
    debugPrint("\u001B[0m");
    debugPrint(
        "└───────────────────────────────────────────────────────────────────────────────────────────────────────");
  }
}

String formatJson(String jsonStr) {
  try {
    final dynamic parsedJson = jsonDecode(jsonStr);
    const formatter = JsonEncoder.withIndent('  ');
    return formatter.convert(parsedJson);
  } on Exception catch (e) {
    debugPrint("\x1b[31m formatJson error ::-> $e \x1b[0m");
    return jsonStr;
  }
}

Map<String, String> defaultHeaders() {
  final Map<String, String> header = {};

  header.putIfAbsent(HttpHeaders.cacheControlHeader, () => 'no-cache');
  header.putIfAbsent('Access-Control-Allow-Headers', () => '*');
  header.putIfAbsent('Access-Control-Allow-Origin', () => '*');

  return header;
}
