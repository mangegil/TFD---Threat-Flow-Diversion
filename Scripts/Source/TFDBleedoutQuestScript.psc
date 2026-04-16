Scriptname TFDBleedoutQuestScript extends Quest

ReferenceAlias Property Speaker Auto

GlobalVariable Property TFDCaptiveState Auto
GlobalVariable Property TFDPayGold Auto

Quest Property TFDSystemEventQuest Auto
Quest Property TFDPleasureQuest Auto
Quest Property TFDCaptiveBridgeQuest Auto

MiscObject Property Gold001 Auto

Float Property PayPercent = 0.10 Auto

Bool pleasurePending = False
Int CurrentQuoteAmount = 0
String CurrentQuoteContext = ""
Bool pleasureWasCaptive = False
Actor pleasureSpeaker = None

Event OnInit()
	ClearSpeaker()
	RegisterPleasureEvents()
EndEvent

Event OnPlayerLoadGame()
	pleasurePending = False
	pleasureWasCaptive = False
	pleasureSpeaker = None
	ClearSpeaker()
	SendModEvent("TFDBleedoutClearAll")
	RegisterPleasureEvents()
EndEvent

Function RegisterPleasureEvents()
	UnregisterForAllModEvents()
	; Legacy pleasure end/failed callbacks are no longer authoritative here.
	; Native runtime owns terminal pleasure lifecycle now.
EndFunction

Actor Function GetAliasActor(ReferenceAlias akAlias)
	If akAlias == None
		Return None
	EndIf
	Return akAlias.GetActorReference()
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return "0"
	EndIf
	Return akActor.GetFormID() as String
EndFunction

Actor Function GetSpeaker()
	Actor a = GetAliasActor(Speaker)
	If IsActorStale(a)
		If a != None
			ClearSpeakerForActor(a)
		EndIf
		Return None
	EndIf
	Return a
EndFunction

Bool Function IsActorStale(Actor akActor)
	If akActor == None
		Return True
	EndIf

	If akActor.IsDead()
		Return True
	EndIf

	Return False
EndFunction

Bool Function SetSpeaker(Actor akActor)
	If Speaker == None
		Return False
	EndIf

	If akActor == None
		Speaker.Clear()
		Return True
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	Speaker.ForceRefTo(akActor)
	Return (Speaker.GetReference() == akActor)
EndFunction

Function ClearSpeaker()
	If Speaker != None
		If Speaker.GetReference() != None
			Speaker.Clear()
		EndIf
	EndIf
EndFunction

Function ClearSpeakerForActor(Actor akActor)
	If akActor == None
		Return
	EndIf

	If Speaker != None
		If Speaker.GetReference() == akActor
			Speaker.Clear()
		EndIf
	EndIf
EndFunction

Function HandoffSpeakerToPleasure(Actor akSpeaker)
	If akSpeaker == None
		Return
	EndIf

	ClearSpeakerForActor(akSpeaker)

	If akSpeaker.Is3DLoaded()
		akSpeaker.StopCombat()
		akSpeaker.StopCombatAlarm()
		akSpeaker.EvaluatePackage()
	EndIf
EndFunction

Bool Function IsCaptiveContext()
	If TFDCaptiveState == None
		Return False
	EndIf
	Return (TFDCaptiveState.GetValueInt() != 0)
EndFunction

Function RefreshPayText()
	If TFDPayGold == None
		Return
	EndIf

	TFDPayGold.SetValueInt(GetPayAmount())
	UpdateCurrentInstanceGlobal(TFDPayGold)
EndFunction

Int Function GetPayAmount()
	If TFDPayGold == None
		Return 0
	EndIf

	Int payAmount = TFDPayGold.GetValueInt()
	If payAmount < 0
		payAmount = 0
	EndIf
	Return payAmount
EndFunction


Event OnPayQuoteEvent(String eventName, String strArg, Float numArg, Form sender)
	If eventName == "TFDPayQuoteUpdate"
		CurrentQuoteContext = strArg
		CurrentQuoteAmount = numArg as Int
		If CurrentQuoteAmount < 0
			CurrentQuoteAmount = 0
		EndIf
		If strArg == "Bleedout"
			If TFDPayGold != None
				TFDPayGold.SetValueInt(CurrentQuoteAmount)
			EndIf
			RefreshPayText()
		EndIf
		Return
	EndIf

	If eventName == "TFDPayQuoteClear"
		CurrentQuoteContext = ""
		CurrentQuoteAmount = 0
		If TFDPayGold != None
			TFDPayGold.SetValueInt(0)
		EndIf
		UpdateCurrentInstanceGlobal(TFDPayGold)
		Return
	EndIf
EndEvent

TFDSystemEventQuestScript Function GetSystemController()
	If TFDSystemEventQuest == None
		Return None
	EndIf
	Return TFDSystemEventQuest as TFDSystemEventQuestScript
