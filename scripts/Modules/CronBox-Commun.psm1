#!/usr/bin/pwsh
# @(#)--------------------------------------------------------------------------
# @(#)Shell		: /usr/bin/pwsh
# @(#)Auteur		: PVaissiere
# @(#)Nom		: CronBox-Commun.psm1
# @(#)Date		: 2021/04/08
# @(#)Version		: 0.5.1
# @(#)
# @(#)Resume		: Module des functions communes
# @(#)
# @(#)Liste des fonctions
# @(#)			Add-FiltreRemoveValues
# @(#)			Add-FiltreRenameValues
# @(#)			Assert-Filtre
# @(#)			Assert-PathName
# @(#)			Get-FiltreRemoveValues
# @(#)			Initialize-ModuleCommun
# @(#)			New-Directory
# @(#)			Optimize-Directories
# @(#)			Remove-EmptyDirectories
# @(#)			Remove-OldFiles
# @(#)			Set-PermissionsValues
# @(#)			Set-RetentionValue
# @(#)--------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# --- Définition des variables du module
# ------------------------------------------------------------------------------
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'ChrSeparateur' -Value ( [System.IO.Path]::DirectorySeparatorChar ) -Description 'caractère séparateur répertoire'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'ChrSeparateurAlt' -Value ( [System.IO.Path]::AltDirectorySeparatorChar ) -Description 'alt caractère séparateur répertoire'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FiltreRemove' -Value ( [Object[]]@() ) -Description 'Liste des fichiers à exclure par filtre REGEX'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'FiltreRename' -Value ( [Object[]]@() ) -Description 'Liste des fichiers à renommer par filtre REGEX'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'MsgModuleCommun' -Value ( [Hashtable]@{
	'ErrOptDir' =		"Le Chemin {0} n'existe pas"
	'ErrModuleCommun' =	"La fonction {0} ne peux pas être appelé avant Initialize-ModuleCommun"
	'NfoOptDir' =		'=== [INFO] Optimisation : {0}'
	'NfoOptDirModName' =	'=== [INFO] Modification fichier : {0}'
	'NfoOptDirNewName' =	'=== [INFO] Nouveau nom : {0}'
	'NfoOptDirSupFile' =	'=== [INFO] Suppression fichier : {0}'
	'NfoPurgeFile' =	'=== [PURGE] Anciens fichiers : {0}'
	'NfoRemoveLocal' =	'=== [INFO] Suppression local : {0}'
	'WrgAssertFiltre' =	"=== [WARNING] Le filtre '{0}' n'est pas reconnu comme Regex"
	'WrgFiltreRemove' =	"=== [WARNING] Aucun filtre pour la supression des fichiers trouvés"
	'WrgFiltreRename' =	"=== [WARNING] Aucun filtre pour le renommage des fichiers trouvés"
} ) -Description 'Variable des messages'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'Permissions' -Value ( [Object[]]@() ) -Description 'Liste des fichiers à renommer par filtre REGEX'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'Retention' -Value ( [Int]7 ) -Description 'Nombre de jours de rétention de log'
New-Variable -Scope 'Script' -Force -Visibility Private -Name 'SwtModuleCommun' -Value ( [Switch]$false ) -Description 'Switch si Initialize-ModuleFtp a été lancé'

# ------------------------------------------------------------------------------
# --- Définition des fonctions
# ------------------------------------------------------------------------------
Function Add-FiltreRemoveValues {
<#
.SYNOPSIS
Ajoute un filtre pour la suprresion des fichiers.

.DESCRIPTION
Permet d'établir une nouvelle valeur d'un filtre
qui va permettre de définir quel fichiers supprimer.

.PARAMETER Regex
Paramètre pour la définition Regex de la variable.

.INPUTS
La valeur ne peut pas être passé par le pipeline.

.EXAMPLE
PS>Add-FiltreRemoveValues -Regex '^RARBG.*txt$'

.LINK
https://docs.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_regular_expressions
https://regex101.com/
#>
	[CmdletBinding()]
	Param (
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$Regex
	)

	$Object = New-Object PSObject
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Regex' -Value $Regex
	$Script:FiltreRemove += $Object
}

