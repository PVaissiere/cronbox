#!/usr/bin/pwsh
# @(#)--------------------------------------------------------------------------
# @(#)Shell		: /usr/bin/pwsh
# @(#)Auteur		: PVaissiere
# @(#)Nom		: CronBox-Log.psm1
# @(#)Date		: 2021/04/08
# @(#)Version		: 0.5.1
# @(#)
# @(#)Resume		: Module des fonctions de journal
# @(#)
# @(#)Liste des fonctions
# @(#)			Get-ModuleLogValue
# @(#)			Get-PathLogValue
# @(#)			Initialize-ModuleLog
# @(#)			Set-LogSubValue
# @(#)			Set-LogTypeValue
# @(#)			Unpublish-LockFile
# @(#)			Write-EnTete
# @(#)			Write-Log
# @(#)			Write-PiedPage
# @(#)--------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# --- Définition des variables du module
# ------------------------------------------------------------------------------
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'LogType' -Value ( [String]'' ) -Description 'Sous-type du script.'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'LogSub' -Value ( [String]'' ) -Description 'Sous-répertoire de stockage de log.'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'LogTmp' -Value ( [String]'' ) -Description 'Variable tampon si -DisableNewLine'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'MsgModuleLog' -Value ( [Hashtable]@{
	'Delimiteur' =		'======================================================='
	'ErrCRONLOGS' =		"La variable d'environnement CRONLOGS est vide.£Merci de vérifier votre POD."
	'ErrFichierLock' = 	'Une instance {0} est déjà en cours.'
	'ErrLogType' =		"La variable LogType est vide.£Ajouter Set-LogTypeValue -Value 'VotreValeur' avant Initialize-ModuleLog"
	'ErrModuleCommun' =	"Le module CronBox-Commun et ses fonctions n'a pas été trouvé£Merci de vérifier le chargement des modules."
	'ErrModuleLog' =	"La fonction {0} ne peux pas être appelé avant Initialize-ModuleLog"
	'InfoLog01' =		"=== Cronbox : {0}"
	'InfoLog02' =		"=== [DEBUT] : {0}"
	'InfoLog03' =		"=== [FIN]   : {0}"
	'InfoLog04' =		"=== [INFO]  : Fichier Log {0}"
} ) -Description 'Variable des messages'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathLockFile' -Value ( [String]'' ) -Description 'Nom et chemin du fichier du journal'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathLog' -Value ( [String]'' ) -Description 'Chemin parent du fichier journal'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'PathLogFile' -Value ( [String]'' ) -Description 'Nom et chemin du fichier du journal'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'SwtModuleLog' -Value ( [Switch]$false ) -Description 'Switch si Initialize-ModuleLog a été lancé'

# ------------------------------------------------------------------------------
# --- Définition des fonctions
# ------------------------------------------------------------------------------
Function Get-ModuleLogValue {
<#
.SYNOPSIS
Permet de récuperer la valeur de la variable ModuleLog

.DESCRIPTION
Le retour $true ou $false permet de savoir si l'initialisation du module est fait
#>

	Return (Get-Variable -Scope 'Script' -Name 'SwtModuleLog' -ValueOnly)
}

Function Get-PathLogValue {
<#
.SYNOPSIS
Permet de récuperer la valeur de la variable PathLog

.DESCRIPTION
Permet de récupérer le chemin où sont stocker les fichiers de log
#>

	If ( -not $Script:SwtModuleLog ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleLog -f $MyInvocation.MyCommand )
	}
	Return (Get-Variable -Scope 'Script' -Name 'PathLog' -ValueOnly)
}

Function Initialize-ModuleLog {
<#
.SYNOPSIS
Permet la vérification de tous les prérequis du module CronBox-Log

.DESCRIPTION
Vérifie si le module CronBox-Commun est chargé,
Vérifie si les variables LogType et $env:CRONLOGS sont défini,
Définie les variables PathLog et PathLogFile,
Création du répertoire de log si non présent et du fichier vierge
Vérifie si un fichier lck est déjà présent sinon le crée
Finalisation Initialisation
#>

	# --- Vérification si le module CronBox-Commun est chargé
	IF ( -not [Bool]( Get-Command -Module CronBox-Commun ) ) {
		Throw ( $Script:MsgModuleLog.ErrModuleCommun )
	}

	# --- Vérifie si la variable LogType est défini
	If ( $LogType -eq '' ) {
		Throw ( $Script:MsgModuleLog.ErrLogType )
	}

	# --- Vérifie si la variable $env:CRONLOGS est défini
	If ( $null -eq ($env:CRONLOGS) ) {
		Throw ( $Script:MsgModuleLog.ErrCRONLOGS )
	}

	# --- Définie la variable PathLogFile
	$Racine = Assert-PathName -Path $env:CRONLOGS
	$SubDir = ( $LogSub ) ? ( Assert-PathName -Path $LogSub ) : ''
	$Parent = "$Racine$SubDir"
	$LogDate = Get-Date -Format 'yyyyMMdd-HHmm'
	Set-Variable -Scope 'Script' -Name 'PathLog' -Value $Parent
	Set-Variable -Scope 'Script' -Name 'PathLogFile' -Value "$Parent$LogDate-$LogType.log"

	# --- Création du répertoire parent si non présent
	Try {
		New-Directory -Path $Parent
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}

	# --- Vérifie si un fichier lck est déjà présent sinon le crée
	Set-Variable -Scope 'Script' -Name 'PathLockFile' -Value "$($Parent)cron-$LogType.lck"
	If ( Test-Path -Path $Script:PathLockFile -PathType Leaf ) {
		Throw ( $Script:MsgModuleLog.ErrFichierLock -f $LogType )
	}

	# --- Création du fichier vierge
	If ( -not ( Test-Path -Path $PathLogFile -PathType Leaf ) ) {
		Try {
			New-Item -Path $PathLogFile -ItemType File -ErrorAction Stop | Out-Null
		}
		Catch {
			Throw ( $_.Exception.Message )
		}
	}

	# --- Finalisation Initialisation
	Try {
		New-Item -Path $Script:PathLockFile -ItemType File | Out-Null
	}
	Catch {
		Throw ( $_.Exception.Message )
	}

	Set-Variable -Scope 'Script' -Name 'SwtModuleLog' -Value $true
}

