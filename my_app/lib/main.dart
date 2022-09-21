// ignore: duplicate_ignore
// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors, duplicate_ignores

import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


// 更新可能なデータ
class UserState extends ChangeNotifier {
  User? user;

  void setUser(User newUser) {
    user = newUser;
    notifyListeners();
  }
}

void main() async {
  // 最初に表示するWidget
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ChatApp());
}

// ignore: use_key_in_widget_constructors
class ChatApp extends StatelessWidget {
  // ユーザーの情報を管理するデータ
  final UserState userState = UserState();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserState>(
      create: (context) => UserState(),
      child: MaterialApp(
        // アプリ名
        title: 'ChatApp',
        theme: ThemeData(
          // テーマカラー
          primarySwatch: Colors.blue,
        ),
        // ログイン画面を表示
        home: LoginPage(),
      ),
    );
  }
}

// ログイン画面用Widget
// ignore: use_key_in_widget_constructors
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 149, 196, 214), // 背景色設定
      appBar: AppBar(
        title: const Text('Welcome to Carrot and Stick'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_oygnve11.json',
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(),
                  );
                },
              ),

              // メールアドレス入力
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'メールアドレス', border: OutlineInputBorder()),
                  onChanged: (String value) {
                    setState(() {
                      email = value;
                    });
                  },
                ),
              ),
              // パスワード入力
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'パスワード', border: OutlineInputBorder()),
                  obscureText: true,
                  onChanged: (String value) {
                    setState(() {
                      password = value;
                    });
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              SizedBox(
                width: double.infinity,
                // ユーザー登録ボタン
                child: ElevatedButton(
                  child: const Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      // ユーザー情報を更新
                      userState.setUser(result.user!);
                      // ユーザー登録に成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      // ignore: use_build_context_synchronously
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      setState(() {
                        infoText = "登録に失敗しました：${e.toString()}";
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                // ログイン登録ボタン
                child: OutlinedButton(
                  child: const Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      // ユーザー情報を更新
                      userState.setUser(result.user!);
                      // ログインに成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      // ignore: use_build_context_synchronously
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage();
                        }),
                      );
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインに失敗しました：${e.toString()}";
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// チャット画面用Widget
class ChatPage extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  ChatPage();
  final myId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;
    final ButtonStyle style =
        ElevatedButton.styleFrom(textStyle: const TextStyle(fontSize: 20));

    return Scaffold(
      appBar: AppBar(
        title: const Text('みんなの目標'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // ログアウト処理
              // 内部で保持しているログイン情報等が初期化される
              // （現時点ではログアウト時はこの処理を呼び出せばOKと、思うぐらいで大丈夫です）
              await FirebaseAuth.instance.signOut();
              // ログイン画面に遷移＋チャット画面を破棄
              // ignore: use_build_context_synchronously
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Text('ログイン情報：${user.email}'),
          ),
          Expanded(
            // Stream
            // 非同期処理の結果を元にWidgetを作れる
            child: StreamBuilder<QuerySnapshot>(
              // 投稿メッセージ一覧を取得（非同期処理）
              // 投稿日時でソート
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('date')
                  .snapshots(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  // 取得した投稿メッセージ一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {
                      return Card(
                        child: ListTile(
                          title: Text(document['text']),
                          subtitle: Text(
                              document['email'] + ' , ' + document['date']),
                        ),
                      );
                    }).toList(),
                  );
                }
                // データが読込中の場合
                // ignore: prefer_const_constructors
                return Center(
                  child: const Text('読込中...'),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                width: 330,
                height: 100,
                child: ElevatedButton(
                  style: style,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {
                        return TargetPostPage();
                      }),
                    );
                  },
                  child: const Text('目標書込'),
                ),
              ),
              SizedBox(
                width: 330,
                height: 100,
                child: ElevatedButton(
                  style: style,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) {
                        return AchievementPostPage();
                      }),
                    );
                  },
                  child: const Text('達成書込'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 目標書込画面用Widget
class TargetPostPage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  TargetPostPage();

  @override
  _TargetPostPageState createState() => _TargetPostPageState();
}

