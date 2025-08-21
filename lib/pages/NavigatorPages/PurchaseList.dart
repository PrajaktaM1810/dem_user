import 'package:flutter/material.dart';
import 'package:flutter_user/functions/functions.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<Map<String, dynamic>> purchaseHistory = [];
  bool isLoading = true;

  Future<void> fetchPurchaseHistory() async {
    setState(() => isLoading = true);
    final result = await getProductPurchaseHistory(
      roleId: 1,
      userId: userDetails['id'],
      // userId: 1,
    );
    setState(() {
      isLoading = false;
      if (result['status'] == 'success') {
        purchaseHistory = List<Map<String, dynamic>>.from(result['data']);
      } else {
        purchaseHistory = [];
      }
    });
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    return [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][month - 1];
  }

  @override
  void initState() {
    super.initState();
    fetchPurchaseHistory();
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_bag, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        history['product_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${history['amount']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  history['status'] == 'active' ? Icons.check_circle : Icons.cancel,
                  color: history['status'] == 'active' ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(history['start_date'])} - ${_formatDate(history['end_date'])}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
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
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
        ),
        title: const Text(
          "Subscription History",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
          : purchaseHistory.isEmpty
          ? const Center(child: Text('No subscription history available'))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 16),
        itemCount: purchaseHistory.length,
        itemBuilder: (context, index) => _buildHistoryItem(purchaseHistory[index]),
      ),
    );
  }
}