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
    
      __out.push('>\n  <span class="zammad-chat-message-avatar">');
    
      __out.push(__sanitize(this.avatarInitials));
    
      __out.push('</span>\n  <span class="zammad-chat-message-content"><span class="zammad-chat-message-row"><span class="zammad-chat-message-body"><a href="');
    
      __out.push(__sanitize(this.url));
    
      __out.push('" class="zammad-chat-attachment" target="_blank" rel="noopener"><svg width="14" height="14" viewBox="0 0 24 24"><path d="M16.5 6v11.5c0 2.21-1.79 4-4 4s-4-1.79-4-4V5c0-1.38 1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5v10.5c0 .55-.45 1-1 1s-1-.45-1-1V6H10v9.5c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5V5c0-2.21-1.79-4-4-4S7 2.79 7 5v12.5c0 3.04 2.46 5.5 5.5 5.5s5.5-2.46 5.5-5.5V6h-1.5z"/></svg><span class="zammad-chat-attachment-filename">');
    
      __out.push(__sanitize(this.filename));
    
      __out.push('</span></a></span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 17 4 12 9 7"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/></svg></button>');
      }
    
      __out.push('</span><span class="zammad-chat-message-time">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('"><svg width="16" height="10" viewBox="0 0 20 12" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 7 5 11 13 2"/>');
        if (this.isRead) {
          __out.push('<polyline points="7 7 11 11 19 2"/>');
        }
        __out.push('</svg></span>');
      }
    
      __out.push('</span></span>\n</div>\n');
    
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
    
      __out.push('</span>\n    </div>\n    <div class="zammad-chat-header-title zammad-chat-is-hidden"><span class="js-header-title-text"></span></div>\n    <div class="zammad-chat-header-controls">\n      <button type="button" class="zammad-chat-header-icon zammad-chat-is-hidden js-chat-info" aria-label="');
    
      __out.push(this.T('Info'));
    
      __out.push('">\n        <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><line x1="12" y1="11" x2="12" y2="16.5"/><circle cx="12" cy="7.7" r="0.9" fill="currentColor" stroke="none"/></svg>\n      </button>\n      <button type="button" class="zammad-chat-header-icon js-chat-close" aria-label="');
    
      __out.push(this.T('Close'));
    
      __out.push('">\n        <svg class="zammad-chat-header-icon-close" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><line x1="6" y1="6" x2="18" y2="18"/><line x1="18" y1="6" x2="6" y2="18"/></svg>\n      </button>\n    </div>\n  </div>\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--home is-active"></div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--messages">\n    <div class="zammad-chat-modal"></div>\n    <div class="zammad-scroll-hint is-hidden">\n      <svg class="zammad-scroll-hint-icon" width="20" height="18" viewBox="0 0 20 18"><path d="M0,2.00585866 C0,0.898053512 0.898212381,0 1.99079514,0 L18.0092049,0 C19.1086907,0 20,0.897060126 20,2.00585866 L20,11.9941413 C20,13.1019465 19.1017876,14 18.0092049,14 L1.99079514,14 C0.891309342,14 0,13.1029399 0,11.9941413 L0,2.00585866 Z M10,14 L16,18 L16,14 L10,14 Z" fill-rule="evenodd"/></svg>\n      ');
    
      __out.push(this.T(this.scrollHint));
    
      __out.push('\n    </div>\n    <div class="zammad-chat-body"></div>\n    <div class="zammad-chat-reply-indicator js-reply-indicator zammad-chat-is-hidden"></div>\n    <form class="zammad-chat-controls">\n      <div class="zammad-chat-emoji-picker js-emoji-picker zammad-chat-is-hidden"></div>\n      <div class="zammad-chat-input" rows="1" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
    
      __out.push('" contenteditable="true"></div>\n      <div class="zammad-chat-controls-icons">\n        <div class="zammad-chat-emoji-toggle js-emoji-toggle">\n          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M8.5 14.5s1.2 2 3.5 2 3.5-2 3.5-2"/><circle cx="9" cy="9.5" r="0.9" fill="currentColor" stroke="none"/><circle cx="15" cy="9.5" r="0.9" fill="currentColor" stroke="none"/></svg>\n        </div>\n        <div class="zammad-chat-attach js-chat-attach zammad-chat-is-hidden">\n          <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M16.5 6v11.5a4 4 0 0 1-8 0V5a2.5 2.5 0 0 1 5 0v10.5a1 1 0 0 1-2 0V6"/></svg>\n        </div>\n        <input type="file" class="js-chat-attachment-input zammad-chat-is-hidden">\n        <button type="submit" class="zammad-chat-send" aria-label="');
    
      __out.push(this.T('Send'));
    
      __out.push('"');
    
      if (this.background) {
        __out.push(__sanitize(" style='background: " + this.background + "'"));
      }
    
      __out.push('>\n          <svg width="15" height="15" viewBox="0 0 24 24" fill="#ffffff"><path d="M2 21l21-9L2 3v7l15 2-15 2z"/></svg>\n        </button>\n      </div>\n    </form>\n  </div>\n\n  <div class="zammad-chat-tab-body zammad-chat-tab-body--help"></div>\n\n  <div class="zammad-chat-tabbar"></div>\n</div>');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <div class="zammad-chat-waiting-spinner">\n    <span class="zammad-chat-waiting-spinner-track"></span>\n    <span class="zammad-chat-waiting-spinner-arc zammad-chat-waiting-spinner-arc--danger"></span>\n    <span class="zammad-chat-waiting-spinner-icon zammad-chat-waiting-spinner-icon--danger">\n      <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>\n    </span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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
      __out.push('<div class="zammad-chat-feedback-thanks">\n  <div class="zammad-chat-feedback-thanks-icon">\n    <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>\n  </div>\n  <div class="zammad-chat-feedback-thanks-title">');
    
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
    
      __out.push('</div>\n\n  <div class="zammad-chat-feedback-stars">\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="1" aria-label="1"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="2" aria-label="2"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="3" aria-label="3"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="4" aria-label="4"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>\n    <button type="button" class="zammad-chat-feedback-star js-feedback-star" data-score="5" aria-label="5"><svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg></button>\n  </div>\n\n  <textarea class="zammad-chat-feedback-textarea js-feedback-comment" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_comment_placeholder'] || 'Add a comment (optional)'));
    
      __out.push('"></textarea>\n\n  <div class="zammad-chat-feedback-error js-feedback-error zammad-chat-is-hidden"></div>\n\n  <div class="zammad-chat-feedback-actions">\n    <button type="button" class="zammad-chat-feedback-skip js-feedback-skip">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_skip_button'] || 'Maybe later'));
    
      __out.push('</button>\n    <button type="button" class="zammad-chat-feedback-submit js-feedback-submit">');
    
      __out.push(this.T(this.phrases['chat_phrase_feedback_submit_button'] || 'Submit Feedback'));
    
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
      __out.push('<div class="zammad-chat-help">\n  <div class="zammad-chat-help-search-wrap">\n    <svg class="zammad-chat-help-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>\n    <input type="text" class="zammad-chat-help-search js-kb-search" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_home_search_button'] || 'Search for help'));
    
      __out.push('">\n  </div>\n  <ul class="zammad-chat-kb-results"></ul>\n  <p class="zammad-chat-kb-empty zammad-chat-is-hidden">');
    
      __out.push(this.T(this.phrases['chat_phrase_help_no_results'] || 'No results found.'));
    
      __out.push('</p>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-home">\n  <div class="zammad-chat-home-logo">\n    <div class="zammad-chat-home-logo-mark">\n      <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n    </div>\n  </div>\n\n  <!-- Enhancement 1 -- Tahap 3 (Offline Message + OTP), mockup OfflineHome.dc.html.\n  Tersembunyi default -- ditampilkan lewat `enterOfflineMode()` (chat.coffee)\n  begitu `chat_status_customer` balas state \'offline\' (SEMUA agent tidak\n  tersedia, termasuk yg lagi AUX -- lihat entri 143). -->\n  <div class="zammad-chat-home-offline-notice zammad-chat-is-hidden">\n    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><line x1="12" y1="8" x2="12" y2="12.5"/><circle cx="12" cy="16" r="0.9" fill="currentColor" stroke="none"/></svg>\n    <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_notice'] || 'All our agents are currently unavailable. Leave your message and email, we will verify it via an OTP code and reply as soon as possible.'));
    
      __out.push('</span>\n  </div>\n\n  <div class="zammad-chat-home-actions">\n    <button type="button" class="zammad-chat-home-action js-home-start-action" data-tab="messages">\n      <span class="js-home-start-label">');
    
      __out.push(this.T(this.phrases['chat_phrase_home_start_button'] || 'Send us a message'));
    
      __out.push('</span>\n      <svg class="zammad-chat-home-action-icon-default" width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M2 21l21-9L2 3v7l15 2-15 2z"/></svg>\n      <svg class="zammad-chat-home-action-icon-offline zammad-chat-is-hidden" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h16v12H4z"/><path d="M4 7l8 6 8-6"/></svg>\n    </button>\n    <button type="button" class="zammad-chat-home-action zammad-chat-home-action--secondary" data-tab="help">\n      <span>');
    
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
    
      __out.push('" target="_blank" rel="noopener noreferrer" class="zammad-chat-kb-result-link">\n    <span class="zammad-chat-kb-result-icon">\n      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M7 3h7l5 5v13a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/><path d="M14 3v5h5"/></svg>\n    </span>\n    <span class="zammad-chat-kb-result-text">\n      <span class="zammad-chat-kb-result-title">');
    
      __out.push(this.title);
    
      __out.push('</span>\n      <span class="zammad-chat-kb-result-body">');
    
      __out.push(this.body);
    
      __out.push('</span>\n    </span>\n    <svg class="zammad-chat-kb-result-chevron" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 6 15 12 9 18"></polyline></svg>\n  </a>\n</li>\n');
    
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
      __out.push('<div class="zammad-chat-launcher">\n  <svg class="zammad-chat-launcher-icon-open" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n  <svg class="zammad-chat-launcher-icon-close" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <div class="zammad-chat-waiting-spinner">\n    <span class="zammad-chat-waiting-spinner-track"></span>\n    <span class="zammad-chat-waiting-spinner-arc"></span>\n    <span class="zammad-chat-waiting-spinner-icon">\n      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n    </span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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
    
      __out.push('>\n  <span class="zammad-chat-message-avatar">');
    
      __out.push(__sanitize(this.avatarInitials));
    
      __out.push('</span>\n  <span class="zammad-chat-message-content"><span class="zammad-chat-message-row"><span class="zammad-chat-message-body"');
    
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
    
      __out.push('</span>');
    
      if (this.from === 'agent' && this.id) {
        __out.push('<button type="button" class="zammad-chat-message-reply js-message-reply" aria-label="');
        __out.push(this.T('Reply'));
        __out.push('"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 17 4 12 9 7"/><path d="M20 18v-2a4 4 0 0 0-4-4H4"/></svg></button>');
      }
    
      __out.push('</span><span class="zammad-chat-message-time">');
    
      __out.push(__sanitize(this.time));
    
      if (this.from === 'customer') {
        __out.push('<span class="zammad-chat-message-status zammad-chat-message-status--');
        __out.push(__sanitize(this.isRead ? 'read' : 'sent'));
        __out.push('" aria-label="');
        __out.push(this.isRead ? this.T('Read') : this.T('Sent'));
        __out.push('"><svg width="16" height="10" viewBox="0 0 20 12" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 7 5 11 13 2"/>');
        if (this.isRead) {
          __out.push('<polyline points="7 7 11 11 19 2"/>');
        }
        __out.push('</svg></span>');
      }
    
      __out.push('</span></span>\n</div>\n');
    
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
      __out.push('<div class="zammad-chat-offline-compose">\n  <div class="zammad-chat-offline-compose-verified">\n    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>\n    <span><strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong> ');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_verified_suffix'] || 'verified'));
    
      __out.push('</span>\n  </div>\n\n  <label class="zammad-chat-offline-compose-label">');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_message_label'] || 'Your message'));
    
      __out.push('</label>\n  <textarea class="zammad-chat-offline-compose-textarea js-offline-message" placeholder="');
    
      __out.push(this.T(this.phrases['chat_phrase_offline_compose_placeholder'] || 'Tell us how we can help…'));
    
      __out.push('"></textarea>\n\n  <div class="zammad-chat-offline-compose-error js-offline-compose-error zammad-chat-is-hidden"></div>\n\n  <button type="button" class="zammad-chat-offline-compose-submit js-offline-compose-submit">');
    
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
      __out.push('<div class="zammad-chat-offline-otp">\n  <div class="zammad-chat-offline-otp-icon">\n    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 6h16v12H4z"/><path d="M4 7l8 6 8-6"/></svg>\n  </div>\n  <div class="zammad-chat-offline-otp-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_title'] || 'Enter verification code'));
    
      __out.push('</div>\n  <div class="zammad-chat-offline-otp-subtitle">');
    
      __out.push(this.T(this.phrases['chat_phrase_otp_subtitle_prefix'] || 'We sent a 6-digit code to'));
    
      __out.push(' <strong>');
    
      __out.push(__sanitize(this.email));
    
      __out.push('</strong>.</div>\n\n  <div class="zammad-chat-offline-otp-boxes">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="0">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="1">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="2">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="3">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="4">\n    <input type="text" inputmode="numeric" pattern="[0-9]*" maxlength="1" autocomplete="off" class="zammad-chat-offline-otp-digit js-otp-digit" data-index="5">\n  </div>\n\n  <div class="zammad-chat-offline-otp-error js-otp-error zammad-chat-is-hidden"></div>\n\n  <button type="button" class="zammad-chat-offline-otp-submit js-otp-submit">');
    
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
      __out.push('<div class="zammad-chat-offline-sent">\n  <div class="zammad-chat-offline-sent-icon">\n    <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>\n  </div>\n  <div class="zammad-chat-offline-sent-title">');
    
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
      __out.push('<div class="zammad-chat-prechat">\n  <div class="zammad-chat-prechat-icon">\n    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n  </div>\n  <div class="zammad-chat-prechat-title">');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_title'] || 'Let\'s get started'));
    
      __out.push('</div>\n  <div class="zammad-chat-prechat-subtext">');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_subtitle'] || 'Please share a few details so our agent can help you faster.'));
    
      __out.push('</div>\n\n  <form class="zammad-chat-prechat-form">\n    ');
    
      if (this.error) {
        __out.push('\n      <div class="zammad-chat-prechat-error">');
        __out.push(this.error);
        __out.push('</div>\n    ');
      }
    
      __out.push('\n    <div class="zammad-chat-prechat-field">\n      <label>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_name_label'] || 'Your name'));
    
      __out.push('</label>\n      <input type="text" class="zammad-chat-prechat-name" value="');
    
      __out.push(this.name || '');
    
      __out.push('" required>\n    </div>\n    <div class="zammad-chat-prechat-field">\n      <label>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_email_label'] || 'Your email'));
    
      __out.push('</label>\n      <input type="email" class="zammad-chat-prechat-email" value="');
    
      __out.push(this.email || '');
    
      __out.push('" required>\n    </div>\n    <button type="submit" class="zammad-chat-prechat-submit">\n      <span>');
    
      __out.push(this.T(this.phrases['chat_phrase_prechat_submit_button'] || 'Start chat'));
    
      __out.push('</span>\n      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M2 21l21-9L2 3v7l15 2-15 2z"/></svg>\n    </button>\n  </form>\n</div>\n');
    
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
      __out.push('<button type="button" class="zammad-chat-tabbar-item is-active" data-tab="home">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>\n  <span>');
    
      __out.push(this.T('Home'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="messages">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n  <span>');
    
      __out.push(this.T('Messages'));
    
      __out.push('</span>\n</button>\n<button type="button" class="zammad-chat-tabbar-item" data-tab="help">\n  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/><path d="M9.3 9.3a2.7 2.7 0 1 1 3.9 2.4c-.7.4-1.2.9-1.2 1.8"/><circle cx="12" cy="16.3" r="0.9" fill="currentColor" stroke="none"/></svg>\n  <span>');
    
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
      __out.push('<div class="zammad-chat-waiting">\n  <div class="zammad-chat-waiting-spinner">\n    <span class="zammad-chat-waiting-spinner-track"></span>\n    <span class="zammad-chat-waiting-spinner-arc"></span>\n    <span class="zammad-chat-waiting-spinner-icon">\n      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 5h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H9l-4 4v-4H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/></svg>\n    </span>\n  </div>\n  <div class="zammad-chat-waiting-title">');
    
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
  slice = [].slice;

(function(window) {
  var Base, Core, Io, Log, Timeout, ZammadChat, myScript, scriptHost, scriptProtocol, scripts;
  scripts = document.getElementsByTagName('script');
  myScript = scripts[scripts.length - 1];
  scriptProtocol = window.location.protocol.replace(':', '');
  if (myScript && myScript.src) {
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1];
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1];
  }
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
      this.connect = bind(this.connect, this);
      this.set = bind(this.set, this);
      return Io.__super__.constructor.apply(this, arguments);
    }

    Io.prototype.logPrefix = 'io';

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
          _this.log.debug('onOpen', e);
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
            _this.log.debug('error close, onError callback');
            if (_this.options.onError) {
              return _this.options.onError('Connection lost...');
            }
          }
        };
      })(this);
      return this.ws.onerror = (function(_this) {
        return function(e) {
          _this.log.debug('onError', e);
          if (_this.options.onError) {
            return _this.options.onError(e);
          }
        };
      })(this);
    };

    Io.prototype.close = function() {
      this.log.debug('close websocket manually');
      this.manualClose = true;
      return this.ws.close();
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
      this.onConnectionEstablished = bind(this.onConnectionEstablished, this);
      this.setSessionId = bind(this.setSessionId, this);
      this.markMessagesRead = bind(this.markMessagesRead, this);
      this.onSessionClosed = bind(this.onSessionClosed, this);
      this.onConnectionReestablished = bind(this.onConnectionReestablished, this);
      this.reconnect = bind(this.reconnect, this);
      this.destroy = bind(this.destroy, this);
      this.onScrollHintClick = bind(this.onScrollHintClick, this);
      this.detectScrolledtoBottom = bind(this.detectScrolledtoBottom, this);
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
      this.showFeedbackThanks = bind(this.showFeedbackThanks, this);
      this.skipFeedback = bind(this.skipFeedback, this);
      this.onFeedbackSubmitResult = bind(this.onFeedbackSubmitResult, this);
      this.submitFeedback = bind(this.submitFeedback, this);
      this.selectFeedbackScore = bind(this.selectFeedbackScore, this);
      this.showFeedback = bind(this.showFeedback, this);
      this.finishOfflineFlow = bind(this.finishOfflineFlow, this);
      this.showOfflineSent = bind(this.showOfflineSent, this);
      this.onOfflineMessageSendResult = bind(this.onOfflineMessageSendResult, this);
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
      this.enterOfflineMode = bind(this.enterOfflineMode, this);
      this.submitPrechatForm = bind(this.submitPrechatForm, this);
      this.showPrechatForm = bind(this.showPrechatForm, this);
      this.open = bind(this.open, this);
      this.addAttachmentMessage = bind(this.addAttachmentMessage, this);
      this.uploadAttachment = bind(this.uploadAttachment, this);
      this.triggerAttachmentInput = bind(this.triggerAttachmentInput, this);
      this.renderReplyIndicator = bind(this.renderReplyIndicator, this);
      this.cancelReply = bind(this.cancelReply, this);
      this.startReply = bind(this.startReply, this);
      this.renderMessage = bind(this.renderMessage, this);
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
      this.onKnowledgeBaseSearchResult = bind(this.onKnowledgeBaseSearchResult, this);
      this.onKbSearchInput = bind(this.onKbSearchInput, this);
      this.insertEmoji = bind(this.insertEmoji, this);
      this.toggleEmojiPicker = bind(this.toggleEmojiPicker, this);
      this.updateHeader = bind(this.updateHeader, this);
      this.switchTab = bind(this.switchTab, this);
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
        onError: this.onError
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

    ZammadChat.prototype.renderBase = function() {
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
      this.options.target.insertAdjacentHTML('beforeend', this.view('launcher')());
      this.launcherEl = this.options.target.querySelector('.zammad-chat-launcher');
      this.launcherEl.addEventListener('click', this.toggle);
      this.input = this.el.querySelector('.zammad-chat-input');
      this.body = this.el.querySelector('.zammad-chat-body');
      this.el.querySelector('.js-chat-close').addEventListener('click', this.exitChat);
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
          target = event.target.closest('.js-feedback-star');
          if (!target) {
            return;
          }
          return _this.selectFeedbackScore(event, target.dataset.score);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('.js-feedback-submit');
          if (!target) {
            return;
          }
          return _this.submitFeedback(event);
        };
      })(this));
      this.el.querySelector('.zammad-chat-modal').addEventListener('click', (function(_this) {
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
      this.el.querySelector('.zammad-chat-tab-body--home').innerHTML = this.view('home')();
      this.el.querySelector('.zammad-chat-tab-body--help').innerHTML = this.view('help')();
      this.el.querySelector('.zammad-chat-tabbar').innerHTML = this.view('tabbar')();
      this.el.querySelector('.js-emoji-picker').innerHTML = this.view('emoji_picker')();
      this.activeTab = 'home';
      this.updateHeader('home');
      this.el.addEventListener('click', (function(_this) {
        return function(event) {
          var target;
          target = event.target.closest('[data-tab]');
          if (!target) {
            return;
          }
          return _this.switchTab(target.dataset.tab);
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
      this.el.querySelector('.js-kb-search').addEventListener('input', this.onKbSearchInput);
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
      }
      activeItem = this.el.querySelector(".zammad-chat-tabbar-item[data-tab='" + tabName + "']");
      if (activeItem != null) {
        activeItem.classList.add('is-active');
      }
      return this.updateHeader(tabName);
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
      this.el.querySelector('.js-chat-info').classList.toggle('zammad-chat-is-hidden', !showAgent);
      this.el.querySelector('.zammad-chat-header-title').classList.toggle('zammad-chat-is-hidden', !showTitle);
      if (showTitle) {
        title = tabName === 'help' ? this.T('Help') : this.T('Messages');
        return this.el.querySelector('.js-header-title-text').textContent = title;
      }
    };

    ZammadChat.prototype.toggleEmojiPicker = function(event) {
      if (event != null) {
        event.preventDefault();
      }
      this.el.querySelector('.js-emoji-picker').classList.toggle('zammad-chat-is-hidden');
      return this.el.querySelector('.js-emoji-toggle').classList.toggle('is-active');
    };

    ZammadChat.prototype.insertEmoji = function(emoji) {
      this.input.focus();
      document.execCommand('insertText', false, emoji);
      this.el.querySelector('.js-emoji-picker').classList.add('zammad-chat-is-hidden');
      this.el.querySelector('.js-emoji-toggle').classList.remove('is-active');
      return this.onInput();
    };

    ZammadChat.prototype.onKbSearchInput = function(event) {
      var query, ref;
      query = ((ref = event.currentTarget.value) != null ? ref.trim() : void 0) || '';
      if (this.kbSearchDelayId) {
        clearTimeout(this.kbSearchDelayId);
      }
      return this.kbSearchDelayId = setTimeout(((function(_this) {
        return function() {
          return _this.send('chat_knowledge_base_search', {
            query: query
          });
        };
      })(this)), 400);
    };

    ZammadChat.prototype.onKnowledgeBaseSearchResult = function(data) {
      var emptyMessage, item, j, len, ref, results, results1;
      results = this.el.querySelector('.zammad-chat-kb-results');
      results.innerHTML = '';
      emptyMessage = this.el.querySelector('.zammad-chat-kb-empty');
      if (!data.result || data.result.length === 0) {
        if (emptyMessage != null) {
          emptyMessage.classList.remove('zammad-chat-is-hidden');
        }
        return;
      }
      if (emptyMessage != null) {
        emptyMessage.classList.add('zammad-chat-is-hidden');
      }
      ref = data.result;
      results1 = [];
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        results1.push(results.insertAdjacentHTML('beforeend', this.view('kb_result')(item)));
      }
      return results1;
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
      var from, j, len, pipe;
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
              this.updateHomeLogo(pipe.data.logo_url);
            }
            if (pipe.data.phrases) {
              this.updatePhrases(pipe.data.phrases);
            }
            switch (pipe.data.state) {
              case 'online':
                this.sessionId = void 0;
                if (!this.options.cssAutoload || this.cssLoaded) {
                  this.onReady();
                } else {
                  this.socketReady = true;
                }
                break;
              case 'offline':
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
      var avatarInitials, isAgentMessage, isRead, j, len, message, ref, ref1, ref2, time, unfinishedMessage;
      this.log.debug('old messages', data.session);
      this.inactiveTimeout.start();
      unfinishedMessage = sessionStorage.getItem('unfinished_message');
      if (data.agent) {
        this.onConnectionEstablished(data);
        ref = data.session;
        for (j = 0, len = ref.length; j < len; j++) {
          message = ref[j];
          isAgentMessage = !!message.created_by_id;
          avatarInitials = this.initialsOf(isAgentMessage ? (ref1 = data.agent) != null ? ref1.name : void 0 : this.customerName);
          time = this.formatTime(message.created_at);
          isRead = !!message.read_at;
          if (message.filename) {
            this.body.insertAdjacentHTML('beforeend', this.view('attachment_message')({
              from: isAgentMessage ? 'agent' : 'customer',
              id: message.id,
              filename: message.filename,
              url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments/" + message.id,
              unreadClass: '',
              avatarInitials: avatarInitials,
              time: time,
              isRead: isRead
            }));
          } else {
            this.renderMessage({
              message: message.content,
              id: message.id,
              from: isAgentMessage ? 'agent' : 'customer',
              avatarInitials: avatarInitials,
              time: time,
              isRead: isRead,
              replyTo: (ref2 = message.reply_to) != null ? ref2.content : void 0
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
        avatarInitials: this.initialsOf(this.customerName),
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
      var ref, ref1;
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
        avatarInitials: this.initialsOf((ref1 = this.agent) != null ? ref1.name : void 0),
        time: this.formatTime(data.message.created_at)
      });
      return this.scrollToBottom({
        showHint: true
      });
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
      var file, formData, ref, xhr;
      file = (ref = event.target.files) != null ? ref[0] : void 0;
      if (!file) {
        return;
      }
      formData = new FormData();
      formData.append('File', file);
      xhr = new XMLHttpRequest();
      xhr.open('POST', (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments");
      xhr.onload = (function(_this) {
        return function() {
          var message, parsed;
          if (xhr.status >= 200 && xhr.status < 300) {
            return;
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
      xhr.send(formData);
      return event.target.value = '';
    };

    ZammadChat.prototype.addAttachmentMessage = function(data, from) {
      var ref;
      this.maybeAddTimestamp();
      this.lastAddedType = "message--" + from;
      this.body.insertAdjacentHTML('beforeend', this.view('attachment_message')({
        from: from,
        id: data.id,
        filename: data.filename,
        url: (this.apiBaseUrl()) + "/api/v1/chat_sessions/" + this.sessionId + "/attachments/" + data.id,
        unreadClass: document.hidden ? ' zammad-chat-message--unread' : '',
        avatarInitials: this.initialsOf(from === 'agent' ? (ref = this.agent) != null ? ref.name : void 0 : this.customerName),
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
      this.launcherEl.classList.add('zammad-chat-is-open');
      this.el.addEventListener('transitionend', this.onOpenAnimationEnd);
      return this.el.classList.add('zammad-chat-is-open');
    };

    ZammadChat.prototype.showPrechatForm = function(params) {
      if (params == null) {
        params = {};
      }
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('prechat')({
        error: params.error,
        name: params.name,
        email: params.email
      });
      return this.el.querySelector('.zammad-chat-prechat-form').addEventListener('submit', this.submitPrechatForm);
    };

    ZammadChat.prototype.submitPrechatForm = function(event) {
      var email, emailFormat, name, ref, ref1, ref2, ref3;
      event.preventDefault();
      name = (ref = this.el.querySelector('.zammad-chat-prechat-name')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      email = (ref2 = this.el.querySelector('.zammad-chat-prechat-email')) != null ? (ref3 = ref2.value) != null ? ref3.trim() : void 0 : void 0;
      emailFormat = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
      if (!name || !email || !emailFormat.test(email)) {
        this.showPrechatForm({
          error: this.T(this.phrases['chat_phrase_prechat_validation_error'] || 'Please provide a valid name and email address.'),
          name: name,
          email: email
        });
        return;
      }
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
      var dot, notice, startAction, status, subtext;
      if (this.offlineMode) {
        return;
      }
      this.offlineMode = true;
      subtext = this.el.querySelector('.zammad-chat-welcome-subtext');
      if (subtext) {
        status = document.createElement('span');
        status.className = 'zammad-chat-welcome-offline-status';
        dot = document.createElement('span');
        dot.className = 'zammad-chat-welcome-offline-dot';
        status.appendChild(dot);
        status.appendChild(document.createTextNode(this.T(this.phrases['chat_phrase_offline_status'] || "We're offline right now")));
        subtext.replaceWith(status);
      }
      notice = this.el.querySelector('.zammad-chat-home-offline-notice');
      if (notice != null) {
        notice.classList.remove('zammad-chat-is-hidden');
      }
      startAction = this.el.querySelector('.js-home-start-action');
      if (startAction) {
        startAction.querySelector('.js-home-start-label').textContent = this.T(this.phrases['chat_phrase_offline_start_button'] || 'Leave us a message');
        startAction.querySelector('.zammad-chat-home-action-icon-default').classList.add('zammad-chat-is-hidden');
        startAction.querySelector('.zammad-chat-home-action-icon-offline').classList.remove('zammad-chat-is-hidden');
      }
      return this.show();
    };

    ZammadChat.prototype.onOfflineSessionInitResult = function(data) {
      if (data.state !== 'ok') {
        this.showPrechatForm({
          error: data.message
        });
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
        return next != null ? next.focus() : void 0;
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
      return (ref2 = boxes[Math.max(lastFilled, 0)]) != null ? ref2.focus() : void 0;
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
      return this.send('chat_offline_otp_verify', {
        session_id: this.sessionId,
        code: code
      });
    };

    ZammadChat.prototype.showOtpError = function(message) {
      var error;
      error = this.el.querySelector('.js-otp-error');
      if (!error) {
        return;
      }
      error.textContent = message;
      return error.classList.remove('zammad-chat-is-hidden');
    };

    ZammadChat.prototype.onOfflineOtpVerifyResult = function(data) {
      var ref;
      if (data.state === 'ok') {
        this.showOfflineCompose();
        return;
      }
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
      var content, errorEl, ref, ref1, submitBtn;
      if (event != null) {
        event.preventDefault();
      }
      content = (ref = this.el.querySelector('.js-offline-message')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      errorEl = this.el.querySelector('.js-offline-compose-error');
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
      submitBtn = this.el.querySelector('.js-offline-compose-submit');
      if (submitBtn != null) {
        submitBtn.setAttribute('disabled', 'disabled');
      }
      return this.send('chat_offline_message_send', {
        session_id: this.sessionId,
        content: content
      });
    };

    ZammadChat.prototype.onOfflineMessageSendResult = function(data) {
      var errorEl, ref;
      if ((ref = this.el.querySelector('.js-offline-compose-submit')) != null) {
        ref.removeAttribute('disabled');
      }
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
      return this.showFeedback();
    };

    ZammadChat.prototype.showFeedback = function() {
      this.feedbackScore = void 0;
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('feedback')();
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
      var comment, errorEl, ref, ref1, submitBtn;
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
      submitBtn = this.el.querySelector('.js-feedback-submit');
      if (submitBtn != null) {
        submitBtn.setAttribute('disabled', 'disabled');
      }
      comment = (ref = this.el.querySelector('.js-feedback-comment')) != null ? (ref1 = ref.value) != null ? ref1.trim() : void 0 : void 0;
      return this.send('chat_session_feedback_submit', {
        session_id: this.lastSessionId,
        score: this.feedbackScore,
        comment: comment
      });
    };

    ZammadChat.prototype.onFeedbackSubmitResult = function(data) {
      var errorEl, ref;
      if ((ref = this.el.querySelector('.js-feedback-submit')) != null) {
        ref.removeAttribute('disabled');
      }
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
      return this.goToStartChat();
    };

    ZammadChat.prototype.showFeedbackThanks = function() {
      this.el.querySelector('.zammad-chat-modal').innerHTML = this.view('feedback_thanks')();
      return setTimeout(this.goToStartChat, 2000);
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
      this.el.addEventListener('transitionend', this.onCloseAnimationEnd);
      return this.el.classList.remove('zammad-chat-is-open');
    };

    ZammadChat.prototype.exitChat = function(event) {
      if (this.activeTab !== 'messages') {
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

    ZammadChat.prototype.reconnect = function() {
      this.log.notice('reconnecting');
      this.disableInput();
      this.lastAddedType = 'status';
      this.setAgentOnlineState('connecting');
      return this.addStatus(this.T('Connection lost'));
    };

    ZammadChat.prototype.onConnectionReestablished = function() {
      var base;
      this.lastAddedType = 'status';
      this.setAgentOnlineState('online');
      this.addStatus(this.T('Connection re-established'));
      return typeof (base = this.options).onConnectionReestablished === "function" ? base.onConnectionReestablished() : void 0;
    };

    ZammadChat.prototype.onSessionClosed = function(data) {
      var base;
      this.addStatus(this.T('Chat closed by %s', data.realname));
      this.disableInput();
      this.setAgentOnlineState('offline');
      this.inactiveTimeout.stop();
      this.agent = void 0;
      this.updateHeader();
      return typeof (base = this.options).onSessionClosed === "function" ? base.onSessionClosed(data) : void 0;
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
        statusEl.setAttribute('aria-label', this.T('Read'));
        results1.push(statusEl.innerHTML = '<svg width="16" height="10" viewBox="0 0 20 12" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><polyline points="1 7 5 11 13 2"/><polyline points="7 7 11 11 19 2"/></svg>');
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

    ZammadChat.prototype.onConnectionEstablished = function(data) {
      var base, ref;
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
      if (data.attachment_enabled) {
        this.el.querySelector('.js-chat-attach').classList.remove('zammad-chat-is-hidden');
      } else {
        this.el.querySelector('.js-chat-attach').classList.add('zammad-chat-is-hidden');
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
      var img, mark;
      mark = this.el.querySelector('.zammad-chat-home-logo-mark');
      if (!mark) {
        return;
      }
      mark.style.background = 'none';
      img = document.createElement('img');
      img.src = url;
      img.alt = '';
      img.style.width = '100%';
      img.style.height = '100%';
      img.style.objectFit = 'contain';
      mark.innerHTML = '';
      return mark.appendChild(img);
    };

    ZammadChat.prototype.updatePhrases = function(phrases) {
      var input, welcomeSubtext, welcomeTitle;
      this.phrases = phrases;
      if (!this.el) {
        return;
      }
      this.el.querySelector('.zammad-chat-tab-body--home').innerHTML = this.view('home')();
      this.el.querySelector('.zammad-chat-tab-body--help').innerHTML = this.view('help')();
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
        return input.setAttribute('placeholder', this.T(this.phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'));
      }
    };

    ZammadChat.prototype.formatTime = function(isoString) {
      var date;
      date = isoString ? new Date(isoString) : new Date();
      return date.toTimeString().substr(0, 5);
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
      var base;
      this.cssLoaded = true;
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
