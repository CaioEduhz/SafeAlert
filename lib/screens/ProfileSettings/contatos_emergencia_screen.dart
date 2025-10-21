import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'adicionar_contato_screen.dart';

class ContatosEmergenciaScreen extends StatelessWidget {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  ContatosEmergenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Cor de fundo alterada para branco
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Contatos de Emergência"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('contatos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final contatos = snapshot.data?.docs ?? [];

          if (contatos.isEmpty) {
            // 2. Texto centralizado e com padding para não ficar colado nas bordas
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Você ainda não adicionou nenhum contato de emergência.",
                  textAlign: TextAlign.center, // Centraliza o texto
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: contatos.length,
            itemBuilder: (context, index) {
              final contato = contatos[index];
              return ListTile(
                title: Text(contato['nome']),
                subtitle: Text(contato['telefone']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(userId)
                        .collection('contatos')
                        .doc(contato.id)
                        .delete();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdicionarContatoScreen()));
        },
        // 3. Cores do botão alteradas
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
