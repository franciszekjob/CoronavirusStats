import 'dart:convert';
import 'package:coronavirus/components/app_bar.dart';
import 'package:coronavirus/loading_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TotalStats {
  List<RegionStats> regionsStatsList;
  final int infected;
  final int deceased;

  TotalStats({this.regionsStatsList,this.infected, this.deceased});

  factory TotalStats.fromJson(Map<String, dynamic> json) {
    Iterable regionList = json['infectedByRegion'];
    List<RegionStats> regionsStats = regionList.map((i) => 
      RegionStats.fromJson(i)).toList();
      return TotalStats(
        regionsStatsList: regionsStats,
        infected: json['infected'],
        deceased: json['deceased'],
    );
  }
}

class RegionStats {
  final String region;
  final int infectedCount;
  final int deceasedCount;

  RegionStats({this.region, this.infectedCount, this.deceasedCount});

  factory RegionStats.fromJson(Map<String, dynamic> json) {
    return RegionStats(
      region: json['region'],
      infectedCount: json['infectedCount'],
      deceasedCount: json['deceasedCount'],
    );
  }
}

class Stats extends StatefulWidget {
  @override
  _StatsState createState() => _StatsState();
}

class _StatsState extends State<Stats> {
  Future<TotalStats> futureData;

  Future<TotalStats> getData() async {
    final response =
        await http.get('https://api.apify.com/v2/key-value-stores/3Po6TV7wTht4vIEid/records/LATEST?disableRedirect=true');
  //       await http.get('https://covid-19-coronavirus-statistics.p.rapidapi.com/v1/stats?country=Poland',headers: {
	// 	"x-rapidapi-host": "covid-19-coronavirus-statistics.p.rapidapi.com",
	// 	"x-rapidapi-key": "3365d0197amsha3584a952c169f8p1094d0jsn85d8b8022cd8"
	// });
    return TotalStats.fromJson(json.decode(response.body));
  }

  @override
  void initState() {
    super.initState();
    futureData = getData();
  }

  Future<TotalStats> _refresh() {
  futureData = getData();
  return getData();
  
}

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
    new GlobalKey<RefreshIndicatorState>();

  TextStyle columnText = TextStyle(fontSize: 14,fontWeight: FontWeight.w500);

  @override
  Widget build(BuildContext context) {

    showAlertDialog(BuildContext context,region,infectedCount,deceasedCount) {

  // set up the button
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () { 
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    
    titlePadding: EdgeInsets.zero,
    contentPadding: EdgeInsets.all(10),
    title: Container(
      decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xff2B5E80),
                    Color(0xff5BAFE7),
                  ])
                ),
      child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          Image.asset('assets/virus.png',width: 35,),
                  SizedBox(width: 5,),
          Text("Województwo "+region,style: TextStyle(color: Colors.white),),
        ],
      ),
    )),
    content: 
        Container(
          height: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text("Zarażenia: "+infectedCount.toString()),
              Text("Zgony: "+deceasedCount.toString()),
            ],
          ),
        ),
      
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

    return FutureBuilder(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<RegionStats> data = snapshot.data.regionsStatsList;
          List<DataRow> rows = [
            DataRow(cells: <DataCell>[
              DataCell(Text('Łącznie',style: TextStyle(color: Colors.red[400]),)
              ),
              DataCell(Text(snapshot.data.infected.toString(),style: TextStyle(color: Colors.red[400]),),),
              DataCell(Text(snapshot.data.deceased.toString(),style: TextStyle(color: Colors.red[400]),)),
            ])
          ];
          for(var i = 0;i<data.length;i++){
            rows.add(DataRow(cells: <DataCell>[
              DataCell(
                Text(data[i].region[0].toUpperCase()+data[i].region.substring(1),style: TextStyle(fontWeight: FontWeight.w600),),
                ),
              DataCell(Text(data[i].infectedCount.toString(),),
              onTap: (){
                showAlertDialog(context,data[i].region[0].toUpperCase()+data[i].region.substring(1),data[i].infectedCount,data[i].deceasedCount);
              }
              ),
              DataCell(Text(data[i].deceasedCount.toString(),)),
            ]));
          }

          

          return Scaffold(
            appBar: appBar,
            body: RefreshIndicator(
               key: _refreshIndicatorKey,
               onRefresh: _refresh,
              child: SingleChildScrollView(
                child: Container(
                  child: DataTable(
                    columns: <DataColumn>[
                      DataColumn(
                        label: Text('Województwo',style: columnText,)),
                      DataColumn(label: Text('Zarażenia',style: columnText)
                      ),
                      DataColumn(label: Text('Zgony',style: columnText)),
                    ],
                    rows: rows
                  ),

                ),
              ),
            )
          );
        }

        return LoadingScreen();
      },
    );
  }
}