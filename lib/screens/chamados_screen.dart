import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Pacote para formatar datas
import 'detalhe_chamado_screen.dart'; // Importe a nova tela do mapa

class ChamadosScreen extends StatelessWidget {
  const ChamadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pega o ID do usuário logado atualmente
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    // Se por algum motivo não houver usuário logado, mostra uma mensagem
    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("Faça login para ver seus chamados.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chamados',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- A CONSULTA CORRETA ESTÁ AQUI ---
        // 1. Acessa a coleção 'chamados'
        // 2. Filtra para mostrar apenas os documentos onde 'destinatarioId' é igual ao ID do usuário logado
        // 3. Ordena os chamados do mais recente para o mais antigo
        stream: FirebaseFirestore.instance
            .collection('chamados')
            .where('destinatarioId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Você ainda não recebeu nenhum chamado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final chamados = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chamados.length,
            itemBuilder: (context, index) {
              final chamado = chamados[index].data() as Map<String, dynamic>;
              
              final String remetenteNome = chamado['remetenteNome'] ?? 'Alguém';
              final String remetenteId = chamado['remetenteId'] ?? '';
              final Timestamp timestamp = chamado['timestamp'] ?? Timestamp.now();
              
              // Formata a data para um formato mais amigável
              final String dataFormatada = DateFormat('dd/MM/yy \'às\' HH:mm').format(timestamp.toDate());

              return ListTile(
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 30,
                ),
                title: Text('$remetenteNome solicitou um chamado.'),
                subtitle: Text(dataFormatada),
                onTap: () {
                  // Navega para a tela do mapa ao clicar, passando os dados necessários
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalheChamadoScreen(
                        remetenteId: remetenteId,
                        remetenteNome: remetenteNome,
                      ),
                    ),
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
