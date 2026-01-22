import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tela_minhas_mensagens.dart';

class TelaClassificados extends StatefulWidget {
  const TelaClassificados({super.key});

  @override
  State<TelaClassificados> createState() => _TelaClassificadosState();
}

class _TelaClassificadosState extends State<TelaClassificados> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // --- FUNÇÃO 1: CRIAR NOVO ANÚNCIO ---
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
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Venda", style: TextStyle(fontSize: 14)),
                            value: 'VENDA',
                            groupValue: tipoSelecionado,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setStateDialog(() => tipoSelecionado = v!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Serviço", style: TextStyle(fontSize: 14)), 
                            value: 'SERVICO',
                            groupValue: tipoSelecionado,
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onChanged: (v) => setStateDialog(() => tipoSelecionado = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: tituloCtrl, decoration: InputDecoration(labelText: tipoSelecionado == 'VENDA' ? "O que está vendendo?" : "Qual serviço oferece?", border: const OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Descrição / Detalhes", border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: valorCtrl, keyboardType: tipoSelecionado == 'VENDA' ? TextInputType.number : TextInputType.phone, decoration: InputDecoration(labelText: tipoSelecionado == 'VENDA' ? "Valor (R\$)" : "WhatsApp/Telefone", border: const OutlineInputBorder(), prefixIcon: Icon(tipoSelecionado == 'VENDA' ? Icons.attach_money : Icons.phone))),
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
                      'status': 'PENDENTE',
                    });

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Anúncio enviado para aprovação!"), backgroundColor: Colors.blue));
                  },
                  child: const Text("ENVIAR PARA ANÁLISE"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  // --- FUNÇÃO 2: ENVIAR INTERESSE (Comprador) ---
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
            TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(hintText: "Ex: Olá, aceita oferta?", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (msgCtrl.text.isNotEmpty) {
                var userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                String meuNome = userDoc.data()?['nome'] ?? 'Interessado';
                String meuApto = "${userDoc.data()?['bloco']}-${userDoc.data()?['unidade']}";

                await FirebaseFirestore.instance.collection('classificados').doc(docId).collection('mensagens').add({
                  'mensagem': msgCtrl.text,
                  'remetente_uid': _user!.uid,
                  'remetente_nome': "$meuNome ($meuApto)",
                  'data_envio': FieldValue.serverTimestamp(),
                  'tipo': 'PERGUNTA' // Marca que é uma pergunta
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

  // --- NOVA FUNÇÃO: RESPONDER MENSAGEM (Vendedor) ---
  void _responderMensagem(String docId, String nomeComprador) {
    final respCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Responder a $nomeComprador"),
        content: TextField(
          controller: respCtrl,
          maxLines: 2,
          decoration: const InputDecoration(hintText: "Sua resposta...", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (respCtrl.text.isNotEmpty) {
                var userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
                String meuNome = userDoc.data()?['nome'] ?? 'Vendedor';
                
                // Salva a resposta na mesma coleção
                await FirebaseFirestore.instance.collection('classificados').doc(docId).collection('mensagens').add({
                  'mensagem': respCtrl.text,
                  'remetente_uid': _user!.uid,
                  'remetente_nome': meuNome,
                  'data_envio': FieldValue.serverTimestamp(),
                  'tipo': 'RESPOSTA' // Marca que é resposta
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Resposta enviada!")));
              }
            },
            child: const Text("RESPONDER"),
          )
        ],
      ),
    );
  }

  // --- FUNÇÃO 3: VER MENSAGENS E RESPONDER ---
  void _verMensagensRecebidas(String docId, String titulo) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Mensagens sobre: $titulo", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('classificados').doc(docId).collection('mensagens').orderBy('data_envio', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Nenhuma mensagem ainda."));

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var msg = snapshot.data!.docs[index];
                      bool souEu = msg['remetente_uid'] == _user!.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: souEu ? Colors.grey : Colors.blue,
                          child: Icon(souEu ? Icons.person : Icons.question_answer, color: Colors.white),
                        ),
                        title: Text(souEu ? "Você respondeu:" : msg['remetente_nome']),
                        subtitle: Text(msg['mensagem']),
                        // Se NÃO fui eu que mandei (é pergunta), mostra botão de responder
                        trailing: !souEu 
                          ? IconButton(
                              icon: const Icon(Icons.reply, color: Colors.green),
                              onPressed: () => _responderMensagem(docId, msg['remetente_nome']),
                              tooltip: "Responder",
                            )
                          : null,
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

  // --- FUNÇÃO 4: EXCLUIR ANÚNCIO ---
  void _excluirAnuncio(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Finalizar Anúncio?"),
        content: const Text("Isso apagará o anúncio e todas as mensagens."),
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
          backgroundColor: const Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: "VENDAS", icon: Icon(Icons.shopping_bag)), Tab(text: "SERVIÇOS", icon: Icon(Icons.handyman))],
          ),
        ),
        body: TabBarView(children: [_buildLista('VENDA'), _buildLista('SERVICO')]),
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
            children: [
              // 1. BOTÃO DE MENSAGENS (O "Cardzinho" Azul)
              FloatingActionButton.extended(
                heroTag: "btnMensagens", // Necessário quando tem 2 botões para não dar erro
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.chat),
                label: const Text("Minhas\nMensagens"),
                onPressed: () {
                  // Precisamos importar a tela nova no topo do arquivo se ainda não estiver
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaMinhasMensagens()));
                },
              ),
              
              const SizedBox(width: 16), // Espaço entre os botões

              // 2. BOTÃO DE ANUNCIAR (O Laranja original)
              FloatingActionButton.extended(
                heroTag: "btnAnunciar",
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_circle),
                label: const Text("ANUNCIAR", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _novoAnuncio,
              ),
            ],
          ),
        ),
      )
    );
    
  }

  Widget _buildLista(String tipoFiltro) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classificados')
          .where('tipo', isEqualTo: tipoFiltro)
          .where('status', isEqualTo: 'ATIVO')
          .orderBy('data_publicacao', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(tipoFiltro == 'VENDA' ? Icons.store_mall_directory_outlined : Icons.handyman, size: 60, color: Colors.grey[300]), const SizedBox(height: 10), Text("Nenhum anúncio disponível.", style: TextStyle(color: Colors.grey[400]))]));

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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(dados['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                        if (souDono) Row(children: [if (tipoFiltro == 'VENDA') IconButton(icon: const Icon(Icons.mail, color: Colors.blue), onPressed: () => _verMensagensRecebidas(doc.id, dados['titulo'])), IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluirAnuncio(doc.id))])
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(dados['descricao'] ?? '', style: TextStyle(color: Colors.grey[800])),
                    const SizedBox(height: 12),
                    Row(children: [Icon(tipoFiltro == 'VENDA' ? Icons.attach_money : Icons.phone_android, color: Colors.orange[800], size: 20), const SizedBox(width: 5), Text(tipoFiltro == 'VENDA' ? "R\$ ${dados['valor_ou_contato']}" : "${dados['valor_ou_contato']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange[900]))]),
                    const SizedBox(height: 8),
                    Text("Anunciado por: ${dados['autor_nome']}", style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    if (tipoFiltro == 'VENDA' && !souDono) ...[const Divider(), SizedBox(width: double.infinity, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), icon: const Icon(Icons.chat), label: const Text("TENHO INTERESSE"), onPressed: () => _enviarInteresse(doc.id, dados['titulo'])))]
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