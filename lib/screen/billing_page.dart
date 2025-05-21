import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;

class BillingPage extends StatefulWidget {
  @override
  _BillingPageState createState() => _BillingPageState();
}

class _BillingPageState extends State<BillingPage> {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final billNoCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  // Controllers for adding/editing products
  final productNameCtrl = TextEditingController();
  final productDescCtrl = TextEditingController();
  final productPriceCtrl = TextEditingController();

  List<Map<String, dynamic>> products = [
    {
      'name': 'Minikate Rice',
      'description': '1 kg',
      'price': 70.0,
      'quantity': 0,
    },
    {
      'name': 'Lentils',
      'description': '1 kg',
      'price': 120.0,
      'quantity': 0,
    },
    {
      'name': 'Sugar',
      'description': '1 kg',
      'price': 130.0,
      'quantity': 0,
    },
    {
      'name': 'Salt',
      'description': '1 packet',
      'price': 20.0,
      'quantity': 0,
    },
    {
      'name': 'Soybean Oil',
      'description': '1 Litter',
      'price': 200.0,
      'quantity': 0,
    },
    {
      'name': 'Egg',
      'description': '1 Hali ',
      'price': 40.0,
      'quantity': 0,
    },
    {
      'name': 'Noodles',
      'description': '1 Packet',
      'price': 40.0,
      'quantity': 0,
    },
    {
      'name': 'Mineral Water',
      'description': '1 Botol',
      'price': 20.0,
      'quantity': 0,
    },
    {
      'name': 'Coffee ',
      'description': '250g',
      'price': 250.0,
      'quantity': 0,
    },
    {
      'name': 'Shampoo',
      'description': 'Packet',
      'price': 200.0,
      'quantity': 0,
    },
    {
      'name': 'PRAN Kulfi Milk Drink ',
      'description': '200ml',
      'price': 30.0,
      'quantity': 0,
    },
    {
      'name': 'PRAN UP ',
      'description': '250ml',
      'price': 20.0,
      'quantity': 0,
    },
    {
      'name': 'Chicken Patties',
      'description': '1 pic',
      'price': 70.0,
      'quantity': 0,
    },
    {
      'name': 'Onion',
      'description': '1 kg',
      'price': 90.0,
      'quantity': 0,
    },
    {
      'name': ' Lexus Vegetable Biscuit',
      'description': '1 Packet',
      'price': 100.0,
      'quantity': 0,
    },
    {
      'name': 'Fit Biscuit',
      'description': '1 Packet',
      'price': 20.0,
      'quantity': 0,
    },
    {
      'name': 'Muri',
      'description': '1 kg',
      'price': 80.0,
      'quantity': 0,
    },
    {
      'name': 'Sos',
      'description': 'Full Packet',
      'price': 140.0,
      'quantity': 0,
    },
    {
      'name': 'Pasta',
      'description': 'Siq Bag',
      'price': 200.0,
      'quantity': 0,
    },
  ];

  String billText = '';
  double total = 0;
  int? editingIndex; // Track which product is being edited

  void updateQuantity(int index, int newQuantity) {
    setState(() {
      products[index]['quantity'] = newQuantity;
    });
  }

  void generateBill() {
    total = 0;
    StringBuffer buffer = StringBuffer();
    buffer.writeln("Welcome To Store's Retail");
    buffer.writeln("Bill No: ${billNoCtrl.text}");
    buffer.writeln("Customer: ${nameCtrl.text}");
    buffer.writeln("Phone: ${phoneCtrl.text}");
    buffer.writeln("=====================================");
    buffer.writeln("Product\t\tQty\tPrice\tTotal");
    buffer.writeln("-------------------------------------");

    for (var product in products) {
      int qty = product['quantity'];
      if (qty > 0) {
        double price = product['price'];
        double productTotal = price * qty;
        total += productTotal;
        buffer.writeln("${product['name']}\t$qty\t${price.toStringAsFixed(2)}\t${productTotal.toStringAsFixed(2)}");
      }
    }

    buffer.writeln("-------------------------------------");
    buffer.writeln("Total\t\t\t\t${total.toStringAsFixed(2)}");
    setState(() {
      billText = buffer.toString();
    });
  }

  void clearFields() {
    nameCtrl.clear();
    phoneCtrl.clear();
    billNoCtrl.clear();
    setState(() {
      for (var product in products) {
        product['quantity'] = 0;
      }
      billText = '';
      total = 0;
    });
  }

