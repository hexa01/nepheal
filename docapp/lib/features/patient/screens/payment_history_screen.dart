import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/api_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _paidPayments = []; // Store as Map like v12

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getPayments();

      if (!mounted) return;

      if (response['success']) {
        final paymentsData = response['data'] as List<dynamic>? ?? [];
        
        // ✅ Filter to only include paid payments using the v12 logic
        final allPayments = paymentsData
            .map((data) => Map<String, dynamic>.from(data))
            .toList();
        
        // Filter for only paid payments
        final paidOnly = allPayments.where((payment) {
          final status = payment['status'] ?? '';
          return status == 'paid';
        }).toList();
        
        setState(() {
          _paidPayments = paidOnly;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load payments';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection error. Please check your internet connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : _error != null
                ? _buildErrorState()
                : _paidPayments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentsList(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPayments,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Payments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment history will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsList() {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: Colors.green,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _paidPayments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard();
          } else {
            final payment = _paidPayments[index - 1];
            return _buildCompactPaymentCard(payment);
          }
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalAmount = _paidPayments.fold<double>(
      0,
      (sum, payment) => sum + ((payment['amount'] as num?)?.toDouble() ?? 0),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet, 
                       color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total Paid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rs. ${totalAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_paidPayments.length} payment${_paidPayments.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPaymentCard(Map<String, dynamic> payment) {
    try {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
      final paymentMethod = payment['payment_method'] ?? 'Payment Method';
      final updatedAt = payment['updated_at'];

      // Get appointment info if available
      final appointment = payment['appointment'] as Map<String, dynamic>?;
      
      String? doctorName;
      String? doctorSpecialization;
      
      if (appointment != null) {
        final doctor = appointment['doctor'] as Map<String, dynamic>?;
        
        if (doctor != null) {
          doctorName = doctor['name']?.toString();
          
          // ✅ FIXED: Extract specialization name from the object
          final specializationObj = doctor['specialization'] as Map<String, dynamic>?;
          if (specializationObj != null) {
            doctorSpecialization = specializationObj['name']?.toString();
          }
        }
      }

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Payment Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Payment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs. ${amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PAID',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Doctor or Appointment Info
                    if (doctorName != null && doctorName.isNotEmpty)
                      Text(
                        'Dr. $doctorName${doctorSpecialization != null ? ' • $doctorSpecialization' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        'Appointment #${payment['appointment_id'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    
                    const SizedBox(height: 2),
                    
                    // Payment Method and Date
                    Row(
                      children: [
                        Icon(Icons.payment, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          paymentMethod.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (updatedAt != null) ...[
                          Text(
                            ' • ${_formatDate(updatedAt.toString())}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Error loading payment: $e',
            style: TextStyle(color: Colors.red.shade600),
          ),
        ),
      );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }


  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDateOnly(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}