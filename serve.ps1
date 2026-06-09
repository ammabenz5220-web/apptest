$port = 3000
$root = $PSScriptRoot
$url  = "http://localhost:$port/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($url)
$listener.Start()
Write-Host "Serving $root" -ForegroundColor Green
Write-Host "Open: $url" -ForegroundColor Cyan
Write-Host "(Ctrl+C to stop)"

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".ttf"  = "font/ttf"
}

try {
    while ($listener.IsListening) {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        try {
            $rawPath  = [Uri]::UnescapeDataString($req.Url.AbsolutePath)
            $filePath = Join-Path $root ($rawPath.TrimStart('/').Replace('/', [System.IO.Path]::DirectorySeparatorChar))

            if (Test-Path $filePath -PathType Container) {
                $filePath = Join-Path $filePath "index.html"
            }

            if (Test-Path $filePath -PathType Leaf) {
                $ext   = [System.IO.Path]::GetExtension($filePath).ToLower()
                $mime  = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
                $bytes = [System.IO.File]::ReadAllBytes($filePath)

                $resp.StatusCode      = 200
                $resp.ContentType     = $mime
                $resp.ContentLength64 = $bytes.LongLength
                if ($req.HttpMethod -ne "HEAD") {
                    $resp.OutputStream.Write($bytes, 0, $bytes.Length)
                }
                Write-Host "200  $rawPath"
            } else {
                $body = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rawPath")
                $resp.StatusCode      = 404
                $resp.ContentType     = "text/plain; charset=utf-8"
                $resp.ContentLength64 = $body.LongLength
                $resp.OutputStream.Write($body, 0, $body.Length)
                Write-Host "404  $rawPath" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "ERR  $_" -ForegroundColor Red
        } finally {
            try { $resp.OutputStream.Close() } catch {}
        }
    }
} finally {
    $listener.Stop()
}
