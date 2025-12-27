import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ConversationModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String lastSenderUid;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderUid,
  });

  factory ConversationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSenderUid: data['lastSenderUid'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    participants,
    lastMessage,
    lastMessageAt,
    lastSenderUid,
  ];
}

class MessageModel extends Equatable {
  final String id;
  final String senderUid;
  final String receiverUid;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderUid,
    required this.receiverUid,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      receiverUid: data['receiverUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderUid,
    receiverUid,
    text,
    createdAt,
    isRead,
  ];
}
