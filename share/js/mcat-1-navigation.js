// -*- coding: utf-8; -*-
// Package MCat.Navigation
MCat.Navigation = (function() {
   const dsName       = 'navigationConfig';
   const triggerClass = 'state-navigation';
   class Navigation {
      constructor(container, config) {
         this.container    = container;
         this.menus        = config['menus'];
         this.moniker      = config['moniker'];
         this.properties   = config['properties'];
         this.baseURL      = this.properties['base-url'];
         this.confirm      = this.properties['confirm'];
         this.controlLabel = this.properties['label'] || '≡';
         this.messagesURL  = new URL(this.properties['messages-url']);
         this.title        = this.properties['title'];
         this.token        = this.properties['verify-token'];
         this.stateTable   = HStateTable.Renderer.manager;
         this.menu;
         this.messages     = new Messages(this);
         this.content;
         const containerName = this.properties['container-name'];
         this.contentContainer = document.getElementById(containerName);
         this.contentPanel;
         this.contextPanel;
         this.controlPanel;
         this.controlOver  = function(event) {
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
            if (event.state.href) this.renderContent(event.state.href);
         }.bind(this));
         container.append(this.renderTitle(this.title));
      }
      async fetchHTML(url) {
         const headers = new Headers();
         headers.set('Prefer', 'render=partial');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await new Response(await response.blob()).text();
      }
      async fetchJSON(url) {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return response.json();
      }
      fetchMenus(url) {
         url.searchParams.set('navigation', true);
         return this.fetchJSON(url);
      }
      fetchMessages(href) {
         const url = new URL(href);
         this.messagesURL.searchParams.set('mid', url.searchParams.get('mid'));
         return this.fetchJSON(this.messagesURL);
      }
      listItem(item, menuName, hasHandler) {
         if (typeof item[0] != 'object') {
            const href = 'data://' + item[1].substring(this.baseURL.length);
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
      async postForm(url, form) {
         const params = new URLSearchParams(new FormData(form));
         const headers = new Headers();
         headers.set('Content-Type', 'application/x-www-form-urlencoded');
         headers.set('Prefer', 'render=partial');
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = {
            body: params.toString(), cache: 'no-store',
            credentials: 'same-origin', headers: headers, method: 'POST'
         };
         const response = await fetch(url, options);
         if (response.headers.get('location')) {
            return { href: response.headers.get('location') };
         }
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return { html: await response.text() };
      }
      async process(action, form) {
         const { href, html } = await this.postForm(action, form);
         if (html) await this.renderHTML(html);
         else if (href) {
            this.messages.render(this.fetchMessages(href));
            await this.renderContent(href);
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
         await this.stateTable.isConstructing();
         this.contentPanel = document.getElementById('panel-content');
         this.replaceLinks(this.contentPanel);
      }
      async renderContent(href) {
         const url = new URL(href);
         url.searchParams.delete('mid');
         this.renderHTML(await this.fetchHTML(url));
         // TODO: See if setting header title will fix browser back strings
         history.pushState({ href: href }, 'Unused', url); // API Darwin award
         this.menus = await this.fetchMenus(url);
         this.redraw();
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
         this.stateTable.scan(panel);
         await this.stateTable.isRendering();
         this.replaceLinks(panel);
         this.contentPanel = document.getElementById('panel-content');
         this.contentPanel = this.display(
            this.contentContainer, 'contentPanel', panel
         );
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
         return this.h.div({ className: 'nav-title' }, title);
      }
      replaceLinks(panel) {
         const url = this.baseURL;
         for (const link of panel.getElementsByTagName('a')) {
            const href = link.href + '';
            if (href.length && url == href.substring(0, url.length)
                && !link.getAttribute('listener')) {
               link.setAttribute('listener', true);
               link.addEventListener('click', this.loadContent(href));
               link.href = 'data://' + href.substring(url.length);
            }
         }
         for (const form of panel.getElementsByTagName('form')) {
            const action = form.action + '';
            if (action.length && url == action.substring(0, url.length)
                && !form.getAttribute('listener')) {
               form.addEventListener('submit', this.submitFormHandler(form));
               form.action = 'data://' + action.substring(url.length);
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
            return false;
         }.bind(this);
      }
   }
   Object.assign(Navigation.prototype, MCat.Util.Markup);
   class Messages {
      constructor(nav) {
         const config = nav.properties['messages']
         this.bufferLimit = config['buffer-limit'] || 3;
         this.displayTime = config['display-time'] || 20;
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
      async render(promise) {
         const messages = await promise;
         for (const message of messages) {
            const item = this.h.div({ className: 'message-item' }, message);
            this.panel.prepend(item);
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
