Scriptname TFDPreCombatQuestScript extends Quest

ReferenceAlias Property Speaker Auto

GlobalVariable Property TFDJoinEnemyState Auto
GlobalVariable Property TFDPayGold Auto
GlobalVariable Property TFDRecruitSlotsFree Auto

TFDPlayerTeammateQuestScript Property Registry Auto
TFDTemporaryFollowerQuestScript Property TemporaryFollowerQuest Auto

Quest Property TFDSystemEventQuest Auto
Quest Property TFDTruceBridgeQuest Auto
Quest Property TFDPleasureQuest Auto

MiscObject Property Gold001 Auto

Float Property UpdateInterval = 0.5 Auto
Float Property SafePassDuration = 20.0 Auto
Float Property SafePassBreakDistance = 180.0 Auto
Float Property FollowDuration = 60.0 Auto
Float Property ReleaseDuration = 10.0 Auto
Float Property PayPercent = 0.10 Auto

String Property PleasureEventName = "TFDPreCombatPleasure" Auto
String TerminalPendingEventName = "TFDPreCombatTerminalPending"
String RecruitPendingEventName = "TFDPreCombatRecruitPending"

Int Property RESULT_FIGHT = 1 Auto Hidden
Int Property RESULT_KIDNAP = 2 Auto Hidden
Int Property RESULT_PLEASURE = 3 Auto Hidden
Int Property RESULT_DONOTHING = 4 Auto Hidden
Int Property RESULT_RELEASE = 5 Auto Hidden
Int Property RESULT_PAY = 6 Auto Hidden
Int Property RESULT_RECRUIT = 7 Auto Hidden
Int Property RESULT_FOLLOW = 8 Auto Hidden
Int Property RESULT_JOINENEMY = 9 Auto Hidden

Actor ManagedRecruitActor
Actor ManagedFollowActor

Bool SafePassActive = False
Actor SafePassActor
Float SafePassExpireAt = 0.0
Int SafePassResult = 0

Bool FollowActive = False
Float FollowExpireAt = 0.0

Bool JoinEnemyActive = False
Location JoinEnemyLocation
Actor JoinEnemySourceActor

Bool PleasureLockActive = False
Actor PleasureLockActor

Bool SessionActive = False
Int SessionToken = 0
Actor SessionSpeaker
Int SessionStage = 0
Int SessionMethod = 0
Int SessionBranch = 0
Bool SessionOutcomeCommitted = False
Float SessionStartedAt = 0.0
String SessionReason = ""

Int ApproachActivationToken = -1
Int ApproachActivationPasses = 0
Float ApproachActivationStartedAt = 0.0
Float ApproachNextEvaluateAt = 0.0

Int SESSION_STAGE_NONE = 0
Int SESSION_STAGE_GREETING = 1
Int SESSION_STAGE_PAY_SELECTED = 2
Int SESSION_STAGE_OUTCOME_COMMITTED = 3

Int SESSION_METHOD_NONE = 0
Int SESSION_METHOD_PAY = 1
Int SESSION_METHOD_PLEASURE = 2
Int SESSION_METHOD_DO_NOTHING = 3
Int SESSION_METHOD_FIGHT = 4
Int SESSION_METHOD_KIDNAP = 5

Int SESSION_BRANCH_NONE = 0
Int SESSION_BRANCH_PAY = 1

