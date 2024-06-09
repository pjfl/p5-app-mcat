// -*- coding: utf-8; -*-
// Package WCom.Filters.Editor
if (!WCom.Filters) WCom.Filters = {};
WCom.Filters.Editor = (function() {
   const dsName = 'filterConfig';
   const triggerClass = 'filter-container';
   class Editor {
      constructor(container, config) {
         this.config = config;
         this.container = container;
         this.dragThreshold = config['drag-threshold'] || 3;
         this.editorDisplay = this.h.div({ className: 'filter-editor' });
         this.instance = true;
         this.ruleEditorWidth = config['rule-editor-width'] || 200;
         this.startHighlightDelay = config['start-highlight-delay'] || 100;

         const fieldName = config['field-name'] || 'filter_json';
         this.field = document.getElementById(fieldName);
         if (!this.field) {
            this.error = `Element ${fieldName} not found`;
            console.warn(this.error);
            return;
         }

         const value = this.originalValue = this.field.value;
         try { this.tree = WCom.Filters.NodeTree.create(value, config) }
         catch (e) { throw `NodeTree.create: ${e}` }
         const treeReg = this.tree.registry;
         treeReg.listen('ruleremove', this.testDataChange.bind(this));
         treeReg.listen('ruleselect', this.ruleSelect.bind(this));
         treeReg.listen('ruleunselect', this.ruleUnselect.bind(this));

         try { this.ruleEditor = new RuleEditor(config) }
         catch (e) { throw `RuleEditor.new: ${e}` }
         const editorReg = this.ruleEditor.registry;
         editorReg.listen('close', this.tree.selectRule, this.tree);
         editorReg.listen('close', this.testDataChange.bind(this));

         const formName = config['form-name'] || 'edit_filter';
         const form = document.getElementById(formName);
         if (!form) console.warn(`Form ${formName} not found`);
         else form.addEventListener('submit', this.submitHandler.bind(this));
      }
      centerNode(node, big) {
         const nodePos = this.getNodeCenter(node);
         if (!nodePos) return;
         this.treeScrollFx.clearTimer();
         this.treeScrollBigFx.clearTimer();
         const effect = big ? this.treeScrollBigFx : this.treeScrollFx;
         effect.custom({
            left: [parseInt(this.tree.el.style.left || 0), nodePos.x],
            top:  [parseInt(this.tree.el.style.top  || 0), nodePos.y]
         });
      }
      drag(event) {
         event.preventDefault();
         const pointer = this.pointer(event);
         const x = this.dragStart.x - pointer.x;
         const y = this.dragStart.y - pointer.y;
         if (!(this.treeDragged
               || Math.max(x, -x) > this.dragThreshold
               || Math.max(y, -y) > this.dragThreshold)) return;
         let posX = -(x - this.scrollStart.x);
         let posY = -(y - this.scrollStart.y);
         if (posX > 0) posX = 0;
         if (posY > 0) posY = 0;
         const editorSize = this.scrollStart.editorSize;
         const treeSize = this.scrollStart.treeSize;
         if (posX < editorSize.width - treeSize.width)
            posX = editorSize.width - treeSize.width;
         if (posY < editorSize.height - treeSize.height)
            posY = editorSize.height - treeSize.height;
         this.tree.el.style.left = posX + 'px';
         this.tree.el.style.top = posY + 'px';
         if (this.treeDragged) return;
         this.treeDragged = true;
         document.body.classList.add('drag');
      }
      getNodeCenter(node) {
         const editorSize = this.h.getDimensions(this.editorDisplay);
         const nodeOffset = this.h.elementOffset(node.wrapper, this.tree.el);
         const nodeSize = this.h.getDimensions(node.el);
         if (nodeOffset.left == 0 && nodeOffset.top == 0 && nodeSize.height == 0
             && nodeSize.width == 0) return;
         const x = -nodeOffset.left
               + (editorSize.width / 2)
               - (nodeSize.width / 2);
         const y = -nodeOffset.top
               + (editorSize.height / 2)
               - (nodeSize.height / 2);
         return { x: x, y: y };
      }
      pointer(event) {
         const offset = this.h.cumulativeOffset(this.editorDisplay);
         const pos = this.pointerPos(event);
         return {
            x: offset.left + this.scrollStart.x + pos.x,
            y: offset.top  + this.scrollStart.y + pos.y
         };
      }
      pointerPos(event) {
         const doc = document.documentElement;
         const body = document.body || { scrollLeft: 0, scrollTop: 0 };
         const x = event.pageX || (event.clientX
                                   + (doc.scrollLeft || body.scrollLeft)
                                   - (doc.clientLeft || 0));
         const y = event.pageY || (event.clientY
                                   + (doc.scrollTop || body.scrollTop)
                                   - (doc.clientTop || 0));
         return { x: x, y: y };
      }
      render() {
         if (this.error) return this.renderErrorState();
         const dragCallback = function(event) { this.drag(event) }.bind(this);
         this.editorDisplay.addEventListener('mousedown', function(event) {
            this.treeScrollFx.clearTimer();
            this.treeScrollBigFx.clearTimer();
            this.scrollStart = {
               editorSize: this.h.getDimensions(this.editorDisplay),
               treeSize: this.h.getDimensions(this.tree.el),
               x: parseInt(this.tree.el.style.left || 0),
               y: parseInt(this.tree.el.style.top || 0)
            };
            this.dragStart = this.pointer(event);
            document.addEventListener('mousemove', dragCallback);
            const body = document.body;
            const pointerId = event.pointerId;
            if (body.setPointerCapture) {
               body.classList.add('drag');
               setTimeout(function() { body.setPointerCapture(pointerId) }, 1);
            }
            const mouseupCallback = function(event) {
               event.preventDefault();
               document.removeEventListener('mousemove', dragCallback);
               document.removeEventListener('mouseup', mouseupCallback);
               document.body.classList.remove('drag');
               if (body.releasePointerCapture)
                  body.releasePointerCapture(pointerId);
            };
            document.addEventListener('mouseup', mouseupCallback);
            this.treeDragged = false;
         }.bind(this));
         this.treeElement = this.tree.render();
         this.editorDisplay.appendChild(this.treeElement);
         this.treeScrollBigFx = new FxStyles(this.tree.el, {
            duration: 1300, transition: FxTransitions.elasticOut
         });
         this.treeScrollFx = new FxStyles(this.tree.el, {
            duration: 300, transition: FxTransitions.cubicInOut
         });
         this.container.appendChild(this.editorDisplay);
         this.container.appendChild(this.ruleEditor.render());
         setTimeout(function() {
            const node = this.tree.getFirstRule();
            this.tree.selectRule(node);
            this.ruleSelect(node, true);
         }.bind(this), this.startHighlightDelay);
         this.setupResizer();
         return;
      }
      renderErrorState() {
         const attr = { className: 'filter-error' };
         this.editorDisplay.appendChild(this.h.h4(attr, this.error));
         return;
      }
      ruleSelect(node, big) {
         this.ruleEditor.editRule(node);
         this.centerNode(node, big);
      }
      ruleUnselect(node) {
         this.ruleEditor.clear();
      }
      setOnBeforeUnload(unset) {
         if (unset) window.onbeforeunload = null;
         else {
            if (!window.onbeforeunload) {
               window.onbeforeunload = function() {
                  return 'You have unsaved changes, are you sure you want to close the filter editor?';
               }
            }
         }
      }
      setupResizer() {
         this.resizer = this.h.div({ className: 'filter-resizer' });
         this.editorDisplay.appendChild(this.resizer);
         this.resizer.addEventListener('mousedown', function(event) {
            event.preventDefault();
            document.onselectstart = function() { return false };
            this.resizer.classList.add('filter-resizer-active');
            this.resizeStart = {
               cursor: this.pointerPos(event).y,
               height: this.editorDisplay.offsetHeight
            };
            const body = document.body;
            const pointerId = event.pointerId;
            if (body.setPointerCapture) body.setPointerCapture(pointerId);
            const moveHandler = function(ev) {
               const cursor = this.pointerPos(ev).y - this.resizeStart.cursor;
               const height = this.resizeStart.height + cursor;
               this.editorDisplay.style.height = Math.max(20, height) + 'px';
            }.bind(this);
            document.addEventListener('mousemove', moveHandler);
            const upHandler = function() {
               document.onselectstart = null;
               this.resizer.classList.remove('filter-resizer-active');
               document.removeEventListener('mousemove', moveHandler);
               document.removeEventListener('mouseup', upHandler);
               if (body.releasePointerCapture)
                  body.releasePointerCapture(pointerId);
             }.bind(this);
            document.addEventListener('mouseup', upHandler);
         }.bind(this));
      }
      submitHandler() {
         this.setOnBeforeUnload(true);
         this.field.value = JSON.stringify(this.tree.forJSON());
      }
      testDataChange() {
         const newValue = JSON.stringify(this.tree.forJSON());
         const newSha = this._hashit(newValue);
         const oldSha = this._hashit(this.originalValue);
         this.setOnBeforeUnload(newSha == oldSha);
         if (newSha != oldSha) this.field.value = newValue;
      }
      _hashit(string) {
         return Array.from(string).reduce(
            (hash, char) => 0 | (31 * hash + char.charCodeAt(0)), 0
         );
      }
   }
   Object.assign(Editor.prototype, WCom.Util.Markup);
   Object.assign(Editor.prototype, WCom.Util.String);
   class RuleEditor {
      constructor(config) {
         this.config = config;
         this.registry = new Registrar(['close']);
         this.padding = 2;
      }
      cancelRule() {
         this.clear();
         this.registry.fire('close', this);
      }
      clear() {
         if (this.cleared) return;
         this.cleared = true;
         this.fx().custom(this.el.offsetWidth, 0);
      }
      async editRule(node) {
         this.cleared = false;
         this.el.innerHTML = '';
         this.ruleEditorFx = null;
         this.editor = new RuleEditorInterface(node);
         this.editor.registry.listen('save', this.saveRule, this);
         this.editor.registry.listen('cancel', this.cancelRule, this);
         this.el.appendChild(await this.editor.render());
         const fx = this.fx();
         fx.custom(this.el.offsetWidth, this.ruleEditorFx.initialWidth);
      }
      fx() {
         if (this.ruleEditorFx) {
            this.ruleEditorFx.clearTimer();
            return this.ruleEditorFx;
         }
         this.ruleEditorFx = new FxWidth(this.el, {
            duration: 400,
            onComplete: function() { this.element.style.overflow = 'auto' },
            transition: FxTransitions.cubicInOut
         });
         this.ruleEditorFx.initialWidth = this.el.scrollWidth + this.padding;
         return this.ruleEditorFx;
      }
      render() {
         this.el = this.h.div({ className: 'rule-editor' });
         this.el.style.width = 0;
         return this.el;
      }
      saveRule() {
         this.clear();
         this.registry.fire('close', this);
      }
   }
   Object.assign(RuleEditor.prototype, WCom.Util.Markup);
   class RuleEditorInterface {
      constructor(node) {
         this.node = node;
         this.registry = new Registrar(['save', 'cancel']);
      }
      cancelEditorChanges() {
         this.node.editorCancel();
         this.registry.fire('cancel', this);
      }
      keyPressed(event) {
         const target = event.target;
         if (event.ignoreKeyPress
             || (target.nodeName == 'TEXTAREA'
                 && !!~target.className.indexOf('type-multistring')))
            return;
         if (event.keyCode == 13) {
            event.preventDefault();
            this.saveEditorChanges();
         }
         else if (event.keyCode == 27) {
            event.preventDefault();
            this.cancelEditorChanges();
         }
         return;
      }
      async render() {
         const legend = this.h.legend({
            className: 'node-rule-edit-title'
         }, this.node.label);
         const content = [ legend ];
         for (const field in this.node.fields) {
            const fieldNode = this.node.data[field];
            if (!fieldNode.group) content.push(await fieldNode.render());
         }
         content.push(this.h.div({ className: 'node-rule-edit-footer' }, [
            this.h.button({
               className: 'node-rule-edit-cancel',
               onclick: function() { this.cancelEditorChanges() }.bind(this),
            }, this.h.span('Cancel')),
            this.h.button({
               className: 'node-rule-edit-save',
               onclick: function() { this.saveEditorChanges() }.bind(this),
            }, this.h.span('OK'))
         ]));
         const el = this.h.fieldset({
            className: 'node-rule-edit',
            onkeypress: function(event) { this.keyPressed(event) }.bind(this)
         }, content);
         const container = this.h.div({
            className: 'node-rule-edit-container'
         }, el);
         this.animateButtons(container);
         return container;
      }
      saveEditorChanges() {
         if (this.node.updateValue() == false) return;
         this.node.editorSave();
         this.registry.fire('save', this);
      }
   }
   Object.assign(RuleEditorInterface.prototype, WCom.Util.Markup);
   const FxTransitions = {
      cubicInOut: function(t, b, c, d) {
         if ((t /= d / 2) < 1) return c / 2 * (t * t * t) + b;
         return c / 2 * ((t -= 2) * t * t + 2) + b;
      },
      elasticOut: function(t, b, c, d, a, p) {
         if ((t /= d) == 1) return b + c;
         if (!p) p = d * 0.3;
         if (!a) a = 1;
         let s;
         if (a < Math.abs(c)) { a = c; s = p / 4; }
         else s = p / (2 * Math.PI) * Math.asin(c / a);
         return a * Math.pow(2, -10 * t) * Math.sin((t * d - s) * (2 * Math.PI) / p) + c + b;
      },
      sineInOut: function(t, b, c, d) {
         return -c / 2 * (Math.cos(Math.PI * t / d) - 1) + b;
      }
   }
   class FxBase {
      constructor(options) {
         this.duration = options['duration'] || 500;
         this.fps = options['fps'] || 50;
         this.onComplete = options['onComplete'] || function() {};
         this.onStart = options['onStart'] || function() {};
         this.transition = options['transition'] || FxTransitions.sineInOut;
         this.unit = options['unit'] || 'px';
         this.wait = options['wait'] || true;
         this.runTime = 0;
      }
      clearTimer() {
         clearInterval(this.timer);
         this.timer = null;
         return this;
      }
      compute(from, to) {
         if (this.runTime == 0) return from;
         return this.transition(this.runTime, from, to - from, this.duration);
      }
      custom(from, to) {
         return this._start(from, to);
      }
      hide() {
         return this.set(0);
      }
      set(to) {
         this.now = to;
         this.increase();
         return this;
      }
      setNow() {
         this.now = this.compute(this.from, this.to);
      }
      setStyle(e, p, v) {
         if (p == 'opacity') {
            if (v == 0 && e.style.visibility != 'hidden')
               e.style.visibility = 'hidden';
            else if (e.style.visibility != 'visible')
               e.style.visibility = 'visible';
            e.style.opacity = v;
         }
         else e.style[p] = v + this.unit;
      }
      step() {
         const timeNow = new Date().getTime();
         if (timeNow < this.startTime + this.duration) {
            this.runTime = timeNow - this.startTime;
            this.setNow();
         }
         else {
            setTimeout(this.onComplete.bind(this, this.element), 10);
            this.clearTimer();
            this.now = this.to;
         }
         this.increase();
      }
      _start(from, to) {
         if (!this.wait) this.clearTimer();
         if (this.timer) return;
         setTimeout(this.onStart.bind(this, this.element), 10);
         this.from = from;
         this.to = to;
         this.startTime = new Date().getTime();
         const interval = Math.round(1000 / this.fps);
         this.timer = setInterval(this.step.bind(this), interval);
         return this;
      }
   }
   class FxStyles extends FxBase {
      constructor(el, options) {
         super(options);
         this.element = el;
         this.now = {};
      }
      custom(obj) {
         if (this.timer && this.wait) return;
         const from = {};
         const to = {};
         for (const p in obj) {
            from[p] = obj[p][0];
            to[p] = obj[p][1];
         }
         return this._start(from, to);
      }
      increase() {
         for (const p in this.now) {
            this.setStyle(this.element, p, this.now[p]);
         }
      }
      setNow() {
         for (const p in this.from) {
            this.now[p] = this.compute(this.from[p], this.to[p]);
         }
      }
   }
   class FxWidth extends FxBase {
      constructor(el, options) {
         super(options);
         this.element = el;
         this.element.style.overflow = 'hidden';
         this.initialWidth = this.element.offsetWidth;
      }
      increase() {
         this.setStyle(this.element, 'width', this.now);
      }
      show() {
         return this.set(this.initialWidth);
      }
      toggle() {
         if (this.element.offsetWidth > 0)
            return this.custom(this.element.offsetWidth, 0);
         return this.custom(0, this.initialWidth);
      }
   }
   const registry = {};
   let registryCount = 0;
   class Registrar {
      constructor(eventList) {
         this.id = 'reg-' + registryCount++;
         registry[this.id] = {};
         if (eventList) this.registerEvents(eventList);
         window.addEventListener('unload', this.unloadHandler);
      }
      fire(eventName, obj, arg) {
         if (!registry[this.id][eventName])
            throw 'Event ' + eventName + ' is not registerd';
         const listeners = registry[this.id][eventName];
         if (!listeners) return;
         for (const listener of listeners) {
            const func = listener.callback.bind(listener.thisObj);
            func(obj, arg);
         }
      }
      listen(eventName, callback, thisObj) {
         if (!registry[this.id][eventName])
            throw 'Event ' + eventName + ' is not registerd';
         if (typeof callback != 'function')
            throw 'Callback must be a function';
         const listener = { callback: callback, thisObj: thisObj };
         registry[this.id][eventName].push(listener);
      }
      register(eventName) {
         if (registry[this.id][eventName])
            throw 'Event ' + eventName + ' is already registered';
         registry[this.id][eventName] = [];
      }
      registerEvents(eventList) {
         for (const eventName of eventList) this.register(eventName);
      }
      remove(eventName, callback) {
         const listeners = registry[this.id][eventName];
         for (let i = 0; i < listeners.length; i++) {
            if (listeners[i].callback == callback) listeners.splice(i, 1);
         }
      }
      unloadHandler() {
         for (const id in registry) {
            for (const eventName in registry[id]) {
               for (let i = 0; i < registry[id][eventName].length; i++) {
                  delete registry[id][eventName][i];
               }
               delete registry[id][eventName];
            }
            delete registry[id];
         }
      }
   }
   class Manager {
      constructor() {
         this.editor;
      }
      scan(content = document) {
         const el = content.getElementsByClassName(triggerClass)[0];
         if (!el) return;
         this.editor = new Editor(el, JSON.parse(el.dataset[dsName]));
         this.editor.render();
      }
      createRegistrar(data) { return new Registrar(data) }
   }
   return {
      manager: new Manager()
   };
})();
