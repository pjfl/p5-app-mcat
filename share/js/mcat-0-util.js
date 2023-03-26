// Package MCat.Util
if (!window.MCat) window.MCat = {};
if (!MCat.Util) MCat.Util = {};
MCat.Util = (function() {
   const _typeof = function(x) {
      if (!x) return;
      const type = typeof x;
      if ((type == 'object') && (x.nodeType == 1)
          && (typeof x.style == 'object')
          && (typeof x.ownerDocument == 'object')) return 'element';
      if (type == 'object' && Array.isArray(x)) return 'array';
      return type;
   };
   const _events = [
      'onchange', 'onclick', 'ondragenter', 'ondragleave',
      'ondragover', 'ondragstart', 'ondrop', 'onmouseenter', 'onmouseleave',
      'onmouseover', 'onsubmit'
   ];
   class Bitch {
      _new_headers() {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         return headers;
      }
      _set_headers(options) {
         if (!options.headers) options.headers = this._new_headers();
         if (!options.headers instanceof Headers) {
            const headers = options.headers;
            options.headers = this._new_headers();
            for (const [k, v] of Object.entries(headers))
               options.headers.set(k, v);
         }
      }
      async blows(url, options) {
         options ||= {};
         const wait = options.wait; delete options.wait;
         const want = options.response || 'text'; delete options.response;
         this._set_headers(options);
         if (options.form) {
            options.headers.set(
               'Content-Type', 'application/x-www-form-urlencoded'
            );
            const form = options.form; delete options.form;
            const params = new URLSearchParams(new FormData(form));
            options.body = params.toString();
         }
         options.cache ||= 'no-store';
         options.credentials ||= 'same-origin';
         options.method ||= 'POST';
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         if (response.headers.get('location')) {
            return { location: response.headers.get('location') };
         }
         if (want == 'text') {
            if (wait) return { text: await response.text() };
            return { text: response.text() };
         }
         return response;
      }
      async sucks(url, options) {
         options ||= {};
         const wait = options.wait; delete options.wait;
         const want = options.response || 'json'; delete options.response;
         this._set_headers(options);
         options.method ||= 'GET';
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.statusText}`);
         }
         if (want == 'blob') {
            if (wait) return await new Response(await response.blob()).text();
            else return response.blob();
         }
         if (want == 'json') {
            if (wait) return await response.json();
            else return response.json();
         }
         return response;
      }
   }
   class HtmlTiny {
      _tag(tag, attr, content) {
         const el = document.createElement(tag);
         const type = _typeof(attr);
         if (type == 'object') {
            for (const prop of Object.keys(attr)) {
               if (_events.includes(prop)) {
                  el.addEventListener(prop.replace(/^on/, ''), attr[prop]);
               }
               else { el[prop] = attr[prop]; }
            }
         }
         else if (type == 'array')   { content = attr; }
         else if (type == 'element') { content = [attr]; }
         else if (type == 'string')  { content = [attr]; }
         if (!content) return el;
         if (_typeof(content) != 'array') content = [content];
         for (const child of content) {
            const childType = _typeof(child);
            if (!childType) continue;
            if (childType == 'number' || childType == 'string') {
               el.append(document.createTextNode(child));
            }
            else { el.append(child); }
         }
         return el;
      }
      a(attr, content)        { return this._tag('a', attr, content) }
      div(attr, content)      { return this._tag('div', attr, content) }
      figure(attr, content)   { return this._tag('figure', attr, content) }
      form(attr, content)     { return this._tag('form', attr, content) }
      h5(attr, content)       { return this._tag('h5', attr, content) }
      input(attr, content)    { return this._tag('input', attr, content) }
      label(attr, content)    { return this._tag('label', attr, content) }
      li(attr, content)       { return this._tag('li', attr, content) }
      nav(attr, content)      { return this._tag('nav', attr, content) }
      option(attr, content)   { return this._tag('option', attr, content) }
      select(attr, content)   { return this._tag('select', attr, content) }
      span(attr, content)     { return this._tag('span', attr, content) }
      strong(attr, content)   { return this._tag('strong', attr, content) }
      table(attr, content)    { return this._tag('table', attr, content) }
      tbody(attr, content)    { return this._tag('tbody', attr, content) }
      td(attr, content)       { return this._tag('td', attr, content) }
      th(attr, content)       { return this._tag('th', attr, content) }
      tr(attr, content)       { return this._tag('tr', attr, content) }
      thead(attr, content)    { return this._tag('thead', attr, content) }
      ul(attr, content)       { return this._tag('ul', attr, content) }
      button(attr, content) {
         if (_typeof(attr) == 'object') attr['type'] ||= 'submit';
         else { content = attr; attr = { type: 'submit' }; }
         return this._tag('button', attr, content);
      }
      checkbox(attr) {
         attr['type'] = 'checkbox';
         return this._tag('input', attr);
      }
      hidden(attr) {
         attr['type'] = 'hidden';
         return this._tag('input', attr);
      }
      text(attr) {
         attr['type'] = 'text';
         return this._tag('input', attr);
      }
   }
   const esc = encodeURIComponent;
   return {
      Markup: { // A role
         h: new HtmlTiny(),
         appendValue: function(obj, key, newValue) {
            let existingValue = obj[key] || '';
            if (existingValue) existingValue += ' ';
            obj[key] = existingValue + newValue;
         },
         bitch: new Bitch(),
         display: function(container, attribute, obj) {
            if (this[attribute] && container.contains(this[attribute])) {
               container.replaceChild(obj, this[attribute]);
            }
            else { container.append(obj) }
            return obj;
         },
         ucfirst: function(s) {
            return s && s[0].toUpperCase() + s.slice(1) || '';
         }
      },
      Modifiers: { // Another role
         applyTraits: function(obj, namespace, traits, args) {
            for (const trait of traits) {
               if (!namespace[trait]) {
                  throw new Error(namespace + `: Unknown trait ${trait}`);
               }
               const initialiser = namespace[trait]['initialise'];
               if (initialiser) initialiser.bind(obj)(args);
               for (const method of Object.keys(namespace[trait].around)) {
                  obj.around(method, namespace[trait].around[method]);
               }
            }
         },
         around: function(method, modifier) {
            if (!this[method]) {
               throw new Error(`Around no method: ${method}`);
            }
            const original = this[method].bind(this);
            const around = modifier.bind(this);
            this[method] = function(args1, args2, args3, args4, args5) {
               return around(original, args1, args2, args3, args4, args5);
            };
         }
      }
   };
})();

