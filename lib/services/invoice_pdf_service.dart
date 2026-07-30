// ignore_for_file: deprecated_member_use
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../core/constants.dart';
import '../models/invoice_model.dart';

class InvoicePdfService {
  static Future<pw.Document> generateInvoiceDocument(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.appName,
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Utensil & Hardware Business Accounting Suite',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Invoice No: ${invoice.invoiceNo}'),
                      pw.Text('Date: ${invoice.date.day}/${invoice.date.month}/${invoice.date.year}'),
                    ],
                  ),
                ],
              ),
              pw.Divider(height: 20),
              pw.Text(
                'Billed To: ${invoice.partyName}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
              ),
              pw.SizedBox(height: 14),
              pw.TableHelper.fromTextArray(
                headers: ['Item Description', 'Qty', 'Unit Price', 'GST %', 'Total (INR)'],
                data: invoice.items.map((item) {
                  return [
                    item.itemName,
                    '${item.quantity} ${item.unit}',
                    AppConstants.formatCurrency(item.unitPrice),
                    '${item.gstRate.toStringAsFixed(0)}%',
                    AppConstants.formatCurrency(item.lineGrandTotal),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.Divider(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${AppConstants.formatCurrency(invoice.subtotal)}'),
                    pw.Text('Total CGST + SGST: ${AppConstants.formatCurrency(invoice.cgstAmount + invoice.sgstAmount)}'),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Grand Total: ${AppConstants.formatCurrency(invoice.grandTotal)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Divider(height: 10),
              pw.Center(
                child: pw.Text(
                  'Thank you for your business! Powered by OmniBook',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static Future<void> printOrShareInvoice(Invoice invoice) async {
    final pdf = await generateInvoiceDocument(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${invoice.invoiceNo}.pdf',
    );
  }
}
