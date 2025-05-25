import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

class Product {
  String name;
  String description;
  double price;
  int quantity;
  int stock;

  Product({
    required this.name,
    required this.description,
    required this.price,
    this.quantity = 0,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      name: map['name'],
      description: map['description'],
      price: map['price'],
      quantity: map['quantity'],
      stock: map['stock'],
    );
  }
}

class ProductHistory {
  final DateTime timestamp;
  final String action; // 'add', 'edit', 'delete'
  final Product? oldProduct;
  final Product? newProduct;
  final String changedBy;

  ProductHistory({
    required this.timestamp,
    required this.action,
    this.oldProduct,
    this.newProduct,
    this.changedBy = 'system',
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'oldProduct': oldProduct?.toMap(),
      'newProduct': newProduct?.toMap(),
      'changedBy': changedBy,
    };
  }

  factory ProductHistory.fromMap(Map<String, dynamic> map) {
    return ProductHistory(
      timestamp: DateTime.parse(map['timestamp']),
      action: map['action'],
      oldProduct: map['oldProduct'] != null ? Product.fromMap(map['oldProduct']) : null,
      newProduct: map['newProduct'] != null ? Product.fromMap(map['newProduct']) : null,
      changedBy: map['changedBy'],
    );
  }
}

class BillRecord {
  final String billNo;
  final String customerName;
  final String phone;
  final double total;
  final DateTime date;
  final String billText;
  final String qrData;

  BillRecord({
    required this.billNo,
    required this.customerName,
    required this.phone,
    required this.total,
    required this.date,
    required this.billText,
    required this.qrData,
  });

  Map<String, dynamic> toMap() {
    return {
      'billNo': billNo,
      'customerName': customerName,
      'phone': phone,
      'total': total,
      'date': date.toIso8601String(),
      'billText': billText,
      'qrData': qrData,
    };
  }

  factory BillRecord.fromMap(Map<String, dynamic> map) {
    return BillRecord(
      billNo: map['billNo'],
      customerName: map['customerName'],
      phone: map['phone'],
      total: map['total'],
      date: DateTime.parse(map['date']),
      billText: map['billText'],
      qrData: map['qrData'] ?? '',
    );
  }
}

class BillingPage extends StatefulWidget {
  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final billNoCtrl = TextEditingController();
  final searchCtrl = TextEditingController();
  String searchQuery = '';

  final productNameCtrl = TextEditingController();
  final productDescCtrl = TextEditingController();
  final productPriceCtrl = TextEditingController();
  final productStockCtrl = TextEditingController();

  List<Product> products = [
    Product(name: 'Minikate Rice', description: '1 kg', price: 70.0, stock: 100),
    Product(name: 'Lentils', description: '1 kg', price: 120.0, stock: 100),
    Product(name: 'Sugar', description: '1 kg', price: 130.0, stock: 100),
    Product(name: 'Salt', description: '1 packet', price: 20.0, stock: 100),
    Product(name: 'Soybean Oil', description: '1 Litter', price: 200.0, stock: 100),
    Product(name: 'Egg', description: '1 Hali', price: 40.0, stock: 120),
    Product(name: 'Noodles', description: '1 Packet', price: 40.0, stock: 100),
    Product(name: 'Mineral Water', description: '1 Bottle', price: 20.0, stock: 500),
    Product(name: 'Coffee', description: '250g', price: 250.0, stock: 100),
    Product(name: 'Shampoo', description: 'Packet', price: 200.0, stock: 100),
    Product(name: 'PRAN Kulfi Milk Drink', description: '200ml', price: 30.0, stock: 200),
    Product(name: 'Chicken Patties', description: '1 pic', price: 70.0, stock: 50),
    Product(name: 'Onion', description: '1 kg', price: 90.0, stock: 100),
    Product(name: 'Sos', description: 'Full Packet', price: 140.0, stock: 100),
    Product(name: 'Pasta', description: 'Siq Bag', price: 200.0, stock: 80),
  ];

  List<ProductHistory> productHistory = [];
  List<BillRecord> billHistory = [];
  int billNumber = 1;

  String billText = '';
  double total = 0;
  int? editingIndex;

