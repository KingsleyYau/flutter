import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';

class SecondPage extends StatefulWidget {
  SecondPage({Key key, @required this.favouriteList}) : super(key: key);

  final Set<WordPair> favouriteList;

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final _biggerFont = const TextStyle(fontSize: 18.0);

  @override
  void initState() {
    super.initState();
    print('_SecondPageState::initState()');
  }

  @override
  void deactivate() {
    super.deactivate();
    print('_SecondPageState::deactivate()');
  }

  @override
  void dispose() {
    super.dispose();
    print('_SecondPageState::dispose()');
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final tiles = widget.favouriteList.map(
      (pair) {
        return new ListTile(
          leading: new Image.asset(
              'images/1.png', fit:BoxFit.contain
          ),
          title: Text(
            pair.asPascalCase,
            style: _biggerFont,
          ),
          trailing: IconButton(
            icon: Icon(
                Icons.favorite,
            ),
            color: Colors.red,
            highlightColor: Colors.red,
            onPressed: () {
              setState(() {
                widget.favouriteList.remove(pair);
              });
            },
          ),
          onTap: () {
            setState(() {
            });
          },
        );
      },
    );
    final divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Favourite'),
      ),
      body: Container(
//          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child:new ListView(children: divided)
      ),
    );
  }
}
