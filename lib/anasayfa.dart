import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:proje1/sayfa2.dart';
import 'package:proje1/main.dart';

void main() => runApp(proje());

class proje extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String mongoUri = '**************';
  late mongo.Db db;
  late mongo.DbCollection collection;
  List<Map<String, dynamic>> documents = [];
  bool isConnected = false;
  List<Map<String, dynamic>> aggregatedData = [];
  


  @override
  void initState() {
    super.initState();
    connectToMongo();
  }

  Future<void> connectToMongo() async {
    db = mongo.Db(mongoUri);
    try {
      await db.open();
      print('MongoDB baglantisi acildi.');
      setState(() {
        isConnected = true;
      });
      collection = db.collection('nvr_collector');
      await fetchAggregatedData();
    } catch (e) {
      print('MongoDB bağlanti hatasi: $e');
      setState(() {
        isConnected = false;
      });
    }
  }

  Future<void> fetchAggregatedData() async {
    try {
      final pipeline = [
        {
          '\$sort': {
            'timestamp': -1 // timestamp alanina göre azalan sirayla siralama
          }
        },
        {
          '\$group': {
            '_id': '\$hostInfo.hostname',
            'count': {'\$sum': 1},
            'os': {'\$first': '\$hostInfo.os'},
            'osversion': {'\$first': '\$hostInfo.osversion'},
            'arch': {'\$first': '\$hostInfo.arch'},
            'roles': {'\$first': '\$roles.roles'},
            'timestamp': {'\$first': '\$timestamp'},
            'consulNodeInfosArray': {
              '\$first': {
                '\$objectToArray': '\$consulNodeInfos.consulNodeInfos'
              }
            },
          
            'cameraHealthInfos': {
              '\$first': '\$cameraHealthInfos.camhealthinfos'
            }
          

          },
        },
      ];

      final result = await collection.aggregateToStream(pipeline).toList();
      setState(() {
        aggregatedData = result;
      });
    } catch (e) {
      print('Error fetching aggregated data: $e');
    }
  }

  @override
  void dispose() {
    db.close();
    print('Database bağlantisi kapatildi.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => anasayfa()),
            );
          },
        ),
        title: Text('MongoDB Veri Görüntüleme'),
      ),
      body: isConnected
          ? (aggregatedData.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: aggregatedData.length,
                  itemBuilder: (context, index) {
                    final sortedData = [...aggregatedData];
                    sortedData.sort((a, b) => a['_id'].compareTo(b['_id']));
                    final item = sortedData[index];

                    final hostname = item['_id'];
                    final count = item['count'];
                    final os = item['os'];
                    final osversion = item['osversion'];
                    final arch = item['arch'];
                    final roles = item['roles'];
                    final timestamp = item['timestamp'];

                    // 30 dakika önce veri gönderme aşaması
                    final currentTime = DateTime.now().millisecondsSinceEpoch;   //1 ocak 1970 ten itibaren geçen süreyi milisaniye cinsinden hesaplar 
                    final timestampInt = int.tryParse(timestamp) ?? 0; //timestampi inte çevirme işlemi     hata döndürürse .toString() ekleyecez
                    final timeDifference = currentTime - timestampInt;  // güncel zaman ile timestamp arasındaki farkı hesaplar
                    final isActive = timeDifference <= 30 * 60 * 1000; // 30 dakikayı milisaniyeye çevirme   *60saniyeye  *1000 milisaniyeye dönüştürür
         
                    // Version
                    List<String> versions = [];
                    if (item['consulNodeInfosArray'] != null) {
                      for (var info in item['consulNodeInfosArray']) {   // info adında geçici bi değişken atadık  sırayla tüm dizi ögelerini atıyoruz
                        if (info['v'] != null && info['v']['version'] != null) {   
                          versions.add(info['v']['version']);
                         
                        }
                       
                      }
                    }
                    //IP ADRESS
                    List<String> ipAddress = [];
                    if (item['consulNodeInfosArray'] != null) {
                      for (var infoo in item['consulNodeInfosArray']) {   // infoo adında geçici bi değişken atadık  sırayla tüm dizi ögelerini atıyoruz
                        if (infoo['v'] != null && 
                        infoo['v']['node']['endpoint']['ipAddress'] != null
                        ) 
                        {   
                          ipAddress.add(infoo['v']['node']['endpoint']['ipAddress']);       
                          //print('$infoo')     // k  ve v den oluşan dizi oluşturuyor object üstte        
                        }
                      }
                    }






  
                  // Kamera durumu
                 var camHealthInfos = item['cameraHealthInfos'];
int activeCount = 0;
int inactiveCount = 0;
List<String> camhata = [];
List<String> camcalisan = [];


if (camHealthInfos != null) {
  camHealthInfos.forEach((key, camInfo) {
    var status = camInfo['status'];
    var recordStatus = camInfo['recordstatus'];

    // Status ve recordStatus içindeki null olmayan değerleri alarak ekrana yazdır  
    if (status != null && status['status'] != null && status['status'].isNotEmpty) {
       camhata.add('Camera $key Status: ${status['status']} ${status['reasons']}');
    }
    else {
      camcalisan.add('Camera $key Status: ${status['status']} ${status['reasons']}');
    }
    // print(camcalisan);
    //null değilse hata mesajını yazdırıcak 
    if (recordStatus != null && recordStatus['status'] != null && recordStatus['status'].isNotEmpty) {
      camhata.add('Camera $key Record Status: ${recordStatus['status']} ${recordStatus['reasons']}');
    }
     else {
      camcalisan.add('Camera $key Record Status: ${recordStatus['status']} ${recordStatus['reasons']}');
    }
    // print(camhata);

//aktif inaktif kamera sayısı
    var isCaminActive = (status != null && status['status'] != null && status['status'].isNotEmpty) ||
                        (recordStatus != null && recordStatus['status'] != null && recordStatus['status'].isNotEmpty);

    if (isCaminActive) {
      inactiveCount++;
    } else {
      activeCount++;
    }
  });
}


                    return Column(
                      children: [
                        ListTile(
                          title: Text('Hostname: $hostname'),
                          tileColor: Colors.blue,
                          subtitle: Text('Adet: $count'),
                        ),
                        Text('OS: $os'),
                        Text('OS Version: $osversion'),
                        Text('Architecture: $arch'),
                        Text('Roles: $roles'),
                        Text('Timestamp: $timestamp'),
                        Text('Versions: ${versions.join(', ')}'),
                        Text('ipAdres: ${ipAddress.join(', ')}' ),
                        Text('Status: ${isActive ? "Active" : "Inactive"}', style: TextStyle(
    color: isActive ? Colors.green : Colors.red,
  ),),

                        Container(
                          color: const Color.fromARGB(255, 141, 141, 141),
                          child: Column(
                            children: [
                          Text('Total Cameras: ${camHealthInfos?.length ?? 0}'),                    
                          Text('Active Cameras: $activeCount'),                  
                          GestureDetector(onTap: () {Navigator.push(context, MaterialPageRoute(builder: (context) => ErrorPage(camErrors: camhata),
                    ),
            );                       
  },
                            child: Text('Inactive Cameras: $inactiveCount'),
                            ),                                   
                          ],  
                          ),
                        ),
                    ],
                    );
                  },
                ))
          : Center(
              child: Text(
                'Baglanti Hatasi',
                style: TextStyle(fontSize: 24),
              ),
            ),
    );
  }
}
