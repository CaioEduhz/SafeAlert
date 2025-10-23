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

  StreamSubscription<DocumentSnapshot>? _alertaSubscription;
  Map<String, dynamic>? _alertaData;
  GeoPoint? _ultimaLocalizacao;

  @override
  void initState() {
    super.initState();
    _iniciarListenerAlerta();
  }

  @override
  void dispose() {
    _alertaSubscription?.cancel();
    super.dispose();
  }

  // ▼▼▼ CORREÇÃO (Erros 1, 2, 3, 4, 5) ▼▼▼
  void _iniciarListenerAlerta() {
    _alertaSubscription = FirebaseFirestore.instance
        .collection('alertasAtivos')
        .doc(widget.remetenteId)
        .snapshots()
        .listen((snapshot) { // 'snapshot' aqui é um DocumentSnapshot
      
      // A verificação correta é se o documento existe
      if (!snapshot.exists || !mounted) {
        return;
      }

      // Os dados são obtidos diretamente com snapshot.data()
      final data = snapshot.data() as Map<String, dynamic>;
      final GeoPoint localizacao = data['localizacao'];
      
      setState(() {
        _alertaData = data;
      });

      bool localizacaoMudou = _ultimaLocalizacao == null ||
                              _ultimaLocalizacao!.latitude != localizacao.latitude ||
                              _ultimaLocalizacao!.longitude != localizacao.longitude;

      if (localizacaoMudou) {
        debugPrint("Nova localização recebida. Atualizando mapa e endereço.");
        _getEnderecoFromLatLng(localizacao);
        _animateToLocation(localizacao);
        _ultimaLocalizacao = localizacao;
      }
    });
  }
  // ▲▲▲ FIM DA CORREÇÃO ▲▲▲


  Future<void> _getEnderecoFromLatLng(GeoPoint point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      Placemark place = placemarks[0];
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
  

  void _copiarLocalizacao(GeoPoint point) async {
    final texto = "${widget.remetenteNome} está em: https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}";
    await Clipboard.setData(ClipboardData(text: texto));


    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Localização copiada para a área de transferência!')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _alertaData == null
              ? const Center(child: Text("Aguardando localização..."))
              : _buildMapBody(),
          
          Positioned(
            top: 40.0,
            left: 16.0,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBody() {
    final GeoPoint localizacao = _alertaData!['localizacao'];
    final bool isAtivo = _alertaData!['ativo'] ?? false;
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
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 70),
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
  }
}