import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showSuccessDialog(
  BuildContext context,
  String title,
  String body,
  Function? callback,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              if (callback != null) {
                callback();
              }
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
