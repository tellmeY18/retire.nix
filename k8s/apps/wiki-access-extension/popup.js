const TOKEN = "af8675e4daaaf432b2735927e7c4e0dcbd3ac020c1687863";

async function init() {
  const dot = document.getElementById("dot");
  const statusText = document.getElementById("status-text");
  const statusSub = document.getElementById("status-sub");
  const tokenPrev = document.getElementById("token-preview");

  // Show last 8 chars of token so users can verify without exposing the full value
  tokenPrev.textContent = `…${TOKEN.slice(-8)}`;

  try {
    const rules = await chrome.declarativeNetRequest.getDynamicRules();
    const active = rules.some((r) => r.id === 1);

    if (active) {
      dot.classList.remove("inactive");
      statusText.textContent = "Active — token injected";
      statusSub.textContent = "Anubis challenge bypassed for this browser";
    } else {
      dot.classList.add("inactive");
      statusText.textContent = "Inactive";
      statusSub.textContent = "Rule not found — try reloading the extension";
    }
  } catch {
    // getDynamicRules not available on this platform (e.g. Firefox for Android)
    // The background rule still works — only the status check is unavailable.
    dot.classList.remove("inactive");
    statusText.textContent = "Active";
    statusSub.textContent = "Status check not supported on this platform";
  }
}

init();
