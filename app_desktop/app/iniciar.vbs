' Arranque sin ventana de consola (usa pythonw.exe del .venv local).
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
appDir = fso.GetParentFolderName(WScript.ScriptFullName)
pythonw = appDir & "\.venv\Scripts\pythonw.exe"
mainPy = appDir & "\main.py"
If Not fso.FileExists(pythonw) Then
    pythonw = appDir & "\.venv\Scripts\python.exe"
End If
sh.CurrentDirectory = appDir
sh.Run """" & pythonw & """ """ & mainPy & """", 1, False
