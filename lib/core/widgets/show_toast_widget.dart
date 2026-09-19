import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Shows a native toast. [state] picks the background colour.
void showToast({required String message, required ToastState state}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: _choseColorState(state),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

enum ToastState { success, error, warning }

Color _choseColorState(ToastState state) {
  switch (state) {
    case ToastState.success:
      return Colors.green;
    case ToastState.error:
      return Colors.red;
    case ToastState.warning:
      return Colors.amber;
  }
}
