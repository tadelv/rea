import 'dart:math';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/service_locator.dart';
import 'package:despresso/ui/screens/shot_edit.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:despresso/generated/l10n.dart';

import 'package:despresso/ui/theme.dart' as theme;
import 'package:intl/intl.dart';

class ShotGraph extends StatefulWidget {
  final int id;
  final List<int>? overlayIds;

  final bool showFlow;
  final bool showPressure;
  final bool showWeight;
  final bool showTemp;

  const ShotGraph(
      {Key? key,
      required this.id,
      this.overlayIds,
      required this.showFlow,
      required this.showPressure,
      required this.showWeight,
      required this.showTemp})
      : super(key: key);

  @override
  ShotGraphState createState() => ShotGraphState();
}

class ShotGraphState extends State<ShotGraph> {
  int id = 0;

  List<int>? overlayIds;

  bool _overlayMode = false;

  List<Shot?> shotOverlay = [];

  ShotGraphState();

  @override
  Widget build(BuildContext context) {
    id = widget.id;
    overlayIds = widget.overlayIds;
    var shotBox = getIt<ObjectBox>().store.box<Shot>();
    if (overlayIds != null) {
      _overlayMode = true;
      for (var element in overlayIds!) {
        shotOverlay.add(shotBox.get(element));
      }
    } else {
      var shot = shotBox.get(id);
      overlayIds = [id];
      shotOverlay.add(shot);
    }
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODO: remove overlay functionality?
          ...shotOverlay.map((e) => Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${DateFormat.Hm().format(e!.date)} ${DateFormat.yMd().format(e.date)} ${e.pourWeight.toStringAsFixed(1)}g in ${e.pourTime.toStringAsFixed(1)}s'),
                      TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ShotEdit(
                                        e.id,
                                      )),
                            );
                          },
                          icon: const Icon(Icons.note_add),
                          label: Text(S.of(context).screenEspressoDiary))
                    ]),
                Row(children: [
                  Text(
                      'Recipe: ${e.recipe.target?.name}, ${e.doseWeight.toStringAsFixed(1)}g in ${e.pourWeight.toStringAsFixed(1)}g out in ${e.pourTime.toStringAsFixed(1)}s',
                      textAlign: TextAlign.start),
                ]),
                Row(children: [
                  Text(
                      '${e.coffee.target!.name} by ${e.coffee.target!.roaster.target!.name}',
                      textAlign: TextAlign.start),
                ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${e.recipe.target!.grinderModel.isNotEmpty ? e.recipe.target?.grinderModel : "Grinder set"} @ ${e.recipe.target?.grinderSettings}'),
                      //Text('${getIt<ProfileService>().profiles.firstWhere((pr) => pr.id == e.recipe.target?.id)}')
                      Text(
                          'Profile: ${e.recipe.target!.profileName.isNotEmpty ? e.recipe.target?.profileName : "Unknown profile"}')
                    ]),
              ])),
          _buildGraphs()['combined'],
          ...shotOverlay.map((e) => SizedBox(
              height: 300,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Shot notes:', textAlign: TextAlign.left),
                    SizedBox(
                        //height: 200,
                        width: 1800,
                        child: Text(e?.description ?? '')),
                    TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          getIt<CoffeeService>()
                              .setSelectedRecipe(e!.recipe.target?.id ?? 0);
                        },
                        icon: const Icon(Icons.replay),
                        label: Text("Repeat recipe")),
                  ])))
        ],
      ),
    );
  }

  _buildGraphs() {
    Iterable<VerticalRangeAnnotation> ranges = [];
    Map<String, List<FlSpot>> datamap = {};

    for (var shot in shotOverlay) {
      if (!_overlayMode) ranges = _createPhasesFl(shot!.shotstates.toList());
      var data = _createDataFlCharts(shot!.id, shot.shotstates);
      datamap.addAll(data);
    }

    var single = _buildGraphSingleFlCharts(datamap, ranges);
    var combined = _builGraphCombinedFlCharts(datamap, ranges);
    return {"single": single, "combined": combined};
  }

  Iterable<VerticalRangeAnnotation> _createPhasesFl(List<ShotState> states) {
    var stateChanges =
        states.where((element) => element.subState.isNotEmpty).toList();

    int i = 0;
    var maxSampleTime =
        states.isNotEmpty ? states.last.sampleTimeCorrected : 10.0;
    return stateChanges.map((from) {
      var toSampleTime = maxSampleTime;

      if (i < stateChanges.length - 1) {
        i++;
        toSampleTime = stateChanges[i].sampleTimeCorrected;
      }

      var col = theme.ThemeColors.statesColors[from.subState];
      var col2 = col ?? theme.ThemeColors.goodColor;
      // col == null ? col! : charts.Color(r: 0xff, g: 50, b: i * 19, a: 100);
      return VerticalRangeAnnotation(
        x1: from.sampleTimeCorrected,
        x2: toSampleTime,
        color: col2,
      );
    });
  }

  Map<String, List<FlSpot>> _createDataFlCharts(
      int id, List<ShotState> shotstates) {
    return {
      "pressure$id": shotstates
          .map((e) =>
              FlSpot(e.sampleTimeCorrected, e.groupPressure.clamp(0, 13)))
          .toList(),
      "pressureSet$id": shotstates
          .map((e) =>
              FlSpot(e.sampleTimeCorrected, e.setGroupPressure.clamp(0, 13)))
          .toList(),
      "flow$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.groupFlow.clamp(0, 13)))
          .toList(),
      "flowSet$id": shotstates
          .map(
              (e) => FlSpot(e.sampleTimeCorrected, e.setGroupFlow.clamp(0, 13)))
          .toList(),
      "temp$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.headTemp))
          .toList(),
      "tempSet$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.setHeadTemp))
          .toList(),
      "tempMix$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.mixTemp))
          .toList(),
      "tempMixSet$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.setMixTemp))
          .toList(),
      "weight$id": shotstates
          .map((e) => FlSpot(
              e.sampleTimeCorrected, e.weight.clamp(0, double.maxFinite)))
          .toList(),
      "flowG$id": shotstates
          .map((e) => FlSpot(e.sampleTimeCorrected, e.flowWeight.clamp(0, double.maxFinite)))
          .toList(),
    };
  }

  LineChartBarData createChartLineDatapoints(
      List<FlSpot> points, double barWidth, Color col, List<int>? dash) {
    return LineChartBarData(
      spots: points,
      dotData: const FlDotData(
        show: false,
      ),
      barWidth: barWidth,
      isCurved: true,
      isStrokeJoinRound: true,
      color: col,
      dashArray: dash,
    );
  }

  Widget _builGraphCombinedFlCharts(Map<String, List<FlSpot>> data,
      Iterable<VerticalRangeAnnotation> ranges) {
    List<LineChartBarData> lineBarsData = [];
    double i = 0;
    for (var id in overlayIds!) {
      lineBarsData.add(createChartLineDatapoints(data["pressure$id"]!, 4,
          calcColor(theme.ThemeColors.pressureColor, i), null));
      lineBarsData.add(createChartLineDatapoints(
          data["pressureSet$id"]!,
          2,
          calcColor(
            theme.ThemeColors.pressureColor,
            i,
          ),
          [5, 5]));
      lineBarsData.add(createChartLineDatapoints(data["flow$id"]!, 4,
          calcColor(theme.ThemeColors.flowColor, i), null));
      lineBarsData.add(createChartLineDatapoints(data["flowSet$id"]!, 2,
          calcColor(theme.ThemeColors.flowColor, i), [5, 5]));
      lineBarsData.add(createChartLineDatapoints(data["flowG$id"]!, 2,
          calcColor(theme.ThemeColors.weightColor, i), null));
					bool largeWeight = data["weight$id"]!.map((a) => a.y).reduce(max) > 15;
      lineBarsData.add(createChartLineDatapoints(
          data["weight$id"]!.map((e) => FlSpot(e.x, (largeWeight ? e.y / 10 : e.y))).toList(),
          2,
          calcColor(theme.ThemeColors.weightColor, i),
          null));
      lineBarsData.add(createChartLineDatapoints(
          data["temp$id"]!.map((e) => FlSpot(e.x, e.y / 10)).toList(),
          4,
          calcColor(theme.ThemeColors.tempColor, i),
          null));
      lineBarsData.add(createChartLineDatapoints(
          data["tempSet$id"]!.map((e) => FlSpot(e.x, e.y / 10)).toList(),
          2,
          calcColor(theme.ThemeColors.tempColor, i),
          [5, 5]));
      lineBarsData.add(createChartLineDatapoints(
          data["tempMix$id"]!.map((e) => FlSpot(e.x, e.y / 10)).toList(),
          4,
          calcColor(theme.ThemeColors.tempColor2, i),
          null));
      lineBarsData.add(createChartLineDatapoints(
          data["tempMixSet$id"]!.map((e) => FlSpot(e.x, e.y / 10)).toList(),
          2,
          calcColor(theme.ThemeColors.tempColor2, i),
          [5, 5]));
      i += 0.25;
    }
    var flowChart1 = LineChart(
      LineChartData(
          // minY: 0,
          // maxY: 15,
          // minX: data["pressure${overlayIds!.first}"]!.first.x,
          // maxX: maxTime,
          lineTouchData: const LineTouchData(enabled: false),
          clipData: const FlClipData.all(),
          gridData: const FlGridData(
            show: true,
            drawVerticalLine: true,
          ),
          lineBarsData: lineBarsData,
          rangeAnnotations: RangeAnnotations(
            verticalRangeAnnotations: [
              //...ranges,
            ],
          ),
          titlesData: FlTitlesData(
              leftTitles: AxisTitles(),
              topTitles: AxisTitles(),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: leftTitleWidgets1,
                    reservedSize: 32),
              ),
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1,
                getTitlesWidget: bottomTitleWidgets1,
              )))),
    );
    return Padding(
        padding: const EdgeInsets.all(18.0),
        child: SizedBox(height: 300, child: flowChart1));
  }

  Widget bottomTitleWidgets1(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16,
    );
    Widget text;
    if (meta.max < 30) {
      if (value.toInt() == value) {
        return Text('${value.toInt()}', style: style);
      } else {
        return Container();
      }
    }
    switch (value.toInt() % 10 == 0 && value == value.toInt()) {
      case true:
        text = Text('${value.toInt()}', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  Widget leftTitleWidgets1(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.w300,
      fontSize: 14,
    );
    if (value.toInt() != value) {
      return Container();
    }
    String text = "$value";

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  Widget _buildGraphSingleFlCharts(Map<String, List<FlSpot>> data,
      Iterable<VerticalRangeAnnotation> ranges) {
    List<LineChartBarData> lineBarsDataFlows = [];
    List<LineChartBarData> lineBarsDataTempWeight = [];
    List<LineChartBarData> lineBarsDataTemp = [];
    double i = 0;
    for (var id in overlayIds!) {
      if (widget.showPressure) {
        lineBarsDataFlows.add(createChartLineDatapoints(data["pressure$id"]!, 4,
            calcColor(theme.ThemeColors.pressureColor, i), null));
        lineBarsDataFlows.add(createChartLineDatapoints(
            data["pressureSet$id"]!,
            2,
            calcColor(
              theme.ThemeColors.pressureColor,
              i,
            ),
            [5, 5]));
      }
      if (widget.showFlow) {
        lineBarsDataFlows.add(createChartLineDatapoints(data["flow$id"]!, 4,
            calcColor(theme.ThemeColors.flowColor, i), null));
        lineBarsDataFlows.add(createChartLineDatapoints(data["flowSet$id"]!, 2,
            calcColor(theme.ThemeColors.flowColor, i), [5, 5]));
        lineBarsDataFlows.add(createChartLineDatapoints(data["flowG$id"]!, 2,
            calcColor(theme.ThemeColors.weightColor, i), null));
      }
      if (widget.showWeight) {
        lineBarsDataTempWeight.add(createChartLineDatapoints(data["weight$id"]!,
            2, calcColor(theme.ThemeColors.weightColor, i), null));
      }
      if (widget.showTemp) {
        lineBarsDataTemp.add(createChartLineDatapoints(data["temp$id"]!, 4,
            calcColor(theme.ThemeColors.tempColor, i), null));
        lineBarsDataTemp.add(createChartLineDatapoints(data["tempSet$id"]!, 2,
            calcColor(theme.ThemeColors.tempColor, i), [5, 5]));
        lineBarsDataTemp.add(createChartLineDatapoints(data["tempMix$id"]!, 4,
            calcColor(theme.ThemeColors.tempColor2, i), null));
        lineBarsDataTemp.add(createChartLineDatapoints(data["tempMixSet$id"]!,
            2, calcColor(theme.ThemeColors.tempColor2, i), [5, 5]));
      }
      i += 0.25;
    }

    var flowChart1 = LineChart(
      LineChartData(
        // minY: 0,
        // maxY: 15,
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataFlows,
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: [
            ...ranges,
          ],
          // horizontalRangeAnnotations: [
          //   HorizontalRangeAnnotation(
          //     y1: 2,
          //     y2: 3,
          //     color: const Color(0xffEEF3FE),
          //   ),
          // ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // bottomTitles: AxisTitles(
          //   sideTitles: SideTitles(showTitles: false),
          // ),
          bottomTitles: !widget.showTemp && !widget.showWeight
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).graphTime,
                    style: Theme.of(context).textTheme.labelSmall,
                    // style: TextStyle(
                    //     // fontSize: 15,
                    //     ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
                )
              : AxisTitles(
                  axisNameSize: 25,
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
                ),
          // bottomTitles: AxisTitles(
          //   axisNameWidget: const Text(
          //     'Time/s',
          //     textAlign: TextAlign.left,
          //     // style: TextStyle(
          //     //     // fontSize: 15,
          //     //     ),
          //   ),
          //   sideTitles: SideTitles(
          //     showTitles: true,
          //     getTitlesWidget: bottomTitleWidgets,
          //     reservedSize: 36,
          //   ),
          // ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).graphFlowMlsPressureBar,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 56,
            ),
          ),
        ),
      ),
    );

    var flowChart2 = LineChart(
      LineChartData(
        // minY: 0,
        // maxY: 15,
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataTempWeight,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: !widget.showTemp
              ? AxisTitles(
                  axisNameSize: 25,
                  axisNameWidget: Text(
                    S.of(context).graphTime,
                    style: Theme.of(context).textTheme.labelSmall,
                    // style: TextStyle(
                    //     // fontSize: 15,
                    //     ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
                )
              : AxisTitles(
                  axisNameSize: 25,
                  sideTitles: SideTitles(
                    showTitles: false,
                    getTitlesWidget: bottomTitleWidgets,
                    reservedSize: 26,
                  ),
                ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).screenEspressoWeightG,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 56,
            ),
          ),
        ),
      ),
    );

    var flowChart3 = LineChart(
      LineChartData(
        // minY: 0,
        // maxY: 15,
        // minX: data["pressure${overlayIds!.first}"]!.first.x,
        // maxX: maxTime,
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: true,
        ),
        lineBarsData: lineBarsDataTemp,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              S.of(context).graphTime,
              style: Theme.of(context).textTheme.labelSmall,
              // style: TextStyle(
              //     // fontSize: 15,
              //     ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: bottomTitleWidgets,
              reservedSize: 26,
            ),
          ),
          show: true,
          leftTitles: AxisTitles(
            axisNameSize: 25,
            axisNameWidget: Text(
              "Temp",
              style: Theme.of(context).textTheme.labelSmall,
            ),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: leftTitleWidgets,
              reservedSize: 56,
            ),
          ),
        ),
      ),
    );

    var height = 300 + 120 + 120;

    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SizedBox(
          //   height: 30,
          //   child: LegendsListWidget(
          //     legends: [
          //       Legend('Pressure', theme.ThemeColors.pressureColor),
          //       Legend('Flow', theme.ThemeColors.flowColor),
          //       Legend('Weight', theme.ThemeColors.weightColor),
          //       Legend('Temp', theme.ThemeColors.tempColor),
          //     ],
          //   ),
          // ),
          if (widget.showFlow || widget.showPressure)
            SizedBox(
                height: height -
                    (widget.showTemp ? 120 : 0) -
                    (widget.showWeight ? 120 : 0),
                child: flowChart1),
          if (widget.showWeight) const SizedBox(height: 20),
          if (widget.showWeight)
            SizedBox(
                height: height -
                    (widget.showFlow || widget.showPressure ? 300 : 0) -
                    (widget.showTemp ? 120 : 0),
                child: flowChart2),
          if (widget.showTemp) const SizedBox(height: 20),
          if (widget.showTemp)
            SizedBox(
                height: height -
                    (widget.showFlow || widget.showPressure ? 300 : 0) -
                    (widget.showWeight ? 120 : 0),
                child: flowChart3),
        ],
      ),
    );
  }

  Color calcColor(Color col, double i) {
    return col.withOpacity(1 - i);
    // return Color.fromRGBO(col.red, col.green, col.blue, col.alpha / 255 - i);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 6,
      child: Text(meta.formattedValue, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(meta.formattedValue, style: style),
    );
  }
}
