import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import 'package:intl/intl.dart';
// Adicionar no início:
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../utils/validators.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/date_picker_field.dart';

class NovaMetaScreen extends StatefulWidget {
  const NovaMetaScreen({super.key});

  @override
  State<NovaMetaScreen> createState() => _NovaMetaScreenState();
}

class _NovaMetaScreenState extends State<NovaMetaScreen> {
  final DBHelper db = DBHelper();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorObjetivoController =
      TextEditingController();
  final TextEditingController _valorAtualController = TextEditingController();

  DateTime _dataFim = DateTime.now().add(const Duration(days: 365));
  String _iconeSelecionado = 'flag';
  String _corSelecionada = 'viagem';

  final List<Map<String, dynamic>> _icones = const [
    {'valor': 'flag', 'icone': Icons.flag, 'label': 'Geral'},
    {'valor': 'viagem', 'icone': Icons.flight, 'label': 'Viagem'},
    {'valor': 'carro', 'icone': Icons.directions_car, 'label': 'Carro'},
    {'valor': 'casa', 'icone': Icons.home, 'label': 'Casa'},
    {'valor': 'estudo', 'icone': Icons.school, 'label': 'Estudo'},
    {
      'valor': 'investimento',
      'icone': Icons.trending_up,
      'label': 'Investimento'
    },
  ];

  final List<Map<String, dynamic>> _cores = const [
    {'valor': 'viagem', 'cor': Colors.blue, 'label': 'Viagem'},
    {'valor': 'carro', 'cor': Colors.red, 'label': 'Carro'},
    {'valor': 'casa', 'cor': Colors.green, 'label': 'Casa'},
    {'valor': 'estudo', 'cor': Colors.orange, 'label': 'Estudo'},
    {'valor': 'investimento', 'cor': Colors.purple, 'label': 'Investimento'},
  ];

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataFim,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('pt', 'BR'),
    );
    if (data != null) {
      setState(() {
        _dataFim = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Meta'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título da Meta',
                hintText: 'Ex: Comprar um carro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),

            // Descrição
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Quero comprar um carro até o final do ano',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Valor Objetivo
            TextField(
              controller: _valorObjetivoController,
              decoration: InputDecoration(
                labelText: 'Valor da Meta',
                hintText: '0,00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Valor Inicial (opcional)
            TextField(
              controller: _valorAtualController,
              decoration: InputDecoration(
                labelText: 'Valor Inicial (opcional)',
                hintText: '0,00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.account_balance_wallet),
                prefixText: 'R\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Data Fim
            InkWell(
              onTap: _selecionarData,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Limite',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_dataFim),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ícone
            const Text(
              'Ícone da Meta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _icones.map((icone) {
                  bool isSelected = _iconeSelecionado == icone['valor'];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _iconeSelecionado = icone['valor'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6A1B9A).withOpacity(0.1)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icone['icone'],
                            color: isSelected
                                ? const Color(0xFF6A1B9A)
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            icone['label'],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF6A1B9A)
                                  : Colors.grey[800],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF6A1B9A), size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Cor
            const Text(
              'Cor da Meta',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _cores.map((cor) {
                bool isSelected = _corSelecionada == cor['valor'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _corSelecionada = cor['valor'];
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cor['cor'],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6A1B9A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _salvarMeta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Criar Meta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _parseValor(String texto) {
    try {
      return double.parse(texto.replaceAll(',', '.'));
    } catch (e) {
      return 0;
    }
  }

  Future<void> _salvarMeta() async {
    if (_tituloController.text.isEmpty ||
        _valorObjetivoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o título e o valor da meta!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final valorObjetivo = _parseValor(_valorObjetivoController.text);
      final valorAtual = _parseValor(_valorAtualController.text);

      await db.insertMeta({
        'titulo': _tituloController.text,
        'descricao': _descricaoController.text,
        'valor_objetivo': valorObjetivo,
        'valor_atual': valorAtual,
        'data_inicio': DateTime.now().toIso8601String(),
        'data_fim': _dataFim.toIso8601String(),
        'icone': _iconeSelecionado,
        'cor': _corSelecionada,
        'concluida': 0,
      });

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _valorObjetivoController.dispose();
    _valorAtualController.dispose();
    super.dispose();
  }
}
