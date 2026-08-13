# Canonical design contracts

このディレクトリは、実装から参照される型、所有者、Rule、Transition、Effect、Port、Failure、Recoveryの唯一の正式定義を置きます。

縦断sliceやscenarioは、このディレクトリのDesign IDを参照し、payloadや不変条件を再定義しません。

- [共通Effect実行・結果取込・Recovery接続](execution.md)
- [Execution schema v2 Acoustic extension](execution-acoustic-v2.md)
- [Execution Revision 3](execution-revision-3.md)
- [共通Presentation値](presentation.md)
- [カメラ移動・撮影・画像解釈](camera-observation.md)
- [有限Conversation・外部Thread・SemanticMemory](finite-conversation.md)
- [一wake一命令・自己音声・再生中Stop抑止](acoustic-interaction.md)
- [設定文書・適用・権限](configuration-application.md)
- [Runtime binding・Profile・readiness](runtime-binding.md)
- [Behavior・推論route Policy](routing-policy.md)
- [Runtime restart・Workspace migration](migration-and-restart.md)
