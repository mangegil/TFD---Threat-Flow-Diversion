Scriptname TFDPreCombatQuestScript extends Quest

ReferenceAlias Property Speaker Auto

GlobalVariable Property TFDJoinEnemyState Auto
GlobalVariable Property TFDPayGold Auto

TFDPlayerTeammateQuestScript Property Registry Auto

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

String Property KidnapEventName = "TFDPreCombatKidnap" Auto
String Property PleasureEventName = "TFDPreCombatPleasure" Auto

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

Function RegisterBridgeEvents()
	UnregisterForAllModEvents()
	RegisterForModEvent("TFDPreCombatAssign", "OnBridgeEvent")
	RegisterForModEvent("TFDPreCombatClear", "OnBridgeEvent")
	RegisterForModEvent("TFDPreCombatClearAll", "OnBridgeEvent")
EndFunction

Event OnInit()
	RegisterBridgeEvents()
	ClearSpeaker()
	QueueUpdate()
EndEvent

Event OnPlayerLoadGame()
	ClearSpeaker()
	PleasureLockActive = False
	PleasureLockActor = None
	ClearBridge()
	RegisterBridgeEvents()
	QueueUpdate()
EndEvent

Event OnBridgeEvent(String eventName, String strArg, Float numArg, Form sender)
	Actor aEvent = sender as Actor

	If eventName == "TFDPreCombatAssign"
		If aEvent != None && !aEvent.IsDead()
			SetSpeaker(aEvent)
			QueueUpdate()
		EndIf
		Return
	EndIf

	If eventName == "TFDPreCombatClear"
		If aEvent != None
			ClearSpeakerForActor(aEvent)
		Else
			ClearSpeaker()
		EndIf
		If ShouldKeepUpdating()
			QueueUpdate()
		EndIf
		Return
	EndIf

	If eventName == "TFDPreCombatClearAll"
		ClearSpeaker()
		If ShouldKeepUpdating()
			QueueUpdate()
		EndIf
		Return
	EndIf
EndEvent

Function QueueUpdate()
	UnregisterForUpdate()
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

Bool Function ShouldKeepUpdating()
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
		Return
	EndIf

	If IsActorStale(a)
		ClearSpeakerForActor(a)
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
	TFDTruceBridge truceCtrl = GetTruceBridge()

	If akActor == None
		Return
	EndIf

	PleasureLockActive = True
	PleasureLockActor = akActor

	If truceCtrl != None
		truceCtrl.AssignActor(akActor)
	EndIf

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
	Actor playerRef = Game.GetPlayer()
	Actor akSpeaker = ResolveCurrentSpeaker()

	If playerRef == None || Gold001 == None
		Return False
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

	playerRef.RemoveItem(Gold001, payAmount, True, akSpeaker)
	SetResolvedState(RESULT_PAY)
	SendModEvent("TFDPreCombatOutcomePay")
	Return True
EndFunction

Function ResolveFight()
	Actor akSpeaker = ResolveCurrentSpeaker()

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ReleasePleasureLock(True)

	SetResolvedState(RESULT_FIGHT)
	SendModEvent("TFDPreCombatOutcomeFight")
	ClearBridge()

	If akSpeaker && !akSpeaker.IsDead()
		akSpeaker.StopCombatAlarm()
		akSpeaker.StartCombat(Game.GetPlayer())
		akSpeaker.EvaluatePackage()
	EndIf
EndFunction

Function ResolveKidnap()
	ResolveKidnapForActor(None)
EndFunction

Function ResolveKidnapForActor(Actor akActor)
	Actor akSpeaker = akActor

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = ResolveCurrentSpeaker()
	EndIf

	If akSpeaker != None && !akSpeaker.IsDead()
		SetSpeaker(akSpeaker)
	EndIf

	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ReleasePleasureLock(True)

	SetResolvedState(RESULT_KIDNAP)
	SendModEvent("TFDPreCombatOutcomeCaptive", ActorFormIDString(akSpeaker))
	ClearBridge()

	If akSpeaker && !akSpeaker.IsDead()
		akSpeaker.StopCombat()
		akSpeaker.StopCombatAlarm()
		akSpeaker.EvaluatePackage()
	EndIf

	SendModEvent(KidnapEventName, ActorFormIDString(akSpeaker))
EndFunction

Function ResolvePleasure()
	Actor akSpeaker = ResolveCurrentSpeaker()
	TFDPleasureQuestScript pleasureCtrl = GetPleasureController()

	If akSpeaker == None || akSpeaker.IsDead()
		Debug.Notification("TFD: No valid actor for pleasure.")
		Return
	EndIf

	If pleasureCtrl == None
		Debug.Notification("TFD: PleasureQuest property is empty or cast failed.")
		Return
	EndIf

	BeginPleasureLock(akSpeaker)
	pleasureCtrl.BeginPleasure(akSpeaker, 1, 0)
EndFunction

Function ResolveDoNothing()
	StartSafePassForActor(None, RESULT_DONOTHING)
EndFunction

Function ResolveRelease()
	Actor akSpeaker = ResolveCurrentSpeaker()
	Float useDuration = ReleaseDuration
	If useDuration <= 0.0
		useDuration = SafePassDuration
	EndIf
	StartSafePassForActorWithDuration(akSpeaker, RESULT_RELEASE, useDuration)
	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = SafePassActor
	EndIf
	SendModEvent("TFDPreCombatOutcomeRelease", ActorFormIDString(akSpeaker), useDuration)
