import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:ffi'; // For FFI
import "dart:convert";

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';

import 'first.dart';
import 'second.dart';

const String mainWidget = '/main';
const String secondWidget = '/second';

/// Channel used to let the Flutter app know to reset the app to a specific
/// route.  See the [run] method.
///
/// Note that we shouldn't use the `setInitialRoute` method on the system
/// navigation channel, as that never gets propagated back to Flutter after the
/// initial call.
const String _kReloadChannelName = 'reload';
const BasicMessageChannel<String> _kReloadChannel =
BasicMessageChannel<String>(_kReloadChannelName, StringCodec());


final DynamicLibrary nativeAddLib = Platform.isAndroid
    ? DynamicLibrary.open("libhttprequest.so")
//    : DynamicLibrary.open("Common_C_Framework.framework/Common_C_Framework");
    : DynamicLibrary.process();

typedef NativeAllocFunc = Pointer<Uint8> Function(Int32 size);
typedef DartAllocFunc = Pointer<Uint8> Function(int size);
final nativeAllocFuncPointer =
nativeAddLib
    .lookup<NativeFunction<NativeAllocFunc>>("allocPointer");
final nativeAlloc = nativeAllocFuncPointer.asFunction<DartAllocFunc>();

typedef NativeFreeFunc = Void Function(Pointer<Uint8>);
typedef DartFreeFunc = void Function(Pointer<Uint8>);
final nativeFreeFuncPointer =
nativeAddLib
    .lookup<NativeFunction<NativeFreeFunc>>("freePointer");
final nativeFree = nativeFreeFuncPointer.asFunction<DartFreeFunc>();

typedef NativeRequestFunc = Void Function(Pointer<Uint8>);
typedef DartRequestFunc = void Function(Pointer<Uint8>);
final nativeRequestFuncPointer =
nativeAddLib
    .lookup<NativeFunction<NativeRequestFunc>>("httpRequest");
final nativeRequest = nativeRequestFuncPointer.asFunction<DartRequestFunc>();

Pointer<Uint8> stringToCString(String input) {
  List<int> units = Utf8Codec().encode(input);
  Pointer<Uint8> str = nativeAlloc(units.length + 1);
  for (int i = 0; i < units.length; ++i) {
    str.elementAt(i).value = units[i];
  }
  str.elementAt(units.length).value = 0;
  return str.cast();
}


void main() {
  // Ensures bindings are initialized before doing anything.
  WidgetsFlutterBinding.ensureInitialized();
  // Start listening immediately for messages from the iOS side. ObjC calls
  // will be made to let us know when we should be changing the app state.
  _kReloadChannel.setMessageHandler(run);
  // Start off with whatever the initial route is supposed to be.
  run(window.defaultRouteName);
}

Future<String> run(String name) async {
  // The platform-specific component will call [setInitialRoute] on the Flutter
  // view (or view controller for iOS) to set [ui.window.defaultRouteName].
  // We then dispatch based on the route names to show different Flutter
  // widgets.
  // Since we don't really care about Flutter-side navigation in this app, we're
  // not using a regular routes map.
  print('run(), name:' + name);
  switch (name) {
    case mainWidget:
      Pointer<Uint8> url = stringToCString('http://www.baidu.com');
      nativeRequest(url);
      nativeFree(url);

      runApp(MyApp());
      break;
    default:
      runApp(DefaultWidget(initialRoute: name));
      break;
  }
  return '';
}

class DefaultWidget extends StatelessWidget {
  final String initialRoute;
  const DefaultWidget({@required this.initialRoute});

  static const platform = const MethodChannel('samples.flutter.dev/goToNativePage');
  Future<void> _popNative() async {
    try {
      final int result = await platform
          .invokeMethod('goToNativePage', {'param': 'DefaultWidget::_popNative()'});
      print(result);
    } on PlatformException catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          leading:new IconButton(icon: new Icon(Icons.arrow_back_ios), onPressed: _popNative),
          title: Text('Default, ' + initialRoute),
        ),
      )
    );
  }
}