class _TargetPostPageState extends State<TargetPostPage> {
  // 入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('目標投稿'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // 投稿メッセージ入力

              Expanded(
                // Stream
                // 非同期処理の結果を元にWidgetを作れる
                child: StreamBuilder<QuerySnapshot>(
                  // 本人の投稿メッセージ一覧を取得（非同期処理）
                  // 投稿日時でソート
                  stream: FirebaseFirestore.instance
                      .collectionGroup('posts')
                      .where('email', isEqualTo: user.email)
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    // データが取得できた場合
                    if (snapshot.hasData) {
                      final List<DocumentSnapshot> documents =
                          snapshot.data!.docs;
                      // 取得した投稿メッセージ一覧を元にリスト表示
                      return ListView(
                        children: documents.map((document) {
                          return Card(
                            child: ListTile(
                              title: Text(document['text']),
                              subtitle: Text(
                                  document['email'] + ' , ' + document['date']),
                              // 自分の投稿メッセージの場合は削除ボタンを表示
                              trailing: document['email'] == user.email
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        // 投稿メッセージのドキュメントを削除
                                        await FirebaseFirestore.instance
                                            .collection('posts')
                                            .doc(document.id)
                                            .delete();
                                      },
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    }

                    // データが読込中の場合
                    return const Center(
                      child: Text('読込中...'),
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: '目標'),
                    // 複数行のテキスト入力
                    keyboardType: TextInputType.multiline,
                    // 最大3行
                    maxLines: 3,
                    onChanged: (String value) {
                      setState(() {
                        messageText = value;
                      });
                    },
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            child: const Text('設定'),
                            onPressed: () async {
                              final date = DateTime.now()
                                  .toLocal()
                                  .toIso8601String(); // 現在の日時
                              final email = user.email; // AddPostPage のデータを参照
                              // 投稿メッセージ用ドキュメント作成
                              await FirebaseFirestore.instance
                                  .collection('posts') // コレクションID指定
                                  .doc() // ドキュメントID自動生成
                                  .set({
                                'text': messageText,
                                'email': email,
                                'date': date
                              });
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          height: 50,
                          child: ElevatedButton(
                            child: const Text('勉強時間'),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) {
                                  return const TimerPickerApp();
                                }),
                              );
                            },
                          ),
                        ),
                      ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 達成書込画面用Widget
class AchievementPostPage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  AchievementPostPage();

  @override
  _AchievementPostPageState createState() => _AchievementPostPageState();
}

class _AchievementPostPageState extends State<AchievementPostPage> {
  // 入力した投稿メッセージ
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    // ユーザー情報を受け取る
    final UserState userState = Provider.of<UserState>(context);
    final User user = userState.user!;

    // Line通知
    Future<void> _request(mg) async{
      String _content = '';
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer {}'
      };
      String body = json.encode({"messages":[{"type":"text","text":mg},{"type":"text","text":"やっふぃー"}]});
      
      final url = Uri.parse("https://api.line.me/v2/bot/message/broadcast");

      final response = await http.post(url, headers: headers, body: body);
      print(response.body);
      print(response.statusCode);

      //var url = Uri.https('https://api.line.me/v2/bot/message/broadcast','');
      //print(url);
      
      //var resp = http.post(url, headers: headers, body: body);
      /*
      if (resp.statusCode != 200) {
        setState(() {
          int statusCode = resp.statusCode;
          _content = "Failed to post $statusCode";
        });
        return;
      }
      setState(() {
        _content = resp.body;
      });
      */
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('達成更新'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                // Stream
                // 非同期処理の結果を元にWidgetを作れる
                child: StreamBuilder<QuerySnapshot>(
                  // 投稿メッセージ一覧を取得（非同期処理）
                  // 投稿日時でソート
                  stream: FirebaseFirestore.instance
                      .collectionGroup('posts')
                      .where('email', isEqualTo: user.email)
                      .orderBy('date')
                      .snapshots(),
                  builder: (context, snapshot) {
                    // データが取得できた場合
                    if (snapshot.hasData) {
                      final List<DocumentSnapshot> documents =
                          snapshot.data!.docs;
                      // 取得した投稿メッセージ一覧を元にリスト表示
                      return ListView(
                        children: documents.map((document) {
                          return Card(
                            child: ListTile(
                              title: Text(document['text']),
                              subtitle: Text(
                                  document['email'] + ' , ' + document['date']),
                              // 自分の投稿メッセージの場合はプラスボタンを表示
                              trailing: document['email'] == user.email
                                  ? IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: () async {
                                        final date = DateTime.now()
                                            .toLocal()
                                            .toIso8601String(); // 現在の日時
                                        final email =
                                            user.email; // AddPostPage のデータを参照
                                        var message = document['text'] + ':' + messageText;

                                        _request(message);

                                        // 投稿メッセージ用ドキュメント作成
                                        await FirebaseFirestore.instance
                                            .collection('posts') // コレクションID指定
                                            .doc(document.id) // ドキュメントIDの紐づけ
                                            .update({
                                          'text': message,
                                          'email': email,
                                          'date': date
                                        });

                                        // メッセージ送信
                                        //await _request(message);

                                        // ignore: use_build_context_synchronously
                                        Navigator.of(context).pop();
                                      })
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    }
                    // データが読込中の場合
                    return const Center(
                      child: Text('読込中...'),
                    );
                  },
                ),
              ),

              // 投稿メッセージ入力
              TextFormField(
                decoration: const InputDecoration(labelText: '達成'),
                // 複数行のテキスト入力
                keyboardType: TextInputType.multiline,
                // 最大3行
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    messageText = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimerPickerApp extends StatelessWidget {
  const TimerPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: TimerPickerExample(),
    );
  }
}

class TimerPickerExample extends StatefulWidget {
  const TimerPickerExample({super.key});

  @override
  State<TimerPickerExample> createState() => _TimerPickerExampleState();
}

class _TimerPickerExampleState extends State<TimerPickerExample> {
  Duration duration = const Duration(hours: 1, minutes: 0, seconds: 0);

  // This shows a CupertinoModalPopup with a reasonable fixed height which hosts CupertinoTimerPicker.
  void _showDialog(Widget child) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              // The Bottom margin is provided to align the popup above the system navigation bar.
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              // Provide a background color for the popup.
              color: CupertinoColors.systemBackground.resolveFrom(context),
              // Use a SafeArea widget to avoid system overlaps.
              child: SafeArea(
                top: false,
                child: child,
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('勉強時間設定画面'),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: CupertinoColors.label.resolveFrom(context),
          fontSize: 22.0,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _TimerPickerItem(
                children: <Widget>[
                  const Text('Timer'),
                  CupertinoButton(
                    // Display a CupertinoTimerPicker with hour/minute mode.
                    onPressed: () => _showDialog(
                      CupertinoTimerPicker(
                        mode: CupertinoTimerPickerMode.hm,
                        initialTimerDuration: duration,
                        // This is called when the user changes the timer duration.
                        onTimerDurationChanged: (Duration newDuration) {
                          setState(() => duration = newDuration);
                        },
                      ),
                    ),
                    // In this example, the timer value is formatted manually. You can use intl package
                    // to format the value based on user's locale settings.
                    child: Text(
                      '$duration',
                      style: const TextStyle(
                        fontSize: 22.0,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  SizedBox(
                    width: 330,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                      child: const Text('時間決定'),
                    ),
                  ),
                  SizedBox(
                    width: 330,
                    height: 100,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                      },
                      child: const Text('キャンセル'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// This class simply decorates a row of widgets.
class _TimerPickerItem extends StatelessWidget {
  const _TimerPickerItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
          bottom: BorderSide(
            color: CupertinoColors.inactiveGray,
            width: 0.0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: children,
        ),
      ),
    );
  }
}
