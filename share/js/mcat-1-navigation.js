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
         this.controlLabel     = this.properties['label'] || '≡';
         this.title            = this.properties['title'];
         this.titleAbbrev      = this.properties['title-abbrev'];
         this.token            = this.properties['verify-token'];
         this.version          = this.properties['version'];
         this.contentContainer = document.getElementById(this.containerName);
         this.content;
         this.contentPanel;
         this.contextPanels = {};
         this.menu;
         container.append(this.renderTitle());
         window.addEventListener('popstate', function(event) {
            if (event.state && event.state.href)
               this.renderContent(event.state.href);
         }.bind(this));
      }
      finagleHistory(url) {
         const href  = url + '';
         history.pushState({ href: href }, 'Unused', url); // API Darwin award
         let entry = href.substring(this.baseURL.length);
         entry = entry.replace(/[_\/]/g, ' ').replace(/\d+$/, 'View');
         entry = this.capitalise(entry.replace(/\d/g, '').replace(/  /g, ' '));
         const head  = (document.getElementsByTagName('head'))[0];
         const title = head.querySelector('title');
         title.innerHTML = this.titleAbbrev + ' - ' + entry;
      }
      loadContent(href) {
         return function(event) {
            event.preventDefault();
            this.renderContent(href);
         }.bind(this);
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
            this.renderContent(location);
         }
         else {
            console.warn('Neither content nor redirect in response to post');
         }
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
         this.contentPanel = document.getElementById('panel-content');
         this.replaceLinks(this.contentPanel);
      }
      async renderContent(href) {
         const url = new URL(href);
         url.searchParams.delete('mid');
         const opt = { headers: { prefer: 'render=partial' }, response: 'text'};
         const { location, text } = await this.bitch.sucks(url, opt);
         if (text && text.length > 0) {
            await this.renderHTML(text);
            this.finagleHistory(url);
            url.searchParams.set('navigation', true);
            const { object } = await this.bitch.sucks(url);
            if (object) {
               this.menus = object['menus'];
               this.token = object['verify-token'];
            }
            this.redraw();
         }
         else if (location) {
            this.messages.render(location);
            const locationURL = new URL(location);
            locationURL.searchParams.delete('mid');
            if (locationURL != href) {
               console.log('Redirect after get to ' + location);
               await this.renderContent(location);
            }
            else {
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
         }
         else {
            console.warn('Neither content nor redirect in response to get');
         }
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
         const panel = this.h.div({
            id: 'panel-content', className: 'panel-content'
         });
         panel.innerHTML = html;
         StateTable.scan(panel);
         await StateTable.isRendering();
         this.replaceLinks(panel);
         this.contentPanel = document.getElementById('panel-content');
         this.contentPanel = this.display(
            this.contentContainer, 'contentPanel', panel
         );
         HForms.Util.focusFirst();
      }
      renderItem(item, menuName, context) {
         const [label, href] = item;
         if (typeof label != 'object') {
            if (href) {
               const attr = { href: href, onclick: this.loadContent(href) };
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
      renderTitle() {
         const title = this.version
               ? this.title + ' v' + this.version : this.title;
         return this.h.div({
            className: 'nav-title'
         }, this.h.span({ className: 'title-text'}, title));
      }
      replaceLinks(panel) {
         const url = this.baseURL;
         for (const link of panel.getElementsByTagName('a')) {
            const href = link.href + '';
            if (href.length && url == href.substring(0, url.length)
                && !link.getAttribute('listener')) {
               link.setAttribute('listener', true);
               link.addEventListener('click', this.loadContent(href));
            }
         }
         for (const form of panel.getElementsByTagName('form')) {
            const action = form.action + '';
            if (action.length && url == action.substring(0, url.length)
                && !form.getAttribute('listener')) {
               form.addEventListener('submit', this.submitFormHandler(form));
            }
         }
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
   }
   const manager = new Manager();
   manager.onReady(function() { manager.createNavigation(); });
   return {
      manager: manager
   };
})();
