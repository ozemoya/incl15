# Science Signal

Flutter science trivia for In-Class Activity 15, Version C2. Built from the supplied C2 starter.

## Run

Run `flutter pub get` and `flutter run` on a connected Android device or emulator. Internet access is required for Open Trivia DB. Run `flutter test` and `flutter analyze` to verify the project.

## What the round does

The Open Trivia DB GET requests five medium Science & Nature true-or-false questions. The starter validates the response code, item count, and decoded fields. The round records one answer per question, shows the result, and calculates the final score from recorded answers. The review shows all five questions with both the selected and correct answers. Replay clears the prior round and issues a new GET.

The score action simulates a submission because no score endpoint was supplied. It shows score, total, and category. The pending state disables repeated submissions, and the completion message explicitly says no request was sent. A real score submission would send a POST or another instructor-specified write request and require a confirming response.

## Verification

The widget test uses a controlled HTTP 503 followed by a valid five-question response to exercise retry. It answers one question incorrectly and four correctly, verifies 4/5, and exercises simulation and replay. See the submission evidence for the device captures. Codex assisted with implementation and testing.
