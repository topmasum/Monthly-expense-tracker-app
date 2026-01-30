import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer = TextRecognizer();

  Future<Map<String, dynamic>> scanReceipt() async {
    // 1. Pick Image
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return {};

    // 2. Process Image with ML Kit
    final inputImage = InputImage.fromFile(File(image.path));
    final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

    // 3. Extract Data (The "Smart" Part)
    String text = recognizedText.text;
    double? amount = _findTotalAmount(text);
    DateTime? date = _findDate(text);

    return {
      'amount': amount,
      'date': date,
      'text': text, // Debugging aid
    };
  }

  // --- HEURISTICS: FIND THE TOTAL AMOUNT ---
  double? _findTotalAmount(String text) {
    // Regex to find prices like 120.50, 1,200.00, $50.00
    // It looks for numbers that might have commas and decimals
    final RegExp priceRegex = RegExp(r'[\d,]+\.\d{2}');

    List<double> prices = [];

    // Split text into lines to process line-by-line
    for (String line in text.split('\n')) {
      // Clean the line (remove currency symbols like $, ৳)
      String cleanLine = line.replaceAll(RegExp(r'[^\d.,]'), '');

      // Try to find a match
      Iterable<Match> matches = priceRegex.allMatches(cleanLine);
      for (Match match in matches) {
        String numStr = match.group(0)!.replaceAll(',', ''); // Remove commas
        double? val = double.tryParse(numStr);
        if (val != null) prices.add(val);
      }
    }

    if (prices.isEmpty) return null;

    // Logic: The "Total" is usually the highest number on the receipt
    prices.sort();
    return prices.last;
  }

  // --- HEURISTICS: FIND THE DATE ---
  DateTime? _findDate(String text) {
    // Regex for DD/MM/YYYY or YYYY-MM-DD
    final RegExp dateRegex = RegExp(r'\d{2,4}[-/]\d{2}[-/]\d{2,4}');

    final match = dateRegex.firstMatch(text);
    if (match != null) {
      String dateStr = match.group(0)!;
      try {
        // Try parsing different formats
        // You might need to add more formats depending on your region's receipts
        if (dateStr.contains('/')) {
          // Assume DD/MM/YYYY
          return DateFormat("dd/MM/yyyy").parse(dateStr);
        } else {
          // Assume YYYY-MM-DD
          return DateTime.parse(dateStr);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void dispose() {
    _recognizer.close();
  }
}