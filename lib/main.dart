import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lift_dispatch/lift_dispatch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info/device_info.dart';
import 'package:permission_handler/permission_handler.dart';



void main() async{
  SharedPreferences.setMockInitialValues({});
  runApp(MyApp());
}

Future<int?> getAndroidSdkVersion() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.version.sdkInt; // 返回 Android SDK 版本号
}

Future<void> handleBluetoothPermissions() async {
  final sdkVersion = await getAndroidSdkVersion();
  if (sdkVersion != null) {
    if (sdkVersion >= 31) { // Android 12 及以上版本
      await checkAndRequestBluetoothScanPermission();
    } else {
      print('无需请求 BLUETOOTH_SCAN 权限');
    }
  } else {
    print('无法获取 Android SDK 版本');
  }
}

Future<void> checkAndRequestBluetoothScanPermission() async {
  if (await Permission.bluetoothScan.isGranted) {
    print('蓝牙扫描权限已被授予');
  } else {
    PermissionStatus status = await Permission.bluetoothScan.request();
    if (status.isGranted) {
      print('蓝牙扫描权限已授予');
    } else if (status.isDenied) {
      print('蓝牙扫描权限被拒绝');
    } else if (status.isPermanentlyDenied) {
      print('蓝牙扫描权限被永久拒绝，请到设置中手动开启权限');
      openAppSettings();
    }
  }
}


