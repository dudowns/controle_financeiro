// lib/screens/editar_transacao.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // 🔥 IMPORT ADICIONADO!
import '../database/db_helper.dart';
import '../repositories/lancamento_repository.dart';
import '../models/lancamento_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../utils/validators.dart';
import '../utils/mask_formatters.dart';
import '../utils/currency_formatter.dart';

class EditarTransacaoScreen extends StatefulWidget {
  final Map<String, dynamic> lancamento;

  const EditarTransacaoScreen({Key? key, required this.lancamento})
      : super(key: key);

  @override
  State<EditarTransacaoScreen> createState() => _EditarTransacaoScreenState();
}

class _EditarTransacaoScreenState extends State<EditarTransacaoScreen> {
  // 🔥 Usar o repositório
  final LancamentoRepository _lancamentoRepo = LancamentoRepository();

  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();

  late String _tipoSelecionado;
  late String _categoriaSelecionada;
  late DateTime _dataSelecionada;

  bool _salvando = false;
  bool _excluindo = false;
  String? _erroValidacao;

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
  void initState() {
    super.initState();

    // Carregar dados do lançamento
    _tipoSelecionado = widget.lancamento['tipo'] ?? 'gasto';
    _categoriaSelecionada = widget.lancamento['categoria'] ?? 'Outros';
    _dataSelecionada = DateTime.parse(widget.lancamento['data']);

    _descricaoController.text = widget.lancamento['descricao'] ?? '';

    // Formatar valor para exibição (com vírgula)
    final valor = (widget.lancamento['valor'] ?? 0).toDouble();
    _valorController.text = valor.toStringAsFixed(2).replaceAll('.', ',');

    _observacaoController.text = widget.lancamento['observacao'] ?? '';
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  // Formatter para dinheiro
  List<TextInputFormatter> get _valorInputFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(13),
        _MoneyInputFormatter(),
      ];

  // Validação melhorada
  bool _validarValor(String valorStr) {
    setState(() => _erroValidacao = null);

    if (valorStr.isEmpty) {
      setState(() => _erroValidacao = 'Digite um valor');
      return false;
    }

    // Remove formatação
    String cleaned = valorStr.replaceAll('.', '').replaceAll(',', '.');

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

  // Salvar usando o repositório
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validarValor(_valorController.text)) return;

    setState(() => _salvando = true);

    try {
      // Converter valor para número
      String valorStr =
          _valorController.text.replaceAll('.', '').replaceAll(',', '.');
      final valor = double.parse(valorStr);

      final lancamentoAtualizado = {
        'id': widget.lancamento['id'],
        'descricao': _descricaoController.text,
        'tipo': _tipoSelecionado,
        'categoria': _categoriaSelecionada,
        'valor': valor,
        'data': _dataSelecionada.toIso8601String(),
        'observacao': _observacaoController.text.isNotEmpty
            ? _observacaoController.text
            : null,
      };

      await _lancamentoRepo.updateLancamento(lancamentoAtualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Lançamento atualizado!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _erroValidacao = 'Erro ao atualizar: $e';
      });
      _mostrarErro('Erro ao atualizar: $e');
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  // Deletar usando o repositório
  Future<void> _deletar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir este lançamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _excluindo = true);

      try {
        await _lancamentoRepo.deleteLancamento(widget.lancamento['id']);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Lançamento excluído!'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        _mostrarErro('Erro ao excluir: $e');
      } finally {
        if (mounted) {
          setState(() => _excluindo = false);
        }
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
    final bool processando = _salvando || _excluindo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Lançamento'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          if (!processando)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deletar,
            ),
          if (_excluindo)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
                              Colors.red, 'gasto', processando)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _buildTipoButton('Receita', Icons.arrow_upward,
                              Colors.green, 'receita', processando)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // DESCRIÇÃO
                  TextFormField(
                    controller: _descricaoController,
                    enabled: !processando,
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

                  // VALOR COM MONEY INPUT FORMATTER
                  TextFormField(
                    controller: _valorController,
                    keyboardType: TextInputType.number,
                    inputFormatters: _valorInputFormatters,
                    enabled: !processando,
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
                    onChanged: processando
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
                    onTap: processando ? null : _selecionarData,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(12),
                        color: processando ? Colors.grey[100] : Colors.white,
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
                                // 🔥 AQUI USA DateFormat CORRETAMENTE
                                DateFormat('dd/MM/yyyy')
                                    .format(_dataSelecionada),
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
                    enabled: !processando,
                    decoration: const InputDecoration(
                      labelText: 'Observação (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 30),

                  // BOTÕES
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              processando ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('CANCELAR'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: processando ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: _salvando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('SALVAR'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Overlay de carregamento
          if (processando)
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
                        Text('Processando...'),
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
      String texto, IconData icone, Color cor, String tipo, bool processando) {
    final isSelecionado = _tipoSelecionado == tipo;

    return InkWell(
      onTap: processando
          ? null
          : () {
              setState(() {
                _tipoSelecionado = tipo;
                _categoriaSelecionada = _categoriasAtuais.first;
                _erroValidacao = null;
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

// 🔥 Formatter de dinheiro
class _MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String cleaned = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return newValue;

    double value = double.parse(cleaned) / 100;
    String formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
