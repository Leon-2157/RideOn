import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Manages peer-to-peer VoIP voice calls via WebRTC + Firebase RTDB signaling
/// under `/calls/{orderId}` without incurring PSTN telephony fees.
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
  StreamSubscription<DatabaseEvent>? _calleeIceSub;

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _disposed = false;

  /// Callback invoked when peer connection state changes or signaling fails gracefully.
  final void Function(String status)? onStatusChanged;

  WebRtcCallService({this.onStatusChanged});

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  /// Starts an outgoing audio-only WebRTC call and publishes the SDP offer + ICE
  /// candidates to Firebase RTDB `/calls/{orderId}`. Safe no-op in headless/test runs.
  Future<void> startCall({
    required String orderId,
    required String callerRole,
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

        _listenForAnswer();
      } else {
        onStatusChanged?.call('LOCAL_ONLY');
      }
    } catch (e) {
      debugPrint('[WebRtcCallService] fallback/unavailable: $e');
      onStatusChanged?.call('UNAVAILABLE');
    }
  }

  void _listenForAnswer() {
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
        } catch (e) {
          debugPrint('[WebRtcCallService] answer error: $e');
        }
      }
    });

    _calleeIceSub?.cancel();
    _calleeIceSub =
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

  /// Toggles microphone mute state on local audio tracks.
  Future<bool> toggleMute([bool? forceValue]) async {
    _isMuted = forceValue ?? !_isMuted;
    try {
      for (final track in _localStream?.getAudioTracks() ?? const []) {
        track.enabled = !_isMuted;
      }
    } catch (_) {}
    return _isMuted;
  }

  /// Toggles loudspeaker routing via WebRTC Helper.
  Future<bool> toggleSpeaker([bool? forceValue]) async {
    _isSpeakerOn = forceValue ?? !_isSpeakerOn;
    try {
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (_) {}
    return _isSpeakerOn;
  }

  /// Closes RTCPeerConnection, stops audio tracks, and marks `/calls/{orderId}` ENDED.
  Future<void> endCall() async {
    if (_disposed) return;
    _disposed = true;

    await _answerSub?.cancel();
    await _calleeIceSub?.cancel();

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

