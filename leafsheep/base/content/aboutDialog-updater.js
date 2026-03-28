/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

// Updater functionality for about dialog
var Updater = {
  init: function() {
    try {
      // Load local version info
      let versionInfo = this.loadLocalVersionInfo();
      
      // Start version comparison
      this.compareVersions(versionInfo);
    } catch (e) {
      console.error("Error initializing updater:", e);
    }
  },

  loadLocalVersionInfo: function() {
    // Version info will be populated by leafsheep_build.sh during compilation
    return {
      channel: "",
      browser_version: "",
      service_pack: "",
      uxp_commit: ""
    };
  },

  compareVersions: async function(localVersionInfo) {
    try {
      // Display local versions
      this.displayLocalVersions(localVersionInfo);
      
      // Fetch latest version info from remote
      let latestInfo = await this.fetchLatestVersionInfo();
      
      // Perform comparison
      this.performVersionComparison(localVersionInfo, latestInfo);
    } catch (e) {
      console.error("Error in version comparison:", e);
      this.displayError("Failed to check for updates");
    }
  },

  displayLocalVersions: function(versionInfo) {
    let channel = document.getElementById("channel");
    let browserVersion = document.getElementById("browser-version");
    let servicePack = document.getElementById("service-pack");
    let uxpVersion = document.getElementById("uxp-version");
    
    if (channel) channel.value = versionInfo.channel;
    if (browserVersion) browserVersion.value = versionInfo.browser_version;
    if (servicePack) servicePack.value = versionInfo.service_pack;
    if (uxpVersion) uxpVersion.value = versionInfo.uxp_commit;
  },

  fetchLatestVersionInfo: async function() {
    try {
      let url = "https://rheoecho.fyi/bl_w/version.json";
      let response = await fetch(url);
      if (response.ok) {
        return await response.json();
      }
    } catch (e) {
      console.error("Failed to fetch latest version info:", e);
    }
    
    // Fallback if fetch fails
    return {
      masterid: "unknown",
      tagsid: "unknown",
      releaseid: "unknown",
      tags: "unknown",
      release: "unknown"
    };
  },

  performVersionComparison: function(local, latest) {
    let messagesDiv = document.getElementById("update-messages");
    if (!messagesDiv) return;
    
    messagesDiv.innerHTML = "";
    
    // Reset styles
    this.resetVersionStyles();
    
    // Priority 1: Browser Version comparison
    if (local.browser_version !== "1.1") {
      this.highlightUpdate("browser-version", "browser-latest", true);
      this.addImportantUpdate(messagesDiv, 
        "You have important updates that need to be updated!",
        "https://github.com/Rheoecho-Studio/Leafsheep/releases");
      return;
    }
    
    // Priority 2: Service Pack comparison
    if (local.service_pack !== "SP0") {
      this.highlightUpdate("service-pack", "service-latest", true);
      this.addOptionalUpdate(messagesDiv,
        "You have the option to update, and you can choose the update according to your needs.",
        "https://github.com/Rheoecho-Studio/Leafsheep/tags");
      return;
    }
    
    // Priority 3: UXP Version comparison
    if (latest.masterid === "unknown") {
      this.displayError("Unable to load version data for comparison");
      return;
    }
    
    if (local.uxp_commit === latest.masterid) {
      this.markAsLatest("uxp-version");
      this.addLatestMessage(messagesDiv, "You are latest!");
    } else if (local.uxp_commit === latest.tagsid || local.uxp_commit === latest.releaseid) {
      this.highlightUpdate("uxp-version", "uxp-latest", false);
      let versionLabel = "";
      let versionType = "";
      
      if (latest.tagsid === latest.releaseid && latest.tags === latest.release) {
        versionLabel = latest.release;
        versionType = "Release";
      } else if (local.uxp_commit === latest.tagsid) {
        versionLabel = latest.tags;
        versionType = "Tags";
      } else {
        versionLabel = latest.release;
        versionType = "Release";
      }
      
      this.addUXPVersionInfo(versionType, versionLabel);
      this.addOptionalUpdate(messagesDiv,
        "You have the option to update, and you can choose the update according to your needs.",
        "https://github.com/Rheoecho-Studio/Leafsheep/tags");
    } else {
      this.highlightUpdate("uxp-version", "uxp-latest", false);
      this.addOptionalUpdate(messagesDiv,
        "You have the option to update, and you can choose the update according to your needs.",
        "https://github.com/Rheoecho-Studio/Leafsheep/tags");
    }
  },

  resetVersionStyles: function() {
    let currentVersions = document.querySelectorAll(".current-version");
    let latestVersions = document.querySelectorAll(".latest-version");
    
    currentVersions.forEach(el => {
      el.style.textDecoration = "none";
      el.style.color = "#ffffff";
    });
    
    latestVersions.forEach(el => {
      el.style.display = "none";
    });
    
    let tagInfoRow = document.getElementById("uxp-tag-info");
    if (tagInfoRow) {
      tagInfoRow.style.display = "none";
    }
  },

  markAsLatest: function(currentId) {
    let currentEl = document.getElementById(currentId);
    if (currentEl) {
      currentEl.style.color = "#16ff98";
      currentEl.style.fontWeight = "bold";
    }
  },

  highlightUpdate: function(currentId, latestId, isImportant) {
    let currentEl = document.getElementById(currentId);
    let latestEl = document.getElementById(latestId);
    
    if (currentEl && latestEl) {
      // 当前版本显示为黄色
      currentEl.style.color = "#ffcc00";
      currentEl.style.fontWeight = "bold";
      
      // 最新版本显示为绿色
      latestEl.style.display = "inline";
      latestEl.style.color = isImportant ? "#ff6b6b" : "#16ff98";
      latestEl.style.fontWeight = "bold";
    }
  },

  addImportantUpdate: function(messagesDiv, message, url) {
    let messageDiv = document.createElement("description");
    messageDiv.className = "update-message important";
    messageDiv.textContent = message;
    messageDiv.style.color = "#ffffff";
    messageDiv.style.marginBottom = "5px";
    messagesDiv.appendChild(messageDiv);
    
    let button = document.createElement("button");
    button.className = "update-button important";
    button.setAttribute("label", "Update");
    button.style.backgroundColor = "#16ff98";
    button.style.color = "#001405";
    button.style.borderRadius = "25px";
    button.style.padding = "10px 20px";
    button.style.fontSize = "14px";
    button.style.fontWeight = "bold";
    button.style.border = "none";
    button.style.minWidth = "auto";
    button.style.width = "auto";
    button.style.marginTop = "5px";
    button.addEventListener("command", () => {
      window.open(url, "_blank");
    });
    messagesDiv.appendChild(button);
  },

  addOptionalUpdate: function(messagesDiv, message, url) {
    let messageDiv = document.createElement("description");
    messageDiv.className = "update-message optional";
    messageDiv.textContent = message;
    messageDiv.style.color = "#e0e0e0";
    messageDiv.style.marginBottom = "5px";
    messagesDiv.appendChild(messageDiv);
    
    let button = document.createElement("button");
    button.className = "update-button optional";
    button.setAttribute("label", "Update");
    button.style.backgroundColor = "#16ff98";
    button.style.color = "#001405";
    button.style.borderRadius = "25px";
    button.style.padding = "10px 20px";
    button.style.fontSize = "14px";
    button.style.fontWeight = "bold";
    button.style.border = "none";
    button.style.minWidth = "auto";
    button.style.width = "auto";
    button.style.marginTop = "5px";
    button.addEventListener("command", () => {
      window.open(url, "_blank");
    });
    messagesDiv.appendChild(button);
  },

  addLatestMessage: function(messagesDiv, message) {
    let messageDiv = document.createElement("description");
    messageDiv.className = "update-message latest";
    messageDiv.textContent = message;
    messageDiv.style.color = "#16ff98";
    messageDiv.style.fontWeight = "bold";
    messageDiv.style.fontSize = "14px";
    messagesDiv.appendChild(messageDiv);
  },

  addUXPVersionInfo: function(versionType, versionLabel) {
    let tagInfoRow = document.getElementById("uxp-tag-info");
    let tagText = document.getElementById("uxp-tag-text");
    
    if (tagInfoRow && tagText) {
      tagInfoRow.style.display = "flex";
      tagText.value = `${versionType} Latest (${versionLabel})`;
    }
  },

  displayError: function(message) {
    let messagesDiv = document.getElementById("update-messages");
    if (!messagesDiv) return;
    
    messagesDiv.innerHTML = `<description class="update-message">Error: ${message}</description>`;
  }
};