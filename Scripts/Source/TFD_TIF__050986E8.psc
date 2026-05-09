;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 2
Scriptname TFD_TIF__050986E8 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;TEAMMATE TERMINATE CONTRACT
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
If sys != None
	sys.ResolveTeammateTerminateContract(akSpeaker)
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDSystemEventQuest Auto
