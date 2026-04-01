import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'assets/constants.dart';
import 'lift_dispatch.dart';

class Api {

  // const
  String host = Constants.host;

  // /liftRequest
  Future<http.Response> liftRequest(String userToken, String floor, String destinationFloor, int zoneId, int towerId) async {
    try {
      var now = DateTime.now();
      var endpoint = '/liftRequest';
      var url = '${host}${endpoint}';


      // build body
      var data = {
        "towerId": towerId,
        "floor": floor,
        "destinatedFloor": destinationFloor,
        "zoneId": zoneId,
        "userToken": userToken,
      };

      print('REQ | ${url}');
      String reqLog = '${now} ${endpoint} | REQ | ${data.toString()}';
      EventBusUtil.fire(LogEvent(reqLog));
      print(reqLog);

      print('----1-----');
      final response = await http.post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'txno': Uuid().v4()
          },
          body: jsonEncode(data)
      ).timeout(Duration(seconds: 10));

      print('Status Code: ${response.statusCode}');
      print('----2-----');

      // if (response.statusCode == 200) {
      var resLog = '${now} ${endpoint} | RES | ${response.body}';
      print(resLog);
      EventBusUtil.fire(LogEvent(resLog));
      return response;
      // }
    } catch(e, stacktrace) {
      http.Response response = exceptionResponse(e, stacktrace);
      return response;
    }
  }


  // /getAccessibleFloors
  Future<http.Response> getAccessibleFloors(String userToken, String floor, int zoneId, int towerId) async {
    try {
      var now = DateTime.now();
      var endpoint = '/getAccessibleFloors';
      var url = '${host}${endpoint}';

      // build body
      var data = {
        "towerId": towerId,
        "floor": floor,
        "zoneId": zoneId,
        "userToken": userToken
      };

      print('REQ | ${url}');
      String reqLog = '${now} ${endpoint} | REQ | ${data.toString()}';
      EventBusUtil.fire(LogEvent(reqLog));
      print(reqLog);

      print('----1-----');
      final response = await http.post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'txno': Uuid().v4()
          },
          body: jsonEncode(data)
      ).timeout(Duration(seconds: 10));

      print('Status Code: ${response.statusCode}');
      print('----2-----');

      // if (response.statusCode == 200) {
      var resLog = '${now} ${endpoint} | RES | ${response.body}';
      print(resLog);
      EventBusUtil.fire(LogEvent(resLog));
      return response;
      // }
    } catch(e, stacktrace) {
      http.Response response = exceptionResponse(e,stacktrace);
      return response;
    }
  }


  // /getCurrentLocation
  Future<http.Response> getCurrentLocation(List<Beacon> beaconList) async {
    try {
      var now = DateTime.now();
      var endpoint = '/getCurrentLocation';
      var url = '${host}${endpoint}';

      // build body
      List<dynamic> beaconDynamicList = [];
      beaconList.forEach((beacon) {
        var beaconDyamic = {
          "rssi": beacon.rssi,
          "uuid": beacon.uuid,
          "major": beacon.major,
          "minor": beacon.minor
        };
        beaconDynamicList.add(beaconDyamic);
      });
      var data = {
          "iBeaconList": beaconDynamicList
      };

      // mock success request
      // var data = {
      //   "iBeaconList": [
      //     { "rssi": -5,
      //       "uuid": "a1389161-727c-457b-999b-e204f1ebfee0",
      //       "major": 12,
      //       "minor": 0}, {"rssi": -22, "uuid": "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0", "major": 0, "minor": 0}
      //   ]};

      print('REQ | ${url}');
      String reqLog = '${now} getCurrentLocation | REQ | ${data.toString()}';
      EventBusUtil.fire(LogEvent(reqLog));

      print(reqLog);
      print('----1-----');
      final response = await http.post(
          Uri.parse(url),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
            'txno': Uuid().v4()
          },
          body: jsonEncode(data)
      );

      print('Status Code: ${response.statusCode}');
      print('----2-----');

      // if (response.statusCode == 200) {
      var resLog = '${now} getCurrentLocation | RES | ${response.body}';
      print(resLog);
      EventBusUtil.fire(LogEvent(resLog));
      return response;
      // }
    } catch(e, stacktrace) {
      http.Response response = exceptionResponse(e, stacktrace);
      return response;
    }
  }



  http.Response exceptionResponse(e, stacktrace) {
    var now = DateTime.now();
    var failBody = {
      "status": "Fail",
      "error": {
        "code": "ERR_GENERIC_EXCEPTION",
        "message": e.toString()
      }
    };
    http.Response response = http.Response(jsonEncode(failBody), 400);
    var resLog = '${now} getCurrentLocation | RES | ${response.body}';
    print(resLog);
    EventBusUtil.fire(LogEvent(resLog));
    return response;
  }
}