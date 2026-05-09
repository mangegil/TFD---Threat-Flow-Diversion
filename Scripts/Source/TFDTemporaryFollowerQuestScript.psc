Scriptname TFDTemporaryFollowerQuestScript extends Quest

ReferenceAlias Property TemporaryFollower Auto
Float Property UpdateInterval = 0.50 Auto

Actor CurrentFollower
Bool WasAlreadyPlayerTeammate = False
Float FollowExpireAt = 0.0

Event OnInit()
	UnregisterForUpdate()
EndEvent

Event OnPlayerLoadGame()
	EndFollow(False)
EndEvent

Function QueueUpdate()
	UnregisterForUpdate()
	RegisterForSingleUpdate(UpdateInterval)
EndFunction

String Function ActorFormIDString(Actor akActor)
	If akActor == None
		Return ""
	EndIf
	Return akActor.GetFormID() as String
EndFunction

Actor Function GetFollowActor()
	If TemporaryFollower != None
		Return TemporaryFollower.GetReference() as Actor
	EndIf
	Return CurrentFollower
EndFunction

Bool Function BeginFollow(Actor akActor, Float afDuration = 60.0)
	Actor playerRef = Game.GetPlayer()
	Float useDuration = afDuration

	If playerRef == None
		Debug.Trace("TFDTemporaryFollowerQuestScript: BeginFollow abort playerRef NONE")
		Return False
	EndIf

	If TemporaryFollower == None
		Debug.Trace("TFDTemporaryFollowerQuestScript: BeginFollow abort TemporaryFollower alias NONE")
		Return False
	EndIf

	If useDuration <= 0.0
		useDuration = 60.0
	EndIf

	If akActor == None || akActor.IsDead()
		Debug.Trace("TFDTemporaryFollowerQuestScript: BeginFollow abort actor invalid")
		Return False
	EndIf

	Actor existingActor = GetFollowActor()
	If existingActor != None && existingActor != akActor
		EndFollow(False)
	EndIf

	CurrentFollower = akActor
	WasAlreadyPlayerTeammate = akActor.IsPlayerTeammate()
	FollowExpireAt = Utility.GetCurrentRealTime() + useDuration

	TemporaryFollower.ForceRefTo(akActor)
	Actor filledActor = GetFollowActor()
	If filledActor != akActor
		Debug.Trace("TFDTemporaryFollowerQuestScript: BeginFollow abort alias fill mismatch requested=" + akActor + " filled=" + filledActor)
		CurrentFollower = None
		WasAlreadyPlayerTeammate = False
		FollowExpireAt = 0.0
		Return False
	EndIf

	akActor.StopCombat()
	akActor.StopCombatAlarm()
	akActor.SetRelationshipRank(playerRef, 3)
	akActor.SetPlayerTeammate(True, False)
	akActor.EvaluatePackage()

	Debug.Trace("TFDTemporaryFollowerQuestScript: BeginFollow success actor=" + akActor + " expireAt=" + FollowExpireAt)
	QueueUpdate()
	Return True
EndFunction

Event OnUpdate()
	Actor playerRef = Game.GetPlayer()
	Actor followActor = GetFollowActor()

	If followActor == None
		EndFollow(False)
		Return
	EndIf

	If followActor.IsDead()
		EndFollow(False)
		Return
	EndIf

	If playerRef == None
		EndFollow(False)
		Return
	EndIf

	If playerRef.IsWeaponDrawn()
		EndFollow(True)
		Return
	EndIf

	If Utility.GetCurrentRealTime() >= FollowExpireAt
		EndFollow(True)
		Return
	EndIf

	RegisterForSingleUpdate(UpdateInterval)
EndEvent

Function EndFollow(Bool abRestoreHostility = False)
	Actor playerRef = Game.GetPlayer()
	Actor previousActor = GetFollowActor()

	UnregisterForUpdate()

	If previousActor != None
		SendModEvent("TFDPreCombatOutcomeReleaseEnd", ActorFormIDString(previousActor), abRestoreHostility as Float)

		If TemporaryFollower != None
			TemporaryFollower.Clear()
		EndIf

		If !WasAlreadyPlayerTeammate
			previousActor.SetPlayerTeammate(False, False)
		EndIf

		previousActor.EvaluatePackage()

		If abRestoreHostility && playerRef != None && !previousActor.IsDead()
			previousActor.StartCombat(playerRef)
			previousActor.EvaluatePackage()
		EndIf
	EndIf

	CurrentFollower = None
	WasAlreadyPlayerTeammate = False
	FollowExpireAt = 0.0
EndFunction