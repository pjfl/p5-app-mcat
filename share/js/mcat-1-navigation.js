// -*- coding: utf-8; -*-
// Package MCat.Navigation
MCat.Navigation = (function() {
   const dsName       = 'navigationConfig';
   const triggerClass = 'state-navigation';
   const StateTable   = HStateTable.Renderer.manager;
   class Navigation {
      constructor(container, config) {
         this.container        = container;
         this.menus            = config['menus'];
         this.messages         = new Messages(config['messages']);
         this.moniker          = config['moniker'];
         this.properties       = config['properties'];
         this.baseURL          = this.properties['base-url'];
         this.confirm          = this.properties['confirm'];
         this.containerName    = this.properties['container-name'];
         this.contentName      = this.properties['content-name'];
         this.controlLabel     = this.properties['label'] || '≡';
         this.title            = this.properties['title'];
         this.titleAbbrev      = this.properties['title-abbrev'];
         this.token            = this.properties['verify-token'];
         this.version          = this.properties['version'];
         this.contentContainer = document.getElementById(this.containerName);
         this.contentPanel     = document.getElementById(this.contentName);
         this.contextPanels    = {};
         this.content;
         this.menu;
         this.titleEntry;
         container.append(this.renderTitle());
         window.addEventListener('popstate', function(event) {
            if (event.state && event.state.href)
               this.renderLocation(event.state.href);
         }.bind(this));
      }
      loadLocation(href) {
         return function(event) {
            event.preventDefault();
            this.renderLocation(href);
         }.bind(this);
      }
      async loadMenuData(url) {
         const state = { href: url + '' };
         history.pushState(state, 'Unused', url); // API Darwin award
         url.searchParams.set('navigation', true);
         const { object } = await this.bitch.sucks(url);
         if (!object) return;
         this.menus = object['menus'];
         this.token = object['verify-token'];
         this.titleEntry = object['title-entry'];
      }
      menuLeave(context) {
         return function(event) {
            event.preventDefault();
            this.contextPanels[context].classList.remove('visible');
         }.bind(this);
      }
      menuOver(context) {
         return function(event) {
            event.preventDefault();
            this.contextPanels[context].classList.toggle('visible');
         }.bind(this);
      }
      async process(action, form) {
         const options = { headers: { prefer: 'render=partial' }, form: form };
         const { location, text } = await this.bitch.blows(action, options);
         if (text) this.renderHTML(text);
         else if (location) {
            this.messages.render(location);
            this.renderLocation(location);
         }
         else {
            console.warn('Neither content nor redirect in response to post');
         }
      }
      async redirectAfterGet(href, location) {
         const locationURL = new URL(location);
         locationURL.searchParams.delete('mid');
         if (locationURL != href) {
            console.log('Redirect after get to ' + location);
            await this.renderLocation(location);
            return;
         }
         const state = history.state;
         console.log('Redirect after get to self ' + location);
         console.log('Current state ' + state.href);
         let count = 0;
         while (href == state.href) {
            history.back();
            if (++count > 3) break;
         }
         console.log('Recovered state ' + count + ' ' + state.href);
      }
      redraw() {
         const menu = this.h.nav({ className: 'nav-menu' }, [
            this.renderList(this.menus['_global'], 'global'),
            this.renderControl()
         ]);
         this.menu = this.display(this.container, 'menu', menu);
      }
      async render() {
         this.redraw();
         await StateTable.isConstructing();
         this.replaceLinks(document.getElementById(this.contentName));
      }
      renderControl() {
         this.contextPanels['control'] = this.h.div({
            className: 'nav-panel control-panel',
            onmouseleave: this.menuLeave('control')
         }, this.renderList(this.menus['_control'], 'control'));
         return this.h.div({ className: 'nav-control' }, [
            this.h.a({
               onmouseover: this.menuOver('control')
            }, this.controlLabel),
            this.contextPanels['control']
         ]);
      }
      async renderHTML(html) {
         const attr  = { id: this.contentName, className: this.contentName };
         const panel = this.h.div(attr);
         panel.innerHTML = html;
         await StateTable.scan(panel);
         this.replaceLinks(panel);
         this.contentPanel = document.getElementById(this.contentName);
         this.contentPanel = this.display(
            this.contentContainer, 'contentPanel', panel
         );
         HForms.Util.focusFirst();
      }
      renderItem(item, menuName, context) {
         const [label, href] = item;
         if (typeof label != 'object') {
            if (href) {
               const attr = { href: href, onclick: this.loadLocation(href) };
               if (context) attr['onmouseover'] = this.menuOver(context);
               const link = this.h.a(attr, label);
               link.setAttribute('listener', true);
               return this.h.li({ className: menuName }, link);
            }
            const spanAttr = { className: 'drop-menu' };
            if (context) spanAttr['onmouseover'] = this.menuOver(context);
            return this.h.li({
               className: menuName
            }, this.h.span(spanAttr, label));
         }
         if (label['method'] != 'post') return;
         const form = this.h.form({
            action: href, className: 'inline', method: 'post'
         }, this.h.hidden({ name: '_verify', value: this.token }));
         form.setAttribute('listener', true);
         form.addEventListener('submit', this.submitFormHandler(form));
         const name = label['name'];
         form.append(this.h.button({
            className: 'form-button', onclick: this.submitHandler(form, name)
         }, this.h.span(name)));
         return this.h.li({ className: menuName }, form);
      }
      renderList(list, menuName) {
         const [title, itemList] = list;
         const items = [];
         let context = false;
         let containsSelected = false;
         for (const item of itemList) {
            if (typeof item == 'string' && this.menus[item]) {
               const className
                     = menuName == 'context' ? 'slide-out' : 'nav-panel';
               this.contextPanels[item] = this.h.div({
                  className: className, onmouseleave: this.menuLeave(item)
               }, this.renderList(this.menus[item], 'context'));
               context = item;
            }
            else {
               const listItem = this.renderItem(item, menuName, context);
               items.push(listItem);
               if (context) {
                  const panel = this.contextPanels[context];
                  listItem.append(panel);
                  context = false;
                  if (panel.firstChild.classList.contains('selected')) {
                     listItem.classList.add('selected');
                     containsSelected = true;
                  }
               }
               if (history.state && history.state.href == item[1]) {
                  listItem.classList.add('selected');
                  containsSelected = true;
               }
            }
         }
         const navList = this.h.ul({ className: 'nav-list' }, items);
         if (menuName) navList.classList.add(menuName);
         if (containsSelected) navList.classList.add('selected');
         return navList;
      }
      async renderLocation(href) {
         const url = new URL(href);
         url.searchParams.delete('mid');
         const opt = { headers: { prefer: 'render=partial' }, response: 'text'};
         const { location, text } = await this.bitch.sucks(url, opt);
         if (text && text.length > 0) {
            await this.renderHTML(text);
            await this.loadMenuData(url);
            this.setHeadTitle();
            this.redraw();
         }
         else if (location) {
            this.messages.render(location);
            this.redirectAfterGet(href, location);
         }
         else {
            console.warn('Neither content nor redirect in response to get');
         }
      }
      renderTitle() {
         return this.h.div({
            className: 'nav-title'
         }, this.h.span({ className: 'title-text'}, this.title));
      }
      replaceLinks(container) {
         const url = this.baseURL;
         for (const link of container.getElementsByTagName('a')) {
            const href = link.href + '';
            if (href.length && url == href.substring(0, url.length)
                && !link.getAttribute('listener')) {
               link.setAttribute('listener', true);
               link.addEventListener('click', this.loadLocation(href));
            }
         }
         for (const form of container.getElementsByTagName('form')) {
            const action = form.action + '';
            if (action.length && url == action.substring(0, url.length)
                && !form.getAttribute('listener')) {
               form.addEventListener('submit', this.submitFormHandler(form));
            }
         }
      }
      setHeadTitle() {
         const head  = (document.getElementsByTagName('head'))[0];
         const title = head.querySelector('title');
         const entry = this.capitalise(this.titleEntry);
         title.innerHTML = this.titleAbbrev + ' - ' + entry;
      }
      submitFormHandler(form) {
         form.setAttribute('listener', true);
         const action = form.action;
         return function(event) {
            event.preventDefault();
            this.process(action, form);
         }.bind(this);
      }
      submitHandler(form, name) {
         return function(event) {
            if (this.confirm) {
               if (confirm(this.confirm.replace(/\*/, name))) return true;
            }
            else if (confirm()) return true;
            event.preventDefault();
            return false;
         }.bind(this);
      }
   }
   Object.assign(Navigation.prototype, MCat.Util.Markup);
   class Messages {
      constructor(config) {
         this.bufferLimit = config['buffer-limit'] || 3;
         this.displayTime = config['display-time'] || 20;
         this.messagesURL = config['messages-url'];
         this.items = [];
         this.panel = this.h.div({ className: 'messages-panel' });
         document.body.append(this.panel);
      }
      animate(item) {
         setTimeout(function() {
            let opacity = 1;
            const fadeOut = function() {
               if (opacity <= 0) return;
               opacity -= 0.01;
               item.style.opacity = opacity;
               requestAnimationFrame(fadeOut);
            };
            requestAnimationFrame(fadeOut);
         }, 1000 * this.displayTime);
      }
      async render(href) {
         const url = new URL(href);
         const messagesURL = new URL(this.messagesURL);
         messagesURL.searchParams.set('mid', url.searchParams.get('mid'));
         const { object } = await this.bitch.sucks(messagesURL);
         if (!object) return;
         let count = 0;
         for (const message of object) {
            const item = this.h.div({ className: 'message-item' }, message);
            if (count++ > 0) this.panel.prepend(item);
            else this.panel.append(item);
            this.items.unshift(item);
            this.animate(item);
         }
         while (this.items.length > this.bufferLimit) {
            this.items.pop().remove();
         }
      }
   }
   Object.assign(Messages.prototype, MCat.Util.Markup);
   class Manager {
      constructor() {
         this.navigator;
      }
      createNavigation() {
         const el = document.getElementsByClassName(triggerClass)[0];
         const nav = new Navigation(el, JSON.parse(el.dataset[dsName]));
         this.navigator = nav;
         nav.render();
      }
      onReady(callback) {
         if (document.readyState != 'loading') callback();
         else if (document.addEventListener)
            document.addEventListener('DOMContentLoaded', callback);
         else document.attachEvent('onreadystatechange', function() {
            if (document.readyState == 'complete') callback();
         });
      }
      renderMessage(href) {
         this.navigator.messages.render(href);
      }
      onContentLoad() {
         if (this.navigator) this.navigator.replaceLinks(
            document.getElementById(this.navigator.contentName)
         );
      }
   }
   const manager = new Manager();
   manager.onReady(function() { manager.createNavigation(); });
   return {
      manager: manager
   };
})();
