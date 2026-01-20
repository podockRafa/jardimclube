import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tela_criar_anuncio.dart'; // Importante para o botão flutuante de criar

class TelaClassificados extends StatelessWidget {
  const TelaClassificados({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Classificados & Serviços"),
        backgroundColor: const Color(0xFF1B4D3E),
        foregroundColor: Colors.white,
      ),
      
      // BOTÃO FLUTUANTE: Onde ele clica para vender o próprio peixe
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TelaCriarAnuncio()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Anunciar", style: TextStyle(color: Colors.white)),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('anuncios')
            .where('status', isEqualTo: 'APROVADO') // <--- O FILTRO DE OURO!
            .orderBy('data_criacao', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          
          if (snapshot.hasError) {
  // ADICIONE ESTA LINHA PARA VER O ERRO NO TERMINAL:
  print("ERRO DETALHADO DO FIREBASE: ${snapshot.error}"); 
  return Center(child: Text("Erro: ${snapshot.error}")); // Mostra na tela também
}
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Nenhum anúncio ativo no momento.", style: TextStyle(color: Colors.grey)),
                  Text("Seja o primeiro a anunciar!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var dados = docs[index].data() as Map<String, dynamic>;
              
              // Define cores e ícones baseados no tipo (Venda ou Serviço)
              bool isVenda = dados['tipo'] == 'VENDA';
              Color corTag = isVenda ? Colors.blue : Colors.purple;
              IconData iconeTag = isVenda ? Icons.shopping_bag_outlined : Icons.handyman_outlined;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho do Card: TAG (Venda/Serviço) + Valor
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: corTag.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(iconeTag, size: 16, color: corTag),
                                const SizedBox(width: 4),
                                Text(
                                  isVenda ? "VENDA" : "SERVIÇO",
                                  style: TextStyle(color: corTag, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dados['valor'] ?? "R\$ 0,00",
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Color(0xFF1B4D3E)
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Título e Descrição
                      Text(dados['titulo'] ?? "Sem Título", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(dados['descricao'] ?? "", style: TextStyle(color: Colors.grey[700])),
                      
                      const Divider(height: 24),
                      
                      // Rodapé: Quem está vendendo?
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${dados['autor_nome']} • ${dados['autor_unidade']}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ),
                          // Botão de Contato (Simulado por enquanto)
                          ElevatedButton(
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Contato via WhatsApp em breve!")));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 30),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            child: const Text("Tenho Interesse"),
                          )
                        ],
                      )
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