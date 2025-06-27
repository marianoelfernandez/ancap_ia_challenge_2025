import "dart:convert";
import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:anc_app/src/features/chatbot/services/chat_service.dart";
import "package:anc_app/src/features/chatbot/widgets/ai_chart_widget.dart";

class StaticChartData {
  final String title;
  final String jsonString;

  StaticChartData({required this.title, required this.jsonString});
}

class StaticChartsWidget extends StatefulWidget {
  const StaticChartsWidget({super.key});

  @override
  _StaticChartsWidgetState createState() => _StaticChartsWidgetState();
}

class _StaticChartsWidgetState extends State<StaticChartsWidget> {
  final ChatService _chatService = GetIt.instance<ChatService>();
  bool _isLoading = true;
  List<StaticChartData> _chartData = [];
  String? _error;

  final Map<String, String> _staticQueries = {
    "Cantidades totales por departamento y categoría de producto": """
      SELECT dpt.DPTONOM, cat.PRDCATNOM, COALESCE(SUM(lin.DOCCNTCORL), 0) AS total_entregado, lin.DCCNTCORUI AS UNIDAD
      FROM datosancap.entregas_facturacion.DOCCRG doc
      JOIN datosancap.entregas_facturacion.DCPRDLIN lin ON doc.PLAID = lin.PLAID AND doc.DOCID = lin.DOCID
      JOIN datosancap.entregas_facturacion.CLIDIR dir ON doc.CLIID = dir.CLIID AND doc.CLIIDDIR = dir.CLIIDDIR
      JOIN datosancap.entregas_facturacion.DEPARTAMENTOS dpt ON dir.DPTOID = dpt.DPTOID
      JOIN datosancap.entregas_facturacion.PRODUCTOS prd ON lin.PRDID = prd.PRDID
      JOIN datosancap.entregas_facturacion.PRDGRP grp ON prd.PRDGRPID = grp.PRDGRPID
      JOIN datosancap.entregas_facturacion.PRDCAT cat ON grp.PRDCATID = cat.PRDCATID
      WHERE doc.DOCFCH BETWEEN DATE '2024-01-01' AND DATE '2024-03-30'
      GROUP BY dpt.DPTONOM, cat.PRDCATNOM, lin.DCCNTCORUI
      ORDER BY dpt.DPTONOM, total_entregado DESC
    """,
    "Cantidades totales por planta y grupo de producto": """
      SELECT pla.PLANOM, grp.PRDGRPDSC, COALESCE(SUM(lin.DOCCNTCORL), 0) AS total, lin.DCCNTCORUI AS UNIDAD
      FROM datosancap.entregas_facturacion.DOCCRG doc
      JOIN datosancap.entregas_facturacion.DCPRDLIN lin ON doc.PLAID = lin.PLAID AND doc.DOCID = lin.DOCID
      JOIN datosancap.entregas_facturacion.PLANTAS pla ON doc.PLAID = pla.PLAID
      JOIN datosancap.entregas_facturacion.PRODUCTOS prd ON lin.PRDID = prd.PRDID
      JOIN datosancap.entregas_facturacion.PRDGRP grp ON prd.PRDGRPID = grp.PRDGRPID
      WHERE doc.DOCFCH BETWEEN DATE '2024-01-01' AND DATE '2024-03-30'
      GROUP BY pla.PLANOM, grp.PRDGRPDSC , lin.DCCNTCORUI
      ORDER BY pla.PLANOM, total DESC
    """,
    "Cantidad de entregas por negocio": """
      SELECT nt.NEGTPODSC, COUNT(*) AS cantidad_docs
      FROM datosancap.entregas_facturacion.DOCCRG doc
      JOIN datosancap.entregas_facturacion.NEGOCIOS neg ON doc.DOCNEGID = neg.NEGID
      JOIN datosancap.entregas_facturacion.NEGTPO nt ON neg.NEGTPOID = nt.NEGTPOID
      WHERE doc.DOCFCH BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
      GROUP BY nt.NEGTPODSC
      ORDER BY cantidad_docs DESC
    """,
    "Cantidades totales por mercado, grupo de producto y producto": """
      SELECT m.MERDSC AS MERCADOS, pg.PRDGRPDSC AS GRUPO_PRODUCTO, p.PRDDSC AS PRODUCTO,
      COALESCE(SUM(dl.DOCCNTCORL), 0) AS VOLUMEN_TOTAL, dl.DCCNTCORUI AS UNIDAD
      FROM datosancap.entregas_facturacion.DCPRDLIN dl
      JOIN datosancap.entregas_facturacion.DOCCRG d ON dl.PLAID = d.PLAID AND dl.DOCID = d.DOCID
      JOIN datosancap.entregas_facturacion.PRODUCTOS p ON dl.PRDID = p.PRDID
      JOIN datosancap.entregas_facturacion.PRDGRP pg ON p.PRDGRPID = pg.PRDGRPID
      JOIN datosancap.entregas_facturacion.POLITICAS pol ON d.POLID = pol.POLID
      JOIN datosancap.entregas_facturacion.MERCADOS m ON pol.MERID = m.MERID
      WHERE d.DOCFCH BETWEEN DATE '2024-01-01' AND DATE '2024-03-30'
      GROUP BY m.MERDSC, pg.PRDGRPDSC, p.PRDDSC, dl.DCCNTCORUI
      ORDER BY m.MERDSC, pg.PRDGRPDSC, p.PRDDSC
    """,
    "Top 10 clientes con más cantidad entregada": """
      SELECT
      c.CLINOM AS CLIENTES,
      COALESCE(SUM(dl.DOCCNTCORL), 0) AS CANTIDAD_TOTAL
      FROM datosancap.entregas_facturacion.DOCCRG d
      JOIN datosancap.entregas_facturacion.DCPRDLIN dl ON d.PLAID = dl.PLAID AND d.DOCID = dl.DOCID
      JOIN datosancap.entregas_facturacion.CLIENTES c ON d.CLIID = c.CLIID
      WHERE d.DOCFCH >= DATE '2024-01-01' AND d.DOCFCH <= DATE '2024-03-30'
      GROUP BY c.CLINOM
      ORDER BY CANTIDAD_TOTAL DESC
      LIMIT 10
    """,
    "Total facturado por distribuidora, mes, negocio, moneda y grupo de producto":
        """
      SELECT
      d.DSTNOM AS DISTRIBUIDORAS,
      n.NEGDSC AS NEGOCIOS,
      grp.PRDGRPDSC AS GRUPO_PRODUCTO,
      m.MONSIG AS MONEDAS,
      COALESCE(SUM(fl.FACLINCNT), 0) AS CANTIDAD_TOTAL
      FROM datosancap.entregas_facturacion.FACCAB fc
      JOIN datosancap.entregas_facturacion.FACLINPR fl
      ON fc.FACPLAID = fl.FACPLAID
      AND fc.FACTPODOC = fl.FACTPODOC
      AND fc.FACNRO = fl.FACNRO
      AND fc.FACSERIE = fl.FACSERIE
      JOIN datosancap.entregas_facturacion.PRODUCTOS pr ON fl.PRDID = pr.PRDID
      JOIN datosancap.entregas_facturacion.PRDGRP grp ON pr.PRDGRPID = grp.PRDGRPID
      JOIN datosancap.entregas_facturacion.NEGOCIOS n ON fc.FACNEGID = n.NEGID
      JOIN datosancap.entregas_facturacion.MONEDAS m ON fc.FACMONID = m.MONID
      JOIN datosancap.entregas_facturacion.DISTRIBUIDORAS d ON fc.DSTID = d.DSTID
      WHERE fc.FACFCH BETWEEN DATE '2024-01-01' AND DATE '2024-01-31'
      GROUP BY
      d.DSTNOM,
      n.NEGDSC,
      grp.PRDGRPDSC,
      m.MONSIG
      ORDER BY
      d.DSTNOM,
      n.NEGDSC,
      grp.PRDGRPDSC
    """,
  };

  @override
  void initState() {
    super.initState();
    _loadCharts();
  }

  Future<void> _loadCharts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<StaticChartData> chartData = [];
      for (var entry in _staticQueries.entries) {
        final result = await _chatService.executeSqlQuery(
          entry.value,
          conversationId: "q5ypej9k72gkmc2",
        );
        chartData.add(
          StaticChartData(
            title: entry.key,
            jsonString: jsonEncode(result),
          ),
        );
      }
      if (mounted) {
        setState(() {
          _chartData = chartData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error loading charts: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_chartData.isEmpty) {
      return const Center(child: Text("No charts to display."));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 600,
        mainAxisExtent: 450,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _chartData.length,
      itemBuilder: (context, index) {
        final chart = _chartData[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: AiDataResponseChart(
            jsonString: chart.jsonString,
            isDashboard: true,
          ),
        );
      },
    );
  }
}
