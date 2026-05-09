Scriptname TFDSystemEventQuestScript extends Quest

; ============================================================
; TFDSystemEventQuestScript (flow-aware compatibility mapper)
; ------------------------------------------------------------
; Tujuan versi ini:
; - tetap tipis sebagai endpoint fragment dialog
; - simpan speaker aktif dan flow aktif
; - compatible dengan native + Papyrus baseline terbaru
; - route choice ke owner lama / legacy mod events yang masih dipakai
; - pertahankan method compatibility untuk fragment TIF dan shell quest
; ============================================================

; -------------------------------
; Alias bridge
; -------------------------------
ReferenceAlias Property ActiveSpeaker Auto
ReferenceAlias Property PackageDriver Auto

; -------------------------------
; Utility / data
; -------------------------------
Quest Property TFDDialogue Auto
GlobalVariable Property TFDPayGold Auto
MiscObject Property Gold001 Auto
Faction Property TFDDefeatedFaction Auto
Faction Property TFDTeammateFaction Auto

; -------------------------------
; Optional legacy controllers kept only for compatibility
; -------------------------------
TFDPreCombatQuestScript Property TFDPreCombatQuest Auto
TFDInCombatQuestScript Property TFDInCombatQuest Auto
TFDBleedoutQuestScript Property TFDBleedoutQuest Auto
TFDCaptiveBridge Property TFDCaptiveQuest Auto
TFDPleasureQuestScript Property TFDPleasureQuest Auto
TFDPlayerTeammateQuestScript Property TFDPlayerTeammateQuest Auto

; -------------------------------
; Debug
; -------------------------------
Bool Property EnableDebugTrace = True Auto

; -------------------------------
; Flow constants
; Keep these for compatibility with existing shell scripts
; -------------------------------
Int Property FLOW_NONE = 0 AutoReadOnly
Int Property FLOW_PRECOMBAT = 1 AutoReadOnly
Int Property FLOW_BLEEDOUT = 2 AutoReadOnly
Int Property FLOW_CAPTIVE = 3 AutoReadOnly
Int Property FLOW_VICTORY = 4 AutoReadOnly
Int Property FLOW_SAVIOR = 5 AutoReadOnly
Int Property FLOW_RECRUIT_CONTRACT = 6 AutoReadOnly
Int Property FLOW_CREATURE_BLEEDOUT = 7 AutoReadOnly
Int Property FLOW_CREATURE_TRUCE = 8 AutoReadOnly
Int Property FLOW_AFTERPLEASURE = 9 AutoReadOnly
Int Property FLOW_INCOMBAT = 10 AutoReadOnly

; -------------------------------
; Entry / method / branch constants
; Kept for shell quest compatibility only
; -------------------------------
Int Property ENTRY_NONE = 0 AutoReadOnly
Int Property ENTRY_HOTKEY = 1 AutoReadOnly
Int Property ENTRY_FORCEGREET = 2 AutoReadOnly
Int Property ENTRY_CAPTIVE_CALL = 3 AutoReadOnly
Int Property ENTRY_AUTO = 4 AutoReadOnly
Int Property ENTRY_SCENE_RETURN = 5 AutoReadOnly

Int Property METHOD_NONE = 0 AutoReadOnly
Int Property METHOD_DIRECT = 1 AutoReadOnly
Int Property METHOD_PAY = 2 AutoReadOnly
Int Property METHOD_PLEASURE = 3 AutoReadOnly

Int Property BRANCH_NONE = 0 AutoReadOnly
Int Property BRANCH_MAIN = 1 AutoReadOnly
Int Property BRANCH_PAY = 2 AutoReadOnly
Int Property BRANCH_PLEASURE = 3 AutoReadOnly

; -------------------------------
; Choice constants
; -------------------------------
Int Property CHOICE_NONE = 0 AutoReadOnly
Int Property CHOICE_DO_NOTHING = 1 AutoReadOnly
Int Property CHOICE_FIGHT = 2 AutoReadOnly
Int Property CHOICE_PAY = 3 AutoReadOnly
Int Property CHOICE_PLEASURE = 4 AutoReadOnly
Int Property CHOICE_KIDNAP = 5 AutoReadOnly
Int Property CHOICE_RELEASE = 6 AutoReadOnly
Int Property CHOICE_JOIN_ENEMY = 7 AutoReadOnly
Int Property CHOICE_RECRUIT = 8 AutoReadOnly
Int Property CHOICE_FOLLOW_PLAYER = 9 AutoReadOnly
Int Property CHOICE_WORK = 10 AutoReadOnly
Int Property CHOICE_LOOT_ENEMY = 11 AutoReadOnly
Int Property CHOICE_KILL_ENEMY = 12 AutoReadOnly
Int Property CHOICE_THANKS = 13 AutoReadOnly
Int Property CHOICE_EXTEND_CONTRACT = 14 AutoReadOnly
Int Property CHOICE_TERMINATE_CONTRACT = 15 AutoReadOnly
Int Property CHOICE_RETURN_CAPTIVE = 16 AutoReadOnly
Int Property CHOICE_REDO_PLEASURE = 17 AutoReadOnly

; -------------------------------
; Pleasure source constants
; -------------------------------
Int Property PLEASURE_SOURCE_NONE = 0 AutoReadOnly
Int Property PLEASURE_SOURCE_PRECOMBAT = 1 AutoReadOnly
Int Property PLEASURE_SOURCE_BLEEDOUT = 2 AutoReadOnly
Int Property PLEASURE_SOURCE_CAPTIVE = 3 AutoReadOnly
Int Property PLEASURE_SOURCE_VICTORY = 4 AutoReadOnly
Int Property PLEASURE_SOURCE_TEAMMATE = 5 AutoReadOnly

; -------------------------------
; Legacy event names
; -------------------------------
String Property EventPreCombatOutcomePay = "TFDPreCombatOutcomePay" Auto
String Property EventPreCombatOutcomeFight = "TFDPreCombatOutcomeFight" Auto
String Property EventPreCombatOutcomeCaptive = "TFDPreCombatOutcomeCaptive" Auto
String Property EventPreCombatOutcomeJoinEnemy = "TFDPreCombatOutcomeJoinEnemy" Auto
String Property EventPreCombatOutcomeRecruit = "TFDPreCombatOutcomeRecruit" Auto
String Property EventPreCombatOutcomeRelease = "TFDPreCombatOutcomeRelease" Auto
String Property EventPreCombatOutcomeFollow = "TFDPreCombatOutcomeFollow" Auto
String Property EventPreCombatOutcomePleasure = "TFDPreCombatOutcomePleasure" Auto
String Property EventPreCombatClearAll = "TFDPreCombatClearAll" Auto
String Property EventPreCombatDialogueConfirmed = "TFDPreCombatDialogueConfirmed" Auto

String Property EventInCombatOutcomePay = "TFDInCombatOutcomePay" Auto
String Property EventInCombatOutcomePleasure = "TFDInCombatOutcomePleasure" Auto
String Property EventInCombatOutcomeCaptive = "TFDInCombatOutcomeCaptive" Auto
String Property EventInCombatOutcomeFight = "TFDInCombatOutcomeFight" Auto
String Property EventInCombatOutcomeDoNothing = "TFDInCombatOutcomeDoNothing" Auto
String Property EventInCombatOutcomeCancel = "TFDInCombatOutcomeCancel" Auto
String Property EventInCombatOutcomeFailed = "TFDInCombatOutcomeFailed" Auto
String Property EventInCombatOutcomeRelease = "TFDInCombatOutcomeRelease" Auto
String Property EventInCombatOutcomeFollow = "TFDInCombatOutcomeFollow" Auto
String Property EventInCombatOutcomeReset = "TFDInCombatOutcomeReset" Auto
String Property EventInCombatClearAll = "TFDInCombatClearAll" Auto

String Property EventBleedoutOutcomePay = "TFDBleedoutOutcomePay" Auto
String Property EventBleedoutOutcomePleasure = "TFDBleedoutOutcomePleasure" Auto
String Property EventBleedoutOutcomeCaptive = "TFDBleedoutOutcomeCaptive" Auto
String Property EventBleedoutOutcomeRelease = "TFDBleedoutOutcomeRelease" Auto
String Property EventBleedoutOutcomeReset = "TFDBleedoutOutcomeReset" Auto
String Property EventBleedoutClearAll = "TFDBleedoutClearAll" Auto

String Property EventTruceClearAll = "TFDTruceClearAll" Auto
String Property EventPlayerSaviorClear = "TFDPlayerSaviorClear" Auto
String Property EventHumanoidTeammateAssign = "TFDHumanoidTeammateAssign" Auto
String Property EventCreatureTeammateAssign = "TFDCreatureTeammateAssign" Auto
String Property EventCreatureTeammateUnassign = "TFDCreatureTeammateUnassign" Auto
String Property EventPleasureOutcomeRelease = "TFDPleasureOutcomeRelease" Auto

