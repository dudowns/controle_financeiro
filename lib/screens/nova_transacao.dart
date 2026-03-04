import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../utils/validators.dart';
import '../utils/mask_formatters.dart';
import '../utils/currency_formatter.dart';

class NovaTransacaoScreen extends StatefulWidget {
  const NovaTransacaoScreen({Key? key}) : super(key: key);

  @override
  State<NovaTransacaoScreen> createState() => _NovaTransacaoScreenState();
}

class _NovaTransacaoScreenState extends State<NovaTransacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();

  String _tipoSelecionado = 'gasto'; // 'receita' ou 'gasto'
  String _categoriaSelecionada = 'Alimentação';
  DateTime _dataSelecionada = DateTime.now();

  final List<String> _categoriasReceita = [
    'Renda Extra',
    'Salário',
    'Investimentos',
    'Outros',
  ];

  final List<String> _categoriasGasto = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Investimentos',
    'Cuidados Pessoais',
    'Empréstimo',
    'Outros',
  ];

  List<String> get _categoriasAtuais {
    return _tipoSelecionado == 'receita'
        ? _categoriasReceita
        : _categoriasGasto;
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // 🔥 VALIDAÇÃO FORTE DO VALOR
  bool _validarValor(String valorStr) {
    if (valorStr.isEmpty) {
      _mostrarErro('Digite um valor');
      return false;
    }

    // Remove espaços e substitui vírgula por ponto
    valorStr = valorStr.trim().replaceAll(',', '.');

    // Verifica caracteres inválidos
    if (valorStr == '+' || valorStr == '-' || valorStr == '.') {
      _mostrarErro('Valor inválido');
      return false;
    }

    // Tenta converter para número
    final valor = double.tryParse(valorStr);

    if (valor == null) {
      _mostrarErro('Digite um número válido (ex: 10,50)');
      return false;
    }

    if (valor <= 0) {
      _mostrarErro('O valor deve ser maior que zero');
      return false;
    }

    return true;
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _salvar() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) return;

    // Validar valor especificamente
    if (!_validarValor(_valorController.text)) return;

    // Converter valor para número
    final valorBruto = _valorController.text.trim().replaceAll(',', '.');
    final valor = double.parse(valorBruto);

    // Criar mapa para salvar
    final lancamento = {
      'descricao': _descricaoController.text,
      'tipo': _tipoSelecionado,
      'categoria': _categoriaSelecionada,
      'valor': valor, // SEMPRE POSITIVO (o tipo define se é receita/gasto)
      'data': _dataSelecionada.toIso8601String(),
      'observacao': _observacaoController.text.isNotEmpty
          ? _observacaoController.text
          : null,
    };

    try {
      final db = DBHelper();
      await db.insertLancamento(lancamento);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lançamento salvo com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao salvar: $e');
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Lançamento'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TIPO
              const Text('Tipo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildTipoButton(
                          'Gasto', Icons.arrow_downward, Colors.red, 'gasto')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildTipoButton('Receita', Icons.arrow_upward,
                          Colors.green, 'receita')),
                ],
              ),

              const SizedBox(height: 20),

              // DESCRIÇÃO
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite uma descrição';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // 🔥 VALOR COM VALIDAÇÃO FORTE
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[,.]?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Ex: 10,50',
                  helperText: 'Digite apenas números positivos',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite um valor';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // CATEGORIA
              DropdownButtonFormField<String>(
                initialValue: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categoriasAtuais.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoriaSelecionada = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // DATA
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dataSelecionada.day.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.month.toString().padLeft(2, '0')}/'
                        '${_dataSelecionada.year}',
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // OBSERVAÇÃO
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 30),

              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SALVAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoButton(
      String texto, IconData icone, Color cor, String tipo) {
    final isSelecionado = _tipoSelecionado == tipo;

    return InkWell(
      onTap: () {
        setState(() {
          _tipoSelecionado = tipo;
          _categoriaSelecionada = _categoriasAtuais.first;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelecionado ? cor.withOpacity(0.1) : Colors.grey.shade100,
          border: Border.all(
            color: isSelecionado ? cor : Colors.grey.shade300,
            width: isSelecionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, color: isSelecionado ? cor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                color: isSelecionado ? cor : Colors.grey.shade700,
                fontWeight: isSelecionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
