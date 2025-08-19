import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_alert/screens/Denuncias/DetalhesDenunciaScreen.dart';

class DenunciasScreen extends StatefulWidget {
  @override
  _DenunciasScreenState createState() => _DenunciasScreenState();
}

class _DenunciasScreenState extends State<DenunciasScreen> {
  final zonas = ['Zona Leste', 'Zona Sul', 'Centro', 'Zona Norte', 'Zona Oeste'];

  final Map<String, List<String>> bairrosPorZona = {
    'Zona Leste': ['São Miguel Paulista', 'Itaim Paulista', 'Itaquera'],
    'Zona Sul': ['Capão Redondo', 'Cambuci', 'Ipiranga'],
    'Centro': ['Sé', 'Paulista', 'Bela Vista'],
    'Zona Norte': ['Santana', 'Tremembé', 'Vila Maria'],
    'Zona Oeste': ['Osasco', 'Sapopemba', 'Butantã'],
  };

  String zonaSelecionada = 'Zona Leste';
  String? bairroSelecionado;

  @override
  Widget build(BuildContext context) {
    final bairros = bairrosPorZona[zonaSelecionada] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Denúncias', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/nova-denuncia');
        },
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: zonas.map((zona) {
                  final isSelected = zona == zonaSelecionada;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(zona),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          zonaSelecionada = zona;
                          bairroSelecionado = null;
                        });
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              hint: const Text('Bairros'),
              value: bairroSelecionado,
              isExpanded: true,
              dropdownColor: Colors.white,
              items: bairros.map((bairro) {
                return DropdownMenuItem(
                  value: bairro,
                  child: Text(bairro),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  bairroSelecionado = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('denuncias')
                    .where('zona', isEqualTo: zonaSelecionada)
                    .where('bairro', isEqualTo: bairroSelecionado)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhuma denúncia encontrada.'));
                  }

                  final denuncias = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: denuncias.length,
                    itemBuilder: (context, index) {
                      final doc = denuncias[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final timestamp = (data['timestamp'] as Timestamp).toDate();
                      final tempoPostagem = DateTime.now().difference(timestamp);

                      String tempoFormatado;

                      if (tempoPostagem.inHours < 24) {
                        final horas = tempoPostagem.inHours;
                        final minutos = tempoPostagem.inMinutes % 60;
                        tempoFormatado = '$horas h $minutos min';
                      } else {
                        final dias = tempoPostagem.inDays;
                        tempoFormatado = '$dias d';
                      }

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetalhesDenunciaScreen(data: data),
                            ),
                          );
                        },
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          data['nome_usuario']?.toString().isNotEmpty == true
                              ? data['nome_usuario']
                              : 'Usuário anônimo',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$tempoFormatado - ${data['descricao']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: data['imagemUrl'] != null && data['imagemUrl'].toString().isNotEmpty
                            ? Image.network(
                                data['imagemUrl'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}