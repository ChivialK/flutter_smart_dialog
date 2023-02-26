import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_smart_dialog/src/helper/navigator_observer.dart';
import 'package:flutter_smart_dialog/src/util/view_utils.dart';
import 'package:flutter_smart_dialog/src/widget/toast_widget.dart';

import 'helper/dialog_proxy.dart';
import 'helper/pop_monitor/boost_route_monitor.dart';
import 'helper/pop_monitor/monitor_pop_route.dart';
import 'widget/loading_widget.dart';

typedef FlutterSmartToastBuilder = Widget Function(String msg);
typedef FlutterSmartLoadingBuilder = Widget Function(String msg);
typedef FlutterSmartStyleBuilder = Widget Function(Widget child);

class FlutterSmartDialog extends StatefulWidget {
  FlutterSmartDialog({
    Key? key,
    required this.child,
    this.toastBuilder,
    this.loadingBuilder,
    this.styleBuilder,
    this.initType,
    this.useDebugModel,
  }) : super(key: key);

  final Widget? child;

  ///set default toast widget
  final FlutterSmartToastBuilder? toastBuilder;

  ///set default loading widget
  final FlutterSmartLoadingBuilder? loadingBuilder;

  ///Compatible with cupertino style
  final FlutterSmartStyleBuilder? styleBuilder;

  ///inti type
  final Set<SmartInitType>? initType;

  ///if you set 'useDebugModel' to true, the SmartDialog function will be closed
  final bool? useDebugModel;

  @override
  _FlutterSmartDialogState createState() => _FlutterSmartDialogState();

  static final observer = SmartNavigatorObserver();

  ///Compatible with flutter_boost
  static Route<dynamic>? boostMonitor(Route<dynamic>? route) =>
      BoostRouteMonitor.instance.push(route);

  ///recommend the way of init
  static TransitionBuilder init({
    TransitionBuilder? builder,
    //set default toast widget
    FlutterSmartToastBuilder? toastBuilder,
    //set default loading widget
    FlutterSmartLoadingBuilder? loadingBuilder,
    //Compatible with cupertino style
    FlutterSmartStyleBuilder? styleBuilder,
    //init type
    Set<SmartInitType>? initType,
    //if you set 'useDebugModel' to true, the SmartDialog function will be closed
    bool? useDebugModel,
  }) {
    MonitorPopRoute.instance;

    return (BuildContext context, Widget? child) {
      return builder == null
          ? FlutterSmartDialog(
              toastBuilder: toastBuilder,
              loadingBuilder: loadingBuilder,
              styleBuilder: styleBuilder,
              initType: initType,
              useDebugModel: useDebugModel,
              child: child,
            )
          : builder(
              context,
              FlutterSmartDialog(
                toastBuilder: toastBuilder,
                loadingBuilder: loadingBuilder,
                styleBuilder: styleBuilder,
                initType: initType,
                useDebugModel: useDebugModel,
                child: child,
              ),
            );
    };
  }
}

class _FlutterSmartDialogState extends State<FlutterSmartDialog> {
  late FlutterSmartStyleBuilder styleBuilder;
  late Set<SmartInitType> initType;
  late bool debugModel;

  @override
  void initState() {
    ViewUtils.addSafeUse(() {
      try {
        var navigator = widget.child as Navigator;
        var key = navigator.key as GlobalKey;
        DialogProxy.contextNavigator = key.currentContext;
      } catch (e) {}
    });

    // init param
    styleBuilder = widget.styleBuilder ??
        (Widget child) => Material(color: Colors.transparent, child: child);
    initType = widget.initType ??
        {
          SmartInitType.custom,
          SmartInitType.attach,
          SmartInitType.loading,
          SmartInitType.toast,
        };

    // solve Flutter Inspector -> select widget mode function failure problem
    DialogProxy.instance.initialize(initType);

    // default toast / loading
    if (initType.contains(SmartInitType.toast)) {
      DialogProxy.instance.toastBuilder =
          widget.toastBuilder ?? (String msg) => ToastWidget(msg: msg);
    }
    if (initType.contains(SmartInitType.loading)) {
      DialogProxy.instance.loadingBuilder =
          widget.loadingBuilder ?? (String msg) => LoadingWidget(msg: msg);
    }

    // debug model
    debugModel = (widget.useDebugModel ?? false) && kDebugMode;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (debugModel) {
      return styleBuilder(widget.child ?? Container());
    }

    return styleBuilder(
      Overlay(initialEntries: [
        //main layout
        OverlayEntry(
          builder: (BuildContext context) {
            if (initType.contains(SmartInitType.custom)) {
              DialogProxy.contextCustom = context;
            }

            if (initType.contains(SmartInitType.attach)) {
              DialogProxy.contextAttach = context;
            }

            if (initType.contains(SmartInitType.toast)) {
              DialogProxy.contextToast = context;
            }

            return widget.child ?? Container();
          },
        ),

        if (initType.contains(SmartInitType.notify))
          DialogProxy.instance.entryNotify,

        //provided separately for loading
        if (initType.contains(SmartInitType.loading))
          DialogProxy.instance.entryLoading,

        if (initType.contains(SmartInitType.toast))
          DialogProxy.instance.entryToast,
      ]),
    );
  }
}
