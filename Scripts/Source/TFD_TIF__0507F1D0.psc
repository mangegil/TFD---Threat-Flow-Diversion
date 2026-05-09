;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 5
Scriptname TFD_TIF__0507F1D0 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_4
Function Fragment_4(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
If sys != None
	sys.ResolveJoinEnemy(akSpeaker)
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDSystemEventQuest Auto
