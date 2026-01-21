import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tela_abrir_chamado.dart';
import 'tela_classificados.dart';
import 'tela_regras.dart'; 
import 'tela_sugestoes.dart';
import 'tela_historico.dart'; 
import 'tela_reservas.dart';
import 'tela_lista_chamados.dart';

class HomeMorador extends StatefulWidget {
  const HomeMorador({super.key});

  @override
  State<HomeMorador> createState() => _HomeMoradorState();
}

class _HomeMoradorState extends State<HomeMorador> {
  User? usuarioLogado = FirebaseAuth.instance.currentUser;
  
  void _editarVeiculos(Map<String, dynamic> dadosAtuais) {
    Map<String, dynamic> carro = dadosAtuais['carro'] ?? {'modelo': '', 'placa': '', 'cor': ''};
    Map<String, dynamic> moto = dadosAtuais['moto'] ?? {'modelo': '', 'placa': '', 'cor': ''};

    final carroModeloCtrl = TextEditingController(text: carro['modelo']);
    final carroPlacaCtrl = TextEditingController(text: carro['placa']);
    final carroCorCtrl = TextEditingController(text: carro['cor']); 

    final motoModeloCtrl = TextEditingController(text: moto['modelo']);
    final motoPlacaCtrl = TextEditingController(text: moto['placa']);
    final motoCorCtrl = TextEditingController(text: moto['cor']); 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Meus Veículos"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🚗 Carro (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: carroModeloCtrl, decoration: const InputDecoration(labelText: "Modelo (Ex: Gol)", border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: carroPlacaCtrl, decoration: const InputDecoration(labelText: "Placa", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: carroCorCtrl, decoration: const InputDecoration(labelText: "Cor", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text("🏍️ Moto (Opcional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(controller: motoModeloCtrl, decoration: const InputDecoration(labelText: "Modelo (Ex: Biz)", border: OutlineInputBorder())),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: motoPlacaCtrl, decoration: const InputDecoration(labelText: "Placa", border: OutlineInputBorder()))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: motoCorCtrl, decoration: const InputDecoration(labelText: "Cor", border: OutlineInputBorder()))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("SALVAR"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(usuarioLogado!.uid).update({
                'carro': {'modelo': carroModeloCtrl.text, 'placa': carroPlacaCtrl.text, 'cor': carroCorCtrl.text},
                'moto': {'modelo': motoModeloCtrl.text, 'placa': motoPlacaCtrl.text, 'cor': motoCorCtrl.text},
              });
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veículos atualizados!")));
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. STREAMBUILDER GLOBAL (Para pegar dados do usuário para o Sininho)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(usuarioLogado!.uid).snapshots(),
      builder: (context, snapshot) {
        
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var dados = snapshot.data!.data() as Map<String, dynamic>;
        String nome = dados['nome'] ?? 'Vizinho';
        String bloco = dados['bloco'] ?? '?';
        String apto = dados['unidade'] ?? '?';

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text("Minha Casa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1B4D3E),
            actions: [
              // --- SININHO ---
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                tooltip: "Histórico de Notificações",
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => TelaHistorico(bloco: bloco, apto: apto)
                    )
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut())
            ],
          ),
          
          // 2. STREAMBUILDER DO CORPO (Encomendas)
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('encomendas')
                .where('bloco', isEqualTo: bloco)
                .where('numero', isEqualTo: apto)
                .where('status', isEqualTo: 'AGUARDANDO_RETIRADA')
                .snapshots(),
            builder: (context, encSnap) {
              
              bool temEncomenda = encSnap.hasData && encSnap.data!.docs.isNotEmpty;
              int qtdEncomendas = temEncomenda ? encSnap.data!.docs.length : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- CABEÇALHO ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF1B4D3E),
                            child: Text(bloco, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Olá, $nome", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Apto $apto - Bloco $bloco", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          
                          if (temEncomenda) 
                            Tooltip(
                              message: "Encomenda na Portaria",
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orange)
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.orange),
                              ),
                            )
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // --- ALERTA GRANDE ---
                    if (temEncomenda)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        width: double.infinity,
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TelaHistorico(bloco: bloco, apto: apto))),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange, 
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.inventory_2, color: Colors.white, size: 40),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$qtdEncomendas Encomenda(s) Chegou!", 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                                      ),
                                      const Text(
                                        "Toque para ver detalhes.",
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    const Text("Serviços", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E))),
                    const SizedBox(height: 16),

                    // --- GRADE DE MENUS ---
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _botaoMenu(
                          icone: Icons.build_circle_outlined, 
                          titulo: "Ocorrências\n(Chamados)", 
                          cor: Colors.redAccent,
                          acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaListaChamados())), // <--- MUDOU AQUI
                        ),
                        _botaoMenu(
                          icone: Icons.storefront,
                          titulo: "Classificados\nInternos",
                          cor: Colors.orange,
                          acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaClassificados())),
                        ),
                        _botaoMenu(
                          icone: Icons.directions_car,
                          titulo: "Meus\nVeículos",
                          cor: Colors.blueGrey,
                          acao: () => _editarVeiculos(dados), 
                        ),
                        _botaoMenu(
                          icone: Icons.event,
                          titulo: "Reservas\n(Salão/Churras)",
                          cor: Colors.purple,
                          acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaReservas())),
                        ),
                        _botaoMenu(
                          icone: Icons.mark_chat_unread_outlined,
                          titulo: "Sugestões\n& Reclamações",
                          cor: Colors.teal,
                          acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaSugestoes())),
                        ),
                        _botaoMenu(
                          icone: Icons.gavel,
                          titulo: "Regras do\nCondomínio",
                          cor: Colors.brown,
                          acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaRegras())),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _botaoMenu({required IconData icone, required String titulo, required Color cor, required VoidCallback acao}) {
    return InkWell(
      onTap: acao,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icone, size: 32, color: cor),
            ),
            const SizedBox(height: 12),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}