import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NovaDenunciaScreen extends StatefulWidget {
  @override
  _NovaDenunciaScreenState createState() => _NovaDenunciaScreenState();
}

class _NovaDenunciaScreenState extends State<NovaDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensagemController = TextEditingController();

  String? zonaSelecionada;
  String? bairroSelecionado;
  File? imagemSelecionada;

  final zonas = ['Zona Leste', 'Zona Sul', 'Centro', 'Zona Norte', 'Zona Oeste'];

  final bairrosPorZona = {
    'Zona Leste': ['São Miguel Paulista', 'Itaim Paulista', 'Itaquera'],
    'Zona Sul': ['Capão Redondo', 'Cambuci', 'Ipiranga'],
    'Centro': ['Sé', 'Paulista', 'Bela Vista'],
    'Zona Norte': ['Santana', 'Tremembé', 'Vila Maria'],
    'Zona Oeste': ['Osasco', 'Sapopemba', 'Butantã'],
  };

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        imagemSelecionada = File(image.path);
      });
    }
  }

  Future<void> _enviarDenuncia() async {
    if (!_formKey.currentState!.validate() || zonaSelecionada == null || bairroSelecionado == null) return;

    String? imageUrl;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    String nomeUsuario = 'Usuário Anônimo';

    try {
      // Buscar nome do usuário a partir da coleção "usuarios"
      if (uid != null) {
        final docUsuario = await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (docUsuario.exists) {
          nomeUsuario = docUsuario.data()?['nome'] ?? 'Usuário Anônimo';
        }
      }

      if (imagemSelecionada != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('denuncias/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await ref.putFile(imagemSelecionada!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('denuncias').add({
        'uid': uid,
        'nome_usuario': nomeUsuario,
        'zona': zonaSelecionada,
        'bairro': bairroSelecionado,
        'descricao': _mensagemController.text.trim(),
        'imagem_url': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Denúncia enviada com sucesso!")));
      Navigator.pop(context);
    } catch (e) {
      print("Erro ao enviar denúncia: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao enviar denúncia")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bairros = zonaSelecionada != null ? bairrosPorZona[zonaSelecionada] ?? [] : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Nova Denúncia"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                hint: Text("Selecione a Zona"),
                value: zonaSelecionada,
                dropdownColor: Colors.white,
                onChanged: (value) => setState(() {
                  zonaSelecionada = value;
                  bairroSelecionado = null;
                }),
                items: zonas.map((zona) {
                  return DropdownMenuItem<String>(
                    value: zona,
                    child: Text(zona),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecione uma zona' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                hint: Text("Selecione o Bairro"),
                value: bairroSelecionado,
                dropdownColor: Colors.white,
                onChanged: (value) => setState(() => bairroSelecionado = value),
                items: bairros.map((bairro) {
                  return DropdownMenuItem<String>(
                    value: bairro,
                    child: Text(bairro),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Selecione um bairro' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _mensagemController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Descreva o ocorrido...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite uma mensagem' : null,
              ),

              /* Botão de imagem (opcional) 
              SizedBox(height: 10),
              if (imagemSelecionada != null)
                Image.file(imagemSelecionada!, height: 150),
              TextButton.icon(
                onPressed: _escolherImagem,
                icon: Icon(Icons.image, color: Colors.red),
                label: Text("Selecionar Imagem", style: TextStyle(color: Colors.red)),
              ),
              */

              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _enviarDenuncia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text("Enviar Denúncia"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
