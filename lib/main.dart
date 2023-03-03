import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gpt3.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GPT3Example(),
    );
  }
}

class GPT3Example extends StatefulWidget {
  @override
  _GPT3ExampleState createState() => _GPT3ExampleState();
}

class _GPT3ExampleState extends State<GPT3Example> {
  late GPT3 gpt3;
  late String apiKey = '';
  late String generatedText;
  bool isShowSendbutton = true;
  final _apiKeyController = TextEditingController();
  final _chatInputController = TextEditingController();
  final List<ChatMessage> _chatMessages = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadChatMessages();
    generatedText = '';
  }

  void _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('apiKey');
    if (apiKey != null) {
      setState(() {
        this.apiKey = apiKey;
        gpt3 = GPT3(apiKey: apiKey);
      });
    }
  }

  void _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = _apiKeyController.text;
      gpt3 = GPT3(apiKey: apiKey);
      prefs.setString('apiKey', apiKey);
    });
  }

  void _saveChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final chatMessages = _chatMessages.map((message) => message.text).toList();
    prefs.setStringList('chatMessages', chatMessages);
  }

  void _loadChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final chatMessages = prefs.getStringList('chatMessages');
    if (chatMessages != null) {
      setState(() {
        _chatMessages.clear();
        final userMessages = <ChatMessage>[];
        final responseMessages = <ChatMessage>[];
        for (final messageText in chatMessages) {
          final message = ChatMessage(text: messageText);
          if (message.isUserMessage) {
            userMessages.add(message);
          } else {
            responseMessages.add(message);
          }
        }
        for (var i = 0; i < userMessages.length; i++) {
          _chatMessages.add(userMessages[i]);
          if (i < responseMessages.length) {
            _chatMessages.add(responseMessages[i]);
          }
        }
      });
      // Scroll to the bottom of the list after adding a new message
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } else {
      setState(() {
        _chatMessages.clear(); // clear chat messages if no saved messages
      });
    }
  }

  void _addChatMessage(ChatMessage message) {
    setState(() {
      _chatMessages.add(message);
    });
    _saveChatMessages(); // save chat messages
  }

  void _handleSubmitted() async {
    // Scroll to the bottom of the list after adding a new message
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    final userMessage = _chatInputController.text;
    final userMessageChatMessage =
        ChatMessage(text: userMessage, isUserMessage: true);
    _addChatMessage(userMessageChatMessage);

    isShowSendbutton = false;
    final response = await gpt3.generateText('User: $userMessage');
    final responseChatMessage = ChatMessage(text: response);
    _addChatMessage(responseChatMessage);

    _chatInputController.clear();
    _saveChatMessages();
    isShowSendbutton = true;
    //

    // Scroll to the bottom of the list after adding a new message
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildChatBubble(ChatMessage message) {
    return GestureDetector(
      onLongPress: () async {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Copy or share message?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'Copy'),
                child: Text('Copy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'Share'),
                child: Text('Share'),
              ),
            ],
          ),
        );
        if (action == 'Copy') {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Message copied'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(milliseconds: 250)),
          );
        } else if (action == 'Share') {
          Share.share(message.text);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: message.isUserMessage ? Colors.blue[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message.text,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (apiKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('GPT-3 Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'API Key',
                ),
                onChanged: (value) => apiKey = value,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveApiKey,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text('GPT-3 Example'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.remove('apiKey');
                setState(() {
                  apiKey = '';
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  return _buildChatBubble(_chatMessages[index]);
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: generatedText.isNotEmpty || isShowSendbutton
                        ? () => _handleSubmitted()
                        : null, // disable the button if there is no response message yet
                    child: Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}

class ChatMessage {
  final String text;
  final bool isUserMessage;

  ChatMessage({required this.text, this.isUserMessage = false});
}