Function Add-FiltreRenameValues {
<#
.SYNOPSIS
Ajoute un filtre pour le rennomage des fichiers.

.DESCRIPTION
Permet d'établir une nouvelle valeur d'un filtre
qui va permettre de définir quel fichiers rennomer.

.PARAMETER Regex
Paramètre pour la définition Regex de la variable

.PARAMETER Rename
Paramètre pour la définition Rename de la variable

.INPUTS
Les valeurs ne peuvent pas être passé par le pipeline.

.EXAMPLE
PS>Add-FiltreRenameValues -Regex '\s{2,}' -Rename ' ' # Replace les doubles (ou plus) espaces par un simple espace

.LINK
https://docs.microsoft.com/fr-fr/powershell/module/microsoft.powershell.core/about/about_regular_expressions
https://regex101.com/
#>
	[CmdletBinding()]
	Param (
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$Regex,
	[Parameter(Mandatory=$false,
	ValueFromPipeline=$false)]
		[String]$Rename
	)

	$Object = New-Object PSObject
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Regex' -Value $Regex
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Rename' -Value $Rename
	$Script:FiltreRename += $Object
}

Function Assert-Filtre {
<#
.SYNOPSIS
Vérifie chaques filtres 

.DESCRIPTION
Test les filtres et vérifie s'ils sont Regex
et fait le trie pour ne garder que les corrects

.PARAMETER Filter
Liste des filtres a vérifier.

.INPUTS
Les valeurs ne peuvent pas être passé par le pipeline.
#>
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Filtre")]
			$Filter
	)

	$MyFiltre = $Filter.Regex | ForEach-Object {
		$SubFiltre = $_
		Try {
			"TEST" | Where-Object {$_ -match $SubFiltre} | Out-Null
			$SubFiltre
		}
		Catch {
			Write-Log -Value ( $Script:MsgModuleCommun.WrgAssertFiltre -f $SubFiltre )
		}
	}

	# --- Trie pour ne garder que les filtres valides
	$Filter = $Filter | Where-Object { $MyFiltre -contains $_.Regex }

	Return $Filter
}

Function Assert-PathName {
<#
.SYNOPSIS
Met en forme le chemin pour être ad hoc avec le système.

.DESCRIPTION
Remplace les ChrSeparateurAlt par des ChrSeparateur
Remplace les multiples ChrSeparateur par un simple ChrSeparateur
Ajoute un ChrSeparateur en fin du chemin si manquant

.PARAMETER Path
Paramètre du chemin a vérifier.

.INPUTS
La variable Path peux être passer par le Pipeline.

.OUTPUTS
$Path mis en forme

.EXAMPLE
PS Windows>Assert-PathName -Path "C:\\MyProject/MyDirectory"
C:\MyProject\MyDirectory\

.EXAMPLE
PS Linux>"/MyProject\\MyDirectory" | Assert-PathName
/MyProject/MyDirectory/
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$true,
		Position=0)]
		[Alias("Chemin")]
			[String]$Path
	)
	# --- Remplace les ChrSeparateurAlts par des ChrSeparateurs
	$Path = $Path.replace( $Script:ChrSeparateurAlt, $Script:ChrSeparateur )
	# --- Remplace les multiples ChrSeparateurs par un simple ChrSeparateur
	$Path = $Path -replace "\$Script:ChrSeparateur+", "$Script:ChrSeparateur"
	# --- Ajoute un ChrSeparateur en fin du chemin si manquant
	If ( $Path -notmatch "\$Script:ChrSeparateur$" ) {
		$Path += $Script:ChrSeparateur
	}

	Return $Path
}

Function Get-FiltreRemoveValues {
<#
.SYNOPSIS
Renvoi la liste des filtres pour la suppression.

.DESCRIPTION
Retourne la liste des filtres vérifié.
#>
	If ( -not $Script:SwtModuleCommun ) {
		Throw ( $Script:MsgModuleCommun.ErrModuleCommun -f $MyInvocation.MyCommand )
	}
	Return ( Get-Variable -Scope 'Script' -Name 'FiltreRemove' -ValueOnly )
}

Function Initialize-ModuleCommun {
<#
.SYNOPSIS
Permet la vérification de tous les prérequis du module CronBox-Communn

.DESCRIPTION
Vérifie les filtres Remove,
Vérifie les filtres Rename.
#>

	$Script:FiltreRemove = Assert-Filtre -Filter $Script:FiltreRemove
	$Script:FiltreRename = Assert-Filtre -Filter $Script:FiltreRename

	If ( $Script:FiltreRemove.Count -eq 0 ) {
		Write-Log -Value $Script:MsgModuleCommun.WrgFiltreRemove
	}
	If ( $Script:FiltreRename.Count -eq 0 ) {
		Write-Log -Value $Script:MsgModuleCommun.WrgFiltreRename
	}

	Set-Variable -Scope 'Script' -Name 'SwtModuleCommun' -Value $true
}

