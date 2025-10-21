import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversasScreen extends StatelessWidget {
  const ConversasScreen({super.key});

  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final String userId = getCurrentUserId();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Conversas',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // <-- CORREÇÃO: trocado print por debugPrint
            debugPrint("ERRO DO FIREBASE: ${snapshot.error}");
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Ocorreu um erro. Verifique o console para criar um índice no Firestore, se necessário.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Você ainda não possui nenhuma conversa.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              
              final List participants = chatData['participants'] ?? [];
              if (participants.isEmpty) return const SizedBox();

              final String otherUserId =
                  participants.firstWhere((id) => id != userId, orElse: () => '');
              if (otherUserId.isEmpty) return const SizedBox();

              final unreadCountMap = chatData['unreadCount'] as Map<String, dynamic>? ?? {};
              final hasUnread = (unreadCountMap[userId] ?? 0) > 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text("..."));
                  }
                  
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const SizedBox();
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                  final String nome = userData['nome'] ?? 'Usuário';
                  
                  final String ultimaMensagem = chatData['lastMessage'] ?? '';
                  final Timestamp? timestamp = chatData['lastMessageTime'];

                  final String hora = timestamp != null
                      ? TimeOfDay.fromDateTime(timestamp.toDate())
                          .format(context)
                      : '';

                  final int corValor = userData['profileColor'] ?? Colors.grey.toARGB32();
                  final Color corDoPerfil = Color(corValor);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: corDoPerfil, // Usa a cor do perfil
                          child: const Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                    title: Text(
                      nome, 
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black,
                      )
                    ),
                    subtitle: Text(
                      ultimaMensagem,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal, 
                        color: hasUnread ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                          Text(
                           hora,
                           style: TextStyle(fontSize: 12, color: hasUnread ? Colors.black87 : Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          if(hasUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(width: 10, height: 10),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'chatId': chatDoc.id,
                          'otherUserId': otherUserId,
                          'otherUserName': nome,
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}