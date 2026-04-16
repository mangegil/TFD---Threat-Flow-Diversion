;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 4
Scriptname TFD_TIF__05047638 Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_3
Function Fragment_3(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
TFDSystemEventQuestScript sys = (TFDSystemEventQuest as TFDSystemEventQuestScript)
If sys != None
	Bool ok = sys.ResolveFollowPlayer(akSpeaker)
	Debug.Trace("[TFD][FollowTrace] TIF 05047638 ResolveFollowPlayer returned=" + ok + " speaker=" + akSpeaker)
Else
	Debug.Trace("[TFD][FollowTrace] TIF 05047638 sys is NONE")
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property TFDSystemEventQuest  Auto  
