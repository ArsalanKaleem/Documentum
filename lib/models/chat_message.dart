import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

enum ChatRole { user, assistant, system }

/// A message in the codebase Q&A chat. [sources] holds the relative paths of
/// files retrieved by RAG that grounded an assistant answer.
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required ChatRole role,
    required String content,
    @Default(<String>[]) List<String> sources,
    @Default(false) bool isStreaming,
    DateTime? createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
