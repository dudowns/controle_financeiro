// lib/screens/nova_transacao.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../repositories/lancamento_repository.dart'; // NOVO: import do repositório
import '../models/lancamento_model.dart'; // NOVO: import do modelo
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
  // 🔥 MUDANÇA 1: Usar o repositório
  final LancamentoRepository _lancamentoRepo = LancamentoRepository();

  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();

  String _tipoSelecionado = 'gasto'; // 'receita' ou 'gasto'
  String _categoriaSelecionada = 'Alimentação';
  DateTime _dataSelecionada = DateTime.now();

  bool _salvando = false; // 🔥 NOVO: controlar estado de salvamento
  String? _erroValidacao; // 🔥 NOVO: erro de validação

  final List<String> _categoriasReceita = const [
    'Renda Extra',
    'Salário',
    'Investimentos',
    'Outros',
  ];

  final List<String> _categoriasGasto = const [
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

  // 🔥 MUDANÇA 2: Usar o MoneyInputFormatter que você já tem!
  List<TextInputFormatter> get _valorInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(13),
        _MoneyInputFormatter(),
      ];

  // 🔥 MUDANÇA 3: Validação melhorada
  bool _validarValor(String valorStr) {
    setState(() => _erroValidacao = null);

    if (valorStr.isEmpty) {
      setState(() => _erroValidacao = 'Digite um valor');
      return false;
    }

    // Remove R$ e espaços se tiver
    String cleaned = valorStr.replaceAll('R\$', '').replaceAll(' ', '');
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');

    if (cleaned.isEmpty) {
      setState(() => _erroValidacao = 'Valor inválido');
      return false;
    }

    final valor = double.tryParse(cleaned);

    if (valor == null) {
      setState(() => _erroValidacao = 'Digite um número válido');
      return false;
    }

    if (valor <= 0) {
      setState(() => _erroValidacao = 'O valor deve ser maior que zero');
      return false;
    }

    if (valor > 999999999) {
      setState(() => _erroValidacao = 'Valor muito alto');
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

  // 🔥 MUDANÇA 4: Salvar usando o repositório
  Future<void> _salvar() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) return;

    // Validar valor especificamente
    if (!_validarValor(_valorController.text)) return;

    setState(() => _salvando = true);

    try {
      // Converter valor para número
      String valorStr = _valorController.text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      final valor = double.parse(valorStr);

      // Criar o lançamento
      final lancamento = {
        'descricao': _descricaoController.text,
        'tipo': _tipoSelecionado,
        'categoria': _categoriaSelecionada,
        'valor': valor,
        'data': _dataSelecionada.toIso8601String(),
        'observacao': _observacaoController.text.isNotEmpty
            ? _observacaoController.text
            : null,
      };

      // Inserir usando o repositório
      await _lancamentoRepo.insertLancamento(lancamento);

      if (mounted) {
        // Mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ ${_tipoSelecionado == 'receita' ? 'Receita' : 'Gasto'} de ${CurrencyFormatter.format(valor)} adicionado!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erroValidacao = 'Erro ao salvar: $e';
        });
        _mostrarErro('Erro ao salvar: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
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
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TIPO
                  const Text('Tipo',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTipoButton('Gasto', Icons.arrow_downward,
                              Colors.red, 'gasto')),
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
                    enabled: !_salvando,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite uma descrição';
                      }
                      if (value.length < 3) {
                        return 'Mínimo 3 caracteres';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // 🔥 VALOR COM MONEY INPUT FORMATTER
                  TextFormField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    inputFormatters: _valorInputFormatters,
                    enabled: !_salvando,
                    decoration: InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0,00',
                      errorText: _erroValidacao,
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
                    value: _categoriaSelecionada,
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
                    onChanged: _salvando
                        ? null
                        : (value) {
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
                    onTap: _salvando ? null : _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                        color: _salvando ? Colors.grey[100] : Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Color(0xFF6A1B9A)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_dataSelecionada.day.toString().padLeft(2, '0')}/'
                                '${_dataSelecionada.month.toString().padLeft(2, '0')}/'
                                '${_dataSelecionada.year}',
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

                  const SizedBox(height: 20),

                  // OBSERVAÇÃO
                  TextFormField(
                    controller: _observacaoController,
                    enabled: !_salvando,
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
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'SALVAR',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 🔥 NOVO: Overlay de carregamento
          if (_salvando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Salvando lançamento...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipoButton(
      String texto, IconData icone, Color cor, String tipo) {
    final isSelecionado = _tipoSelecionado == tipo;

    return InkWell(
      onTap: _salvando
          ? null
          : () {
              setState(() {
                _tipoSelecionado = tipo;
                _categoriaSelecionada = _categoriasAtuais.first;
                _erroValidacao = null; // Limpar erro ao mudar tipo
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

// 🔥 NOVO: Formatter de dinheiro (igual ao seu mask_formatters.dart)
class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return newValue;

    // Converter para double e formatar
    double value = double.parse(cleaned) / 100;
    String formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