  Future<void> saveToFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Bill_${billNoCtrl.text}.txt');
    await file.writeAsString(billText);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bill saved to ${file.path}')),
    );
  }

  Future<void> printBill() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Text(
            billText,
            style: pw.TextStyle(
              font: pw.Font.courier(),
              fontSize: 12,
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void showAddEditProductDialog() {
    if (editingIndex != null) {
      // Editing existing product
      productNameCtrl.text = products[editingIndex!]['name'];
      productDescCtrl.text = products[editingIndex!]['description'];
      productPriceCtrl.text = products[editingIndex!]['price'].toString();
    } else {
      // Adding new product
      productNameCtrl.clear();
      productDescCtrl.clear();
      productPriceCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editingIndex != null ? 'Edit Product' : 'Add Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameCtrl,
              decoration: InputDecoration(labelText: 'Product Name'),
            ),
            TextField(
              controller: productDescCtrl,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: productPriceCtrl,
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                  productPriceCtrl.text.isNotEmpty) {
                setState(() {
                  if (editingIndex != null) {
                    // Update existing product
                    products[editingIndex!] = {
                      'name': productNameCtrl.text,
                      'description': productDescCtrl.text,
                      'price': double.parse(productPriceCtrl.text),
                      'quantity': products[editingIndex!]['quantity'],
                    };
                  } else {
                    // Add new product
                    products.add({
                      'name': productNameCtrl.text,
                      'description': productDescCtrl.text,
                      'price': double.parse(productPriceCtrl.text),
                      'quantity': 0,
                    });
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
    setState(() {
      products.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:Text("Grocery Billing System",style: TextStyle(fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              editingIndex = null;
              showAddEditProductDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          Row(children: [
            Expanded(child: buildField("Customer Name", nameCtrl)),
            SizedBox(width: 10),
            Expanded(child: buildField("Phone No", phoneCtrl)),
            SizedBox(width: 10),
            Expanded(child: buildField("Bill No", billNoCtrl)),
          ]),
          SizedBox(height: 10),
          TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
              counterStyle: TextStyle(color: Colors.white),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                // Implement search functionality if needed
              });
            },
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
                        Text(
                          "Product List",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                        ),
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
                                Text(
                                  "Select Your Products",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: Table(

                                      border: TableBorder.all(),
                                      columnWidths: const {
                                        0: FlexColumnWidth(3),
                                        1: FlexColumnWidth(1),
                                        2: FlexColumnWidth(1),
                                        3: FlexColumnWidth(1),
                                        4: FlexColumnWidth(0.5),
                                      },
                                      children: [
                                        TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Product',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Price',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Qty',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Total',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text('Edit',
                                                  style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                        ...products.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final product = entry.value;
                                          return TableRow(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(product['name']),
                                                    Text(product['description'],
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white)),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                    product['price'].toStringAsFixed(2)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.remove, color: Colors.white),
                                                      onPressed: () {
                                                        if (product['quantity'] > 0) {
                                                          updateQuantity(
                                                              index,
                                                              product['quantity'] - 1);
                                                        }
                                                      },
                                                    ),
                                                    Text(product['quantity'].toString()),
                                                    IconButton(
                                                      icon: Icon(Icons.add, color: Colors.white),
                                                      onPressed: () {
                                                        updateQuantity(
                                                            index,
                                                            product['quantity'] + 1);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text((product['price'] *
                                                    product['quantity'])
                                                    .toStringAsFixed(2)),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: PopupMenuButton(
                                                  itemBuilder: (context) => [
                                                    PopupMenuItem(
                                                      child: Text('Edit'),
                                                      value: 'edit',
                                                    ),
                                                    PopupMenuItem(
                                                      child: Text('Delete'),
                                                      value: 'delete',
                                                    ),
                                                  ],
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      editingIndex = index;
                                                      showAddEditProductDialog();
                                                    } else if (value == 'delete') {
                                                      deleteProduct(index);
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    ),
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
                        Text(
                          "Bill Summary",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              billText,
                              style: TextStyle(fontFamily: 'Courier', fontSize: 14,color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Total: ${total.toStringAsFixed(2)} BDT",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                        ),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent,),
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

  Widget buildField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        SizedBox(height: 5),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}