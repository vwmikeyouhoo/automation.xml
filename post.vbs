@@ -0,0 +1,85 @@
On Error Resume Next
Set objShell = createobject("wscript.shell")
Set getMac = objShell.Exec("cmd.exe /c ipconfig/all | find ""Physical Address""")
Set regexp = new RegExp
regexp.IgnoreCase = True
regexp.Global = True
regexp.Pattern = "([a-fA-F0-9]{2}[:|\-]?){6}"

If getMac.ExitCode = "0" Then
    Set macListed = regexp.execute(getMac.StdOut.ReadAll())
    If macListed.Count > 0 Then
       
        Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP")
        objHTTP.setOption 2, 13056 'ignore any ssl cert errors
   
        Dim Eth: Eth = 1
    Dim requiredContent : requiredContent = ""
    Dim optionalContent : optionalContent = ""
   
        For i = 0 to macListed.Count

            mac = macListed.Item(i)
            Wscript.Echo mac

            objHTTP.open "GET", "https://control.gigenet.com/queue/tmp/files/post/" & mac & ".txt", false
            objHTTP.send()

            If Len(objHTTP.ResponseText) > 0 And Not (objHTTP.ResponseText = "file not found") Then

                requiredContent = objHTTP.ResponseText
               
                'check for optional scripts
                objHTTP.open "GET", "https://control.gigenet.com/queue/tmp/files/script/" & mac & ".txt", false
                objHTTP.send()
                If Len(objHTTP.ResponseText) > 0 And Not (objHTTP.ResponseText = "file not found") Then
                    optionalContent = objHTTP.ResponseText
                End If

                Exit For
            End If
            Eth = Eth + 1
            Wscript.Echo "mac return invalid response, continue loop..."

        Next
       
        Set objFSO = CreateObject("Scripting.FileSystemObject")
        Set writeDir = objFSO.GetFolder("C:\tmp")
       
        Set writeTxt = writeDir.CreateTextFile("winsetup.vbs", True)
        requiredContent = Replace(requiredContent, "echo.", vbCrLf)
        writeTxt.WriteLine(requiredContent)
        writeTxt.Close

        'write valid Ethernet number
        Set writeTxt = writeDir.CreateTextFile("Ethernet.txt", True)
        writeTxt.WriteLine(Eth)
        writeTxt.Close
   
        'write optional scripts
        Set writeDir = objFSO.GetFolder("C:\tmp2")
        Set writeTxt = writeDir.CreateTextFile("winupdate.vbs", True)
        optionalContent = Replace(optionalContent, "echo.", vbCrLf)
        writeTxt.WriteLine(optionalContent)
        writeTxt.Close
        
        'check r1soft
        objHTTP.open "GET", "https://control.gigenet.com/default/scripts/win-rOneSoft.txt", false
        objHTTP.send()
        If Len(objHTTP.ResponseText) > 0 And Not (objHTTP.ResponseText = "file not found") Then
            Set writeTxt = writeDir.CreateTextFile("winr1Soft.bat", True)
            writeTxt.WriteLine(Replace(objHTTP.ResponseText, "echo.", vbCrLf))
            writeTxt.Close
        End If
       
        'If Err.Number <> 0 Then
            'Wscript.ECHO "Ooops something went wrong
        'End IF
       
        'regardless if there was an error we will try to kill dhcp as long as mac address is present
        Wscript.Echo "Done"
        objHTTP.open "GET", "https://control.gigenet.com/queue/status/" & mac & "/1/", False
        objHTTP.send
       
    End If
End If
