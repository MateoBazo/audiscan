import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class VisorPdfPantalla extends StatefulWidget {
  final String rutaArchivo;
  final String titulo;

  const VisorPdfPantalla({
    super.key,
    required this.rutaArchivo,
    required this.titulo,
  });

  @override
  State<VisorPdfPantalla> createState() => _VisorPdfPantallaState();
}

class _VisorPdfPantallaState extends State<VisorPdfPantalla> {
  int _paginaActual = 0;
  int _totalPaginas = 0;
  bool _listo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          if (_listo && _totalPaginas > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_paginaActual + 1} / $_totalPaginas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: PDFView(
        filePath: widget.rutaArchivo,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: false,
        onRender: (paginas) {
          setState(() {
            _totalPaginas = paginas ?? 0;
            _listo = true;
          });
        },
        onPageChanged: (pagina, _) {
          setState(() => _paginaActual = pagina ?? 0);
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al abrir el PDF: $error')),
          );
        },
      ),
    );
  }
}
