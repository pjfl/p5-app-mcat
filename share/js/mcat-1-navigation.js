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
         this.title        = this.properties['title'];
         this.token        = this.properties['verify-token'];
         this.st           = HStateTable.Renderer.manager;
         this.menu;
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
         this.globalOver  = function(event) {
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
      async fetchMenus(href) {
         const url = new URL(href);
         const params = url.searchParams;
         params.set('navigation', true);
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await response.json();
      }
      loadContent(url) {
         return function(event) {
            event.preventDefault();
            this.renderContent(url);
         }.bind(this);
      }
      listItem(item, menuName, hasHandler) {
         if (typeof item[0] != 'object') {
            const attr = { href: '#', onclick: this.loadContent(item[1]) };
            if (hasHandler) attr['onmouseover'] = this.globalOver;
            return this.h.li({ className: menuName }, this.h.a(attr, item[0]));
         }
         if (item[0]['method'] != 'post') return;
         const form = this.h.form({
            action: item[1], className: 'inline', method: 'post'
         }, this.h.hidden({ name: '_verify', value: this.token }));
         const name = item[0]['name'];
         form.append(this.h.button({
            className: 'form-button', onclick: this.submitHandler(form, name)
         }, this.h.span(name)));
         return this.h.li({ className: menuName }, form);
      }
      redraw() {
         const menu = this.h.nav({ className: 'nav-menu' }, [
            this.renderList(this.menus['_global'], 'global'),
            this.renderControl(this.menus['_control'], 'control')
         ]);
         this.menu = this.display(this.container, 'menu', menu);
      }
      async renderContent(href) {
         const panel = this.h.div({
            id: 'panel-content', className: 'panel-content'
         });
         panel.innerHTML = await this.fetchHTML(href);
         this.st.scan(panel);
         await this.st.isRendering();
         this.replaceLinks(panel);
         this.contentPanel = document.getElementById('panel-content');
         this.contentPanel = this.display(
            this.contentContainer, 'contentPanel', panel
         );
         history.pushState({}, 'Unused', href); // API Darwin award
         this.menus = await this.fetchMenus(href);
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
      async render() {
         this.redraw();
         await this.st.isConstructing();
         this.replaceLinks(document);
      }
      replaceLinks(panel) {
         const url = this.baseURL;
         for (const link of panel.getElementsByTagName('a')) {
            const href = link.href + '';
            if (href.length && url == href.substring(0, url.length)) {
               link.addEventListener('click', this.loadContent(href));
               link.href = '#';
            }
         }
      }
      submitHandler(form, name) {
         return function(event) {
            event.preventDefault();
            if (this.confirm) {
               if (confirm(this.confirm.replace(/\*/, name))) form.submit();
            }
            else if (confirm()) form.submit();
         }.bind(this);
      }
   }
   Object.assign(Navigation.prototype, MCat.Util.Markup);
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
