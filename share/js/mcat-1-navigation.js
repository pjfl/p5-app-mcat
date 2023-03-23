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
         this.confirm      = this.properties['confirm'];
         this.controlLabel = this.properties['label'] || '≡';
         this.title        = this.properties['title'];
         this.token        = this.properties['verify-token'];
         this.menu;
         this.content;
         const containerName = this.properties['container-name'];
         this.contentContainer = document.getElementById(containerName);
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
      async fetchJSON(url) {
         const headers = new Headers();
         headers.set('X-Requested-With', 'XMLHttpRequest');
         const options = { headers: headers, method: 'GET' };
         const response = await fetch(url, options);
         if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
         }
         return await response.json();
      }
      itemSelect(url) {
         return function(event) {
            event.preventDefault();
            this.renderContent(url);
         }.bind(this);
      }
      listItem(item, menuName, hasHandler) {
         if (typeof item[0] != 'object') {
            const attr = { href: '#', onclick: this.itemSelect(item[1]) };
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
      async renderContent(href) {
         this.contentContainer.innerHTML = await this.fetchHTML(href);
         HStateTable.Renderer.manager.scan(this.contentContainer);
         history.pushState({}, '', href);
         const url = new URL(href);
         const params = url.searchParams;
         params.set('navigation', true);
         this.menus = await this.fetchJSON(url);
         this.render();
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
      render() {
         const menu = this.h.nav({ className: 'nav-menu' }, [
            this.renderList(this.menus['_global'], 'global'),
            this.renderControl(this.menus['_control'], 'control')
         ]);
         this.menu = this.display(this.container, 'menu', menu);
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
         for (const el of document.getElementsByClassName(triggerClass)) {
            const nav = new Navigation(el, JSON.parse(el.dataset[dsName]));
            this.navigators[nav.name] = nav;
            nav.render();
         }
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
