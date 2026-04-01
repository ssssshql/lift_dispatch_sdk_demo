import 'dart:async';
import 'package:event_bus/event_bus.dart';


class EventBusUtil{
  static EventBus _eventBus = EventBus();

  static EventBus getInstance(){
    if(_eventBus==null){
      _eventBus=EventBus();
    }
    return _eventBus;
  }

  static StreamSubscription<T> listen<T extends Event>(Function(T event) onData) {
    if(_eventBus==null){
      _eventBus=EventBus();
    }
    return _eventBus.on<T>().listen(onData);
  }

  static void fire<T extends Event>(T e) {
    if(_eventBus==null){
      _eventBus=EventBus();
    }
    _eventBus.fire(e);
  }
}

abstract class Event {}


class LogEvent extends Event{
  final String log;
  LogEvent(this.log);
}

class JsonStringEvent extends Event{
  final String jsonString;
  JsonStringEvent(this.jsonString);
}
