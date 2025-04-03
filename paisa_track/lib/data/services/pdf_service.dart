import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/date_utils.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  
  PdfService._internal();
  
  /// Generates a PDF document for a single transaction's details
  Future<Uint8List> generateTransactionDetailsPdf({
    required TransactionModel transaction,
    required CategoryModel category,
    required AccountModel account,
    AccountModel? destinationAccount,
    required String currencySymbol,
    String? originalCurrency,
    double? originalAmount,
  }) async {
    final pdf = pw.Document();
    
    // Load logo image if available
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/app_icon.png');
      final Uint8List bytes = data.buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
    } catch (e) {
      // Logo not available, continue without it
      print('Logo image not available: $e');
    }
    
    // Determine transaction type and colors
    final isIncome = transaction.type.name == 'income';
    final isExpense = transaction.type.name == 'expense';
    final isTransfer = transaction.type.name == 'transfer';
    
    // Create colors for different transaction types
    PdfColor typeColor;
    PdfColor lightBgColor;
    
    if (isIncome) {
      typeColor = PdfColors.green700;
      lightBgColor = PdfColors.green50;
    } else if (isExpense) {
      typeColor = PdfColors.red700;
      lightBgColor = PdfColors.red50;
    } else {
      typeColor = PdfColors.blue700;
      lightBgColor = PdfColors.blue50;
    }
    
    // Format the amount with proper currency
    final amountStr = transaction.amount.toStringAsFixed(2);
    
    // Create PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Header with brand colors and logo
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: lightBgColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Transaction Details',
                            style: const pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            DateFormat('MMMM dd, yyyy').format(transaction.date),
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          if (logoImage != null) ...[
                            pw.Container(
                              height: 40,
                              width: 40,
                              child: pw.Image(logoImage),
                            ),
                            pw.SizedBox(width: 10),
                          ],
                          pw.Text(
                            'Paisa Track',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Transaction amount & type - improved design
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Transaction type badge
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: pw.BoxDecoration(
                          color: lightBgColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(30)),
                        ),
                        child: pw.Text(
                          transaction.type.name.toUpperCase(),
                          style: pw.TextStyle(
                            color: typeColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      
                      // Amount
                      pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: isExpense ? "-" : isIncome ? "+" : "",
                              style: pw.TextStyle(
                                color: typeColor,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            // Use standard ASCII characters for currency when possible
                            pw.TextSpan(
                              text: currencySymbol == "रू" ? "Rs." : currencySymbol,
                              style: pw.TextStyle(
                                color: typeColor,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                            pw.TextSpan(
                              text: amountStr,
                              style: pw.TextStyle(
                                color: typeColor,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (originalCurrency != null && originalAmount != null) ...[
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Original: $originalCurrency${originalAmount.toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                
                // Transaction details table with alternating colors
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TRANSACTION DETAILS',
                        style: const pw.TextStyle(
                          color: PdfColors.grey700,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      
                      // Transaction details table
                      pw.Table(
                        border: null,
                        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                        children: [
                          // Category row
                          _buildTableRow(
                            'Category',
                            category.name,
                            true,
                            typeColor,
                          ),
                          
                          // Account row
                          _buildTableRow(
                            'Account',
                            account.name,
                            false,
                            typeColor,
                          ),
                          
                          // To Account row (for transfers)
                          if (isTransfer && destinationAccount != null)
                            _buildTableRow(
                              'To Account',
                              destinationAccount.name,
                              true,
                              typeColor,
                            ),
                          
                          // Date row
                          _buildTableRow(
                            'Date',
                            AppDateUtils.formatDate(transaction.date),
                            isTransfer && destinationAccount != null ? false : true,
                            typeColor,
                          ),
                          
                          // Time row
                          _buildTableRow(
                            'Time',
                            DateFormat('h:mm a').format(transaction.date),
                            isTransfer && destinationAccount != null ? true : false,
                            typeColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Description box
                if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DESCRIPTION',
                          style: const pw.TextStyle(
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            transaction.description!,
                            style: const pw.TextStyle(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Notes box
                if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NOTES',
                          style: const pw.TextStyle(
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(12),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                          ),
                          child: pw.Text(
                            transaction.notes!,
                            style: const pw.TextStyle(
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Replace flexible Spacer with fixed height SizedBox
                pw.SizedBox(height: 20),
                
                // Footer with horizontal line and dual text
                pw.Divider(color: PdfColors.grey300, thickness: 1),
                pw.SizedBox(height: 10),
                
                // Enhanced footer with more information
                pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                          style: const pw.TextStyle(
                            color: PdfColors.grey,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          'Made with love from Nepal by Aneesh',
                          style: const pw.TextStyle(
                            color: PdfColors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Website: www.paisatrack.com | Contact: support@paisatrack.com',
                          style: const pw.TextStyle(
                            color: PdfColors.grey700,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Track your finances effortlessly with Paisa Track',
                          style: pw.TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  pw.TableRow _buildTableRow(String label, String value, bool isColored, PdfColor accentColor) {
    return pw.TableRow(
      decoration: isColored ? const pw.BoxDecoration(color: PdfColors.grey100) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              color: PdfColors.black,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            value,
          ),
        ),
      ],
    );
  }
  
  /// Saves a PDF document to a temporary file and returns the file path
  Future<String> savePdfToTempFile(Uint8List pdfBytes, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }
  
  /// Shares a PDF document
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    final filePath = await savePdfToTempFile(pdfBytes, fileName);
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Transaction Details from Paisa Track',
      subject: 'Transaction Details',
    );
  }
  
  /// Generates a PDF document for transaction history
  Future<Uint8List> generateTransactionHistoryPdf({
    required List<TransactionModel> transactions,
    required Map<String, CategoryModel> categories,
    required Map<String, AccountModel> accounts,
    required String currencySymbol,
    required DateTime startDate,
    required DateTime endDate,
    String? filterType,
    String? filterCategory,
    String? filterAccount,
    UserProfileModel? userProfile,
  }) async {
    final pdf = pw.Document();
    
    // Load logo image if available
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/app_icon.png');
      final Uint8List bytes = data.buffer.asUint8List();
      logoImage = pw.MemoryImage(bytes);
    } catch (e) {
      // Logo not available, continue without it
      print('Logo image not available: $e');
    }
    
    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (final transaction in transactions) {
      if (transaction.type.name == 'income') {
        totalIncome += transaction.amount;
      } else if (transaction.type.name == 'expense') {
        totalExpense += transaction.amount;
      }
    }
    
    final balance = totalIncome - totalExpense;
    
    // Format date range for header
    final startDateStr = DateFormat('MMM dd, yyyy').format(startDate);
    final endDateStr = DateFormat('MMM dd, yyyy').format(endDate);
    
    // Page number counter for footer
    var pageNum = 0;
    var totalPages = 0;
    
    // Helper to create table header
    pw.TableRow buildTableHeader() {
      return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Date',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Type',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Category',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Account',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              'Amount',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }
    
    // Helper function to create row data for transaction
    pw.TableRow buildTableRow(TransactionModel transaction) {
      final isIncome = transaction.type.name == 'income';
      final isExpense = transaction.type.name == 'expense';
      final isTransfer = transaction.type.name == 'transfer';
      
      PdfColor amountColor = isIncome ? PdfColors.green700 : 
                            isExpense ? PdfColors.red700 : 
                            PdfColors.blue700;
      
      String amountPrefix = isIncome ? '+' : isExpense ? '-' : '';
      
      final category = categories[transaction.categoryId];
      final account = accounts[transaction.accountId];
      
      // Handle special currency symbols
      String safeCurrencySymbol = currencySymbol;
      if (currencySymbol == 'रू' || currencySymbol == '₹') {
        safeCurrencySymbol = 'Rs.';
      } else if (currencySymbol == '€') {
        safeCurrencySymbol = 'EUR';
      } else if (currencySymbol == '£') {
        safeCurrencySymbol = 'GBP';
      } else if (currencySymbol == '¥') {
        safeCurrencySymbol = 'JPY';
      } else if (currencySymbol == '₩') {
        safeCurrencySymbol = 'KRW';
      } else if (currencySymbol == '฿') {
        safeCurrencySymbol = 'THB';
      }
      
      return pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(DateFormat('MM/dd/yy').format(transaction.date)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(transaction.type.name.toUpperCase()),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(category?.name ?? 'Unknown'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(account?.name ?? 'Unknown'),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              '$amountPrefix$safeCurrencySymbol${transaction.amount.toStringAsFixed(2)}',
              style: pw.TextStyle(color: amountColor),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      );
    }
    
    // Define max rows per page (adjust as needed)
    const maxRowsPerPage = 15;
    final totalRows = transactions.length;
    totalPages = (totalRows / maxRowsPerPage).ceil() + 1; // +1 for summary page
    
    // Create header page with summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          pageNum++;
          
          // Handle special currency symbols
          String safeCurrencySymbol = currencySymbol;
          if (currencySymbol == 'रू' || currencySymbol == '₹') {
            safeCurrencySymbol = 'Rs.';
          } else if (currencySymbol == '€') {
            safeCurrencySymbol = 'EUR';
          } else if (currencySymbol == '£') {
            safeCurrencySymbol = 'GBP';
          } else if (currencySymbol == '¥') {
            safeCurrencySymbol = 'JPY';
          } else if (currencySymbol == '₩') {
            safeCurrencySymbol = 'KRW';
          } else if (currencySymbol == '฿') {
            safeCurrencySymbol = 'THB';
          }
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with brand colors and logo
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Transaction History',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue700,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$startDateStr - $endDateStr',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    // Logo
                    logoImage != null
                        ? pw.Container(
                            width: 40,
                            height: 40,
                            child: pw.Image(logoImage),
                          )
                        : pw.SizedBox(),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              
              // User profile information
              if (userProfile != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text(
                            'User: ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.Text(
                            userProfile.name ?? 'User',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (userProfile.email != null && userProfile.email!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Email: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              userProfile.email!,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 12),
              ],
              
              // Filters applied (if any)
              if (filterType != null || filterCategory != null || filterAccount != null) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Filters Applied:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      if (filterType != null && filterType != 'All') ...[
                        pw.Text('• Type: $filterType', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (filterCategory != null) ...[
                        pw.Text('• Category: $filterCategory', style: const pw.TextStyle(fontSize: 10)),
                      ],
                      if (filterAccount != null) ...[
                        pw.Text('• Account: $filterAccount', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
              
              // Summary box
              pw.Text(
                'SUMMARY',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    // Income
                    pw.Column(
                      children: [
                        pw.Text(
                          'Income',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '$safeCurrencySymbol${totalIncome.toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.green700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Expense
                    pw.Column(
                      children: [
                        pw.Text(
                          'Expense',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '$safeCurrencySymbol${totalExpense.toStringAsFixed(2)}',
                          style: const pw.TextStyle(
                            fontSize: 16,
                            color: PdfColors.red700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Balance
                    pw.Column(
                      children: [
                        pw.Text(
                          'Balance',
                          style: const pw.TextStyle(
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          '$safeCurrencySymbol${balance.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            color: balance >= 0 ? PdfColors.green700 : PdfColors.red700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Transactions header
              pw.Text(
                'TRANSACTIONS',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey800,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              
              // Transactions preview (show first few)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Table(
                  border: pw.TableBorder.symmetric(
                    inside: const pw.BorderSide(color: PdfColors.grey300),
                    outside: const pw.BorderSide(color: PdfColors.grey300),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2), // Date
                    1: const pw.FlexColumnWidth(2), // Type
                    2: const pw.FlexColumnWidth(3), // Category
                    3: const pw.FlexColumnWidth(3), // Account
                    4: const pw.FlexColumnWidth(2), // Amount
                  },
                  children: [
                    buildTableHeader(),
                    ...transactions.take(8).map(buildTableRow),
                  ],
                ),
              ),
              
              if (transactions.length > 8) ...[
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Text(
                    '... and ${transactions.length - 8} more transactions on the following pages',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
              
              // Footer
              pw.Spacer(),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 16),
                child: pw.Text(
                  'Page $pageNum of $totalPages',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${DateFormat('MM/dd/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Made with love from Nepal by Aneesh',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Website: www.paisatrack.com | Contact: support@paisatrack.com',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    
    return pdf.save();
  }
} 