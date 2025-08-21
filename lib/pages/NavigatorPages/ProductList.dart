import 'package:flutter/material.dart';
import 'package:flutter_user/functions/functions.dart';
import 'package:shimmer/shimmer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> productList = [];
  bool isLoading = true;
  int? processingProductId;

  Future<void> fetchProductList() async {
    setState(() => isLoading = true);
    final result = await getProductList();
    setState(() {
      isLoading = false;
      if (result['status'] == 'success') {
        productList = List<Map<String, dynamic>>.from(result['data']);
      } else {
        productList = [];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    fetchProductList();
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 200, color: Colors.white),
                const SizedBox(height: 10),
                Container(height: 16, width: 150, color: Colors.white),
                const SizedBox(height: 20),
                Container(height: 40, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    bool isProcessing = processingProductId == product['id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  product['product_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${product['price']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Validity: ${product['validity_days']} days',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                  setState(() => processingProductId = product['id']);

                  final result = await buyProduct(
                    roleId: 1,
                    userId: userDetails['id'].toString(),
                    productId: product['id'],
                  );

                  setState(() => processingProductId = null);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Something went wrong'),
                      backgroundColor: result['status'] == 'success' ? Colors.green : Colors.red,
                    ),
                  );

                  if (result['status'] == 'success') {
                    fetchProductList();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                child: isProcessing
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text(
                  'Purchase',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
        ),
        title: const Text(
          "Subscription List",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildShimmerLoader()
          : productList.isEmpty
          ? const Center(child: Text('No subscription available'))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        itemCount: productList.length,
        itemBuilder: (context, index) => _buildProductItem(productList[index]),
      ),
    );
  }
}
