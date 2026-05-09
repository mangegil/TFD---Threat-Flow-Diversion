Scriptname TFDInCombatQuestScript extends Quest

ReferenceAlias Property Speaker Auto

GlobalVariable Property TFDPayGold Auto
GlobalVariable Property TFDJoinEnemyState Auto

Quest Property TFDSystemEventQuest Auto
Quest Property TFDPleasureQuest Auto
TFDTemporaryFollowerQuestScript Property TemporaryFollowerQuest Auto
TFDPlayerTeammateQuestScript Property Registry Auto

MiscObject Property Gold001 Auto

Float Property UpdateInterval = 0.50 Auto
Float Property FollowDuration = 60.0 Auto
Float Property GraceOutcomeDuration = 10.0 Auto
Float Property ReleaseSafePassDuration = 10.0 Auto

Bool ReleaseSafePassActive = False
Actor ReleaseSafePassActor = None
Float ReleaseSafePassExpireAt = 0.0

Int Property RESULT_FIGHT = 1 Auto Hidden
Int Property RESULT_KIDNAP = 2 Auto Hidden
Int Property RESULT_PLEASURE = 3 Auto Hidden
Int Property RESULT_DONOTHING = 4 Auto Hidden
Int Property RESULT_RELEASE = 5 Auto Hidden
Int Property RESULT_PAY = 6 Auto Hidden
Int Property RESULT_RECRUIT = 7 Auto Hidden
Int Property RESULT_FOLLOW = 8 Auto Hidden
Int Property RESULT_JOINENEMY = 9 Auto Hidden

Int PleasureSourceInCombat = 6

Int Property SESSION_STAGE_NONE = 0 Auto Hidden
Int Property SESSION_STAGE_GREETING = 1 Auto Hidden
Int Property SESSION_STAGE_PAY_SELECTED = 2 Auto Hidden
Int Property SESSION_STAGE_OUTCOME_COMMITTED = 3 Auto Hidden

Int Property SESSION_METHOD_NONE = 0 Auto Hidden
Int Property SESSION_METHOD_PAY = 2 Auto Hidden
Int Property SESSION_BRANCH_NONE = 0 Auto Hidden
Int Property SESSION_BRANCH_PAY = 2 Auto Hidden

Actor ManagedSpeaker = None
Bool SessionActive = False
Int SessionToken = 0
Actor SessionSpeaker = None
Int SessionStage = 0
Int SessionMethod = 0
Int SessionBranch = 0
Bool SessionOutcomeCommitted = False
Bool SessionDialogueOpened = False
Float SessionDialogueOpenedAt = 0.0
Float SessionStartedAt = 0.0
String SessionReason = ""
Int LastResolvedResult = 0
Bool PleasureLockActive = False
Actor PleasureLockActor = None

Int ApproachActivationToken = -1
Int ApproachActivationPasses = 0
Float ApproachActivationStartedAt = 0.0
Float ApproachNextEvaluateAt = 0.0

Bool JoinEnemyActive = False
Location JoinEnemyLocation
Actor JoinEnemySourceActor = None

Event OnInit()
	RegisterNativeEvents()
	ClearSpeaker()
	QueueUpdate()
EndEvent

Event OnPlayerLoadGame()
	AbortSession("load_game", None, False, True)
	EndReleaseSafePass(False, "load_game")
	PleasureLockActive = False
	PleasureLockActor = None
	EndJoinEnemy(False)
	RegisterNativeEvents()
	QueueUpdate()
EndEvent

