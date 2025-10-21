// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetalhesDenunciaScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetalhesDenunciaScreen({super.key, required this.data});
  
  // 1. ADICIONADA A MESMA FUNÇÃO DA TELA DE DENÚNCIAS
  String _formatarTempoPostagem(Duration tempoPostagem) {
    if (tempoPostagem.inDays > 0) {
      return '${tempoPostagem.inDays}d atrás';
    } else if (tempoPostagem.inHours > 0) {
      final horas = tempoPostagem.inHours;
      final minutos = tempoPostagem.inMinutes % 60;
      if (minutos == 0) {
        return '${horas}h atrás'; // Mostra apenas a hora se os minutos forem 0
      }
      return '${horas}h ${minutos}m atrás'; // Mostra horas e minutos
    } else {
      final minutos = tempoPostagem.inMinutes;
      if (minutos < 1) {
        return 'agora mesmo';
      }
      return '${minutos}m atrás'; // Mostra apenas os minutos
    }
  }

  // Função para mostrar a imagem ampliada num diálogo
  void _mostrarImagemAmpliada(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants': [me.uid, otherUserId],
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {
        me.uid: 0,
        otherUserId: 0,
      }
    }, SetOptions(merge: true));

    if (context.mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    
    // 2. A LÓGICA DE FORMATAÇÃO AGORA ESTÁ DENTRO DA FUNÇÃO
    final String tempoTexto;
    if (timestamp != null) {
        final tempoPostagem = DateTime.now().difference(timestamp);
        tempoTexto = _formatarTempoPostagem(tempoPostagem);
    } else {
        tempoTexto = "Data indisponível";
    }

    final nomeUsuario =
        (data['nome_usuario'] as String?)?.trim().isNotEmpty == true
            ? data['nome_usuario']
            : 'Usuário Anônimo';

    final descricao = (data['descricao'] as String?)?.trim().isNotEmpty == true
        ? data['descricao']
        : 'Sem descrição';

    final List<String> imagensUrls =
        (data['imagens_urls'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    final String? uid = data['uid'];

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
                FutureBuilder<DocumentSnapshot>(
                  future: uid != null ? FirebaseFirestore.instance.collection('usuarios').doc(uid).get() : null,
                  builder: (context, userSnapshot) {
                    Color corDoPerfil = Colors.grey;
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final int corValor = userData['profileColor'] ?? Colors.grey.toARGB32();
                      corDoPerfil = Color(corValor);
                    }
                    return CircleAvatar(
                      backgroundColor: corDoPerfil,
                      child: const Icon(Icons.person, color: Colors.white),
                    );
                  },
                ),
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
                  color: Colors.white,
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
            // 3. A VARIÁVEL COM O TEMPO FORMATADO É USADA AQUI
            Text(tempoTexto, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),

            if (imagensUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagensUrls.length,
                  itemBuilder: (context, index) {
                    final imageUrl = imagensUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => _mostrarImagemAmpliada(context, imageUrl),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            width: 250,
                            fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 250,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 250,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 12),
            Text(descricao, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

