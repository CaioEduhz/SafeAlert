import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalhesDenunciaScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetalhesDenunciaScreen({super.key, required this.data});

  // Gera um chatId determinístico para o par de usuários
  String _pairId(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}_${pair[1]}';
  }

  Future<void> _iniciarConversa(BuildContext context) async {
    final otherUserId = (data['uid'] as String?)?.trim();
    final otherUserName =
        (data['nome_usuario'] as String?)?.trim().isNotEmpty == true
            ? data['nome_usuario']
            : 'Usuário';

    final me = FirebaseAuth.instance.currentUser;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para iniciar uma conversa.')),
      );
      return;
    }
    if (otherUserId == null || otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário da denúncia inválido.')),
      );
      return;
    }

    final chatId = _pairId(me.uid, otherUserId);

    // Garante que o documento do chat exista (ou faça merge se já existir)
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [me.uid, otherUserId],
      // esses campos serão atualizados quando enviar mensagens
      'lastMessage': FieldValue.delete(),
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Navega já com os 3 argumentos esperados pela rota /chat
    // (chatId, otherUserId, otherUserName)
    // ↓↓↓
    // ignore: use_build_context_synchronously
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final tempo = timestamp != null
        ? DateTime.now().difference(timestamp)
        : Duration.zero;

    String tempoTexto;
    if (tempo.inDays >= 1) {
      tempoTexto = '${tempo.inDays} dias atrás';
    } else {
      final horas = tempo.inHours;
      final minutos = tempo.inMinutes % 60;
      tempoTexto = '${horas}h ${minutos}min atrás';
    }

    final nomeUsuario =
        (data['nome_usuario'] as String?)?.trim().isNotEmpty == true
            ? data['nome_usuario']
            : 'Usuário Anônimo';

    final descricao = (data['descricao'] as String?)?.trim().isNotEmpty == true
        ? data['descricao']
        : 'Sem descrição';

    final imagemUrl = (data['imagem_url'] as String?); // <<< usa imagem_url

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denúncia'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nomeUsuario,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'conversar') {
                      _iniciarConversa(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'conversar',
                      child: Text('Iniciar conversa'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(tempoTexto, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            if (imagemUrl != null && imagemUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(imagemUrl),
              ),
            const SizedBox(height: 12),
            Text(descricao, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
