Scriptname TFDSystemEventQuestScript extends Quest

; ============================================================
; TFD centralized dialogue outcome router
; ------------------------------------------------------------
; Current patch goal:
; - keep all dialogue fragments pointed to one script
; - keep non-Pleasure dialogue outcomes in this system quest
; - pleasure runtime ownership has been moved out
; ============================================================

; -------------------------------
; Active flow tracking
; -------------------------------
ReferenceAlias Property ActiveSpeaker Auto

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

Int Property OUTCOME_NONE = 0 AutoReadOnly
Int Property OUTCOME_KIDNAP = 1 AutoReadOnly
Int Property OUTCOME_PAY = 2 AutoReadOnly
Int Property OUTCOME_FIGHT = 3 AutoReadOnly
Int Property OUTCOME_RECRUIT = 4 AutoReadOnly
Int Property OUTCOME_JOIN_ENEMY = 5 AutoReadOnly
Int Property OUTCOME_RELEASE = 6 AutoReadOnly
Int Property OUTCOME_PLEASURE = 7 AutoReadOnly
Int Property OUTCOME_FOLLOW_PLAYER = 8 AutoReadOnly
Int Property OUTCOME_DO_NOTHING = 9 AutoReadOnly
Int Property OUTCOME_WORK = 10 AutoReadOnly
Int Property OUTCOME_LOOT_ENEMY = 11 AutoReadOnly
Int Property OUTCOME_KILL_ENEMY = 12 AutoReadOnly
Int Property OUTCOME_THANKS = 13 AutoReadOnly
Int Property OUTCOME_EXTEND_CONTRACT = 14 AutoReadOnly
Int Property OUTCOME_TERMINATE_CONTRACT = 15 AutoReadOnly

; -------------------------------
; Route recorder v2 (transitional)
; Choice = literal player/system choice
; Result = resolved gameplay result after context evaluation
; -------------------------------
Int Property ENTRY_NONE = 0 AutoReadOnly
Int Property ENTRY_HOTKEY = 1 AutoReadOnly
Int Property ENTRY_FORCEGREET = 2 AutoReadOnly
Int Property ENTRY_CAPTIVE_CALL = 3 AutoReadOnly
Int Property ENTRY_AUTO = 4 AutoReadOnly
Int Property ENTRY_SCENE_RETURN = 5 AutoReadOnly
Int Property ENTRY_KIDNAP_TELEPORT = 6 AutoReadOnly
Int Property ENTRY_BLEED_DO_NOTHING_MARKER = 7 AutoReadOnly
Int Property ENTRY_BLEED_DIALOG_CLOSE_MARKER = 8 AutoReadOnly
Int Property ENTRY_BLEED_BLACKOUT = 9 AutoReadOnly

Int Property METHOD_NONE = 0 AutoReadOnly
Int Property METHOD_DIRECT = 1 AutoReadOnly
Int Property METHOD_PAY = 2 AutoReadOnly
Int Property METHOD_PLEASURE = 3 AutoReadOnly

Int Property BRANCH_NONE = 0 AutoReadOnly
Int Property BRANCH_MAIN = 1 AutoReadOnly
Int Property BRANCH_PAY = 2 AutoReadOnly
Int Property BRANCH_PLEASURE = 3 AutoReadOnly
Int Property BRANCH_RELEASE_CONFIRM = 10 AutoReadOnly
Int Property BRANCH_FOLLOW_CONFIRM = 11 AutoReadOnly
Int Property BRANCH_JOIN_ME_CONFIRM = 12 AutoReadOnly
Int Property BRANCH_JOIN_ENEMY_CONFIRM = 13 AutoReadOnly
Int Property BRANCH_FIGHT_CONFIRM = 14 AutoReadOnly
Int Property BRANCH_KIDNAP_CONFIRM = 15 AutoReadOnly
Int Property BRANCH_WORK_CONFIRM = 16 AutoReadOnly
Int Property BRANCH_DO_NOTHING_CONFIRM = 17 AutoReadOnly

Int Property STAGE_NONE = 0 AutoReadOnly
Int Property STAGE_OPENED = 1 AutoReadOnly
Int Property STAGE_NEGOTIATING = 2 AutoReadOnly
Int Property STAGE_METHOD_SELECTED = 3 AutoReadOnly
Int Property STAGE_CHOICE_COMMITTED = 4 AutoReadOnly
Int Property STAGE_RESULT_RESOLVED = 5 AutoReadOnly
Int Property STAGE_SCENE_START_PENDING = 6 AutoReadOnly
Int Property STAGE_SCENE_ACTIVE = 7 AutoReadOnly
Int Property STAGE_AWAIT_AFTERPLEASURE = 8 AutoReadOnly
Int Property STAGE_CLOSED_RESOLVED = 9 AutoReadOnly
Int Property STAGE_CLOSED_NO_COMMIT = 10 AutoReadOnly
Int Property STAGE_ABORTED = 11 AutoReadOnly

Int Property CHOICE_NONE = 0 AutoReadOnly
Int Property CHOICE_FIGHT = 1 AutoReadOnly
Int Property CHOICE_KIDNAP = 2 AutoReadOnly
Int Property CHOICE_DO_NOTHING = 3 AutoReadOnly
Int Property CHOICE_RELEASE_ME = 4 AutoReadOnly
Int Property CHOICE_FOLLOW_ME = 5 AutoReadOnly
Int Property CHOICE_JOIN_ME = 6 AutoReadOnly
Int Property CHOICE_JOIN_ENEMY = 7 AutoReadOnly
Int Property CHOICE_WORK = 8 AutoReadOnly
Int Property CHOICE_RECRUIT = 9 AutoReadOnly
Int Property CHOICE_LOOT_ENEMY = 10 AutoReadOnly
Int Property CHOICE_KILL_ENEMY = 11 AutoReadOnly
Int Property CHOICE_THANKS = 12 AutoReadOnly
Int Property CHOICE_EXTEND_CONTRACT = 13 AutoReadOnly
Int Property CHOICE_TERMINATE_CONTRACT = 14 AutoReadOnly

Int Property CHOICE_SOURCE_NONE = 0 AutoReadOnly
Int Property CHOICE_SOURCE_EXPLICIT_DIALOG = 1 AutoReadOnly
Int Property CHOICE_SOURCE_DIALOG_CLOSED_NO_COMMIT = 2 AutoReadOnly
Int Property CHOICE_SOURCE_SCENE_CALLBACK = 3 AutoReadOnly
Int Property CHOICE_SOURCE_SYSTEM_RESOLVE = 4 AutoReadOnly

Int Property RESULT_NONE = 0 AutoReadOnly
Int Property RESULT_RESUME_PRECOMBAT_HOSTILE = 1 AutoReadOnly
Int Property RESULT_RESUME_INCOMBAT_HOSTILE = 2 AutoReadOnly
Int Property RESULT_CAPTIVE = 3 AutoReadOnly
Int Property RESULT_LEFT_FOR_DEAD = 4 AutoReadOnly
Int Property RESULT_TEMP_RELEASE = 5 AutoReadOnly
Int Property RESULT_TEMP_FOLLOW = 6 AutoReadOnly
Int Property RESULT_JOIN_PLAYER = 7 AutoReadOnly
Int Property RESULT_JOIN_ENEMY = 8 AutoReadOnly
Int Property RESULT_WORK_STATE = 9 AutoReadOnly
Int Property RESULT_RECRUIT_STATE = 10 AutoReadOnly
Int Property RESULT_VICTORY_NEUTRAL_RELEASE = 11 AutoReadOnly
Int Property RESULT_VICTORY_EXECUTION = 12 AutoReadOnly
Int Property RESULT_VICTORY_LOOT = 13 AutoReadOnly
Int Property RESULT_EXTEND_CONTRACT = 14 AutoReadOnly
Int Property RESULT_TERMINATE_CONTRACT = 15 AutoReadOnly
Int Property RESULT_CAPTIVE_IDLE = 16 AutoReadOnly