EndFunction

TFDPleasureQuestScript Function GetPleasureController()
	If TFDPleasureQuest == None
		Return None
	EndIf
	Return TFDPleasureQuest as TFDPleasureQuestScript
EndFunction

TFDCaptiveBridge Function GetCaptiveBridge()
	If TFDCaptiveBridgeQuest == None
		Return None
	EndIf
	Return TFDCaptiveBridgeQuest as TFDCaptiveBridge
EndFunction

Function CommitCaptiveChoiceIfNeeded()
	If !IsCaptiveContext()
		Return
	EndIf

	TFDCaptiveBridge captiveCtrl = GetCaptiveBridge()
	If captiveCtrl != None
		captiveCtrl.CommitCaptiveChoice()
	EndIf
EndFunction

Function ReleaseCaptiveBridgeForPleasureIfNeeded()
	If !pleasureWasCaptive
		Return
	EndIf

	TFDCaptiveBridge captiveCtrl = GetCaptiveBridge()
	If captiveCtrl == None
		Return
	EndIf

	captiveCtrl.CommitCaptiveChoice()
	captiveCtrl.ReleaseOwnedCaptorNoCooldown()
EndFunction

Function ClearDialogueBridgesAfterChoice()
	TFDCaptiveBridge captiveCtrl = GetCaptiveBridge()
	If captiveCtrl != None
		captiveCtrl.CommitCaptiveChoice()
		captiveCtrl.ClearAll()
	EndIf

	SendModEvent("TFDCaptiveClearAll")
	SendModEvent("TFDBleedoutClearAll")
	SendModEvent("TFDTruceClearAll")
	SendModEvent("TFDInCombatClearAll")
EndFunction

Function QueueCaptiveBlackout()
	Debug.Trace("TFDBleedoutQuestScript: captive blackout queue is native-owned; mod event already sent.")
EndFunction

Function QueueRecoverResult()
	Debug.Trace("TFDBleedoutQuestScript: recover result queue is native-owned; no legacy globals written.")
EndFunction

Bool Function ResolvePay()
	Actor playerRef = Game.GetPlayer()
	Actor akSpeaker = GetSpeaker()

	If playerRef == None || Gold001 == None
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	Int payAmount = GetPayAmount()
	If payAmount <= 0
		Return False
	EndIf

	playerRef.RemoveItem(Gold001, payAmount, True, akSpeaker)

	SendModEvent("TFDBleedoutOutcomePay")
	ClearDialogueBridgesAfterChoice()
	Return True
EndFunction

Bool Function ResolveRelease()
	Actor akSpeaker = GetSpeaker()
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	ClearDialogueBridgesAfterChoice()
	SendModEvent("TFDBleedoutOutcomeRelease", ActorFormIDString(akSpeaker), 10.0)
	Return True
EndFunction

Bool Function ResolveDoNothing()
	SendModEvent("TFDBleedoutOutcomeReset")
	Return True
EndFunction

Bool Function ResolveKidnap()
	CommitCaptiveChoiceIfNeeded()
	ClearDialogueBridgesAfterChoice()
	SendModEvent("TFDBleedoutOutcomeCaptive")
	QueueCaptiveBlackout()
	Return True
EndFunction

Bool Function ResolvePleasure()
	Actor akSpeaker = GetSpeaker()
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	Int sourceFlow = 0

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	If pleasureCtrl == None
		Return False
	EndIf

	pleasurePending = True
	pleasureWasCaptive = IsCaptiveContext()
	pleasureSpeaker = akSpeaker

	CommitCaptiveChoiceIfNeeded()
	ReleaseCaptiveBridgeForPleasureIfNeeded()
	HandoffSpeakerToPleasure(akSpeaker)
	ClearDialogueBridgesAfterChoice()

	If pleasureWasCaptive
		sourceFlow = 3
	Else
		sourceFlow = 2
	EndIf

	pleasureCtrl.BeginPleasure(akSpeaker, sourceFlow, 0)

	SendModEvent("TFDBleedoutOutcomePleasure")
	pleasurePending = False
	pleasureWasCaptive = False
	pleasureSpeaker = None
	Return True
EndFunction

Event OnPleasureEnded(String eventName, String strArg, Float numArg, Form sender)
	If !pleasurePending
		Return
	EndIf

	pleasurePending = False
	pleasureWasCaptive = False
	pleasureSpeaker = None
	SendModEvent("TFDBleedoutOutcomeReset")
EndEvent

Event OnPleasureFailed(String eventName, String strArg, Float numArg, Form sender)
	If !pleasurePending
		Return
	EndIf

	pleasurePending = False
	pleasureWasCaptive = False
	pleasureSpeaker = None
	SendModEvent("TFDBleedoutOutcomeReset")
EndEvent