Function Set-LogSubValue {
<#
.SYNOPSIS
Définie la valeur du sous-répertoire pour la log.

.DESCRIPTION
Permet d'établir la variable LogSub qui définie
le sous-répertoire où sera écrit le journal.

.PARAMETER Value
Valeur pour la définition de la variable LogSub

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-LogSubValue -Value "cron"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'LogSub' -Value $Value
}

Function Set-LogTypeValue {
<#
.SYNOPSIS
Définie le type du sous-répertoire pour la log.

.DESCRIPTION
Permet d'établir la variable Logtype qui définie
le sous-type de journal.

.PARAMETER Value
Valeur pour la définition de la variable Logtype

.INPUTS
La valeur ne peux pas être passé par le pipeline

.EXAMPLE
PS>Set-LogTypeValue -Value "daily"
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'Logtype' -Value $Value
}

Function Unpublish-LockFile {
<#
.SYNOPSIS
Supprime le fichier lck.

.DESCRIPTION
Supprime le fichier lck s'il est présent.
#>

	If ( Test-Path -Path $Script:PathLockFile -PathType Leaf ) {
		Remove-Item -Path $Script:PathLockFile | Out-Null
	}
}


Function Write-EnTete {
<#
.SYNOPSIS
Ecrit dans la log l'en-tête de page générique.

.DESCRIPTION
En-tête formaté pour toutes les ouvertures de scripts
#>

	If ( -not $Script:SwtModuleLog ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleLog -f $MyInvocation.MyCommand )
	}

	Try {
		Write-Log -Value ( $Script:MsgModuleLog.Delimiteur,
		( $Script:MsgModuleLog.InfoLog01 -f $Script:Logtype ),
		( $Script:MsgModuleLog.InfoLog02 -f (Get-Date -Format 'dd/MM/yyyy-HH:mm:ss') ),
		( $Script:MsgModuleLog.InfoLog04 -f $Script:PathLogFile ),
		$Script:MsgModuleLog.Delimiteur )
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}

}

Function Write-Log {
<#
.SYNOPSIS
Affiche et archive dans un fichier unique la log d'execution.

.DESCRIPTION
.

.PARAMETER Value
Paramètre d'une ou des lignes du journal a afficher et enregistrer.

.PARAMETER DisableTime
Commutateur d'affichage de la date et heure courante en préfixe des lignes du journal.

.PARAMETER DisableLog
Désactive l'écriture vers le journal.

.PARAMETER DisableNewLine
Permet de pas faire de retour à la ligne automatique.
#>

	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Texte")]
			[String[]]$Value,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("TimeStamp")]
			[Switch]$DisableTime = $false,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[Switch]$DisableLog = $false,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("NoNewLine")]
			[Switch]$DisableNewLine = $false
	)

	If ( -not $Script:SwtModuleLog ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleLog -f $MyInvocation.MyCommand )
	}

	$Value = $Value -split '£'

	$Value | ForEach-Object {
		$Line = $_
		# --- Ajoute la date heure avant le texte
		If (-not $DisableTime) {
			$Line = "$(Get-Date -Format "dd/MM/yyyy-HH:mm:ss") : $Line"
		}
		If ( -not $DisableNewLine ) {
			If ( $Script:LogTmp ) {
				$Script:LogTmp += $Line
				Write-Host $Script:LogTmp
				If ( -not $DisableLog ) {
					Add-Content -Value $Script:LogTmp -Path $PathLogFile
				}
				# --- Re-initialise la variable
				Set-Variable -Scope 'Script' -Force -Name 'LogTmp' -Value ([String]'')
			} Else {
				Write-Host $Line
				If ( -not $DisableLog ) {
					Add-Content -Value $Line -Path $PathLogFile
				}
			}
		} Else {
			# --- Ajoute la ligne dans la variable tempon
			$Script:LogTmp += $Line
		}
	}
}

Function Write-PiedPage {
<#
.SYNOPSIS
Ecrit dans la log le pied de page générique.

.DESCRIPTION
Pied de page formaté pour toutes les fermetures de scripts
#>

	If ( -not $Script:SwtModuleLog ) {
		Throw ( $Script:CronBoxCommunMsg.ErrModuleLog -f $MyInvocation.MyCommand )
	}

	Try {
		Write-Log -Value ( $Script:MsgModuleLog.Delimiteur,
		( $Script:MsgModuleLog.InfoLog01 -f $Script:Logtype ),
		( $Script:MsgModuleLog.InfoLog03 -f (Get-Date -Format 'dd/MM/yyyy-HH:mm:ss') ),
		$Script:MsgModuleLog.Delimiteur)
	}
	Catch {
		Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
	}

	# --- Supprime le fichier lock
	Unpublish-LockFile

}
