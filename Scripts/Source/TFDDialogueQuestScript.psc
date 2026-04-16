Scriptname TFDDialogueQuestScript extends Quest

GlobalVariable Property TFDPayGold Auto

Function RefreshPayText()
	UpdateCurrentInstanceGlobal(TFDPayGold)
EndFunction