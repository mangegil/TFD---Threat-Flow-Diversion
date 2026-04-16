Scriptname TFDDialogueQuestScript extends Quest

GlobalVariable Property TFDPayGold Auto

Int CurrentQuoteAmount = 0
String CurrentQuoteContext = ""

Event OnInit()
	RegisterPayEvents()
	RefreshPayTextFromShared()
EndEvent

Event OnPlayerLoadGame()
	RegisterPayEvents()
	RefreshPayTextFromShared()
EndEvent

Function RegisterPayEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDPayQuoteUpdate", "OnPayQuoteEvent")
	RegisterForModEvent("TFDPayQuoteClear", "OnPayQuoteEvent")
EndFunction

Event OnPayQuoteEvent(String eventName, String strArg, Float numArg, Form sender)
	If eventName == "TFDPayQuoteUpdate"
		CurrentQuoteContext = strArg
		Int payAmount = numArg as Int
		If payAmount < 0
			payAmount = 0
		EndIf
		CurrentQuoteAmount = payAmount
		ApplySharedPayAmount(payAmount)
		Return
	EndIf

	If eventName == "TFDPayQuoteClear"
		ClearSharedPayAmount()
		Return
	EndIf
EndEvent

Function RefreshPayText()
	RefreshPayTextFromShared()
EndFunction

Function RefreshPayTextFromShared()
	Int payAmount = 0
	If TFDPayGold != None
		payAmount = TFDPayGold.GetValueInt()
	EndIf
	If payAmount < 0
		payAmount = 0
	EndIf
	CurrentQuoteAmount = payAmount
	ApplySharedPayAmount(payAmount)
EndFunction

Function ApplySharedPayAmount(Int aiAmount)
	If aiAmount < 0
		aiAmount = 0
	EndIf

	CurrentQuoteAmount = aiAmount
	If TFDPayGold == None
		Return
	EndIf

	TFDPayGold.SetValueInt(aiAmount)
	UpdateCurrentInstanceGlobal(TFDPayGold)
EndFunction

Function ClearSharedPayAmount()
	CurrentQuoteContext = ""
	CurrentQuoteAmount = 0

	If TFDPayGold == None
		Return
	EndIf

	TFDPayGold.SetValueInt(0)
	UpdateCurrentInstanceGlobal(TFDPayGold)
EndFunction

Int Function GetCurrentQuoteAmount()
	Return CurrentQuoteAmount
EndFunction

String Function GetCurrentQuoteContext()
	Return CurrentQuoteContext
EndFunction