; -------------------------------
; Existing quest scripts in current baseline
; -------------------------------
Quest Property TFDPreCombatQuest Auto
Quest Property TFDBleedoutQuest Auto
Quest Property TFDPleasureQuest Auto
Quest Property TFDDialogue Auto
GlobalVariable Property TFDPayGold Auto
MiscObject Property Gold001 Auto

; -------------------------------
; Future / placeholder quest holders
; -------------------------------
Quest Property TFDCaptiveQuest Auto
Quest Property TFDVictoryQuest Auto
Quest Property TFDSaviorQuest Auto
Quest Property TFDRecruitQuest Auto
Quest Property TFDCreatureQuest Auto
Quest Property TFDTruceQuest Auto
Quest Property TFDCaptiveBridgeQuest Auto
GlobalVariable Property TFDCaptiveState Auto
GlobalVariable Property TFDCaptiveMarkerState Auto

Float Property CaptiveWorkUpdateInterval = 0.50 Auto
Int Property CAPTIVE_PHASE_NONE = 0 AutoReadOnly
Int Property CAPTIVE_PHASE_CAPTIVE = 1 AutoReadOnly
Int Property CAPTIVE_PHASE_ESCAPE = 2 AutoReadOnly
Int Property CAPTIVE_PHASE_RELEASED_WORK = 3 AutoReadOnly

Actor CaptiveWorkSpeaker = None
Location CaptiveWorkLocation = None
Bool CaptiveWorkActive = False
Int CurrentCaptivePhaseState = 0

; -------------------------------
; Route recorder runtime
; -------------------------------
Int CurrentRouteToken = 0
Int CurrentRootFlow = 0
Int CurrentEntryMode = 0
Int CurrentMethod = 0
Int CurrentBranch = 0
Int CurrentRouteStage = 0
Int CurrentChoice = 0
Int CurrentChoiceSource = 0
Int CurrentResolvedResult = 0

Actor CurrentRouteSpeaker = None
Float CurrentRouteStartedAt = 0.0

Bool CurrentRouteActive = False
Bool CurrentRouteSceneLocked = False
Bool CurrentChoiceCommitted = False
Bool CurrentResultCommitted = False
String CurrentRouteReason = ""

Bool Property ClearTransientDialoguesOnPlayerLoadGame = True Auto
Bool Property PreserveCaptiveRuntimeOnPlayerLoadGame = True Auto
Float Property HygienePostLoadRetryInterval = 0.75 Auto
Int Property HygienePostLoadRetryCount = 4 Auto
Int PendingHygienePostLoadRetries = 0

Event OnInit()
	ClearCaptiveWorkState()
	CurrentCaptivePhaseState = CAPTIVE_PHASE_NONE
	RegisterRouteEvents()
	RunTransientHygiene(False)
EndEvent

Event OnPlayerLoadGame()
	ClearCaptiveWorkState()
	CurrentCaptivePhaseState = CAPTIVE_PHASE_NONE
	ResetRouteRecorderState()
	ClearActiveFlow()

	If ClearTransientDialoguesOnPlayerLoadGame
		ClearPreCombatFlow(None)
		ClearBleedoutFlow(None)
		ClearTruceFlow()
		ClearInCombatFlow()
	EndIf

	TFDCaptiveBridge captiveCtrlLoad = GetCaptiveBridgeController()
	If captiveCtrlLoad != None
		If PreserveCaptiveRuntimeOnPlayerLoadGame
			captiveCtrlLoad.ResetDialogueStateOnLoad()
		Else
			captiveCtrlLoad.ClearAll()
		EndIf
	EndIf

	RegisterRouteEvents()
	PendingHygienePostLoadRetries = HygienePostLoadRetryCount
	RegisterForSingleUpdate(HygienePostLoadRetryInterval)
EndEvent

Function RegisterRouteEvents()
	RegisterForModEvent("TFDPreCombatAssign", "OnRouteBeginEvent")
	RegisterForModEvent("TFDInCombatAssign", "OnRouteBeginEvent")
	RegisterForModEvent("TFDBleedoutPrimeSpeaker", "OnRouteBeginEvent")
	RegisterForModEvent("TFDBleedImplicitCloseNoCommit", "OnImplicitBleedCloseNoCommitEvent")
EndFunction

Function EnsureDialogueRouteFromEvent(Int aiFlow, Int aiEntryMode, Actor akSpeaker = None, String asReason = "")
	If CurrentRouteActive && CurrentRootFlow == aiFlow
		If akSpeaker == None || CurrentRouteSpeaker == akSpeaker
			If CurrentRouteStage < STAGE_SCENE_START_PENDING
				MarkDialogueNegotiating(akSpeaker, asReason)
			EndIf
			Return
		EndIf
	EndIf
	BeginDialogueRoute(aiFlow, aiEntryMode, akSpeaker, asReason)
	MarkDialogueNegotiating(akSpeaker, asReason)
EndFunction

Event OnRouteBeginEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor akSpeaker = sender as Actor
	If eventName == "TFDPreCombatAssign"
		EnsureDialogueRouteFromEvent(FLOW_PRECOMBAT, ENTRY_HOTKEY, akSpeaker, "mod_event_precombat_assign")
	ElseIf eventName == "TFDInCombatAssign"
		EnsureDialogueRouteFromEvent(FLOW_INCOMBAT, ENTRY_HOTKEY, akSpeaker, "mod_event_incombat_assign")
	ElseIf eventName == "TFDBleedoutPrimeSpeaker"
		EnsureDialogueRouteFromEvent(FLOW_BLEEDOUT, ENTRY_HOTKEY, akSpeaker, "mod_event_bleedout_prime")
	EndIf
EndEvent

Event OnImplicitBleedCloseNoCommitEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor akSpeaker = sender as Actor
	RecordImplicitBleedoutCloseNoCommit(akSpeaker)
EndEvent

; -------------------------------
; Typed accessors
; -------------------------------
TFDPreCombatQuestScript Function GetPreCombatController()
	If TFDPreCombatQuest == None
		Return None
	EndIf
	Return TFDPreCombatQuest as TFDPreCombatQuestScript
EndFunction

TFDBleedoutQuestScript Function GetBleedoutController()
	If TFDBleedoutQuest == None
		Return None
	EndIf
	Return TFDBleedoutQuest as TFDBleedoutQuestScript
EndFunction

TFDPleasureQuestScript Function GetPleasureController()
	If TFDPleasureQuest == None
		Return None
	EndIf
	Return TFDPleasureQuest as TFDPleasureQuestScript
EndFunction

TFDCaptiveBridge Function GetCaptiveBridgeController()
	If TFDCaptiveBridgeQuest == None
		Return None
	EndIf
	Return TFDCaptiveBridgeQuest as TFDCaptiveBridge
EndFunction

; -------------------------------
; Context helpers
; -------------------------------
Function SetActiveFlow(Int aiFlow, Actor akSpeaker = None)
	If ActiveSpeaker != None
		If akSpeaker != None
			ActiveSpeaker.ForceRefTo(akSpeaker)
		Else
			ActiveSpeaker.Clear()
		EndIf
	EndIf