; Victory native bridge events. Internal variables, not CK properties.
String EventVictoryDefeatedRecruit = "TFDDefeatedHumanoidRecruit"
String EventVictoryRecoverDefeatedEnemy = "TFDVictoryRecoverDefeatedEnemy"
String EventVictoryOutcomeRecruit = "TFDVictoryOutcomeRecruit"
String EventVictoryOutcomeKill = "TFDVictoryOutcomeKill"
String EventVictoryOutcomeLoot = "TFDVictoryOutcomeLoot"
String EventVictoryOutcomeCancel = "TFDVictoryOutcomeCancel"
String EventVictoryOutcomePleasure = "TFDVictoryOutcomePleasure"

; Teammate native bridge events. Internal variables, not CK properties.
String EventTeammateGreetStarted = "TFDTeammateGreetStarted"
String EventTeammateExtendContractGold = "TFDTeammateExtendContractGold"
String EventTeammateExtendContractPleasure = "TFDTeammateExtendContractPleasure"
String EventTeammateRestoreHealthPotion = "TFDTeammateRestoreHealthPotion"
String EventTeammateRestoreHealthPleasure = "TFDTeammateRestoreHealthPleasure"
String EventTeammateTerminateContract = "TFDTeammateTerminateContract"

; After pleasure / pleasure runtime
String Property EventAfterPleasureChoiceFinish = "TFDAfterPleasureChoiceFinish" Auto
String Property EventAfterPleasureChoiceRecruit = "TFDAfterPleasureChoiceRecruit" Auto
String Property EventAfterPleasureChoiceJoinEnemy = "TFDAfterPleasureChoiceJoinEnemy" Auto
String Property EventAfterPleasureChoicePleasure = "TFDAfterPleasureChoicePleasure" Auto
String Property EventAfterPleasureChoiceRelease = "TFDAfterPleasureChoiceRelease" Auto
String Property EventAfterPleasureChoiceWork = "TFDAfterPleasureChoiceWork" Auto
String Property EventAfterPleasureChoiceKidnap = "TFDAfterPleasureChoiceKidnap" Auto
String EventSystemEventClearAfterPleasure = "TFDSystemEventClearAfterPleasure"

; Captive native outcome events. Internal variables, not CK properties.
String EventCaptiveOutcomeWork = "TFDCaptiveOutcomeWork"
String EventCaptiveOutcomeReturn = "TFDCaptiveOutcomeReturn"
String EventCaptiveOutcomeRelease = "TFDCaptiveOutcomeRelease"
String EventCaptiveOutcomeEscape = "TFDCaptiveOutcomeEscape"
String EventCaptiveOutcomePleasure = "TFDCaptiveOutcomePleasure"
String EventCaptiveOutcomeCancel = "TFDCaptiveOutcomeCancel"

; Captive request events from PleasureQuest AfterPleasure.
String EventCaptiveRequestWork = "TFDCaptiveRequestWork"
String EventCaptiveRequestReturn = "TFDCaptiveRequestReturn"
String EventCaptiveRequestRelease = "TFDCaptiveRequestRelease"
String EventCaptiveRequestEscape = "TFDCaptiveRequestEscape"

; -------------------------------
; Local route state (very light)
; -------------------------------
Int CurrentFlowKind = 0
Int CurrentEntryMode = 0
Int CurrentMethod = 0
Int CurrentBranch = 0
Bool CurrentRouteActive = False
Actor CurrentRouteSpeaker = None
Bool CurrentGreetConfirmed = False

; -------------------------------
; Captive work compatibility state
; Kept because there is no other owner yet
; -------------------------------
Float Property CaptiveWorkUpdateInterval = 0.50 Auto
Int Property CAPTIVE_PHASE_NONE = 0 AutoReadOnly
Int Property CAPTIVE_PHASE_CAPTIVE = 1 AutoReadOnly
Int Property CAPTIVE_PHASE_ESCAPE = 2 AutoReadOnly
Int Property CAPTIVE_PHASE_RELEASED_WORK = 3 AutoReadOnly
GlobalVariable Property TFDCaptiveState Auto

Actor CaptiveWorkSpeaker = None
Location CaptiveWorkLocation = None
Bool CaptiveWorkActive = False
Int CurrentCaptivePhaseState = 0

; ============================================================
; Init / load
; ============================================================
Event OnInit()
	ClearBridgeState(False)
	RegisterCaptiveRequestEvents()
EndEvent

Event OnPlayerLoadGame()
	ClearBridgeState(False)
	ClearCaptiveWorkState()
	RegisterCaptiveRequestEvents()
EndEvent

Event OnUpdate()
	If CaptiveWorkActive
		UpdateCaptiveWorkMode()
	EndIf
EndEvent

Function RegisterCaptiveRequestEvents()
	RegisterForModEvent(EventCaptiveRequestWork, "OnCaptiveRequestWork")
	RegisterForModEvent(EventCaptiveRequestReturn, "OnCaptiveRequestReturn")
	RegisterForModEvent(EventCaptiveRequestRelease, "OnCaptiveRequestRelease")
	RegisterForModEvent(EventCaptiveRequestEscape, "OnCaptiveRequestEscape")
	RegisterForModEvent(EventSystemEventClearAfterPleasure, "OnSystemEventClearAfterPleasure")
EndFunction

Event OnCaptiveRequestWork(String eventName, String strArg, Float numArg, Form sender)
	Actor requestActor = ResolveCaptiveRequestActor(sender)
	Trace("CaptiveRequestWork event=" + eventName + " sender=" + sender + " actor=" + requestActor + " arg=" + strArg)
	Bool ok = ResolveCaptiveWorkChoice(requestActor)
	Trace("CaptiveRequestWork result=" + BoolText(ok))
EndEvent

Event OnCaptiveRequestReturn(String eventName, String strArg, Float numArg, Form sender)
	Actor requestActor = ResolveCaptiveRequestActor(sender)
	Trace("CaptiveRequestReturn event=" + eventName + " sender=" + sender + " actor=" + requestActor + " arg=" + strArg)
	Bool ok = ResolveCaptiveReturnChoice(requestActor)
	Trace("CaptiveRequestReturn result=" + BoolText(ok))
EndEvent

Event OnCaptiveRequestRelease(String eventName, String strArg, Float numArg, Form sender)
	Actor requestActor = ResolveCaptiveRequestActor(sender)
	Trace("CaptiveRequestRelease event=" + eventName + " sender=" + sender + " actor=" + requestActor + " arg=" + strArg)
	Bool ok = ResolveCaptiveReleaseChoice(requestActor, "captive_after_pleasure_release")
	Trace("CaptiveRequestRelease result=" + BoolText(ok))
EndEvent

Event OnCaptiveRequestEscape(String eventName, String strArg, Float numArg, Form sender)
	Actor requestActor = ResolveCaptiveRequestActor(sender)
	Trace("CaptiveRequestEscape event=" + eventName + " sender=" + sender + " actor=" + requestActor + " arg=" + strArg)
	Bool ok = ResolveCaptiveEscapeChoice(requestActor)
	Trace("CaptiveRequestEscape result=" + BoolText(ok))
EndEvent

Event OnSystemEventClearAfterPleasure(String eventName, String strArg, Float numArg, Form sender)
	Trace("SystemEventClearAfterPleasure event=" + eventName + " arg=" + strArg + " sender=" + sender + " flow=" + CurrentFlowKind + " active=" + BoolText(CurrentRouteActive))
	If CurrentFlowKind == FLOW_AFTERPLEASURE || CurrentFlowKind == FLOW_NONE || CurrentFlowKind == FLOW_RECRUIT_CONTRACT || !CurrentRouteActive
		FinalizeTerminalDialogueRoute("after_pleasure_clear_event")
	Else
		Trace("SystemEventClearAfterPleasure skipped reason=foreign_active_flow flow=" + CurrentFlowKind)
	EndIf
EndEvent

Actor Function ResolveCaptiveRequestActor(Form akSender)
	Actor speakerRef = akSender as Actor
	If IsActorValid(speakerRef)
		Return speakerRef
	EndIf
	Return ResolveCaptiveActor(None)
EndFunction

; ============================================================
; Debug
; ============================================================
Function Trace(String asMsg)
	If !EnableDebugTrace
		Return
	EndIf
	Debug.Trace("[TFD][SystemEventCompat] " + asMsg)
EndFunction

String Function BoolText(Bool abValue)
	If abValue
		Return "true"
	EndIf
	Return "false"
EndFunction

; ============================================================
; Alias helpers
; ============================================================
Actor Function GetActiveSpeaker()
	If ActiveSpeaker == None
		Return None
	EndIf
	Return ActiveSpeaker.GetReference() as Actor
EndFunction

ObjectReference Function GetPackageDriverRef()
	If PackageDriver == None
		Return None
	EndIf
	Return PackageDriver.GetReference()
EndFunction

Function SetActiveSpeaker(Actor akSpeaker)
	CurrentRouteSpeaker = akSpeaker
	If ActiveSpeaker == None
		Return
	EndIf
	If akSpeaker == None
		ActiveSpeaker.Clear()
		Return
	EndIf
	ActiveSpeaker.ForceRefTo(akSpeaker)
