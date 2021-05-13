import 'package:flutter/material.dart';

import 'package:event_bus/event_bus.dart';
import 'package:rockvole_replicator_todo/rockvole_replicator_todo.dart';
import 'package:rockvole_db/rockvole_web_services.dart';

class Bus {
  Application application;
  EventBus eventBus = EventBus();

  Bus(this.application);

  displayServerStatus(BuildContext context) {
    eventBus.on<TransmitStatusDto>().listen((TransmitStatusDto transmitStatusDto) {
      print("EVENT BUS: "+transmitStatusDto.transmitStatus.toString());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Adding something"),
      ));

      String? message=transmitStatusDto.message;
      switch(transmitStatusDto.transmitStatus) {
        case TransmitStatus.DOWNLOAD_STARTED:
          application.serverStatus=ServerStatus.TRANSMITTING;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.DOWNLOADING, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          break;
        case TransmitStatus.DOWNLOAD_STOPPED:
          application.serverStatus=ServerStatus.USER_STOPPED;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.NONE, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.UPLOAD_STARTED:
          application.serverStatus=ServerStatus.TRANSMITTING;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.UPLOADING, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          break;
        case TransmitStatus.UPDATE_STARTED:
          message=null;
          application.serverStatus=ServerStatus.TRANSMITTING;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.UPDATING, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          break;
        case TransmitStatus.RECORDS_REMAINING:
          break;
        case TransmitStatus.NO_DATA_CONNECTION:
          application.serverStatus=ServerStatus.ERROR;
          break;
        case TransmitStatus.WIFI_NOT_FOUND:
          application.serverStatus=ServerStatus.ERROR;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.NONE, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          //startPreferences();
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.USER_NOT_REGISTERED:
          application.serverStatus=ServerStatus.ERROR;
          if(transmitStatusDto.userInitiated!) {
            //startPreferences();
          }
          break;
        case TransmitStatus.USER_UPDATED:
          application.serverStatus=ServerStatus.COMPLETE;
          application.initialize();
          //pagerAdapter.notifyDataSetChanged();
          break;
        case TransmitStatus.SERVER_NOT_FOUND:
        case TransmitStatus.REMOTE_STATE_ERROR:
          application.serverStatus=ServerStatus.ERROR;
          if(transmitStatusDto.userInitiated!) {
            application.remoteStatus=transmitStatusDto.remoteStatus;
            if (transmitStatusDto.remoteStatus == RemoteStatus.AUTHENTICATION_FAILED
                || transmitStatusDto.remoteStatus == RemoteStatus.EXPECTED_PASSKEY    ) {
              //startPreferences();
            }
          }
          message=transmitStatusDto.message;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.NONE, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.SOCKET_TIMEOUT:
          application.serverStatus=ServerStatus.ERROR;
          message=transmitStatusDto.message.toString()+" "+TransmitStatusDto.getDefaultMessage(transmitStatusDto.transmitStatus).toString();
          //showRefreshDialog(RefreshDialogFragment.RefreshType.NONE, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          //supportInvalidateOptionsMenu();
          break;
        case TransmitStatus.UPDATE_COMPLETE:
          message=null;
          application.serverStatus=ServerStatus.COMPLETE;
          break;
        case TransmitStatus.DOWNLOAD_COMPLETE:
        case TransmitStatus.INVALID_SERVER_REQUEST:
        case TransmitStatus.NO_NEW_RECORDS_FOUND:
        case TransmitStatus.PARSE_ERROR:
        case TransmitStatus.RESOURCE_NOT_FOUND:
        case TransmitStatus.UPLOAD_COMPLETE:
          application.serverStatus=ServerStatus.COMPLETE;
          //showRefreshDialog(RefreshDialogFragment.RefreshType.NONE, transmitStatusDto.getMessage(), transmitStatusDto.isDeterminate());
          //supportInvalidateOptionsMenu();
      }
    });
  }
}
