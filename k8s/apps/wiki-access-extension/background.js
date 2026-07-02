// FOSS Cell Wiki Access — background service worker
// Appends the member token to the User-Agent for all requests to wiki.fosscell.org.
// The token is checked by Traefik and Anubis — matching requests bypass the PoW
// challenge entirely and are routed directly to the wiki backend.
//
// Token rotation: update TOKEN below and bump the extension version.
// Then redistribute the updated .zip / .xpi to members.

const TOKEN = "af8675e4daaaf432b2735927e7c4e0dcbd3ac020c1687863";
const RULE_ID = 1;

async function installRule() {
  // Read the browser's real User-Agent at runtime so the rule stays correct
  // across browser version updates (Chrome/Firefox bump the UA on each update).
  const baseUA = navigator.userAgent;
  const memberUA = `${baseUA} FOSSCellWiki/token=${TOKEN}`;

  try {
    await chrome.declarativeNetRequest.updateDynamicRules({
      removeRuleIds: [RULE_ID],
      addRules: [
        {
          id: RULE_ID,
          priority: 100,
          action: {
            type: "modifyHeaders",
            requestHeaders: [
              {
                header: "User-Agent",
                operation: "set",
                value: memberUA,
              },
            ],
          },
          condition: {
            requestDomains: ["wiki.fosscell.org"],
            resourceTypes: [
              "main_frame",
              "sub_frame",
              "xmlhttprequest",
              "script",
              "stylesheet",
              "image",
              "font",
              "media",
              "websocket",
              "other",
            ],
          },
        },
      ],
    });
    console.log("[FOSSCellWiki] Member token rule installed.");
  } catch (err) {
    console.error("[FOSSCellWiki] Failed to install rule:", err);
  }
}

// Re-install rule on every browser startup and after extension updates.
// This ensures the UA stays current when the browser version changes.
chrome.runtime.onInstalled.addListener(installRule);
chrome.runtime.onStartup.addListener(installRule);
