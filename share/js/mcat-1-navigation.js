// -*- coding: utf-8; -*-
// Package MCat.Navigation
MCat.Navigation = (function() {
   const dsName       = 'navigationConfig';
   const triggerClass = 'state-navigation';
   const StateTable   = HStateTable.Renderer.manager;
   class Navigation {
      constructor(container, config) {
         this.container    = container;
         this.menus        = config['menus'];
         this.messages     = new Messages(config['messages']);
         this.moniker      = config['moniker'];
         this.properties   = config['properties'];
         this.baseURL      = this.properties['base-url'];
         this.confirm      = this.properties['confirm'];
         this.controlLabel = this.properties['label'] || '≡';
         this.title        = this.properties['title'];
         this.titleAbbrev  = this.properties['title-abbrev'];
         this.token        = this.properties['verify-token'];
         this.version      = this.properties['version'];
         this.content;
         const containerName = this.properties['container-name'];
         this.contentContainer = document.getElementById(containerName);
         this.contentPanel;
         this.contextPanel;
         this.controlPanel;
         this.menu;
         this.controlOver = function(event) {
            event.preventDefault();
            this.controlPanel.classList.toggle('visible');
         }.bind(this);
         this.globalOver = function(event) {
            event.preventDefault();
            this.contextPanel.classList.toggle('visible');
         }.bind(this);
         this.controlLeave = function(event) {
            event.preventDefault();
            this.controlPanel.classList.remove('visible');
         }.bind(this);
         this.contextLeave = function(event) {
            event.preventDefault();
            this.contextPanel.classList.remove('visible');
         }.bind(this);
         window.addEventListener('popstate', function(event) {
            if (event.state && event.state.href) {
               console.log('Popstate to ' + event.state.href);
               this.renderContent(event.state.href);
            }
         }.bind(this));
         const title = this.version
               ? this.title + ' v' + this.version : this.title;
         container.append(this.renderTitle(title));
      }
      finagleHistory(url) {
         const href = url + '';
         history.pushState({ href: href }, 'Unused', url); // API Darwin award
         const head = (document.getElementsByTagName('head'))[0];
         const title = head.querySelector('title');
         const tag = this.ucfirst(href.substring(this.baseURL.length));
         title.innerHTML = this.titleAbbrev + ' - ' + tag.replace(/\//g, ' ');
      }
      listItem(item, menuName, hasHandler) {
         if (typeof item[0] != 'object') {
            const href = item[1];
            const attr = {
               href: href, listener: true, onclick: this.loadContent(item[1])
            };
            if (hasHandler) attr['onmouseover'] = this.globalOver;
            return this.h.li({ className: menuName }, this.h.a(attr, item[0]));
         }
         if (item[0]['method'] != 'post') return;
         const form = this.h.form({
            action: item[1], className: 'inline', listener: true, method: 'post'
         }, this.h.hidden({ name: '_verify', value: this.token }));
         form.addEventListener('submit', this.submitFormHandler(form));
         const name = item[0]['name'];
         form.append(this.h.button({
            className: 'form-button', onclick: this.submitHandler(form, name)
         }, this.h.span(name)));
         return this.h.li({ className: menuName }, form);
      }
      loadContent(href) {
         return function(event) {
            event.preventDefault();
            this.renderContent(href);
         }.bind(this);
      }
      async process(action, form) {
         const options = { headers: { prefer: 'render=partial' }, form: form };
         const { location, text } = await this.bitch.blows(action, options);
         if (text) await this.renderHTML(text);
         else if (location) {
            this.messages.render(location);
            await this.renderContent(location);
         }
         else { console.warn('No understand post response') }
      }
      redraw() {
         const menu = this.h.nav({ className: 'nav-menu' }, [
            this.renderList(this.menus['_global'], 'global'),
            this.renderControl(this.menus['_control'], 'control')
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
            if (object) this.menus = object;
            this.redraw();
         }
         else if (location) {
            this.messages.render(location);
            const locationURL = new URL(location);
            locationURL.searchParams.delete('mid');
            if (locationURL != href) {
               console.log('Redirected to ' + location);
               await this.renderContent(location);
            }
            else {
               console.log('Redirect to self ' + href + ' ' + location);
               console.log('Current state ' + history.state.href);
               let count = 0;
               while (href == history.state.href) {
                  history.back();
                  if (++count > 3) break;
               }
               console.log('Current state ' + count + ' ' + history.state.href);
            }
         }
         else { console.warn('No understand get response') }
      }
      renderControl(list, menuName) {
         this.controlPanel = this.h.div({
            className: 'nav-panel', onmouseleave: this.controlLeave
         }, this.renderList(list, menuName));
         const control = this.h.div({ className: 'nav-control' }, [
            this.h.a({ onmouseover: this.controlOver }, this.controlLabel),
            this.controlPanel
         ]);
         return control;
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
      renderList(list, menuName) {
         const items = [];
         let context = false;
         for (const item of list[1]) {
            if (typeof item == 'string' && this.menus[item]) {
               this.contextPanel = this.h.div({
                  className: 'nav-panel', onmouseleave: this.contextLeave
               }, this.renderList(this.menus[item], 'context'));
               context = true;
            }
            else {
               const listItem = this.listItem(item, menuName, context);
               items.push(listItem);
               if (context) {
                  listItem.classList.add('selected');
                  listItem.append(this.contextPanel);
                  context = false;
               }
            }
         }
         const navList = this.h.ul({ className: 'nav-list' }, items);
         if (menuName) navList.classList.add(menuName);
         return navList;
      }
      renderTitle(title) {
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
            else this.panel.append(item)
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
         this.navigators = {};
      }
      createNavigation() {
         const el = document.getElementsByClassName(triggerClass)[0];
         const nav = new Navigation(el, JSON.parse(el.dataset[dsName]));
         this.navigators[nav.name] = nav;
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
   }
   const manager = new Manager();
   manager.onReady(function() { manager.createNavigation(); });
})();
