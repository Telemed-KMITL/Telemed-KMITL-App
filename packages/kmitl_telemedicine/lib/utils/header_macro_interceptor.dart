import 'dart:ui';

import 'package:dio/dio.dart';

class HeaderMacroInterceptor extends Interceptor {
  final String headerName;
  final VoidCallback macro;

  HeaderMacroInterceptor(this.headerName, this.macro);

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    final value = response.headers[headerName]?.lastOrNull?.toLowerCase();
    if (value == "true") {
      macro();
    }
    handler.next(response);
  }
}
