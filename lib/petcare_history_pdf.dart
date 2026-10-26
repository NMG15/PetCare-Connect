import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PetCarePdfEntry {
  const PetCarePdfEntry({
    required this.date,
    required this.care,
    required this.time,
    required this.note,
  });
  final DateTime date;
  final String care;
  final String time;
  final String note;
}

String petCarePdfSafeText(String value, {String fallback = ''}) {
  final withoutEmoji = value.replaceAll(
    RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0E}\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]',
      unicode: true,
    ),
    '',
  );
  final clean =
      withoutEmoji
          .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
          .replaceAllMapped(
            RegExp(r'[ \t]+([,.;:!?])'),
            (match) => match.group(1)!,
          )
          .trim();
  return clean.isEmpty ? fallback : clean;
}

String petCarePdfDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

Future<Uint8List> createPetCareHistoryPdf({
  required String petName,
  required String period,
  String ownerName = '',
  required List<PetCarePdfEntry> entries,
}) async {
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/lato/Lato-Regular.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/lato/Lato-Bold.ttf'),
  );
  final brandLogo = pw.MemoryImage(
    (await rootBundle.load(
      'assets/icon/petcare_icon.png',
    )).buffer.asUint8List(),
  );
  const emerald = PdfColor(0.075, 0.412, 0.302);
  const forest = PdfColor(0.075, 0.255, 0.196);
  const mist = PdfColor(0.917, 0.965, 0.937);
  const graphite = PdfColor(0.18, 0.26, 0.23);
  const paperWhite = PdfColor(1, 1, 1);

  final safePetName = petCarePdfSafeText(petName, fallback: 'Mascota');
  final document = pw.Document(
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
    title: 'Historial de cuidados - $safePetName',
    author: 'PetCare Connect',
  );
  final ordered = List<PetCarePdfEntry>.from(entries)
    ..sort((a, b) => b.date.compareTo(a.date));
  final generatedAt = DateTime.now();
  final owner = petCarePdfSafeText(ownerName);

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 300,
      margin: const pw.EdgeInsets.fromLTRB(30, 30, 30, 35),
      header:
          (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 13),
            margin: const pw.EdgeInsets.only(bottom: 18),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: emerald, width: 1.5),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 46,
                  height: 46,
                  padding: const pw.EdgeInsets.all(3),
                  decoration: pw.BoxDecoration(
                    color: paperWhite,
                    border: pw.Border.all(color: mist, width: 1),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Image(brandLogo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PetCare Connect',
                        style: pw.TextStyle(
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          color: emerald,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'REPORTE PERSONAL DE BIENESTAR',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.1,
                          color: graphite,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: pw.BoxDecoration(
                    color: mist,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'HISTORIAL',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: forest,
                    ),
                  ),
                ),
              ],
            ),
          ),
      footer:
          (context) => pw.Column(
            children: [
              pw.Divider(color: mist),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PetCare Connect · Seguimiento personal',
                    style: const pw.TextStyle(fontSize: 8, color: graphite),
                  ),
                  pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: graphite),
                  ),
                ],
              ),
            ],
          ),
      build:
          (context) => [
            ...[
              pw.Text(
                'Historial de cuidados',
                style: pw.TextStyle(
                  fontSize: 23,
                  fontWeight: pw.FontWeight.bold,
                  color: forest,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Un registro claro de los momentos importantes de tu mascota.',
                style: const pw.TextStyle(fontSize: 10, color: graphite),
              ),
              pw.SizedBox(height: 18),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: mist,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      safePetName,
                      style: pw.TextStyle(
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                        color: forest,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (owner.isNotEmpty)
                      pw.Text(
                        'Responsable: $owner',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    pw.Text(
                      'Periodo: ${petCarePdfSafeText(period)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Generado: ${petCarePdfDate(generatedAt)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${ordered.length} ${ordered.length == 1 ? 'cuidado registrado' : 'cuidados registrados'}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: emerald,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
            ],
            pw.Text(
              'Detalle de actividades',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: forest,
              ),
            ),
            pw.SizedBox(height: 10),
            if (ordered.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: mist),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  'No hay cuidados registrados en el periodo seleccionado.',
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: const ['Fecha', 'Cuidado', 'Hora', 'Notas'],
                data:
                    ordered
                        .map(
                          (row) => [
                            petCarePdfDate(row.date),
                            petCarePdfSafeText(row.care, fallback: 'Cuidado'),
                            petCarePdfSafeText(row.time),
                            petCarePdfSafeText(row.note),
                          ],
                        )
                        .toList(),
                border: pw.TableBorder(
                  horizontalInside: const pw.BorderSide(
                    color: mist,
                    width: 0.7,
                  ),
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: paperWhite,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(color: emerald),
                oddRowDecoration: const pw.BoxDecoration(color: mist),
                cellStyle: const pw.TextStyle(fontSize: 9, color: graphite),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            pw.SizedBox(height: 17),
            pw.Text(
              'Este documento es un registro personal de cuidados. '
              'No sustituye una valoración veterinaria.',
              style: const pw.TextStyle(fontSize: 9, color: graphite),
            ),
          ],
    ),
  );
  return document.save();
}