  @override
  void initState() {
    super.initState();
    loadBillHistory();
    loadProductHistory();
    searchCtrl.addListener(() {
      setState(() {
        searchQuery = searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadBillHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/billing_history.json');
      if (await historyFile.exists()) {
        final historyData = jsonDecode(await historyFile.readAsString());
        setState(() {
          billHistory = (historyData as List)
              .map((item) => BillRecord.fromMap(item))
              .toList();
          if (billHistory.isNotEmpty) {
            int maxBillNo = billHistory
                .map((bill) => int.tryParse(bill.billNo) ?? 0)
                .reduce((a, b) => a > b ? a : b);
            billNumber = maxBillNo + 1;
          }
        });
      }
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  Future<void> loadProductHistory() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final historyFile = File('${dir.path}/product_history.json');
      if (await historyFile.exists()) {
        final historyData = jsonDecode(await historyFile.readAsString());
        setState(() {
          productHistory = (historyData as List)
              .map((item) => ProductHistory.fromMap(item))
              .toList();
        });
      }
    } catch (e) {
      print("Error loading product history: $e");
    }
  }

  Future<void> saveProductHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    final historyFile = File('${dir.path}/product_history.json');
    final historyData = productHistory.map((history) => history.toMap()).toList();
    await historyFile.writeAsString(jsonEncode(historyData));
  }

  void addToProductHistory({
    required String action,
    Product? oldProduct,
    Product? newProduct,
  }) {
    setState(() {
      productHistory.insert(0, ProductHistory(
        timestamp: DateTime.now(),
        action: action,
        oldProduct: oldProduct,
        newProduct: newProduct,
      ));
    });
    saveProductHistory();
  }

  List<Product> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((product) {
      return product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  void handleQuantityChange(int index, int newQty) {
    final product = filteredProducts[index];
    final originalIndex = products.indexWhere((p) => p.name == product.name);

    if (newQty < 0) return;

    int diff = newQty - product.quantity;

    if (diff > 0 && product.stock >= diff) {
      product.stock -= diff;
      product.quantity = newQty;
      products[originalIndex] = product;
    } else if (diff < 0) {
      product.stock += -diff;
      product.quantity = newQty;
      products[originalIndex] = product;
    } else if (diff > 0 && product.stock < diff) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Out of Stock')),
      );
      return;
    }

    setState(() {});
  }

  void generateBill() {
    if (phoneCtrl.text.length != 11 || !phoneCtrl.text.startsWith('01')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid 11-digit phone number starting with 01')),
      );
      return;
    }

    if (nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter customer name')),
      );
      return;
    }

    total = 0;
    StringBuffer buffer = StringBuffer();

    String currentBillNo = billNumber.toString().padLeft(4, '0');

    buffer.writeln("===========================");
    buffer.writeln("       WELCOME TO RAFSAN STORE       ");
    buffer.writeln("===========================");
    buffer.writeln("               Bill No: $currentBillNo");
    buffer.writeln("               Customer: ${nameCtrl.text}");
    buffer.writeln("               Phone: ${phoneCtrl.text}");
    buffer.writeln("               Date: ${DateTime.now().toString().substring(0, 16)}");
    buffer.writeln("----------------------------------------------");

    for (var product in products) {
      if (product.quantity > 0) {
        double productTotal = product.price * product.quantity;
        total += productTotal;

        buffer.writeln("               Product: ${product.name}");
        buffer.writeln("               Qty: ${product.quantity} x ${product.price.toStringAsFixed(2)}");
        buffer.writeln("               Total: ${productTotal.toStringAsFixed(2)}");
        buffer.writeln("-----------------------------------------------");
      }
    }

    buffer.writeln("               TOTAL: ${total.toStringAsFixed(2)} BDT");
    buffer.writeln("============================");
    buffer.writeln("        THANK YOU, COME AGAIN!       ");
    buffer.writeln("============================");
    String qrData = '''
Bill No: $currentBillNo
Customer: ${nameCtrl.text}
Phone: ${phoneCtrl.text}
Date: ${DateTime.now().toString().substring(0, 16)}
Total: ${total.toStringAsFixed(2)} BDT
''';

    setState(() {
      billText = buffer.toString();
      billHistory.insert(0, BillRecord(
        billNo: currentBillNo,
        customerName: nameCtrl.text,
        phone: phoneCtrl.text,
        total: total,
        date: DateTime.now(),
        billText: billText,
        qrData: qrData,
      ));
      billNumber++;
      if (billNumber > 1000) billNumber = 1;
    });
  }

