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
      SELECT dpt.DPTONOM, cat.PRDCATNOM, SUM(lin.DOCCNTCORL) AS total_entregado, lin.DCCNTCORUI AS UNIDAD
      FROM CDCDTAPRO.DOCCRG doc
      JOIN CDCDTAPRO.DCPRDLIN lin ON doc.PLAID = lin.PLAID AND doc.DOCID = lin.DOCID
      JOIN CDCDTAPRO.CLIDIR dir ON doc.CLIID = dir.CLIID AND doc.CLIIDDIR = dir.CLIIDDIR
      JOIN CDCDTAPRO.DEPARTAM dpt ON dir.DPTOID = dpt.DPTOID
      JOIN CDCDTAPRO.PRODUCTO prd ON lin.PRDID = prd.PRDID
      JOIN CDCDTAPRO.PRDGRP grp ON prd.PRDGRPID = grp.PRDGRPID
      JOIN CDCDTAPRO.PRDCAT cat ON grp.PRDCATID = cat.PRDCATID
      WHERE doc.DOCFCH BETWEEN '20240101' AND '20240330'
      GROUP BY dpt.DPTONOM, cat.PRDCATNOM, lin.DCCNTCORUI
      ORDER BY dpt.DPTONOM, total_entregado DESC
    """,
    "Cantidades totales por planta y grupo de producto": """
      SELECT pla.PLANOM, grp.PRDGRPDSC, SUM(lin.DOCCNTCORL) AS total, lin.DCCNTCORUI AS UNIDAD
      FROM CDCDTAPRO.DOCCRG doc
      JOIN CDCDTAPRO.DCPRDLIN lin ON doc.PLAID = lin.PLAID AND doc.DOCID = lin.DOCID
      JOIN CDCDTAPRO.plantas pla ON doc.PLAID = pla.PLAID
      JOIN CDCDTAPRO.PRODUCTO prd ON lin.PRDID = prd.PRDID
      JOIN CDCDTAPRO.PRDGRP grp ON prd.PRDGRPID = grp.PRDGRPID
      WHERE doc.DOCFCH BETWEEN '20240101' AND '20240330'
      GROUP BY pla.PLANOM, grp.PRDGRPDSC , lin.DCCNTCORUI
      ORDER BY pla.PLANOM, total DESC
    """,
    "Cantidad de entregas por negocio": """
      SELECT nt.NEGTPODSC, COUNT(*) AS cantidad_docs
      FROM CDCDTAPRO.DOCCRG doc
      JOIN CDCDTAPRO.NEGOCIO neg ON doc.DOCNEGID = neg.NEGID
      JOIN CDCDTAPRO.NEGTPO nt ON neg.NEGTPOID = nt.NEGTPOID
      WHERE doc.DOCFCH BETWEEN '20240101' AND '20241231'
      GROUP BY nt.NEGTPODSC
      ORDER BY cantidad_docs DESC
    """,
    "Cantidades totales por mercado, grupo de producto y producto": """
      SELECT m.MERDSC AS MERCADO, pg.PRDGRPDSC AS GRUPO_PRODUCTO, p.PRDDSC AS PRODUCTO,
      SUM(dl.DOCCNTCORL) AS VOLUMEN_TOTAL, dl.DCCNTCORUI AS UNIDAD
      FROM CDCDTAPRO.DCPRDLIN dl
      JOIN CDCDTAPRO.DOCCRG d ON dl.PLAID = d.PLAID AND dl.DOCID = d.DOCID
      JOIN CDCDTAPRO.PRODUCTO p ON dl.PRDID = p.PRDID
      JOIN CDCDTAPRO.PRDGRP pg ON p.PRDGRPID = pg.PRDGRPID
      JOIN CDCDTAPRO.POLITICA pol ON d.POLID = pol.POLID
      JOIN CDCDTAPRO.MERCADO m ON pol.MERID = m.MERID
      WHERE d.DOCFCH BETWEEN '20240101' AND '20240330'
      GROUP BY m.MERDSC, pg.PRDGRPDSC, p.PRDDSC, dl.DCCNTCORUI
      ORDER BY m.MERDSC, pg.PRDGRPDSC, p.PRDDSC
    """,
    "Top 10 clientes con más cantidad entregada": """
      SELECT
      c.CLINOM AS CLIENTE,
      SUM(dl.DOCCNTCORL) AS CANTIDAD_TOTAL
      FROM CDCDTAPRO.DOCCRG d
      JOIN CDCDTAPRO.DCPRDLIN dl ON d.PLAID = dl.PLAID AND d.DOCID = dl.DOCID
      JOIN CDCDTAPRO.CLIENTE c ON d.CLIID = c.CLIID
      WHERE d.DOCFCH >= '20240101' AND d.DOCFCH <= '20240330'
      GROUP BY c.CLINOM
      ORDER BY CANTIDAD_TOTAL DESC
      FETCH FIRST 10 ROWS ONLY
    """,
    "Total facturado por distribuidora, mes, negocio, moneda y grupo de producto":
        """
      SELECT
      d.DSTNOM AS DISTRIBUIDORA,
      n.NEGDSC AS NEGOCIO,
      grp.PRDGRPDSC AS GRUPO_PRODUCTO,
      m.MONSIG AS MONEDA,
      SUM(fl.FACLINCNT) AS CANTIDAD_TOTAL
      FROM cdcdtapro.FACCAB fc
      JOIN cdcdtapro.FACLINPR fl
      ON fc.FACPLAID = fl.FACPLAID
      AND fc.FACTPODOC = fl.FACTPODOC
      AND fc.FACNRO = fl.FACNRO
      AND fc.FACSERIE = fl.FACSERIE
      JOIN cdcdtapro.PRODUCTO pr ON fl.PRDID = pr.PRDID
      JOIN cdcdtapro.PRDGRP grp ON pr.PRDGRPID = grp.PRDGRPID
      JOIN cdcdtapro.NEGOCIO n ON fc.FACNEGID = n.NEGID
      JOIN cdcdtapro.MONEDA m ON fc.FACMONID = m.MONID
      JOIN cdcdtapro.distribu d ON fc.DSTID = d.DSTID
      WHERE fc.FACFCH BETWEEN '20240101' AND '20240131'
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
        final result = await _chatService.executeSqlQuery(entry.value);
        chartData.add(
          StaticChartData(
            title: entry.key,
            jsonString: jsonEncode({"data": result}),
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
