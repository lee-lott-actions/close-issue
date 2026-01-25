param(
    [int]$Port = 3000
)

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()

Write-Host "Mock server listening on http://127.0.0.1:$Port..." -ForegroundColor Green

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $path = $request.Url.LocalPath
        $method = $request.HttpMethod

        Write-Host "Mock intercepted: $method $path" -ForegroundColor Cyan

        $responseJson = $null
        $statusCode = 200

        # HealthCheck endpoint: GET /HealthCheck
        if ($method -eq "GET" -and $path -eq "/HealthCheck") {
            $statusCode = 200
            $responseJson = @{ status = "ok" } | ConvertTo-Json
        }
        # PATCH /repos/:owner/:repo/issues/:issue_number
        elseif (
            $method -eq "PATCH" -and 
            $path -match '^/repos/([^/]+)/([^/]+)/issues/([^/]+)$'
        ) {
            $owner = $Matches[1]
            $repo = $Matches[2]
            $issueNumber = $Matches[3]

            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()
            Write-Host "Request body: $requestBody"
            Write-Host "Request headers: $($request.Headers | Out-String)"

            # Authorization header validation
            $authHeader = $request.Headers["Authorization"]
            if (-not $authHeader -or -not $authHeader.StartsWith("Bearer ")) {
                $statusCode = 401
                $responseJson = @{ message = "Unauthorized: Missing or invalid Bearer token" } | ConvertTo-Json
            }
            else {
                $bodyObj = $null
                try { $bodyObj = $requestBody | ConvertFrom-Json } catch { $bodyObj = $null }
                $state = $bodyObj.state

                if ($state -eq "closed") {
                    if (
                        $owner -eq "test-owner" -and
                        $repo -eq "test-repo" -and
                        $issueNumber -eq "1"
                    ) {
                        $statusCode = 200
                        $responseJson = @{ state = "closed" } | ConvertTo-Json
                    } else {
                        $statusCode = 404
                        $responseJson = @{ message = "Issue not found" } | ConvertTo-Json
                    }
                } else {
                    $statusCode = 400
                    $responseJson = @{ message = 'Invalid request: state must be "closed"' } | ConvertTo-Json
                }
            }
        }
        else {
            $statusCode = 404
            $responseJson = @{ message = "Not Found" } | ConvertTo-Json
        }

        # Send response
        $response.StatusCode = $statusCode
        $response.ContentType = "application/json"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseJson)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        $response.Close()
    }
}
finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Mock server stopped." -ForegroundColor Yellow
}