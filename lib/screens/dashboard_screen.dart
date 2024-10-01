import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'login.dart';

class Dashboard extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkTheme;

  const Dashboard({
    Key? key,
    required this.toggleTheme,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double _totalExpenses = 0.0;
  double _salary = 0.0;
  String? _selectedCategory;
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final TextEditingController _customCategoryController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _categories = [
    'Alquiler',
    'Servicios Públicos',
    'Mercado',
    'Transporte',
    'Deudas',
    'Otros',
    'Personalizado',
  ];

  final List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadExpenses();
  }

  void _loadUserData() async {
    final userDoc = await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();

    if (userDoc.exists) {
      setState(() {
        _salary = userDoc.data()?['salary'] ?? 0.0;
        if (_salary < 0) {
          _salary = 0;
        }
      });
    }
  }

  void _loadExpenses() async {
    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('expenses')
        .get();

    setState(() {
      _totalExpenses = 0.0;
      _expenses.clear();
      for (var doc in expensesSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Sin categoría';
        final value = (data['value'] as num?)?.toDouble() ?? 0.0;

        _expenses.add({
          'id': doc.id,
          'category': category,
          'value': value,
        });

        _totalExpenses += value;
      }
    });
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'salary': _salary,
        'expenses': _expenses,
      }, SetOptions(merge: true));
    }
  }

  Future<void> _updateSalary() async {
    double newSalary = double.tryParse(
            _salaryController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;

    if (newSalary > 0) {
      setState(() {
        _salary = newSalary;
        _totalExpenses = 0.0;
      });

      await _firestore
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({'salary': _salary}, SetOptions(merge: true));

      _salaryController.clear();
      _loadExpenses();
    }
  }

  void _addExpense() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar una categoría')),
      );
      return;
    }

    final expenseValue = double.tryParse(
            _expenseController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;

    if (expenseValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El valor del gasto debe ser mayor que cero')),
      );
      return;
    }

    String category = _selectedCategory!;
    if (category == 'Personalizado') {
      if (_customCategoryController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debes ingresar una categoría personalizada')),
        );
        return;
      }
      category = _customCategoryController.text;
    }

    setState(() {
      _expenses.add({
        'category': category,
        'value': expenseValue,
      });
      _totalExpenses += expenseValue;

      if (_salary < 0) {
        _salary = 0;
      }

      _expenseController.clear();
      _customCategoryController.clear();
    });

    await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('expenses')
        .add({
      'category': category,
      'value': expenseValue,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _loadExpenses();

    setState(() {
      _selectedCategory = null;
    });
  }

  Future<void> _deleteExpense(String expenseId, double expenseValue) async {
    await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('expenses')
        .doc(expenseId)
        .delete();

    setState(() {
      _totalExpenses -= expenseValue;
      _expenses.removeWhere((expense) => expense['id'] == expenseId);
    });

    _loadExpenses();
    _saveUserData();
  }

  void _showUpdateSalaryDialog() {
    _salaryController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Actualizar Sueldo'),
          content: TextField(
            controller: _salaryController,
            decoration: const InputDecoration(
              labelText: 'Nuevo sueldo',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsSeparatorInputFormatter()],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _updateSalary();
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => LoginScreen(
                          toggleTheme: widget.toggleTheme,
                          isDarkTheme: widget.isDarkTheme,
                        )),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialSummary(),
              const SizedBox(height: 20),
              _buildExpenseInputSection(),
              const SizedBox(height: 20),
              _buildExpenseChart(),
              const SizedBox(height: 20),
              _buildExpenseList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    double availableBalance = _salary - _totalExpenses;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen Financiero',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _buildSummaryItem('Sueldo', _salary),
            _buildSummaryItem('Total de Gastos', _totalExpenses),
            _buildSummaryItem('Balance Disponible', availableBalance),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _showUpdateSalaryDialog();
                },
                child: const Text('Actualizar Sueldo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            formatCurrency(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseInputSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Agregar Gasto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            if (_selectedCategory == 'Personalizado')
              TextField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoría personalizada',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _expenseController,
              decoration: const InputDecoration(
                labelText: 'Valor del gasto',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addExpense,
              child: const Text('Agregar Gasto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Gastos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxExpenseValue(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8.0),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${_getCategoryName(group.x.toInt())}\n${formatCurrency(rod.toY)}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 ||
                              value >= _getUniqueCategories().length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getCategoryName(value.toInt()),
                              style: TextStyle(
                                color: widget.isDarkTheme
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatCurrency(value),
                            style: TextStyle(
                              color: widget.isDarkTheme
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _getExpenseBarGroups(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getUniqueCategories() {
    Set<String> uniqueCategories =
        Set<String>.from(_expenses.map((e) => e['category'] as String));
    return uniqueCategories.toList();
  }

  String _getCategoryName(int index) {
    List<String> uniqueCategories = _getUniqueCategories();
    if (index >= 0 && index < uniqueCategories.length) {
      return uniqueCategories[index];
    }
    return '';
  }

  List<BarChartGroupData> _getExpenseBarGroups() {
    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      categoryTotals[expense['category']] =
          (categoryTotals[expense['category']] ?? 0) + expense['value'];
    }

    List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];

    List<String> uniqueCategories = _getUniqueCategories();

    return List.generate(uniqueCategories.length, (index) {
      final category = uniqueCategories[index];
      final value = categoryTotals[category] ?? 0.0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[index % colors.length],
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxExpenseValue() {
    if (_expenses.isEmpty) return 100;
    return _expenses
            .map((e) => e['value'] as double)
            .reduce((a, b) => a > b ? a : b) *
        1.2;
  }

  Widget _buildExpenseList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lista de Gastos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  title: Text(expense['category']),
                  subtitle: Text(formatCurrency(expense['value'] ?? 0)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteExpense(expense['id'], expense['value']);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return TextEditingValue.empty;
    }

    final number =
        double.tryParse(newValue.text.replaceAll('.', '').replaceAll(',', '.'));
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###', 'es_CO').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
