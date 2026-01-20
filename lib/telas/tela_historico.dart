import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaHistorico extends StatelessWidget {
  // Agora a tela pede essas informações para saber o que buscar
  final String bloco;
  final String apto;

  const TelaHistorico({
    super.key, 
    required this.bloco, 
    required this.apto
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Central de Notificações"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "Encomendas", icon: Icon(Icons.inventory_2)),
              Tab(text: "Avisos Gerais", icon: Icon(Icons.campaign)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- ABA 1: ENCOMENDAS (CORRIGIDO!) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('encomendas')
                  .where('bloco', isEqualTo: bloco) // Filtra pelo SEU bloco
                  .where('numero', isEqualTo: apto) // Filtra pelo SEU apto
                  .orderBy('data_chegada', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Se der erro, mostra no console pra gente pegar o link do índice
                if (snapshot.hasError) {
                  print("ERRO ENCOMENDAS: ${snapshot.error}");
                  return Center(child: Text("Precisa criar o índice no Firebase!\nOlhe o terminal."));
                }
                
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs; 

                if (docs.isEmpty) return _vazio("Nenhuma encomenda para você.");

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var dados = docs[index].data() as Map<String, dynamic>;
                    
                    // Verifica se já foi entregue ou se está na portaria
                    bool retirado = dados['status'] == 'ENTREGUE';
                    
                    return Card(
                      color: retirado ? Colors.grey[100] : Colors.white,
                      elevation: retirado ? 0 : 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: retirado ? Colors.transparent : Colors.orange, width: 1),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.inventory_2, 
                          color: retirado ? Colors.grey : Colors.orange,
                          size: 32,
                        ),
                        title: Text(
                          dados['descricao'] ?? 'Encomenda',
                          style: TextStyle(fontWeight: retirado ? FontWeight.normal : FontWeight.bold),
                        ),
                        subtitle: Text(
                          dados['data_chegada'] != null 
                          ? DateFormat('dd/MM/yyyy HH:mm').format((dados['data_chegada'] as Timestamp).toDate())
                          : 'Data desconhecida'
                        ),
                        trailing: retirado 
                          ? const Chip(label: Text("Retirado")) 
                          : const Chip(
                              label: Text("NA PORTARIA", style: TextStyle(fontWeight: FontWeight.bold)), 
                              backgroundColor: Colors.orange, 
                              labelStyle: TextStyle(color: Colors.white)
                            ),
                      ),
                    );
                  },
                );
              },
            ),

            // --- ABA 2: AVISOS ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('avisos')
                  .orderBy('data_envio', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) return _vazio("Nenhum comunicado recente.");

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var dados = docs[index].data() as Map<String, dynamic>;
                    bool urgente = dados['urgente'] ?? false;

                    return Card(
                      elevation: urgente ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: urgente ? Colors.red : Colors.transparent, width: urgente ? 2 : 0),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: ListTile(
                        leading: Icon(Icons.info, color: urgente ? Colors.red : Colors.blue),
                        title: Text(dados['titulo'] ?? 'Aviso', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(dados['mensagem'] ?? ''),
                            const SizedBox(height: 8),
                            Text(
                               dados['data_envio'] != null 
                              ? DateFormat('dd/MM - HH:mm').format((dados['data_envio'] as Timestamp).toDate())
                              : '',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600])
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(msg, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}