EndFunction

Function ClearActiveFlow()
	SetActiveFlow(FLOW_NONE, None)
EndFunction

Function ResetRouteRecorderState(Bool abKeepToken = False)
	If !abKeepToken
		CurrentRouteToken = 0
	EndIf
	CurrentRouteActive = False
	CurrentRouteSceneLocked = False
	CurrentRootFlow = FLOW_NONE
	CurrentEntryMode = ENTRY_NONE
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_NONE
	CurrentRouteStage = STAGE_NONE
	CurrentChoice = CHOICE_NONE
	CurrentChoiceSource = CHOICE_SOURCE_NONE
	CurrentResolvedResult = RESULT_NONE
	CurrentChoiceCommitted = False
	CurrentResultCommitted = False
	CurrentRouteSpeaker = None
	CurrentRouteStartedAt = 0.0
	CurrentRouteReason = ""
EndFunction

Bool Function IsActorStaleForFlow(Actor akActor)
	If akActor == None
		Return True
	EndIf

	If akActor.IsDead()
		Return True
	EndIf

	Return False
EndFunction

Function RunTransientHygiene(Bool abAbortDeadRoute = True)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	TFDCaptiveBridge captiveCtrl = GetCaptiveBridgeController()
	Actor cachedSpeaker = GetCachedSpeaker()

	If preCtrl != None
		preCtrl.GetSpeaker()
	EndIf

	If bleedCtrl != None
		bleedCtrl.GetSpeaker()
	EndIf

	If captiveCtrl != None
		captiveCtrl.PruneStaleRuntimeRefs()
	EndIf

	If cachedSpeaker != None && cachedSpeaker.IsDead()
		ClearActiveFlow()
	EndIf

	If abAbortDeadRoute && CurrentRouteSpeaker != None && CurrentRouteSpeaker.IsDead()
		AbortDialogueRoute("hygiene_dead_route_speaker", CurrentRouteSpeaker)
		ResetRouteRecorderState(True)
	EndIf

	If !CurrentRouteActive && !CaptiveWorkActive
		If InferLiveFlow(None) == FLOW_NONE
			ClearActiveFlow()
		EndIf
	EndIf
EndFunction

Function BeginDialogueRoute(Int aiFlow, Int aiEntryMode, Actor akSpeaker = None, String asReason = "")
	CurrentRouteToken += 1
	CurrentRouteActive = True
	CurrentRouteSceneLocked = False
	CurrentRootFlow = aiFlow
	CurrentEntryMode = aiEntryMode
	CurrentMethod = METHOD_NONE
	CurrentBranch = BRANCH_MAIN
	CurrentRouteStage = STAGE_OPENED
	CurrentChoice = CHOICE_NONE
	CurrentChoiceSource = CHOICE_SOURCE_NONE
	CurrentResolvedResult = RESULT_NONE
	CurrentChoiceCommitted = False
	CurrentResultCommitted = False
	CurrentRouteSpeaker = akSpeaker
	CurrentRouteStartedAt = Utility.GetCurrentRealTime()
	CurrentRouteReason = asReason
	SetActiveFlow(aiFlow, akSpeaker)
EndFunction

