var React, visualInject;

React = require('react');

window._ = require('lodash');

visualInject = function() {
  var bindEvents, edit, getElementOffset, getNode, getSelector, inTagWhitelist, isEditable, navigate, nodeFromPoint, onMessage, positionInDom;
  window.CLOSEHEAT_EDITOR = {};
  positionInDom = function(el, count) {
    var new_el;
    if (count == null) {
      count = 1;
    }
    if (new_el = el.previousElementSibling) {
      return positionInDom(new_el, count + 1);
    } else {
      return count;
    }
  };
  getSelector = function(el) {
    var c, e, names;
    names = [];
    while (el.parentNode) {
      if (el.id) {
        names.unshift('#' + el.id);
        break;
      } else {
        if (el === el.ownerDocument.documentElement) {
          names.unshift(el.tagName.toLowerCase());
        } else {
          c = 1;
          e = el;
          while (e.previousElementSibling) {
            e = e.previousElementSibling;
            c++;
          }
          names.unshift(el.tagName.toLowerCase() + ':nth-child(' + c + ')');
        }
        el = el.parentNode;
      }
    }
    return names.join(' > ');
  };
  edit = function(e) {
    var node, selector;
    if (window.CLOSEHEAT_EDITOR.navigating) {
      return;
    }
    node = getNode(e);
    if (!isEditable(node)) {
      return;
    }
    e.stopPropagation();
    e.preventDefault();
    selector = getSelector(e.target);
    window.CLOSEHEAT_EDITOR.last_target = e.target;
    parent.postMessage({
      action: 'edit',
      selector: selector,
      top: e.clientX,
      left: e.clientY,
      height: e.target.offsetHeight,
      width: e.target.offsetWidth,
      old_outline: e.target.outline,
      pathname: window.location.pathname,
      text: node.nodeValue
    }, 'SERVER_URL_PLACEHOLDER');
    return false;
  };
  isEditable = function(node) {
    if (inTagWhitelist(node)) {
      return true;
    }
    if (node.nodeValue) {
      return true;
    }
    return false;
  };
  inTagWhitelist = function(node) {
    var NO_CONTENT_TAGS;
    NO_CONTENT_TAGS = ['INPUT', 'BUTTON', 'IMG'];
    return NO_CONTENT_TAGS.indexOf(node.tagName) !== -1;
  };
  getNode = function(event) {
    return nodeFromPoint(event.clientX, event.clientY);
  };
  nodeFromPoint = function(x, y) {
    var el, i, j, n, nodes, r, rect, rects;
    el = document.elementFromPoint(x, y);
    nodes = el.childNodes;
    i = 0;
    while (n = nodes[i++]) {
      if (n.nodeType === 3) {
        r = document.createRange();
        r.selectNode(n);
        rects = r.getClientRects();
        j = 0;
        while (rect = rects[j++]) {
          if (x > rect.left && x < rect.right && y > rect.top && y < rect.bottom) {
            return n;
          }
        }
      }
    }
    return el;
  };
  onMessage = function(e) {
    if (e.data.action === 'navigate') {
      return navigate();
    }
  };
  navigate = function() {
    window.CLOSEHEAT_EDITOR.navigating = true;
    window.CLOSEHEAT_EDITOR.last_target.click();
    return window.CLOSEHEAT_EDITOR.navigating = false;
  };
  bindEvents = function() {
    window.addEventListener('click', edit, true);
    return window.addEventListener('message', onMessage, false);
  };
  getElementOffset = function(element) {
    var box, de, left, top;
    de = document.documentElement;
    box = element.getBoundingClientRect();
    top = box.top + window.pageYOffset - de.clientTop;
    left = box.left + window.pageXOffset - de.clientLeft;
    return {
      top: top,
      left: left
    };
  };
  bindEvents();
  return console.log('injected her');
};

module.exports = React.createClass({
  getInitialState: function() {
    window.addEventListener('message', this.props.onMessage, false);
    return {};
  },
  iframe: function() {
    return document.getElementById('browser');
  },
  refresh: function() {
    return this.iframe().src = this.props.browser_url;
  },
  componentDidMount: function() {
    return $(this.iframe()).load((function(_this) {
      return function() {
        return _this.inject();
      };
    })(this));
  },
  wrapEvalFunction: function(code) {
    return "evalFunction = " + code + "; evalFunction()";
  },
  inject: function() {
    console.log('inkecting');
    return this.evalInIframe(visualInject.toString().replace(/SERVER_URL_PLACEHOLDER/g, window.SERVER_URL));
  },
  evalInIframe: function(code) {
    return this.iframe().contentWindow.postMessage(this.wrapEvalFunction(code), this.props.browser_url);
  },
  render: function() {
    return React.createElement("div", {
      "className": 'browser'
    }, React.createElement("iframe", {
      "ref": 'iframe',
      "id": 'browser',
      "name": 'browser-frame',
      "src": this.props.browser_url
    }));
  }
});
