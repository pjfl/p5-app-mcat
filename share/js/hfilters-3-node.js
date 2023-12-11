// -*- coding: utf-8; -*-
// Package HFilters.Node
HFilters.Node = (function() {
   class Node {
      constructor() {
      }
      nukeNode() {
         const object = this.apply(arguments);
         for (let i = 0, property; property = arguments[i]; i++) {
            if (object[property] && object[property].parentNode) {
               object[property].parentNode.removeChild(object[property]);
               delete object[property];
            }
         }
      }
   }
   Object.assign(Node.prototype, HFilters.Util.Markup);
   class Logic extends Node {
      constructor() {
         super();
         this.nodes = [];
         this.registry = HFilters.Editor.createRegistrar(
            ['addclick', 'addwrapclick']
         );
      }
      appendChildNode(node) {
         this.nodes.push(node);
      }
      forJSON() {
         const nodes = [];
         for (const node of this.nodes) nodes.push(node.forJSON());
         return { type: this.type, nodes: nodes };
      }
      hasSingleNode() {
         for (const node of this.nodes) {
            if (node.type.matches(/^Rule/)) return true;
         }
         return false;
      }
      toString() {
         return this.type ? this.type : 'Logic';
      }
      unrender() {
         this.nukeNode('addEl', 'el', 'addAnd', 'addOr');
      }
   }
   class LogicAnd extends Logic {
      constructor() {
         super();
         this.type = 'Logic.And';
      }
      render() {
         this.el = this.h.div({ className: 'node-logic-and-container' });
         this.addEl = this.h.div({
            className: 'node-logic-and-add',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addclick', [this]);
            }.bind(this)
         });
         this.update();
         return this.el;
      }
      update() {
         this.el.innerHTML = '';
         if (!this.hasSingleNode()) this.el.appendChild(this.addEl);
         const attr = { className: 'node-logic-and' };
         const tbody = this.h.tbody(this._contentRows());
         this.el.appendChild(this.h.table(attr, tbody));
      }
      _contentRows() {
         const rows = [];
         const attr = { className: 'node-logic-and-cell' };
         for (const node of this.nodes)
            rows.push(this.h.tr(this.h.td(attr, node.render())));
         return rows;
      }
   }
   class LogicContainer extends Logic {
      constructor() {
         super();
         this.type = 'Logic.Container';
      }
      appendChildNode(node) {
         if (this.nodes.length >= 1)
            throw 'Containers can only have a single node';
         this.nodes.push(node);
      }
      render() {
         this.el = this.h.div({ className: 'node-logic-container-container' });
         this.addAnd = this.h.div({
            className: 'node-logic-container-add-and',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addwrapclick', [this, 'Logic.And']);
            }.bind(this),
            title: 'AND'
         });
         this.addOr = this.h.div({
            className: 'node-logic-container-add-or',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addwrapclick', [this, 'Logic.Or']);
            }.bind(this),
            title: 'OR'
         });
         this.update();
         return this.el;
      }
      update() {
         this.el.innerHTML = '';
         const node = this.nodes[0];
         this.el.appendChild(node.render());
         if (node.type == 'Logic.Or') this.el.appendChild(this.addAnd);
         if (node.type == 'Logic.And') this.el.appendChild(this.addOr);
      }
   }
   class LogicOr extends Logic {
      constructor() {
         super();
         this.type = 'Logic.Or';
      }
      render() {
         this.el = this.h.div({ className: 'node-logic-or-container' });
         this.addEl = this.h.div({
            className: 'node-logic-or-add',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addclick', [this]);
            }.bind(this)
         });
         this.update();
         return this.el;
      }
      update() {
         this.el.innerHTML = '';
         if (!this.hasSingleNode()) this.el.appendChild(this.addEl);
         this.el.appendChild();
         const attr = { className: 'node-logic-or' };
         const tbody = this.h.tbody(this._contentRows());
         this.el.appendChild(this.h.table(attr, tbody));
      }
      _edgeCells() {
         const cells = [];
         this.nodes.length.times(function() {
            cells.push(this.h.th({ className: 'node-logic-or-edge-center' }));
         }.bind(this));
         if (cells.length == 1) {
            cells[0].className = 'node-logic-or-edge-single';
         }
         else {
            cells.first().className = 'node-logic-or-edge-left';
            cells.last().className = 'node-logic-or-edge-right';
         }
         return cells;
      }
      _contentCells() {
         const attr = { className: 'node-logic-or-cell' };
         return this.nodes.map(function(item) {
            return this.h.td(attr, item.render());
         }.bind(this));
      }
      _contentRows() {
         return [
            this.h.tr({
               className: 'node-logic-or-row-top' }, this._edgeCells()),
            this.h.tr({
               className: 'node-logic-or-row-center' }, this._contentCells()),
            this.h.tr({
               className: 'node-logic-or-row-bottom' }, this._edgeCells())
         ];
      }
   }
   class Rule extends Node {
      constructor(data) {
         super()
         this.registry = HFilters.Editor.createRegistrar(
            ['addruleclick', 'editorsave', 'nodeclick', 'removeruleclick']
         );
         this.warning = 'Incomplete Rule';
         this.data = {};
         for (const field in this.fields) {
            if (data[field] && data[field].type.matches(/^Type/)) {
               this.data[field] = data[field];
            }
            else {
               const fieldObject = this.fields[field];
               const type = 'Type.' + fieldObject.type;
               const args = data[field] || {};
               args.group = fieldObject.group;
               args.hidden = fieldObject.hidden;
               args.inputType = fieldObject.inputType;
               args.label = fieldObject.label
               args.matchRadio = fieldObject.matchRadio;
               args.name = field;
               args.node = this;
               this.data[field] = HFilters.Type.create(type, args);
            }
         }
      }
      editorCancel() {
      }
      editorSave() {
         this.update();
      }
      forJSON() {
         const json = { type: this.type };
         for (const field in this.fields) {
            if (field) json[field] = this.data[field].forJSON();
         }
         return json;
      }
      isValid() {
         this.warning = 'Invalid rule';
         for (const field in this.fields) {
            if (!this.data[field].isValid()) return false;
         }
         return true;
      }
      nodeClick() {
         if (HFilters.Editor.manager.editor.treeDragged) return;
         this.registry.fire('nodeclick', [this]);
      }
      notSelectable() {
         return false;
      }
      render() {
         this.inner = this.h.div({ className: 'node-rule-box-inner' });
         this.el = this.h.div({
            className: 'node-rule-box',
            onclick: function(event) { this.nodeClick() }.bind(this)
         }, this.inner);
         this.renderRuleManagement();
         this.update();
         this.wrapper = this.h.div({ className: 'node-rule-wrapper' }, this.el);
         return this.wrapper;
      }
      renderRuleBox() {
         const contents = Array.prototype.splice.call(arguments);
         this.title = this.h.div({ className: 'node-rule-title' }, this.label);
         this.status = this.h.div(
            { className: 'node-rule-status' }, this.warning
         );
         const box = this.h.div(
            { className: 'rule-string' }, [this.title, this.status, contents]
         );
         if (this.isValid()) {
            this.el.classList.remove('rule-error');
            this.status.innerHTML = '';
         }
         else this.el.classList.add('rule-error');
         return box;
      }
      renderRuleManagement() {
         this.addOr = this.h.div({
            className: 'node-rule-add-or',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addruleclick', [this, 'Logic.Or']);
            }.bind(this),
            title: 'OR'
         });
         this.el.appendChild(this.addOr);
         this.addAnd = this.h.div({
            className: 'node-rule-add-and',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addruleclick', [this, 'Logic.And']);
            }.bind(this),
            title: 'AND'
         });
         this.el.appendChild(this.addAnd);
         this.removeEl = this.h.div({
            className: 'node-rule-remove',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('removeruleclick', [this]);
            }.bind(this)
         }, '×');
         this.el.appendChild(this.removeEl);
      }
      select() {
         if (this.el) this.el.id = 'node-selected';
      }
      toString() {
         return this.type ? this.type : 'Unknown Rule';
      }
      unrender() {
         this.nukeNode('el', 'inner', 'addOr', 'addAnd');
      }
      unselect() {
         if (this.el) this.el.id = '';
      }
      update() {
         this.inner.innerHTML = '';
         this.inner.appendChild(this.renderContent());
      }
      updateValue() {
         let error = false;
         for (const field in this.fields) {
            try { this.data[field].update() }
            catch(e) { error = true }
         }
         return error;
      }
   }
   class RuleEmpty extends Rule {
      label = 'New rule';
      type = 'Rule.Empty';
      constructor(data) {
         super(data);
         this.fields = { ruleType: { label: 'Rule Type', type: 'RuleType' } };
      }
      editorSave() {
         this.registry.fire('editorsave', [this, this.data.ruleType.rule]);
      }
      forJSON() {
         return { type: this.type };
      }
      notSelectable() {
         return true;
      }
      renderContent() {
         this.warning = 'Empty rule';
         return this.renderRuleBox();
      }
   }
   class RuleString extends Rule {
      label = 'Field text match';
      type = 'Rule.String';
      constructor(data) {
         super(data);
         this.fields = {
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' },
            string: { label: 'Match text', type: 'String' }
         };
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox(
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString()),
            this.h.div({ className: 'trpe-string' }, data.string.toDisplay())
         );
      }
   }
   class RuleStringEquals extends RuleString {
      label = 'Field equals';
      type = 'Rule.String.Equals';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'not equal to' : 'equal to';
      }
   }
   class RuleStringContains extends RuleString {
      label = 'Field contains';
      type = 'Rule.String.Contains';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not contain' : 'contains';
      }
   }
   class RuleStringBegins extends RuleString {
      label = 'Field begins with';
      type = 'Rule.String.Begins';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not begin with' : 'begins with';
      }
   }
   class RuleStringEnds extends RuleString {
      label = 'Field ends with';
      type = 'Rule.String.Ends';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not end with' : 'ends with';
      }
   }
   class RuleStringIsEmpty extends RuleString {
      label = 'Field is empty';
      type = 'Rule.String.IsEmpty';
      constructor(data) {
         super(data);
         this.fields = {
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' }
         };
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not empty' : 'is empty';
      }
      renderContent() {
         return this.renderRuleBox(
            this.h.div({ className: 'type-field' }, this.data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString())
         );
      }
   }
   class RuleStringList extends RuleString {
      label = 'Field matches list';
      type = 'Rule.String.List';
      constructor(data) {
         super(data);
         this.fields = {
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' },
            string: { label: 'Match text (one per line)', type: 'MultiString' }
         };
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not one of' : 'is one of';
      }
   }
   class RuleNumeric extends Rule {
      label = 'Field numeric match';
      type = 'Rule.Numeric';
      constructor(data) {
         super(data);
         this.fields = {
            field:  { label: 'Field', type: 'Field' },
            number: { label: 'Value', type: 'Numeric' }
         };
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox(
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString()),
            this.h.div({ className: 'type-string' }, data.number.toDisplay())
         );
      }
   }
   class RuleNumericEqualTo extends RuleNumeric {
      label = 'Field equals';
      type = 'Rule.Numeric.EqualTo'
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return 'equal to';
      }
   }
   class RuleNumericLessThan extends RuleNumeric {
      label = 'Field less than';
      type = 'Rule.Numeric.LessThan'
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return 'less than';
      }
   }
   class RuleNumericGreaterThan extends RuleNumeric {
      label = 'Field greater than';
      type = 'Rule.Numeric.GreaterThan'
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return 'greater than';
      }
   }
   class RuleDate extends Rule {
      label = 'Date match';
      type = 'Rule.Date';
      constructor(data) {
         super(data);
         this.fields = {
            date:   { label: 'Date', type: 'Date' },
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' }
         };
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox(
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-operation' }, this.getBoxString()),
            this.h.div({ className: 'type-date' }, data.date.toDisplay())
         );
      }
   }
   class RuleDateAnniversary extends RuleDate {
      label = 'Anniverary';
      type = 'Rule.Date.Anniversary';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'anniversary is not' : 'has anniversary';
      }
   }
   class RuleDateBefore extends RuleDate {
      label = 'Date is before';
      type = 'Rule.Date.Before';
      constructor(data) {
         super(data);
         this.fields = {
            date:  { label: 'Date', type: 'Date' },
            field: { label: 'Field', type: 'Field' }
         };
      }
      getBoxString() {
         return 'is before';
      }
   }
   class RuleDateAfter extends RuleDate {
      label = 'Date is after';
      type = 'Rule.Date.After';
      constructor(data) {
         super(data);
         this.fields = {
            date:  { label: 'Date', type: 'Date' },
            field: { label: 'Field', type: 'Field' }
         };
      }
      getBoxString() {
         return 'is after';
      }
   }
   class RuleDateEquals extends RuleDate {
      label = 'Date is equal';
      type = 'Rule.Date.Equals';
      constructor(data) {
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not equal to' : 'is equal to';
      }
   }
   return {
      create: function(type) {
         const className = type.replace(/\./g, '');
         return new className;
      },
      subclasses: function(baseClass) {
         const globalObject = Function('return this')();
         return Object.keys(globalObject).filter(function (key) {
            try {
               return globalObject[key].prototype instanceof baseClass
            }
            catch (e) { return false }
         });
      }
   }
})();
