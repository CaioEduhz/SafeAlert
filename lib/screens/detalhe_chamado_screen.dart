import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';


class DetalheChamadoScreen extends StatefulWidget {
  final String remetenteId;
  final String remetenteNome;

  const DetalheChamadoScreen({
    super.key,
    required this.remetenteId,
    required this.remetenteNome,
  });

  @override
  State<DetalheChamadoScreen> createState() => _DetalheChamadoScreenState();
}

class _DetalheChamadoScreenState extends State<DetalheChamadoScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  String _endereco = "Carregando endereço...";

  Future<void> _getEnderecoFromLatLng(GeoPoint point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      Placemark place = placemarks[0];
      
      // Adicionando a verificação 'mounted' aqui também por segurança
      if (!mounted) return;
      setState(() {
        _endereco = "${place.street}, ${place.subLocality}, ${place.locality}";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _endereco = "Não foi possível obter o endereço.";
      });
    }
  }

  Future<void> _animateToLocation(GeoPoint point) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(point.latitude, point.longitude),
        zoom: 17.5,
      ),
    ));
  }
  
  // ▼▼▼ FUNÇÃO CORRIGIDA ▼▼▼
  void _copiarLocalizacao(GeoPoint point) async {
    final texto = "${widget.remetenteNome} está em: https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}";
    await Clipboard.setData(ClipboardData(text: texto));

    // Verificação para garantir que o widget ainda está na tela
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Localização copiada para a área de transferência!')),
    );
  }
  // ▲▲▲ FIM DA CORREÇÃO ▲▲▲

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alertasAtivos')
            .doc(widget.remetenteId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Aguardando localização..."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final GeoPoint localizacao = data['localizacao'];
          final bool isAtivo = data['ativo'] ?? false;

          _getEnderecoFromLatLng(localizacao);
          _animateToLocation(localizacao);
          
          final LatLng latLng = LatLng(localizacao.latitude, localizacao.longitude);

          return Column(
            children: [
              Expanded(
                flex: 3,
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: latLng,
                    zoom: 17.5,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('remetente'),
                      position: latLng,
                      infoWindow: InfoWindow(title: widget.remetenteNome),
                    ),
                  },
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      )
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localização de ${widget.remetenteNome}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (!isAtivo)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Alerta finalizado.',
                            style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _endereco,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _copiarLocalizacao(localizacao),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Copiar Localização'),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}