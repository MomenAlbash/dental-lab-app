import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Minimal stateful toast widget. It exposes an instance method
/// `showToast` which can be called from the widget tree when you hold
/// a reference to the state (for example via a `GlobalKey`). This file
/// also includes the simple top-level `ShowToast` helper and `toastState` enum.
class ShowToastWidget extends StatefulWidget {
  const ShowToastWidget({Key? key}) : super(key: key);

  @override
  _ShowToastWidgetState createState() => _ShowToastWidgetState();
}

class _ShowToastWidgetState extends State<ShowToastWidget> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Top-level convenience function (keeps the original signature)

void ShowToast({required String message, required toastState state}) {
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

enum toastState { success, error, warning }

Color _choseColorState(toastState state) {
  switch (state) {
    case toastState.success:
      return Colors.green;
    case toastState.error:
      return Colors.red;
    case toastState.warning:
      return Colors.amber;
  }
}
