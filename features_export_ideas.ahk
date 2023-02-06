#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

UserInput() {
	InputBox, Features, Export features? Type 1, Boolean
	If (Features == 1) {
		Ext:= ".fcs"
	} Else {
		Ext:= ".txt"
	}

	InputBox, Postfix, Postfix to append to filename, String
	Reps := []
	Loop, parse, Postfix, `,
	{
		Rep := "_" . A_LoopField . Ext
		Reps.Push(Rep)
	}

	InputBox, PopLineInput, Line number of population in feature export data dialog, Number
	PopLines := StrSplit(PopLineInput, ",")

	Options := {PopLines: PopLines, Reps: Reps, Features: Features}
	return Options
}

Main(Out, PopLine, Features)
{
	Send, <!tee{Enter}{Space}
	
	; Selection of population
	WinActivate, Export Feature Data
	WinWaitActive, Export Feature Data

	if (PopLine = 0) {
		ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad110, Export Feature Data
		Sleep, 100
		ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad110, Export Feature Data
	}

	Loop % PopLine
	{
	Sleep, 500
	ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad110, Export Feature Data
	WinWaitNotActive, Export Feature Data
	Sleep, 100
	Send, {Down}
	Sleep, 100
	WinActivate, Export Feature Data
	WinWaitActive, Export Feature Data
	}
	; End

	Send, {Tab}{Down}

	If(Features == 1) {
		Send, {Down}{Tab}{Tab}{Tab}{Tab}{Tab}{Space}{Tab}{Tab}{Tab}{Tab}{Tab}
	}
	Send, {Tab}{Tab}{Enter}

	WinWaitNotActive, Export Feature Data
	Send, %Out%{Enter}
	WinWaitActive, Feature Export Status
	Send, {Enter}
	WinWaitActive, Export Feature Data
	Send, {Tab}{Tab}{Enter}
	
}

RAlt & O::
CoordMode, Mouse, Client
Options := UserInput()
FileSelectFolder, List
SetWorkingDir, %List%
WinActivate IDEAS
WinWaitActive IDEAS
Loop, Files, *.daf
{
	Out := StrReplace(A_LoopFileName, ".daf", Options.Reps[0])
	IfNotExist, %Out%
	{
		Send, <!fo^l%List%{Tab}<!n%A_LoopFileName%{Enter}
		WinWaitActive Processing Status
		WinWaitActive IDEAS
		WinWaitActive Processing Status
		WinWaitActive IDEAS
		Loop % Options.PopLines.Length()
		{
			Out := StrReplace(A_LoopFileName, ".daf", Options.Reps[A_Index])
			IfNotExist, %Out%
			{
				Main(Out, Options.PopLines[A_Index], Options.Features)
				WinWaitActive IDEAS
			}
		}
		Click, 2530, 50
		WinWaitActive, Save Analysis Data
		Send, {Right}{Enter}
		WinWaitActive IDEAS
	}
}
Return

RAlt & F::
	Options := UserInput()
	ControlGetText, File, WindowsForms10.Window.8.app.0.31c915c_r6_ad12, A
	MsgBox, %File%
	Loop % Options.PopLines.Length()
	{
		Out := StrReplace(File, ".daf", Options.Reps[A_Index])
		Main(Out, Options.PopLines[A_Index], Options.Features)
	}
Return
