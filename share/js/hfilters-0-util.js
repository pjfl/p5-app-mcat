// Package HFilters.Util
if (!window.HFilters) window.HFilters = {};
HFilters.Util = (function() {
   const esc = encodeURIComponent;
   const _createQueryString = function(obj, traditional = true) {
      if (!obj) return '';
      return Object.entries(obj)
         .filter(([key, val]) => val)
         .reduce((acc, [k, v]) => {
            if (traditional && Array.isArray(v))
               return acc.concat(v.map(i => `${esc(k)}=${esc(i)}`));
            return acc.concat(`${esc(k)}=${esc(v)}`);
         }, []).join('&');
   };
   const _createURL = function(url, args, query = {}, options = {}) {
      for (const arg of args) url = url.replace(/\*/, arg);
      const q = _createQueryString(
         Object.entries(query).reduce((acc, [key, val]) => {
            if (key && (val && val !== '')) acc[key] = val;
            return acc;
         }, {})
      );
      if (q.length) url += `?${q}`;
      const base = options.requestBase;
      if (!base) return url.replace(/^\//, '');
      return base.replace(/\/+$/, '') + '/' + url.replace(/^\//, '');
   };
   const _events = [
      'onchange', 'onclick', 'ondragenter', 'ondragleave', 'ondragover',
      'ondragstart', 'ondrop', 'onkeypress', 'onmousedown', 'onmouseenter',
      'onmouseleave', 'onmousemove', 'onmouseover', 'onsubmit'
   ];
   const _typeof = function(x) {
      if (!x) return;
      const type = typeof x;
      if ((type == 'object') && (x.nodeType == 1)
          && (typeof x.style == 'object')
          && (typeof x.ownerDocument == 'object')) return 'element';
      if (type == 'object' && Array.isArray(x)) return 'array';
      return type;
   };
   const _ucfirst = function(s) {
      return s && s[0].toUpperCase() + s.slice(1) || '';
   };
   class Bitch {
      _newHeaders() {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         return headers;
      }
      _setHeaders(options) {
         if (!options.headers) options.headers = this._newHeaders();
         if (!(options.headers instanceof Headers)) {
            const headers = options.headers;
            options.headers = this._newHeaders();
            for (const [k, v] of Object.entries(headers))
               options.headers.set(k, v);
         }
      }
      async blows(url, options = {}) {
         let want = options.response || 'text'; delete options.response;
         this._setHeaders(options);
         if (options.form) {
            options.headers.set(
               'Content-Type', 'application/x-www-form-urlencoded'
            );
            const form = options.form; delete options.form;
            const data = new FormData(form);
            data.set('_submit', form.getAttribute('submitter'));
            const params = new URLSearchParams(data);
            options.body = params.toString();
         }
         if (options.json) {
            options.headers.set('Content-Type', 'application/json');
            options.body = options.json; delete options.json;
            want = 'object';
         }
         options.method ||= 'POST';
         if (options.method == 'POST') {
            options.cache ||= 'no-store';
            options.credentials ||= 'same-origin';
         }
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.statusText}`);
         }
         const headers = response.headers;
         const location = headers.get('location');
         if (location) {
            const reload_header = headers.get('x-force-reload');
            const reload = reload_header == 'true' ? true : false;
            return { location: location, reload: reload, status: 302 };
         }
         if (want == 'object') return {
            object: await response.json(), status: response.status
         };
         if (want == 'text') return {
            status: response.status, text: await response.text()
         };
         return { response: response };
      }
      async sucks(url, options = {}) {
         const want = options.response || 'object'; delete options.response;
         this._setHeaders(options);
         options.method ||= 'GET';
         const response = await fetch(url, options);
         if (!response.ok) {
            if (want == 'object') {
               console.warn(`HTTP error! Status: ${response.statusText}`);
               return { object: false, status: response.status };
            }
            throw new Error(`HTTP error! Status: ${response.statusText}`);
         }
         const headers = response.headers;
         const location = headers.get('location');
         if (location) return { location: location, status: 302 };
         if (want == 'blob') {
            const key = 'content-disposition';
            const filename = headers.get(key).split('filename=')[1];
            const blob = await response.blob();
            return { blob: blob, filename: filename, status: response.status };
         }
         if (want == 'object') return {
            object: await response.json(), status: response.status
         };
         if (want == 'text') return {
            status: response.status,
            text: await new Response(await response.blob()).text()
         };
         return { response: response };
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
      caption(attr, content)  { return this._tag('caption', attr, content) }
      div(attr, content)      { return this._tag('div', attr, content) }
      fieldset(attr, content) { return this._tag('fieldset', attr, content) }
      figure(attr, content)   { return this._tag('figure', attr, content) }
      form(attr, content)     { return this._tag('form', attr, content) }
      h1(attr, content)       { return this._tag('h1', attr, content) }
      h2(attr, content)       { return this._tag('h2', attr, content) }
      h3(attr, content)       { return this._tag('h3', attr, content) }
      h4(attr, content)       { return this._tag('h4', attr, content) }
      h5(attr, content)       { return this._tag('h5', attr, content) }
      iframe(attr, content)   { return this._tag('iframe', attr, content) }
      img(attr)               { return this._tag('img', attr) }
      input(attr, content)    { return this._tag('input', attr, content) }
      legend(attr, content)   { return this._tag('legend', attr, content) }
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
      textarea(attr, content) { return this._tag('textarea', attr, content) }
      th(attr, content)       { return this._tag('th', attr, content) }
      thead(attr, content)    { return this._tag('thead', attr, content) }
      tr(attr, content)       { return this._tag('tr', attr, content) }
      ul(attr, content)       { return this._tag('ul', attr, content) }
      button(attr, content) {
         if (_typeof(attr) == 'object') attr['type'] ||= 'submit';
         else {
            content = attr;
            attr = { type: 'submit' };
         }
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
      cumulativeOffset(el) {
         let valueT = 0;
         let valueL = 0;
         if (el.parentNode) {
            do {
               valueT += el.offsetTop  || 0;
               valueL += el.offsetLeft || 0;
               el = el.offsetParent;
            } while (el);
         }
         return { left: Math.round(valueL), top: Math.round(valueT) };
      }
      elementOffset(el, stopEl) {
         let valueT = 0;
         let valueL = 0;
         do {
            if (el) {
               valueT += el.offsetTop  || 0;
               valueL += el.offsetLeft || 0;
               el = el.offsetParent;
               if (stopEl && el == stopEl) break;
            }
         } while (el);
         return { left: Math.round(valueL), top: Math.round(valueT) };
      }
      getDimensions(el) {
         if (!el) return { height: 0, width: 0 };
         const style = el.style || {};
         if (style.display && style.display !== 'none') {
            return { height: el.offsetHeight, width: el.offsetWidth };
         }
         const originalStyles = {
            display: style.display,
            position: style.position,
            visibility: style.visibility
         };
         const newStyles = { display: 'block', visibility: 'hidden' }
         if (originalStyles.position !== 'fixed')
            newStyles.position = 'absolute';
         for (const p in newStyles) style[p] = newStyles[p];
         const dimensions = { height: el.offsetHeight, width: el.offsetWidth };
         for (const p in newStyles) style[p] = originalStyles[p];
         return dimensions;
      }
      getCoords(event, coordKey = 'page') {
         const x = `${coordKey}X`;
         const y = `${coordKey}Y`;
         return {
            x: x in event ? event[x] : event.pageX,
            y: y in event ? event[y] : event.pageY,
         };
      }
      getOffset(el) {
         const rect = el.getBoundingClientRect();
         return {
            left: Math.round(rect.left + window.scrollX),
            top: Math.round(rect.top + window.scrollY)
         };
      }
   }
   return {
      Bitch: {
         bitch: new Bitch(),
      },
      Markup: { // A role
         animateButtons: function(container) {
            const selector = 'button';
            container ||= this.container;
            for (const el of container.querySelectorAll(selector)) {
               if (el.getAttribute('movelistener')) continue;
               el.addEventListener('mousemove', function(event) {
                  const rect = el.getBoundingClientRect();
                  const x = Math.floor(
                     event.pageX - (rect.left + window.scrollX)
                  );
                  const y = Math.floor(
                     event.pageY - (rect.top + window.scrollY)
                  );
                  el.style.setProperty('--x', x + 'px');
                  el.style.setProperty('--y', y + 'px');
               });
               el.setAttribute('movelistener', true);
            }
         },
         appendValue: function(obj, key, newValue) {
            let existingValue = obj[key] || '';
            if (existingValue) existingValue += ' ';
            obj[key] = existingValue + newValue;
         },
         display: function(container, attribute, obj) {
            if (this[attribute] && container.contains(this[attribute])) {
               container.replaceChild(obj, this[attribute]);
            }
            else { container.append(obj) }
            return obj;
         },
         h: new HtmlTiny(),
         isHTMLOfClass: function(value, className) {
            if (typeof value != 'string') return false;
            if (!value.match(new RegExp(`class="${className}"`))) return false;
            return true;
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
         },
         resetModifiers: function(methods) {
            for (const method of Object.keys(methods)) delete methods[method];
         }
      },
      String: {
         capitalise: function(s) {
            const words = [];
            for (const word of s.split(' ')) words.push(_ucfirst(word));
            return words.join(' ');
         },
         guid: function() {
            // https://jsfiddle.net/briguy37/2MVFd/
            let date = new Date().getTime();
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
               const r = ((date + Math.random()) * 16) % 16 | 0;
               date = Math.floor(date / 16);
               return (c === 'x' ? r : ((r & 0x3) | 0x8)).toString(16);
            });
         },
         padString: function(string, padSize, pad) {
            string = string.toString();
            pad = pad.toString() || ' ';
            const size = padSize - string.length;
            if (size < 1) return string;
            return pad.repeat(size) + string;
         },
         ucfirst: _ucfirst
      },
      URL: {
         createURL: _createURL
      }
   };
})();
