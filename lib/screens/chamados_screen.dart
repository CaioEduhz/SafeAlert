import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChamadosScreen extends StatelessWidget {
  const ChamadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;

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
        stream: FirebaseFirestore.instance
            .collection('chamados')
            .where('destinatarioId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chamados = snapshot.data?.docs ?? [];

          if (chamados.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não recebeu nenhum chamado.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: chamados.length,
            itemBuilder: (context, index) {
              final chamado = chamados[index];
              final String nomeRemetente = chamado['remetenteNome'] ?? 'Usuário';
              final Timestamp timestamp = chamado['timestamp'];
              final String dataHora = timestamp.toDate().toString();

              return ListTile(
                leading: const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 30),
                title: Text('$nomeRemetente solicitou um chamado.'),
                subtitle: Text(dataHora),
              );
            },
          );
        },
      ),
    );
  }
}
