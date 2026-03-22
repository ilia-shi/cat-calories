package handler

import "net/http"

const loginPage = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Cat Calories - Login</title>
<style>
	* { margin: 0; padding: 0; box-sizing: border-box; }
	body { font-family: system-ui, sans-serif; background: #0f0f0f; color: #e0e0e0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
	.card { background: #1a1a1a; border-radius: 16px; padding: 48px 40px; max-width: 380px; width: 100%; text-align: center; }
	h1 { font-size: 28px; margin-bottom: 8px; }
	.subtitle { color: #888; margin-bottom: 24px; font-size: 14px; }
	form { display: flex; flex-direction: column; gap: 10px; margin-bottom: 12px; }
	input { padding: 12px 14px; border-radius: 10px; border: 1px solid #333; background: #111; color: #e0e0e0; font-size: 15px; outline: none; }
	input:focus { border-color: #555; }
	.btn { display: block; width: 100%; padding: 14px; border-radius: 10px; border: none; cursor: pointer; font-weight: 600; font-size: 15px; transition: opacity .15s; }
	.btn:hover { opacity: .85; }
	.btn-primary { background: #6c63ff; color: #fff; }
	.toggle { color: #6c63ff; background: none; border: none; cursor: pointer; font-size: 13px; margin-bottom: 20px; }
	.toggle:hover { text-decoration: underline; }
	.divider { display: flex; align-items: center; gap: 12px; margin: 20px 0; color: #555; font-size: 13px; }
	.divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: #333; }
	.oauth { display: flex; flex-direction: column; gap: 12px; }
	a.oauth-btn { display: block; padding: 14px; border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 15px; transition: opacity .15s; }
	a.oauth-btn:hover { opacity: .85; }
	.google { background: #4285f4; color: #fff; }
	.facebook { background: #1877f2; color: #fff; }
	.error { color: #ff6b6b; font-size: 13px; min-height: 18px; }
</style>
</head>
<body>
<div class="card">
	<h1>Cat Calories</h1>
	<p class="subtitle">Sign in to sync your data</p>

	<form id="auth-form" onsubmit="return handleSubmit(event)">
		<input type="text" id="name-field" name="name" placeholder="Name" style="display:none">
		<input type="email" name="email" placeholder="Email" required>
		<input type="password" name="password" placeholder="Password" required>
		<button type="submit" class="btn btn-primary" id="submit-btn">Sign in</button>
	</form>
	<button class="toggle" id="toggle-btn" onclick="toggleMode()">Don't have an account? Register</button>
	<p class="error" id="message"></p>

	<div class="divider">or</div>

	<div class="oauth">
		<a href="/auth/google/login" class="oauth-btn google">Continue with Google</a>
		<a href="/auth/facebook/login" class="oauth-btn facebook">Continue with Facebook</a>
	</div>
</div>
<script>
let isLogin = true;

function toggleMode() {
	isLogin = !isLogin;
	document.getElementById('submit-btn').textContent = isLogin ? 'Sign in' : 'Create account';
	document.getElementById('toggle-btn').textContent = isLogin
		? "Don't have an account? Register"
		: 'Already have an account? Sign in';
	document.getElementById('name-field').style.display = isLogin ? 'none' : 'block';
	document.getElementById('message').textContent = '';
}

async function handleSubmit(e) {
	e.preventDefault();
	const form = e.target;
	const msg = document.getElementById('message');
	const url = isLogin ? '/auth/login' : '/auth/register';
	const body = { email: form.email.value, password: form.password.value };
	if (!isLogin) body.name = form.name.value;

	try {
		const res = await fetch(url, {
			method: 'POST',
			headers: {'Content-Type': 'application/json'},
			body: JSON.stringify(body),
		});
		const data = await res.json();
		if (!res.ok) {
			msg.textContent = data.error || 'Something went wrong';
			return false;
		}
		localStorage.setItem('token', data.token);
		window.location.href = '/';
	} catch {
		msg.textContent = 'Network error';
	}
	return false;
}

// Redirect to home if already logged in
(async function() {
	const token = localStorage.getItem('token');
	if (!token) return;
	const res = await fetch('/api/me', { headers: { 'Authorization': 'Bearer ' + token } });
	if (res.ok) window.location.href = '/';
})();
</script>
</body>
</html>`

func Login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(loginPage))
}
