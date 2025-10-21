import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Importe para formatar a hora

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Color _otherUserColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _fetchUserColor();
  }

  Future<void> _fetchUserColor() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.otherUserId).get();
      if (userDoc.exists && mounted) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final int corValor = userData['profileColor'] ?? Colors.grey.toARGB32();
        setState(() {
          _otherUserColor = Color(corValor);
        });
      }
    } catch (e) {
      // Em caso de erro, mantém a cor padrão
      debugPrint("Erro ao buscar cor do usuário: $e");
    }
  }

  // Zera o contador de mensagens não lidas para o usuário atual
  void _markAsRead() {
    if (currentUser != null) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({'unreadCount.${currentUser!.uid}': 0});
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    // Adiciona a nova mensagem
    await chatRef.collection('messages').add({
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // Atualiza os dados do chat principal e incrementa o contador do OUTRO usuário
    await chatRef.set({
      'participants': [currentUser!.uid, widget.otherUserId],
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      // Cria ou atualiza o campo `unreadCount`
      'unreadCount': {
        widget.otherUserId: FieldValue.increment(1),
        currentUser!.uid: 0,
      }
    }, SetOptions(merge: true)); // `merge: true` é crucial aqui

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.otherUserName.isNotEmpty ? widget.otherUserName : 'Usuário';

    return Scaffold(
      // 1. Cor de fundo alterada para branco
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _otherUserColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('Nenhuma mensagem ainda'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final raw = messages[index].data() as Map<String, dynamic>;
                    final text = (raw['text'] as String?) ?? '';
                    final senderId = (raw['senderId'] as String?) ?? '';
                    final Timestamp? timestamp = raw['timestamp'];
                    
                    final String hora = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    final isMe = senderId == currentUser?.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.black : Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        // 2. Horário exibido dentro do balão
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hora,
                              style: TextStyle(
                                color: isMe ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Mensagem...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
