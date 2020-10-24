// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/deferred_widget.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/demo.dart' deferred as demo;
//import 'package:gallery/pages/home.dart';
import 'package:gallery/studies/crane/app.dart' deferred as crane;
import 'package:gallery/studies/fortnightly/app.dart' deferred as fortnightly;
import 'package:gallery/studies/rally/app.dart' deferred as rally;
import 'package:gallery/studies/reply/app.dart' deferred as reply;
import 'package:gallery/studies/shrine/app.dart' deferred as shrine;
import 'package:gallery/studies/starter/app.dart' deferred as starter;

typedef PathWidgetBuilder = Widget Function(BuildContext, String);

class Path {
  const Path(this.pattern, this.builder);

  /// A RegEx string for route matching.
  final String pattern;

  /// The builder for the associated pattern route. The first argument is the
  /// [BuildContext] and the second argument a RegEx match if that is included
  /// in the pattern.
  ///
  /// ```dart
  /// Path(
  ///   'r'^/demo/([\w-]+)$',
  ///   (context, matches) => Page(argument: match),
  /// )
  /// ```
  final PathWidgetBuilder builder;
}

class RouteConfiguration {
  /// List of [Path] to for route matching. When a named route is pushed with
  /// [Navigator.pushNamed], the route name is matched with the [Path.pattern]
  /// in the list below. As soon as there is a match, the associated builder
  /// will be returned. This means that the paths higher up in the list will
  /// take priority.
  static List<Path> paths = [
    Path(
      r'^/demo' + r'/([\w-]+)$',
      (context, match) =>
          DeferredWidget(demo.loadLibrary, () => demo.DemoPage(slug: match)),
    ),
    Path(
      r'^/rally',
      (context, match) => DeferredWidget(
          rally.loadLibrary, () => StudyWrapper(study: rally.RallyApp())),
    ),
    Path(
      r'^/shrine',
      (context, match) => DeferredWidget(
          shrine.loadLibrary, () => StudyWrapper(study: shrine.ShrineApp())),
    ),
    Path(
      r'^/crane',
      (context, match) => DeferredWidget(
          crane.loadLibrary, () => StudyWrapper(study: crane.CraneApp())),
    ),
    Path(
      r'^/fortnightly',
      (context, match) => DeferredWidget(fortnightly.loadLibrary,
          () => StudyWrapper(study: fortnightly.FortnightlyApp())),
    ),
    Path(
      r'^/reply',
      (context, match) => DeferredWidget(
          reply.loadLibrary,
          () => StudyWrapper(
                alignment: AlignmentDirectional.topCenter,
                study: reply.ReplyApp(),
              )),
    ),
    Path(
      r'^/starter',
      (context, match) => DeferredWidget(
          starter.loadLibrary, () => StudyWrapper(study: starter.StarterApp())),
    ),
    Path(
      r'^/',
      (context, match) => const RootPage(),
    ),
  ];

  /// The route generator callback used when the app is navigated to a named
  /// route. Set it on the [MaterialApp.onGenerateRoute] or
  /// [WidgetsApp.onGenerateRoute] to make use of the [paths] for route
  /// matching.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    for (final path in paths) {
      final regExpPattern = RegExp(path.pattern);
      if (regExpPattern.hasMatch(settings.name)) {
        final firstMatch = regExpPattern.firstMatch(settings.name);
        final match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
        if (kIsWeb) {
          return NoAnimationMaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (context) => path.builder(context, match),
          settings: settings,
        );
      }
    }

    // If no match was found, we let [WidgetsApp.onUnknownRoute] handle it.
    return null;
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
  }) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// Wrap the studies with this to display a back button and allow the user to
/// exit them at any time.
class StudyWrapper extends StatefulWidget {
  const StudyWrapper({
    Key key,
    this.study,
    this.alignment = AlignmentDirectional.bottomStart,
  }) : super(key: key);

  final Widget study;
  final AlignmentDirectional alignment;

  @override
  _StudyWrapperState createState() => _StudyWrapperState();
}

class _StudyWrapperState extends State<StudyWrapper> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ApplyTextOptions(
      child: Stack(
        children: [
          Semantics(
            sortKey: const OrdinalSortKey(1),
            child: widget.study,
          ),
          Align(
            alignment: widget.alignment,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                sortKey: const OrdinalSortKey(0),
                //label: GalleryLocalizations.of(context).backToGallery,
                button: true,
                enabled: true,
                excludeSemantics: true,
                child: FloatingActionButton.extended(
                  //heroTag: _BackButtonHeroTag(),
                  key: const ValueKey('Back'),
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.settings.name == '/');
                  },
                  icon: IconTheme(
                    data: IconThemeData(color: colorScheme.onPrimary),
                    child: const BackButtonIcon(),
                  ),
                  label: Text(
                    MaterialLocalizations.of(context).backButtonTooltip,
                    style: textTheme.button.apply(color: colorScheme.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
