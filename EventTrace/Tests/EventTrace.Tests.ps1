Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

$TestDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$RootModuleDir = Resolve-Path "$TestDir\.."
$Module = "$RootModuleDir\EventTrace.psd1"

$ProviderName = "Microsoft-Windows-Kernel-Process"

Import-Module $Module -Force -ErrorAction Stop

Describe 'New-ETWProviderConfig' {
    Context 'output validation' {
        It 'Should return PS object' {
            { (New-ETWProviderConfig).PSObject.TypeNames[1] } | Should Be 'System.Object'
        }
        It 'Should contain 3 properties' {
            { New-ETWProviderConfig | Get-Member | Where-Object {
                $_.MemberType -eq 'NoteProperty' | Measure-Object | Select-Object count
            } } | Should be 3
        }
    }
}

Describe 'ConvertTo-ETWGuid' {
    Context 'input validation' {
        It 'Should should accept string input' {
            { ConvertTo-ETWGuid -ProviderName $ProviderName } | Should Not Throw
        }

        It "Should error on non-existent provider" {
            { ConvertTo-ETWGuid -ProviderName "DOES NOT EXIST" } | Should Throw
        }

        It 'Should generate errors when required parameters are not provided' {
            { ConvertTo-ETWGuid -ProviderName } | Should Throw
        }
    }

    Context 'output validation' {
        It 'Should return type GUID' {
            { ConvertTo-ETWGuid -ProviderName $ProviderName -is [System.Guid] } | Should Be $true
        }
    }
}

Describe 'Get-ProviderKeywords' {
    Context 'input validation' {
        It 'Should require input' {
            { Get-ProviderKeywords -Provider } | Should Throw
        }

        It 'Should accept string input' {
            { Get-ProviderKeywords -Provider $ProviderName }
        }

        It "Should error on non-existent provider" {
            { Get-ProviderKeywords -ProviderName "DOES NOT EXIST" } | Should Throw
        }
    }
    Context 'output validation'{
        It 'Should return properly formatted ProviderDataItem objects' {
            $Result = Get-ProviderKeywords -Provider $ProviderName

            $Result[0].PSObject.TypeNames[0] | Should be 'Microsoft.Diagnostics.Tracing.Session.ProviderDataItem'
        }
    }
}

Describe 'Get-ETWProvider' {
    Context 'output validation' {
        It 'Should generate output'{ 
            { Get-ETWProvider } | Should Not BeNullOrEmpty
        }
        It 'Should return properly formatted ProviderMetadata objects' {
            $Result = Get-ETWProvider

            $Result[0].PSObject.TypeNames[0] | Should be 'System.Diagnostics.Eventing.Reader.ProviderMetadata'
        }
    }
}

Describe 'Get-ETWSessionNames' {
    Context 'output validation' {
        It 'Should generate output' {
            { Get-ETWSessionNames } | Should Not BeNullOrEmpty
        }
    }
}

Describe 'Get-ETWSessionDetails' {
    Context 'input validation' {
        It 'Should require input' {
            { Get-ETWSessionDetails -SessionName } | Should Throw
        }

        It 'Should error when invalid name provided' {
            { Get-ETWSessionDetails -SessionName "not valid" } | Should Throw "Session does not exist"
        }
    }

    Context 'output validation' {
        It 'Should return TraceEventSessionObject' {
            $SessionName = (Get-ETWSessionNames)[0]
            
            $Result = Get-ETWSessionDetails -SessionName $SessionName
            $Result[0].PSObject.TypeNames[0] | Should be 'Microsoft.Diagnostics.Tracing.Session.TraceEventSession'
        }
    }
}


Describe 'Start-ETWSession' {
    Context 'input validation' {
        $SName = "TestSession"
        $OFile = ".\Output.etl"
        $Key = @("not the right type")

        It 'Should generate errors when required params are not provided' {
            { Start-ETWProvider  -SessionConfig -SessionName -OutputFile } | Should Throw 
        }
        It "Should require ProviderDataItem objects in keyword param"{
            { Start-ETWProvider -ProviderConfig $null -Keywords $Key-OutputFile $OFile -SessionName $SName }`
                | Should Throw
        }
        InModuleScope EventTrace{
            It 'Should fail to run if session already exists' {
                Mock Test-IsSession {return $true}

                { Start-ETWProvider -ProviderConfig $null -OutputFile $OFile -SessionName $SName } `
                    | Should Throw

            }
        }
    }
}

Describe 'Stop-ETWSession' {
    Context "input validation" {
        
        It 'Should generate an error when a non-existent session is provided' {
            { Stop-ETWSession -SessionName "does not exist" } | Should Throw
        }
    }


}
