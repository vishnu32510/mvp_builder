import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'dart:convert' as convert;

import 'package:url_launcher/url_launcher.dart';

import 'token.dart';

// Export ToastService for easier access
export 'toast_service.dart';

enum ServiceError {
  unknownError,
  unknownResponseError,
  clientError,
  serverError,
  timeoutError,
  socketError,
}

abstract class Services {}

class OpenLinkService extends Services {
  Future<String?> openUrl({required String link}) async {
    if (!await launchUrl(Uri.parse(link))) {
      return  'Could not launch $link';
      // throw  Exception('Could not launch $link');
    }
    return null;
  }

  Future<String?> openUrlInApp({required String link}) async {
    if (!await launchUrl(Uri.parse(link), mode: LaunchMode.inAppWebView)) {
      return 'Could not launch $link';
      // throw Exception('Could not launch $link');
    }
    return null;
  }

  Future<String?> openUrlInAppBrowser({required String link}) async {
    if (!await launchUrl(Uri.parse(link), mode: LaunchMode.inAppBrowserView)) {
      return  'Could not launch $link';
      // throw  Exception('Could not launch $link');
    }
    return null;
  }
}

class HttpServices extends Services {
  Future<String?> _getToken() async {
    var token = await Token().getToken();
    return token;
  }

  final RetryOptions _retryOptions = RetryOptions(
    maxAttempts: 5,
    delayFactor: const Duration(seconds: 2),
    maxDelay: const Duration(seconds: 8),
  );

  Future<T> _withRetry<T>(Future<T> Function() fn) {
    int attemptCount = 0;
    
    return _retryOptions.retry(
      () async {
        attemptCount++;
        debugPrint('HTTP Request attempt #$attemptCount');
        try {
          final result = await fn();
          if (attemptCount > 1) {
            debugPrint('Request succeeded after $attemptCount attempts');
          }
          return result;
        } catch (e) {
          debugPrint('Attempt #$attemptCount failed: ${e.runtimeType} - ${e.toString()}');
          rethrow;
        }
      },
      retryIf: (e) => e is TimeoutException || e is SocketException,
      onRetry: (e) {
        debugPrint('Retrying request (attempt #${attemptCount + 1}) due to: ${e.runtimeType}');
      },
    );
  }

  Future postMethod(String url, var body) async {
    var token = await _getToken();
    var bo = convert.jsonEncode(body);
    try {
      var data = await _withRetry(() => http
          .post(
            Uri.parse(url),
            body: bo,
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(seconds: 20)));
      debugPrint(data.body);
      if (data.statusCode == 200 || data.statusCode == 201) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future putMethod(String url, var body) async {
    try {
      var token = await _getToken();
      var data = await _withRetry(() => http
          .put(
            Uri.parse(url),
            body: convert.jsonEncode(body),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(seconds: 20)));
      if (data.statusCode == 200) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future deleteMethod(String url) async {
    var token = await _getToken();
    try {
      var data = await _withRetry(() => http
          .delete(
            Uri.parse(url),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(seconds: 20)));
      debugPrint(data.body);
      if (data.statusCode == 200 || data.statusCode == 204) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future<dynamic> getMethod(String url) async {
    try {
      var token = await _getToken();
      var data = await _withRetry(() => http
          .get(
            Uri.parse(url),
            headers: <String, String>{
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(seconds: 20)));
      debugPrint(data.body);
      if (data.statusCode == 200) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return response;
      } else if (data.statusCode == 400 || data.statusCode == 404) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response);
        return ServiceError.clientError;
      } else if (data.statusCode == 500) {
        var response = convert.jsonDecode(data.body);
        debugPrint(response.toString());
        return ServiceError.serverError;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (_) {
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (_) {
      return ServiceError.unknownError;
    }
  }

  Future<dynamic> postImage({
    required String url,
    required http.MultipartFile imageFile,
    required Map<String, dynamic> body,
  }) async {
    try {
      var token = await _getToken();
      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.files.add(imageFile);

      // request.fields['username'] = body['username'];

      // Set headers
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Authorization': 'Bearer $token',
      });

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseJson = convert.jsonDecode(responseBody);
        return responseJson;
      } else {
        return ServiceError.unknownResponseError;
      }
    } on TimeoutException catch (e) {
      debugPrint(e.toString());
      return ServiceError.timeoutError;
    } on SocketException catch (_) {
      return ServiceError.socketError;
    } on Exception catch (e) {
      debugPrint(e.toString());
      return ServiceError.unknownError;
    }
  }
}
