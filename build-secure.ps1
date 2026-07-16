param(
  [Parameter(Mandatory=$true)][string]$Password,
  [string]$Src = "index-src.html",
  [string]$Out = "index.html"
)
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$srcPath = Join-Path $dir $Src

# 1) Leer la app en claro y anteponer un sello para verificar el descifrado
$plainBytes = [System.IO.File]::ReadAllBytes($srcPath)
$sentinel = [System.Text.Encoding]::UTF8.GetBytes("RSM_OK|")
$data = New-Object byte[] ($sentinel.Length + $plainBytes.Length)
[Array]::Copy($sentinel, 0, $data, 0, $sentinel.Length)
[Array]::Copy($plainBytes, 0, $data, $sentinel.Length, $plainBytes.Length)

# 2) Derivar clave (PBKDF2-SHA256) y cifrar (AES-256-CBC)
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = New-Object byte[] 16; $rng.GetBytes($salt)
$iv   = New-Object byte[] 16; $rng.GetBytes($iv)
$iter = 100000
$kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $salt, $iter, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$key = $kdf.GetBytes(32)
$aes = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256; $aes.Mode = 'CBC'; $aes.Padding = 'PKCS7'; $aes.Key = $key; $aes.IV = $iv
$encryptor = $aes.CreateEncryptor()
$ct = $encryptor.TransformFinalBlock($data, 0, $data.Length)

$payload = @{
  v = 1; iter = $iter
  salt = [Convert]::ToBase64String($salt)
  iv   = [Convert]::ToBase64String($iv)
  ct   = [Convert]::ToBase64String($ct)
} | ConvertTo-Json -Compress

# 3) Plantilla de la pantalla de acceso (descifra en el navegador con Web Crypto)
$gate = @'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>RetailSite Madrid</title>
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#16a34a">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="RetailSite Madrid">
<link rel="icon" href="icons/favicon-32.png" sizes="32x32">
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, -apple-system, sans-serif; background: #f8fafc; color: #111827; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
  .gate { background: #fff; border: 1px solid #e5e7eb; border-radius: 18px; box-shadow: 0 10px 40px rgba(0,0,0,0.08); padding: 32px 28px; width: 100%; max-width: 380px; text-align: center; }
  .logo { font-weight: 800; font-size: 24px; letter-spacing: -0.5px; margin-bottom: 4px; }
  .logo span { color: #16a34a; }
  .sub { font-size: 13px; color: #9ca3af; margin-bottom: 22px; }
  .lock { font-size: 40px; margin-bottom: 14px; }
  input { width: 100%; border: 1.5px solid #d1d5db; border-radius: 10px; padding: 12px 14px; font-size: 16px; outline: none; color: #111827; background: #f9fafb; margin-bottom: 12px; }
  input:focus { border-color: #16a34a; background: #fff; }
  button { width: 100%; background: #16a34a; border: none; color: #fff; border-radius: 10px; padding: 12px; font-weight: 700; font-size: 15px; cursor: pointer; }
  button:disabled { opacity: 0.6; cursor: default; }
  .err { color: #dc2626; font-size: 13px; font-weight: 600; margin-top: 12px; min-height: 18px; }
  .recover { margin-top: 18px; font-size: 12px; color: #6b7280; }
  .recover a { color: #16a34a; font-weight: 600; text-decoration: none; }
</style>
</head>
<body>
<div class="gate">
  <div class="lock">🔒</div>
  <div class="logo">🛒 Retail<span>Site</span> Madrid</div>
  <div class="sub">Acceso privado</div>
  <input id="pw" type="password" placeholder="Contraseña" autocomplete="current-password" autofocus>
  <button id="go">Entrar</button>
  <div class="err" id="err"></div>
  <div class="recover">¿Olvidaste la contraseña?<br><a href="mailto:bordetass@gmail.com?subject=Acceso%20RetailSite%20Madrid">Escribe a bordetass@gmail.com</a></div>
</div>
<script>
const PAYLOAD = __PAYLOAD__;
const b64 = s => Uint8Array.from(atob(s), c => c.charCodeAt(0));

async function decryptApp(password) {
  const salt = b64(PAYLOAD.salt), iv = b64(PAYLOAD.iv), ct = b64(PAYLOAD.ct);
  const km = await crypto.subtle.importKey('raw', new TextEncoder().encode(password), 'PBKDF2', false, ['deriveKey']);
  const key = await crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations: PAYLOAD.iter, hash: 'SHA-256' },
    km, { name: 'AES-CBC', length: 256 }, false, ['decrypt']
  );
  const buf = await crypto.subtle.decrypt({ name: 'AES-CBC', iv }, key, ct);
  const text = new TextDecoder().decode(buf);
  if (!text.startsWith('RSM_OK|')) throw new Error('sello');
  return text.slice(7);
}

async function enter() {
  const btn = document.getElementById('go');
  const err = document.getElementById('err');
  const pw = document.getElementById('pw').value;
  if (!pw) { err.textContent = 'Introduce la contraseña.'; return; }
  btn.disabled = true; err.textContent = 'Descifrando…';
  try {
    const html = await decryptApp(pw);
    // Recordar en este dispositivo: solo se pide la primera vez
    try { localStorage.setItem('rsm_pw', pw); } catch(_) {}
    document.open(); document.write(html); document.close();
  } catch (e) {
    try { localStorage.removeItem('rsm_pw'); } catch(_) {}
    err.textContent = 'Contraseña incorrecta.';
    btn.disabled = false;
  }
}

document.getElementById('go').addEventListener('click', enter);
document.getElementById('pw').addEventListener('keydown', e => { if (e.key === 'Enter') enter(); });

// Si ya se validó antes en este dispositivo, entrar directo sin preguntar
const saved = (() => { try { return localStorage.getItem('rsm_pw'); } catch(_) { return null; } })();
if (saved) {
  document.getElementById('pw').value = saved;
  enter();
}

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(()=>{}));
}
</script>
</body>
</html>
'@

$gate = $gate.Replace('__PAYLOAD__', $payload)
$outPath = Join-Path $dir $Out
[System.IO.File]::WriteAllText($outPath, $gate, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("OK -> {0} generado. Datos cifrados: {1} KB" -f $Out, [math]::Round($ct.Length/1024))