EndFunction

Function ClearActiveSpeaker()
	CurrentRouteSpeaker = None
	If ActiveSpeaker != None
		ActiveSpeaker.Clear()
	EndIf
EndFunction

Function SetPackageDriver(ObjectReference akDriver)
	If PackageDriver == None
		Return
	EndIf
	If akDriver == None
		PackageDriver.Clear()
		Return
	EndIf
	PackageDriver.ForceRefTo(akDriver)
EndFunction

Function ClearPackageDriver()
	If PackageDriver != None
		PackageDriver.Clear()
	EndIf
EndFunction

Function ClearBridgeState(Bool abPreserveCaptiveWork = False)
	ClearActiveSpeaker()
	ClearPackageDriver()
	CurrentRouteActive = False
	CurrentGreetConfirmed = False
	CurrentEntryMode = ENTRY_NONE
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_NONE
	If abPreserveCaptiveWork && CaptiveWorkActive && CaptiveWorkSpeaker != None && !CaptiveWorkSpeaker.IsDead()
		CurrentFlowKind = FLOW_CAPTIVE
	Else
		CurrentFlowKind = FLOW_NONE
	EndIf
EndFunction

; ============================================================
; Compatibility helpers for existing shell scripts
; ============================================================
Int Function GetActiveFlow()
	Return CurrentFlowKind
EndFunction

Function SetActiveFlow(Int aiFlow, Actor akSpeaker = None)
	CurrentFlowKind = aiFlow
	If aiFlow == FLOW_NONE
		CurrentGreetConfirmed = False
	EndIf
	If akSpeaker != None
		SetActiveSpeaker(akSpeaker)
	ElseIf aiFlow == FLOW_NONE
		ClearActiveSpeaker()
	EndIf
EndFunction

Function ClearActiveFlow()
	SetActiveFlow(FLOW_NONE, None)
EndFunction

Bool Function HasActiveDialogueRoute()
	Return CurrentRouteActive
EndFunction

Int Function GetCurrentRouteFlow()
	Return CurrentFlowKind
EndFunction

Function ResetRouteRecorderState(Bool abKeepToken = False)
	CurrentRouteActive = False
	CurrentGreetConfirmed = False
	CurrentEntryMode = ENTRY_NONE
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_NONE
	If CurrentFlowKind != FLOW_CAPTIVE || !CaptiveWorkActive
		CurrentFlowKind = FLOW_NONE
	EndIf
	If !CaptiveWorkActive
		CurrentRouteSpeaker = None
	EndIf
EndFunction

Bool Function BeginDialogueRoute(Int aiFlow, Int aiEntryMode, Actor akSpeaker = None, String asReason = "")
	CurrentRouteActive = True
	CurrentGreetConfirmed = False
	CurrentFlowKind = aiFlow
	CurrentEntryMode = aiEntryMode
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_NONE
	If akSpeaker != None
		SetActiveSpeaker(akSpeaker)
	EndIf
	Trace("BeginDialogueRoute flow=" + aiFlow + " reason=" + asReason)
	Return True
EndFunction

Function MarkDialogueNegotiating(Actor akSpeaker = None, String asReason = "")
	CurrentRouteActive = True
	If akSpeaker != None
		SetActiveSpeaker(akSpeaker)
	EndIf
	Trace("MarkDialogueNegotiating flow=" + CurrentFlowKind + " reason=" + asReason)
EndFunction

Bool Function SetDialogueMethod(Int aiMethod, Actor akSpeaker = None, String asReason = "")
	CurrentMethod = aiMethod
	If akSpeaker != None
		SetActiveSpeaker(akSpeaker)
	EndIf
	Return True
EndFunction

Bool Function SetDialogueBranch(Int aiBranch, Actor akSpeaker = None, String asReason = "")
	CurrentBranch = aiBranch
	If akSpeaker != None
		SetActiveSpeaker(akSpeaker)
	EndIf
	Return True
EndFunction

Function FinalizeTerminalDialogueRoute(String asReason = "", Bool abPreserveCaptiveWorkSpeaker = False)
	Trace("FinalizeTerminalDialogueRoute reason=" + asReason)
	ClearBridgeState(abPreserveCaptiveWorkSpeaker)
EndFunction

Function ClearTransientDialogueBridges()
	SendQuestEvent(EventTruceClearAll)
	SendQuestEvent(EventBleedoutClearAll)
	SendQuestEvent(EventPreCombatClearAll)
	SendQuestEvent(EventInCombatClearAll)
EndFunction

; ============================================================
; Generic helpers
; ============================================================
Actor Function ResolveSpeaker(Actor akSpeaker = None)
	If IsActorValid(akSpeaker)
		Return akSpeaker
	EndIf
	Actor active = GetActiveSpeaker()
	If IsActorValid(active)
		Return active
	EndIf
	If IsActorValid(CurrentRouteSpeaker)
		Return CurrentRouteSpeaker
	EndIf
	Return None
EndFunction

Bool Function IsActorValid(Actor akActor)
	If akActor == None
		Return False
	EndIf
	If akActor.IsDead()
		Return False
	EndIf
	Return True
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return "0"
	EndIf
	Return akActor.GetFormID() as String
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

