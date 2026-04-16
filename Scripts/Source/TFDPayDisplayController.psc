Scriptname TFDPayDisplayController extends Quest

GlobalVariable Property TFDPayGold Auto
TFDDialogueQuestScript Property TFDDialogueQuest Auto

Int CurrentQuoteAmount = 0
String CurrentQuoteContext = ""

Event OnInit()
    RegisterEvents()
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
        If TFDPayGold != None
            TFDPayGold.SetValueInt(CurrentQuoteAmount)
        EndIf
        If TFDDialogueQuest
            TFDDialogueQuest.RefreshPayText()
        EndIf
        Return
    EndIf

    If eventName == "TFDPayQuoteClear"
        ClearQuote()
        Return
    EndIf
EndEvent

Function ClearQuote()
    CurrentQuoteContext = ""
    CurrentQuoteAmount = 0
    If TFDPayGold != None
        TFDPayGold.SetValueInt(0)
    EndIf
    If TFDDialogueQuest
        TFDDialogueQuest.RefreshPayText()
    EndIf
EndFunction

Function UpdatePayAmount()
    If TFDPayGold != None
        TFDPayGold.SetValueInt(CurrentQuoteAmount)
    EndIf

    If TFDDialogueQuest
        TFDDialogueQuest.RefreshPayText()
    EndIf
EndFunction

Int Function GetCurrentQuoteAmount()
    Return CurrentQuoteAmount
EndFunction

String Function GetCurrentQuoteContext()
    Return CurrentQuoteContext
EndFunction
