#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

Main(Out) {
	Send, <!te{Enter}{Space}
	
	WinWaitActive, Create TIFs From Population

	ControlClick, WindowsForms10.SysTreeView32.app.0.31c915c_r6_ad11, Create TIFs From Population
	Loop % 20 {
		Sleep, 100
		Send, {Up}
	}
	Loop % 5 {
		Sleep, 100
		Send, {Down}
	}

	Sleep, 100

	ControlClick, WindowsForms10.LISTBOX.app.0.31c915c_r6_ad11, Create TIFs From Population
	Send, {Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}{Up}
	Send, +{Down}+{Down}+{Down}+{Down}+{Down}+{Down}

	Sleep, 100

	ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad16, Create TIFs From Population
	ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad13, Create TIFs From Population
	ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad11, Create TIFs From Population
	ControlClick, WindowsForms10.EDIT.app.0.31c915c_r6_ad11, Create TIFs From Population
	Send, %Out%

	Sleep, 100

	ControlClick, WindowsForms10.BUTTON.app.0.31c915c_r6_ad15, Create TIFs From Population

	WinWaitActive, Browse For Folder
	Send, {Enter}

	WinWaitNotActive, Processing Status
}

RAlt & U::
CoordMode, Mouse, Client
FileSelectFolder, List
SetWorkingDir, %List%
WinActivate IDEAS
WinWaitActive IDEAS
Loop, Files, *.daf
{
	Send, <!fo^l%List%{Tab}<!n%A_LoopFileName%{Enter}
	WinWaitActive Processing Status
	WinWaitActive IDEAS
	WinWaitActive Processing Status
	WinWaitActive IDEAS
	Out := StrReplace(A_LoopFileName, ".daf")
	Main(Out)
	WinWaitActive IDEAS
	Click, 2530, 50
	WinWaitActive, Save Analysis Data
	Send, {Right}{Enter}
	WinWaitActive IDEAS
}
Return

RAlt & S::
	ControlGetText, File, WindowsForms10.Window.8.app.0.31c915c_r6_ad12, A
	Out := StrReplace(File, ".daf")
	Main(Out)
Return
