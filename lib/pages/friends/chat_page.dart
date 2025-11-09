// lib/pages/friends/chat_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ваши токены/стили
import 'package:offroad_nav/design/colors.dart';
import 'package:offroad_nav/design/styles.dart';

class ChatPage extends StatefulWidget {
  final String peerUid;
  final String peerName;
  final String? peerAvatar;

  const ChatPage({
    super.key,
    required this.peerUid,
    required this.peerName,
    this.peerAvatar,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();

  late final String _myUid;
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    final me = FirebaseAuth.instance.currentUser;
    _myUid = me?.uid ?? '';
    _chatId = _composeChatId(_myUid, widget.peerUid);
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _composeChatId(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}_${pair[1]}';
  }

  Future<void> _sendText() async {
    final msg = _text.text.trim();
    if (msg.isEmpty || _myUid.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    final msgRef = chatRef.collection('messages').doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(msgRef, {
        'id'        : msgRef.id,
        'chatId'    : _chatId,
        'text'      : msg,
        'from'      : _myUid,
        'to'        : widget.peerUid,
        'type'      : 'text',
        'created_at': now,
        'read'      : false,
      });

      tx.set(chatRef, {
        'chatId'      : _chatId,
        'participants': [_myUid, widget.peerUid],
        'last_message': msg,
        'updated_at'  : now,
      }, SetOptions(merge: true));
    });

    _text.clear();
    
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    bool isMe(String uid) => uid == _myUid;

    return Scaffold(
      backgroundColor: backgroundMainColor,
      appBar: AppBar(
        backgroundColor: backgroundMainColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textMainColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.peerName, style: head1TextStyle),
        actions: [
          // заглушки под звонок/видео — кнопки уже в дизайне
          _circleAction(const Icon(Icons.call_rounded, color: Colors.white)),
          const SizedBox(width: 8),
          _circleAction(const Icon(Icons.videocam_rounded, color: Colors.white)),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Start chatting', style: hintTextStyle),
                  );
                }

                return ListView.builder(
                  controller: _scroll,
                  reverse: true, // последние сообщения внизу
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final mine = isMe(m['from'] as String? ?? '');
                    final text = (m['text'] ?? '').toString();

                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: mine ? buttonSecondBackgroundColor : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(mine ? 16 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 16),
                            ),
                            boxShadow: mine
                                ? null
                                : const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 12, offset: Offset(0, 6))],
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: mine ? Colors.white : textMainColor,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Поле ввода
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: backgroundMainColor,
              child: Row(
                children: [
                  // иконка «прикрепить» — заглушка
                  _circleAction(const Icon(Icons.add_rounded, color: Colors.white), size: 36),
                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      controller: _text,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type message…',
                        hintStyle: hintTextStyle,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFE6E6EA)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFD0D0D6)),
                        ),
                        filled: true,
                        fillColor: surfaceColor,
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // микрофон как во Figma — сейчас отправляет текст
                  _circleAction(const Icon(Icons.mic_rounded, color: Colors.white), onTap: _sendText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAction(Widget icon, {VoidCallback? onTap, double size = 40}) {
    return Material(
      color: buttonSecondBackgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: size, height: size, child: Center(child: icon)),
      ),
    );
  }
}