Function RegisterBridgeEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDPreCombatAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDPreCombatClear", "OnBridgeEvent")
	RegisterForModEvent("TFDPreCombatClearAll", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceRelease", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceRecruit", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceFinish", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceJoinEnemy", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceKidnap", "OnBridgeEvent")
	RegisterForModEvent("TFDAfterPleasureChoiceWork", "OnBridgeEvent")
	RegisterForModEvent("TFDPreCombatPleasureFailed", "OnBridgeEvent")
	RegisterForModEvent("TFDPleasureAborted", "OnBridgeEvent")
EndFunction

Event OnInit()
	RegisterBridgeEvents()
	ClearSpeaker()
	QueueUpdate()
EndEvent

Event OnPlayerLoadGame()
	AbortSession("load_game", None, False, True)
	PleasureLockActive = False
	PleasureLockActor = None
	ClearBridge()
	RegisterBridgeEvents()
	QueueUpdate()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor aEvent = sender as Actor

	If IsAfterPleasureTerminalEvent(eventName)
		HandleAfterPleasureTerminalEvent(eventName, strArg, numArg, sender)
		Return
	EndIf

	If eventName == "TFDPreCombatPleasureFailed" || eventName == "TFDPleasureAborted"
		HandlePleasureHandoffEnded(eventName, strArg, numArg, sender)
		Return
	EndIf

	If eventName == "TFDPreCombatAssign"
		If aEvent != None && !aEvent.IsDead()
			BeginSessionForActor(aEvent, "bridge_assign")
			QueueUpdate()
		EndIf
		Return
	EndIf

	If eventName == "TFDPreCombatClear"
		If ShouldIgnoreBridgeClear(aEvent)
			TraceSession("IgnoreBridgeClear", aEvent, "bridge_clear_guarded")
			If SessionSpeaker != None
				SetSpeaker(SessionSpeaker)
			EndIf
			If ShouldKeepUpdating()
				QueueUpdate()
			EndIf
			Return
		EndIf
		AbortSession("bridge_clear", aEvent, False, True)
		If ShouldKeepUpdating()
			QueueUpdate()
		EndIf
		Return
	EndIf

	If eventName == "TFDPreCombatClearAll"
		If ShouldIgnoreBridgeClearAll(sender)
			TraceSession("IgnoreBridgeClearAll", SessionSpeaker, "bridge_clear_all_guarded")
			If ShouldKeepUpdating()
				QueueUpdate()
			EndIf
			Return
		EndIf
		AbortSession("bridge_clear_all", None, False, True)
		If ShouldKeepUpdating()
			QueueUpdate()
		EndIf
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

Bool Function IsPreCombatPleasureSessionActive()
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
	; Event-driven preserve: this does not expire by timeout.
	; It ends only when Pleasure/AfterPleasure sends an explicit terminal, abort, or failure event.
	If !IsPreCombatPleasureSessionActive()
		Return False
	EndIf
	If !PleasureLockActive
		Return False
	EndIf
	Return True
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
	Debug.Trace("[TFD][PreCombatSession] CompletePleasureHandoffSession reason=" + asReason + " actor=" + DescribeActor(previousSpeaker))
EndFunction

Function HandleAfterPleasureTerminalEvent(String eventName, String strArg, Float numArg, Form sender)
	If !IsPreCombatPleasureSessionActive()
		Return
	EndIf

	; TFDPleasureQuest sends CurrentSourceFlow as numArg for after-pleasure choices.
	; SourcePreCombat is 1. Ignore non-precombat terminal events so unrelated pleasure flows
	; do not clear a precombat session by accident.
	If numArg != 1.0
		Debug.Trace("[TFD][PreCombatSession] IgnoreAfterPleasureTerminal event=" + eventName + " source=" + numArg + " reason=not_precombat_source")
		Return
	EndIf

	TraceSession("AfterPleasureTerminalClear", SessionSpeaker, eventName)
	CompletePleasureHandoffSession("after_pleasure_terminal_" + eventName)
EndFunction

Function HandlePleasureHandoffEnded(String eventName, String strArg, Float numArg, Form sender)
	If !IsPreCombatPleasureSessionActive()
		Return
	EndIf

	TraceSession("PleasureHandoffEnded", SessionSpeaker, eventName)
	CompletePleasureHandoffSession("pleasure_handoff_end_" + eventName)
EndFunction

Function QueueUpdate()
	UnregisterForUpdate()
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Bool Function ShouldKeepUpdating()
	If SessionActive
		Return True
	EndIf

	If GetSpeaker() != None
		Return True
	EndIf

	If SafePassActive
		Return True
	EndIf

	If FollowActive
		Return True
	EndIf

	If JoinEnemyActive
		Return True
	EndIf

	Return False
EndFunction

Event OnUpdate()
	PruneStaleSpeaker()
	MaintainSpeakerApproachActivation()
	UpdateSafePass()
	UpdateTemporaryFollow()
	UpdateJoinEnemy()

	If ShouldKeepUpdating()
		RegisterForSingleUpdate(UpdateInterval)
	EndIf
EndEvent

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
		ClearBridge()
	EndIf
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

Bool Function BindSpeakerForNewSession(Actor akActor, String asReason = "")
	If Speaker == None
		Debug.Trace("[TFD][PreCombatSession] BindSpeakerForNewSession failed reason=no_alias actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return False
	EndIf

	If akActor == None || akActor.IsDead()
		Debug.Trace("[TFD][PreCombatSession] BindSpeakerForNewSession failed reason=invalid_actor actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return False
	EndIf

	Actor currentActor = GetAliasActor(Speaker)
	If currentActor != None
		Speaker.Clear()
		Utility.Wait(0.05)
	EndIf

	Speaker.ForceRefTo(akActor)
	Utility.Wait(0.05)

	Bool bound = (Speaker.GetReference() == akActor)
	Debug.Trace("[TFD][PreCombatSession] BindSpeakerForNewSession bound=" + bound + " previous=" + DescribeActor(currentActor) + " actor=" + DescribeActor(akActor) + " reason=" + asReason)
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
	Debug.Trace("[TFD][PreCombatSession] ArmApproach token=" + ApproachActivationToken + " actor=" + DescribeActor(SessionSpeaker) + " reason=" + asReason)
EndFunction

Function DisarmSpeakerApproachActivation()
	ApproachActivationToken = -1
	ApproachActivationPasses = 0
	ApproachActivationStartedAt = 0.0
	ApproachNextEvaluateAt = 0.0
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
		Debug.Trace("[TFD][PreCombatSession] MaintainApproach skipped reason=alias_mismatch token=" + SessionToken + " actor=" + DescribeActor(SessionSpeaker))
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
		Debug.Trace("[TFD][PreCombatSession] EvaluateApproach skipped reason=alias_mismatch actor=" + DescribeActor(akActor) + " source=" + asReason)
		Return
	EndIf

	If abStopCombat
		akActor.StopCombat()
		akActor.StopCombatAlarm()
	EndIf

	akActor.EvaluatePackage()
	Debug.Trace("[TFD][PreCombatSession] EvaluateApproach pass=" + ApproachActivationPasses + " token=" + SessionToken + " actor=" + DescribeActor(akActor) + " reason=" + asReason + " stopCombat=" + abStopCombat)
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

Actor Function GetAliasActor(ReferenceAlias akAlias)
	If akAlias == None
		Return None
	EndIf

	Return akAlias.GetActorReference()
EndFunction

Function ClearAliasIfMatches(ReferenceAlias akAlias, Actor akActor)
	If akAlias == None
		Return
	EndIf

	If akAlias.GetReference() == akActor
		akAlias.Clear()
	EndIf
EndFunction

Int LastResolvedResult = 0

Function SetResolvedState(Int aiResult)
	LastResolvedResult = aiResult
EndFunction

String Function DescribeActor(Actor akActor)
	If akActor == None
		Return "None"
	EndIf
	Return akActor + "(" + ActorFormIDString(akActor) + ")"
EndFunction

Function ReleaseSpeakerForceGreetPackage(Actor akActor, String asReason = "")
	Actor useActor = akActor

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor != None
		ClearSpeakerForActor(useActor)
		useActor.EvaluatePackage()
	Else
		ClearSpeaker()
	EndIf

	DisarmSpeakerApproachActivation()
	Debug.Trace("[TFD][PreCombatSession] ReleaseSpeakerForceGreetPackage actor=" + DescribeActor(useActor) + " reason=" + asReason)
EndFunction

Function TraceSession(String asEvent, Actor akActor = None, String asReason = "")
	String reasonText = asReason
	If reasonText == ""
		reasonText = SessionReason
	EndIf
	Debug.Trace("[TFD][PreCombatSession] " + asEvent + " token=" + SessionToken + " active=" + SessionActive + " stage=" + SessionStage + " method=" + SessionMethod + " branch=" + SessionBranch + " committed=" + SessionOutcomeCommitted + " actor=" + DescribeActor(akActor) + " sessionSpeaker=" + DescribeActor(SessionSpeaker) + " reason=" + reasonText)
EndFunction

Function ResetSessionStateOnly()
	SessionActive = False
	SessionSpeaker = None
	SessionStage = SESSION_STAGE_NONE
	SessionMethod = SESSION_METHOD_NONE
	SessionBranch = SESSION_BRANCH_NONE
	SessionOutcomeCommitted = False
	SessionStartedAt = 0.0
	SessionReason = ""
	DisarmSpeakerApproachActivation()
EndFunction

Function BeginSessionForActor(Actor akActor, String asReason = "")
	Debug.Trace("[TFD][DiagRecruit] PreCombat BeginSessionForActor entry actor=" + DescribeActor(akActor) + " reason=" + asReason + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " committed=" + SessionOutcomeCommitted)
	If akActor == None || akActor.IsDead()
		Debug.Trace("[TFD][DiagRecruit] PreCombat BeginSessionForActor rejected invalid actor")
		Return
	EndIf

	If SessionActive && SessionSpeaker != None && !IsActorStale(SessionSpeaker)
		If IsLocalPayBranchStage() || IsCommittedTerminalStage()
			If akActor == SessionSpeaker
				TraceSession("PreserveBeginReuse", akActor, "preserve_existing_session")
				SetSpeaker(SessionSpeaker)
				Return
			EndIf

			TraceSession("RejectBeginPreserve", akActor, "preserve_other_session")
			Debug.Trace("[TFD][DiagRecruit] PreCombat BeginSessionForActor rejected preserve active session actor=" + DescribeActor(akActor) + " existingSpeaker=" + DescribeActor(SessionSpeaker) + " method=" + SessionMethod + " branch=" + SessionBranch + " committed=" + SessionOutcomeCommitted)
			Return
		EndIf
	EndIf

	SessionToken += 1
	SessionActive = True
	SessionSpeaker = akActor
	SessionStage = SESSION_STAGE_GREETING
	SessionMethod = SESSION_METHOD_NONE
	SessionBranch = SESSION_BRANCH_NONE
	SessionOutcomeCommitted = False
	SessionStartedAt = Utility.GetCurrentRealTime()
	SessionReason = asReason
	Bool speakerBound = BindSpeakerForNewSession(akActor, asReason)
	SyncSystemPreCombatRoot(akActor, asReason)
	If speakerBound
		PrimeSpeakerApproachActivation(akActor, asReason)
	EndIf
	TraceSession("Begin", akActor, asReason)
	Debug.Trace("[TFD][DiagRecruit] PreCombat BeginSessionForActor started actor=" + DescribeActor(akActor) + " token=" + SessionToken + " method=" + SessionMethod + " branch=" + SessionBranch + " committed=" + SessionOutcomeCommitted + " speakerBound=" + speakerBound)
EndFunction

Function MarkSessionMethod(Int aiMethod, Int aiBranch = 0, Actor akActor = None, String asReason = "")
	If !SessionActive
		Return
	EndIf

	If akActor != None
		SessionSpeaker = akActor
	EndIf

	SessionMethod = aiMethod
	SessionBranch = aiBranch
	If aiMethod == SESSION_METHOD_PAY
		SessionStage = SESSION_STAGE_PAY_SELECTED
	EndIf
	If asReason != ""
		SessionReason = asReason
	EndIf
	If aiMethod == SESSION_METHOD_PAY
		SyncSystemPreCombatPayBranch(SessionSpeaker, asReason)
	Else
		SyncSystemPreCombatRoot(SessionSpeaker, asReason)
	EndIf
	TraceSession("MarkMethod", SessionSpeaker, asReason)
EndFunction

Bool Function EnterPayBranchForActor(Actor akActor, String asReason = "")
	Actor useActor = akActor

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If !IsRootSessionValidForActor(useActor)
		Debug.Trace("[TFD][DiagRecruit] PreCombat EnterPayBranchForActor rejected actor=" + DescribeActor(useActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		Debug.Trace("[TFD][DiagRecruit] PreCombat EnterPayBranchForActor invalid actor after root validation")
		Return False
	EndIf

	MarkSessionMethod(SESSION_METHOD_PAY, SESSION_BRANCH_PAY, useActor, asReason)
	TraceSession("EnterPayBranch", useActor, asReason)
	Return IsPayBranchSessionValidForActor(useActor)
EndFunction

Bool Function IsRootSessionValidForActor(Actor akActor)
	Actor useActor = akActor

	If !SessionActive
		TraceSession("RejectRootNoSession", akActor, "no_session")
		Return False
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		TraceSession("RejectRootStaleSessionSpeaker", SessionSpeaker, "stale_session_speaker")
		AbortSession("stale_session_speaker", SessionSpeaker, False, True)
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor == None || useActor.IsDead()
		TraceSession("RejectRootNoActor", akActor, "no_actor")
		Return False
	EndIf

	If useActor != SessionSpeaker
		TraceSession("RejectRootSpeakerMismatch", useActor, "speaker_mismatch")
		Return False
	EndIf

	If SessionOutcomeCommitted
		TraceSession("RejectRootCommitted", useActor, "already_committed")
		Return False
	EndIf

	If SessionMethod != SESSION_METHOD_NONE || SessionBranch != SESSION_BRANCH_NONE
		TraceSession("RejectRootWrongStage", useActor, "not_root_stage")
		Return False
	EndIf

	Return True
EndFunction

Bool Function IsLocalPayBranchStage()
	If !SessionActive
		Return False
	EndIf

	If SessionOutcomeCommitted
		Return False
	EndIf

	If SessionMethod != SESSION_METHOD_PAY
		Return False
	EndIf

	If SessionBranch != SESSION_BRANCH_PAY
		Return False
	EndIf

	If SessionStage != SESSION_STAGE_PAY_SELECTED
		Return False
	EndIf

	Return True
EndFunction

Bool Function IsCommittedTerminalStage()
	If !SessionActive
		Return False
	EndIf

	If !SessionOutcomeCommitted
		Return False
	EndIf

	If SessionStage != SESSION_STAGE_OUTCOME_COMMITTED
		Return False
	EndIf

	Return True
EndFunction

Bool Function ShouldPreserveSessionDuringBridgeClear(Actor akActor = None)
	Actor useActor = akActor

	If !IsLocalPayBranchStage() && !IsPleasureHandoffPreserveActive()
		Return False
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor != None && SessionSpeaker != None && useActor != SessionSpeaker
		Return False
	EndIf

	Return True
EndFunction

Bool Function ShouldPreserveSessionDuringBridgeClearAll(Form akSender = None)
	Actor senderActor = akSender as Actor

	If SessionActive && !SessionOutcomeCommitted && SessionStage == SESSION_STAGE_GREETING
		If SessionSpeaker != None && !IsActorStale(SessionSpeaker) && senderActor == None
			Float sessionAge = Utility.GetCurrentRealTime() - SessionStartedAt
			If sessionAge >= 0.0 && sessionAge <= 4.0
				Return True
			EndIf
		EndIf
	EndIf

	If !IsLocalPayBranchStage() && !IsPleasureHandoffPreserveActive()
		Return False
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		Return False
	EndIf

	If senderActor != None && senderActor != SessionSpeaker
		Return False
	EndIf

	Return True
EndFunction

Bool Function ShouldIgnoreBridgeClear(Actor akActor = None)
	Return ShouldPreserveSessionDuringBridgeClear(akActor)
EndFunction

Bool Function ShouldIgnoreBridgeClearAll(Form akSender = None)
	Return ShouldPreserveSessionDuringBridgeClearAll(akSender)
EndFunction

Bool Function IsPayBranchSessionValidForActor(Actor akActor)
	Actor useActor = akActor

	If !SessionActive
		TraceSession("RejectPayNoSession", akActor, "no_session")
		Return False
	EndIf

	If SessionSpeaker == None || IsActorStale(SessionSpeaker)
		TraceSession("RejectPayStaleSessionSpeaker", SessionSpeaker, "stale_session_speaker")
		AbortSession("stale_session_speaker", SessionSpeaker, False, True)
		Return False
	EndIf

	If useActor == None || useActor.IsDead()
		useActor = SessionSpeaker
	EndIf

	If useActor == None || useActor.IsDead()
		TraceSession("RejectPayNoActor", akActor, "no_actor")
		Return False
	EndIf

	If useActor != SessionSpeaker
		TraceSession("RejectPaySpeakerMismatch", useActor, "speaker_mismatch")
		Return False
	EndIf

	If SessionOutcomeCommitted
		TraceSession("RejectPayCommitted", useActor, "already_committed")
		Return False
	EndIf

	If SessionMethod != SESSION_METHOD_PAY
		TraceSession("RejectPayWrongMethod", useActor, "not_pay_method")
		Return False
	EndIf

	If SessionBranch != SESSION_BRANCH_PAY
		TraceSession("RejectPayWrongBranch", useActor, "not_pay_branch")
		Return False
	EndIf

	If SessionStage != SESSION_STAGE_PAY_SELECTED
		TraceSession("RejectPayWrongStage", useActor, "not_pay_stage")
		Return False
	EndIf

	Debug.Trace("[TFD][DiagRecruit] PreCombat IsPayBranchSessionValidForActor accepted actor=" + DescribeActor(useActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " stage=" + SessionStage + " committed=" + SessionOutcomeCommitted)
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
	ClearSystemPreCombatMirror(asReason)
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
	ClearSystemPreCombatMirror(asReason)
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

Function ClearBridge()
	SendModEvent("TFDPreCombatClearAll")
EndFunction

TFDSystemEventQuestScript Function GetSystemController()
	If TFDSystemEventQuest == None
		Return None
	EndIf

	Return TFDSystemEventQuest as TFDSystemEventQuestScript
EndFunction

TFDTruceBridge Function GetTruceBridge()
	If TFDTruceBridgeQuest == None
		Return None
	EndIf

	Return TFDTruceBridgeQuest as TFDTruceBridge
EndFunction


TFDPleasureQuestScript Function GetPleasureController()
	If TFDPleasureQuest == None
		Return None
	EndIf

	Return TFDPleasureQuest as TFDPleasureQuestScript
EndFunction


Function SyncSystemPreCombatRoot(Actor akActor, String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If !sysCtrl.HasActiveDialogueRoute() || sysCtrl.GetCurrentRouteFlow() != sysCtrl.FLOW_PRECOMBAT
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.BeginDialogueRoute(sysCtrl.FLOW_PRECOMBAT, sysCtrl.ENTRY_FORCEGREET, akActor, asReason)
	EndIf

	sysCtrl.MarkDialogueNegotiating(akActor, asReason)
EndFunction

Function SyncSystemPreCombatPayBranch(Actor akActor, String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If !sysCtrl.HasActiveDialogueRoute() || sysCtrl.GetCurrentRouteFlow() != sysCtrl.FLOW_PRECOMBAT
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.BeginDialogueRoute(sysCtrl.FLOW_PRECOMBAT, sysCtrl.ENTRY_FORCEGREET, akActor, asReason)
	EndIf

	sysCtrl.MarkDialogueNegotiating(akActor, asReason)
	sysCtrl.SetDialogueMethod(sysCtrl.METHOD_PAY, akActor, asReason)
	sysCtrl.SetDialogueBranch(sysCtrl.BRANCH_PAY, akActor, asReason)
EndFunction

Function ClearSystemPreCombatMirror(String asReason = "")
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl == None
		Return
	EndIf

	If sysCtrl.HasActiveDialogueRoute() && sysCtrl.GetCurrentRouteFlow() == sysCtrl.FLOW_PRECOMBAT
		sysCtrl.FinalizeTerminalDialogueRoute(asReason)
	ElseIf !sysCtrl.HasActiveDialogueRoute() && sysCtrl.GetCurrentRouteFlow() == sysCtrl.FLOW_NONE
		sysCtrl.ResetRouteRecorderState(False)
		sysCtrl.ClearActiveFlow()
	EndIf
EndFunction

Function ClearTransientDialogueBridges()
	TFDSystemEventQuestScript sysCtrl = GetSystemController()
	If sysCtrl != None
		sysCtrl.ClearTransientDialogueBridges()
	Else
		SendModEvent("TFDTruceClearAll")
		SendModEvent("TFDBleedoutClearAll")
		SendModEvent("TFDPreCombatClearAll")
		SendModEvent("TFDInCombatClearAll")
	EndIf
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return "0"
	EndIf
	Return akActor.GetFormID() as String
EndFunction

Function ClearTransientEnemyStateFromPlayer()
	; Best effort cleanup for temporary dialogue/combat bridge state.
	ClearTransientDialogueBridges()
EndFunction

Function SignalTerminalPending(Actor akSpeaker, String asReason = "terminal_pending")
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	Debug.Trace("[TFD][PreCombatSession] SignalTerminalPending event=" + TerminalPendingEventName + " reason=" + asReason + " actor=" + DescribeActor(akSpeaker))
	SendModEvent(TerminalPendingEventName, ActorFormIDString(akSpeaker))
EndFunction

Function SignalRecruitPending(Actor akSpeaker, String asReason = "recruit_pending")
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	Debug.Trace("[TFD][PreCombatSession] SignalRecruitPending event=" + RecruitPendingEventName + " reason=" + asReason + " actor=" + DescribeActor(akSpeaker))
	SendModEvent(RecruitPendingEventName, ActorFormIDString(akSpeaker))
EndFunction

Function ForceTemporaryOutcomeCleanup()
	ClearBridge()
	ClearTransientDialogueBridges()
EndFunction

Actor Function ResolveCurrentSpeaker()
	Actor akSpeaker = GetSpeaker()
	If akSpeaker != None
		Return akSpeaker
	EndIf

	If PleasureLockActive && PleasureLockActor != None && !PleasureLockActor.IsDead()
		Return PleasureLockActor
	EndIf

	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()
	If pleasureCtrl != None
		akSpeaker = pleasureCtrl.ResolveCurrentSpeaker()
		If akSpeaker != None && !akSpeaker.IsDead()
			Return akSpeaker
		EndIf
	EndIf

	Return None
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
	Debug.Trace("[TFD][PreCombatSession] BeginPleasureLock actor=" + DescribeActor(akActor) + " native_owned=true no_truce_assign=true")

	If akActor.Is3DLoaded()
		akActor.StopCombat()
		akActor.StopCombatAlarm()
		akActor.EvaluatePackage()
	EndIf
EndFunction

Function ReleasePleasureLock(Bool abClearBridge = True)
	TFDTruceBridge truceCtrl = GetTruceBridge()
	Actor akLocked = PleasureLockActor

	PleasureLockActive = False
	PleasureLockActor = None

	If abClearBridge && truceCtrl != None && akLocked != None
		truceCtrl.ClearActor(akLocked)
	EndIf
EndFunction

Function ReleaseTruceOwnershipForActor(Actor akActor)
	TFDTruceBridge truceCtrl = GetTruceBridge()
	Actor akLocked = PleasureLockActor

	PleasureLockActive = False
	PleasureLockActor = None

	If truceCtrl != None
		If akActor != None
			truceCtrl.ClearActor(akActor)
		EndIf

		If akLocked != None && akLocked != akActor
			truceCtrl.ClearActor(akLocked)
		EndIf
	EndIf
EndFunction

Function StartSafePassForActor(Actor akActor, Int aiResult)
	StartSafePassForActorWithDuration(akActor, aiResult, SafePassDuration)
EndFunction

Function StartSafePassForActorWithDuration(Actor akActor, Int aiResult, Float afDuration)
	Actor akSpeaker = akActor
	Float useDuration = afDuration

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = ResolveCurrentSpeaker()
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	SetResolvedState(aiResult)
	ForceTemporaryOutcomeCleanup()

	If akSpeaker == None || akSpeaker.IsDead()
		SafePassResult = 0
		ReleasePleasureLock(True)
		Return
	EndIf

	ReleaseTruceOwnershipForActor(akSpeaker)

	If useDuration <= 0.0
		useDuration = SafePassDuration
	EndIf

	SafePassActor = akSpeaker
	SafePassExpireAt = Utility.GetCurrentRealTime() + useDuration
	SafePassActive = True
	SafePassResult = aiResult

	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
	ClearTransientDialogueBridges()

	QueueUpdate()
EndFunction


Function CancelPleasureFlowForActor(Actor akActor, Bool abStartCombat = True)
	Actor playerRef = Game.GetPlayer()

	If akActor == None
		akActor = PleasureLockActor
	EndIf

	; Runtime cleanup is owned by TFDSystemEventQuest / native pleasure runtime.
	; PreCombat only releases its own temporary lock and bridge ownership.
	ClearBridge()
	ReleasePleasureLock(True)

	If abStartCombat && akActor != None && playerRef != None && !akActor.IsDead()
		akActor.StopCombatAlarm()
		akActor.StartCombat(playerRef)
		akActor.EvaluatePackage()
	EndIf
EndFunction

Function NotifyPleasureLockBrokenByPlayer(Actor akActor)
	If !IsPleasureLockActor(akActor)
		Return
	EndIf

	CancelPleasureFlowForActor(akActor, True)
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

Bool Function ResolvePay()
	Return ResolvePayForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolvePayForActor(Actor akActor)
	Actor playerRef = Game.GetPlayer()
	Actor akSpeaker = akActor
	Debug.Trace("[TFD][DiagRecruit] PreCombat ResolvePayForActor entry actor=" + DescribeActor(akActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker) + " committed=" + SessionOutcomeCommitted)
	Debug.Trace("[TFD][PreCombatRouter] ResolvePayForActor entry actor=" + DescribeActor(akActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))

	If playerRef == None || Gold001 == None
		Return False
	EndIf

	If !IsRootSessionValidForActor(akSpeaker)
		Debug.Notification("TFD: PreCombat session is not valid for payment.")
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Notification("TFD: No valid target to receive payment.")
		Return False
	EndIf

	Int payAmount = GetPayAmount()
	If payAmount <= 0
		Debug.Notification("TFD: You have no gold to pay.")
		Return False
	EndIf

	If !EnterPayBranchForActor(akSpeaker, "resolve_pay")
		Debug.Trace("[TFD][DiagRecruit] PreCombat ResolvePayForActor failed to enter pay branch actor=" + DescribeActor(akSpeaker) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))
		Debug.Notification("TFD: PreCombat failed to enter pay branch.")
		Return False
	EndIf

	playerRef.RemoveItem(Gold001, payAmount, True, akSpeaker)
	; Route authority lives in TFDSystemEventQuestScript. PreCombat owner only mirrors result/speaker.
	SetResolvedState(RESULT_PAY)
	Debug.Trace("[TFD][DiagRecruit] PreCombat ResolvePayForActor SENDMODEVENT actor=" + DescribeActor(akSpeaker) + " payAmount=" + payAmount + " method=" + SessionMethod + " branch=" + SessionBranch)
	SendModEvent("TFDPreCombatOutcomePay", ActorFormIDString(akSpeaker), payAmount as Float)
	Return True
EndFunction

Function ResolveFight()
	TryResolveFightForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolveFightForActor(Actor akActor)
	TryResolveFightForActor(akActor)
EndFunction

Bool Function TryResolveFightForActor(Actor akActor)
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

	If !CommitSessionOutcome(RESULT_FIGHT, akSpeaker, "resolve_fight")
		Return False
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ReleasePleasureLock(True)
	ClearSession(False, False, "resolve_fight")
	SendModEvent("TFDPreCombatOutcomeFight", ActorFormIDString(akSpeaker))
	ClearBridge()

	If akSpeaker && !akSpeaker.IsDead()
		akSpeaker.StopCombatAlarm()
		akSpeaker.StartCombat(Game.GetPlayer())
		akSpeaker.EvaluatePackage()
	EndIf

	Return True
EndFunction

Function ResolveKidnap()
	TryResolveKidnapForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolveKidnapForActor(Actor akActor)
	TryResolveKidnapForActor(akActor)
EndFunction

Bool Function TryResolveKidnapForActor(Actor akActor)
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

	SetSpeaker(akSpeaker)
	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ReleasePleasureLock(True)
	ClearSession(False, False, "resolve_kidnap")
	SendModEvent("TFDPreCombatOutcomeCaptive", ActorFormIDString(akSpeaker))
	ClearBridge()

	If akSpeaker && !akSpeaker.IsDead()
		akSpeaker.StopCombat()
		akSpeaker.StopCombatAlarm()
		akSpeaker.EvaluatePackage()
	EndIf

	Return True
EndFunction

Function ResolvePleasure()
	TryResolvePleasureForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolvePleasureForActor(Actor akActor)
	TryResolvePleasureForActor(akActor)
EndFunction

Bool Function TryResolvePleasureForActor(Actor akActor)
	Actor akSpeaker = akActor
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()

	If !IsRootSessionValidForActor(akSpeaker)
		Debug.Notification("TFD: PreCombat session is not valid for pleasure.")
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Notification("TFD: No valid actor for pleasure.")
		Return False
	EndIf

	If pleasureCtrl == None
		Debug.Notification("TFD: PleasureQuest property is empty or cast failed.")
		Return False
	EndIf

	If !CommitSessionOutcome(RESULT_PLEASURE, akSpeaker, "resolve_pleasure")
		Return False
	EndIf

	BeginPleasureLock(akSpeaker)

	; Native owns truce/pacify factions. Notify native BEFORE starting OStim
	; and do not clear this PreCombat session here. The speaker must remain
	; under the same precombat suppression through the OStim handoff so the
	; transition stays passive -> passive instead of passive -> hostile -> passive.
	If akSpeaker != None
		akSpeaker.SendModEvent("TFDPreCombatOutcomePleasure", ActorFormIDString(akSpeaker), 0.0)
	Else
		SendModEvent("TFDPreCombatOutcomePleasure")
	EndIf

	Bool pleasureStartOk = pleasureCtrl.BeginPleasureAutoStart(akSpeaker, 1, 0, "precombat")
	Debug.Trace("[TFD][PreCombatSession] ResolvePleasure autoStart=" + pleasureStartOk + " actor=" + DescribeActor(akSpeaker) + " preserve_session=true")

	If !pleasureStartOk
		Debug.Notification("TFD: Pleasure failed to start.")
		pleasureCtrl.AbortPleasureToNeutral("precombat_start_failed", False, True)
		ReleasePleasureLock(True)
		AbortSession("resolve_pleasure_start_failed", akSpeaker, False, True)
		ClearBridge()
		Return False
	EndIf

	Return True
EndFunction

Function ResolveDoNothing()
	TryResolveDoNothingForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolveDoNothingForActor(Actor akActor)
	TryResolveDoNothingForActor(akActor)
EndFunction

Bool Function TryResolveDoNothingForActor(Actor akActor)
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
	StartSafePassForActor(akSpeaker, RESULT_DONOTHING)
	Return True
EndFunction

Function ResolveRelease()
	ResolveReleaseForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveReleaseForActor(Actor akActor)
	Actor akSpeaker = akActor
	Float useDuration = ReleaseDuration
	Debug.Trace("[TFD][PreCombatRouter] ResolveReleaseForActor entry actor=" + DescribeActor(akActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))

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

	SignalTerminalPending(akSpeaker, "resolve_release")

	If useDuration <= 0.0
		useDuration = SafePassDuration
	EndIf

	ClearSession(False, False, "resolve_release")
	StartSafePassForActorWithDuration(akSpeaker, RESULT_RELEASE, useDuration)
	SendModEvent("TFDPreCombatOutcomeRelease", ActorFormIDString(akSpeaker), useDuration)
	Return True
EndFunction

Function StartSafePass(Int aiResult)
	StartSafePassForActor(None, aiResult)
EndFunction

Function UpdateSafePass()
	Actor playerRef = Game.GetPlayer()

	If !SafePassActive
		Return
	EndIf

	If !playerRef
		EndSafePass(False)
		Return
	EndIf

	If !SafePassActor || SafePassActor.IsDead()
		EndSafePass(False)
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= SafePassExpireAt
		EndSafePass(True)
		Return
	EndIf

	If SafePassResult != RESULT_RELEASE
		If SafePassActor.GetDistance(playerRef) <= SafePassBreakDistance
			EndSafePass(True)
			Return
		EndIf
	EndIf
EndFunction

Function EndSafePass(Bool abRestoreHostility)
	Actor playerRef = Game.GetPlayer()
	Actor previousActor = SafePassActor
	Int previousResult = SafePassResult
	Bool hadSafePass = SafePassActive || previousActor != None || previousResult != 0

	If previousResult == RESULT_RELEASE
		SendModEvent("TFDPreCombatOutcomeReleaseEnd", ActorFormIDString(previousActor), abRestoreHostility as Float)
	EndIf

	If previousActor && abRestoreHostility && playerRef && !previousActor.IsDead()
		previousActor.StartCombat(playerRef)
		previousActor.EvaluatePackage()
	EndIf

	SafePassActor = None
	SafePassExpireAt = 0.0
	SafePassActive = False
	SafePassResult = 0

	If hadSafePass
		ClearTransientEnemyStateFromPlayer()
	EndIf
EndFunction

Function ResolveRecruit()
	ResolveRecruitForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveRecruitForActor(Actor akSpeaker)
	Int participantCount = 0
	Int quarantinedCount = 0
	Int promotedCount = 0
	Int previousMethod = 0
	Int previousBranch = 0
	Debug.Trace("[TFD][PreCombatSession] RecruitFinalizeSafeBaseline active version=no_recruit_pacify_v2 actor=" + DescribeActor(akSpeaker))
	Debug.Trace("[TFD][DiagRecruit] PreCombat ResolveRecruitForActor entry actor=" + DescribeActor(akSpeaker) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker) + " committed=" + SessionOutcomeCommitted)
	Debug.Trace("[TFD][PreCombatRouter] ResolveRecruitForActor entry actor=" + DescribeActor(akSpeaker) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))

	If !IsPayBranchSessionValidForActor(akSpeaker)
		TraceSession("RejectRecruitNoPayGate", akSpeaker, "not_pay_branch_session")
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	; Recruit is a terminal followup choice. Arm the native anti-reopen barriers
	; before releasing aliases, stabilizing participants, quarantine, or any other
	; Papyrus-heavy promotion work. In crowded sessions, the old CK forcegreet
	; package can refire on the same speaker during that window.
	SignalRecruitPending(akSpeaker, "resolve_recruit_early")
	SignalTerminalPending(akSpeaker, "resolve_recruit_early")

	; The forcegreet alias/package must be released before registry work or
	; Papyrus-heavy promotion path. Otherwise the CK package can refire in the
	; short window after the player chooses Recruit but before the actor has
	; become a teammate.
	ReleaseSpeakerForceGreetPackage(akSpeaker, "resolve_recruit_early_alias_release")
	StabilizeRecruitPendingParticipants(akSpeaker, "resolve_recruit_early_stabilize")

	Int totalParticipantCount = CountRecruitParticipants(akSpeaker)
	participantCount = CountAllowedRecruitParticipants(akSpeaker)
	If participantCount <= 0
		Debug.Trace("[TFD][PreCombatSession] ResolveRecruitForActor reject no recruit capacity actor=" + DescribeActor(akSpeaker) + " totalParticipants=" + totalParticipantCount + " slotsFree=" + CountAvailableRecruitSlots())
		Debug.Notification("TFD: Recruit failed.")
		AbortSession("resolve_recruit_no_capacity", akSpeaker, False, True)
		ClearBridge()
		ClearTransientDialogueBridges()
		Return False
	EndIf

	Debug.Trace("[TFD][PreCombatSession] ResolveRecruitForActor capacity actor=" + DescribeActor(akSpeaker) + " totalParticipants=" + totalParticipantCount + " allowedParticipants=" + participantCount + " slotsFree=" + CountAvailableRecruitSlots())

	If !CanPromoteTruceParticipantsAsRecruitLikeOutcome(akSpeaker)
		Debug.Trace("[TFD][PreCombatSession] ResolveRecruitForActor reject recruit group preflight actor=" + DescribeActor(akSpeaker) + " participantCount=" + participantCount)
		Debug.Notification("TFD: Recruit failed.")
		AbortSession("resolve_recruit_group_preflight_failed", akSpeaker, False, True)
		ClearBridge()
		ClearTransientDialogueBridges()
		Return False
	EndIf

	quarantinedCount = BeginRecruitQuarantineParticipants(akSpeaker, "resolve_recruit_quarantine", participantCount)
	If quarantinedCount < participantCount
		Debug.Trace("[TFD][DiagRecruit] PreCombat ResolveRecruitForActor abort incomplete quarantine actor=" + DescribeActor(akSpeaker) + " quarantinedCount=" + quarantinedCount + " participantCount=" + participantCount + " method=" + SessionMethod + " branch=" + SessionBranch)
		Debug.Notification("TFD: Recruit failed.")
		RollbackTruceParticipantsRecruit(akSpeaker)
		AbortSession("resolve_recruit_quarantine_failed", akSpeaker, False, True)
		ClearBridge()
		ClearTransientDialogueBridges()
		Return False
	EndIf

	If !CommitSessionOutcome(RESULT_RECRUIT, akSpeaker, "resolve_recruit")
		RollbackTruceParticipantsRecruit(akSpeaker)
		Return False
	EndIf

	; Recruit/terminal pending was already signalled before the slow promotion
	; path. Do not send it again here; duplicate pending events can refresh the
	; native dialogue cooldown while the followup menu is still settling.
	promotedCount = FinalizeQuarantinedRecruitParticipants(akSpeaker, participantCount)
	If promotedCount > 0
		ManagedRecruitActor = akSpeaker
	EndIf
	Debug.Trace("[TFD][PreCombatSession] ResolveRecruitForActor group promote promotedCount=" + promotedCount + " participantCount=" + participantCount + " quarantinedCount=" + quarantinedCount + " actor=" + DescribeActor(akSpeaker))

	If promotedCount < participantCount
		Debug.Trace("[TFD][DiagRecruit] PreCombat ResolveRecruitForActor abort incomplete group promote actor=" + DescribeActor(akSpeaker) + " promotedCount=" + promotedCount + " participantCount=" + participantCount + " method=" + SessionMethod + " branch=" + SessionBranch)
		Debug.Notification("TFD: Recruit failed.")
		RollbackTruceParticipantsRecruit(akSpeaker)
		AbortSession("resolve_recruit_group_promote_failed", akSpeaker, False, True)
		ClearBridge()
		ClearTransientDialogueBridges()
		Return False
	EndIf

	previousMethod = SessionMethod
	previousBranch = SessionBranch
	ClearSession(True, False, "resolve_recruit")
	Debug.Trace("[TFD][DiagRecruit] PreCombat ResolveRecruitForActor SENDMODEVENT actor=" + DescribeActor(akSpeaker) + " promotedCount=" + promotedCount + " participantCount=" + participantCount + " method=" + previousMethod + " branch=" + previousBranch)
	SendModEvent("TFDPreCombatOutcomeRecruit", ActorFormIDString(akSpeaker))
	ClearBridge()
	ClearTransientDialogueBridges()
	Return True
EndFunction


Bool Function BeginTemporaryFollowExternal(Actor akSpeaker, Float afDuration = 0.0)
	Float useDuration = afDuration
	Debug.Trace("TFDPreCombatQuestScript: BeginTemporaryFollowExternal entry actor=" + akSpeaker + " duration=" + afDuration)

	If useDuration <= 0.0
		useDuration = FollowDuration
	EndIf
	If useDuration <= 0.0
		useDuration = 60.0
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = ResolveCurrentSpeaker()
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Trace("TFDPreCombatQuestScript: BeginTemporaryFollowExternal abort speaker invalid")
		Return False
	EndIf

	SetSpeaker(akSpeaker)
	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ClearBridge()

	If TemporaryFollowerQuest == None
		Debug.Trace("TFDPreCombatQuestScript: BeginTemporaryFollowExternal abort TemporaryFollowerQuest NONE")
		Return False
	EndIf

	Utility.WaitMenuMode(0.20)
	Bool started = TemporaryFollowerQuest.BeginFollow(akSpeaker, useDuration)
	Debug.Trace("TFDPreCombatQuestScript: BeginTemporaryFollowExternal begin result=" + started + " speaker=" + akSpeaker)
	If !started
		Return False
	EndIf

	ManagedFollowActor = akSpeaker
	FollowExpireAt = Utility.GetCurrentRealTime() + useDuration
	FollowActive = False
	Return True
EndFunction

Function ResolveFollow()
	ResolveFollowForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveFollowForActor(Actor akActor)
	Actor akSpeaker = akActor
	Float useDuration = FollowDuration
	Debug.Trace("[TFD][PreCombatRouter] ResolveFollowForActor entry actor=" + DescribeActor(akActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))
	Debug.Trace("TFDPreCombatQuestScript: ResolveFollowForActor entry actor=" + akActor + " currentSpeaker=" + ResolveCurrentSpeaker())

	If !IsPayBranchSessionValidForActor(akSpeaker)
		Return False
	EndIf

	If useDuration <= 0.0
		useDuration = 60.0
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SessionSpeaker
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Trace("TFDPreCombatQuestScript: ResolveFollowForActor abort speaker invalid")
		Return False
	EndIf

	If TemporaryFollowerQuest == None
		Debug.Trace("TFDPreCombatQuestScript: ResolveFollowForActor abort TemporaryFollowerQuest NONE")
		Return False
	EndIf

	SetSpeaker(akSpeaker)

	Utility.WaitMenuMode(0.20)
	Bool started = TemporaryFollowerQuest.BeginFollow(akSpeaker, useDuration)
	Debug.Trace("TFDPreCombatQuestScript: ResolveFollowForActor begin result=" + started + " speaker=" + akSpeaker)
	If !started
		Debug.Trace("TFDPreCombatQuestScript: ResolveFollowForActor abort no outcome event because BeginFollow failed speaker=" + akSpeaker)
		Debug.Notification("TFD: Temporary follow failed.")
		Return False
	EndIf

	If !CommitSessionOutcome(RESULT_FOLLOW, akSpeaker, "resolve_follow")
		TemporaryFollowerQuest.EndFollow(False)
		Return False
	EndIf

	SignalTerminalPending(akSpeaker, "resolve_follow")
	EndSafePass(False)
	EndJoinEnemy(False)
	ClearSession(False, False, "resolve_follow")
	SendModEvent("TFDPreCombatOutcomeFollow", ActorFormIDString(akSpeaker), useDuration)
	ClearBridge()

	ManagedFollowActor = akSpeaker
	FollowExpireAt = Utility.GetCurrentRealTime() + useDuration
	FollowActive = False
	Return True
EndFunction

Function UpdateTemporaryFollow()
	; Temporary follow runtime is now owned by TFDTemporaryFollowerQuest.
	Return
EndFunction

Function EndTemporaryFollow(Bool abRestoreHostility)
	Actor previousActor = ManagedFollowActor
	Bool hadTemporaryFollow = FollowActive || previousActor != None

	If TemporaryFollowerQuest != None
		TemporaryFollowerQuest.EndFollow(abRestoreHostility)
	ElseIf previousActor != None
		If Registry != None
			Registry.UnregisterTeammate(previousActor)
		EndIf
		previousActor.SetPlayerTeammate(False, False)
		previousActor.EvaluatePackage()
	EndIf

	ManagedFollowActor = None
	FollowExpireAt = 0.0
	FollowActive = False

	If hadTemporaryFollow
		ClearTransientEnemyStateFromPlayer()
	EndIf
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

Bool Function IsValidRecruitParticipant(Actor akActor)
	If akActor == None
		Return False
	EndIf

	If akActor.IsDead()
		Return False
	EndIf

	Return True
EndFunction

Bool Function IsRecruitParticipantAlreadyListed(Actor akSpeaker, Actor akCandidate, Int aiUpToSlot)
	If akCandidate == None
		Return True
	EndIf

	If akSpeaker != None && akCandidate == akSpeaker
		Return True
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl == None
		Return False
	EndIf

	Int i = 1
	While i < aiUpToSlot
		Actor existingActor = truceCtrl.GetActorBySlotIndex(i)
		If existingActor != None && existingActor == akCandidate
			Return True
		EndIf
		i += 1
	EndWhile

	Return False
EndFunction

Function StabilizeRecruitPendingActor(Actor akActor, String asReason = "")
	If akActor == None || akActor.IsDead()
		Return
	EndIf

	akActor.StopCombat()
	akActor.StopCombatAlarm()
	akActor.EvaluatePackage()
	Debug.Trace("[TFD][PreCombatSession] StabilizeRecruitPendingActor actor=" + DescribeActor(akActor) + " reason=" + asReason)
EndFunction

Function StabilizeRecruitPendingParticipants(Actor akSpeaker, String asReason = "")
	If IsValidRecruitParticipant(akSpeaker)
		StabilizeRecruitPendingActor(akSpeaker, asReason)
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				StabilizeRecruitPendingActor(crowdActor, asReason)
			EndIf
			i += 1
		EndWhile
	EndIf
EndFunction

Function ApplyRecruitQuarantineState(Actor akActor, Actor akPlayer, String asReason = "")
	If akActor == None || akPlayer == None || akActor.IsDead()
		Return
	EndIf

	akActor.SetRelationshipRank(akPlayer, 3)
	akPlayer.SetRelationshipRank(akActor, 3)
	akActor.SetPlayerTeammate(True, False)
	akActor.StopCombat()
	akActor.StopCombatAlarm()
	akActor.EvaluatePackage()
	Debug.Trace("[TFD][PreCombatSession] RecruitQuarantineActor actor=" + DescribeActor(akActor) + " reason=" + asReason)
EndFunction

Int Function BeginRecruitQuarantineParticipants(Actor akSpeaker, String asReason = "", Int aiLimit = -1)
	Actor playerRef = Game.GetPlayer()
	Int count = 0
	Int limit = aiLimit

	If limit < 0
		limit = CountAllowedRecruitParticipants(akSpeaker)
	EndIf

	If playerRef == None || limit <= 0
		Return 0
	EndIf

	If IsValidRecruitParticipant(akSpeaker) && count < limit
		ApplyRecruitQuarantineState(akSpeaker, playerRef, asReason)
		count += 1
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10 && count < limit
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				ApplyRecruitQuarantineState(crowdActor, playerRef, asReason)
				count += 1
			EndIf
			i += 1
		EndWhile
	EndIf

	Debug.Trace("[TFD][PreCombatSession] RecruitQuarantineParticipants count=" + count + " limit=" + limit + " actor=" + DescribeActor(akSpeaker) + " reason=" + asReason)
	Return count
EndFunction

Bool Function FinalizeQuarantinedRecruitActor(Actor akSpeaker, Bool abClearTransientBridges = True)
	Actor playerRef = Game.GetPlayer()
	Bool registered = True

	If playerRef == None
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	ManagedRecruitActor = akSpeaker
	NormalizeRecruitSpeakerState(akSpeaker, playerRef)
	ReleasePleasureLock(True)
	If abClearTransientBridges
		ClearTransientDialogueBridges()
	EndIf

	; R25: do not register precombat recruits into TFDPlayerTeammateAlias before native CommitRecruit.
	; Crowd participants can be SetPlayerTeammate(True) here while TFDTeammateFaction is still absent.
	; If they enter the alias at that timing, CK can keep their old/truce/default package stack
	; and the later same-alias refresh is not always enough to attach TFDTeammatePackage.
	; Native CommitRecruit is the faction owner and will queue TFDHumanoidTeammateAssign after
	; TFDTeammateFaction / TFDPacifyFaction are already installed.
	If Registry != None
		Debug.Trace("[TFD][PreCombatSession] FinalizeQuarantinedRecruitActor registry=deferred_to_native_commit actor=" + DescribeActor(akSpeaker))
	EndIf

	Debug.Trace("[TFD][PreCombatSession] FinalizeQuarantinedRecruitActor actor=" + DescribeActor(akSpeaker))
	Return True
EndFunction

Int Function FinalizeQuarantinedRecruitParticipants(Actor akSpeaker, Int aiLimit = -1)
	Int promotedCount = 0
	Int limit = aiLimit

	If limit < 0
		limit = CountAllowedRecruitParticipants(akSpeaker)
	EndIf

	If limit <= 0
		Return 0
	EndIf

	If IsValidRecruitParticipant(akSpeaker) && promotedCount < limit
		If FinalizeQuarantinedRecruitActor(akSpeaker, False)
			promotedCount += 1
		EndIf
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10 && promotedCount < limit
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				If FinalizeQuarantinedRecruitActor(crowdActor, False)
					promotedCount += 1
				Else
					Debug.Trace("[TFD][PreCombatSession] FinalizeQuarantinedRecruitParticipants failed crowd actor=" + DescribeActor(crowdActor) + " speaker=" + DescribeActor(akSpeaker))
				EndIf
			EndIf
			i += 1
		EndWhile
	EndIf

	Debug.Trace("[TFD][PreCombatSession] FinalizeQuarantinedRecruitParticipants promoted=" + promotedCount + " limit=" + limit + " speaker=" + DescribeActor(akSpeaker))
	Return promotedCount
EndFunction

Int Function CountRecruitParticipants(Actor akSpeaker)
	Int count = 0

	If IsValidRecruitParticipant(akSpeaker)
		count += 1
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				count += 1
			EndIf
			i += 1
		EndWhile
	EndIf

	Return count
EndFunction

Int Function CountRegistryEmptyRecruitSlots()
	If Registry == None
		Return 0
	EndIf

	Int count = 0
	Int i = 0
	Int maxSlots = Registry.GetMaxSlots()
	While i < maxSlots
		If Registry.GetTeammateBySlot(i) == None
			count += 1
		EndIf
		i += 1
	EndWhile

	Return count
EndFunction

Int Function CountAvailableRecruitSlots()
	If TFDRecruitSlotsFree != None
		Int mirroredSlots = TFDRecruitSlotsFree.GetValueInt()
		If mirroredSlots < 0
			Return 0
		EndIf
		Return mirroredSlots
	EndIf

	Return CountRegistryEmptyRecruitSlots()
EndFunction

Int Function CountAllowedRecruitParticipants(Actor akSpeaker)
	Int participantCount = CountRecruitParticipants(akSpeaker)
	Int slotsFree = CountAvailableRecruitSlots()

	If participantCount <= 0 || slotsFree <= 0
		Return 0
	EndIf

	If participantCount > slotsFree
		Return slotsFree
	EndIf

	Return participantCount
EndFunction

Bool Function CanPromoteTruceParticipantsAsRecruitLikeOutcome(Actor akSpeaker)
	Int totalParticipantCount = CountRecruitParticipants(akSpeaker)
	Int allowedParticipantCount = CountAllowedRecruitParticipants(akSpeaker)
	If totalParticipantCount <= 0
		Debug.Trace("[TFD][PreCombatSession] CanPromoteTruceParticipants reject no valid participants actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	If allowedParticipantCount <= 0
		Debug.Trace("[TFD][PreCombatSession] CanPromoteTruceParticipants reject no recruit slots totalParticipants=" + totalParticipantCount + " slotsFree=" + CountAvailableRecruitSlots() + " actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	If !CanPromoteActorAsRecruitLikeOutcome(akSpeaker)
		Return False
	EndIf

	Int checkedCount = 1
	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10 && checkedCount < allowedParticipantCount
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				If !CanPromoteActorAsRecruitLikeOutcome(crowdActor)
					Debug.Trace("[TFD][PreCombatSession] CanPromoteTruceParticipants reject crowd actor=" + DescribeActor(crowdActor) + " speaker=" + DescribeActor(akSpeaker))
					Return False
				EndIf
				checkedCount += 1
			EndIf
			i += 1
		EndWhile
	EndIf

	Debug.Trace("[TFD][PreCombatSession] CanPromoteTruceParticipants ok totalParticipants=" + totalParticipantCount + " allowedParticipants=" + allowedParticipantCount + " slotsFree=" + CountAvailableRecruitSlots() + " actor=" + DescribeActor(akSpeaker))
	Return True
EndFunction

Int Function PromoteTruceParticipantsAsRecruitLikeOutcome(Actor akSpeaker)
	Int promotedCount = 0

	If IsValidRecruitParticipant(akSpeaker)
		If PromoteActorAsRecruitLikeOutcome(akSpeaker, True, False)
			promotedCount += 1
		EndIf
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				If PromoteActorAsRecruitLikeOutcome(crowdActor, True, False)
					promotedCount += 1
				Else
					Debug.Trace("[TFD][PreCombatSession] PromoteTruceParticipants failed crowd actor=" + DescribeActor(crowdActor) + " speaker=" + DescribeActor(akSpeaker))
				EndIf
			EndIf
			i += 1
		EndWhile
	EndIf

	Return promotedCount
EndFunction

Function DemoteRecruitParticipantAfterFailedGroupPromote(Actor akActor)
	If akActor == None
		Return
	EndIf

	If Registry != None
		Registry.UnregisterTeammate(akActor)
	EndIf

	akActor.SetPlayerTeammate(False, False)
	akActor.EvaluatePackage()
EndFunction

Function RollbackTruceParticipantsRecruit(Actor akSpeaker)
	If IsValidRecruitParticipant(akSpeaker)
		DemoteRecruitParticipantAfterFailedGroupPromote(akSpeaker)
	EndIf

	TFDTruceBridge truceCtrl = GetTruceBridge()
	If truceCtrl != None
		Int i = 1
		While i <= 10
			Actor crowdActor = truceCtrl.GetActorBySlotIndex(i)
			If IsValidRecruitParticipant(crowdActor) && !IsRecruitParticipantAlreadyListed(akSpeaker, crowdActor, i)
				DemoteRecruitParticipantAfterFailedGroupPromote(crowdActor)
			EndIf
			i += 1
		EndWhile
	EndIf

	ManagedRecruitActor = None
EndFunction

Bool Function CanPromoteActorAsRecruitLikeOutcome(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()

	If playerRef == None
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	If Registry != None
		If Registry.IsLikelyTeammateActor(akSpeaker) || Registry.IsRegistered(akSpeaker)
			Debug.Trace("[TFD][PreCombatSession] CanPromoteActorAsRecruitLikeOutcome reject actor already teammate/registered actor=" + DescribeActor(akSpeaker))
			Return False
		EndIf

		If Registry.FindEmptySlotIndex() < 0
			Debug.Trace("[TFD][PreCombatSession] CanPromoteActorAsRecruitLikeOutcome reject no empty teammate slot actor=" + DescribeActor(akSpeaker))
			Return False
		EndIf
	ElseIf akSpeaker.IsPlayerTeammate()
		Debug.Trace("[TFD][PreCombatSession] CanPromoteActorAsRecruitLikeOutcome reject actor already teammate actor=" + DescribeActor(akSpeaker))
		Return False
	EndIf

	Return True
EndFunction

Bool Function PromoteActorAsRecruitLikeOutcome(Actor akSpeaker, Bool abAssignToTruceQuest = True, Bool abClearTransientBridges = True)
	Actor playerRef = Game.GetPlayer()
	Bool registered = True

	If playerRef == None
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	If !CanPromoteActorAsRecruitLikeOutcome(akSpeaker)
		Return False
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	ManagedRecruitActor = akSpeaker
	NormalizeRecruitSpeakerState(akSpeaker, playerRef)
	ReleasePleasureLock(True)
	If abClearTransientBridges
		ClearTransientDialogueBridges()
	EndIf

	If Registry != None
		registered = Registry.RegisterOrRefreshTeammate(akSpeaker)
		If !registered
			Debug.Trace("[TFD][PreCombatSession] PromoteActorAsRecruitLikeOutcome reject registry registration failed actor=" + DescribeActor(akSpeaker))
			akSpeaker.SetPlayerTeammate(False, False)
			akSpeaker.EvaluatePackage()
			ManagedRecruitActor = None
			Return False
		EndIf
	EndIf

	Return True
EndFunction

Bool Function BeginJoinEnemyExternal(Actor akSpeaker)
	Actor playerRef = Game.GetPlayer()

	If playerRef == None
		Return False
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return False
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ForceTemporaryOutcomeCleanup()

	JoinEnemyActive = True
	JoinEnemyLocation = playerRef.GetCurrentLocation()
	JoinEnemySourceActor = akSpeaker

	If JoinEnemySourceActor != None && !JoinEnemySourceActor.IsDead()
		JoinEnemySourceActor.StopCombat()
		JoinEnemySourceActor.StopCombatAlarm()
		JoinEnemySourceActor.EvaluatePackage()
	EndIf

	ReleasePleasureLock(True)
	ClearTransientDialogueBridges()
	QueueUpdate()
	Return True
EndFunction

Bool Function IsJoinEnemyOfferedByNative()
	If TFDJoinEnemyState == None
		Return False
	EndIf

	Return (TFDJoinEnemyState.GetValueInt() != 0)
EndFunction

Function ResolveJoinEnemy()
	ResolveJoinEnemyForActor(ResolveCurrentSpeaker())
EndFunction

Bool Function ResolveJoinEnemyForActor(Actor akActor)
	Actor akSpeaker = akActor
	Debug.Trace("[TFD][PreCombatRouter] ResolveJoinEnemyForActor entry actor=" + DescribeActor(akActor) + " sessionActive=" + SessionActive + " method=" + SessionMethod + " branch=" + SessionBranch + " speaker=" + DescribeActor(SessionSpeaker))

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

	ClearSession(False, False, "resolve_join_enemy")
	SendModEvent("TFDPreCombatOutcomeJoinEnemy", ActorFormIDString(akSpeaker))
	ClearBridge()
	Return BeginJoinEnemyExternal(akSpeaker)
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
		ClearTransientEnemyStateFromPlayer()
	EndIf
EndFunction