Function New-Directory {
<#
.SYNOPSIS
Crée un répertoire si non présent.

.DESCRIPTION
Crée un répertoire si non présent,
Sinon ne fait rien.

.PARAMETER Path
Valeur du répertoire à créer.
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Path
	)
	If ( -not ( Test-Path -Path $Path -PathType Container ) ) {
		Try {
			New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
		}
		Catch {
			Throw ( $_.Exception.Message )
		}
	}
}

Function Optimize-Directories {
<#
.SYNOPSIS
Optimise les répertoires par les divers filtres.

.DESCRIPTION
Supprime les fichiers par le Filtre Remove,
Renomme les fichiers par le Filtre Rename,
Supprime les répertoires vides si purge.

.PARAMETER Path
Paramètre du chemin a optimiser.

.PARAMETER Purge
Purge les sous-répertoires vide.
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$false)]
		[Alias("Chemin","Chemins")]
			[String[]]$Path,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Purger")]
			[Switch]$Purge = $false
	)

	If ( $Script:FiltreRemove.Count -eq 0 ) {
		$DoFiltreRemove = $false
	} Else {
		$DoFiltreRemove = $true
		$RemoveFilter = [String]::Join( "|", $Script:FiltreRemove.Regex )
	}

	If ( $Script:FiltreRename.Count -eq 0 ) {
		$DoFiltreRename = $false
	} Else {
		$DoFiltreRename = $true
		$RenameFilter = $Script:FiltreRename | Group-Object -Property Rename | Sort-Object -Property Count -Descending | ForEach-Object {
			$Object = New-Object PSObject
			$Object | Add-Member -MemberType 'NoteProperty' -Name 'Regex' -Value ([String]::Join( "|", $_.Group.Regex ))
			$Object | Add-Member -MemberType 'NoteProperty' -Name 'Rename' -Value $_.Name
			$Object
		}
	}

	If ( $DoFiltreRemove -or $DoFiltreRename ) {
		$Path | ForEach-Object {
			$Chemin = $_
			If ( -not ( Test-Path -Path $Chemin -PathType Container ) ) {
				Write-Log -Value ( $Script:MsgModuleCommun.ErrOptDir -f $Chemin )
				
			} Else {
				Write-Log -Value ( $Script:MsgModuleCommun.NfoOptDir -f $Chemin )
				$Files = Get-ChildItem -LiteralPath $Chemin -Recurse -File | Select-Object -Property Name, FullName
				If ( $DoFiltreRemove ) {
					$Files | Where-Object { $_.Name -match $RemoveFilter } | ForEach-Object {
						Write-Log -Value ( $Script:MsgModuleCommun.NfoOptDirSupFile -f $_.FullName )
						Try {
							Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
						}
						Catch {
							Throw ( $_.Exception.Message )
						}
					}
					$Files = $Files | Where-Object { $_.Name -notmatch $RemoveFilter }
				}
				If ( $DoFiltreRename ) {
					$Files | ForEach-Object {
						$NewName = $_.Name
						Do {
							$Count = 0
							$RenameFilter | ForEach-Object {
								If ($NewName -match $_.Regex) {
									$Count += 1
									$NewName = $NewName -replace $_.Regex, $_.Rename
								}
							}
						} While ($Count -ne 0)
						If ($NewName -ne $_.Name) {
							Write-Log -Value ( $Script:MsgModuleCommun.NfoOptDirModName -f $_.Name )
							Try {
								Rename-Item -Path $_.FullName -NewName $NewName -Force
								Write-Log -Value ( $Script:MsgModuleCommun.NfoOptDirNewName -f $NewName )
							}
							Catch {
								Throw ( $_.Exception.Message )
							}
						}
					}
				}

			}
			If ( $Script:Permissions.Count -eq 1 ) {
				Try {
					If ( $Script:Permissions.Chmod -ne '' ) {
						chmod -R $Script:Permissions.Chmod $Chemin
					}
					If ( $Script:Permissions.Chown -ne '' ) {
						chown -R $Script:Permissions.Chown $Chemin
					}
				}
				Catch {
					Throw ( $_.Exception.Message )
				}

			}
		}
	}

	# --- Supprime les répertoires vides
	If ( $Purge ) {
		Try {
			Remove-EmptyDirectories -Path $Path
		}
		Catch {
			Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
		}
	}
}

