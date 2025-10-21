// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NovaDenunciaScreen extends StatefulWidget {
  const NovaDenunciaScreen({super.key});

  @override
  State<NovaDenunciaScreen> createState() => _NovaDenunciaScreenState();
}

class _NovaDenunciaScreenState extends State<NovaDenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mensagemController = TextEditingController();

  String? zonaSelecionada;
  String? bairroSelecionado;
  List<File> imagensSelecionadas = [];
  bool _carregando = false;

  final zonas = ['Zona Leste', 'Zona Sul', 'Centro', 'Zona Norte', 'Zona Oeste'];

  final bairrosPorZona = {
    'Zona Leste': ['São Miguel Paulista', 'Itaim Paulista', 'Itaquera'],
    'Zona Sul': ['Capão Redondo', 'Cambuci', 'Ipiranga'],
    'Centro': ['Sé', 'Paulista', 'Bela Vista'],
    'Zona Norte': ['Santana', 'Tremembé', 'Vila Maria'],
    'Zona Oeste': ['Osasco', 'Sapopemba', 'Butantã'],
  };

  Future<void> _escolherImagens() async {
    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);

    if (images.isNotEmpty) {
      setState(() {
        imagensSelecionadas.addAll(images.map((xfile) => File(xfile.path)));
      });
    }
  }

  void _removerImagem(int index) {
    setState(() {
      imagensSelecionadas.removeAt(index);
    });
  }

  Future<void> _enviarDenuncia() async {
    // 1ª CORREÇÃO: Adicionadas chaves {} ao 'if'
    if (!_formKey.currentState!.validate() ||
        zonaSelecionada == null ||
        bairroSelecionado == null) {
      return;
    }

    setState(() => _carregando = true);

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    String nomeUsuario = 'Usuário Anônimo';
    List<String> imageUrls = [];

    try {
      if (uid != null) {
        final docUsuario =
            await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
        if (docUsuario.exists) {
          nomeUsuario = docUsuario.data()?['nome'] ?? 'Usuário Anônimo';
        }
      }

      if (imagensSelecionadas.isNotEmpty) {
        for (var file in imagensSelecionadas) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('denuncias/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      await FirebaseFirestore.instance.collection('denuncias').add({
        'uid': uid,
        'nome_usuario': nomeUsuario,
        'zona': zonaSelecionada,
        'bairro': bairroSelecionado,
        'descricao': _mensagemController.text.trim(),
        'imagens_urls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Denúncia enviada com sucesso!")));
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Erro ao enviar denúncia")));
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bairros =
        zonaSelecionada != null ? bairrosPorZona[zonaSelecionada] : [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Nova Denúncia"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: zonaSelecionada,
                decoration: InputDecoration(
                  labelText: "Selecione a Zona",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                onChanged: (value) => setState(() {
                  zonaSelecionada = value;
                  bairroSelecionado = null;
                }),
                items: zonas.map((zona) => DropdownMenuItem<String>(value: zona, child: Text(zona))).toList(),
                validator: (value) => value == null ? 'Selecione uma zona' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: bairroSelecionado,
                decoration: InputDecoration(
                  labelText: "Selecione o Bairro",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                onChanged: (value) => setState(() => bairroSelecionado = value),
                items: bairros?.map((bairro) => DropdownMenuItem<String>(value: bairro, child: Text(bairro))).toList() ?? [],
                validator: (value) => value == null ? 'Selecione um bairro' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _mensagemController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Descreva o ocorrido...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite uma mensagem' : null,
              ),
              const SizedBox(height: 20),
              if (imagensSelecionadas.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagensSelecionadas.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                imagensSelecionadas[index],
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removerImagem(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _escolherImagens,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  // 2ª CORREÇÃO: Usando Color.fromRGBO em vez do método obsoleto
                  overlayColor: const Color.fromRGBO(244, 67, 54, 0.1), // Vermelho com 10% de opacidade
                ),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text("Adicionar Imagens"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _carregando ? null : _enviarDenuncia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: _carregando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Enviar Denúncia"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

