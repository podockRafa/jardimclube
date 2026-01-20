import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePortaria extends StatefulWidget {
  const HomePortaria({super.key});

  @override
  State<HomePortaria> createState() => _HomePortariaState();
}

class _HomePortariaState extends State<HomePortaria> {
  String _blocoSelecionado = "1";
  final List<String> _listaBlocos = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];

  // --- REGISTRAR ENCOMENDA (Lógica Corrigida para Notificar) ---
  Future<void> _registrarEncomenda(Map<String, dynamic> dadosMorador, String transportadora) async {
    String descricaoFinal = transportadora.trim().isEmpty ? "Encomenda" : transportadora;

    try {
      await FirebaseFirestore.instance.collection('encomendas').add({
        'bloco': dadosMorador['bloco'],
        'numero': dadosMorador['unidade'],
        'destinatario_nome': dadosMorador['nome'],
        'destinatario_uid': dadosMorador['uid'], // <--- IMPORTANTE: Isso avisa o morador específico!
        'descricao': descricaoFinal,
        'data_chegada': FieldValue.serverTimestamp(),
        'recebido_por_uid': FirebaseAuth.instance.currentUser!.uid,
        'recebido_por_email': FirebaseAuth.instance.currentUser!.email,
        'status': 'AGUARDANDO_RETIRADA',
        'visivel_para_uid': null,
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recebido para ${dadosMorador['nome']} (Apt ${dadosMorador['unidade']})!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  // --- DIÁLOGO DE ENCOMENDA ---
  void _abrirDialogoEncomenda(Map<String, dynamic> dadosMorador) {
    final transportadoraController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Apt ${dadosMorador['unidade']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(dadosMorador['nome'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.orange),
              const SizedBox(height: 16),
              const Text("Descrição (Opcional)"),
              TextField(
                controller: transportadoraController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Ex: Correios (Ou deixe vazio)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => _registrarEncomenda(dadosMorador, transportadoraController.text),
              child: const Text("CONFIRMAR", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- VISUALIZAR PLACA ---
  void _verPlaca(String tipo, Map<String, dynamic>? dadosVeiculo) {
    if (dadosVeiculo == null || dadosVeiculo['placa'] == null || dadosVeiculo['placa'] == '') return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(tipo == 'Carro' ? Icons.directions_car : Icons.two_wheeler, color: Colors.white),
          const SizedBox(width: 10),
          Text("$tipo: ${dadosVeiculo['modelo']} | Placa: ${dadosVeiculo['placa']}"),
        ],
      ),
      backgroundColor: Colors.blueGrey[900],
      duration: const Duration(seconds: 4),
    ));
  }

  // --- HISTÓRICO ---
  void _abrirHistorico() {
    DateTime dataCorte = DateTime.now().subtract(const Duration(days: 180));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Histórico Recente", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('encomendas')
                        .where('data_chegada', isGreaterThan: dataCorte)
                        .orderBy('data_chegada', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("Nada recente."));

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          var dados = docs[index].data() as Map<String, dynamic>;
                          Timestamp? ts = dados['data_chegada'];
                          String dataHora = ts != null ? DateFormat('dd/MM HH:mm').format(ts.toDate()) : "?";
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.history, color: Colors.grey),
                            title: Text("Apt ${dados['numero']} - Bloco ${dados['bloco']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(dados['descricao']),
                            trailing: Text(dataHora, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Portaria", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: _abrirHistorico),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: Column(
        children: [
          // --- SELETOR DE BLOCOS ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _listaBlocos.length,
              itemBuilder: (context, index) {
                String bloco = _listaBlocos[index];
                bool isSelected = bloco == _blocoSelecionado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text("Bloco $bloco", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    selected: isSelected,
                    selectedColor: Colors.orangeAccent,
                    onSelected: (bool selected) => setState(() => _blocoSelecionado = bloco),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // --- GRADE DE APARTAMENTOS ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('units')
                  .where('bloco', isEqualTo: _blocoSelecionado)
                  .orderBy('numero')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final documentos = snapshot.data!.docs;
                if (documentos.isEmpty) return const Center(child: Text("Bloco vazio ou não cadastrado."));

                // Responsividade da grade
                int colunas = MediaQuery.of(context).size.width > 600 ? 6 : 3;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0, // Quadrado
                  ),
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    var dadosUnit = documentos[index].data() as Map<String, dynamic>;
                    String numeroApt = dadosUnit['numero'];
                    String? inquilinoUid = dadosUnit['inquilino_uid']; // ID do Morador
                    
                    // --- CARTÃO VAGO (Simples) ---
                    if (inquilinoUid == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(numeroApt, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                              const Text("Vago", style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    // --- CARTÃO OCUPADO (Busca dados do morador EM TEMPO REAL) ---
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(inquilinoUid).snapshots(),
                      builder: (context, userSnap) {
                        
                        // Enquanto carrega
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return Container(
                             decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                             child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        var dadosUser = userSnap.data!.data() as Map<String, dynamic>;
                        String nomeMorador = (dadosUser['nome'] ?? 'Morador').split(' ')[0]; // Só o primeiro nome
                        
                        // Verifica Veículos
                        bool temCarro = dadosUser['carro'] != null && (dadosUser['carro']['placa'] ?? '').isNotEmpty;
                        bool temMoto = dadosUser['moto'] != null && (dadosUser['moto']['placa'] ?? '').isNotEmpty;

                        // Prepara dados para passar pro Dialog de Encomenda
                        Map<String, dynamic> dadosCompletos = {
                          'uid': inquilinoUid, // ISSO É ESSENCIAL PARA A NOTIFICAÇÃO
                          'nome': dadosUser['nome'],
                          'bloco': _blocoSelecionado,
                          'unidade': numeroApt,
                        };

                        return InkWell(
                          onTap: () => _abrirDialogoEncomenda(dadosCompletos),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 4, offset: const Offset(2, 2))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Número Apt
                                Text(numeroApt, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                                
                                // Nome Morador
                                Text(nomeMorador, style: TextStyle(fontSize: 14, color: Colors.blue.shade800), overflow: TextOverflow.ellipsis),
                                
                                const SizedBox(height: 6),
                                
                                // Ícones de Veículos
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (temCarro) 
                                      InkWell(
                                        onTap: () => _verPlaca("Carro", dadosUser['carro']),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.directions_car, size: 20, color: Colors.blue),
                                        ),
                                      ),
                                    if (temMoto) 
                                      InkWell(
                                        onTap: () => _verPlaca("Moto", dadosUser['moto']),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.two_wheeler, size: 20, color: Colors.orange),
                                        ),
                                      ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}