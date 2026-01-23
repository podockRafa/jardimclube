import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'tela_login.dart';

class TelaLandingPage extends StatefulWidget {
  const TelaLandingPage({super.key});

  @override
  State<TelaLandingPage> createState() => _TelaLandingPageState();
}

class _TelaLandingPageState extends State<TelaLandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _keyInicio = GlobalKey();
  final GlobalKey _keyEstrutura = GlobalKey();
  final GlobalKey _keyImoveis = GlobalKey();
  final GlobalKey _keyLocalizacao = GlobalKey();
  final GlobalKey _keyContato = GlobalKey();

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(key.currentContext!, duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  // Formulário
  final _nomeVisitanteCtrl = TextEditingController();
  final _contatoVisitanteCtrl = TextEditingController();
  final _msgVisitanteCtrl = TextEditingController();

  Future<void> _enviarContato() async {
    if (_nomeVisitanteCtrl.text.isEmpty || _contatoVisitanteCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha nome e contato.")));
      return;
    }
    await FirebaseFirestore.instance.collection('contatos_site').add({
      'nome': _nomeVisitanteCtrl.text,
      'contato': _contatoVisitanteCtrl.text,
      'mensagem': _msgVisitanteCtrl.text,
      'data': FieldValue.serverTimestamp(),
      'status': 'NOVO'
    });
    
    if (!context.mounted) return;
    _nomeVisitanteCtrl.clear(); _contatoVisitanteCtrl.clear(); _msgVisitanteCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mensagem enviada! Entraremos em contato."), backgroundColor: Color(0xFF1B4D3E))
    );
  }

  Future<void> _abrirMapa() async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=Rua+Baronesa+de+Mesquita,+1308,+Mesquita+RJ");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw Exception('Could not launch');
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Não foi possível abrir o mapa.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pegamos a largura da tela para decidir o tamanho
    final larguraTela = MediaQuery.of(context).size.width;
    final bool isDesktop = larguraTela > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      
      // MENU LATERAL (Direita)
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // CORREÇÃO AQUI: Trocamos DrawerHeader por Container Personalizado
            Container(
              width: double.infinity,
              // Agora a altura do fundo verde cresce junto com a tela
              height: isDesktop ? 350 : 220, 
              color: const Color(0xFF1B4D3E),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  // Altura da imagem controlada
                  height: isDesktop ? 260 : 160, 
                  fit: BoxFit.contain,
                  // Mudei para medium, costuma ser melhor para linhas finas
                  filterQuality: FilterQuality.medium, 
                  isAntiAlias: true,
                ),
              ),
            ),

            ListTile(leading: const Icon(Icons.home), title: const Text('Início'), onTap: () { Navigator.pop(context); _scrollTo(_keyInicio); }),
            ListTile(leading: const Icon(Icons.apartment), title: const Text('Estrutura'), onTap: () { Navigator.pop(context); _scrollTo(_keyEstrutura); }),
            ListTile(leading: const Icon(Icons.key), title: const Text('Imóveis'), onTap: () { Navigator.pop(context); _scrollTo(_keyImoveis); }),
            ListTile(leading: const Icon(Icons.map), title: const Text('Localização'), onTap: () { Navigator.pop(context); _scrollTo(_keyLocalizacao); }),
            ListTile(leading: const Icon(Icons.mail), title: const Text('Contato'), onTap: () { Navigator.pop(context); _scrollTo(_keyContato); }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login, color: Colors.blue),
              title: const Text('Área do Morador', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaLogin())),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 30, shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // 1. CAPA (HERO)
            Image.asset(
              key: _keyInicio,
              'assets/images/topo.png',
              width: double.infinity,
              fit: BoxFit.fitWidth, 
            ),

            // 2. ESTRUTURA
            Container(
              key: _keyEstrutura,
              color: Colors.white,
              child: _conteudoLimitado(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                child: Column(
                  children: [
                    const Text("Nossa Estrutura", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Container(width: 60, height: 3, color: Colors.orange),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        _cardDiferencial(Icons.apartment, "9 Blocos", Colors.redAccent),
                        _cardDiferencial(Icons.pool, "Piscina", Colors.blue),
                        _cardDiferencial(Icons.security, "Portaria 24h", Colors.green),
                        _cardDiferencial(Icons.celebration, "Salão de Festas", Colors.orange),
                        _cardDiferencial(Icons.outdoor_grill, "Churrasqueira", Colors.red),
                        _cardDiferencial(Icons.local_parking, "Estacionamento", Colors.black87),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 3. IMÓVEIS
            Container(
              key: _keyImoveis,
              color: Colors.grey[50],
              child: _conteudoLimitado(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                child: Column(
                  children: [
                    const Text("Unidades Disponíveis", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Container(width: 60, height: 3, color: Colors.blue),
                    const SizedBox(height: 30),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('classificados')
                          .where('tipo', isEqualTo: 'IMOVEL')
                          .where('status', isEqualTo: 'ATIVO')
                          .orderBy('data_publicacao', descending: true)
                          .limit(6)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        if (snapshot.data!.docs.isEmpty) {
                           return Container(
                             padding: const EdgeInsets.all(30),
                             width: double.infinity,
                             decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10), color: Colors.white),
                             child: Column(
                               children: [
                                 Icon(Icons.house_siding, size: 50, color: Colors.grey[300]),
                                 const SizedBox(height: 10),
                                 const Text("Nenhuma unidade anunciada no momento.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                               ],
                             )
                           );
                        }
                        
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 700) {
                              return Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: snapshot.data!.docs.map((doc) {
                                  return SizedBox(
                                    width: (constraints.maxWidth / 2) - 15,
                                    child: _cardImovel(doc),
                                  );
                                }).toList(),
                              );
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) => Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  child: _cardImovel(snapshot.data!.docs[index])
                                ),
                              );
                            }
                          }
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // 4. LOCALIZAÇÃO
            Container(
              key: _keyLocalizacao,
              color: Colors.white,
              child: _conteudoLimitado(
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 30),
                child: Column(
                  children: [
                    const Text("Localização Privilegiada", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),
                    Container(width: 60, height: 3, color: Colors.redAccent),
                    const SizedBox(height: 30),
                    
                    InkWell(
                      onTap: _abrirMapa,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 40, color: Colors.redAccent),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Rua Baronesa de Mesquita, 1308", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const Text("Mesquita - RJ", style: TextStyle(fontSize: 16)),
                                  Text("Toque para abrir no mapa", style: TextStyle(color: Colors.red[300], fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text("O que temos aqui perto?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _itemLocalizacao(Icons.school, "Escolas", "Rakel Rechuem, Brito Elias"),
                    _itemLocalizacao(Icons.restaurant, "Restaurantes", "Gabi Fontes, Nosso Lugar, Espaço Gourmet"),
                    _itemLocalizacao(Icons.shopping_cart, "Mercados", "TurboMil, Magnata"),
                    _itemLocalizacao(Icons.local_pharmacy, "Farmácias", "Drogaria Mais Barato, Atual"),
                    _itemLocalizacao(Icons.fastfood, "Lanches", "Açaí do Bomba"),
                    _itemLocalizacao(Icons.directions_bus, "Condução", "Ponto na porta. Estações de trem (8min a pé)"),
                    _itemLocalizacao(Icons.fitness_center, "Lazer e Saúde", "Ciclovia, academia ao ar livre, quadras"),
                    _itemLocalizacao(Icons.local_police, "Segurança", "Polícia Presente, 20º Batalhão, 53ª DP"),
                  ],
                ),
              ),
            ),

            // 5. CONTATO
            Container(
              key: _keyContato,
              color: const Color(0xFF1B4D3E),
              child: _conteudoLimitado(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
                child: Column(
                  children: [
                    const Text("Fale Conosco", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text("Dúvidas? Agende uma visita.", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 30),
                    
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          _campoTexto("Seu nome", _nomeVisitanteCtrl),
                          const SizedBox(height: 15),
                          _campoTexto("Seu email ou telefone", _contatoVisitanteCtrl),
                          const SizedBox(height: 15),
                          
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: _msgVisitanteCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(border: InputBorder.none, hintText: "Deixe sua mensagem"),
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _enviarContato, 
                              child: const Text("ENVIAR MENSAGEM", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. RODAPÉ
            Container(
              color: const Color(0xFF12382C),
              child: _conteudoLimitado(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("Condomínio Residencial Jardim Clube", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Text("Mesquita - RJ © 2026", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                      ),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaLogin())),
                      icon: const Icon(Icons.login),
                      label: const Text("Acesso do Morador")
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- O SEGREDO DO LAYOUT LIMPO ---
  Widget _conteudoLimitado({required Widget child, required EdgeInsets padding}) {
    return Center(
      child: Container(
        padding: padding,
        constraints: const BoxConstraints(maxWidth: 1100), 
        child: child,
      ),
    );
  }

  Widget _cardImovel(DocumentSnapshot doc) {
    var dados = doc.data() as Map<String, dynamic>;
    String titulo = dados['titulo'] ?? '';
    bool isAluguel = titulo.toUpperCase().contains('ALUGUEL');
    Color corTag = isAluguel ? Colors.blue : Colors.green;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5, offset: const Offset(0, 2))],
        border: Border.all(color: corTag.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: corTag, borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
            child: Text(isAluguel ? "ALUGUEL" : "VENDA", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dados['descricao'] ?? '', style: TextStyle(color: Colors.grey[800])),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.phone_android, size: 18, color: corTag),
                      const SizedBox(width: 8),
                      Text(dados['valor_ou_contato'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTag)),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDiferencial(IconData icon, String titulo, Color corIcone) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: corIcone.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 35, color: corIcone)
          ),
          const SizedBox(height: 15),
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _itemLocalizacao(IconData icon, String titulo, String descricao) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF1B4D3E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF1B4D3E), size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 5),
                Text(descricao, style: TextStyle(color: Colors.grey[700], height: 1.4, fontSize: 15)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _campoTexto(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange, width: 2)),
      ),
    );
  }
}