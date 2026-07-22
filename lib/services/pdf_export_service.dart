import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class PdfExportService {
  static Future<String?> exportAndUploadPdf(
      String topic, int totalPublications, String uid) async {
    bool uploadSuccess = false;
    try {
      // ── Build PDF ────────────────────────────────────────────
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo700,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Journal Trend Analyzer',
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 6),
                  pw.Text('Research Analytics Report',
                      style: const pw.TextStyle(
                          fontSize: 14, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text('Generated: $dateStr',
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text('Search Topic',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700)),
            pw.Divider(color: PdfColors.indigo200),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('"$topic"',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Publication Statistics',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700)),
            pw.Divider(color: PdfColors.indigo200),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              _statBox('Total Publications', '$totalPublications',
                  PdfColors.indigo700),
              pw.SizedBox(width: 12),
              _statBox('Data Source', 'OpenAlex API', PdfColors.teal700),
              pw.SizedBox(width: 12),
              _statBox('Report Type', 'Analytics', PdfColors.orange700),
            ]),
            pw.SizedBox(height: 20),
            pw.Text('Firebase Integration',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo700)),
            pw.Divider(color: PdfColors.indigo200),
            pw.SizedBox(height: 8),
            ...[
              'Firebase Authentication — Google Sign-In',
              'Firebase Analytics — User activity tracking',
              'Firebase Cloud Messaging — Push notifications',
              'Firebase Crashlytics — Crash monitoring',
              'Firebase Remote Config — Dynamic configuration',
              'Firebase Storage — PDF report storage',
              'Cloud Firestore — Bookmark CRUD operations',
            ].map((s) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo500,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(s,
                        style: const pw.TextStyle(fontSize: 12)),
                  ]),
                )),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
                'PRM393 – Mobile Programming | Final Assignment: Journal Trend Analyzer',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      );

      // ── Save locally ─────────────────────────────────────────
      final docsDir = await getApplicationDocumentsDirectory();
      final reportsDir =
          Directory('${docsDir.path}/JournalTrendAnalyzer/reports');
      await reportsDir.create(recursive: true);
      final fileName =
          'report_${topic.replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}.pdf';
      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // ── Upload to Firebase Storage ───────────────────────────
      String downloadUrl = file.path; // fallback to local path
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('reports/$uid/$fileName');
        final uploadTask = await storageRef.putFile(file);
        downloadUrl = await uploadTask.ref.getDownloadURL();
        uploadSuccess = true;
        debugPrint('PDF uploaded to Storage: $downloadUrl');
      } catch (storageErr) {
        debugPrint('Storage upload failed, using local path: $storageErr');
        uploadSuccess = false;
        downloadUrl = file.path;
      }

      // ── Log Analytics event ───────────────────────────────────
      await FirebaseAnalytics.instance.logEvent(
        name: 'export_pdf',
        parameters: {
          'topic': topic,
          'upload_success': uploadSuccess ? 1 : 0,
        },
      );

      return downloadUrl;
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      await FirebaseAnalytics.instance.logEvent(
        name: 'export_pdf',
        parameters: {'topic': topic, 'upload_success': 0},
      );
      return null;
    }
  }

  static pw.Widget _statBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
            pw.SizedBox(height: 4),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
      ),
    );
  }
}
