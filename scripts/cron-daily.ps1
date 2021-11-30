#!/usr/bin/pwsh
# @(#)--------------------------------------------------------------------------
# @(#)Shell		: /usr/bin/pwsh
# @(#)Auteur		: PVaissiere
# @(#)Nom		: cron-daily.ps1
# @(#)Date		: 2021/04/06
# @(#)Version		: 0.4.7
# @(#)
# @(#)Resume		: Script de puge journaliere
# @(#)
# @(#)Description	: Multiples purges et optimisations des répertoires utilisés
# @(#)--------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# --- Importation des fonctions et des variables
# ------------------------------------------------------------------------------
Try {
	# ------------------------------------------------------------------------------
	# --- Importation des fonctions et des variables
	# ------------------------------------------------------------------------------
	$Liste = Get-ChildItem -Path $PSScriptRoot -Recurse | Where-Object { $_.DirectoryName -ne $PSScriptRoot } | Sort-Object -Property Name | Select-Object -ExpandProperty FullName
	$Liste | Where-Object { $_ -match "\.psm1$" } | ForEach-Object { Import-Module $_ -Force -ErrorAction Stop }
	$Liste | Where-Object { $_ -match "\.ps1$" } | ForEach-Object { Import-Module $_ -Force -ErrorAction Stop }

	# ------------------------------------------------------------------------------
	# --- Variables complémentaire du journal
	# ------------------------------------------------------------------------------
	Set-LogtypeValue -Value 'daily'
}
Catch {
	[Object[]]$Message = ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s',''
	$Message += ($_.Exception.Message -split '£'  -split '\r?\n' )
	$Message | ForEach-Object {
		Write-Host "[ERREUR] $_"
	}
	Exit 8
}

# ------------------------------------------------------------------------------
# --- Application
# ------------------------------------------------------------------------------
Try {
	# --- Initialisation du Module Log
	Initialize-ModuleLog

	# --- Bandeau d'en-tête
	Write-EnTete

	# --- Initialisation du Module Commun
	Initialize-ModuleCommun

	# --- Initialisation du Module Ftp
	Initialize-ModuleFtp

	# --- Force la vérification de librairies
	Assert-Libraries -Force

	# --- Purge les vieux fichiers log
	Remove-OldFiles -Path (Get-PathLogValue) -Purge

	Optimize-Directories -Path (Get-FtpPathValues).LocalPath -Purge

	# --- Bandeau d'en-tête
	Write-PiedPage
}
Catch {
	[Object[]]$Message = ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s',''
	$Message += ($_.Exception.Message -split '£')
	If ( Get-ModuleLogValue ) {
		$Message | ForEach-Object {
			Write-Log "[ERREUR] $_" -DisableTime
		}
		# --- Supprime le fichier lock
		Unpublish-LockFile
	} Else {
		$Message | ForEach-Object {
			Write-Host "[ERREUR] $_"
		}
	}
	Exit 8
}

Exit 0
