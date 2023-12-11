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
         const containerName   = this.properties['container-name'];
         this.contentName      = this.properties['content-name'];
         this.controlLabel     = this.properties['control-label'];
         this.linkDisplay      = this.properties['link-display'];
         this.location         = this.properties['location'];
         this.logo             = this.properties['logo'];
         this.mediaBreak       = this.properties['media-break'];
         this.skin             = this.properties['skin'];
         this.title            = this.properties['title'];
         this.titleAbbrev      = this.properties['title-abbrev'];
         this.token            = this.properties['verify-token'];
         this.version          = this.properties['version'];
         this.contentContainer = document.getElementById(containerName);
         this.contentPanel     = document.getElementById(this.contentName);
         this.contextPanels    = {};
         this.content;
         this.headerMenu;
         this.globalMenu;
         this.titleEntry;
         container.append(this.renderTitle());
         window.addEventListener('popstate', function(event) {
            if (event.state && event.state.href)
               this.renderLocation(event.state.href);
         }.bind(this));
         window.addEventListener('resize', this.resizeHandler());
      }
      addSelected(item) {
         item.classList.add('selected');
         return true;
      }
      isCurrentHref(href) {
         return history.state && history.state.href == href ? true : false;
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
            const panel = this.contextPanels[context];
            panel.classList.remove('visible');
            for (const el of panel.getElementsByClassName('visible'))
               el.classList.remove('visible');
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
         const { location, reload, text }
               = await this.bitch.blows(action, options);
         if (location) {
            if (reload) { window.location.href = location }
            else {
               this.renderLocation(location);
               this.messages.render(location);
            }
         }
         else if (text) { this.renderHTML(text) }
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
         const content = [this.renderControl()];
         const global = this.renderList(this.menus['_global'], 'global');
         if (this.location == 'header') content.unshift(global);
         const cMenu = this.h.nav({ className: 'nav-menu' }, content);
         this.headerMenu = this.display(this.container, 'headerMenu', cMenu);
         if (this.location == 'header') return;
         const container = document.getElementById(this.location);
         const gMenu = this.h.nav({ className: 'nav-menu' }, global);
         this.globalMenu = this.display(container, 'globalMenu', gMenu);
      }
      async render() {
         this.messages.render(window.location.href);
         this.redraw();
         await StateTable.isConstructing();
         this.replaceLinks(document.getElementById(this.contentName));
      }
      renderControl() {
         const isURL = this.controlLabel.match(/:/) ? true : false;
         const attr  = { className: 'nav-control-label' };
         if (!isURL) this.appendValue(attr, 'className', 'text');
         const label = isURL
               ? this.h.img({ src: this.controlLabel }) : this.controlLabel;
         const link = this.h.a({
            onmouseover: this.menuOver('control')
         }, this.h.span(attr, label));
         this.contextPanels['control'] = this.h.div({
            className: 'nav-panel control-panel',
            onmouseleave: this.menuLeave('control')
         }, this.renderList(this.menus['_control'], 'control'));
         return this.h.div({
            className: 'nav-control'
         }, [ link, this.contextPanels['control'] ]);
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
         HForms.Util.focusFirst(this.skin);
      }
      renderItem(item, menuName, context) {
         const [text, href, icon] = item;
         if (typeof text != 'object') {
            const label = this.renderLabel(icon, text);
            if (href) {
               const attr = { href: href, onclick: this.loadLocation(href) };
               if (context) attr['onmouseover'] = this.menuOver(context);
               const link = this.h.a(attr, label);
               link.setAttribute('listener', true);
               return this.h.li({ className: menuName }, link);
            }
            const labelAttr = { className: 'drop-menu' };
            if (context) labelAttr['onmouseover'] = this.menuOver(context);
            const menuItem = this.h.span(labelAttr, label);
            return this.h.li({ className: menuName }, menuItem);
         }
         if (text['method'] != 'post') return;
         const form = this.h.form({
            action: href, className: 'inline', method: 'post'
         }, this.h.hidden({ name: '_verify', value: this.token }));
         form.setAttribute('listener', true);
         form.addEventListener('submit', this.submitFormHandler(form));
         form.append(this.h.button({
            className: 'form-button', onclick: this.submitHandler(form, name)
         }, this.h.span(this.renderLabel(icon, text['name']))));
         return this.h.li({ className: menuName }, form);
      }
      renderLabel(icon, text) {
         const iconImage = icon && icon.match(/:/)
               ? this.h.img({ src: icon }) : icon;
         return {
            both: [iconImage, text],
            icon: iconImage ? iconImage : text,
            text: text
         }[this.linkDisplay];
      }
      renderList(list, menuName) {
         const [title, itemList] = list;
         const items = [];
         let context = false;
         let isSelected = false;
         for (const item of itemList) {
            if (typeof item == 'string' && this.menus[item]) {
               const className
                     = menuName == 'context' ? 'slide-out' : 'nav-panel';
               this.contextPanels[item] = this.h.div({
                  className: className, onmouseleave: this.menuLeave(item)
               }, this.renderList(this.menus[item], 'context'));
               context = item;
               continue;
            }
            const listItem = this.renderItem(item, menuName, context);
            if (context) {
               const panel = this.contextPanels[context];
               if (panel.firstChild.classList.contains('selected'))
                  isSelected = this.addSelected(listItem);
               listItem.append(panel);
               context = false;
            }
            if (this.isCurrentHref(item[1]))
               isSelected = this.addSelected(listItem);
            items.push(listItem);
         }
         const navList = this.h.ul({ className: 'nav-list' }, items);
         if (menuName) navList.classList.add(menuName);
         if (isSelected) navList.classList.add('selected');
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
         const title = this.logo.length ? [this.h.img({ src: this.logo })] : [];
         title.push(this.h.span({ className: 'title-text' }, this.title));
         return this.h.div({ className: 'nav-title' }, title);
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
      resizeHandler() {
         return function(event) {
            const linkDisplay = this.linkDisplay;
            const navigation = document.getElementById('navigation');
            const sidebar = document.getElementById('sidebar');
            const content = document.getElementById('content');
            const className = 'link-display-' + this.linkDisplay;
            navigation.classList.remove(className);
            sidebar.classList.remove(className);
            content.classList.remove(className);
            if (window.innerWidth <= this.mediaBreak) {
               navigation.classList.add('link-display-icon');
               sidebar.classList.add('link-display-icon');
               content.classList.add('link-display-icon');
               this.linkDisplay = 'icon';
            }
            else {
               const original = this.properties['link-display'];
               navigation.classList.add('link-display-' + original);
               sidebar.classList.add('link-display-' + original);
               content.classList.add('link-display-' + original);
               this.linkDisplay = original;
            }
            if (linkDisplay != this.linkDisplay) this.redraw();
         }.bind(this);
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
            form.setAttribute('submitter', event.submitter.value);
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
         const mid = url.searchParams.get('mid');
         if (!mid) return;
         messagesURL.searchParams.set('mid', mid);
         const { object } = await this.bitch.sucks(messagesURL);
         if (!object) return;
         let count = 0;
         this.panel.classList.remove('hide');
         for (const message of object) {
            const options = {
               className: 'message-item',
               onclick: function() {
                  this.panel.classList.add('hide');
               }.bind(this)
            };
            const item = this.h.div(options, message);
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
         this.onReady(function() { this.createNavigation() }.bind(this));
      }
      createNavigation() {
         const el = document.getElementsByClassName(triggerClass)[0];
         if (!el) return;
         const nav = new Navigation(el, JSON.parse(el.dataset[dsName]));
         this.navigator = nav;
         nav.render();
      }
      onContentLoad() {
         if (this.navigator) this.navigator.replaceLinks(
            document.getElementById(this.navigator.contentName)
         );
      }
      onReady(callback) {
         if (document.readyState != 'loading') callback();
         else if (document.addEventListener)
            document.addEventListener('DOMContentLoaded', callback);
         else document.attachEvent('onreadystatechange', function() {
            if (document.readyState == 'complete') callback();
         });
      }
      renderLocation(href) {
         this.navigator.renderLocation(href);
      }
      renderMessage(href) {
         this.navigator.messages.render(href);
      }
   }
   return {
      manager: new Manager()
   };
})();
