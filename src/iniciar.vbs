' Arranque de SmartCSET Portería.
' Con runtime\.venv listo: pythonw.exe del venv, sin ventana de consola.
' Primer arranque (sin venv): Python del sistema en consola visible; main.py
' -> bootstrap.ensure_venv() crea runtime\.venv e instala dependencias y
' relanza la app con el venv. La bandera SMARTCSET_VENV_ACTIVE solo se fija
' cuando ya se usa el interprete del venv (si no, el bootstrap se salta).
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
srcDir = fso.GetParentFolderName(WScript.ScriptFullName)
moduleDir = fso.GetParentFolderName(srcDir)
venvPythonw = moduleDir & "\runtime\.venv\Scripts\pythonw.exe"
venvPython = moduleDir & "\runtime\.venv\Scripts\python.exe"
mainPy = srcDir & "\main.py"
sh.CurrentDirectory = srcDir

If fso.FileExists(venvPythonw) Then
    sh.Environment("Process")("SMARTCSET_VENV_ACTIVE") = "1"
    ' 0 = sin ventana de consola; False = no esperar (un solo arranque).
    sh.Run """" & venvPythonw & """ """ & mainPy & """", 0, False
ElseIf fso.FileExists(venvPython) Then
    sh.Environment("Process")("SMARTCSET_VENV_ACTIVE") = "1"
    sh.Run """" & venvPython & """ """ & mainPy & """", 0, False
Else
    ' Sin venv: consola visible (1) para ver la creacion del entorno.
    sh.Environment("Process")("SMARTCSET_VENV_ACTIVE") = ""
    sh.Run "python """ & mainPy & """", 1, False
End If
