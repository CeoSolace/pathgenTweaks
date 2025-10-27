const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 10000;

app.use(express.json());
app.use(express.static('public'));

let users = new Map();

app.post('/api/register', (req, res) => {
    const { username, ip } = req.body;
    if (!username) return res.status(400).json({ error: 'Username required' });
    users.set(username, { ip, timestamp: Date.now(), valid: true });
    console.log(`[REGISTER] ${username} (${ip})`);
    res.json({ success: true });
});

app.get('/api/validate', (req, res) => {
    const { username } = req.query;
    if (!username) return res.status(400).json({ error: 'Username required' });
    const user = users.get(username);
    if (!user) return res.json({ valid: false });
    res.json({ valid: user.valid });
});

app.post('/api/delete', (req, res) => {
    const { username } = req.body;
    if (!username) return res.status(400).json({ error: 'Username required' });
    if (users.has(username)) {
        users.get(username).valid = false;
        console.log(`[EXPIRED] ${username}`);
        res.json({ success: true });
    } else {
        res.status(404).json({ error: 'User not found' });
    }
});

app.get('/admin', (req, res) => {
    const userList = Array.from(users.entries()).map(([username, data]) => ({ username, ...data }));
    res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>PathTweaks Admin</title><meta charset="utf-8"></head>
    <body>
        <h1>PathTweaks Admin Dashboard</h1>
        <table border="1" style="border-collapse:collapse">
            <tr><th>Username</th><th>IP</th><th>Valid</th><th>Action</th></tr>
            ${userList.map(u => `
            <tr>
                <td>${u.username}</td>
                <td>${u.ip}</td>
                <td>${u.valid ? '✅' : '❌'}</td>
                <td><button onclick="expire('${u.username}')">Expire</button></td>
            </tr>`).join('')}
        </table>
        <script>
        async function expire(username) {
            const res = await fetch('/api/delete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username })
            });
            if (res.ok) location.reload();
        }
        </script>
    </body>
    </html>`);
});

app.listen(PORT, () => {
    console.log(`PathTweaks Dashboard running on port ${PORT}`);
});