Function RegisterNativeEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDInCombatAssign", "OnNativeEvent")
	RegisterForModEvent("TFDInCombatClear", "OnNativeEvent")
	RegisterForModEvent("TFDInCombatClearAll", "OnNativeEvent")
	RegisterForModEvent("TFDInCombatResumeCombat", "OnNativeEvent")
	RegisterForModEvent("TFDInCombatEmergencyCancel", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceRelease", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceRecruit", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceFinish", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceJoinEnemy", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceKidnap", "OnNativeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceWork", "OnNativeEvent")
	RegisterForModEvent("TFDPreCombatPleasureFailed", "OnNativeEvent")
	RegisterForModEvent("TFDPleasureAborted", "OnNativeEvent")
EndFunction

Event OnNativeEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor aEvent = sender as Actor

	If eventName == "TFDInCombatEmergencyCancel"
		HandleEmergencyCancelFromNative(aEvent, strArg)
		Return
	EndIf

	If eventName == "TFDInCombatResumeCombat"
		RestoreCombatForActor(aEvent, eventName)
		Return
	EndIf

	If IsAfterPleasureTerminalEvent(eventName)
		HandleAfterPleasureTerminalEvent(eventName, strArg, numArg, sender)
		Return
	EndIf

	If eventName == "TFDPreCombatPleasureFailed" || eventName == "TFDPleasureAborted"
		HandlePleasureHandoffEnded(eventName, strArg, numArg, sender)
		Return
	EndIf

	If eventName == "TFDInCombatAssign"
		If aEvent != None && !aEvent.IsDead()
			BeginSessionForActor(aEvent, "bridge_assign")
			QueueUpdate()
		EndIf
		Return
	EndIf

	If eventName == "TFDInCombatClear"
		If ShouldIgnoreBridgeClear(aEvent)
			TraceSession("IgnoreBridgeClear", aEvent, "bridge_clear_guarded")
			If SessionSpeaker != None
				SetSpeaker(SessionSpeaker)
			EndIf
			If SessionActive || GetSpeaker() != None
				QueueUpdate()
			EndIf
			Return
		EndIf
		AbortSession("bridge_clear", aEvent, False, True)
		Return
	EndIf

	If eventName == "TFDInCombatClearAll"
		If ShouldIgnoreBridgeClearAll(sender)
			TraceSession("IgnoreBridgeClearAll", SessionSpeaker, "bridge_clear_all_guarded")
			If SessionSpeaker != None
				SetSpeaker(SessionSpeaker)
			EndIf
			If SessionActive || GetSpeaker() != None
				QueueUpdate()
			EndIf
			Return
		EndIf
		AbortSession("bridge_clear_all", aEvent, False, True)
		Return
	EndIf
EndEvent

Bool Function IsAfterPleasureTerminalEvent(String eventName)
	If eventName == "TFDAfterPleasureChoiceRelease"
		Return True
	EndIf
	If eventName == "TFDAfterPleasureChoiceRecruit"
		Return True
	EndIf
	If eventName == "TFDAfterPleasureChoiceFinish"
		Return True
	EndIf
	If eventName == "TFDAfterPleasureChoiceJoinEnemy"
		Return True
	EndIf
	If eventName == "TFDAfterPleasureChoiceKidnap"
		Return True
	EndIf
	If eventName == "TFDAfterPleasureChoiceWork"
		Return True
	EndIf
	Return False
EndFunction

Bool Function IsInCombatPleasureSessionActive()
	If !SessionActive
		Return False
	EndIf
	If !SessionOutcomeCommitted
		Return False
	EndIf
	If SessionStage != SESSION_STAGE_OUTCOME_COMMITTED
		Return False
	EndIf
	If SessionReason != "resolve_pleasure"
		Return False
	EndIf
	Return True
EndFunction

Bool Function IsPleasureHandoffPreserveActive()
	If !IsInCombatPleasureSessionActive()
		Return False
	EndIf
	If !PleasureLockActive
		Return False
	EndIf
	Return True
EndFunction

Bool Function ShouldIgnoreBridgeClear(Actor akActor)
	If !IsPleasureHandoffPreserveActive()
		Return False
	EndIf
	If akActor == None
		Return True
	EndIf
	If PleasureLockActor != None && akActor == PleasureLockActor
		Return True
	EndIf
	If SessionSpeaker != None && akActor == SessionSpeaker
		Return True
	EndIf
	Return False
EndFunction

Bool Function ShouldIgnoreBridgeClearAll(Form sender)
	Return IsPleasureHandoffPreserveActive()
EndFunction

Function CompletePleasureHandoffSession(String asReason = "")
	Actor previousSpeaker = SessionSpeaker
	ReleasePleasureLock(False)
	If SessionActive
		ClearSession(True, False, asReason)
	ElseIf previousSpeaker != None
		ClearSpeakerForActor(previousSpeaker)
	EndIf
	ClearTransientDialogueBridges()
	Debug.Trace("[TFD][InCombatSession][R94B] CompletePleasureHandoffSession reason=" + asReason + " actor=" + DescribeActor(previousSpeaker))
EndFunction

Function HandleAfterPleasureTerminalEvent(String eventName, String strArg, Float numArg, Form sender)
	If !IsInCombatPleasureSessionActive()
		Return
	EndIf

	If numArg != 6.0
		Debug.Trace("[TFD][InCombatSession][R93T] IgnoreAfterPleasureTerminal event=" + eventName + " source=" + numArg + " reason=not_incombat_source")
		Return
	EndIf

	TraceSession("AfterPleasureTerminalClear", SessionSpeaker, eventName)
	CompletePleasureHandoffSession("after_pleasure_terminal_" + eventName)
EndFunction

Function HandlePleasureHandoffEnded(String eventName, String strArg, Float numArg, Form sender)
	If !IsInCombatPleasureSessionActive()
		Return
	EndIf

	TraceSession("PleasureHandoffEnded", SessionSpeaker, eventName)
	CompletePleasureHandoffSession("pleasure_handoff_end_" + eventName)
EndFunction

Function RestoreCombatForActor(Actor akActor, String asReason = "")
	Actor playerRef = Game.GetPlayer()
	If akActor == None || akActor.IsDead() || playerRef == None
		Return
	EndIf

	; R93Y: detection wake. InCombat truce stopped combat/alarm for the pack,
	; so one StartCombat call can be lost when the actor has no current target
	; or the player is not fully detected yet. Start both directions and pulse
	; package evaluation twice, without touching persistent factions.
	akActor.StopCombatAlarm()
	akActor.StartCombat(playerRef)
	playerRef.StartCombat(akActor)
	akActor.EvaluatePackage()
	playerRef.EvaluatePackage()
	Utility.Wait(0.10)
	akActor.StartCombat(playerRef)
	akActor.EvaluatePackage()
	Debug.Trace("[TFD][InCombatSession][R93Y] RestoreCombat actor=" + DescribeActor(akActor) + " reason=" + asReason)
EndFunction

Function HandleEmergencyCancelFromNative(Actor akActor, String asReason = "")
	Actor previousSpeaker = SessionSpeaker
	Actor useActor = akActor
	If useActor == None
		useActor = previousSpeaker
	EndIf

	TraceSession("EmergencyCancel", useActor, asReason)
	ReleasePleasureLock(True)
	EndReleaseSafePass(True, "emergency_cancel")
	EndJoinEnemy(False)
	ClearSession(True, True, "emergency_cancel")
	ClearTransientDialogueBridges()
	Debug.Trace("[TFD][InCombatSession][R97A] EmergencyCancel actor=" + DescribeActor(useActor) + " reason=" + asReason)
EndFunction

Function QueueUpdate()
	UnregisterForUpdate()
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Event OnUpdate()
	PruneStaleSpeaker()
	MaintainSpeakerApproachActivation()
	HandleUncommittedDialogueClose()
	UpdateReleaseSafePass()
	UpdateJoinEnemy()
	If SessionActive || GetSpeaker() != None || JoinEnemyActive || ReleaseSafePassActive
		RegisterForSingleUpdate(UpdateInterval)
	EndIf
EndEvent

Actor Function GetAliasActor(ReferenceAlias akAlias)
	If akAlias == None
		Return None
	EndIf
	Return akAlias.GetActorReference()
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

Bool Function SetSpeaker(Actor akActor)
	If Speaker == None
		Return False
	EndIf

	If akActor == None
		Speaker.Clear()
		ManagedSpeaker = None
		Return True
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	Speaker.ForceRefTo(akActor)
	ManagedSpeaker = akActor
	Return (Speaker.GetReference() == akActor)
EndFunction

Bool Function BindSpeakerForNewSession(Actor akActor, String asReason = "")
	If Speaker == None
		Debug.Trace("[TFD][InCombatSession][R93Q] BindSpeaker failed reason=no_alias actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return False
	EndIf

	If akActor == None || akActor.IsDead()
		Debug.Trace("[TFD][InCombatSession][R93Q] BindSpeaker failed reason=invalid_actor actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return False
	EndIf

	Actor currentActor = GetAliasActor(Speaker)
	If currentActor != None
		Speaker.Clear()
		ManagedSpeaker = None
		Utility.Wait(0.05)
	EndIf

	Speaker.ForceRefTo(akActor)
	ManagedSpeaker = akActor
	Utility.Wait(0.05)

	Bool bound = (Speaker.GetReference() == akActor)
	Debug.Trace("[TFD][InCombatSession][R93Q] BindSpeaker bound=" + bound + " previous=" + DescribeActor(currentActor) + " actor=" + DescribeActor(akActor) + " reason=" + asReason)
	Return bound
EndFunction

Function PrimeSpeakerApproachActivation(Actor akActor, String asReason = "")
	ArmSpeakerApproachActivation(asReason)
	EvaluateSpeakerApproachPackage(akActor, "prime_0:" + asReason, True)
	Utility.Wait(0.10)
	EvaluateSpeakerApproachPackage(akActor, "prime_1:" + asReason, False)
EndFunction

Function ArmSpeakerApproachActivation(String asReason = "")
	ApproachActivationToken = SessionToken
	ApproachActivationPasses = 0
	ApproachActivationStartedAt = Utility.GetCurrentRealTime()
	ApproachNextEvaluateAt = 0.0
	Debug.Trace("[TFD][InCombatSession][R93Q] ArmApproach token=" + ApproachActivationToken + " actor=" + DescribeActor(SessionSpeaker) + " reason=" + asReason)
EndFunction

Function DisarmSpeakerApproachActivation()
	ApproachActivationToken = -1
	ApproachActivationPasses = 0
	ApproachActivationStartedAt = 0.0
	ApproachNextEvaluateAt = 0.0
EndFunction

Function NoteDialogueOpened(Actor akActor, String asReason = "")
	If !SessionActive
		Return
	EndIf
	If akActor == None || SessionSpeaker == None || akActor != SessionSpeaker
		TraceSession("IgnoreDialogueOpened", akActor, "speaker_mismatch:" + asReason)
		Return
	EndIf
	If SessionStage != SESSION_STAGE_GREETING
		TraceSession("IgnoreDialogueOpened", akActor, "stage_not_greeting:" + asReason)
		Return
	EndIf
	SessionDialogueOpened = True
	SessionDialogueOpenedAt = Utility.GetCurrentRealTime()
	Debug.Trace("[TFD][InCombatSession][R94F] NoteDialogueOpened actor=" + DescribeActor(akActor) + " reason=" + asReason)
	QueueUpdate()
EndFunction

Function HandleUncommittedDialogueClose()
	If !SessionActive
		Return
	EndIf
	If SessionOutcomeCommitted
		Return
	EndIf
	If SessionStage != SESSION_STAGE_GREETING
		Return
	EndIf
	If !SessionDialogueOpened
		Return
	EndIf
	If Utility.GetCurrentRealTime() - SessionDialogueOpenedAt < 1.00
		Return
	EndIf
	If UI.IsMenuOpen("Dialogue Menu")
		Return
	EndIf

	Actor closeSpeaker = SessionSpeaker
	TraceSession("DialogueClosedNoCommit", closeSpeaker, "restore_combat")
	If closeSpeaker != None && !closeSpeaker.IsDead()
		SendModEvent("TFDInCombatOutcomeCancel", ActorFormIDString(closeSpeaker))
		RestoreCombatForActor(closeSpeaker, "dialogue_closed_no_commit")
	EndIf
	AbortSession("dialogue_closed_no_commit", closeSpeaker, True, True)
EndFunction

Function MaintainSpeakerApproachActivation()
	If !SessionActive
		Return
	EndIf

	If SessionStage != SESSION_STAGE_GREETING
		Return
	EndIf

	If SessionOutcomeCommitted
		Return
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		Return
	EndIf

	If ApproachActivationToken != SessionToken
		Return
	EndIf

	If ApproachActivationPasses >= 240
		Return
	EndIf

	Float nowTime = Utility.GetCurrentRealTime()
	If ApproachNextEvaluateAt > 0.0 && nowTime < ApproachNextEvaluateAt
		Return
	EndIf

	If Speaker == None || Speaker.GetReference() != SessionSpeaker
		Debug.Trace("[TFD][InCombatSession][R93Q] MaintainApproach skipped reason=alias_mismatch token=" + SessionToken + " actor=" + DescribeActor(SessionSpeaker))
		Return
	EndIf

	ApproachActivationPasses += 1
	EvaluateSpeakerApproachPackage(SessionSpeaker, "maintain_" + ApproachActivationPasses, False)
	ApproachNextEvaluateAt = nowTime + 0.35
EndFunction

Function EvaluateSpeakerApproachPackage(Actor akActor, String asReason = "", Bool abStopCombat = False)
	If akActor == None || akActor.IsDead()
		Return
	EndIf

	If Speaker != None && Speaker.GetReference() != akActor
		Debug.Trace("[TFD][InCombatSession][R93Q] EvaluateApproach skipped reason=alias_mismatch actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return
	EndIf

	If abStopCombat
		akActor.StopCombat()
		akActor.StopCombatAlarm()
	EndIf

	akActor.EvaluatePackage()
	Debug.Trace("[TFD][InCombatSession][R93Q] EvaluateApproach pass=" + ApproachActivationPasses + " token=" + SessionToken + " actor=" + DescribeActor(akActor) + " reason=" + asReason + " stopCombat=" + abStopCombat)
EndFunction

Function ClearSpeaker()
	ManagedSpeaker = None
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
	If ManagedSpeaker == akActor
		ManagedSpeaker = None
	EndIf
	If Speaker != None
		If Speaker.GetReference() == akActor
			Speaker.Clear()
		EndIf
	EndIf
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return "0"
	EndIf
	Return akActor.GetFormID() as String
EndFunction

String Function DescribeActor(Actor akActor)
	If akActor == None
		Return "None"
	EndIf
	Return akActor + "(" + ActorFormIDString(akActor) + ")"
EndFunction

Bool Function IsPleasureLockActor(Actor akActor)
	If !PleasureLockActive
		Return False
	EndIf
	If akActor == None
		Return False
	EndIf
	Return (PleasureLockActor == akActor)
EndFunction

Function BeginPleasureLock(Actor akActor)
	If akActor == None
		Return
	EndIf

	PleasureLockActive = True
	PleasureLockActor = akActor
	Debug.Trace("[TFD][InCombatSession][R93T] BeginPleasureLock actor=" + DescribeActor(akActor) + " native_owned=true")

	If akActor.Is3DLoaded()
		akActor.StopCombat()
		akActor.StopCombatAlarm()
		akActor.EvaluatePackage()
	EndIf
EndFunction

Function ReleasePleasureLock(Bool abClearBridge = True)
	PleasureLockActive = False
	PleasureLockActor = None
EndFunction

Function TraceSession(String asEvent, Actor akActor = None, String asReason = "")
	String reasonText = asReason
	If reasonText == ""
		reasonText = SessionReason
	EndIf
	Debug.Trace("[TFD][InCombatSession] " + asEvent + " token=" + SessionToken + " active=" + SessionActive + " stage=" + SessionStage + " method=" + SessionMethod + " branch=" + SessionBranch + " committed=" + SessionOutcomeCommitted + " actor=" + DescribeActor(akActor) + " sessionSpeaker=" + DescribeActor(SessionSpeaker) + " reason=" + reasonText)
EndFunction

Function ResetSessionStateOnly()
	SessionActive = False
	SessionSpeaker = None
	SessionStage = SESSION_STAGE_NONE
	SessionMethod = SESSION_METHOD_NONE
	SessionBranch = SESSION_BRANCH_NONE
	SessionOutcomeCommitted = False
	SessionDialogueOpened = False
	SessionDialogueOpenedAt = 0.0
	SessionStartedAt = 0.0
	SessionReason = ""
	DisarmSpeakerApproachActivation()
EndFunction

Function SetResolvedState(Int aiResult)
	LastResolvedResult = aiResult
EndFunction

Function BeginSessionForActor(Actor akActor, String asReason = "")
	If akActor == None || akActor.IsDead()
		Return
	EndIf

	SessionToken += 1
	SessionActive = True
	SessionSpeaker = akActor
	SessionStage = SESSION_STAGE_GREETING
	SessionMethod = SESSION_METHOD_NONE
	SessionBranch = SESSION_BRANCH_NONE
	SessionOutcomeCommitted = False
	SessionDialogueOpened = False
	SessionDialogueOpenedAt = 0.0
	SessionStartedAt = Utility.GetCurrentRealTime()
	SessionReason = asReason
	Bool speakerBound = BindSpeakerForNewSession(akActor, asReason)
	SyncSystemInCombatRoot(akActor, asReason)
	If speakerBound
		PrimeSpeakerApproachActivation(akActor, asReason)
	EndIf
	TraceSession("Begin", akActor, asReason)
	Debug.Trace("[TFD][InCombatSession][R93Q] BeginSession actor=" + DescribeActor(akActor) + " token=" + SessionToken + " speakerBound=" + speakerBound + " reason=" + asReason)
EndFunction

Bool Function IsSessionValidForActor(Actor akActor)
	Actor useActor = akActor

	If !SessionActive
		TraceSession("RejectNoSession", akActor, "no_session")
		Return False
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		TraceSession("RejectStaleSessionSpeaker", SessionSpeaker, "stale_session_speaker")
		AbortSession("stale_session_speaker", SessionSpeaker, False, True)
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor == None || useActor.IsDead()
		TraceSession("RejectNoActor", akActor, "no_actor")
		Return False
	EndIf

	If useActor != SessionSpeaker
		TraceSession("RejectSpeakerMismatch", useActor, "speaker_mismatch")
		Return False
	EndIf

	If SessionOutcomeCommitted
		TraceSession("RejectCommitted", useActor, "already_committed")
		Return False
	EndIf

	Return True
EndFunction

Bool Function CommitSessionOutcome(Int aiResult, Actor akActor = None, String asReason = "")
	Actor useActor = akActor

	If !SessionActive
		TraceSession("RejectCommitNoSession", akActor, "no_session")
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor == None || useActor.IsDead()
		TraceSession("RejectCommitNoActor", akActor, "no_actor")
		Return False
	EndIf

	SessionOutcomeCommitted = True
	SessionStage = SESSION_STAGE_OUTCOME_COMMITTED
	If asReason != ""
		SessionReason = asReason
	EndIf
	SetResolvedState(aiResult)
	TraceSession("Commit", useActor, asReason)
	Return True
EndFunction

Function ClearSession(Bool abClearAlias = True, Bool abClearBridge = False, String asReason = "")
	Actor previousSpeaker = SessionSpeaker
	TraceSession("Clear", previousSpeaker, asReason)
	ClearSystemInCombatMirror(asReason)
	ResetSessionStateOnly()
	If abClearAlias
		If previousSpeaker != None
			ClearSpeakerForActor(previousSpeaker)
		Else
			ClearSpeaker()
		EndIf
	EndIf
	If abClearBridge
		ClearBridge()
	EndIf
EndFunction

Function AbortSession(String asReason = "", Actor akActor = None, Bool abClearBridge = False, Bool abClearAlias = True)
	Actor previousSpeaker = SessionSpeaker
	If akActor == None
		akActor = previousSpeaker
	EndIf
	If SessionActive || akActor != None
		TraceSession("Abort", akActor, asReason)
	EndIf
	ClearSystemInCombatMirror(asReason)
	ResetSessionStateOnly()
	If abClearAlias
		If akActor != None
			ClearSpeakerForActor(akActor)
		Else
			ClearSpeaker()
		EndIf
	EndIf
	If abClearBridge
		ClearBridge()
	EndIf
EndFunction

Function PruneStaleSpeaker()
	Actor a = GetAliasActor(Speaker)
	If a == None
		If SessionActive && IsActorStale(SessionSpeaker)
			AbortSession("stale_session_speaker", SessionSpeaker, False, True)
		EndIf
		Return
	EndIf

	If IsActorStale(a)
		AbortSession("stale_alias_speaker", a, False, True)
	EndIf
EndFunction

Float Function GetGraceOutcomeDuration()
	Float useDuration = GraceOutcomeDuration
	If useDuration <= 0.0
		useDuration = 10.0
	EndIf
	Return useDuration
EndFunction

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

Function SyncSystemInCombatRoot(Actor akActor, String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If !sysCtrl.HasActiveDialogueRoute() || sysCtrl.GetCurrentRouteFlow() != sysCtrl.FLOW_INCOMBAT
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.BeginDialogueRoute(sysCtrl.FLOW_INCOMBAT, sysCtrl.ENTRY_FORCEGREET, akActor, asReason)
	EndIf

	sysCtrl.MarkDialogueNegotiating(akActor, asReason)
EndFunction

Function SyncSystemInCombatPayBranch(Actor akActor, String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If !sysCtrl.HasActiveDialogueRoute() || sysCtrl.GetCurrentRouteFlow() != sysCtrl.FLOW_INCOMBAT
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.BeginDialogueRoute(sysCtrl.FLOW_INCOMBAT, sysCtrl.ENTRY_FORCEGREET, akActor, asReason)
	EndIf

	sysCtrl.MarkDialogueNegotiating(akActor, asReason)
	sysCtrl.SetDialogueMethod(sysCtrl.METHOD_PAY, akActor, asReason)
	sysCtrl.SetDialogueBranch(sysCtrl.BRANCH_PAY, akActor, asReason)
EndFunction

Function MarkSessionMethod(Int aiMethod, Int aiBranch, String asReason = "")
	SessionMethod = aiMethod
	SessionBranch = aiBranch
	If asReason != ""
		SessionReason = asReason
	EndIf
	TraceSession("MarkMethod", SessionSpeaker, asReason)
EndFunction

Bool Function EnterPayBranchForActor(Actor akActor, String asReason = "")
	Actor useActor = akActor
	If !IsRootSessionValidForActor(useActor)
		Return False
	EndIf
	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf
	If useActor == None || useActor.IsDead()
		Return False
	EndIf

	SessionStage = SESSION_STAGE_PAY_SELECTED
	SessionOutcomeCommitted = False
	MarkSessionMethod(SESSION_METHOD_PAY, SESSION_BRANCH_PAY, asReason)
	SetResolvedState(RESULT_PAY)
	SyncSystemInCombatPayBranch(useActor, asReason)
	TraceSession("EnterPayBranch", useActor, asReason)
	Return True
EndFunction

Bool Function IsRootSessionValidForActor(Actor akActor)
	If !IsSessionValidForActor(akActor)
		Return False
	EndIf
	If SessionStage != SESSION_STAGE_GREETING
		TraceSession("RejectRootStage", akActor, "stage_not_greeting")
		Return False
	EndIf
	If SessionMethod != SESSION_METHOD_NONE || SessionBranch != SESSION_BRANCH_NONE
		TraceSession("RejectRootMethod", akActor, "method_or_branch_not_none")
		Return False
	EndIf
	Return True
EndFunction

Bool Function IsPayBranchSessionValidForActor(Actor akActor)
	If !IsSessionValidForActor(akActor)
		Return False
	EndIf
	If SessionStage != SESSION_STAGE_PAY_SELECTED
		TraceSession("RejectPayStage", akActor, "stage_not_pay_selected")
		Return False
	EndIf
	If SessionMethod != SESSION_METHOD_PAY || SessionBranch != SESSION_BRANCH_PAY
		TraceSession("RejectPayMethod", akActor, "method_or_branch_not_pay")
		Return False
	EndIf
	Return True
EndFunction

Bool Function IsAlreadyManagedTeammate(Actor akActor)
	If akActor == None
		Return False
	EndIf
	If Registry != None
		If Registry.IsLikelyTeammateActor(akActor) || Registry.IsRegistered(akActor)
			Return True
		EndIf
	EndIf
	Return akActor.IsPlayerTeammate()
EndFunction

Function NormalizeRecruitSpeakerState(Actor akSpeaker, Actor akPlayer)
	If akSpeaker == None || akPlayer == None
		Return
	EndIf
	akSpeaker.SetRelationshipRank(akPlayer, 3)
	akPlayer.SetRelationshipRank(akSpeaker, 3)
	akSpeaker.SetPlayerTeammate(True, False)
	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
EndFunction

Function EndTemporaryFollow(Bool abRestoreHostility = False)
	If TemporaryFollowerQuest != None
		TemporaryFollowerQuest.EndFollow(abRestoreHostility)
	EndIf
EndFunction

Bool Function PromoteActorAsRecruitLikeOutcomeInternal(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()

	If playerRef == None
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If IsAlreadyManagedTeammate(akSpeaker)
		Debug.Trace("[TFD][InCombatSession] PromoteActorAsRecruitLikeOutcomeInternal reject actor already teammate actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	NormalizeRecruitSpeakerState(akSpeaker, playerRef)

	If Registry != None
		Registry.RegisterOrRefreshTeammate(akSpeaker)
	EndIf

	Return True
EndFunction

Bool Function BeginTemporaryFollowInternal(Actor akSpeaker, Float afDuration = 0.0)
	Float useDuration = afDuration

	If useDuration <= 0.0
		useDuration = FollowDuration
	EndIf
	If useDuration <= 0.0
		useDuration = 60.0
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If TemporaryFollowerQuest == None
		Debug.Trace("[TFD][InCombatSession] BeginTemporaryFollowInternal abort TemporaryFollowerQuest NONE")
		Return False
	EndIf
	If IsAlreadyManagedTeammate(akSpeaker)
		Debug.Trace("[TFD][InCombatSession] BeginTemporaryFollowInternal reject actor already teammate actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	Utility.WaitMenuMode(0.20)
	Bool started = TemporaryFollowerQuest.BeginFollow(akSpeaker, useDuration)
	Debug.Trace("[TFD][InCombatSession] BeginTemporaryFollowInternal result=" + started + " actor=" + DescribeActor(akSpeaker) + " duration=" + useDuration)
	Return started
EndFunction

Bool Function BeginJoinEnemyInternal(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()

	If playerRef == None
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	JoinEnemyActive = True
	JoinEnemyLocation = playerRef.GetCurrentLocation()
	JoinEnemySourceActor = akSpeaker

	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
	QueueUpdate()
	Debug.Trace("[TFD][InCombatSession] BeginJoinEnemyInternal actor=" + DescribeActor(akSpeaker) + " location=" + JoinEnemyLocation)
	Return True
EndFunction

Function UpdateJoinEnemy()
	Actor playerRef = Game.GetPlayer()

	If !JoinEnemyActive
		Return
	EndIf
	If playerRef == None
		EndJoinEnemy(False)
		Return
	EndIf
	If JoinEnemyLocation == None
		EndJoinEnemy(True)
		Return
	EndIf
	If playerRef.GetCurrentLocation() != JoinEnemyLocation
		EndJoinEnemy(True)
		Return
	EndIf
EndFunction

Function EndJoinEnemy(Bool abRewardSuccess)
	JoinEnemyActive = False
	JoinEnemyLocation = None
	JoinEnemySourceActor = None
	If abRewardSuccess
		TFDSystemEventQuestScript sysCtrl = GetSystemController()
		If sysCtrl != None
			sysCtrl.ClearTransientDialogueBridges()
		EndIf
	EndIf
EndFunction

Function ClearBridge()
	; retired bridge path intentionally no-op for direct native hookup
EndFunction

Function ClearTransientDialogueBridges()
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl != None
		sysCtrl.ClearTransientDialogueBridges()
		Debug.Trace("[TFD][InCombatSession][R94B] ClearTransientDialogueBridges")
	EndIf
EndFunction

Function ClearSystemInCombatMirror(String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If sysCtrl.HasActiveDialogueRoute() && sysCtrl.GetCurrentRouteFlow() == sysCtrl.FLOW_INCOMBAT
		sysCtrl.FinalizeTerminalDialogueRoute(asReason)
	ElseIf !sysCtrl.HasActiveDialogueRoute() && sysCtrl.GetCurrentRouteFlow() == sysCtrl.FLOW_NONE
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.ClearActiveFlow()
	EndIf
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

Bool Function IsJoinEnemyOfferedByNative()
	If TFDJoinEnemyState == None
		Return False
	EndIf
	Return (TFDJoinEnemyState.GetValueInt() != 0)
EndFunction

Function PrepareNeutralSpeaker(Actor akSpeaker)
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf
	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
EndFunction

Actor Function ResolveCurrentSpeaker()
	Actor akSpeaker = GetSpeaker()
	If akSpeaker != None
		Return akSpeaker
	EndIf
	If PleasureLockActive && PleasureLockActor != None && !PleasureLockActor.IsDead()
		Return PleasureLockActor
	EndIf
	If SessionSpeaker != None && !SessionSpeaker.IsDead()
		Return SessionSpeaker
	EndIf
	Return None
EndFunction

Bool Function ResolvePay()
	Return ResolvePayForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolvePayForActor(Actor akActor)
	Actor playerRef = Game.GetPlayer()
	Actor akSpeaker = akActor

	If playerRef == None || Gold001 == None
		Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay rejected reason=missing_player_or_gold_property")
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay rejected reason=invalid_speaker input=" + akActor + " session=" + SessionSpeaker)
		Return False
	EndIf

	If !IsRootSessionValidForActor(akSpeaker)
		Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay rejected reason=root_session_invalid actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	Int payAmount = GetPayAmount()
	Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay begin actor=" + DescribeActor(akSpeaker) + " pay=" + payAmount + " method=" + SessionMethod + " branch=" + SessionBranch + " stage=" + SessionStage)

	If payAmount <= 0
		Debug.Notification("TFD: No valid InCombat payment price.")
		Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay rejected reason=invalid_pay_amount actor=" + DescribeActor(akSpeaker) + " pay=" + payAmount)
		Return False
	EndIf

	; Match PreCombat ordering: enter the pay branch first so SystemEvent
	; accepts Release/Recruit/Follow/JoinEnemy before gold is removed.
	If !EnterPayBranchForActor(akSpeaker, "resolve_pay")
		Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay rejected reason=enter_pay_branch_failed actor=" + DescribeActor(akSpeaker) + " pay=" + payAmount)
		Return False
	EndIf

	playerRef.RemoveItem(Gold001, payAmount, True, akSpeaker)
	SendModEvent("TFDInCombatOutcomePay", ActorFormIDString(akSpeaker), payAmount as Float)
	Debug.Trace("[TFD][InCombatSession][R93U] ResolvePay branch actor=" + DescribeActor(akSpeaker) + " pay=" + payAmount)
	Return True
EndFunction

Bool Function ResolveFight()
	Return ResolveFightForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveFightForActor(Actor akActor)
	Actor akSpeaker = akActor
	Actor playerRef = Game.GetPlayer()

	If !IsRootSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_FIGHT, akSpeaker, "resolve_fight")
		Return False
	EndIf

	ClearSession(False, False, "resolve_fight")
	SendModEvent("TFDInCombatOutcomeFight", ActorFormIDString(akSpeaker))
	If playerRef != None
		akSpeaker.StopCombatAlarm()
		akSpeaker.StartCombat(playerRef)
		akSpeaker.EvaluatePackage()
	EndIf
	Return True
EndFunction

Bool Function ResolveKidnap()
	Return ResolveKidnapForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveKidnapForActor(Actor akActor)
	Actor akSpeaker = akActor

	If !IsRootSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_KIDNAP, akSpeaker, "resolve_kidnap")
		Return False
	EndIf

	PrepareNeutralSpeaker(akSpeaker)
	ClearSession(False, False, "resolve_kidnap")
	SendModEvent("TFDInCombatOutcomeCaptive", ActorFormIDString(akSpeaker))
	Return True
EndFunction

Bool Function ResolveRecruit()
	Return ResolveRecruitForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveRecruitForActor(Actor akActor)
	Actor akSpeaker = akActor
	Bool ok = False

	If !IsPayBranchSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_RECRUIT, akSpeaker, "resolve_recruit")
		Return False
	EndIf

	PrepareNeutralSpeaker(akSpeaker)
	ok = PromoteActorAsRecruitLikeOutcomeInternal(akSpeaker)
	ClearSession(False, False, "resolve_recruit")
	If ok
		SendModEvent("TFDInCombatOutcomeRecruit", ActorFormIDString(akSpeaker), GetGraceOutcomeDuration())
	Else
		SendModEvent("TFDInCombatOutcomeFailed", ActorFormIDString(akSpeaker))
	EndIf
	Return ok
EndFunction

Bool Function ResolveJoinEnemy()
	Return ResolveJoinEnemyForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveJoinEnemyForActor(Actor akActor)
	Actor akSpeaker = akActor
	Bool ok = False

	If !IsJoinEnemyOfferedByNative()
		Debug.Notification("TFD: Join Enemy is not available here.")
		Return False
	EndIf
	If !IsPayBranchSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_JOINENEMY, akSpeaker, "resolve_join_enemy")
		Return False
	EndIf

	PrepareNeutralSpeaker(akSpeaker)
	ok = BeginJoinEnemyInternal(akSpeaker)
	ClearSession(False, False, "resolve_join_enemy")
	If ok
		SendModEvent("TFDInCombatOutcomeJoinEnemy", ActorFormIDString(akSpeaker), GetGraceOutcomeDuration())
	Else
		SendModEvent("TFDInCombatOutcomeFailed", ActorFormIDString(akSpeaker))
	EndIf
	Return ok
EndFunction

Bool Function ResolveRelease()
	Return ResolveReleaseForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveReleaseForActor(Actor akActor)
	Actor akSpeaker = akActor
	Float useDuration = GetGraceOutcomeDuration()

	If !IsPayBranchSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_RELEASE, akSpeaker, "resolve_release")
		Return False
	EndIf

	If useDuration <= 0.0
		useDuration = ReleaseSafePassDuration
	EndIf
	If useDuration <= 0.0
		useDuration = 10.0
	EndIf

	; R93W: mirror PreCombat Pay > Release. Do not call PrepareNeutralSpeaker()
	; before the native release lifecycle starts. That StopCombat path, followed by
	; Generic truce cleanup, was the source of the cross-save passive state.
	ClearSession(False, False, "resolve_release")
	StartReleaseSafePassForActorWithDuration(akSpeaker, useDuration, "resolve_release")
	SendModEvent("TFDInCombatOutcomeRelease", ActorFormIDString(akSpeaker), useDuration)
	Debug.Trace("[TFD][InCombatSession][R93W] ResolveRelease sent actor=" + DescribeActor(akSpeaker) + " duration=" + useDuration)
	Return True
EndFunction


Function StartReleaseSafePassForActorWithDuration(Actor akActor, Float afDuration, String asReason = "")
	EndReleaseSafePass(False, "replace_release_safe_pass")

	If akActor == None || akActor.IsDead()
		Return
	EndIf

	Float useDuration = afDuration
	If useDuration <= 0.0
		useDuration = ReleaseSafePassDuration
	EndIf
	If useDuration <= 0.0
		useDuration = 10.0
	EndIf

	ReleaseSafePassActor = akActor
	ReleaseSafePassExpireAt = Utility.GetCurrentRealTime() + useDuration
	ReleaseSafePassActive = True
	Debug.Trace("[TFD][InCombatSession][R93W] StartReleaseSafePass actor=" + DescribeActor(akActor) + " duration=" + useDuration + " reason=" + asReason)
	QueueUpdate()
EndFunction

Function UpdateReleaseSafePass()
	If !ReleaseSafePassActive
		Return
	EndIf

	If ReleaseSafePassActor == None || ReleaseSafePassActor.IsDead()
		EndReleaseSafePass(False, "release_safe_pass_actor_invalid")
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= ReleaseSafePassExpireAt
		; R93X: match PreCombat SafePass. When the paid release grace ends,
		; restore hostility instead of leaving the actor in the stopped-combat
		; safe-pass state forever.
		EndReleaseSafePass(True, "release_safe_pass_expired")
		Return
	EndIf
EndFunction

Function EndReleaseSafePass(Bool abRestoreHostility, String asReason = "")
	Actor playerRef = Game.GetPlayer()
	Actor previousActor = ReleaseSafePassActor
	Bool hadSafePass = ReleaseSafePassActive || previousActor != None

	ReleaseSafePassActive = False
	ReleaseSafePassActor = None
	ReleaseSafePassExpireAt = 0.0

	If hadSafePass
		SendModEvent("TFDInCombatOutcomeReleaseEnd", ActorFormIDString(previousActor), abRestoreHostility as Float)
		Debug.Trace("[TFD][InCombatSession][R93X] EndReleaseSafePass actor=" + DescribeActor(previousActor) + " restore=" + abRestoreHostility + " reason=" + asReason)
	EndIf

	If previousActor != None && abRestoreHostility && playerRef != None && !previousActor.IsDead()
		previousActor.StopCombatAlarm()
		previousActor.StartCombat(playerRef)
		previousActor.EvaluatePackage()
		Debug.Trace("[TFD][InCombatSession][R93X] EndReleaseSafePass restore combat actor=" + DescribeActor(previousActor) + " reason=" + asReason)
	EndIf
EndFunction

Bool Function ResolveFollow()
	Return ResolveFollowForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveFollowForActor(Actor akActor)
	Actor akSpeaker = akActor
	Bool ok = False
	Float useDuration = FollowDuration

	If useDuration <= 0.0
		useDuration = 60.0
	EndIf
	If !IsPayBranchSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_FOLLOW, akSpeaker, "resolve_follow")
		Return False
	EndIf

	PrepareNeutralSpeaker(akSpeaker)
	ok = BeginTemporaryFollowInternal(akSpeaker, useDuration)
	ClearSession(False, False, "resolve_follow")
	If ok
		SendModEvent("TFDInCombatOutcomeFollow", ActorFormIDString(akSpeaker), GetGraceOutcomeDuration())
	Else
		SendModEvent("TFDInCombatOutcomeFailed", ActorFormIDString(akSpeaker))
	EndIf
	Return ok
EndFunction

Bool Function ResolveDoNothing()
	Return ResolveDoNothingForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveDoNothingForActor(Actor akActor)
	Actor akSpeaker = akActor

	If !IsRootSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_DONOTHING, akSpeaker, "resolve_do_nothing")
		Return False
	EndIf

	ClearSession(False, False, "resolve_do_nothing")
	SendModEvent("TFDInCombatOutcomeDoNothing", ActorFormIDString(akSpeaker))
	Return True
EndFunction

Bool Function ResolvePleasure()
	Return ResolvePleasureForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolvePleasureForActor(Actor akActor)
	Actor akSpeaker = akActor
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()

	If !IsRootSessionValidForActor(akSpeaker)
		Return False
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf
	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf
	If pleasureCtrl == None
		Debug.Notification("TFD: Pleasure quest is not available.")
		Debug.Trace("[TFD][InCombatSession] ResolvePleasureForActor failed pleasure quest none actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf
	If !CommitSessionOutcome(RESULT_PLEASURE, akSpeaker, "resolve_pleasure")
		Return False
	EndIf

	BeginPleasureLock(akSpeaker)
	; R93Z: Match PreCombat. Native owns the truce/pacify handoff, so do not
	; pre-clear combat state here. Clearing locally before native expands the
	; handoff can leave nearby combatants awake and collide with OStim start.
	SendModEvent("TFDInCombatOutcomePleasure", ActorFormIDString(akSpeaker), 0.0)

	Bool pleasureStartOk = pleasureCtrl.BeginPleasureAutoStart(akSpeaker, PleasureSourceInCombat, 0, "incombat")
	Debug.Trace("[TFD][InCombatSession][R93T] ResolvePleasureForActor autoStart=" + pleasureStartOk + " actor=" + DescribeActor(akSpeaker) + " preserve_session=true")

	If !pleasureStartOk
		pleasureCtrl.AbortPleasureToNeutral("incombat_start_failed", False, True)
		ReleasePleasureLock(True)
		SendModEvent("TFDInCombatOutcomeFailed", ActorFormIDString(akSpeaker))
		AbortSession("resolve_pleasure_start_failed", akSpeaker, False, True)
		Debug.Notification("TFD: Pleasure failed.")
		Return False
	EndIf

	Return True
EndFunction