#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.Synopsis
   Armazena numa variável as VMs que estão num host para uma eventual manutenção e depois as move de volta 
.DESCRIPTION
   Armazena numa variável as VMs que estão num host para uma eventual manutenção e depois as move de volta 
.EXAMPLE
   
.EXAMPLE
   Inserir posteriormente
.CREATEDBY
    Juliano Alves de Brito Ribeiro (find me at julianoalvesbr@live.com or https://github.com/julianoabr or https://youtube.com/@powershellchannel)
.VERSION INFO
    0.1
.VERSION NOTES
    
.VERY IMPORTANT
    “Todos os livros científicos passam por constantes atualizações. 
    Se a Bíblia, que por muitos é considerada obsoleta e irrelevante, 
    nunca precisou ser atualizada quanto ao seu conteúdo original, 
    o que podemos dizer dos livros científicos de nossa ciência?” 

#>

#VALIDATE MODULE
$moduleExists = Get-Module -Name Vmware.VimAutomation.Core

if ($moduleExists){
    
    Write-Output "The Module Vmware.VimAutomation.Core is already loaded"
    
}#if validate module
else{
    
    Import-Module -Name Vmware.VimAutomation.Core -WarningAction SilentlyContinue -ErrorAction Stop
    
}#else validate module

function Pause-PSScript
{

   Read-Host 'Pressione [ENTER] para continuar' | Out-Null

}

#VALIDATE IF OPTION IS NUMERIC
function isNumeric ($x) {
    $x2 = 0
    $isNum = [System.Int32]::TryParse($x, [ref]$x2)
    return $isNum
} #end function is Numeric


#FUNCTION CONNECT TO VCENTER
function Connect-vCenterServer
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet('Manual','Auto')]
        $methodToConnect = 'Manual',

        [Parameter(Mandatory=$true,
                   Position=1)]
        [System.String[]]$vCenterServerList, 
                
        [Parameter(Mandatory=$false,
                   Position=2)]
        [System.String]$dnsSuffix,
        
        [Parameter(Mandatory=$false,
                   Position=3)]
        [System.Boolean]$LastConnectedServers = $false,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [System.String]$connectionProtocol,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [ValidateSet('80','443')]
        [System.String]$port = '443'
    )

#VALIDATE IF YOU ARE CONNECTED TO ANY VCENTER 
if ((Get-Datacenter) -eq $null)
    {
        Write-Host "You are not connected to any vCenter" -ForegroundColor White -BackgroundColor DarkMagenta
    }
else{
        
        Write-Host "You are connected to some vCenter. I will disconnect you" -ForegroundColor White -BackgroundColor Red
            
        Disconnect-VIServer -Server * -Confirm:$false -Force -Verbose -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

}#end of else validate if you are connected. 


if ($methodToConnect -eq 'Automatic'){
        
    foreach ($vCenterServer in $vCenterServerList){
            
        $Script:workingServer = ""
        
        $Script:workingServer = $vCenterServer + '.' + $suffix

        $vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $Port -WarningAction Continue -ErrorAction Stop

   }#end of foreach vcenter list
       
}#end of If Method to Connect
else{
        
    $workingLocationNum = ""
        
    $tmpWorkingLocationNum = ""
        
    $Script:WorkingServer = ""
        
    $iterator = 0

    #MENU SELECT VCENTER
    foreach ($vCenterServer in $vCenterServerList){
	   
        $vcServerValue = $vCenterServer
	    
        Write-Output "            [$iterator].- $vcServerValue ";	
	            
        $iterator++	
                
        }#end foreach	
                
            Write-Output "            [$iterator].- Exit this script ";

            while(!(isNumeric($tmpWorkingLocationNum)) ){
	                
                $tmpWorkingLocationNum = Read-Host "Type the number of vCenter that you want to connect to"
                
            }#end of while

                $workingLocationNum = ($tmpWorkingLocationNum / 1)

                if(($WorkingLocationNum -ge 0) -and ($WorkingLocationNum -le ($iterator-1))  ){
	                
                    $Script:WorkingServer = $vCenterServerList[$WorkingLocationNum]
                
                }#end of IF
                else{
            
                    Write-Host "Exit selected, or Invalid choice number. End of Script." -ForegroundColor Red -BackgroundColor White
            
                    Exit;
                }#end of else

        #Connect to Vcenter
        $Script:vcInfo = Connect-VIServer -Server $Script:WorkingServer -Port $port -WarningAction Continue -ErrorAction Stop -Verbose
  
    
    }#end of Else Method to Connect

}#End of Function Connect to vCenter

##############################################################
#MAIN SCRIPT

#DEFINE VCENTER LIST
$vcServerList = @();

#ADD OR REMOVE VCs        
$vcServerList = ('server1','server2','server3','server4','server5','server6') | Sort-Object

#SELECT TYPE OF CONNECTIONS
Do
{
 
 $tmpMethodToConnect = Read-Host -Prompt "Type (Manual) if you want to choose vCenter to Connect. 
 Type (Automatic) if you want to Type the Name of vCenter to Connect"

    if ($tmpMethodToConnect -notmatch "^(?:manual\b|automatic\b)"){
    
        Write-Host "You typed an invalid word. Type only (manual) or (automatic)" -ForegroundColor White -BackgroundColor Red
    
    }
    else{
    
        Write-Host "You typed a valid word. I will continue =D" -ForegroundColor White -BackgroundColor DarkBlue
    
    }
    
}While ($tmpMethodToConnect -notmatch "^(?:manual\b|automatic\b)")#end of while choose method to connect


if ($tmpMethodToConnect -match "^\bautomatic\b$"){

    [System.String]$tmpVC = Read-Host "Write the name of vCenter that you want to connect"

    $tmpSuffix = ""

    [System.String]$tmpSuffix = Read-Host "If necessary type DNS Suffix of vCenter that you want to connect"

    if ($tmpSuffix -like $null){
        
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -port 443 -Verbose
            
    }#end of IF
    else{
    
        Connect-vCenterServer -vCenterServerList $tmpVC -methodToConnect Auto -dnsSuffix $tmpSuffix -port 443 -Verbose
    
    }#end of Else
    

}#end of IF
else{

    Connect-vCenterServer -vCenterServerList $vcServerList -methodToConnect Manual -port 443 -Verbose

}#end of Else


[System.String]$esxiHostName = Read-Host -Prompt "Type the HostName that you want to get All VMs that are run on it"


$hostObj = Get-VMHost -Name $esxiHostName

$vmSourceList = @()

$vmSourceList = $hostObj | get-vm | Select-Object -ExpandProperty Name | Sort-Object

$vmSourceList

[System.Int32]$countVM = $vmSourceList.Count

#FOR TEST PURPOSE ONLY
#$sourceVM = 'testVM'

Pause-PSScript

$counterVM = 0

foreach ($sourceVM in $vmSourceList)
{
    
    $counterVM++

    $vmObj = Get-VM -Name $sourceVM -Verbose

    $hostDestinationObj = Get-VMHost -Name $esxiHostName -Verbose

    Write-Progress -Activity "vMotion Progress" -PercentComplete (($counterVM*100)/$countVM) -Status "$(([math]::Round((($counterVM)/$countVM * 100),0))) %"

    Move-VM -VM $vmObj -Destination $hostDestinationObj -Confirm:$false -RunAsync -Verbose

        
}#end of foreach
