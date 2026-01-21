import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaHistorico extends StatefulWidget {
  final String bloco;
  final String apto;

  const TelaHistorico({super.key, required this.bloco, required this.apto});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  @override
  Widget build(BuildContext context) {
    // DefaultTabController é o segredo para criar as Abas
    return DefaultTabController(
      length: 2, // Temos 2 abas (Encomendas e Avisos)
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Central de Notificações"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.orange, // Cor da barrinha embaixo do texto
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: "Encomendas"),
              Tab(icon: Icon(Icons.campaign), text: "Avisos Gerais"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- ABA 1: ENCOMENDAS (O código que já fizemos) ---
            _buildListaEncomendas(),

            // --- ABA 2: AVISOS (Nova lista) ---
            _buildListaAvisos(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET DA LISTA DE ENCOMENDAS
  // ==========================================
  Widget _buildListaEncomendas() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('encomendas')
          .where('bloco', isEqualTo: widget.bloco)
          .where('numero', isEqualTo: widget.apto)
          .orderBy('data_chegada', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("Nenhuma encomenda registrada.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var dados = docs[index].data() as Map<String, dynamic>;
            
            String status = dados['status'] ?? 'AGUARDANDO_RETIRADA';
            bool jaPeguei = status == 'RETIRADO';
            Timestamp? ts = dados['data_chegada'];
            String dataFormatada = ts != null 
                ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate()) 
                : '--/--/----';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: jaPeguei ? Colors.green.shade200 : Colors.orange, 
                  width: 1.5
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: jaPeguei ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      jaPeguei ? Icons.check_circle : Icons.inventory_2,
                      color: jaPeguei ? Colors.green : Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dados['descricao'] ?? 'Encomenda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(dataFormatada, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: jaPeguei ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      jaPeguei ? "RETIRADO" : "NA PORTARIA",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // WIDGET DA LISTA DE AVISOS (NOVO)
  // ==========================================
  Widget _buildListaAvisos() {
    return StreamBuilder<QuerySnapshot>(
      // Aqui buscamos na coleção 'avisos' (que o admin cria)
      // Ordenado por data, para ver o mais recente no topo
      stream: FirebaseFirestore.instance
          .collection('avisos')
          .orderBy('data_postagem', descending: true) 
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar avisos"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 60, color: Colors.grey),
                SizedBox(height: 10),
                Text("Quadro de avisos vazio.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var dados = docs[index].data() as Map<String, dynamic>;
            
            Timestamp? ts = dados['data_postagem'];
            String dataFormatada = ts != null 
                ? DateFormat('dd/MM/yyyy').format(ts.toDate()) 
                : '--/--/----';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign, color: Color(0xFF1B4D3E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dados['titulo'] ?? 'Aviso Importante',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B4D3E)),
                          ),
                        ),
                        Text(dataFormatada, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const Divider(),
                    Text(
                      dados['mensagem'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}