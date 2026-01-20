import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'tela_abrir_chamado.dart';
import 'tela_classificados.dart';
import 'tela_regras.dart'; 
import 'tela_sugestoes.dart';
import 'tela_historico.dart'; // <--- IMPORT NOVO
import 'tela_reservas.dart';

class HomeMorador extends StatefulWidget {
  const HomeMorador({super.key});

  @override
  State<HomeMorador> createState() => _HomeMoradorState();
}

class _HomeMoradorState extends State<HomeMorador> {
  User? usuarioLogado = FirebaseAuth.instance.currentUser;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarPendencias();
    });
  }

  // --- O DETECTOR DE ENCOMENDAS ---
  Future<void> _verificarPendencias() async {
    if (usuarioLogado == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(usuarioLogado!.uid).get();
    if (!userDoc.exists) return;
    
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String meuBloco = userData['bloco'];
    String meuApto = userData['unidade']; 

    QuerySnapshot encomendas = await FirebaseFirestore.instance
        .collection('encomendas')
        .where('bloco', isEqualTo: meuBloco)
        .where('numero', isEqualTo: meuApto)
        .where('status', isEqualTo: 'AGUARDANDO_RETIRADA')
        .get();

    if (encomendas.docs.isNotEmpty) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.orange),
                SizedBox(width: 10),
                Text("Chegou Encomenda!"),
              ],
            ),
            content: Text(
              "Você tem ${encomendas.docs.length} pacote(s) aguardando retirada na portaria.\n\nFavor buscar o quanto antes.",
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4D3E), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => TelaHistorico(bloco: meuBloco, apto: meuApto)));
                },
                child: const Text("ENTENDI, VOU BUSCAR"),
              ),
            ],
          );
        },
      );
    }
  }

  void _editarVeiculos(Map<String, dynamic> dadosAtuais) {
     Map<String, dynamic> carro = dadosAtuais['carro'] ?? {'modelo': '', 'placa': ''};
    Map<String, dynamic> moto = dadosAtuais['moto'] ?? {'modelo': '', 'placa': ''};

    final carroModeloCtrl = TextEditingController(text: carro['modelo']);
    final carroPlacaCtrl = TextEditingController(text: carro['placa']);
    final motoModeloCtrl = TextEditingController(text: moto['modelo']);
    final motoPlacaCtrl = TextEditingController(text: moto['placa']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Meus Veículos"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🚗 Carro (Opcional)", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: carroModeloCtrl, decoration: const InputDecoration(labelText: "Modelo/Cor")),
              TextField(controller: carroPlacaCtrl, decoration: const InputDecoration(labelText: "Placa")),
              const SizedBox(height: 16),
              const Divider(),
              const Text("🏍️ Moto (Opcional)", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(controller: motoModeloCtrl, decoration: const InputDecoration(labelText: "Modelo/Cor")),
              TextField(controller: motoPlacaCtrl, decoration: const InputDecoration(labelText: "Placa")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            child: const Text("SALVAR"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(usuarioLogado!.uid).update({
                'carro': {'modelo': carroModeloCtrl.text, 'placa': carroPlacaCtrl.text},
                'moto': {'modelo': motoModeloCtrl.text, 'placa': motoPlacaCtrl.text},
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Minha Casa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B4D3E),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(usuarioLogado!.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var dados = snapshot.data!.data() as Map<String, dynamic>;
          String nome = dados['nome'] ?? 'Vizinho';
          String bloco = dados['bloco'] ?? '?';
          String apto = dados['unidade'] ?? '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CABEÇALHO
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Olá, $nome", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Apto $apto - Bloco $bloco", style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                const Text("Serviços", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E))),
                const SizedBox(height: 16),

                // GRADE DE MENUS
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _botaoMenu(
                      icone: Icons.build_circle_outlined, 
                      titulo: "Manutenção\n(Fotos)",
                      cor: Colors.redAccent,
                      acao: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaAbrirChamado())),
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

                    _botaoMenu(
                      icone: Icons.storefront,
                      titulo: "Classificados\n& Serviços",
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

                    // --- BOTÃO DE HISTÓRICO CORRIGIDO ---
                    _botaoMenu(
                      icone: Icons.notifications_active_outlined,
                      titulo: "Notificações\n& Histórico",
                      cor: Colors.blue,
                      acao: () {
                         Navigator.push(
                           context, 
                           MaterialPageRoute(
                             builder: (context) => TelaHistorico(
                               bloco: bloco, 
                               apto: apto
                             )
                           )
                         );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
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