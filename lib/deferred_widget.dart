// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class DeferredWidget extends StatefulWidget {
  final Future Function() loadLibrary;
  final Widget Function() widgetLoader;

  DeferredWidget(this.loadLibrary, this.widgetLoader);

  @override
  State<StatefulWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  Future<Widget> _future;
  Widget _widget;

  @override
  void initState() {
    super.initState();
    _future =
        widget.loadLibrary().then((dynamic value) => widget.widgetLoader());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (_widget == null && snapshot.hasData) {
          _widget = snapshot.data;
        }
        if (_widget != null) {
          return _widget;
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return const CircularProgressIndicator();
        }
      });
}
