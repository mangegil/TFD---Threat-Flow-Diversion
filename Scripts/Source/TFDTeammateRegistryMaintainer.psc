Scriptname TFDTeammateRegistryMaintainer extends Quest

TFDPlayerTeammateQuestScript Property Registry Auto
Float Property RefreshInterval = 10.0 Auto

Bool _started = False

Event OnInit()
	_started = True
	RegisterForSingleUpdate(3.0)
EndEvent

Event OnPlayerLoadGame()
	If !_started
		_started = True
	EndIf
	RegisterForSingleUpdate(3.0)
EndEvent

Event OnUpdate()
	If Registry != None
		If !Registry.IsEventLocked()
			Registry.PruneInvalidTeammates()
		EndIf
	EndIf

	If _started
		RegisterForSingleUpdate(RefreshInterval)
	EndIf
EndEvent