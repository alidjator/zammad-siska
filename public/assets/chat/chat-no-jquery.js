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
    
      __out.push('>\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body zammad-chat-attachment"><span class="zammad-chat-attachment-row"><span class="zammad-chat-attachment-icon">');
    
      __out.push(this.icon('paperclip', 20, {
        tone: 'full'
      }));
    
      __out.push('</span><span class="zammad-chat-attachment-info"><span class="zammad-chat-attachment-filename">');
    
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
    
      __out.push(__sanitize(this.filename));
    
      __out.push('" class="zammad-chat-attachment-download js-attachment-download" target="_blank" rel="noopener" aria-label="');
    
      __out.push(this.T('Download'));
    
      __out.push('">');
    
      __out.push(this.icon('download-simple', 16));
    
      __out.push('</a></span><span class="zammad-chat-message-time">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('">');
        __out.push(this.icon('checks', 16));
        __out.push('</span>');
      }
    
      __out.push('</span></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('">');
        __out.push(this.icon('arrow-bend-up-left', 14));
        __out.push('</button>');
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
    
      __out.push('">\n        ');
    
      __out.push(this.icon('caret-down', 17));
    
      __out.push('\n      </button>\n      <button type="button" class="zammad-chat-header-icon js-chat-close" aria-label="');
    
      __out.push(this.T('End chat'));
    
      __out.push('">\n        ');
    
      __out.push(this.icon('x', 17, {
        "class": 'zammad-chat-header-icon-close'
      }));
    
      __out.push('\n      </button>\n    </div>\n  </div>\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--home is-active"></div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--messages">\n    <div class="zammad-chat-modal"></div>\n    <div class="zammad-scroll-hint is-hidden">\n      ');
    
      __out.push(this.icon('arrow-circle-down', 20, {
        "class": 'zammad-scroll-hint-icon'
      }));
    
      __out.push('\n      ');
    
      __out.push(this.T(this.scrollHint));
    
      __out.push('\n    </div>\n    <div class="zammad-chat-body"></div>\n    <div class="zammad-chat-reply-indicator js-reply-indicator zammad-chat-is-hidden"></div>\n    <form class="zammad-chat-controls">\n      <div class="zammad-chat-emoji-picker js-emoji-picker zammad-chat-is-hidden"></div>\n      <div class="zammad-chat-input" rows="1" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
    
      __out.push('" contenteditable="true"></div>\n      <div class="zammad-chat-controls-icons">\n        <button type="button" class="zammad-chat-emoji-toggle js-emoji-toggle" aria-label="');
    
      __out.push(this.T('Emoji'));
    
      __out.push('" aria-expanded="false">\n          ');
    
      __out.push(this.icon('smiley', 16, {
        tone: 'active'
      }));
    
      __out.push('\n        </button>\n        <!-- Fitur kirim gambar (mockup "Fitur kirim gambar"): tombol TERPISAH\n        dari Attach, pemilih file khusus gambar (di ponsel otomatis\n        menawarkan kamera/galeri). Tampil/sembunyi ikut flag\n        `attachment_enabled` yg sama dgn Attach. Upload lewat endpoint\n        lampiran yg SAMA (`uploadAttachment`). -->\n        <button type="button" class="zammad-chat-attach zammad-chat-attach-image js-chat-attach-image zammad-chat-is-hidden" aria-label="');
    
      __out.push(this.T('Add image'));
    
      __out.push('">\n          ');
    
      __out.push(this.icon('image', 16));
    
      __out.push('\n        </button>\n        <input type="file" accept="image/jpeg,image/png,image/gif,image/webp" class="js-chat-image-input zammad-chat-is-hidden">\n        <button type="button" class="zammad-chat-attach js-chat-attach zammad-chat-is-hidden" aria-label="');
    
      __out.push(this.T('Attach file'));
    
      __out.push('">\n          ');
    
      __out.push(this.icon('paperclip', 16));
    
      __out.push('\n        </button>\n        <input type="file" class="js-chat-attachment-input zammad-chat-is-hidden">\n        <button type="submit" class="zammad-chat-send" aria-label="');
    
      __out.push(this.T('Send'));
    
      __out.push('"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>\n          ');
    
      __out.push(this.icon('paper-plane-right', 15));
    
      __out.push('\n        </button>\n      </div>\n    </form>\n  </div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--help"></div>\n\n  <div class="zammad-chat-tabbar"></div>\n\n  <!-- Atas permintaan user (mockup "SISKA Widget Mockup" -- board\n  IndicatorReconnecting/Restored/Lost): indikator fullpage\n  semi-transparan status koneksi WebSocket widget sendiri, menutupi\n  seluruh panel (isi disuntik dinamis oleh `showConnectionOverlay()`,\n  lihat `connection_overlay.eco`). -->\n  <!-- Audit kit Tailwind: `aria-live` -- perubahan status koneksi\n  (Reconnecting -> restored/lost) dibacakan pembaca layar. -->\n  <div class="zammad-chat-connection-overlay js-connection-overlay zammad-chat-is-hidden" aria-live="polite"></div>\n\n  <!-- Atas permintaan user: layar "Terima kasih" SETELAH submit\n  feedback (rating-nya sendiri sekarang inline di `.zammad-chat-body`,\n  lihat `showFeedback`) tetap fullpage -- container TERPISAH dari\n  overlay koneksi di atas (semantik beda, sengaja tidak dicampur),\n  gaya visual scrim sama (lihat `chat.scss`). Isi disuntik dinamis\n  oleh `showFeedbackThanks()`. -->\n  <div class="zammad-chat-feedback-thanks-overlay js-feedback-thanks-overlay zammad-chat-is-hidden"></div>\n</div>');
    
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
        __out.push('\n  <!-- Audit kit Tailwind: spinner satu elemen (lihat chat.scss) +\n  `role="status"`/`sr-only` spt spinner Waiting/EndingChat. -->\n  <div class="zammad-chat-connection-overlay-spinner" role="status">\n    <span class="zammad-chat-sr-only">');
        __out.push(this.T('Loading...'));
        __out.push('</span>\n  </div>\n');
      } else if (this.state === 'restored') {
        __out.push('\n  <div class="zammad-chat-connection-overlay-icon">\n    ');
        __out.push(this.icon('check-circle', 56, {
          tone: 'full'
        }));
        __out.push('\n  </div>\n');
      } else {
        __out.push('\n  <div class="zammad-chat-connection-overlay-icon">\n    ');
        __out.push(this.icon('x-circle', 56, {
          tone: 'full'
        }));
        __out.push('\n  </div>\n');
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
      __out.push('<!-- Audit ulang kit Tailwind: tiap emoji <button type="button"> (bukan <span>)\nsupaya bisa dipilih lewat Tab + Enter; `type="button"` WAJIB karena picker\nberada di dalam <form class="zammad-chat-controls"> (default submit). -->\n<div class="zammad-chat-emoji-picker-title">');
    
      __out.push(this.T('Emoji'));
    
      __out.push('</div>\n<div class="zammad-chat-emoji-picker-grid" role="group" aria-label="');
    
      __out.push(this.T('Emoji'));
    
      __out.push('">\n  <button type="button" class="js-emoji-item" data-emoji="😀" aria-label="Grinning">😀</button>\n  <button type="button" class="js-emoji-item" data-emoji="😂" aria-label="Joy">😂</button>\n  <button type="button" class="js-emoji-item" data-emoji="😍" aria-label="Heart eyes">😍</button>\n  <button type="button" class="js-emoji-item" data-emoji="😊" aria-label="Smile">😊</button>\n  <button type="button" class="js-emoji-item" data-emoji="🙏" aria-label="Thanks">🙏</button>\n  <button type="button" class="js-emoji-item" data-emoji="👍" aria-label="Thumbs up">👍</button>\n  <button type="button" class="js-emoji-item" data-emoji="👋" aria-label="Wave">👋</button>\n  <button type="button" class="js-emoji-item" data-emoji="❤️" aria-label="Heart">❤️</button>\n  <button type="button" class="js-emoji-item" data-emoji="😢" aria-label="Sad">😢</button>\n  <button type="button" class="js-emoji-item" data-emoji="😮" aria-label="Surprised">😮</button>\n  <button type="button" class="js-emoji-item" data-emoji="🎉" aria-label="Party">🎉</button>\n  <button type="button" class="js-emoji-item" data-emoji="🔥" aria-label="Fire">🔥</button>\n  <button type="button" class="js-emoji-item" data-emoji="✅" aria-label="Check">✅</button>\n  <button type="button" class="js-emoji-item" data-emoji="💡" aria-label="Idea">💡</button>\n  <button type="button" class="js-emoji-item" data-emoji="🤔" aria-label="Thinking">🤔</button>\n  <button type="button" class="js-emoji-item" data-emoji="👌" aria-label="OK">👌</button>\n  <button type="button" class="js-emoji-item" data-emoji="🙌" aria-label="Raised hands">🙌</button>\n  <button type="button" class="js-emoji-item" data-emoji="😎" aria-label="Cool">😎</button>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Audit kit Able Pro TAILWIND baru -- lihat catatan sama di\n  waiting.eco, modifier warna via `--danger` (chat.scss). -->\n  <!-- Audit kit Tailwind (EndingChat): preseden `bc_spinner.html` kit\n  selalu memberi spinner `role="status"` + teks `sr-only` "Loading..."\n  -- supaya pembaca layar mengumumkan status memuat (tidak terlihat\n  secara visual, lihat `.zammad-chat-sr-only` di chat.scss). -->\n  <div class="zammad-chat-waiting-spinner zammad-chat-waiting-spinner--danger" role="status">\n    <span class="zammad-chat-sr-only">');
    
      __out.push(this.T('Loading...'));
    
      __out.push('</span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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
      __out.push('<div class="zammad-chat-feedback-thanks">\n  <div class="zammad-chat-feedback-thanks-icon">\n    ');
    
      __out.push(this.icon('check-circle', 30, {
        tone: 'full'
      }));
    
      __out.push('\n  </div>\n  <div class="zammad-chat-feedback-thanks-title">');
    
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
    
      __out.push('</div>\n\n  <!-- Atas permintaan user (audit kit Tailwind, mockup "Feedback - ikuti\n  kit"): bintang DIGANTI hati -- preseden rating "Heart" kit\n  (`forms/form2_rating.html`, ikon `feather-heart`). Class `-star` &\n  `js-feedback-star` SENGAJA dipertahankan (dipakai logic skor di\n  chat-no-jquery.coffee), cuma ikonnya yg berubah. -->\n  <div class="zammad-chat-feedback-stars">\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="1" aria-label="1">');
    
      __out.push(this.icon('heart', 26, {
        tone: 'active',
        "class": 'zammad-chat-feedback-heart'
      }));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="2" aria-label="2">');
    
      __out.push(this.icon('heart', 26, {
        tone: 'active',
        "class": 'zammad-chat-feedback-heart'
      }));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="3" aria-label="3">');
    
      __out.push(this.icon('heart', 26, {
        tone: 'active',
        "class": 'zammad-chat-feedback-heart'
      }));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="4" aria-label="4">');
    
      __out.push(this.icon('heart', 26, {
        tone: 'active',
        "class": 'zammad-chat-feedback-heart'
      }));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="5" aria-label="5">');
    
      __out.push(this.icon('heart', 26, {
        tone: 'active',
        "class": 'zammad-chat-feedback-heart'
      }));
    
      __out.push('</button>\n  </div>\n\n  <textarea class="zammad-chat-feedback-textarea js-feedback-comment" placeholder="');
    
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
window.zammadChatTemplates["file_upload"] = function(__obj) {
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
      __out.push('<!-- Permintaan user ("upload file attachment ada progressnya juga seperti\nupload gambar"): placeholder kartu file SELAMA upload -- nama file,\npersentase, progress bar tipis gaya `bc_progress.html` kit (track\nbodybg, bar primary-500 rounded-lg, role="progressbar"). Diganti kartu\nfile asli DI POSISINYA saat broadcast `chat_session_attachment` milik\nsendiri tiba (`addAttachmentMessage`), dihapus kalau upload gagal. -->\n<div class="zammad-chat-message zammad-chat-message--customer zammad-chat-message--uploading js-file-upload" data-upload-id="');
    
      __out.push(__sanitize(this.uploadId));
    
      __out.push('">\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body zammad-chat-attachment"><span class="zammad-chat-attachment-row"><span class="zammad-chat-attachment-icon">');
    
      __out.push(this.icon('paperclip', 20, {
        tone: 'full'
      }));
    
      __out.push('</span><span class="zammad-chat-attachment-info"><span class="zammad-chat-attachment-filename">');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('</span><span class="zammad-chat-attachment-meta js-upload-progress-text">');
    
      __out.push(this.T('Uploading…'));
    
      __out.push(' 0%</span></span></span><span class="zammad-chat-upload-progress"><span class="zammad-chat-upload-progress-bar js-upload-progress-bar" role="progressbar" aria-label="');
    
      __out.push(this.T('Upload progress'));
    
      __out.push('" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100"></span></span></span></span>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-help">\n  <div class="zammad-chat-help-search-wrap">\n    ');
    
      __out.push(this.icon('magnifying-glass', 16, {
        "class": 'zammad-chat-help-search-icon'
      }));
    
      __out.push('\n    <input type="text" class="zammad-chat-help-search js-kb-search" placeholder="');
    
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
      __out.push('<div class="zammad-chat-home">\n  <!-- Atas permintaan user ("rubah total Home dan OfflineHome") --\n  ikon bubble chat lama (dari sprite kit VUE) diganti `custom-message-2`,\n  yang GENUINELY ada di sprite "custom" kit Tailwind baru sendiri\n  (`dist/assets/js/icon/custom-font.js`, bukan Tabler kali ini --\n  ikon ini kebetulan SUDAH tersedia asli di kit ini, prioritas 1\n  dibanding cari padanan Tabler). Duotone SENGAJA dipertahankan\n  (`opacity="0.4"` di path pertama) -- gaya asli ikon ini di kit\n  Tailwind (beda dari mayoritas ikon widget lain yang flat 1 opacity),\n  BUKAN kesalahan/disederhanakan. Ukuran badge (52px) & radius\n  (`$siska-radius-lg`=12px) TETAP -- dicek ULANG ke preseden NYATA kit\n  baru (`w_chart.html`: `.w-10.h-10.rounded-xl` = ikon-dlm-kotak,\n  radius `rounded-xl`=12px SAMA PERSIS) -- cuma radiusnya yang\n  terverifikasi identik, ukuran 52px & background SOLID (bukan tint\n  10%) tetap dipertahankan sengaja krn ini logo BRANDING hero (satu-\n  satunya elemen dominan halaman), bukan ikon aksen kecil di kartu\n  dashboard -- preseden itu tidak berlaku sama utk konteks beda ini. -->\n  <div class="zammad-chat-home-logo">\n    <div class="zammad-chat-home-logo-mark">\n      <svg width="26" height="26" viewBox="0 0 24 24"><path opacity="0.4" d="M7 18.4302H11L15.45 21.3902C16.11 21.8302 17 21.3602 17 20.5602V18.4302C20 18.4302 22 16.4302 22 13.4302V7.43018C22 4.43018 20 2.43018 17 2.43018H7C4 2.43018 2 4.43018 2 7.43018V13.4302C2 16.4302 4 18.4302 7 18.4302Z" fill="currentColor"/><path d="M15.5 11.25H8.5C8.09 11.25 7.75 10.91 7.75 10.5C7.75 10.09 8.09 9.75 8.5 9.75H15.5C15.91 9.75 16.25 10.09 16.25 10.5C16.25 10.91 15.91 11.25 15.5 11.25Z" fill="currentColor"/></svg>\n    </div>\n  </div>\n\n  <!-- Enhancement 1 -- Tahap 3 (Offline Message + OTP), mockup OfflineHome.dc.html.\n  Tersembunyi default -- ditampilkan lewat `enterOfflineMode()` (chat.coffee)\n  begitu `chat_status_customer` balas state \'offline\' (SEMUA agent tidak\n  tersedia, termasuk yg lagi AUX -- lihat entri 143). -->\n  <!-- Atas permintaan user (audit kit Able Pro TAILWIND baru, HANYA\n  Home/OfflineHome): pola alert diganti ke `.alert-warning` GENUINE\n  kit baru (lihat chat.scss), teks tetap 1 baris (judul+deskripsi\n  digabung, kedua Setting tetap dipakai). Ikon `custom-warning-fill`\n  LAMA (sprite kit VUE) TIDAK ADA padanannya di kit Tailwind baru --\n  diganti path `alert-triangle` Tabler Icons (dipilih user), diekstrak\n  LANGSUNG dari glyph SVG font kit ini\n  (`assets/fonts/tabler/tabler-icons.svg`, glyph-name="alert-triangle",\n  unicode \\ea06) -- BUKAN digambar ulang manual/ditebak. Koordinat\n  glyph font di-flip vertikal (`scale(1,-1) translate(0,-986.5)`,\n  986.5 = ascent font ini) krn sistem koordinat SVG font terbalik dari\n  SVG biasa -- hasil render dikonfirmasi tegak lewat `rsvg-convert`\n  sebelum dipakai di sini. -->\n  <div class="zammad-chat-home-offline-notice zammad-chat-is-hidden">\n    ');
    
      __out.push(this.icon('warning', 20, {
        tone: 'full',
        "class": 'zammad-chat-home-offline-notice-icon'
      }));
    
      __out.push('\n    <span class="zammad-chat-home-offline-notice-text">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_notice_title'] || 'All agents are currently unavailable'));
    
      __out.push(' ');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_notice'] || 'Leave your message and email, we will verify it via an OTP code and reply as soon as possible.'));
    
      __out.push('</span>\n  </div>\n\n  <!-- Notice agent online -- pola SAMA (audit kit Tailwind baru,\n  `.alert-info`). Ikon `info-circle` Tabler (dipilih user), diekstrak\n  & diverifikasi render dgn cara SAMA persis spt alert-triangle di\n  atas (unicode \\eac5). -->\n  <div class="zammad-chat-home-online-notice zammad-chat-is-hidden">\n    ');
    
      __out.push(this.icon('info', 20, {
        tone: 'full',
        "class": 'zammad-chat-home-online-notice-icon'
      }));
    
      __out.push('\n    <span class="zammad-chat-home-online-notice-text">');
    
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
window.zammadChatTemplates["image_message"] = function(__obj) {
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
      __out.push('<!-- Fitur kirim gambar (mockup "Fitur kirim gambar"): bubble gambar gaya\nWhatsApp -- thumbnail `?view=preview` (lebar ~480px dari server), jam &\ncentang ditumpuk di pojok kanan bawah gambar. Klik -> tampilan layar penuh\n(`openImageViewer`, data diambil dari atribut `data-*` tombol). Gagal\ndimuat -> class `is-broken`, tampil fallback nama file (kartu file). -->\n<div class="zammad-chat-message zammad-chat-message--');
    
      __out.push(__sanitize(this.from));
    
      __out.push(__sanitize(this.unreadClass));
    
      __out.push('"');
    
      if (this.id) {
        __out.push(' data-message-id="');
        __out.push(__sanitize(this.id));
        __out.push('"');
      }
    
      __out.push('>\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body zammad-chat-image"><button type="button" class="zammad-chat-image-open js-image-open" aria-label="');
    
      __out.push(this.T('View image'));
    
      __out.push('" data-url="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('" data-filename="');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('" data-meta="');
    
      __out.push(__sanitize(this.metaLabel));
    
      __out.push('" data-sender="');
    
      __out.push(__sanitize(this.senderLabel));
    
      __out.push('" data-time="');
    
      __out.push(__sanitize(this.time));
    
      __out.push('"><img class="zammad-chat-image-thumb js-image-thumb" src="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('?view=preview" alt="');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('" loading="lazy"><span class="zammad-chat-image-fallback">');
    
      __out.push(this.icon('image', 20, {
        tone: 'full'
      }));
    
      __out.push('<span class="zammad-chat-image-fallback-name">');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('</span></span><span class="zammad-chat-image-meta">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('">');
        __out.push(this.icon('checks', 16));
        __out.push('</span>');
      }
    
      __out.push('</span></button></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('">');
        __out.push(this.icon('arrow-bend-up-left', 14));
        __out.push('</button>');
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
window.zammadChatTemplates["image_upload"] = function(__obj) {
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
      __out.push('<!-- Fitur kirim gambar: placeholder SELAMA upload -- preview lokal (object\nURL) diburamkan + spinner kit + persentase. Diganti bubble gambar asli\nsaat broadcast `chat_session_attachment` milik sendiri tiba\n(`addAttachmentMessage`), dihapus kalau upload gagal. -->\n<div class="zammad-chat-message zammad-chat-message--customer zammad-chat-message--uploading js-image-upload" data-upload-id="');
    
      __out.push(__sanitize(this.uploadId));
    
      __out.push('">\n  <span class="zammad-chat-message-row"><span class="zammad-chat-message-body zammad-chat-image"><span class="zammad-chat-image-open zammad-chat-image-open--uploading"><img class="zammad-chat-image-thumb" src="');
    
      __out.push(__sanitize(this.previewUrl));
    
      __out.push('" alt=""><span class="zammad-chat-image-uploading" role="status"><span class="zammad-chat-image-spinner" aria-hidden="true"></span><span class="zammad-chat-sr-only">');
    
      __out.push(this.T('Uploading…'));
    
      __out.push('</span></span></span><span class="zammad-chat-image-progress js-image-progress">');
    
      __out.push(this.T('Uploading…'));
    
      __out.push(' 0%</span></span></span>\n</div>\n');
    
    }).call(this);
    
  }).call(__obj);
  __obj.safe = __objSafe, __obj.escape = __escape;
  return __out.join('');
};

if (!window.zammadChatTemplates) {
  window.zammadChatTemplates = {};
}
window.zammadChatTemplates["image_viewer"] = function(__obj) {
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
      __out.push('<!-- Fitur kirim gambar (mockup "Kirim gambar - layar penuh"): overlay\nmenutupi SELURUH halaman (ditempel ke <body>, bukan di dalam panel).\nTutup: tombol Close, Esc, klik area gelap. Fokus dikunci di dalam dialog\n(`openImageViewer` di chat-no-jquery.coffee). -->\n<div class="zammad-chat-image-viewer js-image-viewer" role="dialog" aria-modal="true" aria-label="');
    
      __out.push(this.T('Image preview'));
    
      __out.push('">\n  <div class="zammad-chat-image-viewer-bar">\n    <span class="zammad-chat-image-viewer-icon">');
    
      __out.push(this.icon('image', 18, {
        tone: 'full'
      }));
    
      __out.push('</span>\n    <span class="zammad-chat-image-viewer-info">\n      <span class="zammad-chat-image-viewer-name">');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('</span>\n      <span class="zammad-chat-image-viewer-meta">');
    
      __out.push(__sanitize([this.sender, this.time, this.meta].filter(function(part) {
        return part;
      }).join(' · ')));
    
      __out.push('</span>\n    </span>\n    <a class="zammad-chat-image-viewer-download js-image-viewer-download" href="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('?disposition=attachment" download="');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('" target="_blank" rel="noopener">');
    
      __out.push(this.icon('download-simple', 18));
    
      __out.push('<span>');
    
      __out.push(this.T('Download'));
    
      __out.push('</span></a>\n    <button type="button" class="zammad-chat-image-viewer-close js-image-viewer-close" aria-label="');
    
      __out.push(this.T('Close'));
    
      __out.push('">');
    
      __out.push(this.icon('x', 20));
    
      __out.push('</button>\n  </div>\n  <div class="zammad-chat-image-viewer-stage js-image-viewer-stage">\n    <img class="zammad-chat-image-viewer-img" src="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('" alt="');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('">\n  </div>\n</div>\n');
    
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
    
      __out.push('" target="_blank" rel="noopener noreferrer" class="zammad-chat-kb-result-link">\n    <span class="zammad-chat-kb-result-icon">\n      ');
    
      __out.push(this.icon('book-open-text', 18, {
        tone: 'full'
      }));
    
      __out.push('\n    </span>\n    <span class="zammad-chat-kb-result-text">\n      <span class="zammad-chat-kb-result-title">');
    
      __out.push(this.title);
    
      __out.push('</span>\n      <span class="zammad-chat-kb-result-body">');
    
      __out.push(this.body);
    
      __out.push('</span>\n    </span>\n    ');
    
      __out.push(this.icon('caret-right', 14, {
        "class": 'zammad-chat-kb-result-chevron'
      }));
    
      __out.push('\n  </a>\n</li>\n');
    
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
      __out.push('<!-- Audit kit Tailwind (mockup "Launcher - ikuti kit" disetujui): <div>\n-> <button> spt preseden `.btn` kit -- bisa difokus lewat Tab & dibaca\npembaca layar. `aria-expanded` disinkronkan di open()/close()\n(chat-no-jquery.coffee).\nIkon seragam Phosphor Duotone kit (helper `@icon`): chat-circle-dots\n(tertutup) & caret-down (terbuka), tone \'full\' -- tombol utama. -->\n<button type="button" class="zammad-chat-launcher" aria-label="');
    
      __out.push(this.T('Chat'));
    
      __out.push('" aria-expanded="false">\n  ');
    
      __out.push(this.icon('chat-circle-dots', 24, {
        tone: 'full',
        "class": 'zammad-chat-launcher-icon-open'
      }));
    
      __out.push('\n  ');
    
      __out.push(this.icon('caret-down', 24, {
        tone: 'full',
        "class": 'zammad-chat-launcher-icon-close'
      }));
    
      __out.push('\n</button>\n');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Audit kit Able Pro TAILWIND baru -- lihat catatan sama di\n  waiting.eco. -->\n  <!-- Audit kit Tailwind (EndingChat): preseden `bc_spinner.html` kit\n  selalu memberi spinner `role="status"` + teks `sr-only` "Loading..."\n  -- supaya pembaca layar mengumumkan status memuat (tidak terlihat\n  secara visual, lihat `.zammad-chat-sr-only` di chat.scss). -->\n  <div class="zammad-chat-waiting-spinner" role="status">\n    <span class="zammad-chat-sr-only">');
    
      __out.push(this.T('Loading...'));
    
      __out.push('</span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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
        __out.push('">');
        __out.push(this.icon('checks', 16));
        __out.push('</span>');
      }
    
      __out.push('</span></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('">');
        __out.push(this.icon('arrow-bend-up-left', 14));
        __out.push('</button>');
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
      __out.push('<div class="zammad-chat-offline-compose">\n  <div class="zammad-chat-offline-compose-verified">\n    ');
    
      __out.push(this.icon('check', 15));
    
      __out.push('\n    <span><strong>');
    
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
    
      __out.push('"></textarea>\n\n  <div class="zammad-chat-offline-compose-error js-offline-compose-error zammad-chat-is-hidden"></div>\n\n  <!-- Item lampiran (follow-up terpisah dari Enhancement 4 awal).\n  Diisi dinamis lewat JS (`onOfflineAttachmentUploaded`) -- kosong\n  by default, TIDAK ADA tombol hapus (endpoint DELETE tidak ada di\n  manapun di codebase ini, konsisten dgn attachment chat biasa yang\n  juga fire-and-forget/tidak bisa dibatalkan). -->\n  <div class="zammad-chat-offline-compose-attachments js-offline-compose-attachments"></div>\n\n  <button type="button" class="zammad-chat-offline-compose-attach js-offline-compose-attach">\n    ');
    
      __out.push(this.icon('paperclip', 16));
    
      __out.push('\n    <span>');
    
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
      __out.push('<div class="zammad-chat-offline-otp">\n  <div class="zammad-chat-offline-otp-icon">\n    ');
    
      __out.push(this.icon('lock', 26, {
        tone: 'full'
      }));
    
      __out.push('\n  </div>\n  <div class="zammad-chat-offline-otp-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_title'] || 'Enter verification code'));
    
      __out.push('</div>\n  <div class="zammad-chat-offline-otp-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_subtitle_prefix'] || 'We sent a 6-digit code to'));
    
      __out.push(' <strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong>.</div>\n\n  <div class="zammad-chat-offline-otp-boxes">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="0">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="1">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="2">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="3">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="4">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" placeholder="0" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="5">\n  </div>\n\n  <div class="zammad-chat-offline-otp-error js-otp-error zammad-chat-is-hidden">\n    ');
    
      __out.push(this.icon('clock', 14));
    
      __out.push('\n    <span class="js-otp-error-text"></span>\n  </div>\n\n  <button type="button" class="zammad-chat-offline-otp-submit js-otp-submit">');
    
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
      __out.push('<div class="zammad-chat-offline-sent">\n  <div class="zammad-chat-offline-sent-icon">\n    ');
    
      __out.push(this.icon('check-circle', 30, {
        tone: 'full'
      }));
    
      __out.push('\n  </div>\n  <div class="zammad-chat-offline-sent-title">');
    
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
    
      __out.push('</span>\n  ');
    
      __out.push(this.icon('check', 16, {
        "class": 'zammad-chat-prechat-category-check'
      }));
    
      __out.push('\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-prechat">\n  <div class="zammad-chat-prechat-icon">\n    ');
    
      __out.push(this.icon('chat-circle-dots', 24, {
        tone: 'full'
      }));
    
      __out.push('\n  </div>\n  <div class="zammad-chat-prechat-title">');
    
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
        __out.push('\n      <div class="zammad-chat-prechat-notice">\n        ');
        __out.push(this.icon('check-circle', 16, {
          tone: 'full'
        }));
        __out.push('\n        <span>');
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
    
      __out.push('</span>\n        ');
    
      __out.push(this.icon('caret-down', 16, {
        "class": 'zammad-chat-prechat-category-chevron'
      }));
    
      __out.push('\n      </button>\n      <input type="hidden" class="js-prechat-category-input" value="');
    
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
      __out.push('<div class="zammad-chat-preload" style="box-sizing:border-box;position:fixed;right:24px;bottom:92px;width:380px;max-width:calc(100vw - 48px);height:640px;max-height:calc(100vh - 116px);background:#ffffff;border:1px solid #e8ebee;border-radius:8px;box-shadow:0 12px 32px rgba(19,25,32,0.12);display:flex;align-items:center;justify-content:center;z-index:999;">\n  <!-- Audit kit Tailwind: spinner SAMA dgn `.zammad-chat-waiting-spinner`\n  (preseden `bc_spinner.html` kit: satu elemen, sisi kiri transparan,\n  1s, tanpa ikon) -- inline style krn chat.css belum termuat saat\n  preload tampil. `role="status"` + teks sr-only (inline) spt spinner\n  lain. -->\n  <style>@keyframes zammad-chat-preload-spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}</style>\n  <div role="status" style="box-sizing:border-box;width:48px;height:48px;border-radius:50%;border:4px solid #4680FF;border-left-color:transparent;animation:zammad-chat-preload-spin 1s linear infinite;">\n    <span style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0;">');
    
      __out.push(this.T('Loading...'));
    
      __out.push('</span>\n  </div>\n</div>\n');
    
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
    
      __out.push('</span>\n<!-- Audit ulang kit Tailwind: karakter teks `&times;` di <span> diganti\n<button> + ikon Tabler `ti ti-x` (glyph asli kit, pola btn-link-secondary)\nsupaya bisa difokus & dipakai lewat keyboard. -->\n<button type="button" class="zammad-chat-reply-indicator-cancel js-reply-cancel" aria-label="');
    
      __out.push(this.T('Cancel reply'));
    
      __out.push('">');
    
      __out.push(this.icon('x', 14));
    
      __out.push('</button>\n');
    
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
      __out.push('<!-- Ikon seragam Phosphor Duotone kit (lewat helper `@icon`, lihat\n`siskaIcon` di chat-no-jquery.coffee): house, chat-circle-dots,\nbook-open-text, tone \'active\' -- lapisan isi hanya tampil di tab aktif.\nAudit kit Tailwind (mockup "Tabbar - ikuti kit" disetujui): ikon\ndibungkus `.zammad-chat-tabbar-icon` (wadah latar penanda aktif/hover,\npreseden `nav-link` sidebar layout "tab" kit), 20px -> 22px.\n`aria-current` disinkronkan di switchTab() (chat-no-jquery.coffee). -->\n<button type="button" class="zammad-chat-tabbar-item is-active" data-tab="home" aria-current="page">\n  <span class="zammad-chat-tabbar-icon">');
    
      __out.push(this.icon('house', 22, {
        tone: 'active'
      }));
    
      __out.push('</span>\n  <span>');
    
      __out.push(this.T('Home'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="messages">\n  <span class="zammad-chat-tabbar-icon">');
    
      __out.push(this.icon('chat-circle-dots', 22, {
        tone: 'active'
      }));
    
      __out.push('</span>\n  <span>');
    
      __out.push(this.T('Messages'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="help">\n  <span class="zammad-chat-tabbar-icon">');
    
      __out.push(this.icon('book-open-text', 22, {
        tone: 'active'
      }));
    
      __out.push('</span>\n  <span>');
    
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
      __out.push('<!-- Audit ulang kit Tailwind (mockup "Messages detail - ikuti kit"): tampilan\ntetap (kit tidak punya komponen typing); ditambah `role="status"` + teks\n`sr-only` (pola sama dgn spinner Waiting/EndingChat) supaya pembaca layar\ntahu agent sedang mengetik. Titik-titik disembunyikan dari pembaca layar. -->\n<div class="zammad-chat-message zammad-chat-message--typing zammad-chat-message--agent" role="status">\n  <span class="zammad-chat-message-body"><span class="zammad-chat-loading-animation" aria-hidden="true"><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span><span class="zammad-chat-loading-circle"></span></span><span class="zammad-chat-sr-only">');
    
      __out.push(this.T('Agent is typing…'));
    
      __out.push('</span></span>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <!-- Atas permintaan user (audit kit Able Pro TAILWIND baru, mockup\n  "Waiting.dc.html" opsi 1 disetujui) -- spinner SEKARANG satu elemen\n  polos (lihat chat.scss), track/ikon di tengah DIHAPUS, tidak ada\n  padanannya di preseden kit baru. -->\n  <!-- Audit kit Tailwind (EndingChat): preseden `bc_spinner.html` kit\n  selalu memberi spinner `role="status"` + teks `sr-only` "Loading..."\n  -- supaya pembaca layar mengumumkan status memuat (tidak terlihat\n  secara visual, lihat `.zammad-chat-sr-only` di chat.scss). -->\n  <div class="zammad-chat-waiting-spinner" role="status">\n    <span class="zammad-chat-sr-only">');
    
      __out.push(this.T('Loading...'));
    
      __out.push('</span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  slice = [].slice,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function(window) {
  var Base, Core, Io, Log, SISKA_ICONS, Timeout, ZammadChat, ensureViewportMeta, myScript, scriptHost, scriptProtocol, scripts, siskaIcon;
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
  Core = (function() {
    Core.prototype.defaults = {
      debug: false
    };

    function Core(options) {
      var key, ref, value;
      this.options = {};
      ref = this.defaults;
      for (key in ref) {
        value = ref[key];
        this.options[key] = value;
      }
      for (key in options) {
        value = options[key];
        this.options[key] = value;
      }
    }

    return Core;

  })();
  Base = (function(superClass) {
    extend(Base, superClass);

    function Base(options) {
      Base.__super__.constructor.call(this, options);
      this.log = new Log({
        debug: this.options.debug,
        logPrefix: this.options.logPrefix || this.logPrefix
      });
    }

    return Base;

  })(Core);
  Log = (function(superClass) {
    extend(Log, superClass);

    function Log() {
      this.log = bind(this.log, this);
      this.error = bind(this.error, this);
      this.notice = bind(this.notice, this);
      this.debug = bind(this.debug, this);
      return Log.__super__.constructor.apply(this, arguments);
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
      var element, item, j, len, logString;
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
      element = document.querySelector('.js-chatLogDisplay');
      if (element) {
        return element.innerHTML = '<div>' + logString + '</div>' + element.innerHTML;
      }
    };

    return Log;

  })(Core);
  Timeout = (function(superClass) {
    extend(Timeout, superClass);

    function Timeout() {
      this.stop = bind(this.stop, this);
      this.start = bind(this.start, this);
      return Timeout.__super__.constructor.apply(this, arguments);
    }

    Timeout.prototype.timeoutStartedAt = null;

    Timeout.prototype.logPrefix = 'timeout';

    Timeout.prototype.defaults = {
      debug: false,
      timeout: 4,
      timeoutIntervallCheck: 0.5
    };

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

    function Io() {
      this.ping = bind(this.ping, this);
      this.send = bind(this.send, this);
      this.reconnect = bind(this.reconnect, this);
      this.close = bind(this.close, this);
      this.attemptReconnect = bind(this.attemptReconnect, this);
      this.connect = bind(this.connect, this);
      this.set = bind(this.set, this);
      return Io.__super__.constructor.apply(this, arguments);
    }

    Io.prototype.logPrefix = 'io';

    Io.prototype.reconnectAttempts = 0;

    Io.prototype.maxReconnectAttempts = 6;

    Io.prototype.reconnectBaseDelay = 1000;

    Io.prototype.reconnectMaxDelay = 30000;

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
  SISKA_ICONS = {
    'arrow-bend-up-left': ["M320 224v384l-192-192z", "M512 384h-160v-160c0-0.007 0-0.016 0-0.025 0-17.673-14.327-32-32-32-8.843 0-16.848 3.587-22.64 9.385l-0 0-192 192c-5.798 5.792-9.385 13.797-9.385 22.64s3.587 16.848 9.385 22.64l0 0 192 192c5.792 5.798 13.797 9.385 22.64 9.385 17.673 0 32-14.327 32-32 0-0.009-0-0.018-0-0.027l0 0.001v-160h160c194.313 0.228 351.772 157.687 352 351.978l0 0.022c0 17.673 14.327 32 32 32s32-14.327 32-32v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM288 530.76l-114.76-114.76 114.76-114.76z"],
    'arrow-circle-down': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM662.64 521.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-0 0-128 128c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-128-128c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l73.36 73.4v-242.76c0-17.673 14.327-32 32-32s32 14.327 32 32v0 242.76l73.36-73.4c5.792-5.798 13.797-9.385 22.64-9.385s16.848 3.587 22.64 9.385l0 0z"],
    'book-open-text': ["M928 256v512c0 17.673-14.327 32-32 32v0h-256c-70.692 0-128 57.308-128 128v0-576c0-70.692 57.308-128 128-128v0h256c17.673 0 32 14.327 32 32v0z", "M896 192h-256c-52.165 0-98.5 24.964-127.708 63.598l-0.292 0.402c-29.5-39.036-75.835-64-128-64v0h-256c-35.346 0-64 28.654-64 64v0 512c0 35.346 28.654 64 64 64v0h256c53.019 0 96 42.981 96 96v0c0 17.673 14.327 32 32 32s32-14.327 32-32v0c0-53.019 42.981-96 96-96v0h256c35.346 0 64-28.654 64-64v0-512c0-35.346-28.654-64-64-64v0zM384 768h-256v-512h256c53.019 0 96 42.981 96 96v0 448c-26.32-19.976-59.629-32-95.747-32-0.089 0-0.178 0-0.267 0l0.014-0zM896 768h-256c-0.075-0-0.164-0-0.253-0-36.117 0-69.426 12.024-96.142 32.288l0.396-0.288v-448c0-53.019 42.981-96 96-96v0h256zM640 352h160c17.673 0 32 14.327 32 32s-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0zM832 512c0 17.673-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0h160c17.673 0 32 14.327 32 32v0zM832 640c0 17.673-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0h160c17.673 0 32 14.327 32 32v0z"],
    'caret-down': ["M832 384l-320 320-320-320z", "M861.56 371.76c-4.934-11.696-16.306-19.757-29.56-19.76l-640-0c-0.007-0-0.016-0-0.025-0-17.673 0-32 14.327-32 32 0 8.843 3.587 16.848 9.385 22.64l0 0 320 320c5.792 5.798 13.797 9.385 22.64 9.385s16.848-3.587 22.64-9.385l0-0 320-320c5.785-5.79 9.363-13.786 9.363-22.618 0-4.425-0.898-8.639-2.522-12.472l0.079 0.21zM512 658.76l-242.76-242.76h485.52z"],
    'caret-right': ["M704 512l-320 320v-640z", "M726.64 489.36l-320-320c-5.792-5.798-13.797-9.385-22.64-9.385-17.673 0-32 14.327-32 32 0 0.009 0 0.018 0 0.027l-0-0.001v640c-0 0.007-0 0.016-0 0.025 0 17.673 14.327 32 32 32 8.843 0 16.848-3.587 22.64-9.385l0-0 320-320c5.798-5.792 9.385-13.797 9.385-22.64s-3.587-16.848-9.385-22.64l-0-0zM416 754.76v-485.52l242.76 242.76z"],
    'chat-circle-dots': ["M896 512c0 0.014 0 0.031 0 0.048 0 212.077-171.923 384-384 384-70.806 0-137.136-19.164-194.086-52.588l1.806 0.98-149.56 49.88c-3.021 1.042-6.502 1.644-10.124 1.644-17.673 0-32-14.327-32-32 0-3.622 0.602-7.103 1.71-10.349l-0.067 0.225 49.88-149.56c-32.414-55.124-51.56-121.425-51.56-192.197 0-212.077 171.923-384 384-384 212.048 0 383.953 171.875 384 383.912l0 0.005z", "M512 96c-0.027-0-0.059-0-0.091-0-229.75 0-416 186.25-416 416 0 71.565 18.071 138.91 49.9 197.72l-1.089-2.2-45.4 136.2c-2.084 6.042-3.287 13.004-3.287 20.247 0 35.346 28.654 64 64 64 7.243 0 14.205-1.203 20.698-3.421l-0.45 0.134 136.2-45.4c56.567 30.683 123.852 48.72 195.349 48.72 229.75 0 416-186.25 416-416 0-229.69-186.152-415.903-415.82-416l-0.009-0zM512 864c-0.071 0-0.155 0-0.239 0-64.812 0-125.526-17.542-177.654-48.137l1.654 0.897c-4.587-2.706-10.105-4.309-15.997-4.32l-0.003-0c-3.623 0.002-7.103 0.617-10.34 1.747l0.22-0.067-149.64 49.88 49.88-149.6c1.048-3.029 1.653-6.519 1.653-10.151 0-5.895-1.594-11.417-4.374-16.16l0.082 0.151c-29.734-50.544-47.298-111.341-47.298-176.24 0-194.404 157.596-352 352-352s352 157.596 352 352c0 194.384-157.563 351.967-351.939 352l-0.003 0zM560 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM384 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM736 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"],
    'check': ["M928 224v576c0 35.346-28.654 64-64 64v0h-704c-35.346 0-64-28.654-64-64v0-576c0-35.346 28.654-64 64-64v0h704c35.346 0 64 28.654 64 64v0z", "M822.64 342.64l-384 384c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-160-160c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l137.36 137.4 361.36-361.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0z"],
    'check-circle': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M694.64 393.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-0 0-224 224c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-96-96c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l73.36 73.4 201.36-201.4c5.792-5.798 13.797-9.385 22.64-9.385s16.848 3.587 22.64 9.385l0 0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022z"],
    'checks': ["M960 256v512c0 35.346-28.654 64-64 64v0h-768c-35.346 0-64-28.654-64-64v0-512c0-35.346 28.654-64 64-64v0h768c35.346 0 64 28.654 64 64v0z", "M566.64 406.64l-224 224c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-96-96c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378h0l73.36 73.4 201.36-201.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0zM854.64 361.36c-5.792-5.798-13.797-9.385-22.64-9.385s-16.848 3.587-22.64 9.385l-0 0-201.36 201.4-41.36-41.4c-5.794-5.794-13.799-9.378-22.64-9.378-17.683 0-32.018 14.335-32.018 32.018 0 8.841 3.584 16.846 9.378 22.64l64 64c5.792 5.798 13.797 9.385 22.64 9.385s16.848-3.587 22.64-9.385l0-0 224-224c5.798-5.792 9.385-13.797 9.385-22.64s-3.587-16.848-9.385-22.64l-0-0z"],
    'clock': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM768 512c0 17.673-14.327 32-32 32v0h-224c-17.673 0-32-14.327-32-32v0-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0 192h192c17.673 0 32 14.327 32 32v0z"],
    'download-simple': ["M672 448l-160 160-160-160z", "M896 608v224c0 35.346-28.654 64-64 64v0h-640c-35.346 0-64-28.654-64-64v0-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0 224h640v-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0zM329.36 470.64c-5.798-5.792-9.385-13.797-9.385-22.64 0-17.673 14.327-32 32-32 0.009 0 0.018 0 0.027 0l127.999-0v-256c0-17.673 14.327-32 32-32s32 14.327 32 32v0 256h128c0.007-0 0.016-0 0.025-0 17.673 0 32 14.327 32 32 0 8.843-3.587 16.848-9.385 22.64l-0 0-160 160c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0zM429.36 480l82.64 82.76 82.76-82.76z"],
    'heart': ["M928 376c0 264-416 488-416 488s-416-224-416-488c0-119.294 96.706-216 216-216v0c90.36 0 167.76 49.24 200 128 32.24-78.76 109.64-128 200-128 119.294 0 216 96.706 216 216v0z", "M712 128c-82.6 0-154.92 35.52-200 95.56-45.080-60.040-117.4-95.56-200-95.56-136.903 0.159-247.841 111.097-248 247.985l-0 0.015c0 280 415.16 506.64 432.84 516 4.385 2.405 9.607 3.819 15.16 3.819s10.775-1.414 15.327-3.903l-0.167 0.084c17.68-9.36 432.84-236 432.84-516-0.159-136.903-111.097-247.841-247.985-248l-0.015-0zM512 827.2c-73.040-42.56-384-236.44-384-451.2 0.136-101.565 82.435-183.864 183.987-184l0.013-0c77.8 0 143.12 41.44 170.4 108 4.916 11.742 16.312 19.841 29.6 19.841s24.684-8.099 29.521-19.63l0.079-0.211c27.28-66.68 92.6-108 170.4-108 101.565 0.136 183.864 82.435 184 183.987l0 0.013c0 214.44-311.040 408.6-384 451.2z"],
    'house': ["M864 462.16v369.84c0 17.673-14.327 32-32 32v0h-192c-17.673 0-32-14.327-32-32v0-192c0-17.673-14.327-32-32-32v0h-128c-17.673 0-32 14.327-32 32v0 192c0 17.673-14.327 32-32 32v0h-192c-17.673 0-32-14.327-32-32v0-369.84c0.001-9.373 4.032-17.805 10.455-23.657l0.025-0.023 320-302.16c5.663-5.169 13.232-8.335 21.54-8.335s15.877 3.166 21.565 8.358l-0.025-0.023 320 302.16c6.425 5.873 10.44 14.291 10.44 23.647 0 0.012-0 0.023-0 0.035l0-0.002z", "M875.32 415.080l-320-301.92c-0.158-0.138-0.302-0.282-0.435-0.435l-0.005-0.005c-11.324-10.327-26.453-16.652-43.060-16.652s-31.736 6.325-43.11 16.697l0.050-0.045-0.44 0.44-319.64 301.92c-12.732 11.735-20.68 28.495-20.68 47.11 0 0.003 0 0.007 0 0.010l-0-0.001v369.8c0 35.346 28.654 64 64 64v0h192c35.346 0 64-28.654 64-64v0-192h128v192c0 35.346 28.654 64 64 64v0h192c35.346 0 64-28.654 64-64v0-369.8c0-0.003 0-0.006 0-0.010 0-18.616-7.948-35.375-20.636-47.070l-0.044-0.040zM832 832h-192v-192c0-35.346-28.654-64-64-64v0h-128c-35.346 0-64 28.654-64 64v0 192h-192v-369.8l0.44-0.4 319.56-301.8 320.040 302.12z"],
    'info': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M576 704c0 17.673-14.327 32-32 32v0c-35.346 0-64-28.654-64-64v0-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0c35.346 0 64 28.654 64 64v0 160c17.673 0 32 14.327 32 32v0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022zM496 384c26.51 0 48-21.49 48-48s-21.49-48-48-48c-26.51 0-48 21.49-48 48v0c0 26.51 21.49 48 48 48v0z"],
    'lock': ["M864 384v448c0 17.673-14.327 32-32 32v0h-640c-17.673 0-32-14.327-32-32v0-448c0-17.673 14.327-32 32-32v0h640c17.673 0 32 14.327 32 32v0z", "M832 320h-128v-96c0-106.039-85.961-192-192-192s-192 85.961-192 192v0 96h-128c-35.346 0-64 28.654-64 64v0 448c0 35.346 28.654 64 64 64v0h640c35.346 0 64-28.654 64-64v0-448c0-35.346-28.654-64-64-64v0zM384 224c0-70.692 57.308-128 128-128s128 57.308 128 128v0 96h-256zM832 832h-640v-448h640v448zM560 608c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"],
    'magnifying-glass': ["M768 448c0 176.731-143.269 320-320 320s-320-143.269-320-320c0-176.731 143.269-320 320-320v0c176.731 0 320 143.269 320 320v0z", "M918.64 873.36l-200.24-200.24c50.917-60.738 81.843-139.736 81.843-225.957 0-194.868-157.972-352.84-352.84-352.84s-352.84 157.972-352.84 352.84c0 194.868 157.972 352.84 352.84 352.84 86.111 0 165.018-30.847 226.272-82.095l-0.555 0.452 200.24 200.28c5.794 5.794 13.799 9.378 22.64 9.378 17.683 0 32.018-14.335 32.018-32.018 0-8.841-3.584-16.846-9.378-22.64l0 0zM160 448c0-159.058 128.942-288 288-288s288 128.942 288 288c0 159.058-128.942 288-288 288v0c-158.985-0.182-287.818-129.015-288-287.983l-0-0.017z"],
    'paper-plane-right': ["M879.64 539.44l-671.92 384.56c-4.498 2.561-9.883 4.071-15.62 4.071-17.673 0-32-14.327-32-32 0-3.855 0.682-7.551 1.931-10.974l-0.071 0.222 124-362.84c1.198-3.201 1.891-6.899 1.891-10.76s-0.693-7.559-1.962-10.978l0.071 0.218-124-361.88c-1.178-3.2-1.86-6.896-1.86-10.751 0-17.673 14.327-32 32-32 5.737 0 11.122 1.51 15.779 4.154l-0.158-0.083 672 383.4c9.715 5.616 16.147 15.956 16.147 27.797 0 11.874-6.467 22.238-16.072 27.76l-0.155 0.082z", "M895.48 456l-672-383.56c-9.013-5.147-19.808-8.182-31.311-8.182-35.346 0-64 28.654-64 64 0 7.531 1.301 14.759 3.69 21.47l-0.139-0.447 124 361.88c-0.008 0.060-0.012 0.13-0.012 0.2s0.004 0.14 0.013 0.208l-0.001-0.008c-0.011 0.060-0.017 0.129-0.017 0.2s0.006 0.14 0.018 0.207l-0.001-0.007-124 362.68c-2.325 6.36-3.67 13.703-3.67 21.36 0 35.329 28.625 63.971 63.947 64l0.003 0c11.653-0.031 22.572-3.144 31.993-8.566l-0.313 0.166 671.64-384.2c19.669-11.172 32.722-31.98 32.722-55.836 0-23.776-12.965-44.523-32.21-55.559l-0.312-0.165zM192 896v-0.36l120.56-351.64h231.44c17.673 0 32-14.327 32-32s-14.327-32-32-32v0h-231.12l-120.64-351.52-0.24-0.48 672 383.32z"],
    'paperclip': ["M723 419l93 93-328.24 327.76c-34.631 34.087-82.185 55.134-134.654 55.134-106.039 0-192-85.961-192-192 0-52.47 21.047-100.023 55.159-134.679l-0.025 0.025 397.24-402.76c23.166-23.166 55.17-37.495 90.52-37.495 70.701 0 128.015 57.314 128.015 128.015 0 35.35-14.329 67.354-37.495 90.52v0z", "M838.64 489.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-328.2 328c-40.54 40.535-96.542 65.606-158.4 65.606-123.726 0-224.026-100.3-224.026-224.026 0-61.868 25.079-117.878 65.625-158.42l0-0 397.040-402.88c28.966-28.996 68.998-46.932 113.22-46.932 88.383 0 160.032 71.649 160.032 160.032 0 44.162-17.888 84.146-46.814 113.101l0.001-0.001-397.12 402.88c-17.403 17.403-41.444 28.167-68 28.167-53.111 0-96.167-43.055-96.167-96.167 0-26.556 10.764-50.597 28.167-68l0-0 333.2-338.48c5.853-6.233 14.146-10.115 23.346-10.115 17.673 0 32 14.327 32 32 0 9.021-3.733 17.17-9.738 22.987l-0.008 0.008-333.24 338.84c-5.845 5.8-9.464 13.838-9.464 22.72 0 17.675 14.329 32.004 32.004 32.004 8.793 0 16.758-3.546 22.542-9.286l-0.002 0.002 397.080-402.68c17.427-17.392 28.208-41.437 28.208-68 0-53.057-43.011-96.068-96.068-96.068-26.494 0-50.482 10.725-67.862 28.069l0.002-0.002-396.96 402.72c-29.011 28.967-46.958 69.007-46.958 113.24 0 88.376 71.643 160.018 160.018 160.018 44.143 0 84.111-17.874 113.062-46.78l-0.002 0.002 328.24-328c5.782-5.739 13.747-9.285 22.54-9.285 8.873 0 16.902 3.611 22.698 9.444l0.002 0.002z"],
    'smiley': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM320 432c0-26.51 21.49-48 48-48s48 21.49 48 48c0 26.51-21.49 48-48 48v0c-26.51 0-48-21.49-48-48v0zM704 432c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM699.68 624c-41.16 71.16-109.56 112-187.68 112s-146.52-40.8-187.68-112c-3.133-4.86-4.995-10.796-4.995-17.167 0-17.673 14.327-32 32-32 12.25 0 22.893 6.884 28.271 16.994l0.084 0.173c29.88 51.64 76.84 80 132.32 80s102.44-28.4 132.32-80c5.462-10.283 16.104-17.167 28.355-17.167 17.673 0 32 14.327 32 32 0 6.371-1.862 12.307-5.071 17.294l0.076-0.127z"],
    'warning': ["M861.84 864h-699.68c-50.48 0-82.16-52.84-57.64-95.64l349.84-607.48c25.2-44 90.080-44 115.28 0l349.84 607.48c24.52 42.8-7.16 95.64-57.64 95.64z", "M947.2 752.36l-349.8-607.48c-17.525-29.455-49.194-48.883-85.4-48.883s-67.875 19.428-85.149 48.428l-0.251 0.455-349.8 607.48c-8.072 13.588-12.843 29.957-12.843 47.44s4.771 33.852 13.082 47.875l-0.239-0.435c17.146 29.356 48.5 48.765 84.389 48.765 0.356 0 0.711-0.002 1.066-0.006l-0.054 0h699.6c0.277 0.003 0.604 0.004 0.932 0.004 35.888 0 67.242-19.409 84.139-48.304l0.249-0.461c8.097-13.604 12.883-29.998 12.883-47.508 0-17.455-4.756-33.8-13.042-47.808l0.239 0.437zM891.72 815.2c-6.013 10.125-16.892 16.805-29.331 16.805-0.207 0-0.413-0.002-0.619-0.006l0.031 0h-699.6c-0.175 0.003-0.382 0.005-0.589 0.005-12.439 0-23.318-6.68-29.245-16.649l-0.086-0.157c-2.651-4.416-4.219-9.745-4.219-15.44s1.568-11.024 4.296-15.578l-0.077 0.138 349.8-607.48c6.23-10.239 17.329-16.972 30-16.972s23.77 6.734 29.913 16.818l0.087 0.154 349.8 607.48c2.602 4.384 4.14 9.665 4.14 15.305 0 5.75-1.599 11.127-4.376 15.711l0.076-0.135zM480 576v-160c0-17.673 14.327-32 32-32s32 14.327 32 32v0 160c0 17.673-14.327 32-32 32s-32-14.327-32-32v0zM560 720c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"],
    'x': ["M864 192v640c0 17.673-14.327 32-32 32v0h-640c-17.673 0-32-14.327-32-32v0-640c0-17.673 14.327-32 32-32v0h640c17.673 0 32 14.327 32 32v0z", "M822.64 777.36c5.794 5.794 9.378 13.799 9.378 22.64 0 17.683-14.335 32.018-32.018 32.018-8.841 0-16.846-3.584-22.64-9.378l-265.36-265.4-265.36 265.4c-5.794 5.794-13.799 9.378-22.64 9.378-17.683 0-32.018-14.335-32.018-32.018 0-8.841 3.584-16.846 9.378-22.64l-0 0 265.4-265.36-265.4-265.36c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l265.36 265.4 265.36-265.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l-0 0-265.4 265.36z"],
    'x-circle': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M662.64 406.64l-105.4 105.36 105.4 105.36c5.794 5.794 9.378 13.799 9.378 22.64 0 17.683-14.335 32.018-32.018 32.018-8.841 0-16.846-3.584-22.64-9.378l-105.36-105.4-105.36 105.4c-5.794 5.794-13.799 9.378-22.64 9.378-17.683 0-32.018-14.335-32.018-32.018 0-8.841 3.584-16.846 9.378-22.64l105.4-105.36-105.4-105.36c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l105.36 105.4 105.36-105.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022z"],
    'image': ["M896 224v488.24l-158.88-158.88c-5.79-5.786-13.787-9.365-22.62-9.365s-16.83 3.579-22.62 9.365l-102.64 102.64-198.6-198.64c-5.792-5.798-13.797-9.385-22.64-9.385s-16.848 3.587-22.64 9.385l-0 0-217.36 217.4v-450.76c0-17.673 14.327-32 32-32v0h704c17.673 0 32 14.327 32 32v0z", "M864 160h-704c-35.346 0-64 28.654-64 64v0 576c0 35.346 28.654 64 64 64v0h704c35.346 0 64-28.654 64-64v0-576c0-35.346-28.654-64-64-64v0zM864 224v411l-104.28-104.24c-11.582-11.585-27.584-18.75-45.26-18.75s-33.678 7.166-45.26 18.75l-80 80-176-176c-11.58-11.573-27.574-18.73-45.24-18.73s-33.66 7.157-45.24 18.731l-162.72 162.72v-373.48zM160 688l208-208 320 320h-528zM864 800h-85.48l-144-144 80-80 149.48 149.52v74.48zM576 400c0-26.51 21.49-48 48-48s48 21.49 48 48c0 26.51-21.49 48-48 48v0c-26.51 0-48-21.49-48-48v0z"]
  };
  siskaIcon = function(name, size, opts) {
    var cls, fill, paths, tone;
    if (size == null) {
      size = 16;
    }
    if (opts == null) {
      opts = {};
    }
    paths = SISKA_ICONS[name];
    if (!paths) {
      return '';
    }
    tone = opts.tone || 'single';
    cls = opts["class"] ? " class=\"" + opts["class"] + "\"" : '';
    fill = '';
    if (tone === 'full') {
      fill = "<path opacity=\"0.2\" d=\"" + paths[0] + "\"/>";
    } else if (tone === 'active') {
      fill = "<path class=\"zammad-chat-icon-fill\" d=\"" + paths[0] + "\"/>";
    }
    return "<svg" + cls + " width=\"" + size + "\" height=\"" + size + "\" viewBox=\"0 0 1024 1024\" fill=\"currentColor\" aria-hidden=\"true\">" + fill + "<path d=\"" + paths[1] + "\"/></svg>";
  };
  ZammadChat = (function(superClass) {
    extend(ZammadChat, superClass);

    ZammadChat.prototype.defaults = {
      chatId: void 0,
      show: true,
      target: document.querySelector('body'),
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
          options.icon = siskaIcon;
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
      this.autoSubmitOfflineOtp = bind(this.autoSubmitOfflineOtp, this);
      this.onOtpDigitPaste = bind(this.onOtpDigitPaste, this);
      this.onOtpDigitKeydown = bind(this.onOtpDigitKeydown, this);
      this.onOtpDigitInput = bind(this.onOtpDigitInput, this);
      this.showOfflineOtp = bind(this.showOfflineOtp, this);
      this.onOfflineSessionInitResult = bind(this.onOfflineSessionInitResult, this);
      this.applyOnlineHomeState = bind(this.applyOnlineHomeState, this);
      this.applyOfflineHomeState = bind(this.applyOfflineHomeState, this);
      this.enterOfflineMode = bind(this.enterOfflineMode, this);
      this.submitPrechatForm = bind(this.submitPrechatForm, this);
      this.setButtonLoading = bind(this.setButtonLoading, this);
      this.showPrechatForm = bind(this.showPrechatForm, this);
      this.open = bind(this.open, this);
      this.closeImageViewer = bind(this.closeImageViewer, this);
      this.onImageViewerKeydown = bind(this.onImageViewerKeydown, this);
      this.openImageViewer = bind(this.openImageViewer, this);
      this.removeImageUpload = bind(this.removeImageUpload, this);
      this.releaseImageUpload = bind(this.releaseImageUpload, this);
      this.updateImageUpload = bind(this.updateImageUpload, this);
      this.addFileUpload = bind(this.addFileUpload, this);
      this.addImageUpload = bind(this.addImageUpload, this);
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
      this.onInput = bind(this.onInput, this);
      this.onReopenSession = bind(this.onReopenSession, this);
      this.onError = bind(this.onError, this);
      this.onWebSocketMessage = bind(this.onWebSocketMessage, this);
      this.send = bind(this.send, this);
      this.onKeydown = bind(this.onKeydown, this);
      this.onPaste = bind(this.onPaste, this);
      this.onDrop = bind(this.onDrop, this);
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
      ZammadChat.__super__.constructor.call(this, options);
      if (typeof jQuery !== 'undefined' && this.options.target instanceof jQuery) {
        this.log.notice('Chat: target option is a jQuery object. jQuery is not a requirement for the chat any more.');
        this.options.target = this.options.target.get(0);
      }
      this.isFullscreen = window.matchMedia && window.matchMedia('(max-width: 768px)').matches;
      this.scrollRoot = this.getScrollRoot();
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
        this.options.lang = document.documentElement.getAttribute('lang');
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
      start = parseInt(html.pageYOffset, 10);
      html.pageYOffset = start + 1;
      end = parseInt(html.pageYOffset, 10);
      html.pageYOffset = start;
      if (end > start) {
        return html;
      } else {
        return document.body;
      }
    };

    ZammadChat.prototype.render = function() {
      var btn;
      if (!this.el || !document.querySelector('.zammad-chat')) {
        this.renderBase();
      }
      btn = document.querySelector("." + this.options.buttonClass);
      if (btn) {
        btn.classList.add(this.options.inactiveClass);
      }
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
      this.options.target.insertAdjacentHTML('beforeend', this.view('preload')());
      return this.preloadEl = this.options.target.querySelector('.zammad-chat-preload');
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
      if (this.el) {
        this.el.remove();
      }
      if (this.launcherEl) {
        this.launcherEl.remove();
      }
      this.options.target.insertAdjacentHTML('beforeend', this.view('chat')({
        title: this.options.title,
        scrollHint: this.options.scrollHint
      }));
      this.el = this.options.target.querySelector('.zammad-chat');
      if (!this.cssLoaded) {
        this.el.style.display = 'none';
      }
      this.options.target.insertAdjacentHTML('beforeend', this.view('launcher')());
      this.launcherEl = this.options.target.querySelector('.zammad-chat-launcher');
      if (!this.cssLoaded) {
        this.launcherEl.style.display = 'none';
      }
      this.launcherEl.addEventListener('click', this.toggle);
      this.input = this.el.querySelector('.zammad-chat-input');
      this.body = this.el.querySelector('.zammad-chat-body');
      this.el.querySelector('.js-chat-close').addEventListener('click', this.exitChat);
      this.el.querySelector('.js-chat-minimize').addEventListener('click', this.close);
      this.el.querySelector('.zammad-chat-agent').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-chat-status');
          if (!target) {
            return;
          }
          return _this.stopPropagation(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-controls').addEventListener('submit', this.onSubmit);
      this.body.addEventListener('scroll', this.detectScrolledtoBottom);
      this.el.querySelector('.zammad-scroll-hint').addEventListener('click', this.onScrollHintClick);
      this.input.addEventListener('keydown', this.onKeydown);
      this.input.addEventListener('input', this.onInput);
      this.input.addEventListener('paste', this.onPaste);
      this.input.addEventListener('drop', this.onDrop);
      this.body.addEventListener('click', this.startReply);
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-waiting-cancel');
          if (!target) {
            return;
          }
          return _this.cancelQueue(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-submit');
          if (!target) {
            return;
          }
          return _this.submitOfflineOtp(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-resend');
          if (!target) {
            return;
          }
          return _this.resendOfflineOtp(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-change-email');
          if (!target) {
            return;
          }
          return _this.showPrechatForm();
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('input', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-digit');
          if (!target) {
            return;
          }
          return _this.onOtpDigitInput(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('keydown', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-digit');
          if (!target) {
            return;
          }
          return _this.onOtpDigitKeydown(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('paste', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-otp-digit');
          if (!target) {
            return;
          }
          return _this.onOtpDigitPaste(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-offline-compose-submit');
          if (!target) {
            return;
          }
          return _this.submitOfflineMessage(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-offline-sent-done');
          if (!target) {
            return;
          }
          return _this.finishOfflineFlow(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-offline-compose-attach');
          if (!target) {
            return;
          }
          return _this.triggerOfflineAttachmentInput(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('change', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-offline-compose-attachment-input');
          if (!target) {
            return;
          }
          return _this.uploadOfflineAttachment(event);
        };
      })(this));
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-feedback-star');
          if (!target) {
            return;
          }
          return _this.selectFeedbackScore(event, target.dataset.score);
        };
      })(this));
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-feedback-submit');
          if (!target) {
            return;
          }
          return _this.submitFeedback(event);
        };
      })(this));
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-feedback-skip');
          if (!target) {
            return;
          }
          return _this.skipFeedback(event);
        };
      })(this));
      this.el.querySelector('.js-chat-attach').addEventListener('click', this.triggerAttachmentInput);
      this.el.querySelector('.js-chat-attachment-input').addEventListener('change', this.uploadAttachment);
      this.el.querySelector('.js-chat-attach-image').addEventListener('click', (function(_this) {
        return function(event) {
          event.preventDefault();
          return _this.el.querySelector('.js-chat-image-input').click();
        };
      })(this));
      this.el.querySelector('.js-chat-image-input').addEventListener('change', this.uploadAttachment);
      this.body.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-image-open');
          if (!target) {
            return;
          }
          return _this.openImageViewer(target);
        };
      })(this));
      this.body.addEventListener('error', (function(_this) {
        return function(event) {
          var ref, ref1;
          if (!((ref = event.target.classList) != null ? ref.contains('js-image-thumb') : void 0)) {
            return;
          }
          return (ref1 = event.target.closest('.js-image-open')) != null ? ref1.classList.add('is-broken') : void 0;
        };
      })(this), true);
      this.body.addEventListener('load', (function(_this) {
        return function(event) {
          var ref;
          if (!((ref = event.target.classList) != null ? ref.contains('js-image-thumb') : void 0)) {
            return;
          }
          return _this.scrollToBottom();
        };
      })(this), true);
      this.el.querySelector('.zammad-chat-tab-body--home').innerHTML = this.view('home')();
      this.el.querySelector('.zammad-chat-tab-body--help').innerHTML = this.view('help')();
      this.el.querySelector('.zammad-chat-tabbar').innerHTML = this.view('tabbar')();
      this.el.querySelector('.js-emoji-picker').innerHTML = this.view('emoji_picker')();
      this.activeTab = 'home';
      this.updateHeader('home');
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var isHomeAction, target;
          target = event.target.closest('[data-tab]');
          if (!target) {
            return;
          }
          isHomeAction = !!target.closest('.zammad-chat-home-actions');
          if (isHomeAction) {
            _this.setButtonLoading(target, true);
          }
          _this.switchTab(target.dataset.tab);
          if (isHomeAction) {
            return _this.setButtonLoading(target, false);
          }
        };
      })(this));
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-connection-reload');
          if (!target) {
            return;
          }
          return window.location.reload();
        };
      })(this));
      this.el.querySelector('.js-emoji-toggle').addEventListener('click', this.toggleEmojiPicker);
      this.el.querySelector('.js-emoji-picker').addEventListener('click', (function(_this) {
        return function(event) {
          var item;
          item = event.target.closest('.js-emoji-item');
          if (!item) {
            return;
          }
          return _this.insertEmoji(item.dataset.emoji);
        };
      })(this));
      this.el.addEventListener('input', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-kb-search');
          if (!target) {
            return;
          }
          return _this.onKbSearchInput(event);
        };
      })(this));
      this.el.addEventListener('scroll', this.onKbResultsScroll, true);
      window.addEventListener('beforeunload', this.onLeaveTemporary);
      return window.addEventListener('hashchange', (function(_this) {
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
    };

    ZammadChat.prototype.switchTab = function(tabName) {
      var activeBody, activeItem, body, item, j, k, len, len1, ref, ref1;
      if (this.activeTab === tabName) {
        return;
      }
      this.activeTab = tabName;
      ref = this.el.querySelectorAll('.zammad-chat-tab-body');
      for (j = 0, len = ref.length; j < len; j++) {
        body = ref[j];
        body.classList.remove('is-active');
      }
      activeBody = this.el.querySelector(".zammad-chat-tab-body--" + tabName);
      if (activeBody != null) {
        activeBody.classList.add('is-active');
      }
      ref1 = this.el.querySelectorAll('.zammad-chat-tabbar-item');
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        item = ref1[k];
        item.classList.remove('is-active');
        item.removeAttribute('aria-current');
      }
      activeItem = this.el.querySelector(".zammad-chat-tabbar-item[data-tab='" + tabName + "']");
      if (activeItem != null) {
        activeItem.classList.add('is-active');
      }
      if (activeItem != null) {
        activeItem.setAttribute('aria-current', 'page');
      }
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
      this.el.querySelector('.zammad-chat-header').classList.toggle('zammad-chat-header--tinted', showWelcome);
      this.el.querySelector('.zammad-chat-welcome').classList.toggle('zammad-chat-is-hidden', !showWelcome);
      this.el.querySelector('.zammad-chat-agent').classList.toggle('zammad-chat-is-hidden', !showAgent);
      this.el.querySelector('.zammad-chat-header-title').classList.toggle('zammad-chat-is-hidden', !showTitle);
      if (showTitle) {
        title = tabName === 'help' ? this.T('Help') : this.T('Messages');
        return this.el.querySelector('.js-header-title-text').textContent = title;
      }
    };

    ZammadChat.prototype.toggleEmojiPicker = function(event) {
      var isOpen;
      if (event != null) {
        event.preventDefault();
      }
      this.el.querySelector('.js-emoji-picker').classList.toggle('zammad-chat-is-hidden');
      isOpen = this.el.querySelector('.js-emoji-toggle').classList.toggle('is-active');
      return this.el.querySelector('.js-emoji-toggle').setAttribute('aria-expanded', String(isOpen));
    };

    ZammadChat.prototype.insertEmoji = function(emoji) {
      this.input.focus();
      document.execCommand('insertText', false, emoji);
      this.el.querySelector('.js-emoji-picker').classList.add('zammad-chat-is-hidden');
      this.el.querySelector('.js-emoji-toggle').classList.remove('is-active');
      this.el.querySelector('.js-emoji-toggle').setAttribute('aria-expanded', 'false');
      return this.onInput();
    };

    ZammadChat.prototype.onKbSearchInput = function(event) {
      var ref;
      this.kbQuery = ((ref = event.target.value) != null ? ref.trim() : void 0) || '';
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
      var ref;
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
      if ((ref = this.el.querySelector('.zammad-chat-kb-loading')) != null) {
        ref.classList.remove('zammad-chat-is-hidden');
      }
      return this.send('chat_knowledge_base_search', {
        query: this.kbQuery || '',
        offset: this.kbOffset || 0
      });
    };

    ZammadChat.prototype.onKnowledgeBaseSearchResult = function(data) {
      var emptyMessage, isFirstPage, item, j, len, ref, ref1, ref2, results, results1;
      this.kbLoading = false;
      if ((ref = this.el.querySelector('.zammad-chat-kb-loading')) != null) {
        ref.classList.add('zammad-chat-is-hidden');
      }
      if ((data.query || '') !== (this.kbQuery || '')) {
        return;
      }
      results = this.el.querySelector('.zammad-chat-kb-results');
      emptyMessage = this.el.querySelector('.zammad-chat-kb-empty');
      isFirstPage = (data.offset || 0) === 0;
      if (isFirstPage) {
        results.innerHTML = '';
      }
      this.kbHasMore = !!data.has_more;
      this.kbOffset = (data.offset || 0) + (((ref1 = data.result) != null ? ref1.length : void 0) || 0);
      if (isFirstPage && (!data.result || data.result.length === 0)) {
        if (emptyMessage != null) {
          emptyMessage.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      if (emptyMessage != null) {
        emptyMessage.classList.add('zammad-chat-is-hidden');
      }
      ref2 = data.result || [];
      results1 = [];
      for (j = 0, len = ref2.length; j < len; j++) {
        item = ref2[j];
        results1.push(results.insertAdjacentHTML('beforeend', this.view('kb_result')(item)));
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

    ZammadChat.prototype.onDrop = function(e) {
      var dataTransfer, file, reader, x, y;
      e.stopPropagation();
      e.preventDefault();
      if (window.dataTransfer) {
        dataTransfer = window.dataTransfer;
      } else if (e.dataTransfer) {
        dataTransfer = e.dataTransfer;
      } else {
        throw 'No clipboardData support';
      }
      x = e.clientX;
      y = e.clientY;
      file = dataTransfer.files[0];
      if (file.type.match('image.*')) {
        reader = new FileReader();
        reader.onload = (function(_this) {
          return function(e) {
            var insert;
            insert = function(dataUrl, width) {
              var img, pos, range, result;
              if (_this.isRetina()) {
                width = width / 2;
              }
              result = dataUrl;
              img = new Image();
              img.style.width = '100%';
              img.style.maxWidth = width + 'px';
              img.src = result;
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
            return _this.resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
          };
        })(this);
        return reader.readAsDataURL(file);
      }
    };

    ZammadChat.prototype.onPaste = function(e) {
      var clipboardData, docType, html, htmlTmp, imageFile, imageInserted, item, j, k, l, len, len1, len2, len3, m, match, newTag, node, outer, reader, ref, ref1, ref2, ref3, regex, replacementTag, sanitized, text;
      e.stopPropagation();
      e.preventDefault();
      if (e.clipboardData) {
        clipboardData = e.clipboardData;
      } else if (window.clipboardData) {
        clipboardData = window.clipboardData;
      } else if (e.clipboardData) {
        clipboardData = e.clipboardData;
      } else {
        throw 'No clipboardData support';
      }
      imageInserted = false;
      if (clipboardData && clipboardData.items && clipboardData.items[0]) {
        item = clipboardData.items[0];
        if (item.kind === 'file' && (item.type === 'image/png' || item.type === 'image/jpeg')) {
          imageFile = item.getAsFile();
          reader = new FileReader();
          reader.onload = (function(_this) {
            return function(e) {
              var insert;
              insert = function(dataUrl, width) {
                var img;
                if (_this.isRetina()) {
                  width = width / 2;
                }
                img = new Image();
                img.style.width = '100%';
                img.style.maxWidth = width + 'px';
                img.src = dataUrl;
                return document.execCommand('insertHTML', false, img);
              };
              return _this.resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert);
            };
          })(this);
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
      } catch (error1) {
        e = error1;
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
        html = document.createElement('div');
        sanitized = DOMPurify.sanitize(text);
        this.log.debug('sanitized HTML clipboard', sanitized);
        html.innerHTML = sanitized;
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
          html = this.wordFilter(html);
        }
        ref = html.childNodes;
        for (j = 0, len = ref.length; j < len; j++) {
          node = ref[j];
          if (node.nodeType === 8) {
            node.remove();
          }
        }
        ref1 = html.querySelectorAll('a, font, small, time, form, label');
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          node = ref1[k];
          node.outerHTML = node.innerHTML;
        }
        replacementTag = 'div';
        ref2 = html.querySelectorAll('textarea');
        for (l = 0, len2 = ref2.length; l < len2; l++) {
          node = ref2[l];
          outer = node.outerHTML;
          regex = new RegExp('<' + node.tagName, 'i');
          newTag = outer.replace(regex, '<' + replacementTag);
          regex = new RegExp('</' + node.tagName, 'i');
          newTag = newTag.replace(regex, '</' + replacementTag);
          node.outerHTML = newTag;
        }
        ref3 = html.querySelectorAll('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset');
        for (m = 0, len3 = ref3.length; m < len3; m++) {
          node = ref3[m];
          node.remove();
        }
        this.removeAttributes(html);
        text = html.innerHTML;
      }
      if (docType === 'text3') {
        this.pasteHtmlAtCaret(text);
      } else {
        document.execCommand('insertHTML', false, text);
      }
      return true;
    };

    ZammadChat.prototype.onKeydown = function(e) {
      var richtTextControl;
      if (!this.inputDisabled && !e.shiftKey && e.keyCode === 13) {
        e.preventDefault();
        this.sendMessage();
      }
      richtTextControl = false;
      if (!e.altKey && !e.ctrlKey && e.metaKey) {
        richtTextControl = true;
      } else if (!e.altKey && e.ctrlKey && !e.metaKey) {
        richtTextControl = true;
      }
      if (richtTextControl && this.richTextFormatKey[e.keyCode]) {
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
              ref.classList.toggle('zammad-chat-launcher--offline', this.offlineMode);
            }
            if (pipe.data.phrases) {
              this.updatePhrases(pipe.data.phrases);
            }
            if (pipe.data.category_options) {
              this.categoryOptions = pipe.data.category_options;
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
      var base, btn;
      this.log.debug('widget ready for use');
      this.hidePreload();
      btn = document.querySelector("." + this.options.buttonClass);
      if (btn) {
        btn.addEventListener('click', this.open);
        btn.classList.remove(this.options.inactiveClass);
      }
      if (typeof (base = this.options).onReady === "function") {
        base.onReady();
      }
      if (this.options.show) {
        return this.show();
      }
    };

    ZammadChat.prototype.onError = function(message) {
      var base, btn;
      this.log.debug(message);
      this.hidePreload();
      this.addStatus(message);
      btn = document.querySelector("." + this.options.buttonClass);
      if (btn) {
        btn.classList.add('zammad-chat-is-hidden');
      }
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
      var isAgentMessage, isRead, j, len, message, ref, ref1, ref2, ref3, time, unfinishedMessage;
      this.hidePreload();
      this.log.debug('old messages', data.session);
      this.inactiveTimeout.start();
      unfinishedMessage = sessionStorage.getItem('unfinished_message');
      if (data.agent) {
        this.onConnectionEstablished(data, false);
        this.showWelcomeGreeting((ref = data.session) != null ? (ref1 = ref[0]) != null ? ref1.created_at : void 0 : void 0);
        ref2 = data.session;
        for (j = 0, len = ref2.length; j < len; j++) {
          message = ref2[j];
          isAgentMessage = !!message.created_by_id;
          time = this.formatTime(message.created_at);
          isRead = !!message.read_at;
          if (message.filename) {
            this.body.insertAdjacentHTML('beforeend', this.view(this.attachmentView(message.content_type, message.display))({
              from: isAgentMessage ? 'agent' : 'customer',
              id: message.id,
              filename: message.filename,
              metaLabel: this.attachmentMeta(message.filename, message.size),
              senderLabel: this.attachmentSender(isAgentMessage),
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
              replyTo: (ref3 = message.reply_to) != null ? ref3.content : void 0
            });
          }
          if (isAgentMessage && message.id) {
            this.agentMessagesById[message.id] = message;
          }
        }
        if (unfinishedMessage) {
          this.input.innerHTML = unfinishedMessage;
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
        return this.input.focus();
      }
    };

    ZammadChat.prototype.onInput = function() {
      var j, len, message, ref;
      ref = this.el.querySelectorAll('.zammad-chat-message--unread');
      for (j = 0, len = ref.length; j < len; j++) {
        message = ref[j];
        message.classList.remove('zammad-chat-message--unread');
      }
      sessionStorage.setItem('unfinished_message', this.input.innerHTML);
      return this.onTyping();
    };

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
      message = this.input.innerHTML;
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
      if (this.el.querySelector('.zammad-chat-message--typing')) {
        this.lastAddedType = 'typing-placeholder';
        this.el.querySelector('.zammad-chat-message--typing').insertAdjacentHTML('beforebegin', messageElement);
      } else {
        this.lastAddedType = 'message--customer';
        this.body.insertAdjacentHTML('beforeend', messageElement);
      }
      this.input.innerHTML = '';
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
      return this.body.insertAdjacentHTML('beforeend', this.view('message')(data));
    };

    ZammadChat.prototype.startReply = function(event) {
      var message, messageId, target;
      if (!event.target.closest('.js-message-reply')) {
        return;
      }
      event.preventDefault();
      target = event.target.closest('.zammad-chat-message');
      if (!target) {
        return;
      }
      messageId = target.dataset.messageId;
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
      return this.input.focus();
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
      indicator = this.el.querySelector('.js-reply-indicator');
      if (!this.replyTo) {
        indicator.classList.add('zammad-chat-is-hidden');
        indicator.innerHTML = '';
        return;
      }
      snippet = this.replyTo.content.replace(/<[^>]*>/g, '').substr(0, 80);
      indicator.classList.remove('zammad-chat-is-hidden');
      indicator.innerHTML = this.view('reply_indicator')({
        snippet: snippet
      });
      return indicator.querySelector('.js-reply-cancel').addEventListener('click', this.cancelReply);
    };

    ZammadChat.prototype.triggerAttachmentInput = function(event) {
      event.preventDefault();
      return this.el.querySelector('.js-chat-attachment-input').click();
    };

    ZammadChat.prototype.uploadAttachment = function(event) {
      var asFile, file, formData, ref, ref1, uploadId, xhr;
      file = (ref = event.target.files) != null ? ref[0] : void 0;
      if (!file) {
        return;
      }
      formData = new FormData();
      formData.append('File', file);
      asFile = event.target.classList.contains('js-chat-attachment-input');
      if (asFile) {
        formData.append('display', 'file');
      }
      uploadId = !asFile && (ref1 = file.type, indexOf.call(this.IMAGE_TYPES, ref1) >= 0) ? this.addImageUpload(file) : this.addFileUpload(file);
      xhr = new XMLHttpRequest();
      xhr.open('POST', (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments");
      if (uploadId) {
        xhr.upload.onprogress = (function(_this) {
          return function(progress) {
            if (!progress.lengthComputable) {
              return;
            }
            return _this.updateImageUpload(uploadId, Math.round(progress.loaded / progress.total * 100));
          };
        })(this);
      }
      xhr.onload = (function(_this) {
        return function() {
          var message, parsed;
          if (xhr.status >= 200 && xhr.status < 300) {
            return;
          }
          if (uploadId) {
            _this.removeImageUpload(uploadId);
          }
          message = _this.T(_this.phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.');
          try {
            parsed = JSON.parse(xhr.responseText);
            if (parsed.error) {
              message = parsed.error;
            }
          } catch (error1) {}
          return _this.addStatus(message);
        };
      })(this);
      xhr.onerror = (function(_this) {
        return function() {
          if (uploadId) {
            _this.removeImageUpload(uploadId);
          }
          return _this.addStatus(_this.T(_this.phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.'));
        };
      })(this);
      xhr.send(formData);
      return event.target.value = '';
    };

    ZammadChat.prototype.addAttachmentMessage = function(data, from) {
      var html, placeholder, placeholderSelector, viewName;
      viewName = this.attachmentView(data.content_type, data.display);
      html = this.view(viewName)({
        from: from,
        id: data.id,
        filename: data.filename,
        metaLabel: this.attachmentMeta(data.filename, data.size),
        senderLabel: this.attachmentSender(from === 'agent'),
        url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments/" + data.id,
        unreadClass: document.hidden ? ' zammad-chat-message--unread' : '',
        time: this.formatTime(data.created_at)
      });
      if (from === 'agent' && data.id) {
        this.agentMessagesById[data.id] = data;
      }
      placeholderSelector = viewName === 'image_message' ? '.js-image-upload' : '.js-file-upload';
      placeholder = from === 'customer' ? this.body.querySelector(placeholderSelector) : null;
      if (placeholder) {
        this.releaseImageUpload(placeholder.dataset.uploadId);
        placeholder.insertAdjacentHTML('beforebegin', html);
        placeholder.remove();
        this.lastAddedType = "message--" + from;
        this.scrollToBottom({
          showHint: true
        });
        return;
      }
      this.maybeAddTimestamp();
      this.lastAddedType = "message--" + from;
      this.body.insertAdjacentHTML('beforeend', html);
      return this.scrollToBottom({
        showHint: true
      });
    };

    ZammadChat.prototype.IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

    ZammadChat.prototype.attachmentView = function(contentType, display) {
      if (display === 'file') {
        return 'attachment_message';
      }
      if (indexOf.call(this.IMAGE_TYPES, contentType) >= 0) {
        return 'image_message';
      } else {
        return 'attachment_message';
      }
    };

    ZammadChat.prototype.attachmentSender = function(isAgent) {
      var ref;
      if (isAgent) {
        return ((ref = this.agent) != null ? ref.name : void 0) || this.T('Agent');
      } else {
        return this.T('You');
      }
    };

    ZammadChat.prototype.addImageUpload = function(file) {
      var uploadId;
      this.imageUploadSeq = (this.imageUploadSeq || 0) + 1;
      uploadId = String(this.imageUploadSeq);
      this.imageUploadUrls || (this.imageUploadUrls = {});
      this.imageUploadUrls[uploadId] = URL.createObjectURL(file);
      this.maybeAddTimestamp();
      this.lastAddedType = 'message--customer';
      this.body.insertAdjacentHTML('beforeend', this.view('image_upload')({
        uploadId: uploadId,
        previewUrl: this.imageUploadUrls[uploadId]
      }));
      this.scrollToBottom({
        showHint: true
      });
      return uploadId;
    };

    ZammadChat.prototype.addFileUpload = function(file) {
      var uploadId;
      this.imageUploadSeq = (this.imageUploadSeq || 0) + 1;
      uploadId = String(this.imageUploadSeq);
      this.maybeAddTimestamp();
      this.lastAddedType = 'message--customer';
      this.body.insertAdjacentHTML('beforeend', this.view('file_upload')({
        uploadId: uploadId,
        filename: file.name
      }));
      this.scrollToBottom({
        showHint: true
      });
      return uploadId;
    };

    ZammadChat.prototype.updateImageUpload = function(uploadId, percent) {
      var bar, el, label, text;
      el = this.body.querySelector("[data-upload-id='" + uploadId + "']");
      if (!el) {
        return;
      }
      label = percent >= 100 ? this.T('Processing…') : (this.T('Uploading…')) + " " + percent + "%";
      text = el.querySelector('.js-image-progress, .js-upload-progress-text');
      if (text) {
        text.textContent = label;
      }
      bar = el.querySelector('.js-upload-progress-bar');
      if (bar) {
        bar.style.width = percent + "%";
        return bar.setAttribute('aria-valuenow', percent);
      }
    };

    ZammadChat.prototype.releaseImageUpload = function(uploadId) {
      var ref;
      if (!((ref = this.imageUploadUrls) != null ? ref[uploadId] : void 0)) {
        return;
      }
      URL.revokeObjectURL(this.imageUploadUrls[uploadId]);
      return delete this.imageUploadUrls[uploadId];
    };

    ZammadChat.prototype.removeImageUpload = function(uploadId) {
      var ref;
      if ((ref = this.body.querySelector("[data-upload-id='" + uploadId + "']")) != null) {
        ref.remove();
      }
      return this.releaseImageUpload(uploadId);
    };

    ZammadChat.prototype.openImageViewer = function(trigger) {
      var data, viewer, wrapper;
      this.closeImageViewer();
      data = trigger.dataset;
      wrapper = document.createElement('div');
      wrapper.innerHTML = this.view('image_viewer')({
        url: data.url,
        filename: data.filename,
        meta: data.meta,
        sender: data.sender,
        time: data.time
      });
      viewer = wrapper.firstElementChild;
      if (!(viewer != null ? viewer.classList.contains('js-image-viewer') : void 0)) {
        viewer = wrapper.querySelector('.js-image-viewer');
      }
      this.imageViewer = {
        el: viewer,
        trigger: trigger,
        overflow: document.documentElement.style.overflow
      };
      document.documentElement.style.overflow = 'hidden';
      document.body.appendChild(viewer);
      viewer.querySelector('.js-image-viewer-close').addEventListener('click', this.closeImageViewer);
      viewer.addEventListener('click', (function(_this) {
        return function(event) {
          if (event.target === viewer || event.target.classList.contains('js-image-viewer-stage')) {
            return _this.closeImageViewer();
          }
        };
      })(this));
      viewer.addEventListener('keydown', this.onImageViewerKeydown);
      return viewer.querySelector('.js-image-viewer-close').focus();
    };

    ZammadChat.prototype.onImageViewerKeydown = function(event) {
      var first, focusable, last, ref;
      if (event.key === 'Escape') {
        event.preventDefault();
        this.closeImageViewer();
        return;
      }
      if (event.key !== 'Tab') {
        return;
      }
      focusable = (ref = this.imageViewer) != null ? ref.el.querySelectorAll('a[href], button') : void 0;
      if (!(focusable != null ? focusable.length : void 0)) {
        return;
      }
      first = focusable[0];
      last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        return last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        return first.focus();
      }
    };

    ZammadChat.prototype.closeImageViewer = function() {
      var el, overflow, ref, trigger;
      if (!this.imageViewer) {
        return;
      }
      ref = this.imageViewer, el = ref.el, trigger = ref.trigger, overflow = ref.overflow;
      this.imageViewer = null;
      el.remove();
      document.documentElement.style.overflow = overflow;
      if (document.contains(trigger)) {
        return trigger != null ? trigger.focus() : void 0;
      }
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
      this.launcherEl.classList.add('zammad-chat-is-open');
      this.launcherEl.setAttribute('aria-expanded', 'true');
      this.el.addEventListener('transitionend', this.onOpenAnimationEnd);
      return this.el.classList.add('zammad-chat-is-open');
    };

    ZammadChat.prototype.showPrechatForm = function(params) {
      var j, len, menu, opt, ref, selectedValue, toggleBtn;
      if (params == null) {
        params = {};
      }
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('prechat')({
        error: params.error,
        notice: params.notice,
        name: params.name,
        email: params.email,
        category: params.category
      });
      this.el.querySelector('.zammad-chat-prechat-form').addEventListener('submit', this.submitPrechatForm);
      if (this.logoUrl) {
        this.updateHomeLogo(this.logoUrl);
      }
      menu = this.el.querySelector('.js-prechat-category-menu');
      selectedValue = params.category;
      ref = this.categoryOptions || [];
      for (j = 0, len = ref.length; j < len; j++) {
        opt = ref[j];
        menu.insertAdjacentHTML('beforeend', this.view('prechat_category_option')({
          value: opt.value,
          label: opt.label,
          selected: opt.value === selectedValue
        }));
      }
      toggleBtn = this.el.querySelector('.js-prechat-category-toggle');
      toggleBtn.addEventListener('click', (function(_this) {
        return function(event) {
          var isOpen;
          event.preventDefault();
          isOpen = !menu.classList.contains('zammad-chat-is-hidden');
          menu.classList.toggle('zammad-chat-is-hidden', isOpen);
          toggleBtn.classList.toggle('is-open', !isOpen);
          return toggleBtn.setAttribute('aria-expanded', (!isOpen).toString());
        };
      })(this));
      return menu.addEventListener('click', (function(_this) {
        return function(event) {
          var k, label, len1, option, other, ref1, value, valueEl;
          option = event.target.closest('.js-prechat-category-option');
          if (!option) {
            return;
          }
          value = option.dataset.value;
          label = option.querySelector('span').textContent;
          _this.el.querySelector('.js-prechat-category-input').value = value;
          valueEl = _this.el.querySelector('.js-prechat-category-value');
          valueEl.textContent = label;
          valueEl.classList.remove('is-placeholder');
          ref1 = menu.querySelectorAll('.js-prechat-category-option');
          for (k = 0, len1 = ref1.length; k < len1; k++) {
            other = ref1[k];
            other.classList.toggle('is-selected', other === option);
          }
          menu.classList.add('zammad-chat-is-hidden');
          toggleBtn.classList.remove('is-open');
          return toggleBtn.setAttribute('aria-expanded', 'false');
        };
      })(this));
    };

    ZammadChat.prototype.setButtonLoading = function(button, loading) {
      var label, loader;
      if (!button) {
        return;
      }
      if (loading) {
        if (!button.querySelector('.zammad-chat-btn-label')) {
          label = document.createElement('span');
          label.className = 'zammad-chat-btn-label';
          while (button.firstChild) {
            label.appendChild(button.firstChild);
          }
          button.appendChild(label);
          loader = document.createElement('span');
          loader.className = 'zammad-chat-btn-loader';
          loader.setAttribute('aria-hidden', 'true');
          loader.innerHTML = '<svg viewBox="0 0 50 50"><circle cx="25" cy="25" r="20"></circle></svg>';
          button.appendChild(loader);
        }
        button.classList.add('is-loading');
        return button.disabled = true;
      } else {
        button.classList.remove('is-loading');
        return button.disabled = false;
      }
    };

    ZammadChat.prototype.submitPrechatForm = function(event) {
      var category, email, emailFormat, name, ref, ref1, ref2, ref3, ref4, ref5;
      event.preventDefault();
      name = (ref = this.el.querySelector('.zammad-chat-prechat-name')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      email = (ref2 = this.el.querySelector('.zammad-chat-prechat-email')) != null ? (ref3 = ref2.value) != null ? ref3.trim() : void 0 : void 0;
      category = (ref4 = this.el.querySelector('.js-prechat-category-input')) != null ? (ref5 = ref4.value) != null ? ref5.trim() : void 0 : void 0;
      emailFormat = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
      if (!name || !email || !emailFormat.test(email) || !category) {
        this.showPrechatForm({
          error: this.T(this.phrases['chat_phrase_prechat_validation_error'] || 'Please provide a valid name, email, and category.'),
          name: name,
          email: email,
          category: category
        });
        return;
      }
      this.customerName = name;
      sessionStorage.setItem('customerName', name);
      this.customerEmail = email;
      this.setButtonLoading(this.el.querySelector('.zammad-chat-prechat-submit'), true);
      if (this.offlineMode) {
        return this.send('chat_offline_session_init', {
          url: window.location.href,
          name: name,
          email: email,
          category: category
        });
      } else {
        this.showLoader();
        return this.send('chat_session_init', {
          url: window.location.href,
          name: name,
          email: email,
          category: category
        });
      }
    };

    ZammadChat.prototype.enterOfflineMode = function() {
      this.hidePreload();
      this.applyOfflineHomeState();
      return this.show();
    };

    ZammadChat.prototype.applyOfflineHomeState = function() {
      var dot, notice, startAction, status, subtext;
      if (!this.offlineMode) {
        return;
      }
      if (!this.el) {
        return;
      }
      subtext = this.el.querySelector('.zammad-chat-welcome-subtext');
      if (subtext) {
        status = document.createElement('span');
        status.className = 'zammad-chat-welcome-offline-status';
        dot = document.createElement('span');
        dot.className = 'zammad-chat-welcome-offline-dot';
        status.appendChild(dot);
        status.appendChild(document.createTextNode(this.T(this.phrases['chat_phrase_offline_status'] || "We're offline right now")));
        subtext.innerHTML = '';
        subtext.appendChild(status);
      }
      notice = this.el.querySelector('.zammad-chat-home-offline-notice');
      if (notice != null) {
        notice.classList.remove('zammad-chat-is-hidden');
      }
      startAction = this.el.querySelector('.js-home-start-action');
      if (startAction) {
        return startAction.querySelector('.js-home-start-label').textContent = this.T(this.phrases['chat_phrase_offline_start_button'] || 'Leave us a message');
      }
    };

    ZammadChat.prototype.applyOnlineHomeState = function() {
      var notice;
      if (this.offlineMode) {
        return;
      }
      if (!this.el) {
        return;
      }
      notice = this.el.querySelector('.zammad-chat-home-online-notice');
      return notice != null ? notice.classList.remove('zammad-chat-is-hidden') : void 0;
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
      var ref;
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('offline_otp')({
        email: this.customerEmail
      });
      return (ref = this.el.querySelector('.js-otp-digit')) != null ? ref.focus() : void 0;
    };

    ZammadChat.prototype.onOtpDigitInput = function(event) {
      var input, next, nextIndex, value;
      input = event.target;
      value = input.value.replace(/[^0-9]/g, '');
      input.value = value.slice(-1);
      if (value) {
        nextIndex = parseInt(input.dataset.index, 10) + 1;
        next = input.closest('.zammad-chat-offline-otp-boxes').querySelector(".js-otp-digit[data-index='" + nextIndex + "']");
        if (next != null) {
          next.focus();
        }
        return this.autoSubmitOfflineOtp();
      }
    };

    ZammadChat.prototype.onOtpDigitKeydown = function(event) {
      var input, prev, prevIndex;
      if (event.keyCode !== 8) {
        return;
      }
      input = event.target;
      if (input.value) {
        return;
      }
      prevIndex = parseInt(input.dataset.index, 10) - 1;
      if (prevIndex < 0) {
        return;
      }
      prev = input.closest('.zammad-chat-offline-otp-boxes').querySelector(".js-otp-digit[data-index='" + prevIndex + "']");
      if (prev) {
        prev.value = '';
        return prev.focus();
      }
    };

    ZammadChat.prototype.onOtpDigitPaste = function(event) {
      var boxes, lastFilled, pasted, ref, ref1, ref2;
      event.preventDefault();
      pasted = ((ref = event.clipboardData) != null ? (ref1 = ref.getData('text')) != null ? ref1.replace(/[^0-9]/g, '') : void 0 : void 0) || '';
      if (!pasted) {
        return;
      }
      boxes = event.target.closest('.zammad-chat-offline-otp-boxes').querySelectorAll('.js-otp-digit');
      boxes.forEach(function(el, i) {
        return el.value = pasted.charAt(i) || '';
      });
      lastFilled = Math.min(pasted.length, boxes.length) - 1;
      if ((ref2 = boxes[Math.max(lastFilled, 0)]) != null) {
        ref2.focus();
      }
      return this.autoSubmitOfflineOtp();
    };

    ZammadChat.prototype.autoSubmitOfflineOtp = function() {
      var boxes, el, j, len, ref;
      boxes = this.el.querySelectorAll('.js-otp-digit');
      if (!boxes.length) {
        return;
      }
      for (j = 0, len = boxes.length; j < len; j++) {
        el = boxes[j];
        if (!el.value) {
          return;
        }
      }
      if ((ref = this.el.querySelector('.js-otp-submit')) != null ? ref.disabled : void 0) {
        return;
      }
      return this.submitOfflineOtp();
    };

    ZammadChat.prototype.submitOfflineOtp = function(event) {
      var code;
      if (event != null) {
        event.preventDefault();
      }
      code = '';
      this.el.querySelectorAll('.js-otp-digit').forEach(function(el) {
        return code += el.value || '';
      });
      if (code.length !== 6) {
        this.showOtpError(this.T(this.phrases['chat_phrase_otp_incomplete_error'] || 'Please enter the full 6-digit code.'));
        return;
      }
      this.setButtonLoading(this.el.querySelector('.js-otp-submit'), true);
      return this.send('chat_offline_otp_verify', {
        session_id: this.sessionId,
        code: code
      });
    };

    ZammadChat.prototype.showOtpError = function(message) {
      var error, textEl;
      error = this.el.querySelector('.js-otp-error');
      if (!error) {
        return;
      }
      error.classList.remove('zammad-chat-is-hidden');
      textEl = error.querySelector('.js-otp-error-text');
      if (textEl) {
        return textEl.textContent = message;
      }
    };

    ZammadChat.prototype.onOfflineOtpVerifyResult = function(data) {
      var ref;
      if (data.state === 'ok') {
        this.showOfflineCompose();
        return;
      }
      this.setButtonLoading(this.el.querySelector('.js-otp-submit'), false);
      this.showOtpError(data.message);
      this.el.querySelectorAll('.js-otp-digit').forEach(function(el) {
        return el.value = '';
      });
      return (ref = this.el.querySelector('.js-otp-digit')) != null ? ref.focus() : void 0;
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
      var ref;
      if (data.state === 'ok') {
        this.el.querySelectorAll('.js-otp-digit').forEach(function(el) {
          return el.value = '';
        });
        if ((ref = this.el.querySelector('.js-otp-digit')) != null) {
          ref.focus();
        }
        this.showOtpError(this.T(this.phrases['chat_phrase_otp_resend_success'] || 'A new code has been sent.'));
        return;
      }
      return this.showOtpError(data.message || this.T(this.phrases['chat_phrase_otp_resend_error_fallback'] || 'Could not resend code. Please try again.'));
    };

    ZammadChat.prototype.showOfflineCompose = function() {
      return this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('offline_compose')({
        email: this.customerEmail
      });
    };

    ZammadChat.prototype.submitOfflineMessage = function(event) {
      var content, errorEl, ref, ref1, ref2, ref3, subject;
      if (event != null) {
        event.preventDefault();
      }
      subject = (ref = this.el.querySelector('.js-offline-subject')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      content = (ref2 = this.el.querySelector('.js-offline-message')) != null ? (ref3 = ref2.value) != null ? ref3.trim() : void 0 : void 0;
      errorEl = this.el.querySelector('.js-offline-compose-error');
      if (!subject) {
        if (errorEl) {
          errorEl.textContent = this.T(this.phrases['chat_phrase_offline_compose_subject_empty_error'] || 'Please enter a subject.');
          errorEl.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      if (!content) {
        if (errorEl) {
          errorEl.textContent = this.T(this.phrases['chat_phrase_offline_compose_empty_error'] || 'Please write a message.');
          errorEl.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      if (errorEl != null) {
        errorEl.classList.add('zammad-chat-is-hidden');
      }
      this.setButtonLoading(this.el.querySelector('.js-offline-compose-submit'), true);
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
      return this.el.querySelector('.js-offline-compose-attachment-input').click();
    };

    ZammadChat.prototype.uploadOfflineAttachment = function(event) {
      var attachBtn, file, formData, ref, xhr;
      file = (ref = event.target.files) != null ? ref[0] : void 0;
      if (!file) {
        return;
      }
      formData = new FormData();
      formData.append('File', file);
      attachBtn = this.el.querySelector('.js-offline-compose-attach');
      if (attachBtn != null) {
        attachBtn.setAttribute('disabled', 'disabled');
      }
      xhr = new XMLHttpRequest();
      xhr.open('POST', (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments");
      xhr.onload = (function(_this) {
        return function() {
          var chip, data, errorEl, filenameEl, message, parsed, ref1;
          if (attachBtn != null) {
            attachBtn.removeAttribute('disabled');
          }
          if (xhr.status >= 200 && xhr.status < 300) {
            data = JSON.parse(xhr.responseText);
            chip = document.createElement('div');
            chip.className = 'zammad-chat-offline-compose-attachment-chip';
            chip.innerHTML = siskaIcon('paperclip', 16);
            filenameEl = document.createElement('span');
            filenameEl.textContent = data.filename;
            chip.appendChild(filenameEl);
            if ((ref1 = _this.el.querySelector('.js-offline-compose-attachments')) != null) {
              ref1.appendChild(chip);
            }
            return;
          }
          message = _this.T(_this.phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.');
          try {
            parsed = JSON.parse(xhr.responseText);
            if (parsed.error) {
              message = parsed.error;
            }
          } catch (error1) {}
          errorEl = _this.el.querySelector('.js-offline-compose-error');
          if (errorEl) {
            errorEl.textContent = message;
            return errorEl.classList.remove('zammad-chat-is-hidden');
          }
        };
      })(this);
      xhr.send(formData);
      return event.target.value = '';
    };

    ZammadChat.prototype.onOfflineMessageSendResult = function(data) {
      var errorEl;
      this.setButtonLoading(this.el.querySelector('.js-offline-compose-submit'), false);
      if (data.state !== 'ok') {
        errorEl = this.el.querySelector('.js-offline-compose-error');
        if (errorEl) {
          errorEl.textContent = data.message;
          errorEl.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      this.lastSessionId = this.sessionId;
      this.setSessionId(void 0);
      return this.showOfflineSent();
    };

    ZammadChat.prototype.showOfflineSent = function() {
      return this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('offline_sent')({
        email: this.customerEmail
      });
    };

    ZammadChat.prototype.finishOfflineFlow = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.setButtonLoading(this.el.querySelector('.js-offline-sent-done'), true);
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
        this.body.insertAdjacentHTML('beforeend', "<div class=\"zammad-chat-feedback-inline js-feedback-inline\">" + markup + "</div>");
        this.scrollToBottom();
      } else {
        this.el.querySelector('.zammad-chat-modal').innerHTML = markup;
      }
      this.agent = void 0;
      return this.updateHeader();
    };

    ZammadChat.prototype.selectFeedbackScore = function(event, score) {
      if (event != null) {
        event.preventDefault();
      }
      this.feedbackScore = parseInt(score, 10);
      return this.el.querySelectorAll('.js-feedback-star').forEach((function(_this) {
        return function(el) {
          var starScore;
          starScore = parseInt(el.dataset.score, 10);
          return el.classList.toggle('is-active', starScore <= _this.feedbackScore);
        };
      })(this));
    };

    ZammadChat.prototype.submitFeedback = function(event) {
      var comment, errorEl, ref, ref1;
      if (event != null) {
        event.preventDefault();
      }
      errorEl = this.el.querySelector('.js-feedback-error');
      if (!this.feedbackScore) {
        if (errorEl) {
          errorEl.textContent = this.T(this.phrases['chat_phrase_feedback_score_error'] || 'Please select a rating.');
          errorEl.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      if (errorEl != null) {
        errorEl.classList.add('zammad-chat-is-hidden');
      }
      this.setButtonLoading(this.el.querySelector('.js-feedback-submit'), true);
      comment = (ref = this.el.querySelector('.js-feedback-comment')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      return this.send('chat_session_feedback_submit', {
        session_id: this.lastSessionId,
        score: this.feedbackScore,
        comment: comment
      });
    };

    ZammadChat.prototype.onFeedbackSubmitResult = function(data) {
      var errorEl;
      this.setButtonLoading(this.el.querySelector('.js-feedback-submit'), false);
      if (data.state !== 'ok') {
        errorEl = this.el.querySelector('.js-feedback-error');
        if (errorEl) {
          errorEl.textContent = data.message || this.T(this.phrases['chat_phrase_feedback_submit_error_fallback'] || 'Could not save your feedback. Please try again.');
          errorEl.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      return this.showFeedbackThanks();
    };

    ZammadChat.prototype.skipFeedback = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.setButtonLoading(this.el.querySelector('.js-feedback-skip'), true);
      return this.goToStartChat();
    };

    ZammadChat.prototype.showFeedbackThanks = function() {
      var markup, overlay;
      markup = this.view('feedback_thanks')();
      if (this.feedbackInline) {
        overlay = this.el.querySelector('.js-feedback-thanks-overlay');
        if (overlay) {
          overlay.innerHTML = markup;
          overlay.classList.remove('zammad-chat-is-hidden');
        }
      } else {
        this.el.querySelector('.zammad-chat-modal').innerHTML = markup;
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
      overlay = this.el.querySelector('.js-feedback-thanks-overlay');
      if (!overlay) {
        return;
      }
      overlay.classList.add('zammad-chat-is-hidden');
      return overlay.innerHTML = '';
    };

    ZammadChat.prototype.onOpenAnimationEnd = function() {
      var base;
      this.el.removeEventListener('transitionend', this.onOpenAnimationEnd);
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
      this.launcherEl.classList.remove('zammad-chat-is-open');
      this.launcherEl.setAttribute('aria-expanded', 'false');
      this.el.addEventListener('transitionend', this.onCloseAnimationEnd);
      return this.el.classList.remove('zammad-chat-is-open');
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
        this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('ending_chat')();
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
      this.el.removeEventListener('transitionend', this.onCloseAnimationEnd);
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
        this.launcherEl.classList.remove('zammad-chat-is-shown');
        return this.launcherEl.classList.remove('zammad-chat-is-loaded');
      }
    };

    ZammadChat.prototype.show = function() {
      if (this.state === 'offline') {
        return;
      }
      this.launcherEl.classList.add('zammad-chat-is-loaded');
      return this.launcherEl.classList.add('zammad-chat-is-shown');
    };

    ZammadChat.prototype.disableInput = function() {
      this.inputDisabled = true;
      this.input.setAttribute('contenteditable', false);
      this.el.querySelector('.zammad-chat-send').disabled = true;
      return this.io.close();
    };

    ZammadChat.prototype.disableComposeInput = function() {
      var ref, sendBtn;
      this.inputDisabled = true;
      if ((ref = this.input) != null) {
        ref.setAttribute('contenteditable', false);
      }
      sendBtn = this.el.querySelector('.zammad-chat-send');
      if (sendBtn) {
        return sendBtn.disabled = true;
      }
    };

    ZammadChat.prototype.enableInput = function() {
      this.inputDisabled = false;
      this.input.setAttribute('contenteditable', true);
      return this.el.querySelector('.zammad-chat-send').disabled = false;
    };

    ZammadChat.prototype.hideModal = function() {
      return this.el.querySelector('.zammad-chat-modal').innerHTML = '';
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
      return this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('waiting')({
        position: data.position
      });
    };

    ZammadChat.prototype.onAgentTypingStart = function() {
      if (this.stopTypingId) {
        clearTimeout(this.stopTypingId);
      }
      this.stopTypingId = setTimeout(this.onAgentTypingEnd, 3000);
      if (this.el.querySelector('.zammad-chat-message--typing')) {
        return;
      }
      this.maybeAddTimestamp();
      this.body.insertAdjacentHTML('beforeend', this.view('typingIndicator')());
      if (!this.isVisible(this.el.querySelector('.zammad-chat-message--typing'), true)) {
        return;
      }
      return this.scrollToBottom();
    };

    ZammadChat.prototype.onAgentTypingEnd = function() {
      if (this.el.querySelector('.zammad-chat-message--typing')) {
        return this.el.querySelector('.zammad-chat-message--typing').remove();
      }
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
          this.body.insertAdjacentHTML('beforeend', this.view('timestamp')({
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
      var timestamps;
      if (!this.el) {
        return;
      }
      timestamps = this.el.querySelectorAll('.zammad-chat-body .zammad-chat-timestamp');
      if (!timestamps) {
        return;
      }
      return timestamps[timestamps.length - 1].outerHTML = this.view('timestamp')({
        label: label,
        time: time
      });
    };

    ZammadChat.prototype.addStatus = function(status) {
      if (!this.el) {
        return;
      }
      this.maybeAddTimestamp();
      this.body.insertAdjacentHTML('beforeend', this.view('status')({
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
      overlay = this.el.querySelector('.js-connection-overlay');
      if (!overlay) {
        return;
      }
      if (this.connectionOverlayHideTimeoutId) {
        clearTimeout(this.connectionOverlayHideTimeoutId);
        this.connectionOverlayHideTimeoutId = void 0;
      }
      copy = this.connectionOverlayCopy(state);
      overlay.innerHTML = this.view('connection_overlay')({
        state: state,
        title: copy.title,
        subtitle: copy.subtitle
      });
      ref = ['reconnecting', 'restored', 'lost'];
      for (j = 0, len = ref.length; j < len; j++) {
        otherState = ref[j];
        overlay.classList.remove("zammad-chat-connection-overlay--" + otherState);
      }
      overlay.classList.add("zammad-chat-connection-overlay--" + state);
      overlay.classList.remove('zammad-chat-is-hidden');
      if (state === 'restored') {
        return this.connectionOverlayHideTimeoutId = setTimeout(this.hideConnectionOverlay, 1800);
      }
    };

    ZammadChat.prototype.hideConnectionOverlay = function() {
      var overlay;
      if (!this.el) {
        return;
      }
      overlay = this.el.querySelector('.js-connection-overlay');
      if (!overlay) {
        return;
      }
      overlay.classList.add('zammad-chat-is-hidden');
      return overlay.innerHTML = '';
    };

    ZammadChat.prototype.updateLauncherConnectionState = function(hasIssue) {
      var ref;
      return (ref = this.launcherEl) != null ? ref.classList.toggle('zammad-chat-launcher--connection-issue', hasIssue) : void 0;
    };

    ZammadChat.prototype.detectScrolledtoBottom = function() {
      var scrollBottom;
      scrollBottom = this.body.scrollTop + this.body.offsetHeight;
      this.scrolledToBottom = Math.abs(scrollBottom - this.body.scrollHeight) <= this.scrollSnapTolerance;
      if (this.scrolledToBottom) {
        return this.el.querySelector('.zammad-scroll-hint').classList.add('is-hidden');
      }
    };

    ZammadChat.prototype.showScrollHint = function() {
      this.el.querySelector('.zammad-scroll-hint').classList.remove('is-hidden');
      return this.body.scrollTop = this.body.scrollTop + this.el.querySelector('.zammad-scroll-hint').offsetHeight;
    };

    ZammadChat.prototype.onScrollHintClick = function() {
      return this.body.scrollTo({
        top: this.body.scrollHeight,
        behavior: 'smooth'
      });
    };

    ZammadChat.prototype.scrollToBottom = function(arg) {
      var showHint;
      showHint = (arg != null ? arg : {
        showHint: false
      }).showHint;
      if (this.scrolledToBottom) {
        return this.body.scrollTop = this.body.scrollHeight;
      } else if (showHint) {
        return this.showScrollHint();
      }
    };

    ZammadChat.prototype.destroy = function(params) {
      var btn, ref;
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
        btn = document.querySelector("." + this.options.buttonClass);
        if (btn) {
          btn.classList.add(this.options.inactiveClass);
          btn.style.display = 'none';
        }
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
      var ref, sendBtn;
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
          ref.setAttribute('contenteditable', false);
        }
        sendBtn = this.el.querySelector('.zammad-chat-send');
        if (sendBtn) {
          return sendBtn.disabled = true;
        }
      }
    };

    ZammadChat.prototype.onIoReconnected = function() {
      var base, ref, sendBtn;
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
          ref.setAttribute('contenteditable', true);
        }
        sendBtn = this.el.querySelector('.zammad-chat-send');
        if (sendBtn) {
          return sendBtn.disabled = false;
        }
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
      var j, len, results1, statusEl, statusEls;
      statusEls = this.el.querySelectorAll('.zammad-chat-message--customer .zammad-chat-message-status--sent');
      if (!statusEls.length) {
        return;
      }
      results1 = [];
      for (j = 0, len = statusEls.length; j < len; j++) {
        statusEl = statusEls[j];
        statusEl.classList.remove('zammad-chat-message-status--sent');
        statusEl.classList.add('zammad-chat-message-status--read');
        results1.push(statusEl.setAttribute('aria-label', this.T('Read')));
      }
      return results1;
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
      var base, j, len, ref, ref1, ref2, selector;
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
      this.body.innerHTML = '';
      this.el.querySelector('.zammad-chat-agent').innerHTML = this.view('agent')({
        agent: this.agent,
        initials: this.initialsOf((ref = this.agent) != null ? ref.name : void 0)
      });
      if (showGreeting) {
        this.showWelcomeGreeting();
      }
      ref1 = ['.js-chat-attach', '.js-chat-attach-image'];
      for (j = 0, len = ref1.length; j < len; j++) {
        selector = ref1[j];
        if ((ref2 = this.el.querySelector(selector)) != null) {
          ref2.classList.toggle('zammad-chat-is-hidden', !data.attachment_enabled);
        }
      }
      this.enableInput();
      this.hideModal();
      this.updateHeader();
      if (!this.isFullscreen) {
        this.input.focus();
      }
      this.setAgentOnlineState('online');
      this.waitingListTimeout.stop();
      this.idleTimeout.stop();
      this.inactiveTimeout.start();
      return typeof (base = this.options).onConnectionEstablished === "function" ? base.onConnectionEstablished(data) : void 0;
    };

    ZammadChat.prototype.showWelcomeGreeting = function(createdAt) {
      var greeting;
      greeting = this.phrases['chat_phrase_messages_welcome_greeting'];
      if (!greeting) {
        return;
      }
      this.maybeAddTimestamp();
      return this.renderMessage({
        message: greeting,
        from: 'agent',
        time: this.formatTime(createdAt)
      });
    };

    ZammadChat.prototype.showCustomerTimeout = function() {
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('customer_timeout')({
        agent: this.agent.name,
        delay: this.options.inactiveTimeout
      });
      this.el.querySelector('.js-restart').addEventListener('click', function() {
        return location.reload();
      });
      return this.sessionClose();
    };

    ZammadChat.prototype.showWaitingListTimeout = function() {
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('waiting_list_timeout')({
        delay: this.options.watingListTimeout
      });
      this.el.querySelector('.js-restart').addEventListener('click', function() {
        return location.reload();
      });
      return this.sessionClose();
    };

    ZammadChat.prototype.showLoader = function() {
      return this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('loader')();
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
      marks = this.el.querySelectorAll('.zammad-chat-home-logo-mark, .zammad-chat-prechat-icon');
      return marks.forEach(function(mark) {
        var img;
        mark.style.background = 'none';
        img = document.createElement('img');
        img.src = url;
        img.alt = '';
        img.style.width = '100%';
        img.style.height = '100%';
        img.style.objectFit = 'contain';
        mark.innerHTML = '';
        return mark.appendChild(img);
      });
    };

    ZammadChat.prototype.updatePhrases = function(phrases) {
      var input, welcomeSubtext, welcomeTitle;
      this.phrases = phrases;
      if (!this.el) {
        return;
      }
      this.el.querySelector('.zammad-chat-tab-body--home').innerHTML = this.view('home')();
      this.el.querySelector('.zammad-chat-tab-body--help').innerHTML = this.view('help')();
      if (this.activeTab === 'help') {
        this.loadKnowledgeBase(true);
      } else {
        this.kbLoaded = false;
      }
      welcomeTitle = this.el.querySelector('.zammad-chat-welcome-title');
      if (welcomeTitle) {
        welcomeTitle.innerHTML = this.T(this.phrases['chat_phrase_home_greeting'] || 'Hi there') + ' 👋';
      }
      welcomeSubtext = this.el.querySelector('.zammad-chat-welcome-subtext');
      if (welcomeSubtext) {
        welcomeSubtext.textContent = this.T(this.phrases['chat_phrase_home_subtitle'] || 'How can we help you today?');
      }
      input = this.el.querySelector('.zammad-chat-input');
      if (input) {
        input.setAttribute('placeholder', this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
      }
      this.applyOfflineHomeState();
      this.applyOnlineHomeState();
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
      var capitalizedState, statusEl;
      this.state = state;
      if (!this.el) {
        return;
      }
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1);
      statusEl = this.el.querySelector('.zammad-chat-agent-status');
      if (!statusEl) {
        return;
      }
      statusEl.dataset.status = state;
      return statusEl.textContent = this.T(capitalizedState);
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
        ref.style.display = '';
      }
      if ((ref1 = this.launcherEl) != null) {
        ref1.style.display = '';
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
      this.rootScrollOffset = this.scrollRoot.scrollTop;
      this.scrollRoot.style.overflow = 'hidden';
      return this.scrollRoot.style.position = 'fixed';
    };

    ZammadChat.prototype.enableScrollOnRoot = function() {
      this.scrollRoot.scrollTop = this.rootScrollOffset;
      this.scrollRoot.style.overflow = '';
      return this.scrollRoot.style.position = '';
    };

    ZammadChat.prototype.isVisible = function(el, partial, hidden, direction) {
      var bViz, clientSize, hVisible, lViz, rViz, rec, tViz, vVisible, vpHeight, vpWidth;
      if (el.length < 1) {
        return;
      }
      vpWidth = window.innerWidth;
      vpHeight = window.innerHeight;
      direction = direction ? direction : 'both';
      clientSize = hidden === true ? t.offsetWidth * t.offsetHeight : true;
      rec = el.getBoundingClientRect();
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
      var content, cur_level, el, i, j, k, l, last_level, len, len1, len2, len3, len4, len5, len6, len7, list_tag, m, matches, n, o, p, pnt, q, r, ref, ref1, ref2, ref3, ref4, ref5, ref6, ref7, ref8, ref9, s, start, str, txt;
      content = editor.html();
      content = content.replace(/<!--[\s\S]+?-->/gi, '');
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '');
      content = content.replace(/<(\/?)s>/gi, '<$1strike>');
      content = content.replace(/&nbsp;/gi, ' ');
      editor.innerHTML = content;
      ref = editor.querySelectorAll('p');
      for (j = 0, len = ref.length; j < len; j++) {
        p = ref[j];
        str = p.getAttribute('style');
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str);
        if (matches) {
          p.dataset._listLevel = parseInt(matches[1], 10);
        }
      }
      last_level = 0;
      pnt = null;
      ref1 = editor.querySelectorAll('p');
      for (k = 0, len1 = ref1.length; k < len1; k++) {
        p = ref1[k];
        cur_level = p.dataset._listLevel;
        if (cur_level !== void 0) {
          txt = p.textContent;
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
              p.insertAdjacentHTML('beforebegin', list_tag);
              pnt = p.previousElementSibling;
            } else {

            }
            pnt.insertAdjacentHTML('beforeend', list_tag);
          }
          if (cur_level < last_level) {
            for (i = l = ref2 = i, ref3 = last_level - cur_level; ref2 <= ref3 ? l <= ref3 : l >= ref3; i = ref2 <= ref3 ? ++l : --l) {
              pnt = pnt.parentNode;
            }
          }
          if (p.querySelector('span:first')) {
            p.querySelector('span:first').remove();
          }
          pnt.insertAdjacentHTML('beforeend', '<li>' + p.innerHTML + '</li>');
          p.remove();
          last_level = cur_level;
        } else {
          last_level = 0;
        }
      }
      ref4 = editor.querySelectorAll('[style]');
      for (m = 0, len2 = ref4.length; m < len2; m++) {
        el = ref4[m];
        el.removeAttribute('style');
      }
      ref5 = editor.querySelectorAll('[align]');
      for (n = 0, len3 = ref5.length; n < len3; n++) {
        el = ref5[n];
        el.removeAttribute('align');
      }
      ref6 = editor.querySelectorAll('span');
      for (o = 0, len4 = ref6.length; o < len4; o++) {
        el = ref6[o];
        el.outerHTML = el.innerHTML;
      }
      ref7 = editor.querySelectorAll('span:empty');
      for (q = 0, len5 = ref7.length; q < len5; q++) {
        el = ref7[q];
        el.remove();
      }
      ref8 = editor.querySelectorAll("[class^='Mso']");
      for (r = 0, len6 = ref8.length; r < len6; r++) {
        el = ref8[r];
        el.removeAttribute('class');
      }
      ref9 = editor.querySelectorAll('p:empty');
      for (s = 0, len7 = ref9.length; s < len7; s++) {
        el = ref9[s];
        el.remove();
      }
      return editor;
    };

    ZammadChat.prototype.removeAttribute = function(element) {
      var att, j, len, ref, results1;
      if (!element) {
        return;
      }
      ref = element.attributes;
      results1 = [];
      for (j = 0, len = ref.length; j < len; j++) {
        att = ref[j];
        results1.push(element.removeAttribute(att.name));
      }
      return results1;
    };

    ZammadChat.prototype.removeAttributes = function(html) {
      var j, len, node, ref;
      ref = html.querySelectorAll('*');
      for (j = 0, len = ref.length; j < len; j++) {
        node = ref[j];
        this.removeAttribute(node);
      }
      return html;
    };

    return ZammadChat;

  })(Base);
  return window.ZammadChat = ZammadChat;
})(window);
