Describe "Close-Issue" {
    BeforeAll {
        $script:IssueNumber = "1"
        $script:Token       = "fake-token"
        $script:Owner       = "test-owner"
        $script:RepoName    = "test-repo"
        $script:MockApiUrl  = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
	
    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
		It "unit: Close-Issue succeeds with HTTP 200" {
	        Mock Invoke-WebRequest {
				return @{
					StatusCode = 200;
					Content = '{"state": "closed"}'
				}
	        }
			
	        Close-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	}

	Context "HTTP Failure Cases" {
		It "unit: Close-Issue fails with HTTP 404" {
			Mock Invoke-WebRequest {
				return @{
					StatusCode = 404;
					Content = '{"message": "Issue not found"}' 
				}
			}
			
			Close-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Should -Contain "error-message=Error: Failed to close issue #1. Status: 404"
	    }
	}	

	Context "Parameter Validation Failure Cases" {
  		It "unit: Close-Issue fails with empty issue number" {
	        Close-Issue -IssueNumber "" -Token $Token -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
	    }
	
	    It "unit: Close-Issue fails with empty token" {
	        Close-Issue -IssueNumber $IssueNumber -Token "" -Owner $Owner -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
	    }
	
	    It "unit: Close-Issue fails with empty repository" {
	        Close-Issue -IssueNumber $IssueNumber -Token $Token -Owner "" -RepoName ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
	    }
	
	    It "unit: Close-Issue fails with empty owner" {
	        Close-Issue -IssueNumber $IssueNumber -Token $Token -Owner "" -RepoName $RepoName
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: issue_number, repo_name, owner, and token must be provided."
	    }	
	}

	Context "Exception Failure Cases" {
		It "unit: Close-Issue fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			try {
				Close-Issue -IssueNumber $IssueNumber -Token $Token -Owner $Owner -RepoName $RepoName
			} catch {}
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Where-Object { $_ -match "^error-message=Error: Failed to close issue #$IssueNumber. Exception:" } |
				Should -Not -BeNullOrEmpty
		}		
	}
}
