import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TelaHistorico extends StatefulWidget {
  final String bloco;
  final String apto;

  const TelaHistorico({super.key, required this.bloco, required this.apto});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Função para marcar UM aviso específico como lido
  Future<void> _marcarAvisoLido(String docId) async {
    if (_user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
      'avisos_lidos': FieldValue.arrayUnion([docId])
    });
  }

  void _lerAvisoDetalhado(Map<String, dynamic> dados, String docId, bool jaLido) {
    // Se ainda não leu, marca agora
    if (!jaLido) {
      _marcarAvisoLido(docId);
    }

    // Mostra o aviso completo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dados['titulo'] ?? 'Aviso'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dados['mensagem'] ?? '', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Text("Publicado em: ${_formatarData(dados['data_postagem'])}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("FECHAR"))
        ],
      ),
    );
  }

  String _formatarData(Timestamp? ts) {
    if (ts == null) return '--/--';
    return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Central de Notificações"),
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.orange,
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
            _buildListaEncomendas(),
            _buildListaAvisos(),
          ],
        ),
      ),
    );
  }

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
        if (docs.isEmpty) return const Center(child: Text("Nenhuma encomenda registrada.", style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var dados = docs[index].data() as Map<String, dynamic>;
            String status = dados['status'] ?? 'AGUARDANDO_RETIRADA';
            bool jaPeguei = status == 'RETIRADO';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: jaPeguei ? Colors.green.shade200 : Colors.orange, width: 1.5)),
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: jaPeguei ? Colors.green[50] : Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: Icon(jaPeguei ? Icons.check_circle : Icons.inventory_2, color: jaPeguei ? Colors.green : Colors.orange, size: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dados['descricao'] ?? 'Encomenda', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(_formatarData(dados['data_chegada']), style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: jaPeguei ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(20)), child: Text(jaPeguei ? "RETIRADO" : "NA PORTARIA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListaAvisos() {
    // Precisamos ouvir o usuário para saber o que já foi lido
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots(),
      builder: (context, userSnap) {
        List<dynamic> lidos = [];
        if (userSnap.hasData) {
          lidos = userSnap.data!.get('avisos_lidos') ?? [];
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('avisos').orderBy('data_postagem', descending: true).limit(30).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            // FILTRO DE PRIVACIDADE
            var docsFiltrados = snapshot.data!.docs.where((doc) {
              var d = doc.data() as Map<String, dynamic>;
              String alcance = d['alcance_tipo'] ?? 'TODOS';
              String alvoBloco = (d['alcance_bloco'] ?? '').toString();
              String alvoApto = (d['alcance_unidade'] ?? '').toString();
              String meuBloco = widget.bloco.trim();
              String meuApto = widget.apto.trim();

              if (alcance == 'TODOS') return true;
              if (alcance == 'BLOCO' && alvoBloco == meuBloco) return true;
              if (alcance == 'UNIDADE' && alvoBloco == meuBloco && alvoApto == meuApto) return true;
              return false; 
            }).toList();

            if (docsFiltrados.isEmpty) return const Center(child: Text("Nenhum aviso para você.", style: TextStyle(color: Colors.grey)));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docsFiltrados.length,
              itemBuilder: (context, index) {
                var doc = docsFiltrados[index];
                var dados = doc.data() as Map<String, dynamic>;
                bool jaLido = lidos.contains(doc.id);

                return InkWell(
                  // AQUI ESTÁ A MÁGICA: Ao clicar, abre detalhe e marca lido
                  onTap: () => _lerAvisoDetalhado(dados, doc.id, jaLido),
                  child: Card(
                    // Avisos não lidos ficam com borda azul e fundo levemente destacado
                    elevation: jaLido ? 1 : 4,
                    color: jaLido ? Colors.white : Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: jaLido ? Colors.transparent : Colors.blue, width: 1)
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.campaign, color: jaLido ? Colors.grey : Colors.blue[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dados['titulo'] ?? 'Aviso',
                                  style: TextStyle(
                                    fontWeight: jaLido ? FontWeight.normal : FontWeight.bold, 
                                    fontSize: 16, 
                                    color: jaLido ? Colors.black87 : Colors.blue[900]
                                  ),
                                ),
                              ),
                              if (!jaLido) 
                                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(dados['mensagem'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text(_formatarData(dados['data_postagem']), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }
    );
  }
}