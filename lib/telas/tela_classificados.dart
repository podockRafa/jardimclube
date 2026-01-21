import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TelaClassificados extends StatefulWidget {
  const TelaClassificados({super.key});

  @override
  State<TelaClassificados> createState() => _TelaClassificadosState();
}

class _TelaClassificadosState extends State<TelaClassificados> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // --- FUNÇÃO 1: CRIAR NOVO ANÚNCIO (CORRIGIDA) ---
  void _novoAnuncio() {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController(); 
    String tipoSelecionado = 'VENDA'; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Novo Anúncio"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ESCOLHER TIPO (Com ajuste de espaçamento)
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Venda", style: TextStyle(fontSize: 14)), // Fonte um pouco menor ajuda
                            value: 'VENDA',
                            groupValue: tipoSelecionado,
                            contentPadding: EdgeInsets.zero, // <--- Tira a margem lateral
                            visualDensity: VisualDensity.compact, // <--- Deixa mais compacto
                            onChanged: (v) => setStateDialog(() => tipoSelecionado = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Serviço", style: TextStyle(fontSize: 14)), 
                            value: 'SERVICO',
                            groupValue: tipoSelecionado,
                            contentPadding: EdgeInsets.zero, // <--- Tira a margem lateral
                            visualDensity: VisualDensity.compact, // <--- Deixa mais compacto
                            onChanged: (v) => setStateDialog(() => tipoSelecionado = v!),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),

                    TextField(
                      controller: tituloCtrl,
                      decoration: InputDecoration(
                        labelText: tipoSelecionado == 'VENDA' ? "O que está vendendo?" : "Qual serviço oferece?",
                        border: const OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: "Descrição / Detalhes", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),

                    // CAMPO DINÂMICO
                    TextField(
                      controller: valorCtrl,
                      keyboardType: tipoSelecionado == 'VENDA' ? TextInputType.number : TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: tipoSelecionado == 'VENDA' ? "Valor (R\$)" : "WhatsApp/Telefone",
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(tipoSelecionado == 'VENDA' ? Icons.attach_money : Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (tituloCtrl.text.isEmpty) return;

                    var userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                    String nomeAutor = userDoc.data()?['nome'] ?? 'Vizinho';
                    String bloco = userDoc.data()?['bloco'] ?? '';
                    String apto = userDoc.data()?['unidade'] ?? '';

                    await FirebaseFirestore.instance.collection('classificados').add({
                      'titulo': tituloCtrl.text,
                      'descricao': descCtrl.text,
                      'valor_ou_contato': valorCtrl.text,
                      'tipo': tipoSelecionado,
                      'autor_uid': _user!.uid,
                      'autor_nome': "$nomeAutor ($bloco-$apto)",
                      'data_publicacao': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("PUBLICAR"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- FUNÇÃO 2: ENVIAR MENSAGEM DE INTERESSE (Só para Vendas) ---
  void _enviarInteresse(String docId, String tituloAnuncio) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tenho Interesse"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Envie uma mensagem para o vendedor de '$tituloAnuncio':"),
            const SizedBox(height: 10),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Ex: Olá, aceita oferta? Quando posso pegar?",
                border: OutlineInputBorder()
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (msgCtrl.text.isNotEmpty) {
                // Salva na subcoleção 'mensagens' DENTRO do anúncio
                var userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                String meuNome = userDoc.data()?['nome'] ?? 'Interessado';
                String meuApto = "${userDoc.data()?['bloco']}-${userDoc.data()?['unidade']}";

                await FirebaseFirestore.instance
                    .collection('classificados')
                    .doc(docId)
                    .collection('mensagens')
                    .add({
                  'mensagem': msgCtrl.text,
                  'remetente_uid': _user!.uid,
                  'remetente_nome': "$meuNome ($meuApto)",
                  'data_envio': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mensagem enviada!")));
              }
            },
            child: const Text("ENVIAR"),
          )
        ],
      ),
    );
  }

  // --- FUNÇÃO 3: VER MENSAGENS (Para o Dono do Anúncio) ---
  void _verMensagensRecebidas(String docId, String titulo) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Interessados em: $titulo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classificados')
                    .doc(docId)
                    .collection('mensagens')
                    .orderBy('data_envio', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhuma mensagem ainda."));

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var msg = snapshot.data!.docs[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(msg['remetente_nome']),
                        subtitle: Text(msg['mensagem']),
                        trailing: const Icon(Icons.reply, size: 16, color: Colors.grey),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- FUNÇÃO 4: EXCLUIR ANÚNCIO (Dono) ---
  void _excluirAnuncio(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalizar Anúncio?"),
        content: const Text("Isso apagará o anúncio e todas as mensagens recebidas."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('classificados').doc(docId).delete();
              if (!mounted) return;
              Navigator.pop(ctx);
            }, 
            child: const Text("FINALIZAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Classificados Internos"),
          backgroundColor: Colors.orange,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            tabs: [
              Tab(text: "VENDAS", icon: Icon(Icons.shopping_bag)),
              Tab(text: "SERVIÇOS", icon: Icon(Icons.handyman)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLista('VENDA'),
            _buildLista('SERVICO'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.orange,
          onPressed: _novoAnuncio,
          icon: const Icon(Icons.add_circle, color: Colors.white),
          label: const Text("ANUNCIAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLista(String tipoFiltro) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classificados')
          .where('tipo', isEqualTo: tipoFiltro)
          .orderBy('data_publicacao', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Erro ao carregar (Verificar Índice)"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tipoFiltro == 'VENDA' ? Icons.store_mall_directory_outlined : Icons.handyman, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Nenhum anúncio de ${tipoFiltro == 'VENDA' ? 'venda' : 'serviço'} ainda.", style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var dados = doc.data() as Map<String, dynamic>;
            bool souDono = dados['autor_uid'] == _user!.uid;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CABEÇALHO DO CARD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dados['titulo'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        if (souDono)
                          Row(
                            children: [
                              // Ícone de Mensagens (Só para Vendas)
                              if (tipoFiltro == 'VENDA')
                                IconButton(
                                  icon: const Icon(Icons.mail, color: Colors.blue),
                                  tooltip: "Ver Interessados",
                                  onPressed: () => _verMensagensRecebidas(doc.id, dados['titulo']),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Excluir",
                                onPressed: () => _excluirAnuncio(doc.id),
                              ),
                            ],
                          )
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    Text(dados['descricao'] ?? '', style: TextStyle(color: Colors.grey[800])),
                    const SizedBox(height: 12),
                    
                    // INFORMAÇÃO PRINCIPAL (Preço ou Contato)
                    Row(
                      children: [
                        Icon(
                          tipoFiltro == 'VENDA' ? Icons.attach_money : Icons.phone_android,
                          color: Colors.orange[800],
                          size: 20,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tipoFiltro == 'VENDA' 
                              ? "R\$ ${dados['valor_ou_contato']}" 
                              : "${dados['valor_ou_contato']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: Colors.orange[900]
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    Text("Anunciado por: ${dados['autor_nome']}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),

                    // BOTÃO DE INTERESSE (Apenas para VENDA e se NÃO for o dono)
                    if (tipoFiltro == 'VENDA' && !souDono) ...[
                      const Divider(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.chat),
                          label: const Text("TENHO INTERESSE"),
                          onPressed: () => _enviarInteresse(doc.id, dados['titulo']),
                        ),
                      ),
                    ],

                    // AVISO VISUAL DE SERVIÇO
                    if (tipoFiltro == 'SERVICO' && !souDono) ...[
                      const Divider(),
                      const Center(
                        child: Text(
                          "Entre em contato pelo número acima.",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ]
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