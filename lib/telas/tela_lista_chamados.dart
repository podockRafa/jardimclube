import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tela_abrir_chamado.dart'; // Importante para o botão de "+" funcionar

class TelaListaChamados extends StatelessWidget {
  const TelaListaChamados({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Minhas Ocorrências"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "EM ABERTO"),
              Tab(text: "CONCLUÍDOS"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ABA 1: CHAMADOS ATIVOS (Tudo que não for CONCLUIDO ou CANCELADO)
            _buildLista(user!.uid, isAtivo: true),

            // ABA 2: HISTÓRICO (Concluídos)
            _buildLista(user.uid, isAtivo: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1B4D3E),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("NOVO CHAMADO", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const TelaAbrirChamado())
            );
          },
        ),
      ),
    );
  }

  Widget _buildLista(String uid, {required bool isAtivo}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ocorrencias')
          .where('autor_uid', isEqualTo: uid)
          // Aqui filtramos na memória ou via query composta. 
          // Para simplificar e evitar erros de índice agora, vamos pegar tudo do usuário
          // e filtrar visualmente no código abaixo.
          .orderBy('data_abertura', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          String status = doc['status'];
          bool finalizado = status == 'CONCLUIDO' || status == 'CANCELADO';
          return isAtivo ? !finalizado : finalizado;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isAtivo ? Icons.assignment_turned_in : Icons.history, size: 60, color: Colors.grey),
                const SizedBox(height: 10),
                Text(
                  isAtivo ? "Tudo certo! Nenhuma pendência." : "Nenhum histórico ainda.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var dados = docs[index].data() as Map<String, dynamic>;
            String status = dados['status'] ?? 'ABERTO';
            Timestamp? data = dados['data_abertura'];
            String dataFmt = data != null ? DateFormat('dd/MM/yyyy HH:mm').format(data.toDate()) : '?';

            Color corStatus = Colors.orange;
            if (status == 'EM_ANDAMENTO') corStatus = Colors.blue;
            if (status == 'CONCLUIDO') corStatus = Colors.green;
            if (status == 'CANCELADO') corStatus = Colors.red;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: corStatus.withValues(alpha:0.1), shape: BoxShape.circle),
                  child: Icon(Icons.build, color: corStatus),
                ),
                title: Text(dados['titulo'] ?? 'Sem Título', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dados['descricao'] ?? ''),
                    const SizedBox(height: 4),
                    Text(dataFmt, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: corStatus, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}