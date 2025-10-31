# Pollo AI Support Email - Ready to Send

## Plain Text Version

```
Subject: 🚨 API Task Status Endpoint Returns 404 — Request for Confirmation

Hello Pollo AI Support Team,

I'm integrating the Pollo API into a production-level Swift/iOS application called DirectorStudio, built by Neural Draft LLC.
We've confirmed that task creation works as expected, but the status polling endpoint consistently returns 404, even for newly created tasks.

Details

API Key (masked): pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn
Environment: macOS Terminal / cURL

Generation Endpoint (working):
POST https://pollo.ai/api/platform/generation/pollo/pollo-v1-6

Status Endpoint (failing):
GET https://pollo.ai/api/platform/generation/task/status/{taskId}

Test Task IDs:

cmhdugtn008iw142oungth0my

cmhdukfgf09t0ycyfydkjtoli

Behavior:

Task creation succeeds and returns a valid taskId.

All tested variations (/task/status/{id}, /task/{id}, /generation/task/{id}) return 404 immediately or even after 60+ seconds.

Verified across multiple fresh tasks and repeated runs.

Questions

Is the /task/status/{taskId} endpoint still active or has it been updated?

Is there a delay or alternate route for task availability (e.g., webhook or different polling path)?

Are there any API scope or permission changes affecting pollo-v1-6?

Could you confirm the expected response structure and polling method for active tasks?

Impact

This behavior currently blocks automated task monitoring and indexing within DirectorStudio's production pipeline. We're holding deployment until this is clarified.

Thank you for your help.
Please confirm whether this endpoint has changed or provide the correct path for current API versions.

Warm regards,
Amir Khodabakhsh
Founder / Developer — Neural Draft LLC
📧 amir@neuralecho.net

🌐 https://neuraldraft.net | https://directorstudio.dev
```

---

## HTML Version (for Gmail / branded email)

```html
<p>Hello Pollo AI Support Team,</p>

<p>I'm integrating the Pollo API into a production-level Swift/iOS application called 
<strong>DirectorStudio</strong>, built by <strong>Neural Draft LLC</strong>. 
We've confirmed that task creation works as expected, but the 
<strong>status polling endpoint consistently returns 404</strong>, even for newly created tasks.</p>

<hr>
<h3>Details</h3>
<p><strong>API Key (masked):</strong> pollo_wR53NAgcFqBTzPAaggCoQtQBvyusFBSPMfyujBdoCfkn<br>
<strong>Environment:</strong> macOS Terminal / cURL<br>
<strong>Generation Endpoint (working):</strong><br>
<code>POST https://pollo.ai/api/platform/generation/pollo/pollo-v1-6</code><br>
<strong>Status Endpoint (failing):</strong><br>
<code>GET https://pollo.ai/api/platform/generation/task/status/{taskId}</code></p>

<p><strong>Test Task IDs:</strong><br>
cmhdugtn008iw142oungth0my<br>
cmhdukfgf09t0ycyfydkjtoli</p>

<p><strong>Behavior:</strong><br>
Task creation succeeds and returns a valid <code>taskId</code>.<br>
All tested variations (<code>/task/status/{id}</code>, <code>/task/{id}</code>, <code>/generation/task/{id}</code>) 
return <strong>404</strong> even after 60+ seconds.<br>
Verified across multiple new tasks and repeated runs.</p>

<hr>
<h3>Questions</h3>
<ol>
<li>Is the <code>/task/status/{taskId}</code> endpoint still active or has it been updated?</li>
<li>Is there a delay or alternate route for task status (e.g., webhook)?</li>
<li>Have there been scope or permission changes affecting <code>pollo-v1-6</code>?</li>
<li>Could you confirm the current expected response format and polling approach?</li>
</ol>

<hr>
<h3>Impact</h3>
<p>This issue currently blocks automated task monitoring and indexing in DirectorStudio's pipeline. 
We're pausing deployment until endpoint behavior is clarified.</p>

<hr>
<p>Thank you for your time and support.<br>
Please confirm whether this endpoint has changed or provide the correct equivalent path.</p>

<p>Warm regards,<br><br>
<strong>Amir Khodabakhsh</strong><br>
Founder / Developer — Neural Draft LLC<br>
📧 <a href="mailto:amir@neuralecho.net">amir@neuralecho.net</a><br>
🌐 <a href="https://neuraldraft.net">neuraldraft.net</a> | 
<a href="https://directorstudio.dev">directorstudio.dev</a></p>
```

---

## Where to Send

**Pollo AI Support Contact**:
- Check their website for support email or contact form
- Common: support@pollo.ai, hello@pollo.ai, or contact form on their website
- Look for: https://pollo.ai/contact or similar

---

## Additional Context (for your records)

**Testing Performed**:
- ✅ Task creation verified (POST succeeds)
- ✅ Multiple task IDs tested
- ✅ Status endpoint tested with 60+ second waits
- ✅ Alternative endpoint formats tested
- ✅ Fast-fail timeout implemented (30 seconds)

**Files Created**:
- `POLLO_API_ISSUE_ANALYSIS.md` - Technical analysis
- `POLLO_SUPPORT_EMAIL.md` - This file (ready-to-send email)


