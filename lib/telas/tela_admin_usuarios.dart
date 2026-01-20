import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaAdminUsuarios extends StatelessWidget {
  const TelaAdminUsuarios({super.key});

  // Função para atualizar o status no banco
  Future<void> _atualizarStatus(String uid, String novoStatus, String perfil) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': novoStatus, // 'ATIVO' ou 'BLOQUEADO'
      'perfil': perfil,     // 'MORADOR', 'PORTEIRO' ou 'SINDICO'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aprovar Cadastros"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'AGUARDANDO_APROVACAO') // Filtra só os pendentes
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  Text("Tudo limpo! Nenhuma pendência."),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var usuario = docs[index];
              var dados = usuario.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(dados['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Bloco ${dados['bloco']} - Apt ${dados['unidade']}\n${dados['email']}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão BLOQUEAR
                      IconButton(
                        icon: const Icon(Icons.block, color: Colors.red),
                        onPressed: () => _atualizarStatus(usuario.id, 'BLOQUEADO', 'MORADOR'),
                      ),
                      // Botão APROVAR
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        onPressed: () => _atualizarStatus(usuario.id, 'ATIVO', 'MORADOR'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}