EndFunction

Function ResolveReleaseForActor(Actor akActor)
	Float useDuration = ReleaseDuration
	If useDuration <= 0.0
		useDuration = SafePassDuration
	EndIf
	StartSafePassForActorWithDuration(akActor, RESULT_RELEASE, useDuration)
	SendModEvent("TFDPreCombatOutcomeRelease", ActorFormIDString(akActor), useDuration)
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
	ClearTransientEnemyStateFromPlayer()
EndFunction

Function ResolveRecruit()
	ResolveRecruitForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolveRecruitForActor(Actor akSpeaker)
	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	SetSpeaker(akSpeaker)
	SetResolvedState(RESULT_RECRUIT)
	SendModEvent("TFDPreCombatOutcomeRecruit", ActorFormIDString(akSpeaker))
	ClearBridge()

	Utility.WaitMenuMode(0.20)
	PromoteActorAsRecruitLikeOutcome(akSpeaker, True)
EndFunction



Bool Function BeginTemporaryFollowExternal(Actor akSpeaker, Float afDuration = 0.0)
	Actor playerRef = Game.GetPlayer()
	Float useDuration = afDuration

	If playerRef == None
		Return False
	EndIf

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
		Return False
	EndIf

	SetSpeaker(akSpeaker)
	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)
	ClearBridge()

	Utility.WaitMenuMode(0.20)
	If !PromoteActorAsRecruitLikeOutcome(akSpeaker, True)
		Return False
	EndIf

	ManagedFollowActor = akSpeaker
	FollowExpireAt = Utility.GetCurrentRealTime() + useDuration
	FollowActive = True
	QueueUpdate()
	Return True
EndFunction

Function ResolveFollow()
	ResolveFollowForActor(ResolveCurrentSpeaker())
EndFunction

Function ResolveFollowForActor(Actor akActor)
	Actor akSpeaker = akActor
	Actor playerRef = Game.GetPlayer()
	Float useDuration = FollowDuration

	If playerRef == None
		Return
	EndIf

	If useDuration <= 0.0
		useDuration = 60.0
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		akSpeaker = ResolveCurrentSpeaker()
	EndIf

	If akSpeaker == None || akSpeaker.IsDead()
		Return
	EndIf

	SetSpeaker(akSpeaker)
	EndSafePass(False)
	EndTemporaryFollow(False)
	EndJoinEnemy(False)

	SetResolvedState(RESULT_FOLLOW)
	SendModEvent("TFDPreCombatOutcomeFollow", ActorFormIDString(akSpeaker), useDuration)
	ClearBridge()

	Utility.WaitMenuMode(0.20)
	If !PromoteActorAsRecruitLikeOutcome(akSpeaker, True)
		Return
	EndIf

	ManagedFollowActor = akSpeaker
	FollowExpireAt = Utility.GetCurrentRealTime() + useDuration
	FollowActive = True
	QueueUpdate()
EndFunction

Function UpdateTemporaryFollow()
	If !FollowActive
		Return
	EndIf

	Actor playerRef = Game.GetPlayer()
	If playerRef == None
		EndTemporaryFollow(False)
		Return
	EndIf

	If ManagedFollowActor == None || ManagedFollowActor.IsDead()
		EndTemporaryFollow(False)
		Return
	EndIf

	If playerRef.IsWeaponDrawn()
		EndTemporaryFollow(True)
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= FollowExpireAt
		EndTemporaryFollow(True)
		Return
	EndIf
EndFunction

Function EndTemporaryFollow(Bool abRestoreHostility)
	Actor playerRef = Game.GetPlayer()
	Actor previousActor = ManagedFollowActor

	If previousActor != None
		SendModEvent("TFDPreCombatOutcomeReleaseEnd", ActorFormIDString(previousActor), abRestoreHostility as Float)
		If Registry != None
			Registry.UnregisterTeammate(previousActor)
		EndIf
		previousActor.SetPlayerTeammate(False, False)
		previousActor.EvaluatePackage()

		If abRestoreHostility && playerRef && !previousActor.IsDead()
			previousActor.StartCombat(playerRef)
			previousActor.EvaluatePackage()
		EndIf
	EndIf

	ManagedFollowActor = None
	FollowExpireAt = 0.0
	FollowActive = False
	ClearTransientEnemyStateFromPlayer()
EndFunction


Bool Function PromoteActorAsRecruitLikeOutcome(Actor akSpeaker, Bool abAssignToTruceQuest = True)
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

	ManagedRecruitActor = akSpeaker
	akSpeaker.SetRelationshipRank(playerRef, 4)
	akSpeaker.SetPlayerTeammate(True, False)
	akSpeaker.StopCombat()
	akSpeaker.StopCombatAlarm()
	akSpeaker.EvaluatePackage()
	ReleasePleasureLock(True)
	ClearTransientDialogueBridges()

	If Registry != None
		Registry.RegisterOrRefreshTeammate(akSpeaker)
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
	Actor akSpeaker = ResolveCurrentSpeaker()

	If !IsJoinEnemyOfferedByNative()
		Debug.Notification("TFD: Join Enemy is not available here.")
		Return
	EndIf

	SetResolvedState(RESULT_JOINENEMY)
	SendModEvent("TFDPreCombatOutcomeJoinEnemy")
	ClearBridge()

	BeginJoinEnemyExternal(akSpeaker)
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