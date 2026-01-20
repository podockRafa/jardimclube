import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_admin.dart';
import 'home_morador.dart';
import 'home_portaria.dart'; // <--- NÃO ESQUEÇA DESTE IMPORT
import 'tela_login.dart';

class RoteadorTelas extends StatelessWidget {
  const RoteadorTelas({super.key});

  @override
  Widget build(BuildContext context) {
    User? usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) return const TelaLogin();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(usuario.uid).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Erro: Usuário sem cadastro.")));
        }

        Map<String, dynamic> dados = snapshot.data!.data() as Map<String, dynamic>;
        String status = dados['status'] ?? 'AGUARDANDO_APROVACAO';
        String perfil = dados['perfil'] ?? 'MORADOR'; 

        // 1. BLOQUEIOS
        if (status == 'AGUARDANDO_APROVACAO') {
          return _TelaEspera(usuario: usuario);
        }
        if (status == 'BLOQUEADO') {
           return _TelaBloqueada(usuario: usuario);
        }

        // 2. DIRECIONAMENTO (Onde a mágica acontece)
        if (perfil == 'ADMIN' || perfil == 'SINDICO') {
          return const HomeAdmin();
        } else if (perfil == 'PORTEIRO') { // <--- NOVA REGRA AQUI
          return const HomePortaria();
        } else {
          return const HomeMorador();
        }
      },
    );
  }
}

// ... (As classes _TelaEspera e _TelaBloqueada continuam iguais abaixo)
class _TelaEspera extends StatelessWidget {
  final User usuario;
  const _TelaEspera({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              "Cadastro em Análise",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "Seus dados foram enviados para o síndico.\nAssim que ele aprovar, este aplicativo liberará o acesso automaticamente.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Sair e tentar outra conta"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => FirebaseAuth.instance.signOut(),
            )
          ],
        ),
      ),
    );
  }
}

class _TelaBloqueada extends StatelessWidget {
  final User usuario;
  const _TelaBloqueada({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text("Acesso Bloqueado", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Sair"),
            )
          ],
        ),
      ),
    );
  }
}