Function Remove-EmptyDirectories {
<#
.SYNOPSIS
Supprime les sous-répertoires vides.

.DESCRIPTION
Supprime les sous-répertoires vides.

.PARAMETER Path
Paramètre du chemin a optimiser.
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		Position=0)]
		[Alias("Chemin","Chemins")]
			[String[]]$Path
	)

	# --- Supprime les répertoires vides
	$Path | ForEach-Object {
		$Chemin = $_
		Do {
			$Number = 0
			Get-ChildItem -LiteralPath $Chemin -Recurse -Directory | Where-Object { (Get-ChildItem -LiteralPath $_.FullName).Count -eq 0 } | ForEach-Object {
				$Number += 1
				Write-Log -Value ($Script:MsgModuleCommun.NfoRemoveLocal -f $_.FullName)
				Try {
					Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
				}
				Catch {
					Throw ( $_.Exception.Message )
				}
			}
		} While ($Number -ne 0)
	}
}

Function Remove-OldFiles {
<#
.SYNOPSIS
Supprime les anciens fichiers.

.DESCRIPTION
Supprime les anciens fichiers.
Supprime les répertoires vides si purge.

.PARAMETER Path
Chemin vers les fichiers a purger apres x jours de rétention.

.PARAMETER Purge
Purge les sous-répertoires vide.
#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$true,
		ValueFromPipeline=$true,
		Position=0)]
		[Alias("Chemin", "Chemins")]
			[String[]]$Path,
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
		[Alias("Purger")]
			[Switch]$Purge = $false
	)

	# --- Purge des anciens fichiers
	$Path | ForEach-Object {
		$Chemin = $_
		Write-Log -Value ($Script:MsgModuleCommun.NfoPurgeFile -f $Chemin )
		Get-ChildItem -LiteralPath $Chemin -Recurse -File | Where-Object {$_.LastWriteTime -lt  (Get-Date).AddDays(-$Script:Retention)} | ForEach-Object {
			Write-Log -Value ($Script:MsgModuleCommun.NfoRemoveLocal -f $_.FullName)
			Try {
				Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
			}
			Catch {
				Throw ( $_.Exception.Message )
			}
		}
	}
	
	# --- Supprime les répertoires vides
	If ( $Purge ) {
		Try {
			Remove-EmptyDirectories -Path $Path
		}
		Catch {
			Throw ( ( ( $_.ScriptStackTrace -split '\r?\n' )[0] -replace '\<ScriptBlock\>\,\s','' ) + '£' + $_.Exception.Message )
		}
	}
}

Function Set-PermissionsValues {
<#
.SYNOPSIS
Définie la valeur du propiétaire et des permissions.

.DESCRIPTION
Permet d'établir la variable Chown pour le propiétaire et
Chmod pour les permissions.

.PARAMETER Chmod
Paramètre pour la définition de la variable Chmod

.PARAMETER Chown
Paramètre pour la définition de la variable Chown

.INPUTS
Les valeurs ne peuvent pas être passé par le pipeline.

.EXAMPLE
PS>Set-PermissionsValues -Chmod 775 -Chown 'userplex:groupuser'

.EXAMPLE
PS>Set-PermissionsValues -Chmod 777 -Chown '1027:100'
#>
	[CmdletBinding()]
	Param (
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$Chmod,
	[Parameter(Mandatory=$true,
	ValueFromPipeline=$false)]
		[String]$Chown
	)

	$Object = New-Object PSObject
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Chmod' -Value $Chmod
	$Object | Add-Member -MemberType 'NoteProperty' -Name 'Chown' -Value $Chown
	$Script:Permissions = $Object
}

Function Set-RetentionValue {
<#
.SYNOPSIS
Définie la valeur de rétention de log.

.DESCRIPTION
Permet d'établir la variable Retention qui définie
le nombre de jours de journaux a garder.

.PARAMETER Value
Valeur pour la définition de la variable Retention

.INPUTS
La valeur ne peux pas être passé par le pipeline.

.EXAMPLE
PS>Set-RetentionValue -Value 7
#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$false,
		ValueFromPipeline=$false)]
			[String]$Value
	)
	Set-Variable -Scope 'Script' -Name 'Retention' -Value $Value
}