Bool Function TransferPayToSpeaker(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Int payAmount = GetPayAmount()

	If playerRef == None
		Return False
	EndIf
	If Gold001 == None
		Return False
	EndIf
	If !IsActorValid(akSpeaker)
		Return False
	EndIf
	If payAmount <= 0
		Return False
	EndIf

	playerRef.RemoveItem(Gold001, payAmount, True, akSpeaker)
	Return True
EndFunction

Function DispatchLegacyEvent(String asEventName, Actor akSpeaker = None, String asStrArg = "", Float afNumArg = 0.0)
	If asEventName == ""
		Return
	EndIf

	If akSpeaker != None
		akSpeaker.SendModEvent(asEventName, asStrArg, afNumArg)
	Else
		SendModEvent(asEventName, asStrArg, afNumArg)
	EndIf
EndFunction

Function SendQuestEvent(String asEventName)
	If asEventName == ""
		Return
	EndIf
	SendModEvent(asEventName)
EndFunction

Bool Function IsPreCombatRootChoice(Int aiChoiceKind)
	If aiChoiceKind == CHOICE_KIDNAP || aiChoiceKind == CHOICE_PAY || aiChoiceKind == CHOICE_FIGHT || aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_PLEASURE
		Return True
	EndIf
	Return False
EndFunction

Bool Function IsPreCombatPayChoice(Int aiChoiceKind)
	If aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_RECRUIT || aiChoiceKind == CHOICE_JOIN_ENEMY || aiChoiceKind == CHOICE_FOLLOW_PLAYER
		Return True
	EndIf
	Return False
EndFunction

Bool Function IsInCombatRootChoice(Int aiChoiceKind)
	If aiChoiceKind == CHOICE_KIDNAP || aiChoiceKind == CHOICE_PAY || aiChoiceKind == CHOICE_FIGHT || aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_PLEASURE
		Return True
	EndIf
	Return False
EndFunction

Bool Function IsInCombatPayChoice(Int aiChoiceKind)
	If aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_RECRUIT || aiChoiceKind == CHOICE_JOIN_ENEMY || aiChoiceKind == CHOICE_FOLLOW_PLAYER
		Return True
	EndIf
	Return False
EndFunction

Bool Function TryLateConfirmPreCombatChoice(Int aiChoiceKind, Actor akSpeaker = None)
	If CurrentGreetConfirmed
		Return True
	EndIf

	If CurrentFlowKind != FLOW_PRECOMBAT || !CurrentRouteActive
		Return False
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf

	If CurrentRouteSpeaker != None && chosenSpeaker != CurrentRouteSpeaker
		Trace("PreCombatLateConfirmFromChoice rejected reason=speaker_mismatch choice=" + aiChoiceKind + " speaker=" + chosenSpeaker + " routeSpeaker=" + CurrentRouteSpeaker)
		Return False
	EndIf

	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	If preCtrl == None
		Trace("PreCombatLateConfirmFromChoice rejected reason=no_precombat_controller choice=" + aiChoiceKind + " speaker=" + chosenSpeaker)
		Return False
	EndIf

	Bool stageOk = False
	If CurrentMethod == METHOD_NONE && CurrentBranch == BRANCH_NONE && IsPreCombatRootChoice(aiChoiceKind)
		stageOk = preCtrl.IsRootSessionValidForActor(chosenSpeaker)
	ElseIf CurrentMethod == METHOD_PAY && CurrentBranch == BRANCH_PAY && IsPreCombatPayChoice(aiChoiceKind)
		stageOk = preCtrl.IsPayBranchSessionValidForActor(chosenSpeaker)
	EndIf

	If !stageOk
		Trace("PreCombatLateConfirmFromChoice rejected reason=stage_mismatch choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch + " speaker=" + chosenSpeaker)
		Return False
	EndIf

	CurrentGreetConfirmed = True
	Trace("PreCombatLateConfirmFromChoice accepted choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch + " speaker=" + chosenSpeaker)
	DispatchLegacyEvent(EventPreCombatDialogueConfirmed, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	Return True
EndFunction

Bool Function TryLateConfirmInCombatChoice(Int aiChoiceKind, Actor akSpeaker = None)
	If CurrentGreetConfirmed
		Return True
	EndIf

	If CurrentFlowKind != FLOW_INCOMBAT || !CurrentRouteActive
		Return False
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf

	If CurrentRouteSpeaker != None && chosenSpeaker != CurrentRouteSpeaker
		Trace("InCombatLateConfirmFromChoice rejected reason=speaker_mismatch choice=" + aiChoiceKind + " speaker=" + chosenSpeaker + " routeSpeaker=" + CurrentRouteSpeaker)
		Return False
	EndIf

	TFDInCombatQuestScript inCtrl = GetInCombatController()
	If inCtrl == None
		Trace("InCombatLateConfirmFromChoice rejected reason=no_incombat_controller choice=" + aiChoiceKind + " speaker=" + chosenSpeaker)
		Return False
	EndIf

	Bool stageOk = False
	If CurrentMethod == METHOD_NONE && CurrentBranch == BRANCH_NONE && IsInCombatRootChoice(aiChoiceKind)
		stageOk = inCtrl.IsRootSessionValidForActor(chosenSpeaker)
	ElseIf CurrentMethod == METHOD_PAY && CurrentBranch == BRANCH_PAY && IsInCombatPayChoice(aiChoiceKind)
		stageOk = inCtrl.IsPayBranchSessionValidForActor(chosenSpeaker)
	EndIf

	If !stageOk
		Trace("InCombatLateConfirmFromChoice rejected reason=stage_mismatch choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch + " speaker=" + chosenSpeaker)
		Return False
	EndIf

	CurrentGreetConfirmed = True
	inCtrl.NoteDialogueOpened(chosenSpeaker, "late_confirm_choice")
	Trace("InCombatLateConfirmFromChoice accepted choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch + " speaker=" + chosenSpeaker)
	Return True
EndFunction

Bool Function IsPreCombatChoiceAllowed(Int aiChoiceKind, Actor akSpeaker = None)
	If CurrentFlowKind != FLOW_PRECOMBAT
		Return True
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If !CurrentRouteActive
		Trace("RejectPreCombatChoice reason=route_inactive choice=" + aiChoiceKind + " choiceSpeaker=" + chosenSpeaker)
		Return False
	EndIf

	If chosenSpeaker == None
		Trace("RejectPreCombatChoice reason=no_speaker choice=" + aiChoiceKind)
		Return False
	EndIf

	If CurrentRouteSpeaker != None && chosenSpeaker != CurrentRouteSpeaker
		Trace("RejectPreCombatChoice reason=speaker_mismatch choice=" + aiChoiceKind + " speaker=" + chosenSpeaker + " routeSpeaker=" + CurrentRouteSpeaker)
		Return False
	EndIf

	If !CurrentGreetConfirmed && !TryLateConfirmPreCombatChoice(aiChoiceKind, chosenSpeaker)
		Trace("RejectPreCombatChoice reason=greet_not_confirmed choice=" + aiChoiceKind + " choiceSpeaker=" + chosenSpeaker + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	Bool isRootStage = (CurrentMethod == METHOD_NONE && CurrentBranch == BRANCH_NONE)
	Bool isPayStage = (CurrentMethod == METHOD_PAY && CurrentBranch == BRANCH_PAY)

	If isRootStage
		If aiChoiceKind == CHOICE_KIDNAP || aiChoiceKind == CHOICE_PAY || aiChoiceKind == CHOICE_FIGHT || aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_PLEASURE
			Return True
		EndIf
		Trace("RejectPreCombatChoice reason=root_choice_not_allowed choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	If isPayStage
		If aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_RECRUIT || aiChoiceKind == CHOICE_JOIN_ENEMY || aiChoiceKind == CHOICE_FOLLOW_PLAYER
			Return True
		EndIf
		Trace("RejectPreCombatChoice reason=pay_choice_not_allowed choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	Trace("RejectPreCombatChoice reason=unexpected_stage choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
	Return False
EndFunction

Bool Function IsInCombatChoiceAllowed(Int aiChoiceKind, Actor akSpeaker = None)
	If CurrentFlowKind != FLOW_INCOMBAT
		Return True
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If !CurrentRouteActive
		Trace("RejectInCombatChoice reason=route_inactive choice=" + aiChoiceKind + " choiceSpeaker=" + chosenSpeaker)
		Return False
	EndIf

	If chosenSpeaker == None
		Trace("RejectInCombatChoice reason=no_speaker choice=" + aiChoiceKind)
		Return False
	EndIf

	If !CurrentGreetConfirmed && !TryLateConfirmInCombatChoice(aiChoiceKind, chosenSpeaker)
		Trace("RejectInCombatChoice reason=greet_not_confirmed choice=" + aiChoiceKind + " choiceSpeaker=" + chosenSpeaker + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	If CurrentRouteSpeaker != None && chosenSpeaker != CurrentRouteSpeaker
		Trace("RejectInCombatChoice reason=speaker_mismatch choice=" + aiChoiceKind + " speaker=" + chosenSpeaker + " routeSpeaker=" + CurrentRouteSpeaker)
		Return False
	EndIf

	Bool isRootStage = (CurrentMethod == METHOD_NONE && CurrentBranch == BRANCH_NONE)
	Bool isPayStage = (CurrentMethod == METHOD_PAY && CurrentBranch == BRANCH_PAY)

	If isRootStage
		If IsInCombatRootChoice(aiChoiceKind)
			Return True
		EndIf
		Trace("RejectInCombatChoice reason=root_choice_not_allowed choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	If isPayStage
		If IsInCombatPayChoice(aiChoiceKind)
			Return True
		EndIf
		Trace("RejectInCombatChoice reason=pay_choice_not_allowed choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
		Return False
	EndIf

	Trace("RejectInCombatChoice reason=unexpected_stage choice=" + aiChoiceKind + " method=" + CurrentMethod + " branch=" + CurrentBranch)
	Return False
EndFunction

Int Function InferFlowFromSpeaker(Actor akSpeaker = None)
	If CurrentFlowKind != FLOW_NONE
		Return CurrentFlowKind
	EndIf
	If CaptiveWorkActive
		Return FLOW_CAPTIVE
	EndIf
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker != None && TFDDefeatedFaction != None
		If chosenSpeaker.IsInFaction(TFDDefeatedFaction)
			Return FLOW_VICTORY
		EndIf
	EndIf
	If chosenSpeaker != None && TFDTeammateFaction != None
		If chosenSpeaker.IsInFaction(TFDTeammateFaction)
			Return FLOW_RECRUIT_CONTRACT
		EndIf
	EndIf
	Return FLOW_NONE
EndFunction

; ============================================================
; Controller helpers
; ============================================================
TFDPreCombatQuestScript Function GetPreCombatController()
	Return TFDPreCombatQuest
EndFunction

TFDInCombatQuestScript Function GetInCombatController()
	Return TFDInCombatQuest
EndFunction

TFDBleedoutQuestScript Function GetBleedoutController()
	Return TFDBleedoutQuest
EndFunction

TFDCaptiveBridge Function GetCaptiveController()
	Return TFDCaptiveQuest
EndFunction

TFDPleasureQuestScript Function GetPleasureController()
	Return TFDPleasureQuest
EndFunction

TFDPlayerTeammateQuestScript Function GetTeammateController()
	Return TFDPlayerTeammateQuest
EndFunction

Bool Function ShouldBlockTeammateGreetDuringPleasure(Actor akSpeaker = None)
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	If pleasureCtrl == None
		Return False
	EndIf

	If pleasureCtrl.ShouldBlockTeammateGreet(akSpeaker)
		Trace("RejectTeammateGreet reason=pleasure_active speaker=" + akSpeaker)
		Return True
	EndIf

	Return False
EndFunction

Bool Function ShouldBlockPreCombatRootGreetReentry(Actor akSpeaker = None, String asReason = "")
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If preCtrl == None
		Return False
	EndIf

	If preCtrl.ShouldPreserveSessionDuringBridgeClear(chosenSpeaker)
		Trace("RejectPreCombatRootGreet reason=session_preserve speaker=" + chosenSpeaker + " source=" + asReason)
		preCtrl.ReleaseSpeakerForceGreetPackage(chosenSpeaker, "root_greet_reentry_block")
		DispatchLegacyEvent("TFDPreCombatRootGreetRejected", chosenSpeaker, ActorFormIDString(chosenSpeaker), 5.0)
		Return True
	EndIf

	Return False
EndFunction

; ============================================================
; Greet entry wrappers
; ============================================================
Bool Function BeginFlowGreet(Int aiFlow, Actor akSpeaker, ObjectReference akDriver = None, String asReason = "")
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		chosenSpeaker = akSpeaker
	EndIf

	If aiFlow == FLOW_PRECOMBAT && ShouldBlockPreCombatRootGreetReentry(chosenSpeaker, asReason)
		Return False
	EndIf

	CurrentFlowKind = aiFlow
	CurrentRouteActive = True
	CurrentGreetConfirmed = True
	CurrentEntryMode = ENTRY_FORCEGREET
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_NONE
	SetActiveSpeaker(chosenSpeaker)
	SetPackageDriver(akDriver)
	Trace("BeginFlowGreet flow=" + aiFlow + " speaker=" + chosenSpeaker + " reason=" + asReason)
	If aiFlow == FLOW_PRECOMBAT && chosenSpeaker != None
		DispatchLegacyEvent(EventPreCombatDialogueConfirmed, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	EndIf
	If aiFlow == FLOW_INCOMBAT && chosenSpeaker != None && TFDInCombatQuest != None
		TFDInCombatQuest.NoteDialogueOpened(chosenSpeaker, asReason)
	EndIf
	Return True
EndFunction

Bool Function BeginPreCombatGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_PRECOMBAT, akSpeaker, None, "precombat_greet")
EndFunction

Bool Function BeginInCombatGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_INCOMBAT, akSpeaker, None, "incombat_greet")
EndFunction

Bool Function BeginBleedoutGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_BLEEDOUT, akSpeaker, None, "bleedout_greet")
EndFunction

Bool Function BeginCaptiveGreet(Actor akSpeaker)
	Bool ok = BeginFlowGreet(FLOW_CAPTIVE, akSpeaker, None, "captive_greet")
	TFDCaptiveBridge captiveCtrl = GetCaptiveController()
	If captiveCtrl != None
		captiveCtrl.MarkCaptiveDialogueOwned(ResolveSpeaker(akSpeaker))
	EndIf
	Return ok
EndFunction

Bool Function BeginCreatureGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_CREATURE_TRUCE, akSpeaker, None, "creature_greet")
EndFunction

Bool Function BeginRescueGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_SAVIOR, akSpeaker, None, "rescue_greet")
EndFunction

Bool Function BeginTeammateGreet(Actor akSpeaker)
	; Teammate dialogue is normal player-initiated dialogue. Do not keep
	; TFDSystemEventQuest ActiveSpeaker bound here, because a player can close
	; the menu without choosing an outcome. A stale ActiveSpeaker blocks/warps
	; the next teammate dialogue target.
	If !IsActorValid(akSpeaker)
		Return False
	EndIf

	If ShouldBlockTeammateGreetDuringPleasure(akSpeaker)
		Return False
	EndIf

	ClearBridgeState(False)
	Trace("BeginFlowGreet flow=" + FLOW_RECRUIT_CONTRACT + " speaker=" + akSpeaker + " reason=teammate_greet_transient")
	DispatchLegacyEvent(EventTeammateGreetStarted, akSpeaker, ActorFormIDString(akSpeaker), 0.0)
	ClearBridgeState(False)
	Return True
EndFunction

Bool Function BeginTruceTeammateGreet(Actor akSpeaker)
	Return BeginTeammateGreet(akSpeaker)
EndFunction

Bool Function BeginAfterPleasureGreet(Actor akSpeaker)
	Bool ok = BeginFlowGreet(FLOW_AFTERPLEASURE, akSpeaker, None, "after_pleasure_greet")
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	If pleasureCtrl != None
		pleasureCtrl.OnAfterPleasureDialogueOpened()
	EndIf
	Return ok
EndFunction

Bool Function BeginVictoryGreet(Actor akSpeaker)
	Return BeginFlowGreet(FLOW_VICTORY, akSpeaker, None, "victory_greet")
EndFunction

; ============================================================
; Choice wrappers
; ============================================================
Bool Function SubmitChoice(Int aiChoiceKind, Actor akSpeaker = None)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	Int flow = InferFlowFromSpeaker(chosenSpeaker)

	Trace("SubmitChoice flow=" + flow + " choice=" + aiChoiceKind + " speaker=" + chosenSpeaker)

	If flow == FLOW_PRECOMBAT && !IsPreCombatChoiceAllowed(aiChoiceKind, chosenSpeaker)
		Return False
	EndIf

	If flow == FLOW_INCOMBAT && !IsInCombatChoiceAllowed(aiChoiceKind, chosenSpeaker)
		Return False
	EndIf

	If flow == FLOW_AFTERPLEASURE
		Return RouteAfterPleasureChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_PRECOMBAT
		Return RoutePreCombatChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_INCOMBAT
		Return RouteInCombatChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_BLEEDOUT
		Return RouteBleedoutChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_CAPTIVE
		Return RouteCaptiveChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_VICTORY
		Return RouteVictoryChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_SAVIOR
		Return RouteSaviorChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_RECRUIT_CONTRACT
		Return RouteRecruitContractChoice(aiChoiceKind, chosenSpeaker)
	ElseIf flow == FLOW_CREATURE_BLEEDOUT || flow == FLOW_CREATURE_TRUCE
		Return RouteCreatureChoice(aiChoiceKind, chosenSpeaker)
	EndIf

	Debug.Notification("TFD: No active dialogue flow.")
	Return False
EndFunction

Bool Function ResolveDoNothing(Actor akSpeaker)
	Return SubmitChoice(CHOICE_DO_NOTHING, akSpeaker)
EndFunction

Bool Function ResolveFight(Actor akSpeaker)
	Return SubmitChoice(CHOICE_FIGHT, akSpeaker)
EndFunction

Bool Function ResolvePay(Actor akSpeaker)
	Trace("ResolvePay experimental direct submit speaker=" + ResolveSpeaker(akSpeaker))
	Return SubmitChoice(CHOICE_PAY, akSpeaker)
EndFunction

Bool Function ResolvePleasure(Actor akSpeaker)
	Trace("ResolvePleasure experimental direct submit speaker=" + ResolveSpeaker(akSpeaker))
	Return SubmitChoice(CHOICE_PLEASURE, akSpeaker)
EndFunction

Bool Function ResolveKidnap(Actor akSpeaker)
	Return SubmitChoice(CHOICE_KIDNAP, akSpeaker)
EndFunction

Bool Function ResolveRelease(Actor akSpeaker)
	Return SubmitChoice(CHOICE_RELEASE, akSpeaker)
EndFunction

Bool Function ResolveJoinEnemy(Actor akSpeaker)
	Return SubmitChoice(CHOICE_JOIN_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveRecruit(Actor akSpeaker)
	Return SubmitChoice(CHOICE_RECRUIT, akSpeaker)
EndFunction

Bool Function ResolveFollowPlayer(Actor akSpeaker)
	Return SubmitChoice(CHOICE_FOLLOW_PLAYER, akSpeaker)
EndFunction

Bool Function ResolveWork(Actor akSpeaker)
	Return SubmitChoice(CHOICE_WORK, akSpeaker)
EndFunction

Bool Function ResolveLootEnemy(Actor akSpeaker)
	Return SubmitChoice(CHOICE_LOOT_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveKillEnemy(Actor akSpeaker)
	Return SubmitChoice(CHOICE_KILL_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveThanks(Actor akSpeaker)
	Return SubmitChoice(CHOICE_THANKS, akSpeaker)
EndFunction

Bool Function ResolveAfterPleasureEnd(Actor akSpeaker)
	Return SubmitChoice(CHOICE_THANKS, akSpeaker)
EndFunction

Bool Function ResolveExtendContract(Actor akSpeaker)
	Return SubmitChoice(CHOICE_EXTEND_CONTRACT, akSpeaker)
EndFunction

Bool Function ResolveTerminateContract(Actor akSpeaker)
	Return SubmitChoice(CHOICE_TERMINATE_CONTRACT, akSpeaker)
EndFunction

Bool Function ResolveReturnCaptive(Actor akSpeaker)
	Return SubmitChoice(CHOICE_RETURN_CAPTIVE, akSpeaker)
EndFunction

Bool Function ResolveRedoPleasure(Actor akSpeaker)
	Return SubmitChoice(CHOICE_REDO_PLEASURE, akSpeaker)
EndFunction

; ============================================================
; Flow routers
; ============================================================
Bool Function RoutePreCombatChoice(Int aiChoiceKind, Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	If preCtrl == None
		Debug.Notification("TFD: PreCombat quest is not available.")
		Return False
	EndIf

	If akSpeaker != None
		preCtrl.SetSpeaker(akSpeaker)
	EndIf

	If aiChoiceKind == CHOICE_KIDNAP
		Return preCtrl.TryResolveKidnapForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_PAY
		Return preCtrl.ResolvePayForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_FIGHT
		Return preCtrl.TryResolveFightForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_RECRUIT
		Return preCtrl.ResolveRecruitForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_JOIN_ENEMY
		Return preCtrl.ResolveJoinEnemyForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_RELEASE
		Return preCtrl.ResolveReleaseForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_FOLLOW_PLAYER
		Return preCtrl.ResolveFollowForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_DO_NOTHING
		Return preCtrl.TryResolveDoNothingForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Return preCtrl.TryResolvePleasureForActor(akSpeaker)
	EndIf

	Debug.Notification("TFD: Invalid PreCombat outcome.")
	Return False
EndFunction

Bool Function RouteInCombatChoice(Int aiChoiceKind, Actor akSpeaker)
	TFDInCombatQuestScript inCtrl = GetInCombatController()
	If inCtrl == None
		Debug.Notification("TFD: InCombat quest is not available.")
		Return False
	EndIf

	If akSpeaker != None
		inCtrl.SetSpeaker(akSpeaker)
	EndIf

	If aiChoiceKind == CHOICE_KIDNAP
		Return inCtrl.ResolveKidnapForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_PAY
		Return inCtrl.ResolvePayForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_FIGHT
		Return inCtrl.ResolveFightForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_RECRUIT
		Return inCtrl.ResolveRecruitForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_JOIN_ENEMY
		Return inCtrl.ResolveJoinEnemyForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_RELEASE
		Return inCtrl.ResolveReleaseForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_FOLLOW_PLAYER
		Return inCtrl.ResolveFollowForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_DO_NOTHING
		Return inCtrl.ResolveDoNothingForActor(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Return inCtrl.ResolvePleasureForActor(akSpeaker)
	EndIf

	Debug.Notification("TFD: Invalid InCombat outcome.")
	Return False
EndFunction

Bool Function RouteBleedoutChoice(Int aiChoiceKind, Actor akSpeaker)
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	If bleedCtrl == None
		Return False
	EndIf

	If aiChoiceKind == CHOICE_KIDNAP
		Bool okKidnap = bleedCtrl.ResolveKidnap()
		If okKidnap
			FinalizeTerminalDialogueRoute("bleedout_kidnap")
		EndIf
		Return okKidnap
	ElseIf aiChoiceKind == CHOICE_PAY
		Bool okPay = bleedCtrl.ResolvePay()
		If okPay
			FinalizeTerminalDialogueRoute("bleedout_pay")
		EndIf
		Return okPay
	ElseIf aiChoiceKind == CHOICE_RELEASE
		Bool okRelease = bleedCtrl.ResolveRelease()
		If okRelease
			FinalizeTerminalDialogueRoute("bleedout_release")
		EndIf
		Return okRelease
	ElseIf aiChoiceKind == CHOICE_DO_NOTHING
		Bool okNone = bleedCtrl.ResolveDoNothing()
		If okNone
			FinalizeTerminalDialogueRoute("bleedout_do_nothing")
		EndIf
		Return okNone
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Bool okPleasure = bleedCtrl.ResolvePleasure()
		If okPleasure
			FinalizeTerminalDialogueRoute("bleedout_pleasure")
		EndIf
		Return okPleasure
	EndIf

	Debug.Notification("TFD: Invalid Bleedout outcome.")
	Return False
EndFunction

Bool Function RouteCaptiveChoice(Int aiChoiceKind, Actor akSpeaker)
	If aiChoiceKind == CHOICE_WORK
		Return ResolveCaptiveWorkChoice(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_RETURN_CAPTIVE || aiChoiceKind == CHOICE_KIDNAP
		Return ResolveCaptiveReturnChoice(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_THANKS || aiChoiceKind == CHOICE_TERMINATE_CONTRACT
		Return ResolveCaptiveReleaseChoice(akSpeaker, "captive_release")
	ElseIf aiChoiceKind == CHOICE_PAY
		Return ResolveCaptivePayChoice(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_FIGHT
		Return ResolveCaptiveEscapeChoice(akSpeaker)
	ElseIf aiChoiceKind == CHOICE_PLEASURE || aiChoiceKind == CHOICE_REDO_PLEASURE || aiChoiceKind == CHOICE_EXTEND_CONTRACT
		Return ResolveCaptivePleasureChoice(akSpeaker)
	EndIf

	Debug.Notification("TFD: Invalid Captive outcome.")
	Return False
EndFunction

Bool Function RouteAfterPleasureChoice(Int aiChoiceKind, Actor akSpeaker)
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	If pleasureCtrl == None
		Return False
	EndIf

	If aiChoiceKind == CHOICE_PLEASURE || aiChoiceKind == CHOICE_REDO_PLEASURE || aiChoiceKind == CHOICE_EXTEND_CONTRACT
		Bool okRedo = pleasureCtrl.ChooseRedo()
		If okRedo
			FinalizeTerminalDialogueRoute("after_pleasure_redo")
		EndIf
		Return okRedo
	ElseIf aiChoiceKind == CHOICE_KIDNAP || aiChoiceKind == CHOICE_RETURN_CAPTIVE
		Bool okCaptive = pleasureCtrl.ChooseCaptive()
		If okCaptive
			FinalizeTerminalDialogueRoute("after_pleasure_captive")
		EndIf
		Return okCaptive
	ElseIf aiChoiceKind == CHOICE_PAY
		Bool okPay = pleasureCtrl.ChoosePay()
		If okPay
			FinalizeTerminalDialogueRoute("after_pleasure_pay")
		EndIf
		Return okPay
	ElseIf aiChoiceKind == CHOICE_RECRUIT
		Bool okRecruit = pleasureCtrl.ChooseRecruit()
		If okRecruit
			FinalizeTerminalDialogueRoute("after_pleasure_recruit")
		EndIf
		Return okRecruit
	ElseIf aiChoiceKind == CHOICE_JOIN_ENEMY
		Bool okJoin = pleasureCtrl.ChooseJoinEnemy()
		If okJoin
			FinalizeTerminalDialogueRoute("after_pleasure_join_enemy")
		EndIf
		Return okJoin
	ElseIf aiChoiceKind == CHOICE_THANKS || aiChoiceKind == CHOICE_DO_NOTHING
		Bool okEnd = pleasureCtrl.ChooseEnd()
		If okEnd
			FinalizeTerminalDialogueRoute("after_pleasure_end")
		EndIf
		Return okEnd
	ElseIf aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_TERMINATE_CONTRACT
		Bool okRelease = pleasureCtrl.ChooseRelease()
		If okRelease
			FinalizeTerminalDialogueRoute("after_pleasure_release")
		EndIf
		Return okRelease
	ElseIf aiChoiceKind == CHOICE_WORK
		Bool okWork = pleasureCtrl.ChooseWork()
		If okWork
			FinalizeTerminalDialogueRoute("after_pleasure_work")
		EndIf
		Return okWork
	EndIf

	Return False
EndFunction

Bool Function RouteVictoryChoice(Int aiChoiceKind, Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf

	String chosenFormId = ActorFormIDString(chosenSpeaker)

	If aiChoiceKind == CHOICE_RECRUIT
		DispatchLegacyEvent(EventVictoryOutcomeRecruit, chosenSpeaker, chosenFormId, 0.0)
		DispatchLegacyEvent(EventVictoryDefeatedRecruit, chosenSpeaker, chosenFormId, 0.0)
		FinalizeTerminalDialogueRoute("victory_recruit")
		Return True
	ElseIf aiChoiceKind == CHOICE_LOOT_ENEMY
		Bool okLoot = ExecuteVictoryLoot(akSpeaker)
		If okLoot
			DispatchLegacyEvent(EventVictoryOutcomeLoot, chosenSpeaker, chosenFormId, 0.0)
			FinalizeTerminalDialogueRoute("victory_loot")
		EndIf
		Return okLoot
	ElseIf aiChoiceKind == CHOICE_KILL_ENEMY
		Bool okKill = ExecuteVictoryKill(akSpeaker)
		If okKill
			DispatchLegacyEvent(EventVictoryOutcomeKill, chosenSpeaker, chosenFormId, 0.0)
			FinalizeTerminalDialogueRoute("victory_kill")
		EndIf
		Return okKill
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		DispatchLegacyEvent(EventVictoryOutcomePleasure, chosenSpeaker, chosenFormId, 0.0)
		DispatchLegacyEvent(EventVictoryRecoverDefeatedEnemy, chosenSpeaker, chosenFormId, 0.0)
		Utility.WaitMenuMode(0.15)
		Return StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_VICTORY, "victory_pleasure")
	ElseIf aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_DO_NOTHING
		DispatchLegacyEvent(EventVictoryOutcomeCancel, chosenSpeaker, chosenFormId, 0.0)
		FinalizeTerminalDialogueRoute("victory_do_nothing")
		Return True
	EndIf

	Debug.Notification("TFD: Invalid Victory outcome.")
	Return False
EndFunction

Bool Function RouteSaviorChoice(Int aiChoiceKind, Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If aiChoiceKind == CHOICE_THANKS || aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_RELEASE
		DispatchLegacyEvent(EventPlayerSaviorClear, chosenSpeaker)
		FinalizeTerminalDialogueRoute("savior_clear")
		Return True
	ElseIf aiChoiceKind == CHOICE_PAY
		If !TransferPayToSpeaker(chosenSpeaker)
			Return False
		EndIf
		DispatchLegacyEvent(EventPlayerSaviorClear, chosenSpeaker)
		If chosenSpeaker != None && !chosenSpeaker.IsDead()
			chosenSpeaker.StopCombatAlarm()
			chosenSpeaker.EvaluatePackage()
		EndIf
		FinalizeTerminalDialogueRoute("savior_pay")
		Return True
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Return StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_TEAMMATE, "savior_pleasure")
	EndIf

	Debug.Notification("TFD: Invalid Savior outcome.")
	Return False
EndFunction

Bool Function RouteRecruitContractChoice(Int aiChoiceKind, Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If aiChoiceKind == CHOICE_PAY || aiChoiceKind == CHOICE_EXTEND_CONTRACT
		Return ResolveTeammateExtendContractGold(chosenSpeaker)
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Return ResolveTeammateRestoreHealthPleasure(chosenSpeaker)
	ElseIf aiChoiceKind == CHOICE_TERMINATE_CONTRACT || aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_DO_NOTHING || aiChoiceKind == CHOICE_THANKS
		Return ResolveTeammateTerminateContract(chosenSpeaker)
	EndIf

	Debug.Notification("TFD: Invalid Recruit Contract outcome.")
	Return False
EndFunction

Bool Function RouteCreatureChoice(Int aiChoiceKind, Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If aiChoiceKind == CHOICE_FIGHT
		Bool okFight = ExecuteGenericFight(chosenSpeaker)
		If okFight
			FinalizeTerminalDialogueRoute("creature_fight")
		EndIf
		Return okFight
	ElseIf aiChoiceKind == CHOICE_FOLLOW_PLAYER || aiChoiceKind == CHOICE_RECRUIT || aiChoiceKind == CHOICE_KIDNAP
		Bool okAssign = AssignCreatureTeammate(chosenSpeaker)
		If okAssign
			FinalizeTerminalDialogueRoute("creature_assign")
		EndIf
		Return okAssign
	ElseIf aiChoiceKind == CHOICE_RELEASE || aiChoiceKind == CHOICE_DO_NOTHING
		Bool okRelease = ReleaseCreatureTeammate(chosenSpeaker)
		If okRelease
			FinalizeTerminalDialogueRoute("creature_release")
		EndIf
		Return okRelease
	ElseIf aiChoiceKind == CHOICE_PLEASURE
		Return StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_VICTORY, "creature_pleasure")
	EndIf

	Debug.Notification("TFD: Invalid Creature outcome.")
	Return False
EndFunction

; ============================================================
; Teammate contract / healing helpers
; ============================================================
Bool Function ResolveTeammateExtendContractGold(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf
	If !TransferPayToSpeaker(chosenSpeaker)
		Return False
	EndIf
	DispatchLegacyEvent(EventTeammateExtendContractGold, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	FinalizeTerminalDialogueRoute("teammate_extend_contract_gold")
	Return True
EndFunction

Bool Function ResolveTeammateExtendContractPleasure(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf
	DispatchLegacyEvent(EventTeammateExtendContractPleasure, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	Return StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_TEAMMATE, "teammate_extend_contract_pleasure")
EndFunction

Bool Function ResolveTeammateRestoreHealthPotion(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf
	DispatchLegacyEvent(EventTeammateRestoreHealthPotion, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	FinalizeTerminalDialogueRoute("teammate_restore_health_potion")
	Return True
EndFunction

Bool Function ResolveTeammateRestoreHealthPleasure(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf
	DispatchLegacyEvent(EventTeammateRestoreHealthPleasure, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	Return StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_TEAMMATE, "teammate_restore_health_pleasure")
EndFunction

Bool Function ResolveTeammateTerminateContract(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	TFDPlayerTeammateQuestScript teammateCtrl = GetTeammateController()
	If chosenSpeaker == None
		Return False
	EndIf
	DispatchLegacyEvent(EventTeammateTerminateContract, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	If teammateCtrl != None
		teammateCtrl.UnregisterTeammate(chosenSpeaker)
	EndIf
	If !chosenSpeaker.IsDead()
		chosenSpeaker.StopCombat()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.SetPlayerTeammate(False, False)
		chosenSpeaker.EvaluatePackage()
	EndIf
	FinalizeTerminalDialogueRoute("teammate_terminate_contract")
	Return True
EndFunction

; ============================================================
; Pleasure helpers
; ============================================================
Bool Function StartPleasureFromSystemSource(Actor akSpeaker, Int aiSourceFlow, String asReason = "")
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If pleasureCtrl == None
		Return False
	EndIf
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	pleasureCtrl.BeginPleasure(chosenSpeaker, aiSourceFlow, 0)
	If pleasureCtrl.AreCoreAliasesValid()
		Bool ok = pleasureCtrl.ChoosePleasure()
		If ok
			FinalizeTerminalDialogueRoute("pleasure_begin_" + asReason)
		EndIf
		Return ok
	EndIf

	pleasureCtrl.BeginAliasAcquire("system_" + asReason)
	FinalizeTerminalDialogueRoute("pleasure_pending_" + asReason)
	Return True
EndFunction

; ============================================================
; Teammate helpers
; ============================================================
Bool Function AssignHumanoidTeammate(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	TFDPlayerTeammateQuestScript teammateCtrl = GetTeammateController()

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	If TFDTeammateFaction != None
		If !chosenSpeaker.IsInFaction(TFDTeammateFaction)
			chosenSpeaker.AddToFaction(TFDTeammateFaction)
		EndIf
		chosenSpeaker.SetFactionRank(TFDTeammateFaction, 0)
	EndIf

	If playerRef != None
		chosenSpeaker.SetRelationshipRank(playerRef, 3)
		playerRef.SetRelationshipRank(chosenSpeaker, 3)
	EndIf

	chosenSpeaker.StopCombat()
	chosenSpeaker.StopCombatAlarm()
	chosenSpeaker.SetPlayerTeammate(True, False)
	chosenSpeaker.EvaluatePackage()
	DispatchLegacyEvent(EventHumanoidTeammateAssign, chosenSpeaker)

	If teammateCtrl != None
		teammateCtrl.EnsureActiveTeammateContract(chosenSpeaker, "system_assign_humanoid_teammate")
		teammateCtrl.ForceRegisterOrRefreshConvertedTeammate(chosenSpeaker, "system_assign_humanoid_teammate")
	EndIf

	Return True
EndFunction

Bool Function ReleaseHumanoidTeammate(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	TFDPlayerTeammateQuestScript teammateCtrl = GetTeammateController()

	If chosenSpeaker == None
		Return False
	EndIf

	If teammateCtrl != None
		teammateCtrl.UnregisterTeammate(chosenSpeaker)
	EndIf

	If !chosenSpeaker.IsDead()
		chosenSpeaker.StopCombat()
		chosenSpeaker.StopCombatAlarm()
		If TFDTeammateFaction != None && chosenSpeaker.IsInFaction(TFDTeammateFaction)
			chosenSpeaker.RemoveFromFaction(TFDTeammateFaction)
		EndIf
		chosenSpeaker.SetPlayerTeammate(False, False)
		chosenSpeaker.EvaluatePackage()
	EndIf

	Return True
EndFunction

Bool Function AssignCreatureTeammate(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	chosenSpeaker.StopCombat()
	chosenSpeaker.StopCombatAlarm()
	chosenSpeaker.EvaluatePackage()
	DispatchLegacyEvent(EventCreatureTeammateAssign, chosenSpeaker)
	Return True
EndFunction

Bool Function ReleaseCreatureTeammate(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker == None
		Return False
	EndIf

	DispatchLegacyEvent(EventCreatureTeammateUnassign, chosenSpeaker)
	If !chosenSpeaker.IsDead()
		chosenSpeaker.StopCombat()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.EvaluatePackage()
	EndIf
	Return True
EndFunction

; ============================================================
; Generic action helpers
; ============================================================
Bool Function ExecuteGenericFight(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	chosenSpeaker.StopCombatAlarm()
	If playerRef != None
		chosenSpeaker.StartCombat(playerRef)
	EndIf
	chosenSpeaker.EvaluatePackage()
	Return True
EndFunction

Bool Function ExecuteVictoryKill(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	chosenSpeaker.StopCombat()
	chosenSpeaker.StopCombatAlarm()
	chosenSpeaker.Kill(playerRef)
	Return True
EndFunction

Bool Function ExecuteVictoryLoot(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)

	If chosenSpeaker == None
		Return False
	EndIf

	If !chosenSpeaker.IsDead()
		chosenSpeaker.StopCombat()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.Kill(playerRef)
		Utility.WaitMenuMode(0.10)
	EndIf

	If playerRef != None
		chosenSpeaker.Activate(playerRef)
	EndIf
	Return True
EndFunction

; ============================================================
; Captive outcome helpers
; ============================================================
Actor Function ResolveCaptiveActor(Actor akSpeaker = None)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	TFDCaptiveBridge captiveCtrl = GetCaptiveController()

	If IsActorValid(chosenSpeaker)
		Trace("ResolveCaptiveActor direct actor=" + chosenSpeaker)
		Return chosenSpeaker
	EndIf
	If captiveCtrl != None
		chosenSpeaker = captiveCtrl.GetResolveCaptor()
		If IsActorValid(chosenSpeaker)
			Trace("ResolveCaptiveActor bridge actor=" + chosenSpeaker)
			Return chosenSpeaker
		EndIf
	EndIf
	Trace("ResolveCaptiveActor failed input=" + akSpeaker + " activeSpeaker=" + GetActiveSpeaker())
	Return None
EndFunction

Function CommitCaptiveBridgeChoice(Bool abReleaseCaptorNoCooldown = False, Bool abClearAll = False)
	TFDCaptiveBridge captiveCtrl = GetCaptiveController()
	If captiveCtrl == None
		Return
	EndIf

	captiveCtrl.CommitCaptiveChoice()
	If abClearAll
		captiveCtrl.ClearAll()
	ElseIf abReleaseCaptorNoCooldown
		captiveCtrl.ReleaseOwnedCaptorNoCooldown()
	EndIf
	captiveCtrl.ClearCallCooldown()
EndFunction

Bool Function ResolveCaptiveWorkChoice(Actor akSpeaker)
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)
	If chosenSpeaker == None
		Debug.Notification("TFD: No valid captor for Work.")
		Return False
	EndIf

	Bool okWork = BeginCaptiveWorkMode(chosenSpeaker)
	If okWork
		DispatchLegacyEvent(EventCaptiveOutcomeWork, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
		FinalizeTerminalDialogueRoute("captive_work", True)
	EndIf
	Return okWork
EndFunction

Bool Function ResolveCaptiveReturnChoice(Actor akSpeaker)
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)
	If chosenSpeaker == None
		Debug.Notification("TFD: No valid captor.")
		Return False
	EndIf

	If CaptiveWorkActive
		StopCaptiveWorkMode(True, False, "captive_return")
	Else
		CommitCaptiveBridgeChoice(True, False)
		ClearTransientDialogueBridges()
		SetCaptivePhaseValue(CAPTIVE_PHASE_CAPTIVE)
	EndIf

	DispatchLegacyEvent(EventCaptiveOutcomeReturn, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	FinalizeTerminalDialogueRoute("captive_return")
	Return True
EndFunction

Bool Function ResolveCaptiveReleaseChoice(Actor akSpeaker, String asReason = "captive_release")
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)

	If chosenSpeaker == None
		Debug.Notification("TFD: No valid captor to release.")
		Return False
	EndIf

	ClearCaptiveWorkState()
	CommitCaptiveBridgeChoice(False, True)
	SendQuestEvent("TFDCaptiveClearAll")
	ClearTransientDialogueBridges()
	SetCaptivePhaseValue(CAPTIVE_PHASE_NONE)
	DispatchLegacyEvent(EventCaptiveOutcomeRelease, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	FinalizeTerminalDialogueRoute(asReason)
	Return True
EndFunction

Bool Function ResolveCaptivePayChoice(Actor akSpeaker)
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)
	If chosenSpeaker == None
		Debug.Notification("TFD: No valid captor to pay.")
		Return False
	EndIf
	If !TransferPayToSpeaker(chosenSpeaker)
		Debug.Notification("TFD: Pay failed.")
		Return False
	EndIf
	Return ResolveCaptiveReleaseChoice(chosenSpeaker, "captive_pay")
EndFunction

Bool Function ResolveCaptiveEscapeChoice(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)

	If playerRef == None || chosenSpeaker == None || chosenSpeaker.IsDead()
		Debug.Notification("TFD: No valid captor to fight.")
		Return False
	EndIf

	CommitCaptiveBridgeChoice(True, False)
	ClearTransientDialogueBridges()
	SetCaptivePhaseValue(CAPTIVE_PHASE_ESCAPE)
	DispatchLegacyEvent(EventCaptiveOutcomeEscape, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)

	If chosenSpeaker.Is3DLoaded()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.StartCombat(playerRef)
		chosenSpeaker.EvaluatePackage()
	EndIf

	FinalizeTerminalDialogueRoute("captive_escape")
	Return True
EndFunction

Bool Function ResolveCaptivePleasureChoice(Actor akSpeaker)
	Actor chosenSpeaker = ResolveCaptiveActor(akSpeaker)
	If chosenSpeaker == None
		Debug.Notification("TFD: No valid captor for Pleasure.")
		Return False
	EndIf

	CommitCaptiveBridgeChoice(True, False)
	SetCaptivePhaseValue(4)
	DispatchLegacyEvent(EventCaptiveOutcomePleasure, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)

	Bool okPleasure = StartPleasureFromSystemSource(chosenSpeaker, PLEASURE_SOURCE_CAPTIVE, "captive_pleasure")
	If !okPleasure
		SetCaptivePhaseValue(CAPTIVE_PHASE_CAPTIVE)
		DispatchLegacyEvent(EventCaptiveOutcomeReturn, chosenSpeaker, ActorFormIDString(chosenSpeaker), 0.0)
	EndIf
	Return okPleasure
EndFunction

; ============================================================
; Captive work compatibility
; ============================================================
Function SetCaptivePhaseValue(Int aiPhase)
	CurrentCaptivePhaseState = aiPhase
	If TFDCaptiveState != None
		TFDCaptiveState.SetValue(aiPhase as Float)
	EndIf
EndFunction

Function ClearCaptiveWorkState()
	CaptiveWorkActive = False
	CaptiveWorkSpeaker = None
	CaptiveWorkLocation = None
	CurrentCaptivePhaseState = CAPTIVE_PHASE_NONE
EndFunction

Function StopCaptiveWorkMode(Bool restoreCaptivePhase, Bool startHostile, String asReason)
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = CaptiveWorkSpeaker
	TFDCaptiveBridge captiveCtrl = GetCaptiveController()

	ClearCaptiveWorkState()
	ClearTransientDialogueBridges()

	If restoreCaptivePhase
		SetCaptivePhaseValue(CAPTIVE_PHASE_CAPTIVE)
	Else
		SetCaptivePhaseValue(CAPTIVE_PHASE_ESCAPE)
	EndIf

	If captiveCtrl != None
		captiveCtrl.ClearCallCooldown()
	EndIf

	If speakerRef != None && !speakerRef.IsDead()
		If speakerRef.Is3DLoaded()
			speakerRef.StopCombatAlarm()
			If startHostile && playerRef != None
				speakerRef.StartCombat(playerRef)
			Else
				speakerRef.StopCombat()
			EndIf
			speakerRef.EvaluatePackage()
		EndIf
	EndIf
EndFunction

Bool Function BeginCaptiveWorkMode(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	TFDCaptiveBridge captiveCtrl = GetCaptiveController()

	If playerRef == None
		Return False
	EndIf
	If CurrentFlowKind != FLOW_CAPTIVE && !CaptiveWorkActive
		Debug.Notification("TFD: Work is only valid during Captive flow.")
		Return False
	EndIf
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		If captiveCtrl != None
			chosenSpeaker = captiveCtrl.GetResolveCaptor()
		EndIf
	EndIf
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Debug.Notification("TFD: No valid captor for Work.")
		Return False
	EndIf

	If captiveCtrl != None
		captiveCtrl.CommitCaptiveChoice()
		captiveCtrl.ReleaseOwnedCaptorNoCooldown()
		captiveCtrl.ClearCallCooldown()
	EndIf

	CaptiveWorkActive = True
	CaptiveWorkSpeaker = chosenSpeaker
	CaptiveWorkLocation = playerRef.GetCurrentLocation()
	SetActiveFlow(FLOW_CAPTIVE, chosenSpeaker)
	ClearTransientDialogueBridges()
	SetCaptivePhaseValue(CAPTIVE_PHASE_RELEASED_WORK)

	If chosenSpeaker.Is3DLoaded()
		chosenSpeaker.StopCombat()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.EvaluatePackage()
	EndIf

	RegisterForSingleUpdate(CaptiveWorkUpdateInterval)
	Return True
EndFunction

Function UpdateCaptiveWorkMode()
	Actor playerRef = Game.GetPlayer()
	Actor speakerRef = CaptiveWorkSpeaker

	If !CaptiveWorkActive
		Return
	EndIf
	If playerRef == None
		ClearCaptiveWorkState()
		Return
	EndIf
	If speakerRef == None || speakerRef.IsDead()
		StopCaptiveWorkMode(True, False, "speaker_lost")
		Return
	EndIf
	If CaptiveWorkLocation != None
		If playerRef.GetCurrentLocation() != CaptiveWorkLocation
			StopCaptiveWorkMode(False, True, "leave_location")
			Return
		EndIf
	EndIf
	If playerRef.IsInCombat() || speakerRef.IsInCombat() || speakerRef.IsHostileToActor(playerRef)
		StopCaptiveWorkMode(False, True, "hostile_violation")
		Return
	EndIf

	If speakerRef.Is3DLoaded()
		speakerRef.StopCombatAlarm()
		speakerRef.EvaluatePackage()
	EndIf

	RegisterForSingleUpdate(CaptiveWorkUpdateInterval)
EndFunction