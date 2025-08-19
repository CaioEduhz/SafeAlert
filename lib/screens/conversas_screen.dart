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
            .where('users', arrayContains: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "Você ainda não possui nenhuma conversa",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index];
              final List users = chatData['users'];
              final String otherUserId =
                  users.firstWhere((id) => id != userId);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();

                  final user = userSnapshot.data!;
                  final String nome = user['nome'] ?? 'Usuário';
                  final String ultimaMensagem =
                      chatData['ultimaMensagem'] ?? '';
                  final Timestamp? timestamp = chatData['timestamp'];
                  final String hora = timestamp != null
                      ? TimeOfDay.fromDateTime(timestamp.toDate())
                          .format(context)
                      : '';

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(nome),
                    subtitle: Text(
                      ultimaMensagem,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      hora,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat',
                        arguments: {
                          'chatId': chatData.id,
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
