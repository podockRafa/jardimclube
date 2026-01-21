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

  // --- FUNÇÃO 1: REGISTRAR NOVA ENCOMENDA ---
  Future<void> _registrarEncomenda(String idUnidade, String numeroApt, String transportadora, {String? uidMorador, String? nomeMorador}) async {
    String descricaoFinal = transportadora.trim().isEmpty ? "Encomenda" : transportadora;

    try {
      await FirebaseFirestore.instance.collection('encomendas').add({
        'unidade_ref': idUnidade,
        'bloco': _blocoSelecionado,
        'numero': numeroApt,
        'descricao': descricaoFinal,
        'destinatario_uid': uidMorador, 
        'destinatario_nome': nomeMorador, 
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
          content: Text("Recebido para Apt $numeroApt" + (nomeMorador != null ? " ($nomeMorador)" : "") + "!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- FUNÇÃO 2: ENTREGAR TUDO (DAR BAIXA) ---
  Future<void> _entregarPacotes(List<DocumentSnapshot> pacotes, String nomeMorador) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Entrega"),
        content: Text("Entregar ${pacotes.length} pacote(s) para $nomeMorador agora?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("CONFIRMAR ENTREGA"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      String uidPorteiro = FirebaseAuth.instance.currentUser!.uid;

      for (var doc in pacotes) {
        batch.update(doc.reference, {
          'status': 'RETIRADO',
          'data_retirada': FieldValue.serverTimestamp(),
          'entregue_por_uid': uidPorteiro,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tudo entregue! Card ficou verde."), backgroundColor: Colors.green),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  // --- UI AUXILIARES ---
  void _mostrarDadosVeiculo(String tipo, Map<String, dynamic> dados) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(tipo == 'Carro' ? Icons.directions_car : Icons.two_wheeler, color: Colors.blue[900]),
            const SizedBox(width: 10),
            Text(tipo),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Modelo: ${dados['modelo'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
            Text("Cor: ${dados['cor'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)), 
            const Divider(),
            Text("PLACA: ${dados['placa'] ?? '---'}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("FECHAR"))
        ],
      ),
    );
  }

  void _abrirDialogoNovaEncomenda(String idUnidade, String numeroApt, {String? uidMorador, String? nomeMorador}) {
    final transportadoraController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Apt $numeroApt - Bloco $_blocoSelecionado"), 
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nomeMorador != null)
                Text(nomeMorador, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 16)),
              const SizedBox(height: 10),
              const Icon(Icons.inventory_2_outlined, size: 50, color: Colors.orange),
              const SizedBox(height: 16),
              const Text("Chegou encomenda nova?"),
              const SizedBox(height: 10),
              TextField(
                controller: transportadoraController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Descrição (Ex: Correios)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                _registrarEncomenda(idUnidade, numeroApt, transportadoraController.text, uidMorador: uidMorador, nomeMorador: nomeMorador);
              },
              child: const Text("REGISTRAR CHEGADA", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- TELA DE HISTÓRICO ---
  void _abrirHistorico() {
    DateTime dataCorte = DateTime.now().subtract(const Duration(days: 180));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8, 
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Histórico Geral",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
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
                      if (docs.isEmpty) return const Center(child: Text("Nenhum histórico."));

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: docs.length,
                        separatorBuilder: (c, i) => const Divider(),
                        itemBuilder: (context, index) {
                          var dados = docs[index].data() as Map<String, dynamic>;
                          
                          Timestamp? ts = dados['data_chegada'];
                          String dataHora = ts != null
                              ? DateFormat('dd/MM HH:mm').format(ts.toDate())
                              : "?";

                          String status = dados['status'] ?? '';
                          bool retirado = status == 'RETIRADO';

                          return ListTile(
                            leading: Icon(
                              retirado ? Icons.check_circle : Icons.inventory_2,
                              color: retirado ? Colors.green : Colors.orange,
                            ),
                            title: Text(
                              "Apt ${dados['numero']} - Bloco ${dados['bloco']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text("${dados['descricao']} • ${dados['destinatario_nome'] ?? ''}"),
                            trailing: Text(dataHora),
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
        // --- AQUI: BOTÕES NA BARRA SUPERIOR ---
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Histórico",
            onPressed: _abrirHistorico,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Sair",
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      
      body: Column(
        children: [
          // SELETOR DE BLOCO
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
          
          // GRADE DE APARTAMENTOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('units')
                  .where('bloco', isEqualTo: _blocoSelecionado)
                  .orderBy('numero')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erro ao carregar."));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final documentos = snapshot.data!.docs;
                if (documentos.isEmpty) return const Center(child: Text("Bloco vazio."));

                // Responsividade
                int colunas = MediaQuery.of(context).size.width > 600 ? 6 : 3;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colunas,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85, 
                  ),
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    var dadosUnit = documentos[index].data() as Map<String, dynamic>;
                    String numeroApt = dadosUnit['numero'];
                    String idUnidade = documentos[index].id;
                    
                    // 1. Busca Morador
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .where('bloco', isEqualTo: _blocoSelecionado)
                          .where('unidade', isEqualTo: numeroApt)
                          .where('status', isEqualTo: 'ATIVO')
                          .limit(1)
                          .snapshots(),
                      builder: (context, userSnap) {
                        
                        // --- VAGO ---
                        if (!userSnap.hasData || userSnap.data!.docs.isEmpty) {
                          return InkWell(
                            onTap: () => _abrirDialogoNovaEncomenda(idUnidade, numeroApt),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(numeroApt, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                                  Text("Vago", style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                                ],
                              ),
                            ),
                          );
                        }

                        // --- OCUPADO ---
                        var userDoc = userSnap.data!.docs.first;
                        var userDados = userDoc.data() as Map<String, dynamic>;
                        String uidMorador = userDoc.id;
                        String nomeMorador = (userDados['nome'] ?? 'Morador').split(' ')[0];

                        // Veículos
                        Map<String, dynamic>? carro = userDados['carro'];
                        Map<String, dynamic>? moto = userDados['moto'];
                        bool temCarro = carro != null && (carro['placa'] ?? '').isNotEmpty;
                        bool temMoto = moto != null && (moto['placa'] ?? '').isNotEmpty;

                        // 2. Busca Encomendas
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('encomendas')
                              .where('bloco', isEqualTo: _blocoSelecionado)
                              .where('numero', isEqualTo: numeroApt)
                              .where('status', isEqualTo: 'AGUARDANDO_RETIRADA')
                              .snapshots(),
                          builder: (context, encSnap) {
                            
                            bool temEncomenda = encSnap.hasData && encSnap.data!.docs.isNotEmpty;
                            int qtdPacotes = temEncomenda ? encSnap.data!.docs.length : 0;

                            Color corFundo = temEncomenda ? Colors.orange.shade50 : Colors.blue.shade50;
                            Color corBorda = temEncomenda ? Colors.orange : Colors.blue.shade200;
                            double espessuraBorda = temEncomenda ? 2.0 : 1.0;

                            return InkWell(
                              onTap: () => _abrirDialogoNovaEncomenda(idUnidade, numeroApt, uidMorador: uidMorador, nomeMorador: userDados['nome']),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: corFundo,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: corBorda, width: espessuraBorda),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(2, 2))
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // --- ESPAÇO EXTRA NO TOPO ---
                                    const SizedBox(height: 12), 

                                    // Número do Apt
                                    Text(
                                      numeroApt,
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold, 
                                        color: temEncomenda ? Colors.orange[900] : Colors.blue[900]
                                      ),
                                    ),
                                    
                                    // Nome do Morador
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        nomeMorador,
                                        style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 5),

                                    // Ícones Veículos
                                    if (!temEncomenda || MediaQuery.of(context).size.width > 600)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (temCarro)
                                            GestureDetector(
                                              onTap: () => _mostrarDadosVeiculo('Carro', carro!),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(Icons.directions_car, size: 18, color: Colors.blue),
                                              ),
                                            ),
                                          if (temMoto)
                                            GestureDetector(
                                              onTap: () => _mostrarDadosVeiculo('Moto', moto!),
                                              child: const Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Icon(Icons.two_wheeler, size: 18, color: Colors.orange),
                                              ),
                                            ),
                                        ],
                                      ),
                                    
                                    const Spacer(),

                                    // BOTÃO DE ENTREGA
                                    if (temEncomenda)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 35,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                            ),
                                            onPressed: () {
                                              _entregarPacotes(encSnap.data!.docs, nomeMorador);
                                            },
                                            child: Text(
                                              "ENTREGAR ($qtdPacotes)", 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 10), 
                                  ],
                                ),
                              ),
                            );
                          }
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