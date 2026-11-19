import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Manages peer-to-peer VoIP voice calls via WebRTC + Firebase RTDB `/calls/{orderId}`.
class WebRtcCallService {
  static const Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  DatabaseReference? _callRef;
  StreamSubscription<DatabaseEvent>? _answerSub;
  StreamSubscription<DatabaseEvent>? _iceSub;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _disposed = false;
  final void Function(String status)? onStatusChanged;

  WebRtcCallService({this.onStatusChanged});

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  Future<void> startCall({
    required String orderId,
    String callerRole = 'CUSTOMER',
  }) async {
    if (_disposed || orderId.isEmpty) return;
    try {
      _peerConnection = await createPeerConnection(_rtcConfig);
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }

      if (Firebase.apps.isNotEmpty) {
        _callRef = FirebaseDatabase.instance.ref('calls/$orderId');
        await _callRef!.update({
          'caller_role': callerRole,
          'status': 'RINGING',
          'updated_at': ServerValue.timestamp,
        });

        _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
          if (_disposed || _callRef == null) return;
          _callRef!.child('caller_candidates').push().set({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }).catchError((_) {});
        };

        _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
          onStatusChanged?.call(state.name);
        };

        final offer = await _peerConnection!.createOffer({
          'offerToReceiveAudio': true,
          'offerToReceiveVideo': false,
        });
        await _peerConnection!.setLocalDescription(offer);
        await _callRef!.child('offer').set({
          'sdp': offer.sdp,
          'type': offer.type,
        });

        _listenSignaling();
      } else {
        onStatusChanged?.call('LOCAL_ONLY');
      }
    } catch (e) {
      debugPrint('[WebRtcCallService] fallback/unavailable: $e');
      onStatusChanged?.call('UNAVAILABLE');
    }
  }

  void _listenSignaling() {
    if (_callRef == null) return;
    _answerSub?.cancel();
    _answerSub = _callRef!.child('answer').onValue.listen((event) async {
      if (_disposed || _peerConnection == null) return;
      final raw = event.snapshot.value;
      if (raw is Map && raw['sdp'] != null && raw['type'] != null) {
        try {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(raw['sdp'].toString(), raw['type'].toString()),
          );
          onStatusChanged?.call('CONNECTED');
        } catch (_) {}
      }
    });

    _iceSub?.cancel();
    _iceSub =
        _callRef!.child('callee_candidates').onChildAdded.listen((event) async {
      if (_disposed || _peerConnection == null) return;
      final raw = event.snapshot.value;
      if (raw is Map && raw['candidate'] != null) {
        try {
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              raw['candidate'].toString(),
              raw['sdpMid']?.toString(),
              raw['sdpMLineIndex'] is int
                  ? raw['sdpMLineIndex'] as int
                  : int.tryParse(raw['sdpMLineIndex']?.toString() ?? '0') ?? 0,
            ),
          );
        } catch (_) {}
      }
    });
  }

  Future<bool> toggleMute([bool? forceValue]) async {
    _isMuted = forceValue ?? !_isMuted;
    try {
      for (final track in _localStream?.getAudioTracks() ?? const []) {
        track.enabled = !_isMuted;
      }
    } catch (_) {}
    return _isMuted;
  }

  Future<bool> toggleSpeaker([bool? forceValue]) async {
    _isSpeakerOn = forceValue ?? !_isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
    return _isSpeakerOn;
  }

  Future<void> endCall() async {
    if (_disposed) return;
    _disposed = true;
    await _answerSub?.cancel();
    await _iceSub?.cancel();
    try {
      if (_callRef != null && Firebase.apps.isNotEmpty) {
        await _callRef!.update({
          'status': 'ENDED',
          'ended_at': ServerValue.timestamp,
        });
      }
    } catch (_) {}
    try {
      for (final track in _localStream?.getTracks() ?? const []) {
        await track.stop();
      }
      await _localStream?.dispose();
    } catch (_) {}
    try {
      await _peerConnection?.close();
    } catch (_) {}
    _localStream = null;
    _peerConnection = null;
  }
}