Function MarkDialogueNegotiating(Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return
	EndIf
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	CurrentRouteStage = STAGE_NEGOTIATING
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Bool Function SetDialogueMethod(Int aiMethod, Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return False
	EndIf
	CurrentMethod = aiMethod
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	CurrentRouteStage = STAGE_METHOD_SELECTED
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
	Return True
EndFunction

Function SetDialogueBranch(Int aiBranch, Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return
	EndIf
	CurrentBranch = aiBranch
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Bool Function RecordDialogueChoice(Int aiChoice, Int aiChoiceSource, Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return False
	EndIf
	CurrentChoice = aiChoice
	CurrentChoiceSource = aiChoiceSource
	CurrentChoiceCommitted = True
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	CurrentRouteStage = STAGE_CHOICE_COMMITTED
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
	Return True
EndFunction

Bool Function HasCaptiveMarkerForCurrentContext()
	If TFDCaptiveMarkerState == None
		Return False
	EndIf
	Return TFDCaptiveMarkerState.GetValueInt() != 0
EndFunction

Int Function ResolveChoiceToResult(Int aiFlow, Int aiMethod, Int aiChoice, Actor akSpeaker = None)
	If aiChoice == CHOICE_NONE
		Return RESULT_NONE
	EndIf

	If aiFlow == FLOW_PRECOMBAT
		If aiChoice == CHOICE_FIGHT || aiChoice == CHOICE_DO_NOTHING
			Return RESULT_RESUME_PRECOMBAT_HOSTILE
		ElseIf aiChoice == CHOICE_KIDNAP
			Return RESULT_CAPTIVE
		ElseIf aiChoice == CHOICE_RELEASE_ME
			Return RESULT_TEMP_RELEASE
		ElseIf aiChoice == CHOICE_FOLLOW_ME
			Return RESULT_TEMP_FOLLOW
		ElseIf aiChoice == CHOICE_JOIN_ME
			Return RESULT_JOIN_PLAYER
		ElseIf aiChoice == CHOICE_JOIN_ENEMY
			Return RESULT_JOIN_ENEMY
		ElseIf aiChoice == CHOICE_RECRUIT
			Return RESULT_RECRUIT_STATE
		EndIf
	ElseIf aiFlow == FLOW_INCOMBAT
		If aiChoice == CHOICE_FIGHT || aiChoice == CHOICE_DO_NOTHING
			Return RESULT_RESUME_INCOMBAT_HOSTILE
		ElseIf aiChoice == CHOICE_KIDNAP
			Return RESULT_CAPTIVE
		ElseIf aiChoice == CHOICE_RELEASE_ME
			Return RESULT_TEMP_RELEASE
		ElseIf aiChoice == CHOICE_FOLLOW_ME
			Return RESULT_TEMP_FOLLOW
		ElseIf aiChoice == CHOICE_JOIN_ME
			Return RESULT_JOIN_PLAYER
		ElseIf aiChoice == CHOICE_JOIN_ENEMY
			Return RESULT_JOIN_ENEMY
		EndIf
	ElseIf aiFlow == FLOW_BLEEDOUT
		If aiChoice == CHOICE_KIDNAP
			Return RESULT_CAPTIVE
		ElseIf aiChoice == CHOICE_DO_NOTHING
			If HasCaptiveMarkerForCurrentContext()
				Return RESULT_CAPTIVE
			EndIf
			Return RESULT_LEFT_FOR_DEAD
		ElseIf aiChoice == CHOICE_RELEASE_ME
			Return RESULT_TEMP_RELEASE
		ElseIf aiChoice == CHOICE_FOLLOW_ME
			Return RESULT_TEMP_FOLLOW
		EndIf
	ElseIf aiFlow == FLOW_CAPTIVE
		If aiChoice == CHOICE_WORK
			Return RESULT_WORK_STATE
		ElseIf aiChoice == CHOICE_DO_NOTHING
			Return RESULT_CAPTIVE_IDLE
		ElseIf aiChoice == CHOICE_RELEASE_ME
			Return RESULT_TEMP_RELEASE
		ElseIf aiChoice == CHOICE_FOLLOW_ME
			Return RESULT_TEMP_FOLLOW
		ElseIf aiChoice == CHOICE_JOIN_ME
			Return RESULT_JOIN_PLAYER
		ElseIf aiChoice == CHOICE_JOIN_ENEMY
			Return RESULT_JOIN_ENEMY
		EndIf
	ElseIf aiFlow == FLOW_VICTORY
		If aiChoice == CHOICE_RECRUIT
			Return RESULT_RECRUIT_STATE
		ElseIf aiChoice == CHOICE_LOOT_ENEMY
			Return RESULT_VICTORY_LOOT
		ElseIf aiChoice == CHOICE_KILL_ENEMY
			Return RESULT_VICTORY_EXECUTION
		ElseIf aiChoice == CHOICE_THANKS
			Return RESULT_VICTORY_NEUTRAL_RELEASE
		ElseIf aiChoice == CHOICE_EXTEND_CONTRACT
			Return RESULT_EXTEND_CONTRACT
		ElseIf aiChoice == CHOICE_TERMINATE_CONTRACT
			Return RESULT_TERMINATE_CONTRACT
		EndIf
	EndIf

	Return RESULT_NONE
EndFunction

Bool Function CommitResolvedResult(Int aiResult, Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return False
	EndIf
	CurrentResolvedResult = aiResult
	CurrentResultCommitted = True
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	CurrentRouteStage = STAGE_RESULT_RESOLVED
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
	Return True
EndFunction

Bool Function ResolveRecordedChoice(Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return False
	EndIf
	If !CurrentChoiceCommitted
		Return False
	EndIf
	Int resolved = ResolveChoiceToResult(CurrentRootFlow, CurrentMethod, CurrentChoice, akSpeaker)
	Return CommitResolvedResult(resolved, akSpeaker, asReason)
EndFunction

Function MarkRouteSceneStartPending(Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return
	EndIf
	CurrentRouteSceneLocked = True
	CurrentRouteStage = STAGE_SCENE_START_PENDING
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Function MarkRouteSceneActive(Actor akSpeaker = None, String asReason = "")
	If !CurrentRouteActive
		Return
	EndIf
	CurrentRouteSceneLocked = True
	CurrentRouteStage = STAGE_SCENE_ACTIVE
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Function CloseDialogueRouteResolved(String asReason = "")
	If !CurrentRouteActive
		Return
	EndIf
	CurrentRouteStage = STAGE_CLOSED_RESOLVED
	CurrentRouteSceneLocked = False
	CurrentRouteActive = False
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Function CloseDialogueRouteNoCommit(String asReason = "", Actor akSpeaker = None)
	If !CurrentRouteActive
		Return
	EndIf
	CurrentRouteStage = STAGE_CLOSED_NO_COMMIT
	CurrentRouteSceneLocked = False
	CurrentRouteActive = False
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Function AbortDialogueRoute(String asReason = "", Actor akSpeaker = None)
	If !CurrentRouteActive
		Return
	EndIf
	CurrentRouteStage = STAGE_ABORTED
	CurrentRouteSceneLocked = False
	CurrentRouteActive = False
	If akSpeaker != None
		CurrentRouteSpeaker = akSpeaker
	EndIf
	If asReason != ""
		CurrentRouteReason = asReason
	EndIf
EndFunction

Bool Function HasActiveDialogueRoute()
	Return CurrentRouteActive
EndFunction

Bool Function HasCommittedChoice()
	Return CurrentChoiceCommitted
EndFunction

Bool Function HasCommittedResult()
	Return CurrentResultCommitted
EndFunction

Int Function GetCurrentRouteFlow()
	Return CurrentRootFlow
EndFunction

Int Function GetCurrentRouteMethod()
	Return CurrentMethod
EndFunction

Int Function GetCurrentRouteBranch()
	Return CurrentBranch
EndFunction

Int Function GetCurrentRouteStage()
	Return CurrentRouteStage
EndFunction

Int Function GetCurrentChoice()
	Return CurrentChoice
EndFunction

Int Function GetCurrentChoiceSource()
	Return CurrentChoiceSource
EndFunction

Int Function GetCurrentResolvedResult()
	Return CurrentResolvedResult
EndFunction

Int Function GetCurrentRouteToken()
	Return CurrentRouteToken
EndFunction

Actor Function GetCurrentRouteSpeaker()
	Return CurrentRouteSpeaker
EndFunction

Bool Function IsRouteSceneLocked()
	Return CurrentRouteSceneLocked
EndFunction

Bool Function IsFallbackAllowed()
	If !CurrentRouteActive
		Return True
	EndIf
	Int stageValue = CurrentRouteStage
	If stageValue == STAGE_METHOD_SELECTED || stageValue == STAGE_CHOICE_COMMITTED || stageValue == STAGE_RESULT_RESOLVED || stageValue == STAGE_SCENE_START_PENDING || stageValue == STAGE_SCENE_ACTIVE || stageValue == STAGE_AWAIT_AFTERPLEASURE
		Return False
	EndIf
	Return True
EndFunction

Bool Function IsEscapeDetectionAllowed()
	If !CurrentRouteActive
		Return True
	EndIf
	Int stageValue = CurrentRouteStage
	If stageValue == STAGE_SCENE_START_PENDING || stageValue == STAGE_SCENE_ACTIVE || stageValue == STAGE_AWAIT_AFTERPLEASURE
		Return False
	EndIf
	Return True
EndFunction

Bool Function IsHostileRestoreAllowed()
	If !CurrentRouteActive
		Return True
	EndIf
	Int stageValue = CurrentRouteStage
	If stageValue == STAGE_METHOD_SELECTED || stageValue == STAGE_CHOICE_COMMITTED || stageValue == STAGE_RESULT_RESOLVED || stageValue == STAGE_SCENE_START_PENDING || stageValue == STAGE_SCENE_ACTIVE || stageValue == STAGE_AWAIT_AFTERPLEASURE
		Return False
	EndIf
	Return True
EndFunction

Int Function GetActiveFlow()
	If CurrentRouteActive && CurrentRootFlow != FLOW_NONE
		Return CurrentRootFlow
	EndIf

	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	If preCtrl != None
		Actor preSpeaker = preCtrl.GetSpeaker()
		If preSpeaker != None && !preSpeaker.IsDead()
			Return FLOW_PRECOMBAT
		EndIf
	EndIf

	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	If bleedCtrl != None
		Actor bleedSpeaker = bleedCtrl.GetSpeaker()
		If bleedSpeaker != None && !bleedSpeaker.IsDead()
			Return FLOW_BLEEDOUT
		EndIf
	EndIf

	If IsCaptiveDialogueFlowLive()
		TFDCaptiveBridge captiveCtrl = GetCaptiveBridgeController()
		If captiveCtrl != None
			Actor captiveSpeaker = captiveCtrl.GetResolveCaptor()
			If captiveSpeaker != None && !captiveSpeaker.IsDead()
				Return FLOW_CAPTIVE
			EndIf
		EndIf
	EndIf

	Return FLOW_NONE
EndFunction

Int Function InferLiveFlow(Actor akSpeaker = None)
	If CurrentRouteActive && CurrentRootFlow != FLOW_NONE
		Return CurrentRootFlow
	EndIf

	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	If preCtrl != None
		Actor preSpeaker = preCtrl.GetSpeaker()
		If preSpeaker != None && !preSpeaker.IsDead()
			Return FLOW_PRECOMBAT
		EndIf
	EndIf

	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	If bleedCtrl != None
		Actor bleedSpeaker = bleedCtrl.GetSpeaker()
		If bleedSpeaker != None && !bleedSpeaker.IsDead()
			Return FLOW_BLEEDOUT
		EndIf
	EndIf

	If IsCaptiveDialogueFlowLive()
		TFDCaptiveBridge captiveCtrl = GetCaptiveBridgeController()
		If captiveCtrl != None
			Actor captiveSpeaker = captiveCtrl.GetResolveCaptor()
			If captiveSpeaker != None && !captiveSpeaker.IsDead()
				Return FLOW_CAPTIVE
			EndIf
		EndIf
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker != None && !chosenSpeaker.IsDead()
		TFDPreCombatQuestScript preCtrl2 = GetPreCombatController()
		If preCtrl2 != None
			Actor preSpeaker2 = preCtrl2.GetSpeaker()
			If preSpeaker2 == chosenSpeaker
				Return FLOW_PRECOMBAT
			EndIf
		EndIf

		TFDBleedoutQuestScript bleedCtrl2 = GetBleedoutController()
		If bleedCtrl2 != None
			Actor bleedSpeaker2 = bleedCtrl2.GetSpeaker()
			If bleedSpeaker2 == chosenSpeaker
				Return FLOW_BLEEDOUT
			EndIf
		EndIf

		If IsCaptiveDialogueFlowLive()
			TFDCaptiveBridge captiveCtrl2 = GetCaptiveBridgeController()
			If captiveCtrl2 != None
				Actor captiveSpeaker2 = captiveCtrl2.GetResolveCaptor()
				If captiveSpeaker2 == chosenSpeaker
					Return FLOW_CAPTIVE
				EndIf
			EndIf
		EndIf
	EndIf

	Return FLOW_NONE
EndFunction

Actor Function GetCachedSpeaker()
	If ActiveSpeaker == None
		Return None
	EndIf
	Actor a = ActiveSpeaker.GetReference() as Actor
	If a != None && a.IsDead()
		ActiveSpeaker.Clear()
		Return None
	EndIf
	Return a
EndFunction

Actor Function ResolveSpeaker(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()

	If akSpeaker != None
		If akSpeaker != playerRef && !akSpeaker.IsDead()
			Return akSpeaker
		EndIf
	EndIf

	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	If preCtrl != None
		Actor preSpeaker = preCtrl.GetSpeaker()
		If preSpeaker != None && !preSpeaker.IsDead()
			Return preSpeaker
		EndIf
	EndIf

	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	If bleedCtrl != None
		Actor bleedSpeaker = bleedCtrl.GetSpeaker()
		If bleedSpeaker != None && !bleedSpeaker.IsDead()
			Return bleedSpeaker
		EndIf
	EndIf

	If IsCaptiveDialogueFlowLive()
		TFDCaptiveBridge captiveCtrl = GetCaptiveBridgeController()
		If captiveCtrl != None
			Actor captiveSpeaker = captiveCtrl.GetResolveCaptor()
			If captiveSpeaker != None && !captiveSpeaker.IsDead()
				Return captiveSpeaker
			EndIf
		EndIf
	EndIf

	Actor cachedSpeaker = GetCachedSpeaker()
	If cachedSpeaker != None && !cachedSpeaker.IsDead()
		Return cachedSpeaker
	EndIf

	Return None
EndFunction

Float Function GetGraceOutcomeDuration()
	Return 10.0
EndFunction

Function EmitReleaseGraceEventForFlow(Int aiFlow, Actor akSpeaker)
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	Float useDuration = GetGraceOutcomeDuration()

	If aiFlow == FLOW_INCOMBAT
		SendModEvent("TFDInCombatOutcomeRelease", ActorFormIDString(akSpeaker), useDuration)
	EndIf
EndFunction

Function EmitFollowGraceEventForFlow(Int aiFlow, Actor akSpeaker)
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	Float useDuration = GetGraceOutcomeDuration()

	If aiFlow == FLOW_INCOMBAT
		SendModEvent("TFDInCombatOutcomeFollow", ActorFormIDString(akSpeaker), useDuration)
	EndIf
EndFunction

Int Function ResolveSourceFlowForAfterPleasure()
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	If pleasureCtrl != None
		Return pleasureCtrl.GetSource()
	EndIf
	Return FLOW_NONE
EndFunction

Function ClearPreCombatFlow(Actor akSpeaker = None)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor targetSpeaker = akSpeaker

	If preCtrl != None
		If targetSpeaker == None
			targetSpeaker = preCtrl.GetSpeaker()
		EndIf

		If targetSpeaker != None
			preCtrl.ClearSpeakerForActor(targetSpeaker)
		Else
			preCtrl.ClearSpeaker()
		EndIf

		preCtrl.ClearBridge()
	Else
		SendModEvent("TFDPreCombatClearAll")
	EndIf
EndFunction

Function ClearBleedoutFlow(Actor akSpeaker = None)
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	Actor targetSpeaker = akSpeaker

	If bleedCtrl != None
		If targetSpeaker == None
			targetSpeaker = bleedCtrl.GetSpeaker()
		EndIf

		If targetSpeaker != None
			bleedCtrl.ClearSpeakerForActor(targetSpeaker)
		Else
			bleedCtrl.ClearSpeaker()
		EndIf
	EndIf

	SendModEvent("TFDBleedoutClearAll")
EndFunction

Function ClearTruceFlow()
	SendModEvent("TFDTruceClearAll")
EndFunction

Function ClearInCombatFlow()
	SendModEvent("TFDInCombatClearAll")
EndFunction

Function ClearCaptiveDialogueFlow(Bool abClearRuntimeRefs = False, Bool abApplyCooldown = False)
	TFDCaptiveBridge captiveCtrl = GetCaptiveBridgeController()
	If captiveCtrl == None
		Return
	EndIf

	captiveCtrl.CommitCaptiveChoice()

	If abClearRuntimeRefs
		captiveCtrl.ClearAll()
	ElseIf abApplyCooldown
		captiveCtrl.ReleaseOwnedCaptor()
	Else
		captiveCtrl.ReleaseOwnedCaptorNoCooldown()
	EndIf
EndFunction

Function ClearTransientDialogueBridges()
	ClearPreCombatFlow(None)
	ClearBleedoutFlow(None)
	ClearTruceFlow()
	ClearInCombatFlow()
EndFunction

Bool Function IsCaptiveDialogueFlowLive()
	If TFDCaptiveState == None
		Return False
	EndIf

	Int captiveState = TFDCaptiveState.GetValueInt()
	If captiveState != 1
		Return False
	EndIf

	If CaptiveWorkActive
		Return False
	EndIf

	If CurrentCaptivePhaseState == CAPTIVE_PHASE_ESCAPE || CurrentCaptivePhaseState == CAPTIVE_PHASE_RELEASED_WORK
		Return False
	EndIf

	Return True
EndFunction

Function SetCaptivePhaseValue(Int aiPhase)
	CurrentCaptivePhaseState = aiPhase
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return "0"
	EndIf
	Return akActor.GetFormID() as String
EndFunction

Bool Function IsAfterPleasureRouteLive()
	If CurrentRouteActive && CurrentRootFlow == FLOW_AFTERPLEASURE
		Return True
	EndIf

	If GetActiveFlow() == FLOW_AFTERPLEASURE
		Return True
	EndIf

	Return False
EndFunction

Function SendAfterPleasureChoiceEvent(String asEventName, Actor akSpeaker = None)
	If asEventName == ""
		Return
	EndIf

	If !IsAfterPleasureRouteLive()
		Return
	EndIf

	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	SendModEvent(asEventName, ActorFormIDString(chosenSpeaker), ResolveSourceFlowForAfterPleasure() as Float)
EndFunction

Function SendCaptiveWorkEvent(String asEventName, Actor akSpeaker)
	If asEventName == ""
		Return
	EndIf
	SendModEvent(asEventName, ActorFormIDString(akSpeaker), 0.0)
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
	TFDCaptiveBridge captiveBridgeCtrl = GetCaptiveBridgeController()

	ClearCaptiveWorkState()
	ClearPreCombatFlow(None)
	ClearBleedoutFlow(None)
	ClearTruceFlow()
	ClearInCombatFlow()

	If restoreCaptivePhase
		SetCaptivePhaseValue(CAPTIVE_PHASE_CAPTIVE)
		SendCaptiveWorkEvent("TFDCaptiveWorkStop", speakerRef)
	Else
		SetCaptivePhaseValue(CAPTIVE_PHASE_ESCAPE)
		SendCaptiveWorkEvent("TFDCaptiveWorkViolation", speakerRef)
	EndIf

	If captiveBridgeCtrl != None
		captiveBridgeCtrl.ClearCallCooldown()
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
	TFDCaptiveBridge captiveBridgeCtrl = GetCaptiveBridgeController()

	If playerRef == None
		Return False
	EndIf

	If !IsCaptiveDialogueFlowLive()
		Debug.Notification("TFD: Work is only valid during Captive flow.")
		Return False
	EndIf

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		If captiveBridgeCtrl != None
			chosenSpeaker = captiveBridgeCtrl.GetResolveCaptor()
		EndIf
	EndIf

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Debug.Notification("TFD: No valid captor for Work.")
		Return False
	EndIf

	If captiveBridgeCtrl != None
		(captiveBridgeCtrl as TFDCaptiveBridge).CommitCaptiveChoice()
		(captiveBridgeCtrl as TFDCaptiveBridge).ReleaseOwnedCaptorNoCooldown()
		(captiveBridgeCtrl as TFDCaptiveBridge).ClearCallCooldown()
	EndIf

	CaptiveWorkActive = True
	CaptiveWorkSpeaker = chosenSpeaker
	CaptiveWorkLocation = playerRef.GetCurrentLocation()
	SetActiveFlow(FLOW_CAPTIVE, chosenSpeaker)
	ClearPreCombatFlow(None)
	ClearBleedoutFlow(None)
	ClearTruceFlow()
	ClearInCombatFlow()
	SetCaptivePhaseValue(CAPTIVE_PHASE_RELEASED_WORK)
	SendCaptiveWorkEvent("TFDCaptiveWorkStart", chosenSpeaker)

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

; -------------------------------
; Main generic router
; -------------------------------
Bool Function ResolveDialogueOutcome(Int aiOutcome, Actor akSpeaker = None)
	Int flow = GetActiveFlow()
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	Int liveFlow = InferLiveFlow(chosenSpeaker)

	If flow == FLOW_AFTERPLEASURE
		; keep AfterPleasure authoritative once it is active
	ElseIf liveFlow == FLOW_BLEEDOUT && flow != FLOW_BLEEDOUT
		flow = FLOW_BLEEDOUT
		SetActiveFlow(flow, chosenSpeaker)
	ElseIf liveFlow == FLOW_CAPTIVE && flow != FLOW_CAPTIVE
		flow = FLOW_CAPTIVE
		SetActiveFlow(flow, chosenSpeaker)
	ElseIf flow == FLOW_NONE
		flow = liveFlow
		If flow != FLOW_NONE
			SetActiveFlow(flow, chosenSpeaker)
		EndIf
	EndIf

	If flow == FLOW_AFTERPLEASURE
		Return RouteAfterPleasureOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_PRECOMBAT
		Return RoutePreCombatOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_BLEEDOUT
		Return RouteBleedoutOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_CAPTIVE
		Return RouteCaptiveOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_VICTORY
		Return RouteVictoryOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_SAVIOR
		Return RouteSaviorOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_RECRUIT_CONTRACT
		Return RouteRecruitContractOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_CREATURE_BLEEDOUT
		Return RouteCreatureBleedoutOutcome(aiOutcome, chosenSpeaker)
	ElseIf flow == FLOW_CREATURE_TRUCE
		Return RouteCreatureTruceOutcome(aiOutcome, chosenSpeaker)
	EndIf

	Debug.Notification("TFD: No active dialogue flow.")
	Return False
EndFunction

; -------------------------------
; Public wrappers for dialogue fragments
; -------------------------------
Bool Function ResolveKidnap(Actor akSpeaker)
	If !HasActiveDialogueRoute()
		Int autoFlow = InferLiveFlow(akSpeaker)
		If autoFlow != FLOW_NONE
			BeginDialogueRoute(autoFlow, ENTRY_FORCEGREET, akSpeaker, "resolve_kidnap_autobegin")
			MarkDialogueNegotiating(akSpeaker, "resolve_kidnap_autobegin")
		EndIf
	EndIf
	RecordDialogueChoice(CHOICE_KIDNAP, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_kidnap")
	ResolveRecordedChoice(akSpeaker, "resolve_kidnap")
	Bool ok = ResolveDialogueOutcome(OUTCOME_KIDNAP, akSpeaker)
	If ok
		SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceKidnap", akSpeaker)
	EndIf
	Return ok
EndFunction

Bool Function ResolvePay(Actor akSpeaker)
	If !HasActiveDialogueRoute()
		Int autoFlow = InferLiveFlow(akSpeaker)
		If autoFlow != FLOW_NONE
			BeginDialogueRoute(autoFlow, ENTRY_FORCEGREET, akSpeaker, "resolve_pay_autobegin")
			MarkDialogueNegotiating(akSpeaker, "resolve_pay_autobegin")
		EndIf
	EndIf
	SetDialogueMethod(METHOD_PAY, akSpeaker, "resolve_pay")
	SetDialogueBranch(BRANCH_PAY, akSpeaker, "resolve_pay")
	Return ResolveDialogueOutcome(OUTCOME_PAY, akSpeaker)
EndFunction

Bool Function ResolveFight(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_FIGHT, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_fight")
	ResolveRecordedChoice(akSpeaker, "resolve_fight")
	Return ResolveDialogueOutcome(OUTCOME_FIGHT, akSpeaker)
EndFunction

Bool Function ResolveRecruit(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_RECRUIT, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_recruit")
	ResolveRecordedChoice(akSpeaker, "resolve_recruit")
	Return ResolveDialogueOutcome(OUTCOME_RECRUIT, akSpeaker)
EndFunction

Bool Function ResolveJoinEnemy(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_JOIN_ENEMY, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_join_enemy")
	ResolveRecordedChoice(akSpeaker, "resolve_join_enemy")
	Return ResolveDialogueOutcome(OUTCOME_JOIN_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveRelease(Actor akSpeaker)
	Int requestedFlow = GetActiveFlow()
	If requestedFlow == FLOW_NONE
		requestedFlow = InferLiveFlow(akSpeaker)
	EndIf

	If !HasActiveDialogueRoute()
		Int autoFlow = requestedFlow
		If autoFlow != FLOW_NONE
			BeginDialogueRoute(autoFlow, ENTRY_FORCEGREET, akSpeaker, "resolve_release_autobegin")
			MarkDialogueNegotiating(akSpeaker, "resolve_release_autobegin")
		EndIf
	EndIf
	RecordDialogueChoice(CHOICE_RELEASE_ME, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_release")
	ResolveRecordedChoice(akSpeaker, "resolve_release")
	Bool ok = ResolveDialogueOutcome(OUTCOME_RELEASE, akSpeaker)
	If ok
		Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
		EmitReleaseGraceEventForFlow(requestedFlow, chosenSpeaker)
		SendAfterPleasureChoiceEvent("TFDAfterPleasureChoiceRelease", chosenSpeaker)
	EndIf
	Return ok
EndFunction

Bool Function ResolveFollowPlayer(Actor akSpeaker)
	Int requestedFlow = GetActiveFlow()
	If requestedFlow == FLOW_NONE
		requestedFlow = InferLiveFlow(akSpeaker)
	EndIf

	RecordDialogueChoice(CHOICE_FOLLOW_ME, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_follow_player")
	ResolveRecordedChoice(akSpeaker, "resolve_follow_player")
	Bool ok = ResolveDialogueOutcome(OUTCOME_FOLLOW_PLAYER, akSpeaker)
	If ok
		Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
		EmitFollowGraceEventForFlow(requestedFlow, chosenSpeaker)
	EndIf
	Return ok
EndFunction

Bool Function ResolveDoNothing(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_DO_NOTHING, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_do_nothing")
	ResolveRecordedChoice(akSpeaker, "resolve_do_nothing")
	Return ResolveDialogueOutcome(OUTCOME_DO_NOTHING, akSpeaker)
EndFunction

Bool Function ResolveWork(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_WORK, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_work")
	ResolveRecordedChoice(akSpeaker, "resolve_work")
	Return ResolveDialogueOutcome(OUTCOME_WORK, akSpeaker)
EndFunction

Bool Function ResolveLootEnemy(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_LOOT_ENEMY, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_loot_enemy")
	ResolveRecordedChoice(akSpeaker, "resolve_loot_enemy")
	Return ResolveDialogueOutcome(OUTCOME_LOOT_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveKillEnemy(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_KILL_ENEMY, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_kill_enemy")
	ResolveRecordedChoice(akSpeaker, "resolve_kill_enemy")
	Return ResolveDialogueOutcome(OUTCOME_KILL_ENEMY, akSpeaker)
EndFunction

Bool Function ResolveThanks(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_THANKS, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_thanks")
	ResolveRecordedChoice(akSpeaker, "resolve_thanks")
	Return ResolveDialogueOutcome(OUTCOME_THANKS, akSpeaker)
EndFunction

Bool Function ResolveExtendContract(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_EXTEND_CONTRACT, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_extend_contract")
	ResolveRecordedChoice(akSpeaker, "resolve_extend_contract")
	Return ResolveDialogueOutcome(OUTCOME_EXTEND_CONTRACT, akSpeaker)
EndFunction

Bool Function ResolveTerminateContract(Actor akSpeaker)
	RecordDialogueChoice(CHOICE_TERMINATE_CONTRACT, CHOICE_SOURCE_EXPLICIT_DIALOG, akSpeaker, "resolve_terminate_contract")
	ResolveRecordedChoice(akSpeaker, "resolve_terminate_contract")
	Return ResolveDialogueOutcome(OUTCOME_TERMINATE_CONTRACT, akSpeaker)
EndFunction

Bool Function ChoosePayMethod(Actor akSpeaker)
	Return SetDialogueMethod(METHOD_PAY, akSpeaker, "choose_pay_method")
EndFunction

Bool Function RecordImplicitBleedoutCloseNoCommit(Actor akSpeaker = None)
	If !CurrentRouteActive
		BeginDialogueRoute(FLOW_BLEEDOUT, ENTRY_FORCEGREET, akSpeaker, "implicit_bleed_close_no_commit")
	EndIf
	If CurrentRootFlow != FLOW_BLEEDOUT
		Return False
	EndIf
	RecordDialogueChoice(CHOICE_DO_NOTHING, CHOICE_SOURCE_DIALOG_CLOSED_NO_COMMIT, akSpeaker, "implicit_bleed_close_no_commit")
	Return ResolveRecordedChoice(akSpeaker, "implicit_bleed_close_no_commit")
EndFunction


Int Function GetSharedPayAmount()
	If TFDPayGold == None
		Return 0
	EndIf

	Int payAmount = TFDPayGold.GetValueInt()
	If payAmount < 0
		payAmount = 0
	EndIf
	Return payAmount
EndFunction

Actor Function ResolvePreCombatSpeaker(Actor akSpeaker)
	Actor chosenSpeaker = ResolveSpeaker(akSpeaker)
	If chosenSpeaker != None && !chosenSpeaker.IsDead()
		Return chosenSpeaker
	EndIf
	Return None
EndFunction

Function PreparePreCombatSpeaker(TFDPreCombatQuestScript preCtrl, Actor akSpeaker)
	If preCtrl == None
		Return
	EndIf
	If akSpeaker != None && !akSpeaker.IsDead()
		preCtrl.SetSpeaker(akSpeaker)
	EndIf
EndFunction

Function CleanupPreCombatTemporaryState(TFDPreCombatQuestScript preCtrl)
	If preCtrl == None
		Return
	EndIf
	preCtrl.EndSafePass(False)
	preCtrl.EndTemporaryFollow(False)
	preCtrl.EndJoinEnemy(False)
	preCtrl.ReleasePleasureLock(True)
EndFunction

Bool Function ExecutePreCombatKidnap(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	CleanupPreCombatTemporaryState(preCtrl)

	If preCtrl != None
		preCtrl.ClearBridge()
	Else
		ClearTransientDialogueBridges()
	EndIf

	SendModEvent("TFDPreCombatOutcomeCaptive", ActorFormIDString(chosenSpeaker))
	chosenSpeaker.StopCombat()
	chosenSpeaker.StopCombatAlarm()
	chosenSpeaker.EvaluatePackage()
	SendModEvent("TFDPreCombatKidnap", ActorFormIDString(chosenSpeaker))
	Return True
EndFunction

Bool Function ExecutePreCombatPay(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	If playerRef == None || Gold001 == None
		Return False
	EndIf
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	Int payAmount = GetSharedPayAmount()
	If payAmount <= 0
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	CleanupPreCombatTemporaryState(preCtrl)
	If preCtrl != None
		preCtrl.ClearBridge()
	Else
		ClearTransientDialogueBridges()
	EndIf

	playerRef.RemoveItem(Gold001, payAmount, True, chosenSpeaker)
	SendModEvent("TFDPreCombatOutcomePay")
	Return True
EndFunction

Bool Function ExecutePreCombatFight(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	CleanupPreCombatTemporaryState(preCtrl)
	If preCtrl != None
		preCtrl.ClearBridge()
	Else
		ClearTransientDialogueBridges()
	EndIf

	SendModEvent("TFDPreCombatOutcomeFight")

	If chosenSpeaker != None && playerRef != None && !chosenSpeaker.IsDead()
		chosenSpeaker.StopCombatAlarm()
		chosenSpeaker.StartCombat(playerRef)
		chosenSpeaker.EvaluatePackage()
	EndIf
	Return True
EndFunction

Bool Function ExecutePreCombatRecruit(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor playerRef = Game.GetPlayer()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	If preCtrl != None
		preCtrl.ClearBridge()
	Else
		ClearTransientDialogueBridges()
	EndIf

	SendModEvent("TFDPreCombatOutcomeRecruit", ActorFormIDString(chosenSpeaker))

	If preCtrl != None
		Utility.WaitMenuMode(0.20)
		Return preCtrl.PromoteActorAsRecruitLikeOutcome(chosenSpeaker, True)
	EndIf

	If playerRef == None
		Return False
	EndIf

	chosenSpeaker.SetRelationshipRank(playerRef, 4)
	chosenSpeaker.SetPlayerTeammate(True, False)
	chosenSpeaker.StopCombat()
	chosenSpeaker.StopCombatAlarm()
	chosenSpeaker.EvaluatePackage()
	Return True
EndFunction

Bool Function ExecutePreCombatJoinEnemy(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	If preCtrl == None
		Return False
	EndIf
	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf
	If !preCtrl.IsJoinEnemyOfferedByNative()
		Debug.Notification("TFD: Join Enemy is not available here.")
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	SendModEvent("TFDPreCombatOutcomeJoinEnemy")
	preCtrl.ClearBridge()
	Return preCtrl.BeginJoinEnemyExternal(chosenSpeaker)
EndFunction

Bool Function ExecutePreCombatRelease(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	Float useDuration = 10.0

	If preCtrl != None
		If preCtrl.ReleaseDuration > 0.0
			useDuration = preCtrl.ReleaseDuration
		ElseIf preCtrl.SafePassDuration > 0.0
			useDuration = preCtrl.SafePassDuration
		EndIf
	EndIf

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	If preCtrl != None
		preCtrl.StartSafePassForActorWithDuration(chosenSpeaker, 5, useDuration)
	Else
		ClearTransientDialogueBridges()
	EndIf
	SendModEvent("TFDPreCombatOutcomeRelease", ActorFormIDString(chosenSpeaker), useDuration)
	Return True
EndFunction

Bool Function ExecutePreCombatFollow(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	Float useDuration = 60.0

	If preCtrl != None && preCtrl.FollowDuration > 0.0
		useDuration = preCtrl.FollowDuration
	EndIf

	If chosenSpeaker == None || chosenSpeaker.IsDead()
		Return False
	EndIf

	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	SendModEvent("TFDPreCombatOutcomeFollow", ActorFormIDString(chosenSpeaker), useDuration)

	If preCtrl != None
		Return preCtrl.BeginTemporaryFollowExternal(chosenSpeaker, useDuration)
	EndIf

	Return False
EndFunction

Bool Function ExecutePreCombatDoNothing(Actor akSpeaker)
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()
	Actor chosenSpeaker = ResolvePreCombatSpeaker(akSpeaker)
	PreparePreCombatSpeaker(preCtrl, chosenSpeaker)
	If preCtrl != None
		preCtrl.StartSafePassForActor(chosenSpeaker, 4)
		Return True
	EndIf
	Return False
EndFunction

; -------------------------------
; Route: PreCombat
; -------------------------------
Bool Function RoutePreCombatOutcome(Int aiOutcome, Actor akSpeaker)
	If aiOutcome == OUTCOME_KIDNAP
		Return ExecutePreCombatKidnap(akSpeaker)
	ElseIf aiOutcome == OUTCOME_PAY
		Return ExecutePreCombatPay(akSpeaker)
	ElseIf aiOutcome == OUTCOME_FIGHT
		Return ExecutePreCombatFight(akSpeaker)
	ElseIf aiOutcome == OUTCOME_RECRUIT
		Return ExecutePreCombatRecruit(akSpeaker)
	ElseIf aiOutcome == OUTCOME_JOIN_ENEMY
		Return ExecutePreCombatJoinEnemy(akSpeaker)
	ElseIf aiOutcome == OUTCOME_RELEASE
		Return ExecutePreCombatRelease(akSpeaker)
	ElseIf aiOutcome == OUTCOME_FOLLOW_PLAYER
		Return ExecutePreCombatFollow(akSpeaker)
	ElseIf aiOutcome == OUTCOME_DO_NOTHING
		Return ExecutePreCombatDoNothing(akSpeaker)
	EndIf

	Debug.Notification("TFD: Invalid PreCombat outcome.")
	Return False
EndFunction

; -------------------------------
; Route: Bleedout
; -------------------------------
Bool Function RouteBleedoutOutcome(Int aiOutcome, Actor akSpeaker)
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	If bleedCtrl == None
		Return False
	EndIf

	If aiOutcome == OUTCOME_KIDNAP
		Return bleedCtrl.ResolveKidnap()
	ElseIf aiOutcome == OUTCOME_PAY
		Return bleedCtrl.ResolvePay()
	ElseIf aiOutcome == OUTCOME_RELEASE
		Return bleedCtrl.ResolveRelease()
	ElseIf aiOutcome == OUTCOME_DO_NOTHING
		Return bleedCtrl.ResolveDoNothing()
	EndIf

	Debug.Notification("TFD: Invalid Bleedout outcome.")
	Return False
EndFunction

; -------------------------------
; Route: AfterPleasure
; -------------------------------
Bool Function RouteAfterPleasureOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Trace("TFDSystemEventQuestScript: RouteAfterPleasureOutcome not wired yet for SystemEvent.")
	Return False
EndFunction

Event OnUpdate()
	If PendingHygienePostLoadRetries > 0
		PendingHygienePostLoadRetries -= 1
		RunTransientHygiene(False)
		RegisterForSingleUpdate(HygienePostLoadRetryInterval)
		Return
	EndIf

	If CaptiveWorkActive
		UpdateCaptiveWorkMode()
		Return
	EndIf

	RunTransientHygiene(False)
EndEvent

; -------------------------------
; Future routes - placeholder
; -------------------------------
Bool Function RouteCaptiveOutcome(Int aiOutcome, Actor akSpeaker)
	TFDCaptiveBridge captiveBridgeCtrl = GetCaptiveBridgeController()
	TFDBleedoutQuestScript bleedCtrl = GetBleedoutController()
	Actor bleedSpeaker = None

	If bleedCtrl != None
		bleedSpeaker = bleedCtrl.GetSpeaker()
	EndIf

	If bleedSpeaker != None && !bleedSpeaker.IsDead()
		If aiOutcome == OUTCOME_KIDNAP || aiOutcome == OUTCOME_PAY || aiOutcome == OUTCOME_DO_NOTHING
			Return RouteBleedoutOutcome(aiOutcome, bleedSpeaker)
		EndIf
	EndIf

	If aiOutcome == OUTCOME_WORK
		Return BeginCaptiveWorkMode(akSpeaker)
	ElseIf aiOutcome == OUTCOME_DO_NOTHING
		If CaptiveWorkActive
			StopCaptiveWorkMode(True, False, "captor_do_nothing")
			Return True
		EndIf
		If captiveBridgeCtrl != None
			captiveBridgeCtrl.CommitCaptiveChoice()
			captiveBridgeCtrl.ReleaseOwnedCaptor()
			Return True
		EndIf
		Return False
	EndIf

	Debug.Notification("TFD: Captive outcome router not wired yet.")
	Return False
EndFunction

Bool Function RouteVictoryOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Notification("TFD: Victory outcome router not wired yet.")
	Return False
EndFunction

Bool Function RouteSaviorOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Notification("TFD: Savior outcome router not wired yet.")
	Return False
EndFunction

Bool Function RouteRecruitContractOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Notification("TFD: Recruit contract router not wired yet.")
	Return False
EndFunction

Bool Function RouteCreatureBleedoutOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Notification("TFD: Creature bleedout router not wired yet.")
	Return False
EndFunction

Bool Function RouteCreatureTruceOutcome(Int aiOutcome, Actor akSpeaker)
	Debug.Notification("TFD: Creature truce router not wired yet.")
	Return False
EndFunction