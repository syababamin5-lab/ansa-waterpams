import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  Future<void> generateAndShareInvoice(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('ANSA WATER', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
              ),
              pw.Center(
                child: pw.Text('Struk Tagihan Air Terpadu', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue),
              pw.SizedBox(height: 20),
              pw.Text('Detail Pelanggan:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Nama: ${data['nama']}'),
              pw.Text('Alamat: ${data['alamat']}'),
              pw.Text('Tanggal: ${data['tanggal']}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Deskripsi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Nilai', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  _buildTableRow('Meter Lalu', '${data['meter_lalu']} m³'),
                  _buildTableRow('Meter Sekarang', '${data['meter_skrg']} m³'),
                  _buildTableRow('Total Pemakaian', '${data['pemakaian']} m³'),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('TOTAL TAGIHAN:', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                    pw.Text('Rp ${data['total'].toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Terima kasih atas pembayaran Anda', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/tagihan_${data['nama'].toString().replaceAll(' ', '_')}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share to WhatsApp or other apps
    await Share.shareXFiles([XFile(file.path)], text: 'Halo ${data['nama']}, berikut adalah tagihan air Anda untuk periode ini.');
  }

  pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label)),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value)),
      ],
    );
  }
}
