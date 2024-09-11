import 'dart:io';

import 'package:github/github.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:televerse/telegram.dart';
import 'package:televerse/televerse.dart';

final aiModel = Platform.environment['OPENAI_MODEL']!;
final repositorySlug =
    RepositorySlug.full(Platform.environment['GITHUB_REPOSITORY']!);

final openaiKey = Platform.environment['OPENAI_API_KEY']!;
final openaiBaseUrl = Platform.environment['OPENAI_BASE_URL'] ?? 'https://api.openai.com/v1';

final botUsername = Platform.environment['TELEGRAM_BOT_USERNAME']!;
final botToken = Platform.environment['TELEGRAM_BOT_TOKEN']!;

final githubAuth =
    Authentication.withToken(Platform.environment['GITHUB_TOKEN']!);

final chats = <int, List<Message>>{};

void main() async {
  final github = GitHub(auth: githubAuth);

  final mistral = ChatOpenAI(
    apiKey: openaiKey,
    baseUrl: openaiBaseUrl,
    defaultOptions: ChatOpenAIOptions(
      model: aiModel,
      responseFormat: ChatOpenAIResponseFormat.jsonSchema(
        ChatOpenAIJsonSchema(
          name: 'issue',
          schema: {
            "type": "object",
            "properties": {
              "title": {"type": "string"},
              "body": {"type": "string"},
              "labels": {
                "type": "array",
                "items": {"type": "string"}
              },
              "assignee": {
                "type": ["string", "null"]
              }
            },
            "required": ["title", "body", "labels", "assignee"],
            "additionalProperties": false
          },
          strict: true,
        ),
      ),
    ),
  );

  final template =
      await ChatPromptTemplate.fromTemplateFile('assets/prompt.md');

  final bot = Bot(botToken)
    ..onMessage((Context context) async {
      if (context.message == null) return;
      final message = context.message!;

      if (message.text?.contains('@$botUsername') == true) {
        // Include only last 10 messages from the chat.
        // TODO: Make it include all the recent messages when the interval between them is less than 30 minutes.
        final chatHistory =
            chats[message.chat.id]?.reversed.take(20).toList().reversed;

        if (chatHistory == null || chatHistory.isEmpty) {
          await context.reply('No chat history found.');
          return;
        }

        final withoutUsernames = [
          for (final message in chatHistory)
            if (message.from?.username == null)
              '${message.from?.firstName} ${message.from?.lastName}'
        ];

        if (withoutUsernames.isNotEmpty) {
          await context.reply(
            'Chat history includes messages from users without usernames: ${withoutUsernames.join(', ')}. '
            'Please remind all users to set their usernames as they appear on GitHub.',
          );
          return;
        }

        await context.sendTyping();

        final labels = await github.issues.listLabels(repositorySlug).toList();

        final prompt = template.formatPrompt({
          'labels': [for (final label in labels) '"${label.name}"'].join(', '),
          'chat_history': [
            for (final chatMessage in chatHistory)
              '- "${chatMessage.from?.username}": ${chatMessage.text}'
          ].join('\n'),
        });

        final json =
            await JsonOutputParser().invoke(await mistral.invoke(prompt));

        final issue = await github.issues.create(
          repositorySlug,
          IssueRequest.fromJson(json),
        );

        await context.reply(
          'Issue [${issue.title}](${issue.htmlUrl}) #${issue.number} created successfully.',
          parseMode: ParseMode.markdown,
        );

        return;
      }

      print('Message recorded');
      chats.putIfAbsent(message.chat.id, () => <Message>[]).add(message);
    });

  await bot.start();
}
