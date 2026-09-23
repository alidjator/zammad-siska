if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["agent"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-agent-avatar-wrap">\n  ');
    
      if (this.agent.avatar) {
        __out.push('\n    <img class="zammad-chat-agent-avatar" src="');
        __out.push(__sanitize(this.agent.avatar));
        __out.push('">\n  ');
      } else {
        __out.push('\n    <span class="zammad-chat-agent-avatar zammad-chat-agent-avatar--initials">');
        __out.push(__sanitize(this.initials));
        __out.push('</span>\n  ');
      }
    
      __out.push('\n  <span class="zammad-chat-agent-status js-chat-status" data-status="online"></span>\n</div>\n<span class="zammad-chat-agent-sentence">\n  <span class="zammad-chat-agent-name">');
    
      __out.push(__sanitize(this.agent.name));
    
      __out.push('</span>\n  <span class="zammad-chat-agent-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_messages_agent_status_active'] || 'Active now'));
    
      __out.push('</span>\n</span>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["attachment_message"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-message zammad-chat-message--');
    
      __out.push(__sanitize(this.from));
    
      __out.push(__sanitize(this.unreadClass));
    
      __out.push('"');
    
      if (this.id) {
        __out.push(' data-message-id="');
        __out.push(__sanitize(this.id));
        __out.push('"');
      }
    
      __out.push('>\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body zammad-chat-attachment"><span class="zammad-chat-attachment-row"><span class="zammad-chat-attachment-icon"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M15.8 2.21c-.41-.41-1.12-.13-1.12.44v3.49c0 1.46 1.24 2.67 2.75 2.67.95.01 2.27.01 3.4.01.57 0 .87-.67.47-1.07-1.44-1.45-4.02-4.06-5.5-5.54Z"/><path d="M20.5 10.19h-2.89c-2.37 0-4.3-1.93-4.3-4.3V3c0-.55-.45-1-1-1H8.07C4.99 2 2.5 4 2.5 7.57v8.86C2.5 20 4.99 22 8.07 22h7.86c3.08 0 5.57-2 5.57-5.57v-5.24c0-.55-.45-1-1-1Zm-9 7.56h-4c-.41 0-.75-.34-.75-.75s.34-.75.75-.75h4c.41 0 .75.34.75.75s-.34.75-.75.75Zm2-4h-6c-.41 0-.75-.34-.75-.75s.34-.75.75-.75h6c.41 0 .75.34.75.75s-.34.75-.75.75Z"/></svg></span><span class="zammad-chat-attachment-info"><span class="zammad-chat-attachment-filename">');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('</span>');
    
      if (this.metaLabel) {
        __out.push('<span class="zammad-chat-attachment-meta">');
        __out.push(__sanitize(this.metaLabel));
        __out.push('</span>');
      }
    
      __out.push('</span><a href="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('?disposition=attachment" download="');
    
      __out.push(this.filename);
    
      __out.push('" class="zammad-chat-attachment-download js-attachment-download" target="_blank" rel="noopener" aria-label="');
    
      __out.push(this.T('Download'));
    
      __out.push('"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M15.2605 22.25H8.74047C3.83047 22.25 1.73047 20.15 1.73047 15.24V15.11C1.73047 10.67 3.48047 8.53003 7.40047 8.16003C7.80047 8.13003 8.18047 8.43003 8.22047 8.84003C8.26047 9.25003 7.96047 9.62003 7.54047 9.66003C4.40047 9.95003 3.23047 11.43 3.23047 15.12V15.25C3.23047 19.32 4.67047 20.76 8.74047 20.76H15.2605C19.3305 20.76 20.7705 19.32 20.7705 15.25V15.12C20.7705 11.41 19.5805 9.93003 16.3805 9.66003C15.9705 9.62003 15.6605 9.26003 15.7005 8.85003C15.7405 8.44003 16.0905 8.13003 16.5105 8.17003C20.4905 8.51003 22.2705 10.66 22.2705 15.13V15.26C22.2705 20.15 20.1705 22.25 15.2605 22.25Z"/><path d="M12 15.63C11.59 15.63 11.25 15.29 11.25 14.88V2C11.25 1.59 11.59 1.25 12 1.25C12.41 1.25 12.75 1.59 12.75 2V14.88C12.75 15.3 12.41 15.63 12 15.63Z"/><path d="M11.9998 16.7501C11.8098 16.7501 11.6198 16.6801 11.4698 16.5301L8.11984 13.1801C7.82984 12.8901 7.82984 12.4101 8.11984 12.1201C8.40984 11.8301 8.88984 11.8301 9.17984 12.1201L11.9998 14.9401L14.8198 12.1201C15.1098 11.8301 15.5898 11.8301 15.8798 12.1201C16.1698 12.4101 16.1698 12.8901 15.8798 13.1801L12.5298 16.5301C12.3798 16.6801 12.1898 16.7501 11.9998 16.7501Z"/></svg></a></span><span class="zammad-chat-message-time">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M0.41,13.41L6,19L7.41,17.58L1.83,12M22.24,5.58L11.66,16.17L7.5,12L6.07,13.41L11.66,19L23.66,7M18,7L16.59,5.58L10.24,11.93L11.66,13.34L18,7Z"/></svg></span>');
      }
    
      __out.push('</span></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M7.13 18.31h8c2.76 0 5-2.24 5-5s-2.24-5-5-5h-11"/><path d="M6.43 10.81L3.87 8.25l2.56-2.56"/></svg></button>');
      }
    
      __out.push('</span>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["chat"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat');
    
      if (this.flat) {
        __out.push(__sanitize(' zammad-chat--flat'));
      }
    
      __out.push('"');
    
      if (this.fontSize) {
        __out.push(__sanitize(" style='font-size: " + this.fontSize + "'"));
      }
    
      __out.push('>\n  <div class="zammad-chat-header">\n    <div class="zammad-chat-agent zammad-chat-is-hidden">\n    </div>\n    <div class="zammad-chat-welcome">\n      <span class="zammad-chat-welcome-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_home_greeting'] || 'Hi there'));
    
      __out.push(' 👋</span>\n      <span class="zammad-chat-welcome-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_home_subtitle'] || 'How can we help you today?'));
    
      __out.push('</span>\n    </div>\n    <div class="zammad-chat-header-title zammad-chat-is-hidden"><span class="js-header-title-text"></span></div>\n    <div class="zammad-chat-header-controls">\n      <button type="button" class="zammad-chat-header-icon zammad-chat-header-icon-minimize js-chat-minimize" aria-label="');
    
      __out.push(this.T('Minimize'));
    
      __out.push('">\n        <svg width="17" height="17" viewBox="0 0 24 24" fill="currentColor"><path d="M17.919 8.18H6.079c-.96 0-1.44 1.16-.76 1.84l5.18 5.18c.83.83 2.18.83 3.01 0l1.97-1.97 3.21-3.21c.67-.68.19-1.84-.77-1.84z"/></svg>\n      </button>\n      <button type="button" class="zammad-chat-header-icon js-chat-close" aria-label="');
    
      __out.push(this.T('End chat'));
    
      __out.push('">\n        <svg class="zammad-chat-header-icon-close" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" style="transform: rotate(45deg)"><path d="M6 12h12M12 18V6"/></svg>\n      </button>\n    </div>\n  </div>\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--home is-active"></div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--messages">\n    <div class="zammad-chat-modal"></div>\n    <div class="zammad-scroll-hint is-hidden">\n      <svg class="zammad-scroll-hint-icon" width="20" height="18" viewBox="0 0 20 18"><path d="M0,2.00585866 C0,0.898053512 0.898212381,0 1.99079514,0 L18.0092049,0 C19.1086907,0 20,0.897060126 20,2.00585866 L20,11.9941413 C20,13.1019465 19.1017876,14 18.0092049,14 L1.99079514,14 C0.891309342,14 0,13.1029399 0,11.9941413 L0,2.00585866 Z M10,14 L16,18 L16,14 L10,14 Z" fill-rule="evenodd"/></svg>\n      ');
    
      __out.push(this.T(this.scrollHint));
    
      __out.push('\n    </div>\n    <div class="zammad-chat-body"></div>\n    <div class="zammad-chat-reply-indicator js-reply-indicator zammad-chat-is-hidden"></div>\n    <form class="zammad-chat-controls">\n      <div class="zammad-chat-emoji-picker js-emoji-picker zammad-chat-is-hidden"></div>\n      <div class="zammad-chat-input" rows="1" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
    
      __out.push('" contenteditable="true"></div>\n      <div class="zammad-chat-controls-icons">\n        <div class="zammad-chat-emoji-toggle js-emoji-toggle">\n          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M9 22h6c5 0 7-2 7-7V9c0-5-2-7-7-7H9C4 2 2 4 2 9v6c0 5 2 7 7 7Z"/><path d="M15.5 9.75a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3ZM8.5 9.75a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3ZM8.4 13.3h7.2c.5 0 .9.4.9.9 0 2.49-2.01 4.5-4.5 4.5s-4.5-2.01-4.5-4.5c0-.5.4-.9.9-.9Z"/></svg>\n        </div>\n        <div class="zammad-chat-attach js-chat-attach zammad-chat-is-hidden">\n          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11.97 12v3.5c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5V10c0-3.87-3.13-7-7-7s-7 3.13-7 7v6c0 3.31 2.69 6 6 6"/></svg>\n        </div>\n        <input type="file" class="js-chat-attachment-input zammad-chat-is-hidden">\n        <button type="submit" class="zammad-chat-send" aria-label="');
    
      __out.push(this.T('Send'));
    
      __out.push('"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>\n          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m9.51 4.23 8.56 4.28c3.84 1.92 3.84 5.06 0 6.98l-8.56 4.28c-5.76 2.88-8.11.52-5.23-5.23l.87-1.73c.22-.44.22-1.17 0-1.61l-.87-1.74C1.4 3.71 3.76 1.35 9.51 4.23ZM5.44 12h5.4"/></svg>\n        </button>\n      </div>\n    </form>\n  </div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--help"></div>\n\n  <div class="zammad-chat-tabbar"></div>\n\n  <!-- Atas permintaan user (mockup "SISKA Widget Mockup" -- board\n  IndicatorReconnecting/Restored/Lost): indikator fullpage\n  semi-transparan status koneksi WebSocket widget sendiri, menutupi\n  seluruh panel (isi disuntik dinamis oleh `showConnectionOverlay()`,\n  lihat `connection_overlay.eco`). -->\n  <div class="zammad-chat-connection-overlay js-connection-overlay zammad-chat-is-hidden"></div>\n\n  <!-- Atas permintaan user: layar "Terima kasih" SETELAH submit\n  feedback (rating-nya sendiri sekarang inline di `.zammad-chat-body`,\n  lihat `showFeedback`) tetap fullpage -- container TERPISAH dari\n  overlay koneksi di atas (semantik beda, sengaja tidak dicampur),\n  gaya visual scrim sama (lihat `chat.scss`). Isi disuntik dinamis\n  oleh `showFeedbackThanks()`. -->\n  <div class="zammad-chat-feedback-thanks-overlay js-feedback-thanks-overlay zammad-chat-is-hidden"></div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["connection_overlay"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      if (this.state === 'reconnecting') {
        __out.push('\n  <div class="zammad-chat-connection-overlay-spinner">\n    <svg viewBox="0 0 44 44" width="56" height="56" xmlns="http://www.w3.org/2000/svg">\n      <circle class="zammad-chat-pc-track" cx="22" cy="22" r="20" fill="none" stroke-width="4"></circle>\n      <circle class="zammad-chat-pc-arc" cx="22" cy="22" r="20" fill="none" stroke-width="4" stroke-dasharray="125.6" stroke-dashoffset="0"></circle>\n    </svg>\n  </div>\n');
      } else if (this.state === 'restored') {
        __out.push('\n  <div class="zammad-chat-connection-overlay-icon">\n    <svg width="56" height="56" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.49 2 2 6.49 2 12C2 17.51 6.49 22 12 22C17.51 22 22 17.51 22 12C22 6.49 17.51 2 12 2ZM16.78 9.7L11.11 15.37C10.97 15.51 10.78 15.59 10.58 15.59C10.38 15.59 10.19 15.51 10.05 15.37L7.22 12.54C6.93 12.25 6.93 11.77 7.22 11.48C7.51 11.19 7.99 11.19 8.28 11.48L10.58 13.78L15.72 8.64C16.01 8.35 16.49 8.35 16.78 8.64C17.07 8.93 17.07 9.4 16.78 9.7Z"></path></svg>\n  </div>\n');
      } else {
        __out.push('\n  <div class="zammad-chat-connection-overlay-icon">\n    <svg width="56" height="56" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg"><path d="M12 2C6.49 2 2 6.49 2 12s4.49 10 10 10 10-4.49 10-10S17.51 2 12 2Zm3.36 12.3c.29.29.29.77 0 1.06-.15.15-.34.22-.53.22s-.38-.07-.53-.22l-2.3-2.3-2.3 2.3c-.15.15-.34.22-.53.22s-.38-.07-.53-.22a.754.754 0 0 1 0-1.06l2.3-2.3-2.3-2.3a.754.754 0 0 1 0-1.06c.29-.29.77-.29 1.06 0l2.3 2.3 2.3-2.3c.29-.29.77-.29 1.06 0 .29.29.29.77 0 1.06l-2.3 2.3 2.3 2.3Z"></path></svg>\n  </div>\n');
      }
    
      __out.push('\n\n<div class="zammad-chat-connection-overlay-title">');
    
      __out.push(this.title);
    
      __out.push('</div>\n');
    
      if (this.subtitle) {
        __out.push('\n  <div class="zammad-chat-connection-overlay-subtitle">');
        __out.push(this.subtitle);
        __out.push('</div>\n');
      }
    
      __out.push('\n');
    
      if (this.state === 'lost') {
        __out.push('\n  <button type="button" class="zammad-chat-connection-overlay-reload js-connection-reload">');
        __out.push(this.T('Reload page'));
        __out.push('</button>\n');
      }
    
      __out.push('\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["customer_timeout"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-modal-text">\n  ');
    
      if (this.agent) {
        __out.push('\n    ');
        __out.push(this.T(this.phrases['chat_phrase_customer_timeout_with_agent'] || 'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.', this.delay, this.agent));
        __out.push('\n  ');
      } else {
        __out.push('\n    ');
        __out.push(this.T(this.phrases['chat_phrase_customer_timeout'] || 'Since you didn\'t respond in the last %s minutes your conversation was closed.', this.delay));
        __out.push('\n  ');
      }
    
      __out.push('\n  <br>\n  <button type="button" class="zammad-chat-timeout-restart js-restart"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
      __out.push(this.T(this.phrases['chat_phrase_restart_button'] || 'Start new conversation'));
    
      __out.push('</button>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["emoji_picker"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-emoji-picker-title">');
    
      __out.push(this.T('Emoji'));
    
      __out.push('</div>\n<div class="zammad-chat-emoji-picker-grid">\n  <span class="js-emoji-item" data-emoji="😀">😀</span>\n  <span class="js-emoji-item" data-emoji="😂">😂</span>\n  <span class="js-emoji-item" data-emoji="😍">😍</span>\n  <span class="js-emoji-item" data-emoji="😊">😊</span>\n  <span class="js-emoji-item" data-emoji="🙏">🙏</span>\n  <span class="js-emoji-item" data-emoji="👍">👍</span>\n  <span class="js-emoji-item" data-emoji="👋">👋</span>\n  <span class="js-emoji-item" data-emoji="❤️">❤️</span>\n  <span class="js-emoji-item" data-emoji="😢">😢</span>\n  <span class="js-emoji-item" data-emoji="😮">😮</span>\n  <span class="js-emoji-item" data-emoji="🎉">🎉</span>\n  <span class="js-emoji-item" data-emoji="🔥">🔥</span>\n  <span class="js-emoji-item" data-emoji="✅">✅</span>\n  <span class="js-emoji-item" data-emoji="💡">💡</span>\n  <span class="js-emoji-item" data-emoji="🤔">🤔</span>\n  <span class="js-emoji-item" data-emoji="👌">👌</span>\n  <span class="js-emoji-item" data-emoji="🙌">🙌</span>\n  <span class="js-emoji-item" data-emoji="😎">😎</span>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["ending_chat"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Audit kit Able Pro TAILWIND baru -- lihat catatan sama di\n  waiting.eco, modifier warna via `--danger` (chat.scss). -->\n  <div class="zammad-chat-waiting-spinner zammad-chat-waiting-spinner--danger"></div>\n  <div class="zammad-chat-waiting-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_ending_title'] || 'Ending conversation…'));
    
      __out.push('</div>\n  <div class="zammad-chat-waiting-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_ending_subtitle'] || 'Please wait a moment.'));
    
      __out.push('</div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["feedback_thanks"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-feedback-thanks">\n  <div class="zammad-chat-feedback-thanks-icon">\n    <svg width="30" height="30" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.49 2 2 6.49 2 12C2 17.51 6.49 22 12 22C17.51 22 22 17.51 22 12C22 6.49 17.51 2 12 2ZM16.78 9.7L11.11 15.37C10.97 15.51 10.78 15.59 10.58 15.59C10.38 15.59 10.19 15.51 10.05 15.37L7.22 12.54C6.93 12.25 6.93 11.77 7.22 11.48C7.51 11.19 7.99 11.19 8.28 11.48L10.58 13.78L15.72 8.64C16.01 8.35 16.49 8.35 16.78 8.64C17.07 8.93 17.07 9.4 16.78 9.7Z"/></svg>\n  </div>\n  <div class="zammad-chat-feedback-thanks-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_thanks_title'] || 'Thank you for your feedback!'));
    
      __out.push('</div>\n  <div class="zammad-chat-feedback-thanks-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_thanks_subtitle'] || 'We appreciate you taking the time.'));
    
      __out.push('</div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["feedback"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-feedback">\n  <div class="zammad-chat-feedback-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_title'] || 'How was your experience?'));
    
      __out.push('</div>\n  <div class="zammad-chat-feedback-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_subtitle'] || 'Your feedback helps us improve.'));
    
      __out.push('</div>\n\n  <div class="zammad-chat-feedback-stars">\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="1" aria-label="1"><svg class="zammad-chat-feedback-star-empty" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,15.39L8.24,17.66L9.23,13.38L5.91,10.5L10.29,10.13L12,6.09L13.71,10.13L18.09,10.5L14.77,13.38L15.76,17.66M22,9.24L14.81,8.63L12,2L9.19,8.63L2,9.24L7.45,13.97L5.82,21L12,17.27L18.18,21L16.54,13.97L22,9.24Z"/></svg><svg class="zammad-chat-feedback-star-filled" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="2" aria-label="2"><svg class="zammad-chat-feedback-star-empty" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,15.39L8.24,17.66L9.23,13.38L5.91,10.5L10.29,10.13L12,6.09L13.71,10.13L18.09,10.5L14.77,13.38L15.76,17.66M22,9.24L14.81,8.63L12,2L9.19,8.63L2,9.24L7.45,13.97L5.82,21L12,17.27L18.18,21L16.54,13.97L22,9.24Z"/></svg><svg class="zammad-chat-feedback-star-filled" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="3" aria-label="3"><svg class="zammad-chat-feedback-star-empty" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,15.39L8.24,17.66L9.23,13.38L5.91,10.5L10.29,10.13L12,6.09L13.71,10.13L18.09,10.5L14.77,13.38L15.76,17.66M22,9.24L14.81,8.63L12,2L9.19,8.63L2,9.24L7.45,13.97L5.82,21L12,17.27L18.18,21L16.54,13.97L22,9.24Z"/></svg><svg class="zammad-chat-feedback-star-filled" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="4" aria-label="4"><svg class="zammad-chat-feedback-star-empty" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,15.39L8.24,17.66L9.23,13.38L5.91,10.5L10.29,10.13L12,6.09L13.71,10.13L18.09,10.5L14.77,13.38L15.76,17.66M22,9.24L14.81,8.63L12,2L9.19,8.63L2,9.24L7.45,13.97L5.82,21L12,17.27L18.18,21L16.54,13.97L22,9.24Z"/></svg><svg class="zammad-chat-feedback-star-filled" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="5" aria-label="5"><svg class="zammad-chat-feedback-star-empty" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,15.39L8.24,17.66L9.23,13.38L5.91,10.5L10.29,10.13L12,6.09L13.71,10.13L18.09,10.5L14.77,13.38L15.76,17.66M22,9.24L14.81,8.63L12,2L9.19,8.63L2,9.24L7.45,13.97L5.82,21L12,17.27L18.18,21L16.54,13.97L22,9.24Z"/></svg><svg class="zammad-chat-feedback-star-filled" width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12,17.27L18.18,21L16.54,13.97L22,9.24L14.81,8.62L12,2L9.19,8.62L2,9.24L7.45,13.97L5.82,21L12,17.27Z"/></svg></button>\n  </div>\n\n  <textarea class="zammad-chat-feedback-textarea js-feedback-comment" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_comment_placeholder'] || 'Add a comment (optional)'));
    
      __out.push('"></textarea>\n\n  <div class="zammad-chat-feedback-error js-feedback-error zammad-chat-is-hidden"></div>\n\n  <div class="zammad-chat-feedback-actions">\n    <button type="button" class="zammad-chat-feedback-skip js-feedback-skip">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_skip_button'] || 'Maybe later'));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-submit js-feedback-submit">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_submit_button'] || 'Submit'));
    
      __out.push('</button>\n  </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["help"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-help">\n  <div class="zammad-chat-help-search-wrap">\n    <svg class="zammad-chat-help-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M11.5 21.75C5.85 21.75 1.25 17.15 1.25 11.5C1.25 5.85 5.85 1.25 11.5 1.25C17.15 1.25 21.75 5.85 21.75 11.5C21.75 17.15 17.15 21.75 11.5 21.75ZM11.5 2.75C6.67 2.75 2.75 6.68 2.75 11.5C2.75 16.32 6.67 20.25 11.5 20.25C16.33 20.25 20.25 16.32 20.25 11.5C20.25 6.68 16.33 2.75 11.5 2.75Z"/><path d="M22.0004 22.7499C21.8104 22.7499 21.6204 22.6799 21.4704 22.5299L19.4704 20.5299C19.1804 20.2399 19.1804 19.7599 19.4704 19.4699C19.7604 19.1799 20.2404 19.1799 20.5304 19.4699L22.5304 21.4699C22.8204 21.7599 22.8204 22.2399 22.5304 22.5299C22.3804 22.6799 22.1904 22.7499 22.0004 22.7499Z"/></svg>\n    <input type="text" class="zammad-chat-help-search js-kb-search" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_home_search_button'] || 'Search for help'));
    
      __out.push('">\n  </div>\n  <ul class="zammad-chat-kb-results"></ul>\n  <p class="zammad-chat-kb-empty zammad-chat-is-hidden">');
    
      __out.push(this.T(this.phrases['chat_phrase_help_no_results'] || 'No results found.'));
    
      __out.push('</p>\n  <!-- Atas permintaan user: daftar artikel dimuat lewat scroll\n  (bukan tombol/nomor halaman) -- indikator ini muncul di dasar\n  daftar SELAMA halaman berikutnya sedang diambil. Pola animasi\n  SAMA persis dgn indikator "agent sedang mengetik"\n  (`views/typingIndicator.eco`), dipakai ulang bukan dibuat baru. -->\n  <div class="zammad-chat-kb-loading zammad-chat-is-hidden">\n    <span class="zammad-chat-loading-animation"><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span></span>\n  </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["home"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-home">\n  <!-- Atas permintaan user ("rubah total Home dan OfflineHome") --\n  ikon bubble chat lama (dari sprite kit VUE) diganti `custom-message-2`,\n  yang GENUINELY ada di sprite "custom" kit Tailwind baru sendiri\n  (`dist/assets/js/icon/custom-font.js`, bukan Tabler kali ini --\n  ikon ini kebetulan SUDAH tersedia asli di kit ini, prioritas 1\n  dibanding cari padanan Tabler). Duotone SENGAJA dipertahankan\n  (`opacity="0.4"` di path pertama) -- gaya asli ikon ini di kit\n  Tailwind (beda dari mayoritas ikon widget lain yang flat 1 opacity),\n  BUKAN kesalahan/disederhanakan. Ukuran badge (52px) & radius\n  (`$siska-radius-lg`=12px) TETAP -- dicek ULANG ke preseden NYATA kit\n  baru (`w_chart.html`: `.w-10.h-10.rounded-xl` = ikon-dlm-kotak,\n  radius `rounded-xl`=12px SAMA PERSIS) -- cuma radiusnya yang\n  terverifikasi identik, ukuran 52px & background SOLID (bukan tint\n  10%) tetap dipertahankan sengaja krn ini logo BRANDING hero (satu-\n  satunya elemen dominan halaman), bukan ikon aksen kecil di kartu\n  dashboard -- preseden itu tidak berlaku sama utk konteks beda ini. -->\n  <div class="zammad-chat-home-logo">\n    <div class="zammad-chat-home-logo-mark">\n      <svg width="26" height="26" viewBox="0 0 24 24"><path opacity="0.4" d="M7 18.4302H11L15.45 21.3902C16.11 21.8302 17 21.3602 17 20.5602V18.4302C20 18.4302 22 16.4302 22 13.4302V7.43018C22 4.43018 20 2.43018 17 2.43018H7C4 2.43018 2 4.43018 2 7.43018V13.4302C2 16.4302 4 18.4302 7 18.4302Z" fill="currentColor"/><path d="M15.5 11.25H8.5C8.09 11.25 7.75 10.91 7.75 10.5C7.75 10.09 8.09 9.75 8.5 9.75H15.5C15.91 9.75 16.25 10.09 16.25 10.5C16.25 10.91 15.91 11.25 15.5 11.25Z" fill="currentColor"/></svg>\n    </div>\n  </div>\n\n  <!-- Enhancement 1 -- Tahap 3 (Offline Message + OTP), mockup OfflineHome.dc.html.\n  Tersembunyi default -- ditampilkan lewat `enterOfflineMode()` (chat.coffee)\n  begitu `chat_status_customer` balas state \'offline\' (SEMUA agent tidak\n  tersedia, termasuk yg lagi AUX -- lihat entri 143). -->\n  <!-- Atas permintaan user (audit kit Able Pro TAILWIND baru, HANYA\n  Home/OfflineHome): pola alert diganti ke `.alert-warning` GENUINE\n  kit baru (lihat chat.scss), teks tetap 1 baris (judul+deskripsi\n  digabung, kedua Setting tetap dipakai). Ikon `custom-warning-fill`\n  LAMA (sprite kit VUE) TIDAK ADA padanannya di kit Tailwind baru --\n  diganti path `alert-triangle` Tabler Icons (dipilih user), diekstrak\n  LANGSUNG dari glyph SVG font kit ini\n  (`assets/fonts/tabler/tabler-icons.svg`, glyph-name="alert-triangle",\n  unicode \\ea06) -- BUKAN digambar ulang manual/ditebak. Koordinat\n  glyph font di-flip vertikal (`scale(1,-1) translate(0,-986.5)`,\n  986.5 = ascent font ini) krn sistem koordinat SVG font terbalik dari\n  SVG biasa -- hasil render dikonfirmasi tegak lewat `rsvg-convert`\n  sebelum dipakai di sini. -->\n  <div class="zammad-chat-home-offline-notice zammad-chat-is-hidden">\n    <svg class="zammad-chat-home-offline-notice-icon" width="20" height="20" viewBox="0 0 1010 986.5" fill="currentColor"><g transform="scale(1,-1) translate(0,-986.5)"><path d="M508 818C563.386 818 598.068 788.886 619 754C634.577 728.04 904.693 261.6120000000001 918 235C924.652 221.694 925 214.2000000000001 925 192C925 141.04 903.451 112.088 874 90C860.403 79.803 842.976 72.995 823 69C815 68 780 67 509 67C236 67 203 68 196 69C135.622 81.0750000000001 93 123.586 93 196C93 219.963 99.464 232.928 108 250C108.083 250.165 406.993 763.988 407 764C413.665 775.107 427.904 789.343 439 796C457.02 806.813 478.581 818 508 818zM515 734H504C496.24 734 484.625 726.625 480 722C472.12 714.12 184.16 212.24 180 206C177 201 177 199 177 190C177 168.735 191.042 157.3200000000001 207 152C212 151 245 150 509 150C705 150 807 150 810 151C825.843 158.92 848.593 171.63 842 198C839.872 210.7670000000001 544.6890000000001 716.311 539 722C534.01 726.99 523.65 734 515 734zM509 567C532.466 567 544.995 551.015 551 533C552 530 552 513 552 484C552 444.207 552.282 438.848 547 423C542.719 410.155 526.815 400 510 400C485.452 400 475.161 415.517 469 434C468 437 468 458 468 484C468 513 468 530 469 533C474.66 549.981 486.697 567 509 567zM509 317C485.564 317 463.687 294.564 469 268C473.813 248.751 485.473 234 510 234C534.6 234 546.07 248.28 551 268C556.251 294.257 537.382 309.54 518 316C515 317 511 317 509 317z"/></g></svg>\n    <span class="zammad-chat-home-offline-notice-text">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_notice_title'] || 'All agents are currently unavailable'));
    
      __out.push(' ');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_notice'] || 'Leave your message and email, we will verify it via an OTP code and reply as soon as possible.'));
    
      __out.push('</span>\n  </div>\n\n  <!-- Notice agent online -- pola SAMA (audit kit Tailwind baru,\n  `.alert-info`). Ikon `info-circle` Tabler (dipilih user), diekstrak\n  & diverifikasi render dgn cara SAMA persis spt alert-triangle di\n  atas (unicode \\eac5). -->\n  <div class="zammad-chat-home-online-notice zammad-chat-is-hidden">\n    <svg class="zammad-chat-home-online-notice-icon" width="20" height="20" viewBox="0 0 1010 986.5" fill="currentColor"><g transform="scale(1,-1) translate(0,-986.5)"><path d="M518 816C572.269 816 607.844 805.045 650 793C676.847 785.33 706.197 769.535 728 755C734 751 745 745 752 740C780.122 719.913 807.295 693.49 830 667C875.205 614.26 904.582 551.09 921 469C926.277 442.611 926 432.576 926 400C926 322.915 909.682 261.192 881 211C877 204 872 192 868 186C852.258 162.387 836.235 137.235 816 117L793 94C772.79 73.79 747.842 57.895 724 42C718 38 706 33 699 29C656.655 4.803 606.866 -6.59 548 -15C541 -16 525 -16 510 -16C366.081 -16 276.3590000000001 44.64 204 117C190.573 130.427 177.435 148.348 167 164C124.516 227.727 93 304.861 93 412C93 442.781 96.97 460.87 103 488C125.691 590.112 175.576 662.208 243 720C265.945 739.667 288.82 755.91 317 770C357.559 790.28 404.55 806.364 458 814C465 815 476 816 483 816H518zM508 733C498 733 486 732 480 732C445.876 732 414.148 719.05 387 710C359.568 700.856 326.9220000000001 678.691 306 663C275.306 639.98 248.682 608.523 227 576C218.048 562.571 207.325 541.976 202 526C200 520 195 510 193 503C184.175 472.112 177 440.455 177 400C177 358.895 182.469 326.749 194 296C206.502 262.6620000000001 218.494 231.6320000000001 239 206C249.21 193.237 254.906 186.312 266 173C276.0950000000001 160.886 294.086 145.936 306 137C329.615 119.29 364.361 99.702 394 87C401 84 413 82 419 80C432.854 75.382 451.407 72.5990000000001 467 70C473 69 488 67 500 67C535.335 67 560.567 68.162 588 76C595 78 606 81 613 83S630 90 636 92C660.179 100.06 685.883 114.506 704 129C727.81 148.049 753.273 169.031 772 194C789.798 217.73 810.505 254.8450000000001 823 284C826 291 828 303 830 309C840.242 339.727 842 356.197 842 400C842 444.112 840.332 460.005 830 491C828 497 826 509 823 516C809.96 546.428 790.923 580.1030000000001 773 604C749.98 634.694 718.523 661.318 686 683C672.571 691.952 651.976 702.675 636 708C630 710 620 715 613 717C581.318 726.052 549.749 733 508 733zM512 608C535.563 608 552 590.338 552 567C552 542.79 534.867 526 510 526C485.4 526 473.93 540.28 469 560C466.16 574.2 471.856 586.856 479 594C487.697 602.697 493.958 608 512 608zM488 442C451.182 442 443.8160000000001 437.724 430 417C427 412 428 411 428 400C428 383.526 429.629 380.371 438 372C446.073 363.927 454.126 360.312 468 358V294C468 225.2100000000001 466.814 234.558 474 213C476.994 204.018 490.36 196.584 498 192H562C577.974 201.1280000000001 592 208.35 592 234C592 248.135 590.523 252.477 584 259C577.47 265.53 567.875 275 555 275H552V339C552 383 552 404 551 408C541.555 436.336 528.73 442 488 442z"/></g></svg>\n    <span class="zammad-chat-home-online-notice-text">');
    
      __out.push(this.T(this.phrases['chat_phrase_home_online_notice'] || "Agents are online now — start a conversation and we'll respond right away."));
    
      __out.push('</span>\n  </div>\n\n  <div class="zammad-chat-home-actions">\n    <!-- Atas permintaan user ("hilangkan icon pada button Leave\n    us.../Send us..."): KEDUA ikon (online & offline) dihapus dari\n    markup -- toggle visibilitasnya di `applyOfflineHomeState`\n    (chat.coffee/chat-no-jquery.coffee) ikut dihapus, TIDAK cuma\n    disembunyikan CSS. Pergantian LABEL teks ("Send us a\n    message"/"Leave us a message") TETAP jalan, itu bukan ikon. -->\n    <button type="button" class="zammad-chat-home-action js-home-start-action" data-tab="messages">\n      <span class="js-home-start-label">');
    
      __out.push(this.T(this.phrases['chat_phrase_home_start_button'] || 'Send us a message'));
    
      __out.push('</span>\n    </button>\n    <button type="button" class="zammad-chat-home-action zammad-chat-home-action--secondary" data-tab="help">\n      <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_home_search_button'] || 'Search for help'));
    
      __out.push('</span>\n    </button>\n  </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["kb_result"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<li class="zammad-chat-kb-result">\n  <a href="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('" target="_blank" rel="noopener noreferrer" class="zammad-chat-kb-result-link">\n    <span class="zammad-chat-kb-result-icon">\n      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 7v10c0 3-1.5 5-5 5H8c-3.5 0-5-2-5-5V7c0-3 1.5-5 5-5h8c3.5 0 5 2 5 5Z"/><path d="M14.5 4.5v2c0 1.1.9 2 2 2h2M8 13h4M8 17h8"/></svg>\n    </span>\n    <span class="zammad-chat-kb-result-text">\n      <span class="zammad-chat-kb-result-title">');
    
      __out.push(this.title);
    
      __out.push('</span>\n      <span class="zammad-chat-kb-result-body">');
    
      __out.push(this.body);
    
      __out.push('</span>\n    </span>\n    <svg class="zammad-chat-kb-result-chevron" width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 9.33v5.34c0 3.32 2.35 4.67 5.22 3.02l1.28-.74c.31-.18.5-.51.5-.87V7.92c0-.36-.19-.69-.5-.87l-1.28-.74C8.35 4.66 6 6.01 6 9.33z"/><path d="M14 8.79v6.43c0 .39.42.63.75.43l1.1-.64c2.87-1.65 2.87-4.37 0-6.02l-1.1-.64a.503.503 0 00-.75.44z" opacity=".4"/></svg>\n  </a>\n</li>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["launcher"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-launcher">\n  <svg class="zammad-chat-launcher-icon-open" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22.81C11.31 22.81 10.66 22.46 10.2 21.85L8.7 19.85C8.67 19.81 8.55 19.76 8.5 19.75H8C3.83 19.75 1.25 18.62 1.25 13V8C1.25 3.58 3.58 1.25 8 1.25H16C20.42 1.25 22.75 3.58 22.75 8V13C22.75 17.42 20.42 19.75 16 19.75H15.5C15.42 19.75 15.35 19.79 15.3 19.85L13.8 21.85C13.34 22.46 12.69 22.81 12 22.81ZM8 2.75C4.42 2.75 2.75 4.42 2.75 8V13C2.75 17.52 4.3 18.25 8 18.25H8.5C9.01 18.25 9.59 18.54 9.9 18.95L11.4 20.95C11.75 21.41 12.25 21.41 12.6 20.95L14.1 18.95C14.43 18.51 14.95 18.25 15.5 18.25H16C19.58 18.25 21.25 16.58 21.25 13V8C21.25 4.42 19.58 2.75 16 2.75H8Z"/><path d="M17 8.75H7C6.59 8.75 6.25 8.41 6.25 8C6.25 7.59 6.59 7.25 7 7.25H17C17.41 7.25 17.75 7.59 17.75 8C17.75 8.41 17.41 8.75 17 8.75Z"/><path d="M13 13.75H7C6.59 13.75 6.25 13.41 6.25 13C6.25 12.59 6.59 12.25 7 12.25H13C13.41 12.25 13.75 12.59 13.75 13C13.75 13.41 13.41 13.75 13 13.75Z"/></svg>\n  <svg class="zammad-chat-launcher-icon-close" width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M17.919 8.18H6.079c-.96 0-1.44 1.16-.76 1.84l5.18 5.18c.83.83 2.18.83 3.01 0l1.97-1.97 3.21-3.21c.67-.68.19-1.84-.77-1.84z"/></svg>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["loader"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Audit kit Able Pro TAILWIND baru -- lihat catatan sama di\n  waiting.eco. -->\n  <div class="zammad-chat-waiting-spinner"></div>\n  <div class="zammad-chat-waiting-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_title'] || 'Connecting you to an agent…'));
    
      __out.push('</div>\n  <button type="button" class="zammad-chat-waiting-cancel js-waiting-cancel">');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_cancel_button'] || 'Cancel'));
    
      __out.push('</button>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["message"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-message zammad-chat-message--');
    
      __out.push(__sanitize(this.from));
    
      __out.push(__sanitize(this.unreadClass));
    
      __out.push('"');
    
      if (this.id) {
        __out.push(' data-message-id="');
        __out.push(__sanitize(this.id));
        __out.push('"');
      }
    
      __out.push('>\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body"');
    
      if (this.background && this.from === 'customer') {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
      if (this.replyTo) {
        __out.push('<span class="zammad-chat-message-quote">');
        __out.push(__sanitize(this.replyTo.substr(0, 80)));
        __out.push('</span>');
      }
    
      __out.push(this.message);
    
      __out.push('<span class="zammad-chat-message-time">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M0.41,13.41L6,19L7.41,17.58L1.83,12M22.24,5.58L11.66,16.17L7.5,12L6.07,13.41L11.66,19L23.66,7M18,7L16.59,5.58L10.24,11.93L11.66,13.34L18,7Z"/></svg></span>');
      }
    
      __out.push('</span></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M7.13 18.31h8c2.76 0 5-2.24 5-5s-2.24-5-5-5h-11"/><path d="M6.43 10.81L3.87 8.25l2.56-2.56"/></svg></button>');
      }
    
      __out.push('</span>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["offline_compose"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-offline-compose">\n  <div class="zammad-chat-offline-compose-verified">\n    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="m7.75 12 2.83 2.83 5.67-5.66"/></svg>\n    <span><strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong> ');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_verified_suffix'] || 'verified'));
    
      __out.push('</span>\n  </div>\n\n  <!-- Atas permintaan user ("saya mau menambahkan subject, dan subject\n  ini mandatory") -- subject WAJIB diisi (divalidasi frontend & backend,\n  lihat `submitOfflineMessage`/`chat_offline_message_send.rb`), dipakai\n  jadi JUDUL tiket yang dibuat otomatis (bukan lagi "Live Chat -\n  [nama]" generik, lihat `Chat::Session#create_ticket_for_chat!`). -->\n  <label class="zammad-chat-offline-compose-label">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_subject_label'] || 'Subject'));
    
      __out.push('</label>\n  <input type="text" class="zammad-chat-offline-compose-subject-input js-offline-subject" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_subject_placeholder'] || "What's this about?"));
    
      __out.push('">\n\n  <label class="zammad-chat-offline-compose-label zammad-chat-offline-compose-label--spaced">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_message_label'] || 'Your message'));
    
      __out.push('</label>\n  <textarea class="zammad-chat-offline-compose-textarea js-offline-message" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_placeholder'] || 'Tell us how we can help…'));
    
      __out.push('"></textarea>\n\n  <div class="zammad-chat-offline-compose-error js-offline-compose-error zammad-chat-is-hidden"></div>\n\n  <!-- Item lampiran (follow-up terpisah dari Enhancement 4 awal).\n  Diisi dinamis lewat JS (`onOfflineAttachmentUploaded`) -- kosong\n  by default, TIDAK ADA tombol hapus (endpoint DELETE tidak ada di\n  manapun di codebase ini, konsisten dgn attachment chat biasa yang\n  juga fire-and-forget/tidak bisa dibatalkan). -->\n  <div class="zammad-chat-offline-compose-attachments js-offline-compose-attachments"></div>\n\n  <button type="button" class="zammad-chat-offline-compose-attach js-offline-compose-attach">\n    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11.97 12v3.5c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5V10c0-3.87-3.13-7-7-7s-7 3.13-7 7v6c0 3.31 2.69 6 6 6"/></svg>\n    <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_attach_button'] || 'Add attachment'));
    
      __out.push('</span>\n  </button>\n  <input type="file" class="js-offline-compose-attachment-input zammad-chat-is-hidden">\n\n  <button type="button" class="zammad-chat-offline-compose-submit js-offline-compose-submit">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_send_button'] || 'Send Message'));
    
      __out.push('</button>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["offline_otp"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-offline-otp">\n  <div class="zammad-chat-offline-otp-icon">\n    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M17 20.5H7c-3 0-5-1.5-5-5v-7c0-3.5 2-5 5-5h10c3 0 5 1.5 5 5v7c0 3.5-2 5-5 5Z"/><path d="m17 9-3.13 2.5c-1.03.82-2.72.82-3.75 0L7 9"/></svg>\n  </div>\n  <div class="zammad-chat-offline-otp-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_title'] || 'Enter verification code'));
    
      __out.push('</div>\n  <div class="zammad-chat-offline-otp-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_subtitle_prefix'] || 'We sent a 6-digit code to'));
    
      __out.push(' <strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong>.</div>\n\n  <div class="zammad-chat-offline-otp-boxes">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="0">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="1">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="2">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="3">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="4">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="5">\n  </div>\n\n  <div class="zammad-chat-offline-otp-error js-otp-error zammad-chat-is-hidden">\n    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M12 7.75V13M21.08 8.58v6.84c0 1.12-.6 2.16-1.57 2.73l-5.94 3.43c-.97.56-2.17.56-3.15 0l-5.94-3.43a3.15 3.15 0 0 1-1.57-2.73V8.58c0-1.12.6-2.16 1.57-2.73l5.94-3.43c.97-.56 2.17-.56 3.15 0l5.94 3.43c.97.57 1.57 1.6 1.57 2.73Z"/><path d="M12 16.2v.1"/></svg>\n    <span class="js-otp-error-text"></span>\n  </div>\n\n  <button type="button" class="zammad-chat-offline-otp-submit js-otp-submit">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_verify_button'] || 'Verify'));
    
      __out.push('</button>\n\n  <div class="zammad-chat-offline-otp-resend">\n    <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_resend_question'] || "Didn't receive the code?"));
    
      __out.push('</span>\n    <button type="button" class="zammad-chat-offline-otp-resend-btn js-otp-resend">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_resend_button'] || 'Resend code'));
    
      __out.push('</button>\n  </div>\n\n  <button type="button" class="zammad-chat-offline-otp-change-email js-otp-change-email">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_change_email'] || 'Change email address'));
    
      __out.push('</button>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["offline_sent"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-offline-sent">\n  <div class="zammad-chat-offline-sent-icon">\n    <svg width="30" height="30" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.49 2 2 6.49 2 12C2 17.51 6.49 22 12 22C17.51 22 22 17.51 22 12C22 6.49 17.51 2 12 2ZM16.78 9.7L11.11 15.37C10.97 15.51 10.78 15.59 10.58 15.59C10.38 15.59 10.19 15.51 10.05 15.37L7.22 12.54C6.93 12.25 6.93 11.77 7.22 11.48C7.51 11.19 7.99 11.19 8.28 11.48L10.58 13.78L15.72 8.64C16.01 8.35 16.49 8.35 16.78 8.64C17.07 8.93 17.07 9.4 16.78 9.7Z"/></svg>\n  </div>\n  <div class="zammad-chat-offline-sent-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_sent_title'] || 'Your message has been sent!'));
    
      __out.push('</div>\n  <div class="zammad-chat-offline-sent-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_sent_subtitle_prefix'] || 'Our team will reply to'));
    
      __out.push(' <strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong> ');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_sent_subtitle_suffix'] || 'as soon as an agent is available.'));
    
      __out.push('</div>\n  <button type="button" class="zammad-chat-offline-sent-button js-offline-sent-done">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_sent_button'] || 'Continue'));
    
      __out.push('</button>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["prechat_category_option"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<!-- Atas pelajaran entri 191 (ACTIVITY_LOG_SISKA.md -- ikon centang\nganda rusak krn 2 sumber render SVG tidak sinkron): ikon centang di\nsini SELALU dirender tanpa syarat, lalu tampil/sembunyi MURNI lewat\nCSS class is-selected (chat.scss) -- klik opsi lain (chat-no-jquery.coffee)\ncukup tukar class ke row yang tepat, TIDAK PERNAH perlu menyisipkan\natau menghapus markup SVG lagi. -->\n<div class="zammad-chat-prechat-category-option js-prechat-category-option');
    
      if (this.selected) {
        __out.push(__sanitize(' is-selected'));
      }
    
      __out.push('" data-value="');
    
      __out.push(this.value);
    
      __out.push('">\n  <span>');
    
      __out.push(this.label);
    
      __out.push('</span>\n  <svg class="zammad-chat-prechat-category-check" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["prechat"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-prechat">\n  <div class="zammad-chat-prechat-icon">\n    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22.81C11.31 22.81 10.66 22.46 10.2 21.85L8.7 19.85C8.67 19.81 8.55 19.76 8.5 19.75H8C3.83 19.75 1.25 18.62 1.25 13V8C1.25 3.58 3.58 1.25 8 1.25H16C20.42 1.25 22.75 3.58 22.75 8V13C22.75 17.42 20.42 19.75 16 19.75H15.5C15.42 19.75 15.35 19.79 15.3 19.85L13.8 21.85C13.34 22.46 12.69 22.81 12 22.81ZM8 2.75C4.42 2.75 2.75 4.42 2.75 8V13C2.75 17.52 4.3 18.25 8 18.25H8.5C9.01 18.25 9.59 18.54 9.9 18.95L11.4 20.95C11.75 21.41 12.25 21.41 12.6 20.95L14.1 18.95C14.43 18.51 14.95 18.25 15.5 18.25H16C19.58 18.25 21.25 16.58 21.25 13V8C21.25 4.42 19.58 2.75 16 2.75H8Z"/><path d="M17 8.75H7C6.59 8.75 6.25 8.41 6.25 8C6.25 7.59 6.59 7.25 7 7.25H17C17.41 7.25 17.75 7.59 17.75 8C17.75 8.41 17.41 8.75 17 8.75Z"/><path d="M13 13.75H7C6.59 13.75 6.25 13.41 6.25 13C6.25 12.59 6.59 12.25 7 12.25H13C13.41 12.25 13.75 12.59 13.75 13C13.75 13.41 13.41 13.75 13 13.75Z"/></svg>\n  </div>\n  <div class="zammad-chat-prechat-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_title'] || 'Let\'s get started'));
    
      __out.push('</div>\n  <div class="zammad-chat-prechat-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_subtitle'] || 'Please share a few details so our agent can help you faster.'));
    
      __out.push('</div>\n\n  <form class="zammad-chat-prechat-form">\n    ');
    
      if (this.error) {
        __out.push('\n      <div class="zammad-chat-prechat-error">');
        __out.push(this.error);
        __out.push('</div>\n    ');
      }
    
      __out.push('\n    <!-- Notice BUKAN error (kabar baik, mis. "agent sekarang\n    tersedia"), TERPISAH dari `.zammad-chat-prechat-error` (tetap\n    merah, dipakai pesan gagal validasi sungguhan). Atas permintaan\n    user (audit kit Able Pro TAILWIND baru): pola alert diganti ke\n    `.alert-success` GENUINE kit baru (lihat chat.scss, sama dgn\n    notice Home). Ikon centang stroke lama diganti Tabler\n    `circle-check` (diekstrak+diverifikasi dgn cara sama spt ikon\n    Home). -->\n    ');
    
      if (this.notice) {
        __out.push('\n      <div class="zammad-chat-prechat-notice">\n        <svg width="16" height="16" viewBox="0 0 1010 986.5" fill="currentColor"><g transform="scale(1,-1) translate(0,-986.5)"><path d="M518 816C530 816 545 816 553 815C677.367 799.454 765.015 742.816 830 667C875.205 614.26 904.582 551.09 921 469C926.277 442.611 926 432.576 926 400C926 324.03 909.781 267.562 884 216C864.868 177.736 844.6610000000001 145.6610000000001 816 117L793 94C772.933 73.933 750.076 57.33 725 43C666.595 9.625 602.028 -16 510 -16C471.821 -16 449.486 -15.425 420 -7C384.66 3.098 357.568 10.216 326 26C287.736 45.132 255.661 65.3389999999999 227 94L204 117C190.573 130.427 177.435 148.348 167 164C125.575 226.137 94 296.337 94 400C94 460.342 104.183 499.549 119 544C121 550 124 560 127 566L140 592C170.252 652.504 214.535 700.812 268 739C316.793 773.852 374.601 801.657 447 812C459.05 813.722 477.947 816 490 816H518zM508 733C497 733 484 732 479 732C445.765 732 413.549 718.85 387 710C360 701 326.705 678.528 306 663C275.306 639.98 248.682 608.523 227 576C208.395 548.094 197.195 515.685 187 480C179.855 454.994 177 431.92 177 400C177 358.342 183.768 329.314 193 297C195 290 200 280 202 274C215.732 232.802 241.187 202.775 266 173C276.0950000000001 160.886 294.086 145.936 306 137C329.264 119.552 364.57 99.612 394 87C401 84 413 82 419 80C432.854 75.382 451.407 72.5990000000001 467 70C473 69 488 67 500 67C556.137 67 597.623 75.85 638 92C716.753 123.501 770.0889999999999 180.664 809 252C814 262 820 277 823 284S828 303 830 309C834.618 322.8540000000001 837.401 341.4070000000001 840 357C841 363 843 378 843 390C843 436.9 838.86 469.707 826 504C811.55 542.533 797.363 573.796 774 603C749.429 633.7139999999999 719.59 660.606 686 683C657.835 701.7760000000001 626.066 712.6949999999999 590 723C564.121 730.395 541.37 733 508 733zM634 525C625.33 525 620.683 522.842 615 520C612 518 590 497 540 447L468 376L440 405C416 429 409 434 404 437C395.056 442.963 375.352 443.234 366 437C352.93 428.287 332.651 404.023 348 381C351 376 358 368 397 329C424 302 444 283 447 281C454.026 277.487 458.9 275 471 275C476 275 481 277 485 279C495.528 284.265 665.924 453.873 672 464C690.61 491.915 661.99 525 634 525z"/></g></svg>\n        <span>');
        __out.push(this.notice);
        __out.push('</span>\n      </div>\n    ');
      }
    
      __out.push('\n    <!-- Atas permintaan user ("saya mau menambahkan kategori ini pada\n    halaman messages, sejalan dengan inputan name, email"): field\n    wajib diisi, gaya & tinggi identik dgn Name/Email di bawah.\n    Ditaruh PALING ATAS (urutan Category -> Name -> Email, atas\n    permintaan user) -- BUKAN <select> native, widget ini konsisten\n    pakai kontrol custom (pola sama dgn emoji-picker) supaya gaya Able\n    Pro genuinely terpasang (select native tidak bisa di-skin lintas-\n    browser). Isi pilihan (.js-prechat-category-menu) SENGAJA kosong\n    di sini, dipopulasi via JS dari @categoryOptions\n    (chat-no-jquery.coffee, showPrechatForm) -- pola SAMA dgn\n    `.zammad-chat-kb-results` (views/help.eco) yg jg dipopulasi via\n    JS, bukan loop di eco. -->\n    <div class="zammad-chat-prechat-field zammad-chat-prechat-field--category">\n      <label>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_category_label'] || 'Category'));
    
      __out.push('</label>\n      <button type="button" class="zammad-chat-prechat-category js-prechat-category-toggle');
    
      if (this.error && !this.category) {
        __out.push(__sanitize(' zammad-chat-field-invalid'));
      }
    
      __out.push('" aria-expanded="false">\n        <span class="zammad-chat-prechat-category-value js-prechat-category-value');
    
      if (!this.category) {
        __out.push(__sanitize(' is-placeholder'));
      }
    
      __out.push('">');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_category_placeholder'] || 'Select a category'));
    
      __out.push('</span>\n        <svg class="zammad-chat-prechat-category-chevron" width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M17.919 8.18H6.079c-.96 0-1.44 1.16-.76 1.84l5.18 5.18c.83.83 2.18.83 3.01 0l1.97-1.97 3.21-3.21c.67-.68.19-1.84-.77-1.84z"/></svg>\n      </button>\n      <input type="hidden" class="js-prechat-category-input" value="');
    
      __out.push(this.category || '');
    
      __out.push('">\n      <div class="zammad-chat-prechat-category-menu js-prechat-category-menu zammad-chat-is-hidden"></div>\n    </div>\n    <div class="zammad-chat-prechat-field">\n      <label>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_name_label'] || 'Your name'));
    
      __out.push('</label>\n      <input type="text" class="zammad-chat-prechat-name');
    
      if (this.error && !this.name) {
        __out.push(__sanitize(' zammad-chat-field-invalid'));
      }
    
      __out.push('" value="');
    
      __out.push(this.name || '');
    
      __out.push('" required>\n    </div>\n    <div class="zammad-chat-prechat-field">\n      <label>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_email_label'] || 'Your email'));
    
      __out.push('</label>\n      <input type="email" class="zammad-chat-prechat-email');
    
      if (this.error && !this.email) {
        __out.push(__sanitize(' zammad-chat-field-invalid'));
      }
    
      __out.push('" value="');
    
      __out.push(this.email || '');
    
      __out.push('" required>\n    </div>\n    <!-- Atas permintaan user ("hilangkan icon pada button Start\n    Chat"): ikon paper-plane dihapus, teks polos saja. -->\n    <button type="submit" class="zammad-chat-prechat-submit">\n      <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_submit_button'] || 'Start chat'));
    
      __out.push('</span>\n    </button>\n  </form>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["preload"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-preload" style="box-sizing:border-box;position:fixed;right:24px;bottom:92px;width:380px;max-width:calc(100vw - 48px);height:640px;max-height:calc(100vh - 116px);background:#ffffff;border:1px solid #e8ebee;border-radius:8px;box-shadow:0 12px 32px rgba(20,20,20,0.12);display:flex;align-items:center;justify-content:center;z-index:999;">\n  <style>@keyframes zammad-chat-preload-spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}</style>\n  <div style="position:relative;width:56px;height:56px;">\n    <span style="position:absolute;inset:0;border-radius:50%;border:4px solid #e8ebee;"></span>\n    <span style="position:absolute;inset:0;border-radius:50%;border:4px solid transparent;border-top-color:#4680FF;border-right-color:#4680FF;animation:zammad-chat-preload-spin 900ms linear infinite;"></span>\n    <span style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;color:#4680FF;">\n      <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22.81C11.31 22.81 10.66 22.46 10.2 21.85L8.7 19.85C8.67 19.81 8.55 19.76 8.5 19.75H8C3.83 19.75 1.25 18.62 1.25 13V8C1.25 3.58 3.58 1.25 8 1.25H16C20.42 1.25 22.75 3.58 22.75 8V13C22.75 17.42 20.42 19.75 16 19.75H15.5C15.42 19.75 15.35 19.79 15.3 19.85L13.8 21.85C13.34 22.46 12.69 22.81 12 22.81ZM8 2.75C4.42 2.75 2.75 4.42 2.75 8V13C2.75 17.52 4.3 18.25 8 18.25H8.5C9.01 18.25 9.59 18.54 9.9 18.95L11.4 20.95C11.75 21.41 12.25 21.41 12.6 20.95L14.1 18.95C14.43 18.51 14.95 18.25 15.5 18.25H16C19.58 18.25 21.25 16.58 21.25 13V8C21.25 4.42 19.58 2.75 16 2.75H8Z"/><path d="M17 8.75H7C6.59 8.75 6.25 8.41 6.25 8C6.25 7.59 6.59 7.25 7 7.25H17C17.41 7.25 17.75 7.59 17.75 8C17.75 8.41 17.41 8.75 17 8.75Z"/><path d="M13 13.75H7C6.59 13.75 6.25 13.41 6.25 13C6.25 12.59 6.59 12.25 7 12.25H13C13.41 12.25 13.75 12.59 13.75 13C13.75 13.41 13.41 13.75 13 13.75Z"/></svg>\n    </span>\n  </div>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["reply_indicator"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<span class="zammad-chat-reply-indicator-text">');
    
      __out.push(this.T(this.phrases['chat_phrase_messages_reply_prefix'] || 'Replying to:'));
    
      __out.push(' ');
    
      __out.push(__sanitize(this.snippet));
    
      __out.push('</span>\n<span class="zammad-chat-reply-indicator-cancel js-reply-cancel">&times;</span>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["status"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-status">\n  <div class="zammad-chat-status-inner">\n    ');
    
      __out.push(this.status);
    
      __out.push('\n  </div>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["tabbar"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<button type="button" class="zammad-chat-tabbar-item is-active" data-tab="home">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M17 20.5H7c-3 0-5-1.5-5-5v-7c0-3.5 2-5 5-5h10c3 0 5 1.5 5 5v7c0 3.5-2 5-5 5Z"/><path d="m17 9-3.13 2.5c-1.03.82-2.72.82-3.75 0L7 9"/></svg>\n  <span>');
    
      __out.push(this.T('Home'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="messages">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22.81C11.31 22.81 10.66 22.46 10.2 21.85L8.7 19.85C8.67 19.81 8.55 19.76 8.5 19.75H8C3.83 19.75 1.25 18.62 1.25 13V8C1.25 3.58 3.58 1.25 8 1.25H16C20.42 1.25 22.75 3.58 22.75 8V13C22.75 17.42 20.42 19.75 16 19.75H15.5C15.42 19.75 15.35 19.79 15.3 19.85L13.8 21.85C13.34 22.46 12.69 22.81 12 22.81ZM8 2.75C4.42 2.75 2.75 4.42 2.75 8V13C2.75 17.52 4.3 18.25 8 18.25H8.5C9.01 18.25 9.59 18.54 9.9 18.95L11.4 20.95C11.75 21.41 12.25 21.41 12.6 20.95L14.1 18.95C14.43 18.51 14.95 18.25 15.5 18.25H16C19.58 18.25 21.25 16.58 21.25 13V8C21.25 4.42 19.58 2.75 16 2.75H8Z"/><path d="M17 8.75H7C6.59 8.75 6.25 8.41 6.25 8C6.25 7.59 6.59 7.25 7 7.25H17C17.41 7.25 17.75 7.59 17.75 8C17.75 8.41 17.41 8.75 17 8.75Z"/><path d="M13 13.75H7C6.59 13.75 6.25 13.41 6.25 13C6.25 12.59 6.59 12.25 7 12.25H13C13.41 12.25 13.75 12.59 13.75 13C13.75 13.41 13.41 13.75 13 13.75Z"/></svg>\n  <span>');
    
      __out.push(this.T('Messages'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="help">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M22 4.6697V16.7397C22 17.6997 21.22 18.5997 20.26 18.7197L19.93 18.7597C17.75 19.0497 14.39 20.1597 12.47 21.2197C12.21 21.3697 11.78 21.3697 11.51 21.2197L11.47 21.1997C9.54997 20.1497 6.20003 19.0497 4.03003 18.7597L3.73999 18.7197C2.77999 18.5997 2 17.6997 2 16.7397V4.65969C2 3.46969 2.96997 2.5697 4.15997 2.6697C6.25997 2.8397 9.43997 3.89973 11.22 5.00973L11.47 5.15969C11.76 5.33969 12.24 5.33969 12.53 5.15969L12.7 5.04971C13.33 4.65971 14.13 4.2697 15 3.9197V7.99972L17 6.6697L19 7.99972V2.77975C19.27 2.72975 19.53 2.69971 19.77 2.67971H19.83C21.02 2.57971 22 3.4697 22 4.6697Z"/><path d="M12 5.49023V20.4902"/><path d="M19 2.7793V7.99927L17 6.66925L15 7.99927V3.91925C16.31 3.39925 17.77 2.9793 19 2.7793Z"/></svg>\n  <span>');
    
      __out.push(this.T('Help'));
    
      __out.push('</span>\n</button>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["timestamp"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-timestamp"><strong>');
    
      __out.push(__sanitize(this.label));
    
      __out.push('</strong> ');
    
      __out.push(__sanitize(this.time));
    
      __out.push('</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["typingIndicator"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-message zammad-chat-message--typing zammad-chat-message--agent">\n  <span class="zammad-chat-message-body"><span class="zammad-chat-loading-animation"><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span></span></span>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["waiting_list_timeout"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-modal-text">\n  ');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_timeout_message'] || 'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!'));
    
      __out.push('\n  <br>\n  <button type="button" class="zammad-chat-timeout-restart js-restart"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>');
    
      __out.push(this.T(this.phrases['chat_phrase_restart_button'] || 'Start new conversation'));
    
      __out.push('</button>\n</div>');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["waiting"] = function(__obj) {
  if (!__obj) __obj = {};
  var __out = [], __capture = function(callback) {
    var out = __out, result;
    __out = [];
    callback.call(this);
    result = __out.join('');
    __out = out;
    return __safe(result);
  }, __sanitize = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else if (typeof value !== 'undefined' && value != null) {
      return __escape(value);
    } else {
      return '';
    }
  }, __safe, __objSafe = __obj.safe, __escape = __obj.escape;
  __safe = __obj.safe = function(value) {
    if (value && value.ecoSafe) {
      return value;
    } else {
      if (!(typeof value !== 'undefined' && value != null)) value = '';
      var result = new String(value);
      result.ecoSafe = true;
      return result;
    }
  };
  if (!__escape) {
    __escape = __obj.escape = function(value) {
      return ('' + value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
    };
  }
  (function() {
    (function() {
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Atas permintaan user (audit kit Able Pro TAILWIND baru, mockup\n  "Waiting.dc.html" opsi 1 disetujui) -- spinner SEKARANG satu elemen\n  polos (lihat chat.scss), track/ikon di tengah DIHAPUS, tidak ada\n  padanannya di preseden kit baru. -->\n  <div class="zammad-chat-waiting-spinner"></div>\n  <div class="zammad-chat-waiting-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_title'] || 'Connecting you to an agent…'));
    
      __out.push('</div>\n  <div class="zammad-chat-waiting-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_subtitle'] || 'All colleagues are busy.'));
    
      __out.push('</div>\n  ');
    
      if (this.position) {
        __out.push('\n    <div class="zammad-chat-waiting-position">');
        __out.push(this.T(this.phrases['chat_phrase_waiting_queue_position'] || 'You are on waiting list position <strong>%s</strong>.', this.position));
        __out.push('</div>\n  ');
      }
    
      __out.push('\n  <button type="button" class="zammad-chat-waiting-cancel js-waiting-cancel">');
    
      __out.push(this.T(this.phrases['chat_phrase_waiting_cancel_button'] || 'Cancel'));
    
      __out.push('</button>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

/*! @license DOMPurify 2.3.1 | (c) Cure53 and other contributors | Released under the Apache license 2.0 and Mozilla Public License 2.0 | github.com/cure53/DOMPurify/blob/2.3.1/LICENSE */
!function(e,t){"object"==typeof exports&&"undefined"!=typeof module?module.exports=t():"function"==typeof define&&define.amd?define(t):(e=e||self).DOMPurify=t()}(this,(function(){"use strict";var e=Object.hasOwnProperty,t=Object.setPrototypeOf,n=Object.isFrozen,r=Object.getPrototypeOf,o=Object.getOwnPropertyDescriptor,i=Object.freeze,a=Object.seal,l=Object.create,c="undefined"!=typeof Reflect&&Reflect,s=c.apply,u=c.construct;s||(s=function(e,t,n){return e.apply(t,n)}),i||(i=function(e){return e}),a||(a=function(e){return e}),u||(u=function(e,t){return new(Function.prototype.bind.apply(e,[null].concat(function(e){if(Array.isArray(e)){for(var t=0,n=Array(e.length);t<e.length;t++)n[t]=e[t];return n}return Array.from(e)}(t))))});var f,m=x(Array.prototype.forEach),d=x(Array.prototype.pop),p=x(Array.prototype.push),g=x(String.prototype.toLowerCase),h=x(String.prototype.match),y=x(String.prototype.replace),v=x(String.prototype.indexOf),b=x(String.prototype.trim),T=x(RegExp.prototype.test),A=(f=TypeError,function(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];return u(f,t)});function x(e){return function(t){for(var n=arguments.length,r=Array(n>1?n-1:0),o=1;o<n;o++)r[o-1]=arguments[o];return s(e,t,r)}}function S(e,r){t&&t(e,null);for(var o=r.length;o--;){var i=r[o];if("string"==typeof i){var a=g(i);a!==i&&(n(r)||(r[o]=a),i=a)}e[i]=!0}return e}function w(t){var n=l(null),r=void 0;for(r in t)s(e,t,[r])&&(n[r]=t[r]);return n}function N(e,t){for(;null!==e;){var n=o(e,t);if(n){if(n.get)return x(n.get);if("function"==typeof n.value)return x(n.value)}e=r(e)}return function(e){return console.warn("fallback value for",e),null}}var k=i(["a","abbr","acronym","address","area","article","aside","audio","b","bdi","bdo","big","blink","blockquote","body","br","button","canvas","caption","center","cite","code","col","colgroup","content","data","datalist","dd","decorator","del","details","dfn","dialog","dir","div","dl","dt","element","em","fieldset","figcaption","figure","font","footer","form","h1","h2","h3","h4","h5","h6","head","header","hgroup","hr","html","i","img","input","ins","kbd","label","legend","li","main","map","mark","marquee","menu","menuitem","meter","nav","nobr","ol","optgroup","option","output","p","picture","pre","progress","q","rp","rt","ruby","s","samp","section","select","shadow","small","source","spacer","span","strike","strong","style","sub","summary","sup","table","tbody","td","template","textarea","tfoot","th","thead","time","tr","track","tt","u","ul","var","video","wbr"]),E=i(["svg","a","altglyph","altglyphdef","altglyphitem","animatecolor","animatemotion","animatetransform","circle","clippath","defs","desc","ellipse","filter","font","g","glyph","glyphref","hkern","image","line","lineargradient","marker","mask","metadata","mpath","path","pattern","polygon","polyline","radialgradient","rect","stop","style","switch","symbol","text","textpath","title","tref","tspan","view","vkern"]),D=i(["feBlend","feColorMatrix","feComponentTransfer","feComposite","feConvolveMatrix","feDiffuseLighting","feDisplacementMap","feDistantLight","feFlood","feFuncA","feFuncB","feFuncG","feFuncR","feGaussianBlur","feMerge","feMergeNode","feMorphology","feOffset","fePointLight","feSpecularLighting","feSpotLight","feTile","feTurbulence"]),O=i(["animate","color-profile","cursor","discard","fedropshadow","feimage","font-face","font-face-format","font-face-name","font-face-src","font-face-uri","foreignobject","hatch","hatchpath","mesh","meshgradient","meshpatch","meshrow","missing-glyph","script","set","solidcolor","unknown","use"]),R=i(["math","menclose","merror","mfenced","mfrac","mglyph","mi","mlabeledtr","mmultiscripts","mn","mo","mover","mpadded","mphantom","mroot","mrow","ms","mspace","msqrt","mstyle","msub","msup","msubsup","mtable","mtd","mtext","mtr","munder","munderover"]),_=i(["maction","maligngroup","malignmark","mlongdiv","mscarries","mscarry","msgroup","mstack","msline","msrow","semantics","annotation","annotation-xml","mprescripts","none"]),M=i(["#text"]),L=i(["accept","action","align","alt","autocapitalize","autocomplete","autopictureinpicture","autoplay","background","bgcolor","border","capture","cellpadding","cellspacing","checked","cite","class","clear","color","cols","colspan","controls","controlslist","coords","crossorigin","datetime","decoding","default","dir","disabled","disablepictureinpicture","disableremoteplayback","download","draggable","enctype","enterkeyhint","face","for","headers","height","hidden","high","href","hreflang","id","inputmode","integrity","ismap","kind","label","lang","list","loading","loop","low","max","maxlength","media","method","min","minlength","multiple","muted","name","noshade","novalidate","nowrap","open","optimum","pattern","placeholder","playsinline","poster","preload","pubdate","radiogroup","readonly","rel","required","rev","reversed","role","rows","rowspan","spellcheck","scope","selected","shape","size","sizes","span","srclang","start","src","srcset","step","style","summary","tabindex","title","translate","type","usemap","valign","value","width","xmlns","slot"]),F=i(["accent-height","accumulate","additive","alignment-baseline","ascent","attributename","attributetype","azimuth","basefrequency","baseline-shift","begin","bias","by","class","clip","clippathunits","clip-path","clip-rule","color","color-interpolation","color-interpolation-filters","color-profile","color-rendering","cx","cy","d","dx","dy","diffuseconstant","direction","display","divisor","dur","edgemode","elevation","end","fill","fill-opacity","fill-rule","filter","filterunits","flood-color","flood-opacity","font-family","font-size","font-size-adjust","font-stretch","font-style","font-variant","font-weight","fx","fy","g1","g2","glyph-name","glyphref","gradientunits","gradienttransform","height","href","id","image-rendering","in","in2","k","k1","k2","k3","k4","kerning","keypoints","keysplines","keytimes","lang","lengthadjust","letter-spacing","kernelmatrix","kernelunitlength","lighting-color","local","marker-end","marker-mid","marker-start","markerheight","markerunits","markerwidth","maskcontentunits","maskunits","max","mask","media","method","mode","min","name","numoctaves","offset","operator","opacity","order","orient","orientation","origin","overflow","paint-order","path","pathlength","patterncontentunits","patterntransform","patternunits","points","preservealpha","preserveaspectratio","primitiveunits","r","rx","ry","radius","refx","refy","repeatcount","repeatdur","restart","result","rotate","scale","seed","shape-rendering","specularconstant","specularexponent","spreadmethod","startoffset","stddeviation","stitchtiles","stop-color","stop-opacity","stroke-dasharray","stroke-dashoffset","stroke-linecap","stroke-linejoin","stroke-miterlimit","stroke-opacity","stroke","stroke-width","style","surfacescale","systemlanguage","tabindex","targetx","targety","transform","text-anchor","text-decoration","text-rendering","textlength","type","u1","u2","unicode","values","viewbox","visibility","version","vert-adv-y","vert-origin-x","vert-origin-y","width","word-spacing","wrap","writing-mode","xchannelselector","ychannelselector","x","x1","x2","xmlns","y","y1","y2","z","zoomandpan"]),I=i(["accent","accentunder","align","bevelled","close","columnsalign","columnlines","columnspan","denomalign","depth","dir","display","displaystyle","encoding","fence","frame","height","href","id","largeop","length","linethickness","lspace","lquote","mathbackground","mathcolor","mathsize","mathvariant","maxsize","minsize","movablelimits","notation","numalign","open","rowalign","rowlines","rowspacing","rowspan","rspace","rquote","scriptlevel","scriptminsize","scriptsizemultiplier","selection","separator","separators","stretchy","subscriptshift","supscriptshift","symmetric","voffset","width","xmlns"]),C=i(["xlink:href","xml:id","xlink:title","xml:space","xmlns:xlink"]),z=a(/\{\{[\s\S]*|[\s\S]*\}\}/gm),H=a(/<%[\s\S]*|[\s\S]*%>/gm),U=a(/^data-[\-\w.\u00B7-\uFFFF]/),j=a(/^aria-[\-\w]+$/),B=a(/^(?:(?:(?:f|ht)tps?|mailto|tel|callto|cid|xmpp):|[^a-z]|[a-z+.\-]+(?:[^a-z+.\-:]|$))/i),P=a(/^(?:\w+script|data):/i),W=a(/[\u0000-\u0020\u00A0\u1680\u180E\u2000-\u2029\u205F\u3000]/g),G="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(e){return typeof e}:function(e){return e&&"function"==typeof Symbol&&e.constructor===Symbol&&e!==Symbol.prototype?"symbol":typeof e};function q(e){if(Array.isArray(e)){for(var t=0,n=Array(e.length);t<e.length;t++)n[t]=e[t];return n}return Array.from(e)}var K=function(){return"undefined"==typeof window?null:window},V=function(e,t){if("object"!==(void 0===e?"undefined":G(e))||"function"!=typeof e.createPolicy)return null;var n=null,r="data-tt-policy-suffix";t.currentScript&&t.currentScript.hasAttribute(r)&&(n=t.currentScript.getAttribute(r));var o="dompurify"+(n?"#"+n:"");try{return e.createPolicy(o,{createHTML:function(e){return e}})}catch(e){return console.warn("TrustedTypes policy "+o+" could not be created."),null}};return function e(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:K(),n=function(t){return e(t)};if(n.version="2.3.1",n.removed=[],!t||!t.document||9!==t.document.nodeType)return n.isSupported=!1,n;var r=t.document,o=t.document,a=t.DocumentFragment,l=t.HTMLTemplateElement,c=t.Node,s=t.Element,u=t.NodeFilter,f=t.NamedNodeMap,x=void 0===f?t.NamedNodeMap||t.MozNamedAttrMap:f,Y=t.Text,X=t.Comment,$=t.DOMParser,Z=t.trustedTypes,J=s.prototype,Q=N(J,"cloneNode"),ee=N(J,"nextSibling"),te=N(J,"childNodes"),ne=N(J,"parentNode");if("function"==typeof l){var re=o.createElement("template");re.content&&re.content.ownerDocument&&(o=re.content.ownerDocument)}var oe=V(Z,r),ie=oe&&ze?oe.createHTML(""):"",ae=o,le=ae.implementation,ce=ae.createNodeIterator,se=ae.createDocumentFragment,ue=ae.getElementsByTagName,fe=r.importNode,me={};try{me=w(o).documentMode?o.documentMode:{}}catch(e){}var de={};n.isSupported="function"==typeof ne&&le&&void 0!==le.createHTMLDocument&&9!==me;var pe=z,ge=H,he=U,ye=j,ve=P,be=W,Te=B,Ae=null,xe=S({},[].concat(q(k),q(E),q(D),q(R),q(M))),Se=null,we=S({},[].concat(q(L),q(F),q(I),q(C))),Ne=null,ke=null,Ee=!0,De=!0,Oe=!1,Re=!1,_e=!1,Me=!1,Le=!1,Fe=!1,Ie=!1,Ce=!0,ze=!1,He=!0,Ue=!0,je=!1,Be={},Pe=null,We=S({},["annotation-xml","audio","colgroup","desc","foreignobject","head","iframe","math","mi","mn","mo","ms","mtext","noembed","noframes","noscript","plaintext","script","style","svg","template","thead","title","video","xmp"]),Ge=null,qe=S({},["audio","video","img","source","image","track"]),Ke=null,Ve=S({},["alt","class","for","id","label","name","pattern","placeholder","role","summary","title","value","style","xmlns"]),Ye="http://www.w3.org/1998/Math/MathML",Xe="http://www.w3.org/2000/svg",$e="http://www.w3.org/1999/xhtml",Ze=$e,Je=!1,Qe=null,et=o.createElement("form"),tt=function(e){Qe&&Qe===e||(e&&"object"===(void 0===e?"undefined":G(e))||(e={}),e=w(e),Ae="ALLOWED_TAGS"in e?S({},e.ALLOWED_TAGS):xe,Se="ALLOWED_ATTR"in e?S({},e.ALLOWED_ATTR):we,Ke="ADD_URI_SAFE_ATTR"in e?S(w(Ve),e.ADD_URI_SAFE_ATTR):Ve,Ge="ADD_DATA_URI_TAGS"in e?S(w(qe),e.ADD_DATA_URI_TAGS):qe,Pe="FORBID_CONTENTS"in e?S({},e.FORBID_CONTENTS):We,Ne="FORBID_TAGS"in e?S({},e.FORBID_TAGS):{},ke="FORBID_ATTR"in e?S({},e.FORBID_ATTR):{},Be="USE_PROFILES"in e&&e.USE_PROFILES,Ee=!1!==e.ALLOW_ARIA_ATTR,De=!1!==e.ALLOW_DATA_ATTR,Oe=e.ALLOW_UNKNOWN_PROTOCOLS||!1,Re=e.SAFE_FOR_TEMPLATES||!1,_e=e.WHOLE_DOCUMENT||!1,Fe=e.RETURN_DOM||!1,Ie=e.RETURN_DOM_FRAGMENT||!1,Ce=!1!==e.RETURN_DOM_IMPORT,ze=e.RETURN_TRUSTED_TYPE||!1,Le=e.FORCE_BODY||!1,He=!1!==e.SANITIZE_DOM,Ue=!1!==e.KEEP_CONTENT,je=e.IN_PLACE||!1,Te=e.ALLOWED_URI_REGEXP||Te,Ze=e.NAMESPACE||$e,Re&&(De=!1),Ie&&(Fe=!0),Be&&(Ae=S({},[].concat(q(M))),Se=[],!0===Be.html&&(S(Ae,k),S(Se,L)),!0===Be.svg&&(S(Ae,E),S(Se,F),S(Se,C)),!0===Be.svgFilters&&(S(Ae,D),S(Se,F),S(Se,C)),!0===Be.mathMl&&(S(Ae,R),S(Se,I),S(Se,C))),e.ADD_TAGS&&(Ae===xe&&(Ae=w(Ae)),S(Ae,e.ADD_TAGS)),e.ADD_ATTR&&(Se===we&&(Se=w(Se)),S(Se,e.ADD_ATTR)),e.ADD_URI_SAFE_ATTR&&S(Ke,e.ADD_URI_SAFE_ATTR),e.FORBID_CONTENTS&&(Pe===We&&(Pe=w(Pe)),S(Pe,e.FORBID_CONTENTS)),Ue&&(Ae["#text"]=!0),_e&&S(Ae,["html","head","body"]),Ae.table&&(S(Ae,["tbody"]),delete Ne.tbody),i&&i(e),Qe=e)},nt=S({},["mi","mo","mn","ms","mtext"]),rt=S({},["foreignobject","desc","title","annotation-xml"]),ot=S({},E);S(ot,D),S(ot,O);var it=S({},R);S(it,_);var at=function(e){var t=ne(e);t&&t.tagName||(t={namespaceURI:$e,tagName:"template"});var n=g(e.tagName),r=g(t.tagName);if(e.namespaceURI===Xe)return t.namespaceURI===$e?"svg"===n:t.namespaceURI===Ye?"svg"===n&&("annotation-xml"===r||nt[r]):Boolean(ot[n]);if(e.namespaceURI===Ye)return t.namespaceURI===$e?"math"===n:t.namespaceURI===Xe?"math"===n&&rt[r]:Boolean(it[n]);if(e.namespaceURI===$e){if(t.namespaceURI===Xe&&!rt[r])return!1;if(t.namespaceURI===Ye&&!nt[r])return!1;var o=S({},["title","style","font","a","script"]);return!it[n]&&(o[n]||!ot[n])}return!1},lt=function(e){p(n.removed,{element:e});try{e.parentNode.removeChild(e)}catch(t){try{e.outerHTML=ie}catch(t){e.remove()}}},ct=function(e,t){try{p(n.removed,{attribute:t.getAttributeNode(e),from:t})}catch(e){p(n.removed,{attribute:null,from:t})}if(t.removeAttribute(e),"is"===e&&!Se[e])if(Fe||Ie)try{lt(t)}catch(e){}else try{t.setAttribute(e,"")}catch(e){}},st=function(e){var t=void 0,n=void 0;if(Le)e="<remove></remove>"+e;else{var r=h(e,/^[\r\n\t ]+/);n=r&&r[0]}var i=oe?oe.createHTML(e):e;if(Ze===$e)try{t=(new $).parseFromString(i,"text/html")}catch(e){}if(!t||!t.documentElement){t=le.createDocument(Ze,"template",null);try{t.documentElement.innerHTML=Je?"":i}catch(e){}}var a=t.body||t.documentElement;return e&&n&&a.insertBefore(o.createTextNode(n),a.childNodes[0]||null),Ze===$e?ue.call(t,_e?"html":"body")[0]:_e?t.documentElement:a},ut=function(e){return ce.call(e.ownerDocument||e,e,u.SHOW_ELEMENT|u.SHOW_COMMENT|u.SHOW_TEXT,null,!1)},ft=function(e){return!(e instanceof Y||e instanceof X)&&!("string"==typeof e.nodeName&&"string"==typeof e.textContent&&"function"==typeof e.removeChild&&e.attributes instanceof x&&"function"==typeof e.removeAttribute&&"function"==typeof e.setAttribute&&"string"==typeof e.namespaceURI&&"function"==typeof e.insertBefore)},mt=function(e){return"object"===(void 0===c?"undefined":G(c))?e instanceof c:e&&"object"===(void 0===e?"undefined":G(e))&&"number"==typeof e.nodeType&&"string"==typeof e.nodeName},dt=function(e,t,r){de[e]&&m(de[e],(function(e){e.call(n,t,r,Qe)}))},pt=function(e){var t=void 0;if(dt("beforeSanitizeElements",e,null),ft(e))return lt(e),!0;if(h(e.nodeName,/[\u0080-\uFFFF]/))return lt(e),!0;var r=g(e.nodeName);if(dt("uponSanitizeElement",e,{tagName:r,allowedTags:Ae}),!mt(e.firstElementChild)&&(!mt(e.content)||!mt(e.content.firstElementChild))&&T(/<[/\w]/g,e.innerHTML)&&T(/<[/\w]/g,e.textContent))return lt(e),!0;if("select"===r&&T(/<template/i,e.innerHTML))return lt(e),!0;if(!Ae[r]||Ne[r]){if(Ue&&!Pe[r]){var o=ne(e)||e.parentNode,i=te(e)||e.childNodes;if(i&&o)for(var a=i.length-1;a>=0;--a)o.insertBefore(Q(i[a],!0),ee(e))}return lt(e),!0}return e instanceof s&&!at(e)?(lt(e),!0):"noscript"!==r&&"noembed"!==r||!T(/<\/no(script|embed)/i,e.innerHTML)?(Re&&3===e.nodeType&&(t=e.textContent,t=y(t,pe," "),t=y(t,ge," "),e.textContent!==t&&(p(n.removed,{element:e.cloneNode()}),e.textContent=t)),dt("afterSanitizeElements",e,null),!1):(lt(e),!0)},gt=function(e,t,n){if(He&&("id"===t||"name"===t)&&(n in o||n in et))return!1;if(De&&!ke[t]&&T(he,t));else if(Ee&&T(ye,t));else{if(!Se[t]||ke[t])return!1;if(Ke[t]);else if(T(Te,y(n,be,"")));else if("src"!==t&&"xlink:href"!==t&&"href"!==t||"script"===e||0!==v(n,"data:")||!Ge[e]){if(Oe&&!T(ve,y(n,be,"")));else if(n)return!1}else;}return!0},ht=function(e){var t=void 0,r=void 0,o=void 0,i=void 0;dt("beforeSanitizeAttributes",e,null);var a=e.attributes;if(a){var l={attrName:"",attrValue:"",keepAttr:!0,allowedAttributes:Se};for(i=a.length;i--;){var c=t=a[i],s=c.name,u=c.namespaceURI;if(r=b(t.value),o=g(s),l.attrName=o,l.attrValue=r,l.keepAttr=!0,l.forceKeepAttr=void 0,dt("uponSanitizeAttribute",e,l),r=l.attrValue,!l.forceKeepAttr&&(ct(s,e),l.keepAttr))if(T(/\/>/i,r))ct(s,e);else{Re&&(r=y(r,pe," "),r=y(r,ge," "));var f=e.nodeName.toLowerCase();if(gt(f,o,r))try{u?e.setAttributeNS(u,s,r):e.setAttribute(s,r),d(n.removed)}catch(e){}}}dt("afterSanitizeAttributes",e,null)}},yt=function e(t){var n=void 0,r=ut(t);for(dt("beforeSanitizeShadowDOM",t,null);n=r.nextNode();)dt("uponSanitizeShadowNode",n,null),pt(n)||(n.content instanceof a&&e(n.content),ht(n));dt("afterSanitizeShadowDOM",t,null)};return n.sanitize=function(e,o){var i=void 0,l=void 0,s=void 0,u=void 0,f=void 0;if((Je=!e)&&(e="\x3c!--\x3e"),"string"!=typeof e&&!mt(e)){if("function"!=typeof e.toString)throw A("toString is not a function");if("string"!=typeof(e=e.toString()))throw A("dirty is not a string, aborting")}if(!n.isSupported){if("object"===G(t.toStaticHTML)||"function"==typeof t.toStaticHTML){if("string"==typeof e)return t.toStaticHTML(e);if(mt(e))return t.toStaticHTML(e.outerHTML)}return e}if(Me||tt(o),n.removed=[],"string"==typeof e&&(je=!1),je);else if(e instanceof c)1===(l=(i=st("\x3c!----\x3e")).ownerDocument.importNode(e,!0)).nodeType&&"BODY"===l.nodeName||"HTML"===l.nodeName?i=l:i.appendChild(l);else{if(!Fe&&!Re&&!_e&&-1===e.indexOf("<"))return oe&&ze?oe.createHTML(e):e;if(!(i=st(e)))return Fe?null:ie}i&&Le&&lt(i.firstChild);for(var m=ut(je?e:i);s=m.nextNode();)3===s.nodeType&&s===u||pt(s)||(s.content instanceof a&&yt(s.content),ht(s),u=s);if(u=null,je)return e;if(Fe){if(Ie)for(f=se.call(i.ownerDocument);i.firstChild;)f.appendChild(i.firstChild);else f=i;return Ce&&(f=fe.call(r,f,!0)),f}var d=_e?i.outerHTML:i.innerHTML;return Re&&(d=y(d,pe," "),d=y(d,ge," ")),oe&&ze?oe.createHTML(d):d},n.setConfig=function(e){tt(e),Me=!0},n.clearConfig=function(){Qe=null,Me=!1},n.isValidAttribute=function(e,t,n){Qe||tt({});var r=g(e),o=g(t);return gt(r,o,n)},n.addHook=function(e,t){"function"==typeof t&&(de[e]=de[e]||[],p(de[e],t))},n.removeHook=function(e){de[e]&&d(de[e])},n.removeHooks=function(e){de[e]&&(de[e]=[])},n.removeAllHooks=function(){de={}},n}()}));
//# sourceMappingURL=purify.min.js.map

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  slice = [].slice,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

(function($, window) {
  var Base, Io, Log, Timeout, ZammadChat, ensureViewportMeta, myScript, scriptHost, scriptProtocol, scripts;
  scripts = document.getElementsByTagName('script');
  myScript = scripts[scripts.length - 1];
  scriptProtocol = window.location.protocol.replace(':', '');
  if (myScript && myScript.src) {
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1];
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1];
  }
  ensureViewportMeta = function() {
    var meta;
    if (document.querySelector('meta[name="viewport"]')) {
      return;
    }
    if (!document.head) {
      return;
    }
    meta = document.createElement('meta');
    meta.setAttribute('name', 'viewport');
    meta.setAttribute('content', 'width=device-width, initial-scale=1');
    return document.head.appendChild(meta);
  };
  ensureViewportMeta();
  Base = (function() {
    Base.prototype.defaults = {
      debug: false
    };

    function Base(options) {
      this.options = $.extend({}, this.defaults, options);
      this.log = new Log({
        debug: this.options.debug,
        logPrefix: this.options.logPrefix || this.logPrefix
      });
    }

    return Base;

  })();
  Log = (function() {
    Log.prototype.defaults = {
      debug: false
    };

    function Log(options) {
      this.log = bind(this.log, this);
      this.error = bind(this.error, this);
      this.notice = bind(this.notice, this);
      this.debug = bind(this.debug, this);
      this.options = $.extend({}, this.defaults, options);
    }

    Log.prototype.debug = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      if (!this.options.debug) {
        return;
      }
      return this.log('debug', items);
    };

    Log.prototype.notice = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.log('notice', items);
    };

    Log.prototype.error = function() {
      var items;
      items = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return this.log('error', items);
    };

    Log.prototype.log = function(level, items) {
      var item, j, len, logString;
      items.unshift('||');
      items.unshift(level);
      items.unshift(this.options.logPrefix);
      console.log.apply(console, items);
      if (!this.options.debug) {
        return;
      }
      logString = '';
      for (j = 0, len = items.length; j < len; j++) {
        item = items[j];
        logString += ' ';
        if (typeof item === 'object') {
          logString += JSON.stringify(item);
        } else if (item && item.toString) {
          logString += item.toString();
        } else {
          logString += item;
        }
      }
      return $('.js-chatLogDisplay').prepend('<div>' + logString + '</div>');
    };

    return Log;

  })();
  Timeout = (function(superClass) {
    extend(Timeout, superClass);

    Timeout.prototype.timeoutStartedAt = null;

    Timeout.prototype.logPrefix = 'timeout';

    Timeout.prototype.defaults = {
      debug: false,
      timeout: 4,
      timeoutIntervallCheck: 0.5
    };

    function Timeout(options) {
      this.stop = bind(this.stop, this);
      this.start = bind(this.start, this);
      Timeout.__super__.constructor.call(this, options);
    }

    Timeout.prototype.start = function() {
      var check, timeoutStartedAt;
      this.stop();
      timeoutStartedAt = new Date;
      check = (function(_this) {
        return function() {
          var timeLeft;
          timeLeft = new Date - new Date(timeoutStartedAt.getTime() + _this.options.timeout * 1000 * 60);
          _this.log.debug("Timeout check for " + _this.options.timeout + " minutes (left " + (timeLeft / 1000) + " sec.)");
          if (timeLeft < 0) {
            return;
          }
          _this.stop();
          return _this.options.callback();
        };
      })(this);
      this.log.debug("Start timeout in " + this.options.timeout + " minutes");
      return this.intervallId = setInterval(check, this.options.timeoutIntervallCheck * 1000 * 60);
    };

    Timeout.prototype.stop = function() {
      if (!this.intervallId) {
        return;
      }
      this.log.debug("Stop timeout of " + this.options.timeout + " minutes");
      return clearInterval(this.intervallId);
    };

    return Timeout;

  })(Base);
  Io = (function(superClass) {
    extend(Io, superClass);

    Io.prototype.logPrefix = 'io';

    Io.prototype.reconnectAttempts = 0;

    Io.prototype.maxReconnectAttempts = 6;

    Io.prototype.reconnectBaseDelay = 1000;

    Io.prototype.reconnectMaxDelay = 30000;

    function Io(options) {
      this.ping = bind(this.ping, this);
      this.send = bind(this.send, this);
      this.reconnect = bind(this.reconnect, this);
      this.close = bind(this.close, this);
      this.attemptReconnect = bind(this.attemptReconnect, this);
      this.connect = bind(this.connect, this);
      this.set = bind(this.set, this);
      Io.__super__.constructor.call(this, options);
    }

    Io.prototype.set = function(params) {
      var key, results1, value;
      results1 = [];
      for (key in params) {
        value = params[key];
        results1.push(this.options[key] = value);
      }
      return results1;
    };

    Io.prototype.connect = function() {
      this.log.debug("Connecting to " + this.options.host);
      this.ws = new window.WebSocket("" + this.options.host);
      this.ws.onopen = (function(_this) {
        return function(e) {
          var base;
          _this.log.debug('onOpen', e);
          if (_this.reconnectAttempts > 0) {
            _this.log.debug("reconnected after " + _this.reconnectAttempts + " attempt(s)");
            _this.reconnectAttempts = 0;
            if (typeof (base = _this.options).onReconnected === "function") {
              base.onReconnected();
            }
          }
          _this.options.onOpen(e);
          return _this.ping();
        };
      })(this);
      this.ws.onmessage = (function(_this) {
        return function(e) {
          var j, len, pipe, pipes;
          pipes = JSON.parse(e.data);
          _this.log.debug('onMessage', e.data);
          for (j = 0, len = pipes.length; j < len; j++) {
            pipe = pipes[j];
            if (pipe.event === 'pong') {
              _this.ping();
            }
          }
          if (_this.options.onMessage) {
            return _this.options.onMessage(pipes);
          }
        };
      })(this);
      this.ws.onclose = (function(_this) {
        return function(e) {
          _this.log.debug('close websocket connection', e);
          if (_this.pingDelayId) {
            clearTimeout(_this.pingDelayId);
          }
          if (_this.manualClose) {
            _this.log.debug('manual close, onClose callback');
            _this.manualClose = false;
            if (_this.options.onClose) {
              return _this.options.onClose(e);
            }
          } else {
            return _this.attemptReconnect();
          }
        };
      })(this);
      return this.ws.onerror = (function(_this) {
        return function(e) {
          return _this.log.debug('onError', e);
        };
      })(this);
    };

    Io.prototype.attemptReconnect = function() {
      var base, base1, delay;
      if (this.reconnectAttempts >= this.maxReconnectAttempts) {
        this.log.debug("gave up after " + this.reconnectAttempts + " reconnect attempts");
        this.reconnectAttempts = 0;
        if (typeof (base = this.options).onReconnectFailed === "function") {
          base.onReconnectFailed();
        }
        return;
      }
      this.reconnectAttempts += 1;
      delay = Math.min(this.reconnectBaseDelay * Math.pow(2, this.reconnectAttempts - 1), this.reconnectMaxDelay);
      this.log.debug("reconnect attempt " + this.reconnectAttempts + "/" + this.maxReconnectAttempts + " in " + delay + "ms");
      if (typeof (base1 = this.options).onReconnecting === "function") {
        base1.onReconnecting(this.reconnectAttempts, this.maxReconnectAttempts);
      }
      return this.reconnectTimeoutId = setTimeout(this.connect, delay);
    };

    Io.prototype.close = function() {
      var base;
      this.log.debug('close websocket manually');
      this.manualClose = true;
      if (this.reconnectTimeoutId) {
        clearTimeout(this.reconnectTimeoutId);
        this.reconnectTimeoutId = void 0;
      }
      this.reconnectAttempts = 0;
      if (this.ws && this.ws.readyState !== window.WebSocket.CLOSED && this.ws.readyState !== window.WebSocket.CLOSING) {
        return this.ws.close();
      } else {
        this.manualClose = false;
        return typeof (base = this.options).onClose === "function" ? base.onClose() : void 0;
      }
    };

    Io.prototype.reconnect = function() {
      this.log.debug('reconnect');
      this.close();
      return this.connect();
    };

    Io.prototype.send = function(event, data) {
      var msg;
      if (data == null) {
        data = {};
      }
      this.log.debug('send', event, data);
      if (!this.ws || this.ws.readyState !== window.WebSocket.OPEN) {
        return;
      }
      msg = JSON.stringify({
        event: event,
        data: data
      });
      return this.ws.send(msg);
    };

    Io.prototype.ping = function() {
      var localPing;
      localPing = (function(_this) {
        return function() {
          return _this.send('ping');
        };
      })(this);
      return this.pingDelayId = setTimeout(localPing, 29000);
    };

    return Io;

  })(Base);
  ZammadChat = (function(superClass) {
    extend(ZammadChat, superClass);

    ZammadChat.prototype.defaults = {
      chatId: void 0,
      show: true,
      target: $('body'),
      host: '',
      debug: false,
      flat: false,
      lang: void 0,
      cssAutoload: true,
      cssUrl: void 0,
      fontSize: void 0,
      buttonClass: 'open-zammad-chat',
      inactiveClass: 'is-inactive',
      title: '<strong>Chat</strong> with us!',
      scrollHint: 'Scroll down to see new messages',
      idleTimeout: 6,
      idleTimeoutIntervallCheck: 0.5,
      inactiveTimeout: 8,
      inactiveTimeoutIntervallCheck: 0.5,
      waitingListTimeout: 4,
      waitingListTimeoutIntervallCheck: 0.5,
      onReady: void 0,
      onCloseAnimationEnd: void 0,
      onError: void 0,
      onOpenAnimationEnd: void 0,
      onConnectionReestablished: void 0,
      onSessionClosed: void 0,
      onConnectionEstablished: void 0,
      onCssLoaded: void 0
    };

    ZammadChat.prototype.logPrefix = 'chat';

    ZammadChat.prototype._messageCount = 0;

    ZammadChat.prototype.isOpen = false;

    ZammadChat.prototype.blinkOnlineInterval = null;

    ZammadChat.prototype.stopBlinOnlineStateTimeout = null;

    ZammadChat.prototype.showTimeEveryXMinutes = 2;

    ZammadChat.prototype.lastTimestamp = null;

    ZammadChat.prototype.lastAddedType = null;

    ZammadChat.prototype.inputDisabled = false;

    ZammadChat.prototype.inputTimeout = null;

    ZammadChat.prototype.isTyping = false;

    ZammadChat.prototype.state = 'offline';

    ZammadChat.prototype.offlineMode = false;

    ZammadChat.prototype.initialQueueDelay = 10000;

    ZammadChat.prototype.translations = {
      'ca': {
        '<strong>Chat</strong> with us!': '<strong>Xateja</strong> amb nosaltres!',
        'All colleagues are busy.': 'Tot el personal està ocupat.',
        'Chat closed by %s': 'Xat tancat per %s',
        'Compose your message…': 'Redacta el teu missatge…',
        'Connecting': 'Connectant',
        'Connection lost': 'Connexió perduda',
        'Connection re-established': 'Connexió restablerta',
        'Offline': 'Fora de línia',
        'Online': 'En línia',
        'Scroll down to see new messages': 'Desplaçat més avall per veure nous missatges',
        'Send': 'Envia',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Com que no heu respost en els darrers %s minuts, la vostra conversa s\'ha tancat.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Com que no heu respost en els darrers %s minuts, la vostra conversa amb <strong>%s</strong> s\'ha tancat.',
        'Start new conversation': 'Inicia una conversa nova',
        'Today': 'Avui',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Ho sentim, està tardant més del que s\'esperava per aconseguir un espai. Si us plau, torna-ho a intentar més tard o envia\'ns un correu electrònic. Gràcies!',
        'You are on waiting list position <strong>%s</strong>.': 'Estàs en la posició <strong>%s</strong> de la llista d\'espera.'
      },
      'cs': {
        '<strong>Chat</strong> with us!': '<strong>Chatujte</strong> s námi!',
        'All colleagues are busy.': 'Všichni kolegové jsou vytíženi.',
        'Chat closed by %s': '%s ukončil konverzaci',
        'Compose your message…': 'Napište svou zprávu…',
        'Connecting': 'Připojování',
        'Connection lost': 'Připojení ztraceno',
        'Connection re-established': 'Připojení obnoveno',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Srolujte dolů pro zobrazení nových zpráv',
        'Send': 'Odeslat',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace byla uzavřena.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace s <strong>%s</strong> byla uzavřena.',
        'Start new conversation': 'Zahájit novou konverzaci',
        'Today': 'Dnes',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Omlouváme se, že musíte čekat déle, než je vhodné pro získání slotu. Prosím, zkuste to později, případně nám napište e-mail. Děkujeme!',
        'You are on waiting list position <strong>%s</strong>.': 'Jste <strong>%s</strong>. v pořadí na čekací listině.'
      },
      'da': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med os!',
        'All colleagues are busy.': 'Alle medarbejdere er optaget.',
        'Chat closed by %s': 'Chat lukket af %s',
        'Compose your message…': 'Skriv din besked…',
        'Connecting': 'Forbinder',
        'Connection lost': 'Forbindelse mistet',
        'Connection re-established': 'Forbindelse genoprettet',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Rul ned for at se nye beskeder',
        'Send': 'Send',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da du ikke svarede inden for de sidste %s minutter, blev din samtale lukket.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da du ikke svarede inden for de sidste %s minutter, blev din samtale med <strong>%s</strong> lukket.',
        'Start new conversation': 'Start en ny samtale',
        'Today': 'I dag',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Vi beklager, det tager længere end forventet at få en ledig plads. Prøv igen senere, eller send os en email. Tak!',
        'You are on waiting list position <strong>%s</strong>.': 'Du er i kø som nummer <strong>%s</strong>.'
      },
      'de': {
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!',
        'All colleagues are busy.': 'Alle Kollegen sind beschäftigt.',
        'Chat closed by %s': 'Chat von %s geschlossen',
        'Compose your message…': 'Verfassen Sie Ihre Nachricht…',
        'Connecting': 'Verbinde',
        'Connection lost': 'Verbindung verloren',
        'Connection re-established': 'Verbindung wieder aufgebaut',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Nach unten scrollen um neue Nachrichten zu sehen',
        'Send': 'Senden',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung geschlossen.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung mit <strong>%s</strong> geschlossen.',
        'Start new conversation': 'Neue Unterhaltung starten',
        'Today': 'Heute',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Entschuldigung, es dauert länger als erwartet einen freien Platz zu bekommen. Versuchen Sie es später erneut oder senden Sie uns eine E-Mail. Vielen Dank!',
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste auf Position <strong>%s</strong>.'
      },
      'es': {
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!',
        'All colleagues are busy.': 'Todos los colegas están ocupados.',
        'Chat closed by %s': 'Chat cerrado por %s',
        'Compose your message…': 'Escribe tu mensaje…',
        'Connecting': 'Conectando',
        'Connection lost': 'Conexión perdida',
        'Connection re-established': 'Conexión reestablecida',
        'Offline': 'Desconectado',
        'Online': 'En línea',
        'Scroll down to see new messages': 'Desplace hacia abajo para ver nuevos mensajes',
        'Send': 'Enviar',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación se ha cerrado.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación con <strong>%s</strong> se ha cerrado.',
        'Start new conversation': 'Iniciar nueva conversación',
        'Today': 'Hoy',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, estamos tardando más de lo esperado para asignar un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!',
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
      },
      'fa': {
        '<strong>Chat</strong> with us!': 'با ما <strong>گفتگو کنید</strong>!',
        'All colleagues are busy.': 'تمام همکاران مشغول هستند.',
        'Chat closed by %s': 'چت توسط %s بسته شد',
        'Compose your message…': 'پیام خود را وارد نمایید…',
        'Connecting': 'درحال برقراری ارتباط',
        'Connection lost': 'ارتباط قطع شد',
        'Connection re-established': 'ارتباط مجددا برقرار شد',
        'Offline': 'برون خط',
        'Online': 'آنلاین',
        'Scroll down to see new messages': 'برای دیدن پیام‌های جدید به سمت پایین حرکت کنید',
        'Send': 'ارسال',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'از آنجایی که در %s دقیقه گذشته پاسخی ندادید، مکالمه شما بسته شد.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'از آنجایی که در %s دقیقه گذشته پاسخی ندادید، مکالمه شما با <strong>%s</strong> بسته شد.',
        'Start new conversation': 'شروع مکالمه جدید',
        'Today': 'امروز',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'متاسفیم، گرفتن یک موقعیت بیشتر از حد انتظار طول می‌کشد. لطفاً بعداً دوباره تلاش کنید یا برای ما ایمیل بفرستید. متشکریم!',
        'You are on waiting list position <strong>%s</strong>.': 'شما در موقعیت لیست انتظار <strong>%s</strong> هستید.'
      },
      'fr': {
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous !',
        'All colleagues are busy.': 'Tous les agents sont occupés.',
        'Chat closed by %s': 'Chat fermé par %s',
        'Compose your message…': 'Écrivez votre message…',
        'Connecting': 'Connexion',
        'Connection lost': 'Connexion perdue',
        'Connection re-established': 'Connexion ré-établie',
        'Offline': 'Hors-ligne',
        'Online': 'En ligne',
        'Scroll down to see new messages': 'Défiler vers le bas pour voir les nouveaux messages',
        'Send': 'Envoyer',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Sans réponse de votre part depuis %s minutes, votre conservation a été fermée.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Sans réponse de votre part depuis %s minutes, votre conversation avec <strong>%s</strong> a été fermée.',
        'Start new conversation': 'Démarrer une nouvelle conversation',
        'Today': 'Aujourd\'hui',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, trouver un agent disponible prend plus de temps que prévu. Réessayez ultérieurement ou envoyez-nous un mail. Merci !',
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.'
      },
      'hr': {
        '<strong>Chat</strong> with us!': '<strong>Čavrljajte</strong> sa nama!',
        'All colleagues are busy.': 'Svi agenti su zauzeti.',
        'Chat closed by %s': '%s zatvara chat',
        'Compose your message…': 'Sastavite poruku…',
        'Connecting': 'Povezivanje',
        'Connection lost': 'Veza prekinuta',
        'Connection re-established': 'Veza je ponovno uspostavljena',
        'Offline': 'Odsutan',
        'Online': 'Dostupan(a)',
        'Scroll down to see new messages': 'Pomaknite se prema dolje da biste vidjeli nove poruke',
        'Send': 'Pošalji',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor zatvoren.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor s <strong>%</strong>s zatvoren.',
        'Start new conversation': 'Započni novi razgovor',
        'Today': 'Danas',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Oprostite, traje duže nego inače za dobiti slobodan termin. Molimo, pokušajte ponovno kasnije ili nam pošaljite e-mail. Hvala!',
        'You are on waiting list position <strong>%s</strong>.': 'Nalazite se u redu čekanja na poziciji <strong>%s</strong>.'
      },
      'hu': {
        '<strong>Chat</strong> with us!': '<strong>Csevegjen</strong> velünk!',
        'All colleagues are busy.': 'Az összes munkatárs elfoglalt.',
        'Chat closed by %s': 'A csevegés %s által lezárva',
        'Compose your message…': 'Üzenet írása…',
        'Connecting': 'Kapcsolatépítés',
        'Connection lost': 'A kapcsolat megszakadt',
        'Connection re-established': 'A kapcsolat helyreállt',
        'Offline': 'Kapcsolat nélkül',
        'Online': 'Elérhető',
        'Scroll down to see new messages': 'Görgessen le az új üzenetek megtekintéséhez',
        'Send': 'Küldés',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Mivel nem válaszolt az elmúlt %s percben, a beszélgetése lezárásra került.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Mivel nem válaszolt az elmúlt %s percben, <strong>%s</strong> ügyintézővel folytatott beszélgetése lezárásra került.',
        'Start new conversation': 'Új beszélgetés indítása',
        'Today': 'Ma',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, a vártnál hosszabb ideig tart a helyfoglalás. Próbálja meg később újra, vagy küldjön nekünk e-mailt. Köszönjük!',
        'You are on waiting list position <strong>%s</strong>.': 'Ön a várólista <strong>%s.</strong> helyén szerepel.'
      },
      'id': {
        '<strong>Chat</strong> with us!': '<strong>Obrolan</strong> dengan kami!',
        'All colleagues are busy.': 'Semua rekan sedang sibuk.',
        'Chat closed by %s': 'Obrolan ditutup oleh %s',
        'Compose your message…': 'Tulis pesan Anda…',
        'Connecting': 'Menghubungkan',
        'Connection lost': 'Koneksi terputus',
        'Connection re-established': 'Koneksi dipulihkan',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Gulir ke bawah untuk melihat pesan baru',
        'Send': 'Kirim',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Karena Anda tidak membalas dalam %s menit terakhir, percakapan Anda ditutup.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Karena Anda tidak membalas dalam %s menit terakhir, percakapan Anda dengan <strong>%s</strong> ditutup.',
        'Start new conversation': 'Mulai percakapan baru',
        'Today': 'Hari ini',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Kami minta maaf, proses ini memakan waktu lebih lama dari yang diharapkan untuk mendapatkan slot. Silakan coba lagi nanti atau kirimkan email ke kami. Terima kasih!',
        'You are on waiting list position <strong>%s</strong>.': 'Anda berada di posisi daftar tunggu <strong>%s</strong>.'
      },
      'it': {
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!',
        'All colleagues are busy.': 'Tutti i colleghi sono occupati.',
        'Chat closed by %s': 'Chat chiusa da %s',
        'Compose your message…': 'Scrivi il tuo messaggio…',
        'Connecting': 'Connessione in corso',
        'Connection lost': 'Connessione persa',
        'Connection re-established': 'Connessione ristabilita',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Scorri verso il basso per vedere i nuovi messaggi',
        'Send': 'Invia',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione è stata chiusa.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione con <strong>%s</strong> è stata chiusa.',
        'Start new conversation': 'Avvia una nuova chat',
        'Today': 'Oggi',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Siamo spiacenti, ci vuole più tempo del previsto per ottenere uno spazio libero. Riprova più tardi o inviaci un\'e-mail. Grazie!',
        'You are on waiting list position <strong>%s</strong>.': 'Sei alla posizione <strong>%s</strong> della lista di attesa.'
      },
      'ko': {
        '<strong>Chat</strong> with us!': '우리와 <strong>채팅</strong> !',
        'All colleagues are busy.': '모든 동료가 바쁩니다.',
        'Chat closed by %s': '%s에 의해 채팅 종료',
        'Compose your message…': '메시지를 작성하세요…',
        'Connecting': '연결 중',
        'Connection lost': '연결 끊김',
        'Connection re-established': '연결 재설정됨',
        'Offline': '오프라인',
        'Online': '온라인',
        'Scroll down to see new messages': '새 메시지를 보려면 아래로 스크롤',
        'Send': '보내기',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': '지난 %s분 동안 응답하지 않아 대화가 종료되었습니다.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': '지난 %s분 동안 응답하지 않아 <strong>%s</strong>님과의 대화가 종료되었습니다.',
        'Start new conversation': '새 대화 시작',
        'Today': '오늘',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': '죄송합니다. 슬롯을 받는 데 예상보다 시간이 오래 걸리고 있습니다. 나중에 다시 시도하거나 이메일을 보내주세요. 감사합니다!',
        'You are on waiting list position <strong>%s</strong>.': '대기 목록 위치 <strong>%s</strong>에 있습니다.'
      },
      'lt': {
        '<strong>Chat</strong> with us!': '<strong>Kalbėkitės</strong> su mumis!',
        'All colleagues are busy.': 'Visi kolegos užimti.',
        'Chat closed by %s': '%s uždarė pokalbį',
        'Compose your message…': 'Rašykite žinutę…',
        'Connecting': 'Jungiamasi',
        'Connection lost': 'Dingo ryšys',
        'Connection re-established': 'Ryšys atnaujintas',
        'Offline': 'Atsijungęs',
        'Online': 'Prisijungęs',
        'Scroll down to see new messages': 'Naujos žinutės žemiau',
        'Send': 'Siųsti',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jūsų pokalbis buvo uždarytas, nes nieko neatsakėte per %s minučių.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jūsų pokalbis su <strong>%s</strong> buvo uždarytas, nes nieko neatsakėte per %s minučių.',
        'Start new conversation': 'Pradėti naują pokalbį',
        'Today': 'Šiandien',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Atsiprašome, kad tenka laukti atskymo. Bandykite vėliau arba rašykite el. paštu. Ačiū!',
        'You are on waiting list position <strong>%s</strong>.': 'Esate <strong>%s</strong> eilėje.'
      },
      'nl': {
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!',
        'All colleagues are busy.': 'Alle collega\'s zijn bezet.',
        'Chat closed by %s': 'Chat gesloten door %s',
        'Compose your message…': 'Stel je bericht op…',
        'Connecting': 'Verbinden',
        'Connection lost': 'Verbinding verbroken',
        'Connection re-established': 'Verbinding hersteld',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Scroll naar beneden om nieuwe tickets te bekijken',
        'Send': 'Verstuur',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'De chat is afgesloten omdat je de laatste %s minuten niet hebt gereageerd.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Je chat met <strong>%s</strong> is afgesloten omdat je niet hebt gereageerd in de laatste %s minuten.',
        'Start new conversation': 'Nieuw gesprek starten',
        'Today': 'Vandaag',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om een chat te starten. Probeer het later nog eens of stuur ons een e-mail. Bedankt!',
        'You are on waiting list position <strong>%s</strong>.': 'Je bevindt zich op wachtlijstpositie <strong>%s</strong>.'
      },
      'pl': {
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!',
        'All colleagues are busy.': 'Wszyscy agenci są zajęci.',
        'Chat closed by %s': 'Chat zamknięty przez %s',
        'Compose your message…': 'Skomponuj swoją wiadomość…',
        'Connecting': 'Łączenie',
        'Connection lost': 'Utracono połączenie',
        'Connection re-established': 'Ponowne nawiązanie połączenia',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Skroluj w dół, aby zobaczyć wiadomości',
        'Send': 'Wyślij',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa z <strong>%s</strong> została zamknięta.',
        'Start new conversation': 'Rozpocznij nową rozmowę',
        'Today': 'Dzisiaj',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Przepraszamy, znalezienie wolnego konsultanta zajmuje więcej czasu niż oczekiwano. Spróbuj ponownie później lub wyślij nam e-mail. Dziękujemy!',
        'You are on waiting list position <strong>%s</strong>.': 'Jesteś na pozycji listy oczekujących <strong>%s</strong>.'
      },
      'pt-br': {
        '<strong>Chat</strong> with us!': '<strong>Converse</strong> conosco!',
        'All colleagues are busy.': 'Todos os agentes estão ocupados.',
        'Chat closed by %s': 'Chat encerrado por %s',
        'Compose your message…': 'Escreva sua mensagem…',
        'Connecting': 'Conectando',
        'Connection lost': 'Conexão perdida',
        'Connection re-established': 'Conexão restabelecida',
        'Offline': 'Desconectado',
        'Online': 'Online',
        'Scroll down to see new messages': 'Role para baixo para ver novas mensagens',
        'Send': 'Enviar',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa foi encerrada.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa com <strong>%s</strong> foi encerrada.',
        'Start new conversation': 'Iniciar uma nova conversa',
        'Today': 'Hoje',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lamentamos, está demorando mais do que o esperado para conseguir uma vaga. Tente novamente mais tarde ou envie-nos um email. Obrigado!',
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> da lista de espera.'
      },
      'ro': {
        '<strong>Chat</strong> with us!': '<strong>Comunică</strong> cu noi!',
        'All colleagues are busy.': 'Toți colegii sunt ocupați momentan.',
        'Chat closed by %s': 'Chat închis de către %s',
        'Compose your message…': 'Compune-ți mesajul…',
        'Connecting': 'Se conectează',
        'Connection lost': 'Conexiune pierdută',
        'Connection re-established': 'Conexiune restabilită',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Derulați în jos pentru a vedea mesajele noi',
        'Send': 'Trimite',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta a fost închisă.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta cu <strong>%s</strong> a fost închisă.',
        'Start new conversation': 'Începe o conversație nouă',
        'Today': 'Azi',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Ne pare rău, durează mai mult decât ne așteptam să obținem un loc. Te rugăm să încerci din nou mai târziu sau să ne trimiți un email. Mulțumim!',
        'You are on waiting list position <strong>%s</strong>.': 'Aveți poziția <strong>%s</strong> în lista de așteptare.'
      },
      'ru': {
        '<strong>Chat</strong> with us!': '<strong>Напишите</strong> нам!',
        'All colleagues are busy.': 'Все коллеги заняты.',
        'Chat closed by %s': 'Чат закрыт %s',
        'Compose your message…': 'Составьте сообщение…',
        'Connecting': 'Подключение',
        'Connection lost': 'Подключение потеряно',
        'Connection re-established': 'Подключение восстановлено',
        'Offline': 'Оффлайн',
        'Online': 'В сети',
        'Scroll down to see new messages': 'Прокрутите вниз, чтобы увидеть новые сообщения',
        'Send': 'Отправить',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор был закрыт.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор с <strong>%s</strong> был закрыт.',
        'Start new conversation': 'Начать новый разговор',
        'Today': 'Сегодня',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Извините, получение свободного слота занимает больше времени, чем ожидалось. Пожалуйста, повторите попытку позже или отправьте нам электронное письмо. Благодарим Вас!',
        'You are on waiting list position <strong>%s</strong>.': 'Вы находитесь в списке ожидания <strong>%s</strong>.'
      },
      'sk': {
        '<strong>Chat</strong> with us!': '<strong>Napíšte</strong> nám cez chat!',
        'All colleagues are busy.': 'Všetci kolegovia sú zaneprázdnení.',
        'Chat closed by %s': 'Chat zatvoril(a) %s',
        'Compose your message…': 'Napíšte vašu správu…',
        'Connecting': 'Pripája sa',
        'Connection lost': 'Spojenie prerušené',
        'Connection re-established': 'Pripojenie obnovené',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Posuňte sa nadol, aby ste videli nové správy',
        'Send': 'Odoslať',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Keďže ste neodpovedali v posledných %s minútach, vaša konverzácia bola uzavretá.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Keďže ste v posledných %s minútach neodpovedali, vaša konverzácia s <strong>%s</strong> bola ukončená.',
        'Start new conversation': 'Začať novú konverzáciu',
        'Today': 'Dnes',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Je nám ľúto, že získanie slotu trvá dlhšie, než sme očakávali. Skúste to prosím neskôr alebo nám pošlite e-mail. Ďakujeme!',
        'You are on waiting list position <strong>%s</strong>.': 'Na čakacej listine ste na pozícii <strong>%s</strong>.'
      },
      'sr': {
        '<strong>Chat</strong> with us!': '<strong>Ћаскајте</strong> са нама!',
        'All colleagues are busy.': 'Све колеге су заузете.',
        'Chat closed by %s': 'Ћаскање затворено од стране %s',
        'Compose your message…': 'Напишите поруку…',
        'Connecting': 'Повезивање',
        'Connection lost': 'Веза је изгубљена',
        'Connection re-established': 'Веза је поново успостављена',
        'Offline': 'Одсутан(а)',
        'Online': 'Доступан(а)',
        'Scroll down to see new messages': 'Скролујте на доле за нове поруке',
        'Send': 'Пошаљи',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор је завршен.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор са <strong>%s</strong> је завршен.',
        'Start new conversation': 'Започни нови разговор',
        'Today': 'Данас',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Жао нам је, добијање празног термина траје дуже од очекиваног. Молимо покушајте поново касније или нам пошаљите имејл поруку. Хвала вам!',
        'You are on waiting list position <strong>%s</strong>.': 'Ви сте тренутно <strong>%s.</strong> у реду за чекање.'
      },
      'sr-latn-rs': {
        '<strong>Chat</strong> with us!': '<strong>Ćaskajte</strong> sa nama!',
        'All colleagues are busy.': 'Sve kolege su zauzete.',
        'Chat closed by %s': 'Ćaskanje zatvoreno od strane %s',
        'Compose your message…': 'Napišite poruku…',
        'Connecting': 'Povezivanje',
        'Connection lost': 'Veza je izgubljena',
        'Connection re-established': 'Veza je ponovo uspostavljena',
        'Offline': 'Odsutan(a)',
        'Online': 'Dostupan(a)',
        'Scroll down to see new messages': 'Skrolujte na dole za nove poruke',
        'Send': 'Pošalji',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor je završen.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor sa <strong>%s</strong> je završen.',
        'Start new conversation': 'Započni novi razgovor',
        'Today': 'Danas',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Žao nam je, dobijanje praznog termina traje duže od očekivanog. Molimo pokušajte ponovo kasnije ili nam pošaljite imejl poruku. Hvala vam!',
        'You are on waiting list position <strong>%s</strong>.': 'Vi ste trenutno <strong>%s.</strong> u redu za čekanje.'
      },
      'sv': {
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!',
        'All colleagues are busy.': 'Alla kollegor är upptagna.',
        'Chat closed by %s': 'Chatt stängd av %s',
        'Compose your message…': 'Skriv ditt meddelande …',
        'Connecting': 'Ansluter',
        'Connection lost': 'Anslutningen försvann',
        'Connection re-established': 'Anslutningen återupprättas',
        'Offline': 'Offline',
        'Online': 'Online',
        'Scroll down to see new messages': 'Bläddra ner för att se nya meddelanden',
        'Send': 'Skicka',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Din chatt avslutades då du inte svarade inom %s minuter.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Chatten stängdes eftersom du inte svarat inom %s minuter i din konversation med <strong>%s</strong>.',
        'Start new conversation': 'Starta ny konversation',
        'Today': 'Idag',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Det tar tyvärr längre tid än förväntat att få en ledig plats. Försök igen senare eller skicka ett mejl till oss. Tack!',
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.'
      },
      'tr': {
        '<strong>Chat</strong> with us!': 'Bizimle <strong>Sohbet</strong> edin!',
        'All colleagues are busy.': 'Tüm meslektaşlar meşgul.',
        'Chat closed by %s': 'Sohbet %s tarafından kapatıldı',
        'Compose your message…': 'Mesajınızı yazın…',
        'Connecting': 'Bağlanıyor',
        'Connection lost': 'Bağlantı koptu',
        'Connection re-established': 'Bağlantı yeniden sağlandı',
        'Offline': 'Çevrimdışı',
        'Online': 'Online',
        'Scroll down to see new messages': 'Scroll down to see new messages',
        'Send': 'Gönder',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Son %s dakika içinde yanıt vermediğiniz için görüşmeniz kapatıldı.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Son %s dakika içinde yanıt vermediğiniz için <strong>%s</strong> ile görüşmeniz sonlandırıldı.',
        'Start new conversation': 'Yeni görüşme başlat',
        'Today': 'Bugün',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Üzgünüz, yer bulmamız beklenenden daha uzun sürüyor. Lütfen daha sonra tekrar deneyin veya bize bir e-posta gönderin. Teşekkür ederiz!',
        'You are on waiting list position <strong>%s</strong>.': 'Bekleme listesindeki sıranız <strong>%s</strong>.'
      },
      'uk': {
        '<strong>Chat</strong> with us!': '<strong>Напишіть</strong> нам!',
        'All colleagues are busy.': 'Всі колеги зайняті.',
        'Chat closed by %s': 'Чат закрито %s',
        'Compose your message…': 'Складіть ваше повідомлення…',
        'Connecting': 'Підключення',
        'Connection lost': 'Підключення втрачено',
        'Connection re-established': 'Підключення відновлено',
        'Offline': 'Не в мережі',
        'Online': 'В мережі',
        'Scroll down to see new messages': 'Прокрутіть униз, щоб побачити нові повідомлення',
        'Send': 'Відправити',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Оскільки ви не відповіли протягом останніх %s хвилин, вашу розмову було закрито.',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Оскільки ви не відповіли протягом останніх %s хвилин, ваша розмова з <strong>%s</strong> була завершена.',
        'Start new conversation': 'Почніть нову розмову',
        'Today': 'Сьогодні',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Вибачте, отримання слоту займає більше часу, ніж очікувалося. Будь ласка, спробуйте пізніше або надішліть нам електронного листа. Дякуємо!',
        'You are on waiting list position <strong>%s</strong>.': 'Ви перебуваєте у списку очікування <strong>%s</strong>.'
      },
      'zh-cn': {
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!',
        'All colleagues are busy.': '所有同事都很忙。',
        'Chat closed by %s': '对话已被 %s 关闭',
        'Compose your message…': '编辑您的信息…',
        'Connecting': '连接中',
        'Connection lost': '连接丢失',
        'Connection re-established': '正在重新建立连接',
        'Offline': '离线',
        'Online': '在线',
        'Scroll down to see new messages': '向下滚动以查看新消息',
        'Send': '发送',
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': '"由于您超过 %s 分钟没有任何回复',
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': '"由于您超过 %s 分钟没有回复',
        'Start new conversation': '开始新的会话',
        'Today': '今天',
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': '',
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.'
      }
    };

    ZammadChat.prototype.sessionId = void 0;

    ZammadChat.prototype.lastSessionId = void 0;

    ZammadChat.prototype.feedbackScore = void 0;

    ZammadChat.prototype.phrases = {};

    ZammadChat.prototype.scrolledToBottom = true;

    ZammadChat.prototype.scrollSnapTolerance = 10;

    ZammadChat.prototype.richTextFormatKey = {
      66: true,
      73: true,
      85: true,
      83: true
    };

    ZammadChat.prototype.T = function() {
      var item, items, j, len, string, translations;
      string = arguments[0], items = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (this.options.lang && this.options.lang !== 'en') {
        if (!this.translations[this.options.lang]) {
          this.log.notice("Translation '" + this.options.lang + "' needed!");
        } else {
          translations = this.translations[this.options.lang];
          if (!translations[string]) {
            this.log.notice("Translation needed for '" + string + "'");
          }
          string = translations[string] || string;
        }
      }
      if (items) {
        for (j = 0, len = items.length; j < len; j++) {
          item = items[j];
          string = string.replace(/%s/, item);
        }
      }
      return string;
    };

    ZammadChat.prototype.view = function(name) {
      return (function(_this) {
        return function(options) {
          if (!options) {
            options = {};
          }
          options.T = _this.T;
          options.background = _this.options.background;
          options.flat = _this.options.flat;
          options.fontSize = _this.options.fontSize;
          options.phrases = _this.phrases;
          return window.zammadChatTemplates[name](options);
        };
      })(this);
    };

    function ZammadChat(options) {
      this.removeAttributes = bind(this.removeAttributes, this);
      this.startTimeoutObservers = bind(this.startTimeoutObservers, this);
      this.onCssLoaded = bind(this.onCssLoaded, this);
      this.apiBaseUrl = bind(this.apiBaseUrl, this);
      this.setAgentOnlineState = bind(this.setAgentOnlineState, this);
      this.updatePhrases = bind(this.updatePhrases, this);
      this.updateHomeLogo = bind(this.updateHomeLogo, this);
      this.showWelcomeGreeting = bind(this.showWelcomeGreeting, this);
      this.onConnectionEstablished = bind(this.onConnectionEstablished, this);
      this.setSessionId = bind(this.setSessionId, this);
      this.markMessagesRead = bind(this.markMessagesRead, this);
      this.onSessionClosed = bind(this.onSessionClosed, this);
      this.onReconnectFailed = bind(this.onReconnectFailed, this);
      this.onIoReconnected = bind(this.onIoReconnected, this);
      this.onIoReconnecting = bind(this.onIoReconnecting, this);
      this.destroy = bind(this.destroy, this);
      this.onScrollHintClick = bind(this.onScrollHintClick, this);
      this.detectScrolledtoBottom = bind(this.detectScrolledtoBottom, this);
      this.updateLauncherConnectionState = bind(this.updateLauncherConnectionState, this);
      this.hideConnectionOverlay = bind(this.hideConnectionOverlay, this);
      this.showConnectionOverlay = bind(this.showConnectionOverlay, this);
      this.connectionOverlayCopy = bind(this.connectionOverlayCopy, this);
      this.onLeaveTemporary = bind(this.onLeaveTemporary, this);
      this.onAgentTypingEnd = bind(this.onAgentTypingEnd, this);
      this.onAgentTypingStart = bind(this.onAgentTypingStart, this);
      this.onQueue = bind(this.onQueue, this);
      this.onQueueScreen = bind(this.onQueueScreen, this);
      this.onWebSocketClose = bind(this.onWebSocketClose, this);
      this.onCloseAnimationEnd = bind(this.onCloseAnimationEnd, this);
      this.goToStartChat = bind(this.goToStartChat, this);
      this.exitChat = bind(this.exitChat, this);
      this.close = bind(this.close, this);
      this.toggle = bind(this.toggle, this);
      this.cancelQueue = bind(this.cancelQueue, this);
      this.sessionClose = bind(this.sessionClose, this);
      this.onOpenAnimationEnd = bind(this.onOpenAnimationEnd, this);
      this.hideFeedbackThanksOverlay = bind(this.hideFeedbackThanksOverlay, this);
      this.showFeedbackThanks = bind(this.showFeedbackThanks, this);
      this.skipFeedback = bind(this.skipFeedback, this);
      this.onFeedbackSubmitResult = bind(this.onFeedbackSubmitResult, this);
      this.submitFeedback = bind(this.submitFeedback, this);
      this.selectFeedbackScore = bind(this.selectFeedbackScore, this);
      this.showFeedback = bind(this.showFeedback, this);
      this.finishOfflineFlow = bind(this.finishOfflineFlow, this);
      this.showOfflineSent = bind(this.showOfflineSent, this);
      this.onOfflineMessageSendResult = bind(this.onOfflineMessageSendResult, this);
      this.uploadOfflineAttachment = bind(this.uploadOfflineAttachment, this);
      this.triggerOfflineAttachmentInput = bind(this.triggerOfflineAttachmentInput, this);
      this.submitOfflineMessage = bind(this.submitOfflineMessage, this);
      this.showOfflineCompose = bind(this.showOfflineCompose, this);
      this.onOfflineOtpResendResult = bind(this.onOfflineOtpResendResult, this);
      this.resendOfflineOtp = bind(this.resendOfflineOtp, this);
      this.onOfflineOtpVerifyResult = bind(this.onOfflineOtpVerifyResult, this);
      this.showOtpError = bind(this.showOtpError, this);
      this.submitOfflineOtp = bind(this.submitOfflineOtp, this);
      this.onOtpDigitPaste = bind(this.onOtpDigitPaste, this);
      this.onOtpDigitKeydown = bind(this.onOtpDigitKeydown, this);
      this.onOtpDigitInput = bind(this.onOtpDigitInput, this);
      this.showOfflineOtp = bind(this.showOfflineOtp, this);
      this.onOfflineSessionInitResult = bind(this.onOfflineSessionInitResult, this);
      this.applyOfflineHomeState = bind(this.applyOfflineHomeState, this);
      this.enterOfflineMode = bind(this.enterOfflineMode, this);
      this.submitPrechatForm = bind(this.submitPrechatForm, this);
      this.setButtonLoading = bind(this.setButtonLoading, this);
      this.showPrechatForm = bind(this.showPrechatForm, this);
      this.open = bind(this.open, this);
      this.addAttachmentMessage = bind(this.addAttachmentMessage, this);
      this.uploadAttachment = bind(this.uploadAttachment, this);
      this.triggerAttachmentInput = bind(this.triggerAttachmentInput, this);
      this.renderReplyIndicator = bind(this.renderReplyIndicator, this);
      this.cancelReply = bind(this.cancelReply, this);
      this.startReply = bind(this.startReply, this);
      this.renderMessage = bind(this.renderMessage, this);
      this.playMessageSound = bind(this.playMessageSound, this);
      this.receiveMessage = bind(this.receiveMessage, this);
      this.onSubmit = bind(this.onSubmit, this);
      this.onFocus = bind(this.onFocus, this);
      this.onInput = bind(this.onInput, this);
      this.onReopenSession = bind(this.onReopenSession, this);
      this.onError = bind(this.onError, this);
      this.onWebSocketMessage = bind(this.onWebSocketMessage, this);
      this.send = bind(this.send, this);
      this.checkForEnter = bind(this.checkForEnter, this);
      this.onKbResultsScroll = bind(this.onKbResultsScroll, this);
      this.onKnowledgeBaseSearchResult = bind(this.onKnowledgeBaseSearchResult, this);
      this.loadKnowledgeBase = bind(this.loadKnowledgeBase, this);
      this.onKbSearchInput = bind(this.onKbSearchInput, this);
      this.insertEmoji = bind(this.insertEmoji, this);
      this.toggleEmojiPicker = bind(this.toggleEmojiPicker, this);
      this.updateHeader = bind(this.updateHeader, this);
      this.switchTab = bind(this.switchTab, this);
      this.hidePreload = bind(this.hidePreload, this);
      this.render = bind(this.render, this);
      this.view = bind(this.view, this);
      this.T = bind(this.T, this);
      this.options = $.extend({}, this.defaults, options);
      ZammadChat.__super__.constructor.call(this, this.options);
      this.isFullscreen = window.matchMedia && window.matchMedia('(max-width: 768px)').matches;
      this.scrollRoot = $(this.getScrollRoot());
      if (!$) {
        this.state = 'unsupported';
        this.log.notice('Chat: no jquery found!');
        return;
      }
      if (!window.WebSocket || !sessionStorage) {
        this.state = 'unsupported';
        this.log.notice('Chat: Browser not supported!');
        return;
      }
      if (!this.options.chatId) {
        this.state = 'unsupported';
        this.log.error('Chat: need chatId as option!');
        return;
      }
      if (!this.options.lang) {
        this.options.lang = $('html').attr('lang');
      }
      if (this.options.lang) {
        if (!this.translations[this.options.lang]) {
          this.log.debug("lang: No " + this.options.lang + " found, try first two letters");
          this.options.lang = this.options.lang.replace(/-.+?$/, '');
        }
        this.log.debug("lang: " + this.options.lang);
      }
      if (!this.options.host) {
        this.detectHost();
      }
      this.loadCss();
      this.io = new Io(this.options);
      this.io.set({
        onOpen: this.render,
        onClose: this.onWebSocketClose,
        onMessage: this.onWebSocketMessage,
        onError: this.onError,
        onReconnecting: this.onIoReconnecting,
        onReconnected: this.onIoReconnected,
        onReconnectFailed: this.onReconnectFailed
      });
      this.io.connect();
      this.replyTo = null;
      this.agentMessagesById = {};
    }

    ZammadChat.prototype.getScrollRoot = function() {
      var end, html, start;
      if ('scrollingElement' in document) {
        return document.scrollingElement;
      }
      html = document.documentElement;
      start = html.scrollTop;
      html.scrollTop = start + 1;
      end = html.scrollTop;
      html.scrollTop = start;
      if (end > start) {
        return html;
      } else {
        return document.body;
      }
    };

    ZammadChat.prototype.render = function() {
      if (!this.el || !$('.zammad-chat').get(0)) {
        this.renderBase();
      }
      $("." + this.options.buttonClass).addClass(this.options.inactiveClass);
      this.setAgentOnlineState('online');
      this.log.debug('widget rendered');
      this.startTimeoutObservers();
      this.idleTimeout.start();
      this.sessionId = sessionStorage.getItem('sessionId');
      this.customerName = sessionStorage.getItem('customerName');
      return this.send('chat_status_customer', {
        session_id: this.sessionId,
        url: window.location.href
      });
    };

    ZammadChat.prototype.showPreload = function() {
      if (this.preloadEl) {
        return;
      }
      this.preloadEl = $(this.view('preload')());
      return this.options.target.append(this.preloadEl);
    };

    ZammadChat.prototype.hidePreload = function() {
      if (!this.preloadEl) {
        return;
      }
      this.preloadEl.remove();
      return this.preloadEl = void 0;
    };

    ZammadChat.prototype.renderBase = function() {
      this.showPreload();
      this.el = $(this.view('chat')({
        title: this.options.title,
        scrollHint: this.options.scrollHint
      }));
      if (!this.cssLoaded) {
        this.el.css('display', 'none');
      }
      this.options.target.append(this.el);
      this.launcherEl = $(this.view('launcher')());
      if (!this.cssLoaded) {
        this.launcherEl.css('display', 'none');
      }
      this.options.target.append(this.launcherEl);
      this.launcherEl.on('click', this.toggle);
      this.input = this.el.find('.zammad-chat-input');
      this.el.find('.js-chat-close').on('click', this.exitChat);
      this.el.find('.js-chat-minimize').on('click', this.close);
      this.el.find('.zammad-chat-agent').on('click', '.js-chat-status', this.stopPropagation);
      this.el.find('.zammad-chat-controls').on('submit', this.onSubmit);
      this.el.find('.zammad-chat-body').on('scroll', this.detectScrolledtoBottom);
      this.el.find('.zammad-scroll-hint').on('click', this.onScrollHintClick);
      this.el.find('.zammad-chat-body').on('click', '.js-message-reply', this.startReply);
      this.el.find('.js-reply-indicator').on('click', '.js-reply-cancel', this.cancelReply);
      this.el.find('.zammad-chat-modal').on('click', '.js-waiting-cancel', this.cancelQueue);
      this.el.find('.zammad-chat-modal').on('click', '.js-otp-submit', this.submitOfflineOtp);
      this.el.find('.zammad-chat-modal').on('click', '.js-otp-resend', this.resendOfflineOtp);
      this.el.find('.zammad-chat-modal').on('click', '.js-otp-change-email', (function(_this) {
        return function() {
          return _this.showPrechatForm();
        };
      })(this));
      this.el.find('.zammad-chat-modal').on('input', '.js-otp-digit', this.onOtpDigitInput);
      this.el.find('.zammad-chat-modal').on('keydown', '.js-otp-digit', this.onOtpDigitKeydown);
      this.el.find('.zammad-chat-modal').on('paste', '.js-otp-digit', this.onOtpDigitPaste);
      this.el.find('.zammad-chat-modal').on('click', '.js-offline-compose-submit', this.submitOfflineMessage);
      this.el.find('.zammad-chat-modal').on('click', '.js-offline-sent-done', this.finishOfflineFlow);
      this.el.find('.zammad-chat-modal').on('click', '.js-offline-compose-attach', this.triggerOfflineAttachmentInput);
      this.el.find('.zammad-chat-modal').on('change', '.js-offline-compose-attachment-input', this.uploadOfflineAttachment);
      this.el.on('click', '.js-feedback-star', this.selectFeedbackScore);
      this.el.on('click', '.js-feedback-submit', this.submitFeedback);
      this.el.on('click', '.js-feedback-skip', this.skipFeedback);
      this.el.find('.js-chat-attach').on('click', this.triggerAttachmentInput);
      this.el.find('.js-chat-attachment-input').on('change', this.uploadAttachment);
      this.el.find('.zammad-chat-tab-body--home').html(this.view('home')());
      this.el.find('.zammad-chat-tab-body--help').html(this.view('help')());
      this.el.find('.zammad-chat-tabbar').html(this.view('tabbar')());
      this.el.find('.js-emoji-picker').html(this.view('emoji_picker')());
      this.activeTab = 'home';
      this.updateHeader('home');
      this.el.on('click', '[data-tab]', (function(_this) {
        return function(event) {
          var isHomeAction, target;
          target = $(event.currentTarget);
          isHomeAction = target.closest('.zammad-chat-home-actions').length > 0;
          if (isHomeAction) {
            _this.setButtonLoading(target, true);
          }
          _this.switchTab(target.data('tab'));
          if (isHomeAction) {
            return _this.setButtonLoading(target, false);
          }
        };
      })(this));
      this.el.on('click', '.js-connection-reload', (function(_this) {
        return function(event) {
          return window.location.reload();
        };
      })(this));
      this.el.find('.js-emoji-toggle').on('click', this.toggleEmojiPicker);
      this.el.find('.js-emoji-picker').on('click', '.js-emoji-item', (function(_this) {
        return function(event) {
          return _this.insertEmoji($(event.currentTarget).data('emoji'));
        };
      })(this));
      this.el.on('input', '.js-kb-search', this.onKbSearchInput);
      this.el[0].addEventListener('scroll', this.onKbResultsScroll, true);
      this.input.on({
        keydown: this.checkForEnter,
        input: this.onInput
      });
      this.input.on('keydown', (function(_this) {
        return function(e) {
          var richtTextControl;
          richtTextControl = false;
          if (!e.altKey && !e.ctrlKey && e.metaKey) {
            richtTextControl = true;
          } else if (!e.altKey && e.ctrlKey && !e.metaKey) {
            richtTextControl = true;
          }
          if (richtTextControl && _this.richTextFormatKey[e.keyCode]) {
            e.preventDefault();
            if (e.keyCode === 66) {
              document.execCommand('bold');
              return true;
            }
            if (e.keyCode === 73) {
              document.execCommand('italic');
              return true;
            }
            if (e.keyCode === 85) {
              document.execCommand('underline');
              return true;
            }
            if (e.keyCode === 83) {
              document.execCommand('strikeThrough');
              return true;
            }
          }
        };
      })(this));
      this.input.on('paste', (function(_this) {
        return function(e) {
          var clipboardData, docType, html, htmlTmp, imageFile, imageInserted, item, match, reader, regex, replacementTag, sanitized, text;
          e.stopPropagation();
          e.preventDefault();
          clipboardData;
          if (e.clipboardData) {
            clipboardData = e.clipboardData;
          } else if (window.clipboardData) {
            clipboardData = window.clipboardData;
          } else if (e.originalEvent.clipboardData) {
            clipboardData = e.originalEvent.clipboardData;
          } else {
            throw 'No clipboardData support';
          }
          imageInserted = false;
          if (clipboardData && clipboardData.items && clipboardData.items[0]) {
            item = clipboardData.items[0];
            if (item.kind === 'file' && (item.type === 'image/png' || item.type === 'image/jpeg')) {
              imageFile = item.getAsFile();
              reader = new FileReader();
              reader.onload = function(e) {
                var img, insert, result;
                result = e.target.result;
                img = document.createElement('img');
                img.src = result;
                insert = function(dataUrl, width, height, isRetina) {
                  if (_this.isRetina()) {
                    width = width / 2;
                    height = height / 2;
                  }
                  result = dataUrl;
                  img = "<img style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">";
                  return document.execCommand('insertHTML', false, img);
                };
                return _this.resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
              };
              reader.readAsDataURL(imageFile);
              imageInserted = true;
            }
          }
          if (imageInserted) {
            return;
          }
          text = void 0;
          docType = void 0;
          try {
            text = clipboardData.getData('text/html');
            docType = 'html';
            if (!text || text.length === 0) {
              docType = 'text';
              text = clipboardData.getData('text/plain');
            }
            if (!text || text.length === 0) {
              docType = 'text2';
              text = clipboardData.getData('text');
            }
          } catch (error) {
            e = error;
            console.log('Sorry, can\'t insert markup because browser is not supporting it.');
            docType = 'text3';
            text = clipboardData.getData('text');
          }
          if (docType === 'text' || docType === 'text2' || docType === 'text3') {
            text = '<div>' + text.replace(/\n/g, '</div><div>') + '</div>';
            text = text.replace(/<div><\/div>/g, '<div><br></div>');
          }
          console.log('p', docType, text);
          if (docType === 'html') {
            sanitized = DOMPurify.sanitize(text);
            _this.log.debug('sanitized HTML clipboard', sanitized);
            html = $("<div>" + sanitized + "</div>");
            match = false;
            htmlTmp = text;
            regex = new RegExp('<(/w|w)\:[A-Za-z]');
            if (htmlTmp.match(regex)) {
              match = true;
              htmlTmp = htmlTmp.replace(regex, '');
            }
            regex = new RegExp('<(/o|o)\:[A-Za-z]');
            if (htmlTmp.match(regex)) {
              match = true;
              htmlTmp = htmlTmp.replace(regex, '');
            }
            if (match) {
              html = _this.wordFilter(html);
            }
            html = $(html);
            html.contents().each(function() {
              if (this.nodeType === 8) {
                return $(this).remove();
              }
            });
            html.find('a, font, small, time, form, label').replaceWith(function() {
              return $(this).contents();
            });
            replacementTag = 'div';
            html.find('textarea').each(function() {
              var newTag, outer;
              outer = this.outerHTML;
              regex = new RegExp('<' + this.tagName, 'i');
              newTag = outer.replace(regex, '<' + replacementTag);
              regex = new RegExp('</' + this.tagName, 'i');
              newTag = newTag.replace(regex, '</' + replacementTag);
              return $(this).replaceWith(newTag);
            });
            html.find('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove();
            _this.removeAttributes(html);
            text = html.html();
          }
          if (docType === 'text3') {
            _this.pasteHtmlAtCaret(text);
          } else {
            document.execCommand('insertHTML', false, text);
          }
          return true;
        };
      })(this));
      this.input.on('drop', (function(_this) {
        return function(e) {
          var dataTransfer, file, reader, x, y;
          e.stopPropagation();
          e.preventDefault();
          dataTransfer;
          if (window.dataTransfer) {
            dataTransfer = window.dataTransfer;
          } else if (e.originalEvent.dataTransfer) {
            dataTransfer = e.originalEvent.dataTransfer;
          } else {
            throw 'No clipboardData support';
          }
          x = e.clientX;
          y = e.clientY;
          file = dataTransfer.files[0];
          if (file.type.match('image.*')) {
            reader = new FileReader();
            reader.onload = function(e) {
              var img, insert, result;
              result = e.target.result;
              img = document.createElement('img');
              img.src = result;
              insert = function(dataUrl, width, height, isRetina) {
                var pos, range;
                if (_this.isRetina()) {
                  width = width / 2;
                  height = height / 2;
                }
                result = dataUrl;
                img = $("<img style=\"width: 100%; max-width: " + width + "px;\" src=\"" + result + "\">");
                img = img.get(0);
                if (document.caretPositionFromPoint) {
                  pos = document.caretPositionFromPoint(x, y);
                  range = document.createRange();
                  range.setStart(pos.offsetNode, pos.offset);
                  range.collapse();
                  return range.insertNode(img);
                } else if (document.caretRangeFromPoint) {
                  range = document.caretRangeFromPoint(x, y);
                  return range.insertNode(img);
                } else {
                  return console.log('could not find carat');
                }
              };
              return _this.resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
            };
            return reader.readAsDataURL(file);
          }
        };
      })(this));
      $(window).on('beforeunload', (function(_this) {
        return function() {
          return _this.onLeaveTemporary();
        };
      })(this));
      $(window).on('hashchange', (function(_this) {
        return function() {
          if (_this.isOpen) {
            if (_this.sessionId) {
              _this.send('chat_session_notice', {
                session_id: _this.sessionId,
                message: window.location.href
              });
            }
            return;
          }
          return _this.idleTimeout.start();
        };
      })(this));
      if (this.isFullscreen) {
        return this.input.on({
          focus: this.onFocus,
          focusout: this.onFocusOut
        });
      }
    };

    ZammadChat.prototype.switchTab = function(tabName) {
      if (this.activeTab === tabName) {
        return;
      }
      this.activeTab = tabName;
      this.el.find('.zammad-chat-tab-body').removeClass('is-active');
      this.el.find(".zammad-chat-tab-body--" + tabName).addClass('is-active');
      this.el.find('.zammad-chat-tabbar-item').removeClass('is-active');
      this.el.find(".zammad-chat-tabbar-item[data-tab='" + tabName + "']").addClass('is-active');
      this.updateHeader(tabName);
      if (tabName === 'help' && !this.kbLoaded) {
        this.kbLoaded = true;
        return this.loadKnowledgeBase(true);
      }
    };

    ZammadChat.prototype.updateHeader = function(tabName) {
      var showAgent, showTitle, showWelcome, title;
      if (tabName == null) {
        tabName = this.activeTab;
      }
      showAgent = tabName === 'messages' && (this.agent != null);
      showWelcome = tabName === 'home' && !showAgent;
      showTitle = !showWelcome && !showAgent;
      this.el.find('.zammad-chat-header').toggleClass('zammad-chat-header--tinted', showWelcome);
      this.el.find('.zammad-chat-welcome').toggleClass('zammad-chat-is-hidden', !showWelcome);
      this.el.find('.zammad-chat-agent').toggleClass('zammad-chat-is-hidden', !showAgent);
      this.el.find('.zammad-chat-header-title').toggleClass('zammad-chat-is-hidden', !showTitle);
      if (showTitle) {
        title = tabName === 'help' ? this.T('Help') : this.T('Messages');
        return this.el.find('.js-header-title-text').text(title);
      }
    };

    ZammadChat.prototype.toggleEmojiPicker = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.el.find('.js-emoji-picker').toggleClass('zammad-chat-is-hidden');
      return this.el.find('.js-emoji-toggle').toggleClass('is-active');
    };

    ZammadChat.prototype.insertEmoji = function(emoji) {
      this.input.trigger('focus');
      document.execCommand('insertText', false, emoji);
      this.el.find('.js-emoji-picker').addClass('zammad-chat-is-hidden');
      this.el.find('.js-emoji-toggle').removeClass('is-active');
      return this.onInput();
    };

    ZammadChat.prototype.onKbSearchInput = function(event) {
      var ref;
      this.kbQuery = ((ref = $(event.currentTarget).val()) != null ? ref.trim() : void 0) || '';
      if (this.kbSearchDelayId) {
        clearTimeout(this.kbSearchDelayId);
      }
      return this.kbSearchDelayId = setTimeout(((function(_this) {
        return function() {
          return _this.loadKnowledgeBase(true);
        };
      })(this)), 400);
    };

    ZammadChat.prototype.loadKnowledgeBase = function(reset) {
      if (this.kbLoading) {
        return;
      }
      if (!reset && !this.kbHasMore) {
        return;
      }
      if (reset) {
        this.kbOffset = 0;
      }
      this.kbLoading = true;
      this.el.find('.zammad-chat-kb-loading').removeClass('zammad-chat-is-hidden');
      return this.send('chat_knowledge_base_search', {
        query: this.kbQuery || '',
        offset: this.kbOffset || 0
      });
    };

    ZammadChat.prototype.onKnowledgeBaseSearchResult = function(data) {
      var isFirstPage, item, j, len, ref, ref1, results, results1;
      this.kbLoading = false;
      this.el.find('.zammad-chat-kb-loading').addClass('zammad-chat-is-hidden');
      if ((data.query || '') !== (this.kbQuery || '')) {
        return;
      }
      results = this.el.find('.zammad-chat-kb-results');
      isFirstPage = (data.offset || 0) === 0;
      if (isFirstPage) {
        results.empty();
      }
      this.kbHasMore = !!data.has_more;
      this.kbOffset = (data.offset || 0) + (((ref = data.result) != null ? ref.length : void 0) || 0);
      if (isFirstPage && (!data.result || data.result.length === 0)) {
        this.el.find('.zammad-chat-kb-empty').removeClass('zammad-chat-is-hidden');
        return;
      }
      this.el.find('.zammad-chat-kb-empty').addClass('zammad-chat-is-hidden');
      ref1 = data.result || [];
      results1 = [];
      for (j = 0, len = ref1.length; j < len; j++) {
        item = ref1[j];
        results1.push(results.append(this.view('kb_result')(item)));
      }
      return results1;
    };

    ZammadChat.prototype.onKbResultsScroll = function(event) {
      var el, ref;
      if (!((ref = event.target.classList) != null ? ref.contains('zammad-chat-kb-results') : void 0)) {
        return;
      }
      el = event.target;
      if (el.scrollTop + el.clientHeight < el.scrollHeight - 200) {
        return;
      }
      return this.loadKnowledgeBase(false);
    };

    ZammadChat.prototype.stopPropagation = function(event) {
      return event.stopPropagation();
    };

    ZammadChat.prototype.checkForEnter = function(event) {
      if (!this.inputDisabled && !event.shiftKey && event.keyCode === 13) {
        event.preventDefault();
        return this.sendMessage();
      }
    };

    ZammadChat.prototype.send = function(event, data) {
      if (data == null) {
        data = {};
      }
      data.chat_id = this.options.chatId;
      return this.io.send(event, data);
    };

    ZammadChat.prototype.onWebSocketMessage = function(pipes) {
      var from, j, len, pipe, ref;
      for (j = 0, len = pipes.length; j < len; j++) {
        pipe = pipes[j];
        this.log.debug('ws:onmessage', pipe);
        switch (pipe.event) {
          case 'chat_error':
            this.log.notice(pipe.data);
            if (pipe.data && pipe.data.state === 'chat_disabled') {
              this.destroy({
                remove: true
              });
            }
            break;
          case 'chat_session_message':
            if (pipe.data.self_written) {
              return;
            }
            this.receiveMessage(pipe.data);
            break;
          case 'chat_session_attachment':
            from = pipe.data.message.created_by_id ? 'agent' : 'customer';
            this.addAttachmentMessage(pipe.data.message, from);
            break;
          case 'chat_session_typing':
            if (pipe.data.self_written) {
              return;
            }
            this.onAgentTypingStart();
            break;
          case 'chat_session_start':
            this.onConnectionEstablished(pipe.data);
            break;
          case 'chat_session_queue':
            this.onQueueScreen(pipe.data);
            break;
          case 'chat_session_init':
            if (pipe.data.state === 'failed') {
              this.showPrechatForm({
                error: pipe.data.message
              });
            }
            break;
          case 'chat_session_closed':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_session_left':
            this.onSessionClosed(pipe.data);
            break;
          case 'chat_session_notice':
            this.addStatus(this.T(pipe.data.message));
            break;
          case 'chat_session_message_read':
            this.markMessagesRead();
            break;
          case 'chat_knowledge_base_search':
            this.onKnowledgeBaseSearchResult(pipe.data);
            break;
          case 'chat_offline_session_init':
            this.onOfflineSessionInitResult(pipe.data);
            break;
          case 'chat_offline_otp_verify':
            this.onOfflineOtpVerifyResult(pipe.data);
            break;
          case 'chat_offline_otp_resend':
            this.onOfflineOtpResendResult(pipe.data);
            break;
          case 'chat_offline_message_send':
            this.onOfflineMessageSendResult(pipe.data);
            break;
          case 'chat_session_feedback_submit':
            this.onFeedbackSubmitResult(pipe.data);
            break;
          case 'chat_status_customer':
            if (pipe.data.logo_url) {
              this.logoUrl = pipe.data.logo_url;
            }
            if (this.logoUrl) {
              this.updateHomeLogo(this.logoUrl);
            }
            this.offlineMode = pipe.data.state === 'offline';
            if ((ref = this.launcherEl) != null) {
              ref.toggleClass('zammad-chat-launcher--offline', this.offlineMode);
            }
            if (pipe.data.phrases) {
              this.updatePhrases(pipe.data.phrases);
            }
            this.statusReceived = true;
            if (this.cssLoaded) {
              this.hidePreload();
            }
            switch (pipe.data.state) {
              case 'online':
                this.setSessionId(void 0);
                if (!this.options.cssAutoload || this.cssLoaded) {
                  this.onReady();
                } else {
                  this.socketReady = true;
                }
                break;
              case 'offline':
                this.setSessionId(void 0);
                this.enterOfflineMode();
                break;
              case 'chat_disabled':
                this.onError('Zammad Chat: Chat is disabled');
                break;
              case 'no_seats_available':
                this.onError("Zammad Chat: Too many clients in queue. Clients in queue: " + pipe.data.queue);
                break;
              case 'reconnect':
                this.onReopenSession(pipe.data);
            }
        }
      }
    };

    ZammadChat.prototype.onReady = function() {
      var base;
      this.log.debug('widget ready for use');
      this.hidePreload();
      $("." + this.options.buttonClass).on('click', this.open).removeClass(this.options.inactiveClass);
      if (typeof (base = this.options).onReady === "function") {
        base.onReady();
      }
      if (this.options.show) {
        return this.show();
      }
    };

    ZammadChat.prototype.onError = function(message) {
      var base;
      this.log.debug(message);
      this.hidePreload();
      this.addStatus(message);
      $("." + this.options.buttonClass).hide();
      if (this.isOpen) {
        this.disableInput();
        this.destroy({
          remove: false
        });
      } else {
        this.destroy({
          remove: true
        });
      }
      return typeof (base = this.options).onError === "function" ? base.onError(message) : void 0;
    };

    ZammadChat.prototype.onReopenSession = function(data) {
      var isAgentMessage, isRead, j, len, message, ref, ref1, time, unfinishedMessage;
      this.hidePreload();
      this.log.debug('old messages', data.session);
      this.inactiveTimeout.start();
      unfinishedMessage = sessionStorage.getItem('unfinished_message');
      if (data.agent) {
        this.onConnectionEstablished(data, false);
        ref = data.session;
        for (j = 0, len = ref.length; j < len; j++) {
          message = ref[j];
          isAgentMessage = !!message.created_by_id;
          time = this.formatTime(message.created_at);
          isRead = !!message.read_at;
          if (message.filename) {
            this.el.find('.zammad-chat-body').append(this.view('attachment_message')({
              from: isAgentMessage ? 'agent' : 'customer',
              id: message.id,
              filename: message.filename,
              metaLabel: this.attachmentMeta(message.filename, message.size),
              url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments/" + message.id,
              unreadClass: '',
              time: time,
              isRead: isRead
            }));
          } else {
            this.renderMessage({
              message: message.content,
              id: message.id,
              from: isAgentMessage ? 'agent' : 'customer',
              time: time,
              isRead: isRead,
              replyTo: (ref1 = message.reply_to) != null ? ref1.content : void 0
            });
          }
          if (isAgentMessage && message.id) {
            this.agentMessagesById[message.id] = message;
          }
        }
        if (unfinishedMessage) {
          this.input.html(unfinishedMessage);
        }
      }
      if (data.position) {
        this.onQueue(data);
      }
      this.show();
      if (!this.minimizedWithSession) {
        this.open();
        this.scrollToBottom();
      }
      if (unfinishedMessage) {
        return this.input.trigger('focus');
      }
    };

    ZammadChat.prototype.onInput = function() {
      this.el.find('.zammad-chat-message--unread').removeClass('zammad-chat-message--unread');
      sessionStorage.setItem('unfinished_message', this.input.html());
      return this.onTyping();
    };

    ZammadChat.prototype.onFocus = function() {
      var keyboardShown;
      $(window).scrollTop(10);
      keyboardShown = $(window).scrollTop() > 0;
      $(window).scrollTop(0);
      if (keyboardShown) {
        return this.log.notice('virtual keyboard shown');
      }
    };

    ZammadChat.prototype.onFocusOut = function() {};

    ZammadChat.prototype.onTyping = function() {
      if (this.isTyping && this.isTyping > new Date(new Date().getTime() - 1500)) {
        return;
      }
      this.isTyping = new Date();
      this.send('chat_session_typing', {
        session_id: this.sessionId
      });
      return this.inactiveTimeout.start();
    };

    ZammadChat.prototype.onSubmit = function(event) {
      event.preventDefault();
      return this.sendMessage();
    };

    ZammadChat.prototype.sendMessage = function() {
      var data, message, messageElement, ref, ref1, replyToId, replyToSnippet;
      message = this.input.html();
      if (!message) {
        return;
      }
      this.inactiveTimeout.start();
      sessionStorage.removeItem('unfinished_message');
      replyToId = (ref = this.replyTo) != null ? ref.id : void 0;
      replyToSnippet = (ref1 = this.replyTo) != null ? ref1.content : void 0;
      messageElement = this.view('message')({
        message: message,
        from: 'customer',
        id: this._messageCount++,
        unreadClass: '',
        replyTo: replyToSnippet,
        time: this.formatTime()
      });
      this.maybeAddTimestamp();
      if (this.el.find('.zammad-chat-message--typing').get(0)) {
        this.lastAddedType = 'typing-placeholder';
        this.el.find('.zammad-chat-message--typing').before(messageElement);
      } else {
        this.lastAddedType = 'message--customer';
        this.el.find('.zammad-chat-body').append(messageElement);
      }
      this.input.html('');
      this.scrollToBottom();
      data = {
        content: message,
        id: this._messageCount,
        session_id: this.sessionId
      };
      if (replyToId) {
        data.reply_to_id = replyToId;
      }
      this.send('chat_session_message', data);
      return this.cancelReply();
    };

    ZammadChat.prototype.receiveMessage = function(data) {
      var ref;
      this.inactiveTimeout.start();
      this.onAgentTypingEnd();
      this.maybeAddTimestamp();
      if (data.message.id) {
        this.agentMessagesById[data.message.id] = data.message;
      }
      this.renderMessage({
        message: data.message.content,
        id: data.message.id,
        from: 'agent',
        replyTo: (ref = data.message.reply_to) != null ? ref.content : void 0,
        time: this.formatTime(data.message.created_at)
      });
      this.scrollToBottom({
        showHint: true
      });
      return this.playMessageSound();
    };

    ZammadChat.prototype.playMessageSound = function() {
      var playPromise;
      if (!document.hidden && this.isOpen) {
        return;
      }
      if (this.messageSound == null) {
        this.messageSound = new Audio((this.apiBaseUrl()) + "/assets/sounds/chat_message.mp3");
      }
      playPromise = this.messageSound.play();
      return playPromise != null ? playPromise["catch"]((function(_this) {
        return function(e) {
          return _this.log.debug('playMessageSound: diblokir kebijakan autoplay browser', e);
        };
      })(this)) : void 0;
    };

    ZammadChat.prototype.renderMessage = function(data) {
      this.lastAddedType = "message--" + data.from;
      data.unreadClass = document.hidden ? ' zammad-chat-message--unread' : '';
      return this.el.find('.zammad-chat-body').append(this.view('message')(data));
    };

    ZammadChat.prototype.startReply = function(event) {
      var message, messageId;
      event.preventDefault();
      messageId = $(event.currentTarget).closest('.zammad-chat-message').data('message-id');
      if (!messageId) {
        return;
      }
      message = this.agentMessagesById[messageId];
      if (!message) {
        return;
      }
      this.replyTo = {
        id: messageId,
        content: message.filename || message.content
      };
      this.renderReplyIndicator();
      return this.input.trigger('focus');
    };

    ZammadChat.prototype.cancelReply = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.replyTo = null;
      return this.renderReplyIndicator();
    };

    ZammadChat.prototype.renderReplyIndicator = function() {
      var indicator, snippet;
      indicator = this.el.find('.js-reply-indicator');
      if (!this.replyTo) {
        indicator.addClass('zammad-chat-is-hidden').html('');
        return;
      }
      snippet = this.replyTo.content.replace(/<[^>]*>/g, '').substr(0, 80);
      return indicator.removeClass('zammad-chat-is-hidden').html(this.view('reply_indicator')({
        snippet: snippet
      }));
    };

    ZammadChat.prototype.triggerAttachmentInput = function(event) {
      event.preventDefault();
      return this.el.find('.js-chat-attachment-input').trigger('click');
    };

    ZammadChat.prototype.uploadAttachment = function(event) {
      var file, formData, ref;
      file = (ref = event.currentTarget.files) != null ? ref[0] : void 0;
      if (!file) {
        return;
      }
      formData = new FormData();
      formData.append('File', file);
      $.ajax({
        type: 'POST',
        url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments",
        data: formData,
        processData: false,
        contentType: false,
        cache: false,
        error: (function(_this) {
          return function(xhr) {
            var message, ref1;
            message = ((ref1 = xhr.responseJSON) != null ? ref1.error : void 0) || _this.T(_this.phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.');
            return _this.addStatus(message);
          };
        })(this)
      });
      return this.el.find('.js-chat-attachment-input').val('');
    };

    ZammadChat.prototype.addAttachmentMessage = function(data, from) {
      this.maybeAddTimestamp();
      this.lastAddedType = "message--" + from;
      this.el.find('.zammad-chat-body').append(this.view('attachment_message')({
        from: from,
        id: data.id,
        filename: data.filename,
        metaLabel: this.attachmentMeta(data.filename, data.size),
        url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments/" + data.id,
        unreadClass: document.hidden ? ' zammad-chat-message--unread' : '',
        time: this.formatTime(data.created_at)
      }));
      if (from === 'agent' && data.id) {
        this.agentMessagesById[data.id] = data;
      }
      return this.scrollToBottom({
        showHint: true
      });
    };

    ZammadChat.prototype.open = function() {
      if (this.isOpen) {
        this.log.debug('widget already open, block');
        return;
      }
      this.minimizedWithSession = false;
      this.isOpen = true;
      this.log.debug('open widget');
      this.show();
      if (this.sessionId) {
        this.switchTab('messages');
      } else {
        this.showPrechatForm();
      }
      this.launcherEl.addClass('zammad-chat-is-open');
      this.el.addClass('zammad-chat-is-open');
      return this.el.one('transitionend', this.onOpenAnimationEnd);
    };

    ZammadChat.prototype.showPrechatForm = function(params) {
      if (params == null) {
        params = {};
      }
      this.el.find('.zammad-chat-modal').html(this.view('prechat')({
        error: params.error,
        notice: params.notice,
        name: params.name,
        email: params.email
      }));
      this.el.find('.zammad-chat-prechat-form').on('submit', this.submitPrechatForm);
      if (this.logoUrl) {
        return this.updateHomeLogo(this.logoUrl);
      }
    };

    ZammadChat.prototype.setButtonLoading = function(button, loading) {
      if ((button == null) || !button.length) {
        return;
      }
      if (loading) {
        if (!button.find('.zammad-chat-btn-label').length) {
          button.wrapInner('<span class="zammad-chat-btn-label"></span>');
          button.append('<span class="zammad-chat-btn-loader" aria-hidden="true"><svg viewBox="0 0 50 50"><circle cx="25" cy="25" r="20"/></svg></span>');
        }
        return button.addClass('is-loading').prop('disabled', true);
      } else {
        return button.removeClass('is-loading').prop('disabled', false);
      }
    };

    ZammadChat.prototype.submitPrechatForm = function(event) {
      var email, emailFormat, name, ref, ref1;
      event.preventDefault();
      name = (ref = this.el.find('.zammad-chat-prechat-name').val()) != null ? ref.trim() : void 0;
      email = (ref1 = this.el.find('.zammad-chat-prechat-email').val()) != null ? ref1.trim() : void 0;
      emailFormat = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
      if (!name || !email || !emailFormat.test(email)) {
        this.showPrechatForm({
          error: this.T(this.phrases['chat_phrase_prechat_validation_error'] || 'Please provide a valid name and email address.'),
          name: name,
          email: email
        });
        return;
      }
      this.setButtonLoading(this.el.find('.zammad-chat-prechat-submit'), true);
      this.customerName = name;
      sessionStorage.setItem('customerName', name);
      this.customerEmail = email;
      if (this.offlineMode) {
        return this.send('chat_offline_session_init', {
          url: window.location.href,
          name: name,
          email: email
        });
      } else {
        this.showLoader();
        return this.send('chat_session_init', {
          url: window.location.href,
          name: name,
          email: email
        });
      }
    };

    ZammadChat.prototype.enterOfflineMode = function() {
      this.hidePreload();
      this.applyOfflineHomeState();
      return this.show();
    };

    ZammadChat.prototype.applyOfflineHomeState = function() {
      var startAction;
      if (!this.offlineMode) {
        return;
      }
      if (!this.el) {
        return;
      }
      this.el.find('.zammad-chat-welcome-subtext').html($('<span>').addClass('zammad-chat-welcome-offline-status').append($('<span>').addClass('zammad-chat-welcome-offline-dot')).append(document.createTextNode(this.T(this.phrases['chat_phrase_offline_status'] || "We're offline right now"))));
      this.el.find('.zammad-chat-home-offline-notice').removeClass('zammad-chat-is-hidden');
      startAction = this.el.find('.js-home-start-action');
      return startAction.find('.js-home-start-label').text(this.T(this.phrases['chat_phrase_offline_start_button'] || 'Leave us a message'));
    };

    ZammadChat.prototype.onOfflineSessionInitResult = function(data) {
      if (data.state !== 'ok') {
        if (data.reason === 'agent_available') {
          this.showPrechatForm({
            notice: data.message
          });
        } else {
          this.showPrechatForm({
            error: data.message
          });
        }
        return;
      }
      this.setSessionId(data.session_id);
      return this.showOfflineOtp();
    };

    ZammadChat.prototype.showOfflineOtp = function() {
      this.el.find('.zammad-chat-modal').html(this.view('offline_otp')({
        email: this.customerEmail
      }));
      return this.el.find('.js-otp-digit').first().trigger('focus');
    };

    ZammadChat.prototype.onOtpDigitInput = function(event) {
      var input, next, value;
      input = $(event.currentTarget);
      value = input.val().replace(/[^0-9]/g, '');
      input.val(value.slice(-1));
      if (value) {
        next = input.closest('.zammad-chat-offline-otp-boxes').find(".js-otp-digit[data-index='" + (parseInt(input.data('index'), 10) + 1) + "']");
        if (next.length) {
          return next.trigger('focus');
        }
      }
    };

    ZammadChat.prototype.onOtpDigitKeydown = function(event) {
      var input, prev, prevIndex;
      if (event.keyCode !== 8) {
        return;
      }
      input = $(event.currentTarget);
      if (input.val()) {
        return;
      }
      prevIndex = parseInt(input.data('index'), 10) - 1;
      if (prevIndex < 0) {
        return;
      }
      prev = input.closest('.zammad-chat-offline-otp-boxes').find(".js-otp-digit[data-index='" + prevIndex + "']");
      if (prev.length) {
        return prev.val('').trigger('focus');
      }
    };

    ZammadChat.prototype.onOtpDigitPaste = function(event) {
      var boxes, clipboard, lastFilled, pasted, ref, ref1;
      event.preventDefault();
      clipboard = ((ref = event.originalEvent) != null ? ref.clipboardData : void 0) || event.clipboardData;
      pasted = (clipboard != null ? (ref1 = clipboard.getData('text')) != null ? ref1.replace(/[^0-9]/g, '') : void 0 : void 0) || '';
      if (!pasted) {
        return;
      }
      boxes = $(event.currentTarget).closest('.zammad-chat-offline-otp-boxes').find('.js-otp-digit');
      boxes.each(function(i, el) {
        return $(el).val(pasted.charAt(i) || '');
      });
      lastFilled = Math.min(pasted.length, boxes.length) - 1;
      return boxes.eq(Math.max(lastFilled, 0)).trigger('focus');
    };

    ZammadChat.prototype.submitOfflineOtp = function(event) {
      var code;
      if (event != null) {
        event.preventDefault();
      }
      code = '';
      this.el.find('.js-otp-digit').each(function(i, el) {
        return code += $(el).val() || '';
      });
      if (code.length !== 6) {
        this.showOtpError(this.T(this.phrases['chat_phrase_otp_incomplete_error'] || 'Please enter the full 6-digit code.'));
        return;
      }
      this.setButtonLoading(this.el.find('.js-otp-submit'), true);
      return this.send('chat_offline_otp_verify', {
        session_id: this.sessionId,
        code: code
      });
    };

    ZammadChat.prototype.showOtpError = function(message) {
      this.el.find('.js-otp-error').removeClass('zammad-chat-is-hidden');
      return this.el.find('.js-otp-error-text').text(message);
    };

    ZammadChat.prototype.onOfflineOtpVerifyResult = function(data) {
      if (data.state === 'ok') {
        this.showOfflineCompose();
        return;
      }
      this.setButtonLoading(this.el.find('.js-otp-submit'), false);
      this.showOtpError(data.message);
      this.el.find('.js-otp-digit').val('');
      return this.el.find('.js-otp-digit').first().trigger('focus');
    };

    ZammadChat.prototype.resendOfflineOtp = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      return this.send('chat_offline_otp_resend', {
        session_id: this.sessionId
      });
    };

    ZammadChat.prototype.onOfflineOtpResendResult = function(data) {
      if (data.state === 'ok') {
        this.el.find('.js-otp-digit').val('');
        this.el.find('.js-otp-digit').first().trigger('focus');
        this.showOtpError(this.T(this.phrases['chat_phrase_otp_resend_success'] || 'A new code has been sent.'));
        return;
      }
      return this.showOtpError(data.message || this.T(this.phrases['chat_phrase_otp_resend_error_fallback'] || 'Could not resend code. Please try again.'));
    };

    ZammadChat.prototype.showOfflineCompose = function() {
      return this.el.find('.zammad-chat-modal').html(this.view('offline_compose')({
        email: this.customerEmail
      }));
    };

    ZammadChat.prototype.submitOfflineMessage = function(event) {
      var content, ref, ref1, subject;
      if (event != null) {
        event.preventDefault();
      }
      subject = (ref = this.el.find('.js-offline-subject').val()) != null ? ref.trim() : void 0;
      if (!subject) {
        this.el.find('.js-offline-compose-error').text(this.T(this.phrases['chat_phrase_offline_compose_subject_empty_error'] || 'Please enter a subject.')).removeClass('zammad-chat-is-hidden');
        return;
      }
      content = (ref1 = this.el.find('.js-offline-message').val()) != null ? ref1.trim() : void 0;
      if (!content) {
        this.el.find('.js-offline-compose-error').text(this.T(this.phrases['chat_phrase_offline_compose_empty_error'] || 'Please write a message.')).removeClass('zammad-chat-is-hidden');
        return;
      }
      this.el.find('.js-offline-compose-error').addClass('zammad-chat-is-hidden');
      this.setButtonLoading(this.el.find('.js-offline-compose-submit'), true);
      return this.send('chat_offline_message_send', {
        session_id: this.sessionId,
        subject: subject,
        content: content
      });
    };

    ZammadChat.prototype.triggerOfflineAttachmentInput = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      return this.el.find('.js-offline-compose-attachment-input').trigger('click');
    };

    ZammadChat.prototype.uploadOfflineAttachment = function(event) {
      var attachBtn, file, formData, ref;
      file = (ref = event.currentTarget.files) != null ? ref[0] : void 0;
      if (!file) {
        return;
      }
      formData = new FormData();
      formData.append('File', file);
      attachBtn = this.el.find('.js-offline-compose-attach');
      attachBtn.prop('disabled', true);
      $.ajax({
        type: 'POST',
        url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments",
        data: formData,
        processData: false,
        contentType: false,
        cache: false,
        success: (function(_this) {
          return function(data) {
            var chip;
            chip = $('<div>').addClass('zammad-chat-offline-compose-attachment-chip');
            chip.append($('<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11.97 12v3.5c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5V10c0-3.87-3.13-7-7-7s-7 3.13-7 7v6c0 3.31 2.69 6 6 6"/></svg>'));
            chip.append($('<span>').text(data.filename));
            return _this.el.find('.js-offline-compose-attachments').append(chip);
          };
        })(this),
        error: (function(_this) {
          return function(xhr) {
            var message, ref1;
            message = ((ref1 = xhr.responseJSON) != null ? ref1.error : void 0) || _this.T(_this.phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.');
            return _this.el.find('.js-offline-compose-error').text(message).removeClass('zammad-chat-is-hidden');
          };
        })(this),
        complete: (function(_this) {
          return function() {
            return attachBtn.prop('disabled', false);
          };
        })(this)
      });
      return this.el.find('.js-offline-compose-attachment-input').val('');
    };

    ZammadChat.prototype.onOfflineMessageSendResult = function(data) {
      this.setButtonLoading(this.el.find('.js-offline-compose-submit'), false);
      if (data.state !== 'ok') {
        this.el.find('.js-offline-compose-error').text(data.message).removeClass('zammad-chat-is-hidden');
        return;
      }
      this.lastSessionId = this.sessionId;
      this.setSessionId(void 0);
      return this.showOfflineSent();
    };

    ZammadChat.prototype.showOfflineSent = function() {
      return this.el.find('.zammad-chat-modal').html(this.view('offline_sent')({
        email: this.customerEmail
      }));
    };

    ZammadChat.prototype.finishOfflineFlow = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.setButtonLoading(this.el.find('.js-offline-sent-done'), true);
      return this.showFeedback();
    };

    ZammadChat.prototype.showFeedback = function(inline) {
      var markup;
      if (inline == null) {
        inline = false;
      }
      this.feedbackScore = void 0;
      this.feedbackInline = inline;
      markup = this.view('feedback')();
      if (inline) {
        this.hideModal();
        this.maybeAddTimestamp();
        this.el.find('.zammad-chat-body').append("<div class=\"zammad-chat-feedback-inline js-feedback-inline\">" + markup + "</div>");
        this.scrollToBottom();
      } else {
        this.el.find('.zammad-chat-modal').html(markup);
      }
      this.agent = void 0;
      return this.updateHeader();
    };

    ZammadChat.prototype.selectFeedbackScore = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.feedbackScore = parseInt($(event.currentTarget).data('score'), 10);
      return this.el.find('.js-feedback-star').each((function(_this) {
        return function(i, el) {
          var starScore;
          starScore = parseInt($(el).data('score'), 10);
          return $(el).toggleClass('is-active', starScore <= _this.feedbackScore);
        };
      })(this));
    };

    ZammadChat.prototype.submitFeedback = function(event) {
      var comment, ref;
      if (event != null) {
        event.preventDefault();
      }
      if (!this.feedbackScore) {
        this.el.find('.js-feedback-error').text(this.T(this.phrases['chat_phrase_feedback_score_error'] || 'Please select a rating.')).removeClass('zammad-chat-is-hidden');
        return;
      }
      this.el.find('.js-feedback-error').addClass('zammad-chat-is-hidden');
      this.setButtonLoading(this.el.find('.js-feedback-submit'), true);
      comment = (ref = this.el.find('.js-feedback-comment').val()) != null ? ref.trim() : void 0;
      return this.send('chat_session_feedback_submit', {
        session_id: this.lastSessionId,
        score: this.feedbackScore,
        comment: comment
      });
    };

    ZammadChat.prototype.onFeedbackSubmitResult = function(data) {
      this.setButtonLoading(this.el.find('.js-feedback-submit'), false);
      if (data.state !== 'ok') {
        this.el.find('.js-feedback-error').text(data.message || this.T(this.phrases['chat_phrase_feedback_submit_error_fallback'] || 'Could not save your feedback. Please try again.')).removeClass('zammad-chat-is-hidden');
        return;
      }
      return this.showFeedbackThanks();
    };

    ZammadChat.prototype.skipFeedback = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.setButtonLoading(this.el.find('.js-feedback-skip'), true);
      return this.goToStartChat();
    };

    ZammadChat.prototype.showFeedbackThanks = function() {
      var markup, overlay;
      markup = this.view('feedback_thanks')();
      if (this.feedbackInline) {
        overlay = this.el.find('.js-feedback-thanks-overlay');
        if (overlay.length) {
          overlay.html(markup).removeClass('zammad-chat-is-hidden');
        }
      } else {
        this.el.find('.zammad-chat-modal').html(markup);
      }
      return setTimeout(((function(_this) {
        return function() {
          _this.hideFeedbackThanksOverlay();
          return _this.goToStartChat();
        };
      })(this)), 2000);
    };

    ZammadChat.prototype.hideFeedbackThanksOverlay = function() {
      var overlay;
      overlay = this.el.find('.js-feedback-thanks-overlay');
      if (!overlay.length) {
        return;
      }
      overlay.addClass('zammad-chat-is-hidden');
      return overlay.html('');
    };

    ZammadChat.prototype.onOpenAnimationEnd = function() {
      var base;
      this.idleTimeout.stop();
      if (this.isFullscreen) {
        this.disableScrollOnRoot();
      }
      return typeof (base = this.options).onOpenAnimationEnd === "function" ? base.onOpenAnimationEnd() : void 0;
    };

    ZammadChat.prototype.sessionClose = function() {
      this.send('chat_session_close', {
        session_id: this.sessionId
      });
      this.inactiveTimeout.stop();
      this.waitingListTimeout.stop();
      sessionStorage.removeItem('unfinished_message');
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      this.lastSessionId = this.sessionId;
      return this.setSessionId(void 0);
    };

    ZammadChat.prototype.cancelQueue = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.sessionClose();
      this.inQueue = false;
      this.showPrechatForm();
      return this.switchTab('home');
    };

    ZammadChat.prototype.toggle = function(event) {
      if (this.isOpen) {
        return this.close(event);
      } else {
        return this.open(event);
      }
    };

    ZammadChat.prototype.close = function(event) {
      if (!this.isOpen) {
        this.log.debug('can\'t close widget, it\'s not open');
        return;
      }
      if (this.initDelayId) {
        clearTimeout(this.initDelayId);
      }
      this.minimizedWithSession = !!this.sessionId;
      this.log.debug('close widget');
      if (event) {
        event.stopPropagation();
      }
      if (this.isFullscreen) {
        this.enableScrollOnRoot();
      }
      this.launcherEl.removeClass('zammad-chat-is-open');
      this.el.one('transitionend', this.onCloseAnimationEnd);
      return this.el.removeClass('zammad-chat-is-open');
    };

    ZammadChat.prototype.exitChat = function(event) {
      if (this.activeTab !== 'messages' || this.offlineMode) {
        this.close(event);
        return;
      }
      if (event != null) {
        event.preventDefault();
      }
      if (event != null) {
        event.stopPropagation();
      }
      if (this.sessionId) {
        this.log.debug('exit chat');
        this.el.find('.zammad-chat-modal').html(this.view('ending_chat')());
        this.sessionClose();
        return setTimeout(this.showFeedback, 2000);
      } else {
        return this.goToStartChat();
      }
    };

    ZammadChat.prototype.goToStartChat = function() {
      this.agent = void 0;
      this.showPrechatForm();
      return this.switchTab('home');
    };

    ZammadChat.prototype.onCloseAnimationEnd = function() {
      var base;
      if (!this.sessionId) {
        this.agent = void 0;
        this.switchTab('home');
      }
      this.isOpen = false;
      if (typeof (base = this.options).onCloseAnimationEnd === "function") {
        base.onCloseAnimationEnd();
      }
      return this.io.reconnect();
    };

    ZammadChat.prototype.onWebSocketClose = function() {
      if (this.isOpen) {
        return;
      }
      if (this.launcherEl) {
        this.launcherEl.removeClass('zammad-chat-is-shown');
        return this.launcherEl.removeClass('zammad-chat-is-loaded');
      }
    };

    ZammadChat.prototype.show = function() {
      if (this.state === 'offline') {
        return;
      }
      this.launcherEl.addClass('zammad-chat-is-loaded');
      return this.launcherEl.addClass('zammad-chat-is-shown');
    };

    ZammadChat.prototype.disableInput = function() {
      this.inputDisabled = true;
      this.input.prop('contenteditable', false);
      this.el.find('.zammad-chat-send').prop('disabled', true);
      return this.io.close();
    };

    ZammadChat.prototype.disableComposeInput = function() {
      var ref;
      this.inputDisabled = true;
      if ((ref = this.input) != null) {
        ref.prop('contenteditable', false);
      }
      return this.el.find('.zammad-chat-send').prop('disabled', true);
    };

    ZammadChat.prototype.enableInput = function() {
      this.inputDisabled = false;
      this.input.prop('contenteditable', true);
      return this.el.find('.zammad-chat-send').prop('disabled', false);
    };

    ZammadChat.prototype.hideModal = function() {
      return this.el.find('.zammad-chat-modal').html('');
    };

    ZammadChat.prototype.onQueueScreen = function(data) {
      var show;
      this.setSessionId(data.session_id);
      show = (function(_this) {
        return function() {
          _this.onQueue(data);
          return _this.waitingListTimeout.start();
        };
      })(this);
      if (this.initialQueueDelay && !this.onInitialQueueDelayId) {
        this.onInitialQueueDelayId = setTimeout(show, this.initialQueueDelay);
        return;
      }
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      return show();
    };

    ZammadChat.prototype.onQueue = function(data) {
      this.log.notice('onQueue', data.position);
      this.inQueue = true;
      return this.el.find('.zammad-chat-modal').html(this.view('waiting')({
        position: data.position
      }));
    };

    ZammadChat.prototype.onAgentTypingStart = function() {
      if (this.stopTypingId) {
        clearTimeout(this.stopTypingId);
      }
      this.stopTypingId = setTimeout(this.onAgentTypingEnd, 3000);
      if (this.el.find('.zammad-chat-message--typing').get(0)) {
        return;
      }
      this.maybeAddTimestamp();
      this.el.find('.zammad-chat-body').append(this.view('typingIndicator')());
      if (!this.isVisible(this.el.find('.zammad-chat-message--typing'), true)) {
        return;
      }
      return this.scrollToBottom();
    };

    ZammadChat.prototype.onAgentTypingEnd = function() {
      return this.el.find('.zammad-chat-message--typing').remove();
    };

    ZammadChat.prototype.onLeaveTemporary = function() {
      if (!this.sessionId) {
        return;
      }
      return this.send('chat_session_leave_temporary', {
        session_id: this.sessionId
      });
    };

    ZammadChat.prototype.maybeAddTimestamp = function() {
      var label, time, timestamp;
      timestamp = Date.now();
      if (!this.lastTimestamp || (timestamp - this.lastTimestamp) > this.showTimeEveryXMinutes * 60000) {
        label = this.T('Today');
        time = new Date().toTimeString().substr(0, 5);
        if (this.lastAddedType === 'timestamp') {
          this.updateLastTimestamp(label, time);
          return this.lastTimestamp = timestamp;
        } else {
          this.el.find('.zammad-chat-body').append(this.view('timestamp')({
            label: label,
            time: time
          }));
          this.lastTimestamp = timestamp;
          this.lastAddedType = 'timestamp';
          return this.scrollToBottom();
        }
      }
    };

    ZammadChat.prototype.updateLastTimestamp = function(label, time) {
      if (!this.el) {
        return;
      }
      return this.el.find('.zammad-chat-body').find('.zammad-chat-timestamp').last().replaceWith(this.view('timestamp')({
        label: label,
        time: time
      }));
    };

    ZammadChat.prototype.addStatus = function(status) {
      if (!this.el) {
        return;
      }
      this.maybeAddTimestamp();
      this.el.find('.zammad-chat-body').append(this.view('status')({
        status: status
      }));
      return this.scrollToBottom();
    };

    ZammadChat.prototype.connectionOverlayCopy = function(state) {
      switch (state) {
        case 'reconnecting':
          return {
            title: this.T('Connection lost'),
            subtitle: "Trying to reconnect — please don't close this window."
          };
        case 'restored':
          return {
            title: this.T('Connection re-established'),
            subtitle: "You're back online."
          };
        case 'lost':
          return {
            title: 'Connection lost',
            subtitle: "We couldn't reconnect after several attempts. Please reload the page to continue this conversation."
          };
      }
    };

    ZammadChat.prototype.showConnectionOverlay = function(state) {
      var copy, j, len, otherState, overlay, ref;
      if (!this.el) {
        return;
      }
      overlay = this.el.find('.js-connection-overlay');
      if (!overlay.length) {
        return;
      }
      if (this.connectionOverlayHideTimeoutId) {
        clearTimeout(this.connectionOverlayHideTimeoutId);
        this.connectionOverlayHideTimeoutId = void 0;
      }
      copy = this.connectionOverlayCopy(state);
      overlay.html(this.view('connection_overlay')({
        state: state,
        title: copy.title,
        subtitle: copy.subtitle
      }));
      ref = ['reconnecting', 'restored', 'lost'];
      for (j = 0, len = ref.length; j < len; j++) {
        otherState = ref[j];
        overlay.removeClass("zammad-chat-connection-overlay--" + otherState);
      }
      overlay.addClass("zammad-chat-connection-overlay--" + state);
      overlay.removeClass('zammad-chat-is-hidden');
      if (state === 'restored') {
        return this.connectionOverlayHideTimeoutId = setTimeout(this.hideConnectionOverlay, 1800);
      }
    };

    ZammadChat.prototype.hideConnectionOverlay = function() {
      var overlay;
      if (!this.el) {
        return;
      }
      overlay = this.el.find('.js-connection-overlay');
      if (!overlay.length) {
        return;
      }
      overlay.addClass('zammad-chat-is-hidden');
      return overlay.html('');
    };

    ZammadChat.prototype.updateLauncherConnectionState = function(hasIssue) {
      var ref;
      return (ref = this.launcherEl) != null ? ref.toggleClass('zammad-chat-launcher--connection-issue', hasIssue) : void 0;
    };

    ZammadChat.prototype.detectScrolledtoBottom = function() {
      var scrollBottom;
      scrollBottom = this.el.find('.zammad-chat-body').scrollTop() + this.el.find('.zammad-chat-body').outerHeight();
      this.scrolledToBottom = Math.abs(scrollBottom - this.el.find('.zammad-chat-body').prop('scrollHeight')) <= this.scrollSnapTolerance;
      if (this.scrolledToBottom) {
        return this.el.find('.zammad-scroll-hint').addClass('is-hidden');
      }
    };

    ZammadChat.prototype.showScrollHint = function() {
      this.el.find('.zammad-scroll-hint').removeClass('is-hidden');
      return this.el.find('.zammad-chat-body').scrollTop(this.el.find('.zammad-chat-body').scrollTop() + this.el.find('.zammad-scroll-hint').outerHeight());
    };

    ZammadChat.prototype.onScrollHintClick = function() {
      return this.el.find('.zammad-chat-body').animate({
        scrollTop: this.el.find('.zammad-chat-body').prop('scrollHeight')
      }, 300);
    };

    ZammadChat.prototype.scrollToBottom = function(arg) {
      var showHint;
      showHint = (arg != null ? arg : {
        showHint: false
      }).showHint;
      if (this.scrolledToBottom) {
        return this.el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'));
      } else if (showHint) {
        return this.showScrollHint();
      }
    };

    ZammadChat.prototype.destroy = function(params) {
      var ref;
      if (params == null) {
        params = {};
      }
      this.log.debug('destroy widget', params);
      this.setAgentOnlineState('offline');
      if (params.remove && this.el) {
        this.el.remove();
        if ((ref = this.launcherEl) != null) {
          ref.remove();
        }
        $("." + this.options.buttonClass).hide();
      }
      if (this.waitingListTimeout) {
        this.waitingListTimeout.stop();
      }
      if (this.inactiveTimeout) {
        this.inactiveTimeout.stop();
      }
      if (this.idleTimeout) {
        this.idleTimeout.stop();
      }
      return this.io.close();
    };

    ZammadChat.prototype.onIoReconnecting = function(attempt, maxAttempts) {
      var ref;
      this.log.debug("reconnecting attempt " + attempt + "/" + maxAttempts);
      if (attempt !== 1) {
        return;
      }
      if (!this.isOpen) {
        return;
      }
      this.setAgentOnlineState('connecting');
      this.showConnectionOverlay('reconnecting');
      this.updateLauncherConnectionState(true);
      if (!this.inputDisabled) {
        this.reconnectDisabledInput = true;
        if ((ref = this.input) != null) {
          ref.prop('contenteditable', false);
        }
        return this.el.find('.zammad-chat-send').prop('disabled', true);
      }
    };

    ZammadChat.prototype.onIoReconnected = function() {
      var base, ref;
      this.log.debug('reconnected');
      if (!this.isOpen) {
        return;
      }
      this.setAgentOnlineState('online');
      this.showConnectionOverlay('restored');
      this.updateLauncherConnectionState(false);
      if (typeof (base = this.options).onConnectionReestablished === "function") {
        base.onConnectionReestablished();
      }
      if (this.reconnectDisabledInput) {
        this.reconnectDisabledInput = false;
        if ((ref = this.input) != null) {
          ref.prop('contenteditable', true);
        }
        return this.el.find('.zammad-chat-send').prop('disabled', false);
      }
    };

    ZammadChat.prototype.onReconnectFailed = function() {
      this.log.debug('gave up reconnecting');
      if (!this.isOpen) {
        this.destroy({
          remove: true
        });
        return;
      }
      this.setAgentOnlineState('offline');
      this.showConnectionOverlay('lost');
      this.updateLauncherConnectionState(true);
      return this.disableInput();
    };

    ZammadChat.prototype.onSessionClosed = function(data) {
      var base;
      this.addStatus(this.T('Chat closed by %s', data.realname));
      this.disableComposeInput();
      this.setAgentOnlineState('offline');
      this.inactiveTimeout.stop();
      this.agent = void 0;
      this.updateHeader();
      if (typeof (base = this.options).onSessionClosed === "function") {
        base.onSessionClosed(data);
      }
      if (data.closed_by_agent && this.sessionId) {
        sessionStorage.removeItem('unfinished_message');
        this.lastSessionId = this.sessionId;
        this.setSessionId(void 0);
        return setTimeout(((function(_this) {
          return function() {
            return _this.showFeedback(true);
          };
        })(this)), 2000);
      }
    };

    ZammadChat.prototype.markMessagesRead = function() {
      var statusEls;
      statusEls = this.el.find('.zammad-chat-message--customer .zammad-chat-message-status--sent');
      if (!statusEls.length) {
        return;
      }
      return statusEls.removeClass('zammad-chat-message-status--sent').addClass('zammad-chat-message-status--read').attr('aria-label', this.T('Read'));
    };

    ZammadChat.prototype.setSessionId = function(id) {
      this.sessionId = id;
      if (id === void 0) {
        return sessionStorage.removeItem('sessionId');
      } else {
        return sessionStorage.setItem('sessionId', id);
      }
    };

    ZammadChat.prototype.onConnectionEstablished = function(data, showGreeting) {
      var base, ref;
      if (showGreeting == null) {
        showGreeting = true;
      }
      if (this.onInitialQueueDelayId) {
        clearTimeout(this.onInitialQueueDelayId);
      }
      this.inQueue = false;
      if (data.agent) {
        this.agent = data.agent;
      }
      if (data.session_id) {
        this.setSessionId(data.session_id);
      }
      this.el.find('.zammad-chat-body').html('');
      this.el.find('.zammad-chat-agent').html(this.view('agent')({
        agent: this.agent,
        initials: this.initialsOf((ref = this.agent) != null ? ref.name : void 0)
      }));
      if (showGreeting) {
        this.showWelcomeGreeting();
      }
      this.el.find('.js-chat-attach').toggleClass('zammad-chat-is-hidden', !data.attachment_enabled);
      this.enableInput();
      this.hideModal();
      this.updateHeader();
      if (!this.isFullscreen) {
        this.input.trigger('focus');
      }
      this.setAgentOnlineState('online');
      this.waitingListTimeout.stop();
      this.idleTimeout.stop();
      this.inactiveTimeout.start();
      return typeof (base = this.options).onConnectionEstablished === "function" ? base.onConnectionEstablished(data) : void 0;
    };

    ZammadChat.prototype.showWelcomeGreeting = function() {
      var greeting;
      greeting = this.phrases['chat_phrase_messages_welcome_greeting'];
      if (!greeting) {
        return;
      }
      this.maybeAddTimestamp();
      return this.renderMessage({
        message: greeting,
        from: 'agent',
        time: this.formatTime()
      });
    };

    ZammadChat.prototype.showCustomerTimeout = function() {
      var reload;
      this.el.find('.zammad-chat-modal').html(this.view('customer_timeout')({
        agent: this.agent.name,
        delay: this.options.inactiveTimeout
      }));
      reload = function() {
        return location.reload();
      };
      this.el.find('.js-restart').on('click', reload);
      return this.sessionClose();
    };

    ZammadChat.prototype.showWaitingListTimeout = function() {
      var reload;
      this.el.find('.zammad-chat-modal').html(this.view('waiting_list_timeout')({
        delay: this.options.watingListTimeout
      }));
      reload = function() {
        return location.reload();
      };
      this.el.find('.js-restart').on('click', reload);
      return this.sessionClose();
    };

    ZammadChat.prototype.showLoader = function() {
      return this.el.find('.zammad-chat-modal').html(this.view('loader')());
    };

    ZammadChat.prototype.initialsOf = function(name) {
      var parts, ref, ref1;
      if (!name) {
        return '';
      }
      parts = name.trim().split(/\s+/);
      return ((((ref = parts[0]) != null ? ref[0] : void 0) || '') + (((ref1 = parts[1]) != null ? ref1[0] : void 0) || '')).toUpperCase();
    };

    ZammadChat.prototype.updateHomeLogo = function(url) {
      var marks;
      marks = this.el.find('.zammad-chat-home-logo-mark, .zammad-chat-prechat-icon');
      marks.css('background', 'none');
      return marks.html($('<img>').attr({
        src: url,
        alt: ''
      }).css({
        width: '100%',
        height: '100%',
        'object-fit': 'contain'
      }));
    };

    ZammadChat.prototype.updatePhrases = function(phrases) {
      this.phrases = phrases;
      if (!this.el) {
        return;
      }
      this.el.find('.zammad-chat-tab-body--home').html(this.view('home')());
      this.el.find('.zammad-chat-tab-body--help').html(this.view('help')());
      if (this.activeTab === 'help') {
        this.loadKnowledgeBase(true);
      } else {
        this.kbLoaded = false;
      }
      this.el.find('.zammad-chat-welcome-title').html(this.T(this.phrases['chat_phrase_home_greeting'] || 'Hi there') + ' 👋');
      this.el.find('.zammad-chat-welcome-subtext').text(this.T(this.phrases['chat_phrase_home_subtitle'] || 'How can we help you today?'));
      this.el.find('.zammad-chat-input').attr('placeholder', this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
      this.applyOfflineHomeState();
      if (this.logoUrl) {
        return this.updateHomeLogo(this.logoUrl);
      }
    };

    ZammadChat.prototype.formatTime = function(isoString) {
      var date;
      date = isoString ? new Date(isoString) : new Date();
      return date.toTimeString().substr(0, 5);
    };

    ZammadChat.prototype.formatFileSize = function(bytes) {
      if (!bytes) {
        return '';
      }
      if (bytes < 1024) {
        return bytes + " B";
      }
      if (bytes < 1024 * 1024) {
        return (Math.round(bytes / 1024)) + " KB";
      }
      return ((bytes / (1024 * 1024)).toFixed(1)) + " MB";
    };

    ZammadChat.prototype.fileExtensionLabel = function(filename) {
      var parts;
      if (!filename) {
        return '';
      }
      parts = filename.split('.');
      if (parts.length < 2) {
        return '';
      }
      return parts[parts.length - 1].toUpperCase();
    };

    ZammadChat.prototype.attachmentMeta = function(filename, size) {
      return [this.fileExtensionLabel(filename), this.formatFileSize(size)].filter(function(part) {
        return part;
      }).join(' · ');
    };

    ZammadChat.prototype.setAgentOnlineState = function(state) {
      var capitalizedState;
      this.state = state;
      if (!this.el) {
        return;
      }
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1);
      return this.el.find('.zammad-chat-agent-status').attr('data-status', state).text(this.T(capitalizedState));
    };

    ZammadChat.prototype.detectHost = function() {
      var protocol;
      protocol = 'ws://';
      if (scriptProtocol === 'https') {
        protocol = 'wss://';
      }
      return this.options.host = "" + protocol + scriptHost + "/ws";
    };

    ZammadChat.prototype.apiBaseUrl = function() {
      return this.options.host.replace(/^wss/i, 'https').replace(/^ws/i, 'http').replace(/\/ws$/i, '');
    };

    ZammadChat.prototype.loadCss = function() {
      var newSS, styles, url;
      if (!this.options.cssAutoload) {
        return;
      }
      url = this.options.cssUrl;
      if (!url) {
        url = this.options.host.replace(/^wss/i, 'https').replace(/^ws/i, 'http').replace(/\/ws$/i, '');
        url += '/assets/chat/chat.css';
      }
      this.log.debug("load css from '" + url + "'");
      styles = "@import url('" + url + "');";
      newSS = document.createElement('link');
      newSS.onload = this.onCssLoaded;
      newSS.rel = 'stylesheet';
      newSS.href = 'data:text/css,' + escape(styles);
      return document.getElementsByTagName('head')[0].appendChild(newSS);
    };

    ZammadChat.prototype.onCssLoaded = function() {
      var base, ref, ref1;
      this.cssLoaded = true;
      if ((ref = this.el) != null) {
        ref.css('display', '');
      }
      if ((ref1 = this.launcherEl) != null) {
        ref1.css('display', '');
      }
      if (this.statusReceived) {
        this.hidePreload();
      }
      if (this.socketReady) {
        this.onReady();
      }
      return typeof (base = this.options).onCssLoaded === "function" ? base.onCssLoaded() : void 0;
    };

    ZammadChat.prototype.startTimeoutObservers = function() {
      this.idleTimeout = new Timeout({
        logPrefix: 'idleTimeout',
        debug: this.options.debug,
        timeout: this.options.idleTimeout,
        timeoutIntervallCheck: this.options.idleTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Idle timeout reached, hide widget', new Date);
            return _this.destroy({
              remove: true
            });
          };
        })(this)
      });
      this.inactiveTimeout = new Timeout({
        logPrefix: 'inactiveTimeout',
        debug: this.options.debug,
        timeout: this.options.inactiveTimeout,
        timeoutIntervallCheck: this.options.inactiveTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Inactive timeout reached, show timeout screen.', new Date);
            _this.showCustomerTimeout();
            return _this.destroy({
              remove: false
            });
          };
        })(this)
      });
      return this.waitingListTimeout = new Timeout({
        logPrefix: 'waitingListTimeout',
        debug: this.options.debug,
        timeout: this.options.waitingListTimeout,
        timeoutIntervallCheck: this.options.waitingListTimeoutIntervallCheck,
        callback: (function(_this) {
          return function() {
            _this.log.debug('Waiting list timeout reached, show timeout screen.', new Date);
            _this.showWaitingListTimeout();
            return _this.destroy({
              remove: false
            });
          };
        })(this)
      });
    };

    ZammadChat.prototype.disableScrollOnRoot = function() {
      this.rootScrollOffset = this.scrollRoot.scrollTop();
      return this.scrollRoot.css({
        overflow: 'hidden',
        position: 'fixed'
      });
    };

    ZammadChat.prototype.enableScrollOnRoot = function() {
      this.scrollRoot.scrollTop(this.rootScrollOffset);
      return this.scrollRoot.css({
        overflow: '',
        position: ''
      });
    };

    ZammadChat.prototype.isVisible = function(el, partial, hidden, direction) {
      var $t, $w, _bottom, _left, _right, _top, bViz, clientSize, compareBottom, compareLeft, compareRight, compareTop, hVisible, lViz, offset, rViz, rec, t, tViz, vVisible, viewBottom, viewLeft, viewRight, viewTop, vpHeight, vpWidth;
      if (el.length < 1) {
        return;
      }
      $w = $(window);
      $t = el.length > 1 ? el.eq(0) : el;
      t = $t.get(0);
      vpWidth = $w.width();
      vpHeight = $w.height();
      direction = direction ? direction : 'both';
      clientSize = hidden === true ? t.offsetWidth * t.offsetHeight : true;
      if (typeof t.getBoundingClientRect === 'function') {
        rec = t.getBoundingClientRect();
        tViz = rec.top >= 0 && rec.top < vpHeight;
        bViz = rec.bottom > 0 && rec.bottom <= vpHeight;
        lViz = rec.left >= 0 && rec.left < vpWidth;
        rViz = rec.right > 0 && rec.right <= vpWidth;
        vVisible = partial ? tViz || bViz : tViz && bViz;
        hVisible = partial ? lViz || rViz : lViz && rViz;
        if (direction === 'both') {
          return clientSize && vVisible && hVisible;
        } else if (direction === 'vertical') {
          return clientSize && vVisible;
        } else if (direction === 'horizontal') {
          return clientSize && hVisible;
        }
      } else {
        viewTop = $w.scrollTop();
        viewBottom = viewTop + vpHeight;
        viewLeft = $w.scrollLeft();
        viewRight = viewLeft + vpWidth;
        offset = $t.offset();
        _top = offset.top;
        _bottom = _top + $t.height();
        _left = offset.left;
        _right = _left + $t.width();
        compareTop = partial === true ? _bottom : _top;
        compareBottom = partial === true ? _top : _bottom;
        compareLeft = partial === true ? _right : _left;
        compareRight = partial === true ? _left : _right;
        if (direction === 'both') {
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop)) && ((compareRight <= viewRight) && (compareLeft >= viewLeft));
        } else if (direction === 'vertical') {
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop));
        } else if (direction === 'horizontal') {
          return !!clientSize && ((compareRight <= viewRight) && (compareLeft >= viewLeft));
        }
      }
    };

    ZammadChat.prototype.isRetina = function() {
      var mq;
      if (window.matchMedia) {
        mq = window.matchMedia('only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)');
        return mq && mq.matches || (window.devicePixelRatio > 1);
      }
      return false;
    };

    ZammadChat.prototype.resizeImage = function(dataURL, x, y, sizeFactor, type, quallity, callback, force) {
      var imageObject;
      if (x == null) {
        x = 'auto';
      }
      if (y == null) {
        y = 'auto';
      }
      if (sizeFactor == null) {
        sizeFactor = 1;
      }
      if (force == null) {
        force = true;
      }
      imageObject = new Image();
      imageObject.onload = function() {
        var canvas, context, factor, imageHeight, imageWidth, newDataUrl, resize;
        imageWidth = imageObject.width;
        imageHeight = imageObject.height;
        console.log('ImageService', 'current size', imageWidth, imageHeight);
        if (y === 'auto' && x === 'auto') {
          x = imageWidth;
          y = imageHeight;
        }
        if (y === 'auto') {
          factor = imageWidth / x;
          y = imageHeight / factor;
        }
        if (x === 'auto') {
          factor = imageWidth / y;
          x = imageHeight / factor;
        }
        resize = false;
        if (x < imageWidth || y < imageHeight) {
          resize = true;
          x = x * sizeFactor;
          y = y * sizeFactor;
        } else {
          x = imageWidth;
          y = imageHeight;
        }
        canvas = document.createElement('canvas');
        canvas.width = x;
        canvas.height = y;
        context = canvas.getContext('2d');
        context.drawImage(imageObject, 0, 0, x, y);
        if (quallity === 'auto') {
          if (x < 200 && y < 200) {
            quallity = 1;
          } else if (x < 400 && y < 400) {
            quallity = 0.9;
          } else if (x < 600 && y < 600) {
            quallity = 0.8;
          } else if (x < 900 && y < 900) {
            quallity = 0.7;
          } else {
            quallity = 0.6;
          }
        }
        newDataUrl = canvas.toDataURL(type, quallity);
        if (resize) {
          console.log('ImageService', 'resize', x / sizeFactor, y / sizeFactor, quallity, (newDataUrl.length * 0.75) / 1024 / 1024, 'in mb');
          callback(newDataUrl, x / sizeFactor, y / sizeFactor, true);
          return;
        }
        console.log('ImageService', 'no resize', x, y, quallity, (newDataUrl.length * 0.75) / 1024 / 1024, 'in mb');
        return callback(newDataUrl, x, y, false);
      };
      return imageObject.src = dataURL;
    };

    ZammadChat.prototype.pasteHtmlAtCaret = function(html) {
      var el, frag, lastNode, node, range, sel;
      sel = void 0;
      range = void 0;
      if (window.getSelection) {
        sel = window.getSelection();
        if (sel.getRangeAt && sel.rangeCount) {
          range = sel.getRangeAt(0);
          range.deleteContents();
          el = document.createElement('div');
          el.innerHTML = html;
          frag = document.createDocumentFragment(node, lastNode);
          while (node = el.firstChild) {
            lastNode = frag.appendChild(node);
          }
          range.insertNode(frag);
          if (lastNode) {
            range = range.cloneRange();
            range.setStartAfter(lastNode);
            range.collapse(true);
            sel.removeAllRanges();
            return sel.addRange(range);
          }
        }
      } else if (document.selection && document.selection.type !== 'Control') {
        return document.selection.createRange().pasteHTML(html);
      }
    };

    ZammadChat.prototype.wordFilter = function(editor) {
      var content, last_level, pnt;
      content = editor.html();
      content = content.replace(/<!--[\s\S]+?-->/gi, '');
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '');
      content = content.replace(/<(\/?)s>/gi, '<$1strike>');
      content = content.replace(/&nbsp;/gi, ' ');
      editor.html(content);
      $('p', editor).each(function() {
        var matches, str;
        str = $(this).attr('style');
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str);
        if (matches) {
          return $(this).data('_listLevel', parseInt(matches[1], 10));
        }
      });
      last_level = 0;
      pnt = null;
      $('p', editor).each(function() {
        var cur_level, i, j, list_tag, matches, ref, ref1, start, txt;
        cur_level = $(this).data('_listLevel');
        if (cur_level !== void 0) {
          txt = $(this).text();
          list_tag = '<ul></ul>';
          if (/^\s*\w+\./.test(txt)) {
            matches = /([0-9])\./.exec(txt);
            if (matches) {
              start = parseInt(matches[1], 10);
              list_tag = start > 1 ? '<ol start="' + start + '"></ol>' : '<ol></ol>';
            } else {
              list_tag = '<ol></ol>';
            }
          }
          if (cur_level > last_level) {
            if (last_level === 0) {
              $(this).before(list_tag);
              pnt = $(this).prev();
            } else {
              pnt = $(list_tag).appendTo(pnt);
            }
          }
          if (cur_level < last_level) {
            for (i = j = ref = i, ref1 = last_level - cur_level; ref <= ref1 ? j <= ref1 : j >= ref1; i = ref <= ref1 ? ++j : --j) {
              pnt = pnt.parent();
            }
          }
          $('span:first', this).remove();
          pnt.append('<li>' + $(this).html() + '</li>');
          $(this).remove();
          return last_level = cur_level;
        } else {
          return last_level = 0;
        }
      });
      $('[style]', editor).removeAttr('style');
      $('[align]', editor).removeAttr('align');
      $('span', editor).replaceWith(function() {
        return $(this).contents();
      });
      $('span:empty', editor).remove();
      $("[class^='Mso']", editor).removeAttr('class');
      $('p:empty', editor).remove();
      return editor;
    };

    ZammadChat.prototype.removeAttribute = function(element) {
      var $element, att, j, len, ref;
      if (!element) {
        return;
      }
      $element = $(element);
      ref = element.attributes;
      for (j = 0, len = ref.length; j < len; j++) {
        att = ref[j];
        if (att && att.name) {
          element.removeAttribute(att.name);
        }
      }
      return $element.removeAttr('style').removeAttr('class').removeAttr('lang').removeAttr('type').removeAttr('align').removeAttr('id').removeAttr('wrap').removeAttr('title');
    };

    ZammadChat.prototype.removeAttributes = function(html, parent) {
      if (parent == null) {
        parent = true;
      }
      if (parent) {
        html.each((function(_this) {
          return function(index, element) {
            return _this.removeAttribute(element);
          };
        })(this));
      }
      html.find('*').each((function(_this) {
        return function(index, element) {
          return _this.removeAttribute(element);
        };
      })(this));
      return html;
    };

    return ZammadChat;

  })(Base);
  return window.ZammadChat = ZammadChat;
})(window.jQuery, window);
