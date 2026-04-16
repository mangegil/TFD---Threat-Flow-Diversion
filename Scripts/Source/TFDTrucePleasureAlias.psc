Scriptname TFDTrucePleasureAlias extends ReferenceAlias

Quest Property TFDPreCombatQuest Auto

Actor Function GetAliasActor()
	ObjectReference akRef = GetReference()
	If akRef == None
		Return None
	EndIf

	Return akRef as Actor
EndFunction

TFDPreCombatQuestScript Function GetPreCombatController()
	If TFDPreCombatQuest == None
		Return None
	EndIf

	Return TFDPreCombatQuest as TFDPreCombatQuestScript
EndFunction

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, Bool abPowerAttack, Bool abSneakAttack, Bool abBashAttack, Bool abHitBlocked)
	Actor akSelf = GetAliasActor()
	Actor akPlayer = Game.GetPlayer()
	TFDPreCombatQuestScript preCtrl = GetPreCombatController()

	If akSelf == None
		Return
	EndIf

	If akPlayer == None
		Return
	EndIf

	If preCtrl == None
		Return
	EndIf

	If akAggressor != akPlayer
		Return
	EndIf

	If !preCtrl.IsPleasureLockActor(akSelf)
		Return
	EndIf

	preCtrl.NotifyPleasureLockBrokenByPlayer(akSelf)
EndEvent