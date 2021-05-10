import 'package:event_bus/event_bus.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class Bus {
  EventBus eventBus = EventBus();

  setupBus() {
    eventBus.on<TransmitStatusDto>().listen((event) {
// All events are of type UserLoggedInEvent (or subtypes of it).
      print("MY EVENT BUS"+event.transmitStatus.toString());
    });
  }
}
