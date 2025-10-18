# Login to get JWT token for testing Discussion APIs
# Replace phone and password with your actual credentials

$loginData = @{
    phone = "+1234567890"  # Replace with your actual phone
    password = "your_password"  # Replace with your actual password
} | ConvertTo-Json

Write-Host "🔐 Attempting login..." -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "https://astrologerapp-production.up.railway.app/api/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $loginData

    if ($response.success) {
        Write-Host "✅ Login successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Your JWT Token:" -ForegroundColor Yellow
        Write-Host $response.data.token -ForegroundColor White
        Write-Host ""
        Write-Host "👤 Logged in as: $($response.data.astrologer.name)" -ForegroundColor Cyan
        Write-Host "📧 Email: $($response.data.astrologer.email)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "💾 Token saved to: jwt_token.txt" -ForegroundColor Green
        
        # Save token to file for easy access
        $response.data.token | Out-File -FilePath "jwt_token.txt" -NoNewline
        
        return $response.data.token
    } else {
        Write-Host "❌ Login failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Error during login: $($_.Exception.Message)" -ForegroundColor Red
}