class MyApp extends StatelessWidget {
  static const String _title = 'Lift Dispatch SDK Test App';


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child:Scaffold(
        body: const MyStatefulWidget(),
          resizeToAvoidBottomInset: false
        ),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);


  @override
  _MyStatefulWidgetState createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final _myController = TextEditingController();
  final _logScrollController = ScrollController();
  final _floorTxtController = TextEditingController();
  final _destFloorTxtController = TextEditingController();
  final _towerIdTxtController = TextEditingController();
  final _zoneIdTxtController = TextEditingController();
  final _userTokenTxtController = TextEditingController();


  final _sdk = LiftDispatch();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();


  String outputText = "";

  String floorTf = "";
  String towerIdTf = "";


  late StreamSubscription<JsonStringEvent> _jsonStrStreamSub;
  late StreamSubscription<LogEvent> _logStreamSub;


  Future<void> _savePrefs() async {
    final SharedPreferences prefs = await _prefs;

    prefs.setString('userToken', _userTokenTxtController.text);
    prefs.setString('floor', _floorTxtController.text);
    prefs.setString('destFloor', _destFloorTxtController.text);
    prefs.setInt('towerId', int.parse(_towerIdTxtController.text));
    prefs.setInt('zoneId', int.parse(_zoneIdTxtController.text));
  }

  Future<void> _getPrefs() async {
    final SharedPreferences prefs = await _prefs;

    _userTokenTxtController.text = prefs.getString('userToken') ?? 'CtA02wFY3uYUdtOJMZ15xLA+HMsOl1+QI1novR7A876Cyzo6AoKNbT2Ba6k=';
    _floorTxtController.text = prefs.getString('floor') ?? '23';
    _destFloorTxtController.text = prefs.getString('destFloor') ?? '2';
    _towerIdTxtController.text = (prefs.getInt('towerId') ?? 2).toString();
    _zoneIdTxtController.text = (prefs.getInt('zoneId') ?? 0).toString();
  }




  @override
  void initState() {
    super.initState();

    handleBluetoothPermissions();

    setState(() {
      _getPrefs();
    });


    // subscribe JSON String Event
    _jsonStrStreamSub = EventBusUtil.listen((event){
      // action
      setState(() {
        // extract jsonString from event
        outputText ='\\*-------SDK User receives this in string--------\n' + '${event.jsonString} \n' '------------------------------------------*/\n' + outputText  ;
        _logScrollController.jumpTo(0);
      });
    });

    _logStreamSub = EventBusUtil.listen((event){
      // action
      setState(() {
        // extract jsonString from event
        outputText = '${event.log} \n' + outputText;
        _logScrollController.jumpTo(0);
      });
    });
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _myController.dispose();
    _logScrollController.dispose();
    _floorTxtController.dispose();
    _destFloorTxtController.dispose();
    _towerIdTxtController.dispose();
    _zoneIdTxtController.dispose();
    _userTokenTxtController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));


    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 30,
                child: TextField(
                  controller: _floorTxtController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'floor',
                  ),
                ),
              ),

              const SizedBox(width: 5),

              SizedBox(
                width: 100,
                height: 30,
                child: TextField(
                  controller: _towerIdTxtController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'towerId',
                  ),
                ),
              ),

              const SizedBox(width: 5),

              SizedBox(
                width: 100,
                height: 30,
                child: TextField(
                  controller: _zoneIdTxtController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'zoneId',
                  ),
                ),
              ),


            ],
          ),

          const SizedBox(height: 5),

          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 30,
                  child: TextField(
                    controller: _destFloorTxtController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'destFloor',
                    ),
                  ),
                ),
                const SizedBox(width: 105),
                const SizedBox(width: 105),
              ]
          ),

          const SizedBox(height: 5),


            SizedBox(
              width: 310,
              height: 40,
              child: TextField(
                keyboardType: TextInputType.multiline,
                maxLines: 2,
                style: TextStyle(fontSize: 10),
                controller: _userTokenTxtController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(5, 0,  0, 0),
                  border: OutlineInputBorder(),
                  labelText: 'userToken',
                ),
              ),
            ),


          Container (
            alignment: Alignment.bottomLeft,
            margin: EdgeInsets.only(left: 15),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton(
                      style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () {
                        print('"Save" Button  clicked');
                        setState(() {
                          _savePrefs();
                        });
                      },
                      child: const Text('SAVE'),
                    ),
                    const SizedBox(width: 180),
                    TextButton(
                      style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 15)),
                      onPressed: () {
                        print('"DEFAULT" Button  clicked');
                        setState(() {
                          // extract jsonString from event
                          _userTokenTxtController.text = 'CtA02wFY3uYUdtOJMZ15xLA+HMsOl1+QI1novR7A876Cyzo6AoKNbT2Ba6k=';
                          _floorTxtController.text = '23';
                          _destFloorTxtController.text = '2';
                          _towerIdTxtController.text = '${2}';
                          _zoneIdTxtController.text = '${0}';
                        });
                      },
                      child: const Text('DEFAULT'),
                    ),
                  ]
              ),




          ),



          SizedBox(
          width: 200,
          height: 30,
            child:ElevatedButton(
              style: style,
              onPressed: () {
                print('"Current Floor" Button  clicked');
                _sdk.getCurrentFloor();
              },
              child: const Text('Current Floor'),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: 200,
            height: 30,
            child: ElevatedButton(
              style: style,
              onPressed: () {
                print('"Accessible Floors" Button clicked');

                _sdk.getAccessibleFloors(_userTokenTxtController.text, _floorTxtController.text, int.parse(_zoneIdTxtController.text), int.parse(_towerIdTxtController.text));
              },
              child: const Text('Accessible Floors'),
            ),
          ),


          const SizedBox(height: 10),



          SizedBox(
            width: 200,
            height: 30,
            child: ElevatedButton(
                style: style,
                onPressed: () {
                  print('"Lift dispatch" Button clicked');

                  _sdk.liftRequest(_userTokenTxtController.text, _floorTxtController.text, _destFloorTxtController.text, int.parse(_zoneIdTxtController.text), int.parse(_towerIdTxtController.text));
                },
                    child: const Text('Lift dispatch'),
            ),
          ),
          const SizedBox(height: 5),


          Container (
            alignment: Alignment.bottomRight,
            margin: EdgeInsets.only(right: 1),
            child: TextButton(
              style: ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 15)),
              onPressed: () {
                print('"Clear" Button  clicked');
                setState(() {
                  // extract jsonString from event
                  outputText = '';
                });
              },
              child: const Text('CLEAR'),
            ),
          ),

          // log window
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Container(
              margin: EdgeInsets.only(left:5, right: 5),
              decoration: BoxDecoration(
                  color: Colors.black12
              ),
              child: Flex(
                direction: Axis.vertical,
                  children: [
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        controller: _logScrollController,
                        scrollDirection: Axis.vertical,
                        child: Text(
                          outputText,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ]
              ),
            ),
          ),

        ],
      ),
    );
  }
}






