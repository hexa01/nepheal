import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/models/payment.dart';
import '../widgets/patient_dashboard_with_tab.dart';

class PaymentScreen extends StatefulWidget {
  final int appointmentId;
  final double amount;
  final String doctorName;
  final String appointmentDate;
  final String appointmentSlot;

  const PaymentScreen({
    super.key,
    required this.appointmentId,
    required this.amount,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentSlot,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _error;
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedMethod;
  bool _isLoadingMethods = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoadingMethods = true;
      _error = null;
    });

    final methods = [
      PaymentMethod(
        id: 'esewa',
        name: 'eSewa',
        available: true,
        logo: 'esewa_logo.png',
      ),
      PaymentMethod(
        id: 'khalti',
        name: 'Khalti',
        available: false,
        logo: 'khalti_logo.png',
      ),
      PaymentMethod(
        id: 'card',
        name: 'Card Payment',
        available: false,
        logo: 'card_logo.png',
      ),
    ];

    setState(() {
      _paymentMethods = methods;
      // Auto-select eSewa if available
      _selectedMethod = _paymentMethods.firstWhere(
        (method) => method.available,
        orElse: () => _paymentMethods.isNotEmpty
            ? _paymentMethods.first
            : PaymentMethod(
                id: 'none',
                name: 'No methods available',
                available: false,
                logo: '',
              ),
      );
      _isLoadingMethods = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingMethods
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildPaymentContent(),
      bottomNavigationBar:
          _isLoadingMethods || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPaymentMethods,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Appointment Summary Card
          _buildAppointmentSummary(),
          const SizedBox(height: 24),

          // Payment Methods Section
          const Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Payment Methods List
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),

          const SizedBox(height: 24),

          // Payment Summary
          _buildPaymentSummary(),
        ],
      ),
    );
  }

  Widget _buildAppointmentSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Doctor', widget.doctorName),
            _buildDetailRow('Date', _formatDate(widget.appointmentDate)),
            _buildDetailRow('Time', _formatTime(widget.appointmentSlot)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs. ${widget.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedMethod?.id == method.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: method.available
            ? () => setState(() => _selectedMethod = method)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getMethodColor(method.id).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getMethodIcon(method.id),
                  color: _getMethodColor(method.id),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: method.available ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.available ? 'Available' : 'Coming Soon',
                      style: TextStyle(
                        fontSize: 12,
                        color: method.available ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (method.available)
                Radio<PaymentMethod>(
                  value: method,
                  groupValue: _selectedMethod,
                  onChanged: (value) => setState(() => _selectedMethod = value),
                  activeColor: Colors.blue.shade600,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Consultation Fee', 'Rs. ${widget.amount.toStringAsFixed(0)}'),
            _buildSummaryRow('Service Charge', 'Rs. 0'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              'Rs. ${widget.amount.toStringAsFixed(0)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedMethod?.available == true && !_isLoading
                ? _processPayment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay Rs. ${widget.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedMethod?.id == 'esewa') {
      await _handleEsewaPayment();
    } else {
      setState(() {
        _error = 'Payment method not supported yet';
      });
    }
  }

  Future<void> _handleEsewaPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First initiate payment to get payment ID
      final initiateResponse = await ApiService.initiatePayment(
        appointmentId: widget.appointmentId,
        paymentMethod: 'esewa',
      );

      if (initiateResponse['success']) {
        final paymentId = initiateResponse['data']['payment_id'];

        // Get eSewa HTML content
        final htmlContent =
            await ApiService.initiateEsewaPayment(paymentId: paymentId);

        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => EsewaWebViewScreen(
                htmlContent: htmlContent,
                paymentId: paymentId,
              ),
            ),
          );

          // Handle payment result
          if (result == true) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const PatientDashboardWithTab(
                      initialTab: 2), // 👈 open Appointments tab
                ),
                (route) => false,
              );
            }
          } else {
            // Payment failed or cancelled
            setState(() {
              _error = 'Payment failed or was cancelled';
            });
          }
        }
      } else {
        setState(() {
          _error = initiateResponse['message'] ?? 'Failed to initiate payment';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getMethodColor(String methodId) {
    switch (methodId) {
      case 'esewa':
        return Colors.green;
      case 'khalti':
        return Colors.purple;
      case 'card':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMethodIcon(String methodId) {
    switch (methodId) {
      case 'esewa':
        return Icons.account_balance_wallet;
      case 'khalti':
        return Icons.wallet;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String time24) {
    try {
      String timeStr = time24.trim();
      if (timeStr.contains(':') && timeStr.split(':').length == 3) {
        final parts = timeStr.split(':');
        timeStr = '${parts[0]}:${parts[1]}';
      }
      final time = DateFormat('HH:mm').parse(timeStr);
      return DateFormat('h:mm a').format(time);
    } catch (e) {
      return time24;
    }
  }
}

class EsewaWebViewScreen extends StatefulWidget {
  final String htmlContent;
  final int paymentId;

  const EsewaWebViewScreen({
    super.key,
    required this.htmlContent,
    required this.paymentId,
  });

  @override
  State<EsewaWebViewScreen> createState() => _EsewaWebViewScreenState();
}

class _EsewaWebViewScreenState extends State<EsewaWebViewScreen> {
  late final WebViewController controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) async {
            setState(() {
              _isLoading = false;
            });

            if (url.contains('esewa/success')) {
              Navigator.of(context).pop(true);
              return;
            } else if (url.contains('esewa/failure')) {
              Navigator.of(context).pop(false);
              return;
            }

            // 🟨 Fallback: Check if raw JSON page loaded
            try {
              final rawText = await controller
                  .runJavaScriptReturningResult("document.body.innerText");

              final text = rawText.toString();
              if (text.contains('"success":true')) {
                Navigator.of(context).pop(true);
              } else if (text.contains('"success":false')) {
                Navigator.of(context).pop(false);
              }
            } catch (e) {
              // optional: log or ignore
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Handle eSewa success/failure URLs
            if (request.url.contains('payment/success')) {
              // Payment successful - pop with true
              Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            } else if (request.url.contains('payment/failure')) {
              // Payment failed - pop with false
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSewa Payment'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
