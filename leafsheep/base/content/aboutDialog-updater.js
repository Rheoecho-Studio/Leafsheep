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
      // First fetch the lsversion.json for channel-specific version info
      let lsUrl = "https://rheoecho.fyi/bl_w/lsversion.json";
      let lsResponse = await fetch(lsUrl);
      if (lsResponse.ok) {
        let lsData = await lsResponse.json();
        
        // Then fetch the version.json for UXP version info
        let versionUrl = "https://rheoecho.fyi/bl_w/version.json";
        let versionResponse = await fetch(versionUrl);
        let versionData = {};
        if (versionResponse.ok) {
          versionData = await versionResponse.json();
        }
        
        return {
          lsversion: lsData,
          version: versionData
        };
      }
    } catch (e) {
      console.error("Failed to fetch latest version info:", e);
    }
    
    // Fallback if fetch fails
    return {
      lsversion: {},
      version: {
        masterid: "unknown",
        tagsid: "unknown", 
        releaseid: "unknown",
        tags: "unknown",
        release: "unknown"
      }
    };
  },

  // Detect current operating system
  detectSystem: function() {
    let userAgent = navigator.userAgent.toLowerCase();
    if (userAgent.includes("windows")) {
      return "windows";
    } else if (userAgent.includes("linux")) {
      return "linux";
    } else if (userAgent.includes("mac")) {
      return "macos";
    } else if (userAgent.includes("illumos")) {
      return "illumos";
    } else if (userAgent.includes("bsd")) {
      return "bsd";
    } else {
      return "default";
    }
  },

  performVersionComparison: function(local, latest) {
    let messagesDiv = document.getElementById("update-messages");
    if (!messagesDiv) return;
    
    messagesDiv.innerHTML = "";
    
    // Reset styles
    this.resetVersionStyles();
    
    // Check if we have valid data
    if (!latest.lsversion || Object.keys(latest.lsversion).length === 0) {
      this.displayError("Unable to load version data for comparison");
      return;
    }
    
    // Get the channel from local version
    let channel = local.channel;
    if (!channel || channel === "") {
      this.displayError("Unable to determine current channel");
      return;
    }
    
    // Check if channel exists in lsversion.json
    let channelData = latest.lsversion[channel];
    if (!channelData) {
      this.displayError(`Channel ${channel} not found in update data`);
      return;
    }
    
    // Priority 1: Browser Version comparison
    if (local.browser_version !== channelData.browser_version) {
      this.highlightUpdate("browser-version", "browser-latest", true);
      let latestEl = document.getElementById("browser-latest");
      if (latestEl) {
        latestEl.value = channelData.browser_version;
      }
      this.addImportantUpdate(messagesDiv, 
        `You have important updates that need to be updated! (Current: ${local.browser_version}, Latest: ${channelData.browser_version})`,
        "https://github.com/Rheoecho-Studio/Leafsheep/releases");
      return;
    }
    
    // Priority 2: Service Pack comparison
    if (local.service_pack !== channelData.service_pack_version) {
      this.highlightUpdate("service-pack", "service-latest", true);
      let latestEl = document.getElementById("service-latest");
      if (latestEl) {
        latestEl.value = channelData.service_pack_version;
      }
      this.addOptionalUpdate(messagesDiv,
        `You have the option to update, and you can choose the update according to your needs. (Current: ${local.service_pack}, Latest: ${channelData.service_pack_version})`,
        "https://github.com/Rheoecho-Studio/Leafsheep/tags");
      return;
    }
    
    // Priority 3: UXP Version comparison
    let currentSystem = this.detectSystem();
    let uxpVersion = channelData.uxp_version;
    
    // Check if system-specific UXP version exists
    if (uxpVersion && uxpVersion[currentSystem]) {
      uxpVersion = uxpVersion[currentSystem];
    } else if (uxpVersion && uxpVersion.latest_uxp_version) {
      // Fallback to default UXP version
      uxpVersion = uxpVersion.latest_uxp_version;
    } else {
      // Fallback to version.json masterid
      uxpVersion = latest.version.masterid;
    }
    
    if (local.uxp_commit === uxpVersion) {
      this.markAsLatest("uxp-version");
      this.addLatestMessage(messagesDiv, "You are latest!");
    } else if (latest.version && (local.uxp_commit === latest.version.tagsid || local.uxp_commit === latest.version.releaseid)) {
      this.highlightUpdate("uxp-version", "uxp-latest", false);
      let versionLabel = "";
      let versionType = "";
      
      if (latest.version.tagsid === latest.version.releaseid && latest.version.tags === latest.version.release) {
        versionLabel = latest.version.release;
        versionType = "Release";
      } else if (local.uxp_commit === latest.version.tagsid) {
        versionLabel = latest.version.tags;
        versionType = "Tags";
      } else {
        versionLabel = latest.version.release;
        versionType = "Release";
      }
      
      this.addUXPVersionInfo(versionType, versionLabel);
      this.addOptionalUpdate(messagesDiv,
        `You have the option to update, and you can choose the update according to your needs. (Current: ${local.uxp_commit}, Latest: ${uxpVersion})`,
        "https://github.com/Rheoecho-Studio/Leafsheep/tags");
    } else {
      this.highlightUpdate("uxp-version", "uxp-latest", false);
      let latestEl = document.getElementById("uxp-latest");
      if (latestEl) {
        latestEl.value = uxpVersion;
      }
      this.addOptionalUpdate(messagesDiv,
        `You have the option to update, and you can choose the update according to your needs. (Current: ${local.uxp_commit}, Latest: ${uxpVersion})`,
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