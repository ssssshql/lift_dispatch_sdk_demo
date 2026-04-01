library lift_dispatch;

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

// import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:lift_dispatch/event_bus_util.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:lift_dispatch/api.dart';

// export
export 'event_bus_util.dart';

// Api library
class LiftDispatch {
  static var _streamRanging;

  // functions
  Future getCurrentFloor() async {
    // scan for 3 seconds
    // capture the nearest matching beacons
    List<Beacon> beaconList = await scan();

    // add 1 hardcoded ibeacon for testing purppose 2022-02-10
    // var mockiBeacon = new Beacon("E2C56DB5-DFFB-48D2-B060-D0F5A71096E0", 0, 0, -40);
    // beaconList.add(mockiBeacon);

    // send list of beacon with nearest rssi descending order to backend
    beaconList.sort((a, b) {
      return b.rssi.compareTo(a.rssi);
    });

    // for debug
    beaconList.forEach((beacon) => {
          print(
              '${beacon.uuid} | ${beacon.major} | ${beacon.minor} | ${beacon.rssi}')
        });

    // retrieve the floor number and zone from backend
    Api api = Api();
    http.Response response = await api.getCurrentLocation(beaconList);
    String responseStr = handleResponse(response);

    EventBusUtil.fire(JsonStringEvent(responseStr));
  }

  getAccessibleFloors(
      String userToken, String floor, int zoneId, int towerId) async {
    Api api = Api();
    http.Response response =
        await api.getAccessibleFloors(userToken, floor, zoneId, towerId);
    String responseStr = handleResponse(response);

    EventBusUtil.fire(JsonStringEvent(responseStr));
  }

  liftRequest(String userToken, String floor, String destinationFloor,
      int zoneId, int towerId) async {
    Api api = Api();
    http.Response response = await api.liftRequest(
        userToken, floor, destinationFloor, zoneId, towerId);
    String responseStr = handleResponse(response);

    EventBusUtil.fire(JsonStringEvent(responseStr));
  }

  Future<List<Beacon>> scan() async {
    print('scan()');
    EventBusUtil.fire(LogEvent('${DateTime.now()} scan start...'));

    List<Beacon> beaconList = [];

    try {
      // permission check
      if (Platform.isIOS) {
        // note: this function only works in ios
        await flutterBeacon.initializeScanning;
      } else {
        // note: this function only works in android
        await flutterBeacon.initializeAndCheckScanning;
      }
    } on PlatformException catch (e) {
      // library failed to initialize, check code and message
      print('Error: ${e.stacktrace}');
    }

    final regions = <Region>[];

    print('------5------');
    regions.add(Region(
        identifier: '', proximityUUID: 'E2C56DB5-DFFB-48D2-B060-D0F5A71096E0'));

    print('------6------');
    print('start scanning...');
    // to start ranging beacons
    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
      // result contains a region and list of beacons found
      // list can be empty if no matching beacons were found in range
      if (result.beacons.length > 0) {
        // print('Beacon List length: ${result.beacons.length}' );

        // print(' ${result.beacons[0].proximityUUID} | ${result.beacons[0].macAddress} | ${result.beacons[0].major} | ${result.beacons[0].minor}, ');
        for (var beacon in result.beacons) {
          print('Detected beacons..');
          beaconList.add(Beacon(
              beacon.proximityUUID, beacon.major, beacon.minor, beacon.rssi));
        }
      }
    });

    await Future.delayed(const Duration(seconds: 10), () {
      print('stopped scanning....');
      EventBusUtil.fire(LogEvent('${DateTime.now()} scan complete...'));

      // x seconds have past, you can do your work
      _streamRanging.cancel();

      beaconList.forEach((beacon) => {
            print(
                '${beacon.uuid} | ${beacon.major} | ${beacon.minor} | ${beacon.rssi}')
          });
    });

    return beaconList;
  }

  stopScan() async {
    // to stop ranging beacons
    _streamRanging.cancel();
  }

  //
  String handleResponse(http.Response response) {
    var status;
    var content;
    var contentObj;
    Map<String, dynamic> jsonObj = json.decode(response.body);

    if (response.statusCode == 200 && jsonObj['status'] == 'Success') {
      status = "Success";
      content = "data";
      contentObj = jsonObj['data'];
    } else {
      status = "Fail";
      content = "error";
      if (jsonObj['error'] != null) {
        contentObj = jsonObj['error'];
      } else {
        contentObj = {
          "code": "ERR_UNKNOWN_SERVER_ERROR",
          "message": "Unknown Error"
        };
      }
    }

    var appResponse = {"status": status, content: contentObj};

    return json.encode(appResponse);
  }
}

class ResponseSuccess {}

class ResponseFailed {}

class Beacon {
  final String uuid;
  final int major;
  final int minor;
  final int rssi;

  const Beacon(this.uuid, this.major, this.minor, this.rssi);
}
