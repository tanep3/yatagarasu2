# Canonical design contracts

このディレクトリは、実装から参照される型、所有者、Rule、Transition、Effect、Port、Failure、Recoveryの唯一の正式定義を置きます。

縦断sliceやscenarioは、このディレクトリのDesign IDを参照し、payloadや不変条件を再定義しません。

- [共通Effect実行・結果取込・Recovery接続](execution.md)
- [共通Presentation値](presentation.md)
- [カメラ移動・撮影・画像解釈](camera-observation.md)
- [有限Conversation・外部Thread・SemanticMemory](finite-conversation.md)
