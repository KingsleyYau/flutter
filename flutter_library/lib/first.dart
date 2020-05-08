import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'second.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Main'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _biggerFont = const TextStyle(fontSize: 10.0);

  final _suggestionList = <WordPair>[];
  final _favouriteList = new Set<WordPair>();
  static const platform = const MethodChannel('samples.flutter.dev/goToNativePage');

  bool _loading = false;
  Timer _addTimer;
  Timer _refreshTimer;

  void _add() {
    print('_add(), loading:' + _loading.toString() + ', count:' + _suggestionList.length.toString());

    if ( !_loading ) {
      _loading = true;
      _addTimer = Timer(Duration(seconds: 3), () {
        _suggestionList.addAll(generateWordPairs().take(10));

        setState(() {
          _loading = false;
        });
      });
    }
  }

  void _refresh() {
    print('_refresh(), loading:' + _loading.toString());

    if ( !_loading ) {
      _suggestionList.clear();
      _favouriteList.clear();
      _loading = true;

      setState(() {
        _refreshTimer = Timer(Duration(seconds: 3), () {
          _suggestionList.addAll(generateWordPairs().take(10));
          setState(() {
            _loading = false;
          });
        });
      });
    }
  }

  void _pushSaved() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new SecondPage(favouriteList: _favouriteList);
        },
      ),
    );
  }

  Future<void> _popNative() async {
    try {
      runApp(Center());
      final int result = await platform
          .invokeMethod('goToNativePage', {'param': '_MyHomePageState::_popNative()'});
    } on PlatformException catch (e) {
    }
  }

  @override
  void initState() {
    super.initState();
    print('_MyHomePageState::initState()');
    _add();
  }

  @override
  void deactivate() {
    super.deactivate();
    print('_MyHomePageState::deactivate()');
  }

  @override
  void dispose() {
    super.dispose();
    print('_MyHomePageState::dispose()');
    _addTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        leading:new IconButton(icon: new Icon(Icons.arrow_back_ios), onPressed: _popNative),
        title: Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.refresh), onPressed: _refresh),
          new IconButton(icon: new Icon(Icons.list), onPressed: _pushSaved),
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          children: <Widget>[
            Container(
              padding: (_suggestionList.length == 0)?const EdgeInsets.fromLTRB(0, 10, 0, 0):EdgeInsets.all(0),
              child: (_suggestionList.length == 0)?CircularProgressIndicator(strokeWidth: 2.0):Center()//Text('We move under cover and we move as one'),
            ),
            Expanded(
              child: _buildSuggestions(),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        tooltip: 'Refresh',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildRow(int index, WordPair pair) {
    final alreadySaved = _favouriteList.contains(pair);
    return Container(
      child:ListTile(
      leading: Image.asset(
          'images/1.png', fit:BoxFit.contain
      ),
      title: new Text(
        index.toString() + ':' + pair.asPascalCase,
//        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _favouriteList.remove(pair);
          } else {
            _favouriteList.add(pair);
          }
        });
      },
    )
    );
  }

  Widget _buildSuggestions() {
    return new ListView.builder(
        itemCount: _suggestionList.length * 2,
//        itemExtent: 30,
        itemBuilder: (context, i) {
          print('_buildSuggestions(), i:' + i.toString() + ', count:' + (_suggestionList.length * 2).toString() );

          if (i < _suggestionList.length * 2 - 1)   {
            // 语法 "i ~/ 2" 表示i除以2，但返回值是整形（向下取整），比如i为：1, 2, 3, 4, 5
            // 时，结果为0, 1, 1, 2, 2， 这可以计算出ListView中减去分隔线后的实际单词对数量
            final index = i ~/ 2;

            if (i.isOdd) {
              // 在每一列之前，添加一个1像素高的分隔线widget
              return Divider(height:1.0);
            } else {
              return _buildRow(index, _suggestionList[index]);
            }
          } else {
            if ( _suggestionList.length < 100 ) {
              _add();
              return Column(
                children: <Widget>[
                  Divider(height:1.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child:CircularProgressIndicator(strokeWidth: 2.0),
                  )
                ],
              );
            } else {
              return Column(
                children: <Widget>[
                  Divider(height:1.0),
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child:Text("No More", style: TextStyle(color: Colors.grey),)
                  )
                ],
              );
            }
          }
        }
    );
  }
}
