// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs, avoid_print, use_build_context_synchronously

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_videohole/video_player.dart';
import 'package:tizen_app_control/tizen_app_control.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PlayerPage(),
    );
  }
}

typedef _InitDartApiNative = Bool Function(Pointer<Int8>, Pointer<Int8>);
typedef _InitDartApi = bool Function(Pointer<Int8>, Pointer<Int8>);

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController _controller;

  // Set preview infos
  void preview() {
    final DynamicLibrary lib =
        DynamicLibrary.open('/usr/lib/libcontent-db-api.so.0');

    final _InitDartApi initDartApi =
        lib.lookupFunction<_InitDartApiNative, _InitDartApi>(
            'set_preview_metadata');

    // `jsonStr` sample, see more from: https://developer.samsung.com/onlinedocs/tv/Preview/sampleJSON.json
    String jsonStr = '{"sections": '
        '[{"title": "Popular VOD","tiles":[{"title": "Funny","subtitle": "Birthday Party",'
        '"image_ratio": "16by9","image_url": "http://developer.samsung.com/onlinedocs/tv/Preview/1.jpg",'
        '"action_data": "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",'
        '"is_playable": true}]},'
        '{"title": "VOD recommended","tiles": [{"title": "Living","image_ratio": "1by1",'
        '"image_url": "http://developer.samsung.com/onlinedocs/tv/Preview/2.jpg",'
        '"action_data": "https://dash.akamaized.net/dash264/TestCasesUHD/2b/11/MultiRate.mpd",'
        '"is_playable": true},'
        '{"title": "Cooking","subtitle": "Season 1",'
        '"image_ratio": "16by9",'
        '"image_url": "http://developer.samsung.com/onlinedocs/tv/Preview/3.jpg",'
        '"action_data": "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",'
        '"is_playable": false},'
        '{"title": "Party","image_ratio": "16by9",'
        '"image_url": "http://developer.samsung.com/onlinedocs/tv/Preview/4.jpg",'
        '"action_data": "https://dash.akamaized.net/dash264/TestCasesUHD/2b/11/MultiRate.mpd",'
        '"is_playable": false},'
        '{"title": "Animal","image_ratio": "16by9",'
        '"image_url": "http://developer.samsung.com/onlinedocs/tv/Preview/5.jpg",'
        '"action_data": "https://media.w3.org/2010/05/bunny/trailer.mp4",'
        '"is_playable": false}]}]}';
    // `packageName` is your package name
    String packageName = 'com.example.preview_test_sample';

    initDartApi(jsonStr.toNativeUtf8().cast<Int8>(),
        packageName.toNativeUtf8().cast<Int8>());
  }

  // Receive the request from server
  void receiveRequest() {
    final StreamSubscription<ReceivedAppControl> appControlListener =
        AppControl.onAppControl.listen((ReceivedAppControl request) async {
      // The `action_data` value is converted to an object with the `PAYLOAD` key.
      // Player can be launched by this action data.
      String strMap = '';
      if (request.extraData['PAYLOAD'] != null) {
        strMap = request.extraData['PAYLOAD'];
        print(strMap);
      }

      // This is the sample: get url from `action_data` and update to player
      // You can change `action_data` whatever you want.
      if (strMap.isNotEmpty) {
        String updatedUrl =
            strMap.substring(strMap.indexOf(':') + 2, strMap.length - 2);

        _controller = VideoPlayerController.network(updatedUrl);
        _controller.initialize().then((_) => setState(() {}));
        _controller.play();
        return;
      }

      _controller.initialize().then((_) => setState(() {}));
      _controller.play();
    });
  }

  @override
  void initState() {
    super.initState();
    preview();

    _controller = VideoPlayerController.network(
        'https://media.w3.org/2010/05/bunny/trailer.mp4');

    receiveRequest();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(padding: const EdgeInsets.only(top: 20.0)),
          const Text('With remote mp4'),
          Container(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: <Widget>[
                  VideoPlayer(_controller),
                  ClosedCaption(text: _controller.value.caption.text),
                  VideoProgressIndicator(_controller, allowScrubbing: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
