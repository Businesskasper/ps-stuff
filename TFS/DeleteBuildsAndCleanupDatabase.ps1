# This is a workaround  for this TFS 2018 Update 2 bug:
# https://docs.microsoft.com/en-us/visualstudio/releasenotes/tfs2018-update3
#   -> Database size continues to grow after builds are deleted.
#   -> Builds are not getting deleted based on the build retention policy.
# The Bug is (apparently?) fixed with Update 3.

# It deletes all builds and releases including artifacts but the last x or which are older than the last x days.
# It also configures the tfs retention policy for builds and releases accordingly.
# It then invokes the tfs jobs which mark all corresponding datasets with the delete flag.
# To release the free space from the database, run following stored procedures on sql after completion.
# Make sure you have a lot of free space for the log to grow. Also note that this can take a loooong time.
# EXEC prc_CleanupDeletedFileContent 1
# EXEC prc_DeleteUnusedFiles 1, 0, 100 -> run this multiple times until it completes instantly

# After this you can make a full backup to clear the log. After the full backup you can shrink the database.

$teams = @("Production", "Internal")
$tfsUrl = "https://tfs.contoso.com"
$daysToKeep = 3
$numberOfBuildsToKeep = 3

foreach ($team in $teams) {

    #
    # Builds
    #

    $buildDefinitions = Invoke-RestMethod -UseDefaultCredentials `
        -Uri "$($tfsUrl)/$($team)/_apis/build/definitions?api-version=4.0" `
        -Method Get -UseBasicParsing | select -ExpandProperty value

    foreach ($definition in $buildDefinitions) {
    
        $definition.name

        # Retention Policy anpassen  
        $settings = Invoke-WebRequest -Method Get -UseDefaultCredentials -Uri $definition._links.self.href -UseBasicParsing -ContentType "application/json" | select -ExpandProperty Content | ConvertFrom-Json
    
        if ($settings.retentionRules.Count -ne 0) {

            foreach ($retentionRule in $settings.retentionRules) {

                $retentionRule.daysToKeep = $daysToKeep
                $retentionRule.minimumToKeep = $numberOfBuildsToKeep
                $retentionRule.artifactTypesToDelete = @(
                    "FilePath",
                    "SymbolStore",
                    "SymbolRequest",
                    "PipelineArtifact"
                )
            }
     
            $body = $settings | ConvertTo-Json -Depth 100 

            Invoke-WebRequest -Method Put `
                -uri "$($tfsUrl)/$($team)/_apis/build/definitions/$($definition.id)?api-version=4.0" `
                -UseDefaultCredentials `
                -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
                -ContentType "application/json" `
                -ErrorAction Stop | Out-Null
        }
    
        # Retention Policy von Builds anpassen und alte Builds löschen
        [array]$builds = Invoke-RestMethod -UseDefaultCredentials `
            -Uri "$($tfsUrl)/$($team)/_apis/build/builds?api-version=4.0&definitions=$($definition.id)" `
            -Method Get | select -ExpandProperty value

        foreach ($build in $builds) {
    
            $body = @{
                keepforever       = $false
                retainedByRelease = $false
            } | ConvertTo-Json

            Invoke-WebRequest -Method Patch `
                -Uri "$($tfsUrl)/$($team)/_apis/build/builds/$($build.id)?api-version=4.0" `
                -UseDefaultCredentials `
                -Body $body `
                -ContentType "application/json" `
                -ErrorAction Stop | Out-Null
        }    

        $buildsToDelete = $builds | Sort-Object startTime -Descending | select -Skip $numberOfBuildsToKeep
        foreach ($buildToDelete in $buildsToDelete) {

            Invoke-RestMethod -UseDefaultCredentials `
                -Uri "$($tfsUrl)/$($team)/_apis/build/builds/$($buildToDelete.id)?api-version=4.0" `
                -Method Delete | Out-Null
        }   
    }



    #
    # Releases
    #

    [array]$releaseDefinitions = Invoke-RestMethod -UseDefaultCredentials `
        -Uri "$($tfsUrl)/$($team)/_apis/release/definitions" `
        -Method Get -UseBasicParsing | select -ExpandProperty value

    foreach ($releaseDefinition in $releaseDefinitions) {

        Write-Host $releaseDefinition.name
    
        # Retention Policy anpassen
        $settings = Invoke-WebRequest -Method Get -UseDefaultCredentials -Uri $releaseDefinition._links.self.href -UseBasicParsing -ContentType "application/json" | select -ExpandProperty Content | ConvertFrom-Json
    
        foreach ($environment in $settings.environments) {

            $environment.retentionPolicy.daysToKeep = $daysToKeep
            $environment.retentionPolicy.releasesToKeep = $numberOfBuildsToKeep
            $environment.retentionPolicy.retainBuild = $false
        }

        $body = $settings | ConvertTo-Json -Depth 100 
        Invoke-WebRequest -Method Put `
            -Uri "$($tfsUrl)/$($team)/_apis/release/definitions/$($releaseDefinition.id)?api-version=4.0-preview" `
            -UseDefaultCredentials `
            -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) `
            -ContentType "application/json" `
            -ErrorAction Stop | Out-Null
    

        # Alte Releases löschen    
        [array]$releases = Invoke-RestMethod -UseDefaultCredentials `
            -Uri "$($tfsUrl)/$($team)/_apis/release/releases?definitionId=$($releaseDefinition.Id)&api-version=4.0-preview" `
            -Method Get | select -ExpandProperty value

        $releasesToDelete = $releases | Sort-Object createdOn -Descending | select -Skip $numberOfBuildsToKeep
        foreach ($releaseToDelete in $releasesToDelete) {

            Invoke-WebRequest -UseDefaultCredentials `
                -Uri "$($tfsUrl)/$($team)/_apis/release/releases/$($releaseToDelete.id)?api-version=4.0-preview" `
                -Method Delete | Out-Null
        }
    }
}


#
# Gelöschte Builds flaggen
#

Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Client.dll"
Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.Common.dll"
Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.WorkItemTracking.Client.dll"
Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v2.0\Microsoft.TeamFoundation.VersionControl.Client.dll"
Add-Type -Path "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\ReferenceAssemblies\v4.5\Microsoft.TeamFoundation.ProjectManagement.dll"
$collection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection("$($tfsUrl)/")
$jobService = $collection.GetService([Microsoft.TeamFoundation.Framework.Client.ITeamFoundationJobService])
$job = $jobService.QueryJobs() | Where-Object { $_.Name -eq "Build Information Cleanup Job" }
$jobService.QueueJobNow([Guid] $job.JobId, $false)
#$jobService.QueryLatestJobHistory([Guid[]] @($job.JobId))


