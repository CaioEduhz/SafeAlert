import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool alertaAtivado = false;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<Color?> _colorAnimation;

  FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _gravando = false;

  final user = FirebaseAuth.instance.currentUser;
  String? nomeUsuario;

  @override
  void initState() {
    super.initState();
    _buscarNomeUsuario();

    _animController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: Color(0xFFF4F0E8),
      end: Colors.red,
    ).animate(_animController);
  }

  Future<void> _buscarNomeUsuario() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();

      setState(() {
        nomeUsuario = doc['nome'];
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  void _segurarParaAtivar() {
    if (alertaAtivado) return;

    _animController.forward();

    _timer = Timer(Duration(seconds: 3), () async {
      setState(() => alertaAtivado = true);
      await _capturarLocalizacao();
      await _iniciarGravacao();
    });
  }

  void _cancelarAtivacao() {
    if (!alertaAtivado) {
      _timer?.cancel();
      _animController.reverse();
    }
  }

  Future<void> _capturarLocalizacao() async {
    loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    if (permissionGranted == loc.PermissionStatus.granted) {
      final locData = await location.getLocation();
      print("📍 Localização: ${locData.latitude}, ${locData.longitude}");

      // Em breve: enviar para Firestore junto do alerta
    }
  }

  Future<void> _iniciarGravacao() async {
    final status = await perm.Permission.microphone.request();

    if (status != perm.PermissionStatus.granted) {
      print("❌ Permissão de microfone negada");
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/alerta_gravado.aac';

    await _recorder.openRecorder();
    await _recorder.startRecorder(toFile: path);
    _gravando = true;

    print("🎙️ Gravando áudio...");

    Future.delayed(Duration(minutes: 1), () async {
      if (_gravando) {
        final filePath = await _recorder.stopRecorder();
        _gravando = false;
        print("✅ Gravação salva: $filePath");

        // Upload para Firebase pode ser feito aqui
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 👤 Saudação com nome do usuário
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bem-vindo, ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      nomeUsuario ?? "...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            GestureDetector(
              onTapDown: (_) => _segurarParaAtivar(),
              onTapUp: (_) => _cancelarAtivacao(),
              onTapCancel: _cancelarAtivacao,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) => Container(
                  height: 140,
                  width: 140,
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      alertaAtivado
                          ? Icons.notifications_active
                          : Icons.notifications_none_rounded,
                      size: 48,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 24),

            Text(
              alertaAtivado ? 'Botão acionado!' : 'Botão de Alerta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
              child: Text(
                alertaAtivado
                    ? 'Sua localização em tempo real e uma gravação de áudio de 1 minuto foi enviada ao seu contato de confiança!'
                    : 'Pressione o botão para enviar um sinal de alerta para seu contato de confiança',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

            Spacer(),
          ],
        ),
      ),
    );
  }
}
