;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname TFD_TIF__05047654 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
;INCOMBAT CAPTIVE
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
If sys != None
	sys.ResolveKidnap(akSpeaker)
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDSystemEventQuest Auto