  void clearFields() {
    nameCtrl.clear();
    phoneCtrl.clear();
    billNoCtrl.clear();
    setState(() {
      for (var product in products) {
        product.quantity = 0;
      }
      billText = '';
      total = 0;
    });
  }

  Future<void> saveToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Bill_${billNumber.toString().padLeft(4, '0')}.txt');
    await file.writeAsString(billText);

    final historyFile = File('${dir.path}/billing_history.json');
    final historyData = billHistory.map((bill) => bill.toMap()).toList();
    await historyFile.writeAsString(jsonEncode(historyData));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bill saved to ${file.path}')),
    );
  }

  Future<void> printBill() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Text(billText, style: pw.TextStyle(font: pw.Font.courier(), fontSize: 12));
    }));
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> exportToExcel() async {
    if (billHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No bills in history to export')),
      );
      return;
    }

    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['Bills'];

      sheet.appendRow([
        'Bill No',
        'Customer Name',
        'Phone',
        'Date',
        'Total (BDT)',
        'Bill Details'
      ]);

      for (final bill in billHistory) {
        sheet.appendRow([
          bill.billNo,
          bill.customerName,
          bill.phone,
          bill.date.toString().substring(0, 16),
          bill.total.toStringAsFixed(2),
          bill.billText.replaceAll('\n', ' | ')
        ]);
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/bill_history_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to Excel: $e')),
      );
    }
  }

  Future<void> exportSingleBillToExcel(BillRecord bill) async {
    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['Bill ${bill.billNo}'];

      sheet.appendRow(['Bill Details']);

      for (var line in bill.billText.split('\n')) {
        sheet.appendRow([line]);
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/bill_${bill.billNo}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to Excel: $e')),
      );
    }
  }

  Future<void> exportProductHistoryToExcel() async {
    try {
      final excel = ex.Excel.createExcel();
      final sheet = excel['Product History'];

      sheet.appendRow([
        'Timestamp',
        'Action',
        'Product Name',
        'Old Price',
        'New Price',
        'Old Stock',
        'New Stock',
        'Changed By'
      ]);

      for (final history in productHistory) {
        sheet.appendRow([
          history.timestamp.toString().substring(0, 16),
          history.action,
          history.action == 'add' ? history.newProduct?.name :
          history.action == 'delete' ? history.oldProduct?.name :
          history.newProduct?.name,
          history.oldProduct?.price.toStringAsFixed(2),
          history.newProduct?.price.toStringAsFixed(2),
          history.oldProduct?.stock.toString(),
          history.newProduct?.stock.toString(),
          history.changedBy,
        ]);
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/product_history_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Excel: $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting to Excel: $e')),
      );
    }
  }

  void showAddEditProductDialog() {
    if (editingIndex != null) {
      productNameCtrl.text = products[editingIndex!].name;
      productDescCtrl.text = products[editingIndex!].description;
      productPriceCtrl.text = products[editingIndex!].price.toString();
      productStockCtrl.text = products[editingIndex!].stock.toString();
    } else {
      productNameCtrl.clear();
      productDescCtrl.clear();
      productPriceCtrl.clear();
      productStockCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingIndex != null ? 'Edit Product' : 'Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: productNameCtrl, decoration: InputDecoration(labelText: 'Product Name')),
            TextField(controller: productDescCtrl, decoration: InputDecoration(labelText: 'Description')),
            TextField(
              controller: productPriceCtrl,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: productStockCtrl,
              decoration: InputDecoration(labelText: 'Stock'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              editingIndex = null;
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (productNameCtrl.text.isNotEmpty &&
                  productPriceCtrl.text.isNotEmpty &&
                  productStockCtrl.text.isNotEmpty) {
                setState(() {
                  if (editingIndex != null) {
                    final oldProduct = products[editingIndex!];
                    final updatedProduct = Product(
                      name: productNameCtrl.text,
                      description: productDescCtrl.text,
                      price: double.parse(productPriceCtrl.text),
                      quantity: oldProduct.quantity,
                      stock: int.parse(productStockCtrl.text),
                    );
                    addToProductHistory(
                      action: 'edit',
                      oldProduct: oldProduct,
                      newProduct: updatedProduct,
                    );
                    products[editingIndex!] = updatedProduct;
                  } else {
                    final newProduct = Product(
                      name: productNameCtrl.text,
                      description: productDescCtrl.text,
                      price: double.parse(productPriceCtrl.text),
                      stock: int.parse(productStockCtrl.text),
                    );
                    addToProductHistory(
                      action: 'add',
                      newProduct: newProduct,
                    );
                    products.add(newProduct);
                  }
                  editingIndex = null;
                });
                Navigator.pop(context);
              }
            },
            child: Text(editingIndex != null ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void deleteProduct(int index) {
    final deletedProduct = products[index];
    addToProductHistory(
      action: 'delete',
      oldProduct: deletedProduct,
    );
    setState(() {
      products.removeAt(index);
    });
  }

  void showBillHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bill History"),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (billHistory.isEmpty)
                Text("No bills in history")
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: billHistory.length,
                    itemBuilder: (context, index) {
                      final bill = billHistory[index];
                      return Card(
                        child: ListTile(
                          title: Text("Bill #${bill.billNo}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bill.customerName),
                              Text("${bill.date.toString().substring(0, 16)}"),
                              Text("Total: ${bill.total.toStringAsFixed(2)} BDT"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () {
                              Navigator.pop(context);
                              showBillDetails(bill);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (billHistory.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                exportToExcel();
              },
              child: Text("Export All to Excel"),
            ),
        ],
      ),
    );
  }

  void showProductHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Product Change History"),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (productHistory.isEmpty)
                Text("No product changes recorded")
              else
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: productHistory.length,
                    itemBuilder: (context, index) {
                      final history = productHistory[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            "${history.action.toUpperCase()} - ${history.timestamp.toString().substring(0, 16)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (history.action == 'edit')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Old: ${history.oldProduct?.name} (${history.oldProduct?.price} BDT, Stock: ${history.oldProduct?.stock})"),
                                    Text("New: ${history.newProduct?.name} (${history.newProduct?.price} BDT, Stock: ${history.newProduct?.stock})"),
                                  ],
                                ),
                              if (history.action == 'add')
                                Text("Added: ${history.newProduct?.name} (${history.newProduct?.price} BDT, Stock: ${history.newProduct?.stock})"),
                              if (history.action == 'delete')
                                Text("Deleted: ${history.oldProduct?.name}"),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          if (productHistory.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                exportProductHistoryToExcel();
              },
              child: Text("Export to Excel"),
            ),
        ],
      ),
    );
  }

  void showBillDetails(BillRecord bill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Bill #${bill.billNo}"),
        content: SingleChildScrollView(child: Text(bill.billText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: bill.billText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Bill copied to clipboard")),
              );
            },
            child: Text("Copy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              exportSingleBillToExcel(bill);
            },
            child: Text("Export to Excel"),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About BillLagbe"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Version: 1.0.0", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("How to use this app:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("1. Enter customer details (Name & Phone)"),
              Text("2. Select products from the list"),
              Text("3. Set quantities using +/- buttons"),
              Text("4. Click Generate Bill to create invoice"),
              Text("5. Save/Print the bill for records"),
              SizedBox(height: 10),
              Text("Features:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("- Product management (Add/Edit/Delete)"),
              Text("- Bill history tracking"),
              Text("- Product change history"),
              Text("- Export to Excel/PDF"),
              Text("- Direct printing support"),
              SizedBox(height: 10),
              Text("Developed for small businesses", style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPortfolio() async {
    const url = 'https://rafsan-theta.vercel.app/';
    try {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        await Process.run('start', [url], runInShell: true);
      } else if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeveloperDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Developer Information"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Developed By:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("MD.RAFSAN ZANI",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white),),
              Text("(Junior App Developer at Softnextit)",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 12,color: Colors.white),),
              Text("Email: rafsanzanirizon539@gmail.com"),
              Text("Phone: +8801308078535"),
              SizedBox(height: 10),
              Text("Portfolio:", style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _launchPortfolio,
                child: Text(
                  'View My Portfolio',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text("Technology Used:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Flutter Framework"),
              Text("Dart Programming Language"),
              Text("Firebase"),
              Text("Local Database"),
              SizedBox(height: 10),
              Text("All rights reserved © ${DateTime.now().year}"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bill Lagbe", style: TextStyle(fontWeight: FontWeight.bold,fontStyle: FontStyle.italic,)),
        actions: [
          IconButton(icon: Icon(Icons.history), onPressed: showBillHistory),
          IconButton(icon: Icon(Icons.inventory), onPressed: showProductHistory),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              editingIndex = null;
              showAddEditProductDialog();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'about') {
                _showAboutDialog();
              } else if (value == 'developer') {
                _showDeveloperDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'developer',
                child: Row(
                  children: [
                    Icon(Icons.code, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Developer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Customer Name", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 5),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone Number", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 5),
                    TextField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '01XXXXXXXXX',
                        counterText: '${phoneCtrl.text.length}/11',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 11,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bill No", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 5),
                    TextField(
                      controller: TextEditingController(text: billNumber.toString().padLeft(4, '0')),
                      readOnly: true,
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      children: [
                        Text("Product List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 10),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              children: [
                                Text("Select Your Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(height: 10),
                                Table(
                                  border: TableBorder.all(),
                                  columnWidths: const {
                                    0: FlexColumnWidth(3),
                                    1: FlexColumnWidth(1),
                                    2: FlexColumnWidth(1),
                                    3: FlexColumnWidth(1),
                                    4: FlexColumnWidth(1),
                                    5: FlexColumnWidth(0.5),
                                  },
                                  children: [
                                    TableRow(
                                      children: [
                                        Padding(padding: EdgeInsets.all(8), child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                        Padding(padding: EdgeInsets.all(8), child: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                                      ],
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: filteredProducts.length,
                                    itemBuilder: (context, index) {
                                      final product = filteredProducts[index];
                                      return Table(
                                        border: TableBorder.all(),
                                        columnWidths: const {
                                          0: FlexColumnWidth(3),
                                          1: FlexColumnWidth(1),
                                          2: FlexColumnWidth(1),
                                          3: FlexColumnWidth(1),
                                          4: FlexColumnWidth(1),
                                          5: FlexColumnWidth(0.5),
                                        },
                                        children: [
                                          TableRow(
                                            children: [
                                              Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(product.name, style: TextStyle(color: Colors.white)),
                                                    Text(product.description, style: TextStyle(fontSize: 12, color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(padding: EdgeInsets.all(8), child: Text(product.price.toStringAsFixed(2), style: TextStyle(color: Colors.white))),
                                              Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.remove, color: Colors.white),
                                                      onPressed: product.quantity > 0
                                                          ? () => handleQuantityChange(index, product.quantity - 1)
                                                          : null,
                                                    ),
                                                    Text(product.quantity.toString(), style: TextStyle(color: Colors.white)),
                                                    IconButton(
                                                      icon: Icon(Icons.add, color: Colors.white),
                                                      onPressed: () => handleQuantityChange(index, product.quantity + 1),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(padding: EdgeInsets.all(8), child: Text((product.price * product.quantity).toStringAsFixed(2), style: TextStyle(color: Colors.white))),
                                              Padding(padding: EdgeInsets.all(8), child: Text(product.stock.toString(), style: TextStyle(color: Colors.white))),
                                              Padding(
                                                padding: EdgeInsets.all(8),
                                                child: PopupMenuButton(
                                                  itemBuilder: (context) => [
                                                    PopupMenuItem(child: Text('Edit'), value: 'edit'),
                                                    PopupMenuItem(child: Text('Delete'), value: 'delete'),
                                                  ],
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      editingIndex = products.indexWhere((p) => p.name == product.name);
                                                      showAddEditProductDialog();
                                                    } else if (value == 'delete') {
                                                      deleteProduct(products.indexWhere((p) => p.name == product.name));
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bill Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Text(billText, style: TextStyle(fontFamily: 'Courier', fontSize: 14, color: Colors.white)),
                                if (billText.isNotEmpty) // Show QR code only when there's a bill
                                  Column(
                                    children: [
                                      SizedBox(height: 20),
                                      Text("Scan for digital receipt", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      SizedBox(height: 10),
                                      Center(
                                        child: QrImageView(
                                          data: billHistory.isNotEmpty ? billHistory.first.qrData : '',
                                          version: QrVersions.auto,
                                          size: 120.0,
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text("Total: ${total.toStringAsFixed(2)} BDT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: generateBill,
                child: Text("Generate Bill"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              ),
              ElevatedButton(
                onPressed: clearFields,
                child: Text("Clear"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              ElevatedButton(
                onPressed: () => exit(0),
                child: Text("Exit"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton(
                onPressed: saveToFile,
                child: Text("Save Bill"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              ElevatedButton(
                onPressed: printBill,
                child: Text("Print Bill"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}