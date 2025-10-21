import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool alertaAtivado = false;
  Timer? _pressTimer;
  Timer? _locationUpdateTimer;

  late AnimationController _animController;
  late Animation<Color?> _colorAnimation;

  final user = FirebaseAuth.instance.currentUser;
  String? nomeUsuario;

  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _buscarNomeUsuario();

    _animController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xFFF4F0E8),
      end: Colors.red,
    ).animate(_animController);

    // MUDANÇA: Verifica o estado do alerta no Firestore ao iniciar a tela.
    _verificarEstadoDoAlertaInicial(); 
  }

  // MUDANÇA: Nova função para verificar o estado do alerta.
  Future<void> _verificarEstadoDoAlertaInicial() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('alertasAtivos').doc(user!.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        // Se o documento no Firebase diz que o alerta está ativo...
        if (data['ativo'] == true) {
          // ... atualizamos o estado da tela para refletir isso.
          setState(() {
            alertaAtivado = true;
          });
          // Avança a animação para o final (botão vermelho)
          _animController.forward(from: 1.0);
          // Reinicia o compartilhamento de localização
          _startLocationUpdates();
        }
      }
    } catch (e) {
      debugPrint("Erro ao verificar estado do alerta: $e");
    }
  }


  @override
  void dispose() {
    _pressTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _buscarNomeUsuario() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('nome')) {
            nomeUsuario = data['nome'];
          }
        });
      }
    }
  }

  void _segurarParaAtivar() {
    if (alertaAtivado) return;

    _animController.forward();

    _pressTimer = Timer(const Duration(seconds: 3), () {
      setState(() => alertaAtivado = true);
      _startLocationUpdates();
      _enviarChamadosIniciais();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Alerta ativado! A partilhar localização..."))
        );
      }
    });
  }

  void _cancelarAtivacao() {
    if (!alertaAtivado) {
      _pressTimer?.cancel();
      _animController.reverse();
    }
  }

  Future<void> _tentarDesativarAlerta() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Por favor, autentique-se para desativar o alerta de emergência',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate && mounted) {
        _stopLocationUpdates();
      }
    } on PlatformException catch (e) {
      debugPrint("Erro de autenticação: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Autenticação falhou ou não está configurada.")),
        );
      }
    }
  }

  Future<void> _enviarChamadosIniciais() async {
    if (user == null) return;

    final contatosSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('contatos')
        .get();

    final List<QueryDocumentSnapshot> contatosDeEmergencia = contatosSnapshot.docs;

    if (contatosDeEmergencia.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Você não possui contatos de emergência."))
        );
        return;
    }

    for (var contato in contatosDeEmergencia) {
      final emailContato = contato['email'];
      final usuarioDestinoSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: emailContato)
          .limit(1)
          .get();

      if (usuarioDestinoSnapshot.docs.isNotEmpty) {
        final destinatario = usuarioDestinoSnapshot.docs.first;
        await FirebaseFirestore.instance.collection('chamados').add({
          'destinatarioId': destinatario.id,
          'remetenteNome': nomeUsuario ?? "Alguém",
          'remetenteId': user!.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint("Chamado enviado para: $emailContato");
      }
    }
  }

  void _startLocationUpdates() {
    if (user == null) return;
    final alertaRef = FirebaseFirestore.instance.collection('alertasAtivos').doc(user!.uid);
    
    // MUDANÇA: Cancela qualquer timer antigo antes de criar um novo para evitar duplicação.
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 20), (timer) async {
      final locData = await _capturarLocalizacao();
      if (locData != null) {
        // MUDANÇA: Usamos `update` em vez de `set` para não sobrescrever outros campos.
        // Se o documento não existir, `set` com `merge` é uma alternativa.
        // Para este caso, `set` completo é ok, pois ativamos tudo de uma vez.
        alertaRef.set({
          'remetenteNome': nomeUsuario ?? "Alguém",
          'ativo': true,
          'localizacao': GeoPoint(locData.latitude!, locData.longitude!),
          'ultimaAtualizacao': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
    if(user != null) {
      FirebaseFirestore.instance
          .collection('alertasAtivos')
          .doc(user!.uid)
          .update({'ativo': false});
    }

    setState(() => alertaAtivado = false);
    _animController.reverse();
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alerta desativado com segurança.")),
      );
    }
  }

  Future<loc.LocationData?> _capturarLocalizacao() async {
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) serviceEnabled = await location.requestService();
    if (!serviceEnabled) return null;

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }
    if (permissionGranted == loc.PermissionStatus.granted) {
      return await location.getLocation();
    }
    return null;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bem-vindo, ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      nomeUsuario ?? "...",
                      style: const TextStyle(
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
              onTap: () {
                if (alertaAtivado) {
                  _tentarDesativarAlerta();
                }
              },
              onLongPress: _segurarParaAtivar,
              onLongPressUp: _cancelarAtivacao,

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
                        offset: const Offset(0, 4),
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
            const SizedBox(height: 24),
            Text(
              alertaAtivado ? 'Alerta Ativado!' : 'Botão de Alerta',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8),
              child: Text(
                alertaAtivado
                    ? 'Toque para desativar. A sua localização está a ser partilhada com os seus contatos.'
                    : 'Pressione e segure por 3 segundos para enviar um sinal de alerta.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}