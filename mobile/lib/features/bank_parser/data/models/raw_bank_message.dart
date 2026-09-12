import 'dart:convert';
import 'package:crypto/crypto.dart';

enum ProcessingStatus {
  received,
  parsed,
  confirmed,
  ignored,
  failed,
}

class RawBankMessage {
  final String localId;
  final String sender;
  final String messageBody;
  final DateTime receivedAt;
  final String? detectedBank;
  final ProcessingStatus processingStatus;
  final String messageHash;
  final String parserVersion;
  final DateTime createdAt;

  RawBankMessage({
    required this.localId,
    required this.sender,
    required this.messageBody,
    required this.receivedAt,
    this.detectedBank,
    this.processingStatus = ProcessingStatus.received,
    String? messageHash,
    this.parserVersion = '1.0',
    DateTime? createdAt,
  })  : messageHash = messageHash ?? sha256.convert(utf8.encode(messageBody)).toString(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'sender': sender,
        // messageBody is kept local, never serialized to remote APIs
        'receivedAt': receivedAt.toIso8601String(),
        'detectedBank': detectedBank,
        'processingStatus': processingStatus.name,
        'messageHash': messageHash,
        'parserVersion': parserVersion,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RawBankMessage.fromJson(Map<String, dynamic> json) => RawBankMessage(
        localId: json['localId'] as String,
        sender: json['sender'] as String,
        messageBody: json['messageBody'] as String? ?? '',
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        detectedBank: json['detectedBank'] as String?,
        processingStatus: ProcessingStatus.values.firstWhere(
          (e) => e.name == json['processingStatus'],
          orElse: () => ProcessingStatus.received,
        ),
        messageHash: json['messageHash'] as String?,
        parserVersion: json['parserVersion'] as String? ?? '1.0',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
