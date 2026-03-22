package handler

import "net/http"

const homePage = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cat Calories</title>
<style>
	* { margin: 0; padding: 0; box-sizing: border-box; }
	body { font-family: system-ui, sans-serif; background: #0f0f0f; color: #e0e0e0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
	.card { background: #1a1a1a; border-radius: 16px; padding: 48px 40px; max-width: 440px; width: 100%; }
	h1 { font-size: 28px; margin-bottom: 24px; text-align: center; }
	.loading { text-align: center; color: #888; }
	.user-info { display: none; }
	.field { margin-bottom: 16px; }
	.field label { display: block; font-size: 12px; color: #888; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px; }
	.field .value { font-size: 16px; padding: 10px 14px; background: #111; border: 1px solid #333; border-radius: 10px; }
	.logout { display: block; width: 100%; margin-top: 24px; padding: 14px; border-radius: 10px; border: none; cursor: pointer; font-weight: 600; font-size: 15px; background: #333; color: #e0e0e0; transition: opacity .15s; }
	.logout:hover { opacity: .85; }
</style>
</head>
<body>
<div class="card">
	<h1>Cat Calories</h1>
	<p class="loading" id="loading">Loading...</p>
	<div class="user-info" id="user-info">
		<div class="field">
			<label>Email</label>
			<div class="value" id="user-email"></div>
		</div>
		<div class="field">
			<label>Name</label>
			<div class="value" id="user-name"></div>
		</div>
		<div class="field">
			<label>Provider</label>
			<div class="value" id="user-provider"></div>
		</div>
		<div class="field">
			<label>Member since</label>
			<div class="value" id="user-created"></div>
		</div>
		<button class="logout" onclick="logout()">Sign out</button>
	</div>
</div>
<script>
function logout() {
	localStorage.removeItem('token');
	window.location.href = '/login';
}

(async function() {
	const token = localStorage.getItem('token');
	if (!token) {
		window.location.href = '/login';
		return;
	}

	const res = await fetch('/api/me', {
		headers: { 'Authorization': 'Bearer ' + token }
	});

	if (!res.ok) {
		localStorage.removeItem('token');
		window.location.href = '/login';
		return;
	}

	const user = await res.json();
	document.getElementById('user-email').textContent = user.email;
	document.getElementById('user-name').textContent = user.name || '(not set)';
	document.getElementById('user-provider').textContent = user.provider;
	document.getElementById('user-created').textContent = new Date(user.created_at).toLocaleDateString();
	document.getElementById('loading').style.display = 'none';
	document.getElementById('user-info').style.display = 'block';
})();
</script>
</body>
</html>`

func Home(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(homePage))
}
