
// lib/screens/events/admin/ticket_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:gloryfit_version_3/service/event_service.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen> {
  final EventService _eventService = EventService();
  bool _isProcessing = false;

  void _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final String? code = capture.barcodes.first.rawValue;
    if (code == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final decoded = jsonDecode(code);
      final userId = decoded['userId'] as String?;
      final ticketId = decoded['ticketId'] as String?;

      if (userId == null || ticketId == null) throw const FormatException("Invalid QR code format.");

      final resultMessage = await _eventService.markTicketAsUsed(userId, ticketId);
      _showResultDialog(true, resultMessage);

    } catch (e) {
      _showResultDialog(false, e.toString());
    }
  }
  
  void _showResultDialog(bool isSuccess, String message){
      showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red, size: 50),
          content: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
                setState(() => _isProcessing = false); // Allow scanning again
              }, 
              child: const Text("OK")
            )
          ],
        )
      );
  }

  @override
  Widget build(BuildContext context) {
    if(kIsWeb) {
      return const Scaffold(body: Center(child: Text("QR Scanner is not available on Web.")));
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Event Ticket")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _handleDetection,
          ),
          // Scanner Overlay
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(12)
            ),
          ),
           if(_isProcessing) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}