Set-PSDebug -Trace 2

$ErrorActionPreference = 'Stop'
$p = [int]::Parse($env:Fabric_Endpoint_ServiceEndpoint)

# discover SF user name of code package main entry point
$x = [xml](gc "${env:Fabric_Folder_Application}/${env:Fabric_ServicePackageName}.${env:Fabric_ServicePackageActivationId}.Package.Current.xml")
$x.OuterXml
$ns = @{ sf = 'http://schemas.microsoft.com/2011/01/fabric' }
$n1 = Select-Xml -Xml $x -Namespace $ns -XPath "//sf:ServicePackage/sf:DigestedCodePackage/sf:RunAsPolicy[@CodePackageRef='${env:Fabric_CodePackageName}'][@EntryPointType='Main']/@UserRef"
$n2 = Select-Xml -Xml $x -Namespace $ns -XPath "//sf:ServicePackage/sf:DigestedCodePackage/sf:RunAsPolicy[@CodePackageRef='${env:Fabric_CodePackageName}'][@EntryPointType='All']/@UserRef"
$n3 = Select-Xml -Xml $x -Namespace $ns -XPath "//sf:ServicePackage/sf:DigestedCodePackage/sf:RunAsPolicy[@CodePackageRef='${env:Fabric_CodePackageName}'][not(@EntryPointType)]/@UserRef"
$n = ($n1.Node.Value, $n2.Node.Value, $n3.Node.Value -ne $null)[0]
Write-Host "Discovered Main entry point user: $n"

$ErrorActionPreference = 'SilentlyContinue'
& netsh http delete urlacl url=http://*:$p/
& netsh http delete urlacl url=http://+:$p/
& netsh http delete urlacl url=http://localhost:$p/
& netsh http delete urlacl url=http://${env:Fabric_Endpoint_IPOrFQDN_ServiceEndpoint}:$p/

$ErrorActionPreference = 'Stop'
Test-Path $env:Fabric_Folder_Application\Application.Sids.txt
$s = $($h=@{};(gc $env:Fabric_Folder_Application\Application.Sids.txt).Split(',')|%{$l=$_.Split(':');$h[$l[0]]=$l[1].Trim()};$h[$n])
$o = New-Object System.Security.Principal.SecurityIdentifier $s
$u = $o.Translate([System.Security.Principal.NTAccount]).Value

Write-Host "Adding URL reservation: url=http://*:$p/ user=$u"
& netsh http add urlacl url=http://*:$p/ user=$u

Write-Host "Running aspnet_regiis for $u"
& $env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -ga $u
& $env:windir\Microsoft.NET\Framework64\v4.0.30319\aspnet_regiis.exe -ga $u

foreach ($reg in @(
    "HKLM:\SOFTWARE\Microsoft\ASP.NET\4.0.30319.0\CompilationMutexName",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\ASP.NET\4.0.30319.0\CompilationMutexName")) {
    Write-Host "Setting registry permissions: $reg"
    $acl = Get-Acl $reg
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ($u, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $acl | Set-Acl -Path $reg
}
