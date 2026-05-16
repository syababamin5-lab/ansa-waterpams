import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

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
                child: pw.Text(data['pamsimas'] ?? 'ANSA WATER', 
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              ),
              pw.Center(
                child: pw.Text('Struk Tagihan Air Bulanan', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey),
              pw.SizedBox(height: 10),
              
              // Info Pelanggan
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Pelanggan:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.Text(data['nama'], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['alamat'] ?? '-', style: pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Tanggal:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.Text(data['tanggal'], style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 20),
              
              // Tabel Perhitungan
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  _headerRow(['Rincian', 'Nilai']),
                  _dataRow('Meter Lalu', '${data['meter_lalu']} m³'),
                  _dataRow('Meter Sekarang', '${data['meter_skrg']} m³'),
                  _dataRow('Total Pemakaian', '${data['pemakaian']} m³'),
                  _dataRow('Harga per m³', formatCurrency(data['harga'])),
                ],
              ),
              
              pw.SizedBox(height: 15),
              
              // Total Section
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                child: pw.Column(
                  children: [
                    _summaryRow('Biaya Pemakaian', formatCurrency(data['pemakaian'] * data['harga'])),
                    pw.SizedBox(height: 5),
                    _summaryRow('Biaya Beban Tetap', formatCurrency(data['beban'])),
                    pw.Divider(thickness: 0.5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL BAYAR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text(formatCurrency(data['total']), 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blue900)),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Simpan struk ini sebagai bukti pembayaran sah.', 
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey, fontStyle: pw.FontStyle.italic)),
              ),
            ],
          );
        },
      ),
    );

    // Menggunakan Printing agar kompatibel dengan Web/Chrome & Mobile
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Tagihan_${data['nama']}',
    );
  }

  static String formatCurrency(dynamic amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );
    return "${formatter.format(amount)},-";
  }

  pw.TableRow _headerRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      children: labels.map((l) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(l, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      )).toList(),
    );
  }

  pw.TableRow _dataRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(label, style: const pw.TextStyle(fontSize: 10))),
        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
      ],
    );
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }
}
