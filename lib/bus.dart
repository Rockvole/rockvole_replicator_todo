import 'package:flutter/material.dart';

import 'package:event_bus/event_bus.dart';
import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

enum RefreshType { NONE, DOWNLOADING, UPLOADING, UPDATING }

class Bus {
  bool dialogShowing = false;
  Application application;
  EventBus eventBus = EventBus();

  Bus(this.application);

  displayServerStatus(BuildContext context) {
    eventBus
        .on<TransmitStatusDto>()
        .listen((TransmitStatusDto transmitStatusDto) {
      print("EVENT BUS: " + transmitStatusDto.transmitStatus.toString());

      String? message = transmitStatusDto.message;
      switch (transmitStatusDto.transmitStatus) {
        case TransmitStatus.DOWNLOAD_STARTED:
          application.serverStatus = ServerStatus.TRANSMITTING;
          showRefreshDialog(RefreshType.DOWNLOADING, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          break;
        case TransmitStatus.DOWNLOAD_STOPPED:
          application.serverStatus = ServerStatus.USER_STOPPED;
          showRefreshDialog(RefreshType.NONE, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.UPLOAD_STARTED:
          application.serverStatus = ServerStatus.TRANSMITTING;
          showRefreshDialog(RefreshType.UPLOADING, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          break;
        case TransmitStatus.UPDATE_STARTED:
          message = null;
          application.serverStatus = ServerStatus.TRANSMITTING;
          showRefreshDialog(RefreshType.UPDATING, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          break;
        case TransmitStatus.RECORDS_REMAINING:
          break;
        case TransmitStatus.NO_DATA_CONNECTION:
          application.serverStatus = ServerStatus.ERROR;
          break;
        case TransmitStatus.WIFI_NOT_FOUND:
          application.serverStatus = ServerStatus.ERROR;
          showRefreshDialog(RefreshType.NONE, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          //startPreferences();
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.USER_NOT_REGISTERED:
          application.serverStatus = ServerStatus.ERROR;
          if (transmitStatusDto.userInitiated!) {
            //startPreferences();
          }
          break;
        case TransmitStatus.USER_UPDATED:
          application.serverStatus = ServerStatus.COMPLETE;
          application.initialize();
          //pagerAdapter.notifyDataSetChanged();
          break;
        case TransmitStatus.SERVER_NOT_FOUND:
        case TransmitStatus.REMOTE_STATE_ERROR:
          application.serverStatus = ServerStatus.ERROR;
          if (transmitStatusDto.userInitiated!) {
            application.remoteStatus = transmitStatusDto.remoteStatus;
            if (transmitStatusDto.remoteStatus ==
                    RemoteStatus.AUTHENTICATION_FAILED ||
                transmitStatusDto.remoteStatus ==
                    RemoteStatus.EXPECTED_PASSKEY) {
              //startPreferences();
            }
          }
          message = transmitStatusDto.message;
          showRefreshDialog(RefreshType.NONE, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.SOCKET_TIMEOUT:
          application.serverStatus = ServerStatus.ERROR;
          message = transmitStatusDto.message.toString() +
              " " +
              TransmitStatusDto.getDefaultMessage(
                      transmitStatusDto.transmitStatus)
                  .toString();
          showRefreshDialog(RefreshType.NONE, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.UPDATE_COMPLETE:
          message = null;
          application.serverStatus = ServerStatus.COMPLETE;
          break;
        case TransmitStatus.DOWNLOAD_COMPLETE:
        case TransmitStatus.INVALID_SERVER_REQUEST:
        case TransmitStatus.NO_NEW_RECORDS_FOUND:
        case TransmitStatus.PARSE_ERROR:
        case TransmitStatus.RESOURCE_NOT_FOUND:
        case TransmitStatus.UPLOAD_COMPLETE:
          application.serverStatus = ServerStatus.COMPLETE;
          showRefreshDialog(RefreshType.NONE, transmitStatusDto.message,
              transmitStatusDto.isDeterminate, context);
        //supportInvalidateOptionsMenu();
      }
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
        ));
      }
    });
  }

  void showRefreshDialog(RefreshType refreshType, String? startMessage,
      bool determinate, BuildContext context) {
    if (dialogShowing) {
      Navigator.pop(context);
      dialogShowing = false;
    }
    if (refreshType != RefreshType.NONE) {
      dialogShowing = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext buildContext) {
          context = buildContext;
          return Dialog(
            child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator()),
                    Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("Loading ...",
                            style: TextStyle(fontSize: 20))),
                  ],
                )),
          );
        },
      );
    }
  }
}
