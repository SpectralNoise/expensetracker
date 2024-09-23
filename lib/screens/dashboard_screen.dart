import 'package:expense_tracker/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      theme: ThemeData.light(), // Tema claro si lo necesitas
      darkTheme: ThemeData.dark(), // Tema oscuro
      themeMode: ThemeMode.dark, // Usar siempre el tema oscuro
      home: Dashboard(
        toggleTheme: () {},
        isDarkTheme: true,
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard(
      {super.key,
      required Null Function() toggleTheme,
      required bool isDarkTheme});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double _totalExpenses = 0.0;
  double _salary = 0.0;
  bool _isEditingSalary = false; // Estado para controlar la visibilidad
  String? _selectedCategory;
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _categories = [
    'Alquiler',
    'Servicios Públicos',
    'Mercado',
    'Transporte',
    'Deudas',
    'Otros',
  ];

  final List<Map<String, dynamic>> _expenses = [];

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

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
        _salary = userDoc.data()?['salary'] ?? 0.0; // Manejo de nulos
        // Asegúrate de que el sueldo no sea negativo al cargarlo
        if (_salary < 0) {
          _salary = 0; // Ajustar el sueldo a 0 si se vuelve negativo
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
      // No restar los gastos del sueldo aquí
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

    final String category = _selectedCategory!;

    setState(() {
      _expenses.add({
        'category': category,
        'value': expenseValue,
      });
      _totalExpenses += expenseValue;

      // Asegúrate de que el sueldo no sea negativo
      if (_salary < 0) {
        _salary = 0; // Ajustar el sueldo a 0 si se vuelve negativo
      }

      // Limpiar el controlador de gastos
      _expenseController.clear();
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
    // Eliminar el gasto de Firestore
    await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('expenses')
        .doc(expenseId)
        .delete();

    // Actualizar el estado local
    setState(() {
      _totalExpenses -= expenseValue; // Restar del total de gastos
      // Aquí no debes sumar al sueldo, ya que eso es incorrecto
      _expenses.removeWhere((expense) =>
          expense['id'] == expenseId); // Eliminar de la lista local
    });

    // Cargar nuevamente los gastos para asegurarte de que todo esté actualizado
    _loadExpenses();
    // Guardar los datos después de eliminar
    _saveUserData();
  }

  void _showUpdateSalaryDialog() {
    // Limpiar el controlador antes de abrir el diálogo
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
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _updateSalary(); // Llama al método para actualizar el sueldo
                Navigator.of(context)
                    .pop(); // Cierra el diálogo después de guardar
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navegar a la pantalla de login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
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
              _buildFinancialSummary(), // Resumen financiero (con botón de actualizar sueldo)
              const SizedBox(height: 20),
              _buildExpenseInputSection(), // Sección para agregar gastos
              const SizedBox(height: 20),
              _buildExpenseChart(), // Gráfico de gastos
              const SizedBox(height: 20),
              _buildExpenseList(), // Lista de gastos
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
              // Centra el botón
              child: ElevatedButton(
                onPressed: () {
                  _showUpdateSalaryDialog(); // Abre el diálogo para actualizar el sueldo
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
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _getExpenseChartSections(),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getExpenseChartSections() {
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
    ];

    return categoryTotals.entries.map((entry) {
      int colorIndex = _categories.indexOf(entry.key) % colors.length;
      return PieChartSectionData(
        color: colors[colorIndex],
        value: entry.value,
        title: '${entry.key}\n${formatCurrency(entry.value)}',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
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
