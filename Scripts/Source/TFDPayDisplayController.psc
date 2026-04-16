Scriptname TFDPayDisplayController extends Quest

GlobalVariable Property TFDPayGold Auto
TFDDialogueQuestScript Property TFDDialogueQuest Auto

Int CurrentQuoteAmount = 0
String CurrentQuoteContext = ""

Event OnInit()
    RegisterEvents()
    RefreshDialogueOwnerFromShared()
EndEvent

Event OnPlayerLoadGame()
    RegisterEvents()
    ClearQuote()
EndEvent

Function RegisterEvents()
    UnregisterForAllModEvents()
    RegisterForModEvent("TFDPayQuoteUpdate", "OnPayQuoteEvent")
    RegisterForModEvent("TFDPayQuoteClear", "OnPayQuoteEvent")
EndFunction

Event OnPayQuoteEvent(String eventName, String strArg, Float numArg, Form sender)
    If eventName == "TFDPayQuoteUpdate"
        CurrentQuoteContext = strArg
        CurrentQuoteAmount = numArg as Int
        If CurrentQuoteAmount < 0
            CurrentQuoteAmount = 0
        EndIf
        ApplySharedQuoteToDialogueOwner(CurrentQuoteAmount)
        Return
    EndIf

    If eventName == "TFDPayQuoteClear"
        ClearQuote()
        Return
    EndIf
EndEvent

Function ApplySharedQuoteToDialogueOwner(Int aiAmount)
    If aiAmount < 0
        aiAmount = 0
    EndIf

    CurrentQuoteAmount = aiAmount

    If TFDDialogueQuest
        TFDDialogueQuest.ApplySharedPayAmount(CurrentQuoteAmount)
        Return
    EndIf

    If TFDPayGold != None
        TFDPayGold.SetValueInt(CurrentQuoteAmount)
    EndIf
EndFunction

Function ClearQuote()
    CurrentQuoteContext = ""
    CurrentQuoteAmount = 0

    If TFDDialogueQuest
        TFDDialogueQuest.ClearSharedPayAmount()
        Return
    EndIf

    If TFDPayGold != None
        TFDPayGold.SetValueInt(0)
    EndIf
EndFunction

Function RefreshDialogueOwnerFromShared()
    Int payAmount = 0
    If TFDPayGold != None
        payAmount = TFDPayGold.GetValueInt()
    EndIf
    If payAmount < 0
        payAmount = 0
    EndIf

    CurrentQuoteAmount = payAmount

    If TFDDialogueQuest
        TFDDialogueQuest.RefreshPayTextFromShared()
    EndIf
EndFunction

Function UpdatePayAmount()
    ApplySharedQuoteToDialogueOwner(CurrentQuoteAmount)
EndFunction

Int Function GetCurrentQuoteAmount()
    Return CurrentQuoteAmount
EndFunction

String Function GetCurrentQuoteContext()
    Return CurrentQuoteContext
EndFunction