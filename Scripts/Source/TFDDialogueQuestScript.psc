Scriptname TFDDialogueQuestScript extends Quest

GlobalVariable Property TFDPayGold Auto

Function RefreshPayText()
    Debug.Notification("RefreshPayText: " + TFDPayGold.GetValueInt())
    UpdateCurrentInstanceGlobal(TFDPayGold)
EndFunction