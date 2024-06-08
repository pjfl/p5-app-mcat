// -*- coding: utf-8; -*-
// Package WCom.Filters.Node
WCom.Filters.Node = (function() {
   const filterEditor = WCom.Filters.Editor.manager;
   const classes = [];
   classes.push('Node');
   class Node {
      constructor(data) {
         this.config = data.config;
         this.instance = true;
      }
      nukeNode(properties) {
         for (const property of properties) {
            if (this[property] && this[property].parentNode) {
               this[property].parentNode.removeChild(this[property]);
               delete this[property];
            }
         }
      }
   }
   Object.assign(Node.prototype, WCom.Util.Markup);
   classes.push('Logic');
   class Logic extends Node {
      constructor(data) {
         super(data);
         this.nodes = [];
         this.registry = filterEditor.createRegistrar(
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
            if (node.type.match(/^Rule/)) return true;
         }
         return false;
      }
      toString() {
         return this.type ? this.type : 'Logic';
      }
      unrender() {
         this.nukeNode(['addEl', 'el', 'addAnd', 'addOr']);
      }
   }
   classes.push('LogicAnd');
   class LogicAnd extends Logic {
      constructor(data) {
         super(data);
         this.type = 'Logic.And';
      }
      render() {
         this.el = this.h.div({ className: 'node-logic-and-container' });
         this.addEl = this.h.div({
            className: 'node-logic-and-add',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addclick', this);
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
   classes.push('LogicContainer');
   class LogicContainer extends Logic {
      constructor(data) {
         super(data);
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
               this.registry.fire('addwrapclick', this, 'Logic.And');
            }.bind(this),
            title: 'AND'
         });
         this.addOr = this.h.div({
            className: 'node-logic-container-add-or',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addwrapclick', this, 'Logic.Or');
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
   classes.push('LogicOr');
   class LogicOr extends Logic {
      constructor(data) {
         super(data);
         this.type = 'Logic.Or';
      }
      render() {
         this.el = this.h.div({ className: 'node-logic-or-container' });
         this.addEl = this.h.div({
            className: 'node-logic-or-add',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addclick', this);
            }.bind(this)
         });
         this.update();
         return this.el;
      }
      update() {
         this.el.innerHTML = '';
         if (!this.hasSingleNode()) this.el.appendChild(this.addEl);
         const attr = { className: 'node-logic-or' };
         const tbody = this.h.tbody(this._contentRows());
         this.el.appendChild(this.h.table(attr, tbody));
      }
      _edgeCells() {
         const cells = [];
         for (const node of this.nodes) {
            cells.push(this.h.th({ className: 'node-logic-or-edge-center' }));
         };
         if (cells.length == 1) {
            cells[0].className = 'node-logic-or-edge-single';
         }
         else {
            cells[0].className = 'node-logic-or-edge-left';
            cells[cells.length - 1].className = 'node-logic-or-edge-right';
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
   classes.push('Rule');
   class Rule extends Node {
      constructor(data) {
         super(data);
         this.registry = filterEditor.createRegistrar(
            ['addruleclick', 'editorsave', 'nodeclick', 'removeruleclick']
         );
         this.data = {};
         this.fields = data.fields;
         this.label = data.label;
         this.type = data.type;
         this.warning = 'Incomplete Rule';
         if (this.setup) this.setup();
         for (const name in this.fields) {
            if (data[name] && data[name].instance) {
               this.data[name] = data[name];
            }
            else {
               const fieldObject = this.fields[name];
               const type = 'Type.' + fieldObject.type;
               const args = data[name] || {};
               args.config = this.config;
               args.dataType = fieldObject.dataType;
               args.group = fieldObject.group;
               args.hidden = fieldObject.hidden;
               args.inputType = fieldObject.inputType;
               args.label = fieldObject.label;
               args.matchRadio = fieldObject.matchRadio;
               args.node = this;
               this.data[name] = WCom.Filters.Type.create(type, args);
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
      isEmpty() {
         return false;
      }
      isValid() {
         this.warning = 'Invalid rule';
         for (const name in this.fields) {
            if (!this.data[name].isValid()) return false;
         }
         return true;
      }
      nodeClick() {
         if (filterEditor.editor.treeDragged) return;
         this.registry.fire('nodeclick', this);
      }
      notSelectable() {
         return false;
      }
      render() {
         this.inner = this.h.div({
            className: 'node-rule-box-inner',
            onclick: function(event) {
               if (event.target.className == 'node-rule-remove-button') return;
               this.nodeClick();
            }.bind(this)
         });
         this.el = this.h.div({ className: 'node-rule-box' }, this.inner);
         this.renderRuleManagement();
         this.update();
         const classStatus = this.isEmpty() ? ' empty' : '';
         this.wrapper = this.h.div(
            { className: 'node-rule-wrapper' + classStatus }, this.el
         );
         return this.wrapper;
      }
      renderRuleBox(contents = []) {
         this.title = this.h.div({ className: 'node-rule-title' }, this.label);
         this.removeEl = this.h.span({
            className: 'node-rule-remove-button',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('removeruleclick', this);
            }.bind(this)
         }, '×');
         const titleWrapper = this.h.div({
            className: 'node-rule-title-wrapper'
         }, [this.title, this.removeEl]);
         this.status = this.h.div({
            className: 'node-rule-status'
         }, this.warning);
         const box = this.h.div({
            className: 'rule-string'
         }, [titleWrapper, this.status, ...contents]);
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
               this.registry.fire('addruleclick', this, 'Logic.Or');
            }.bind(this),
            title: 'OR'
         });
         this.el.appendChild(this.addOr);
         this.addAnd = this.h.div({
            className: 'node-rule-add-and',
            onclick: function(event) {
               event.preventDefault();
               this.registry.fire('addruleclick', this, 'Logic.And');
            }.bind(this),
            title: 'AND'
         });
         this.el.appendChild(this.addAnd);
      }
      select() {
         if (this.el) this.el.id = 'node-selected';
      }
      toString() {
         return this.type ? this.type : 'Unknown Rule';
      }
      unrender() {
         this.nukeNode(['el', 'inner', 'addOr', 'addAnd']);
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
         for (const name in this.fields) {
            try { this.data[name].update() }
            catch(e) {
               console.warn(`Rule update failed: ${e}`);
               error = true;
            }
         }
         return error ? false : true;
      }
   }
   classes.push('RuleData');
   class RuleData extends Rule {
      constructor(data) {
         data.fields ||= { negate: { label: 'Inverse', type: 'Negate' } };
         data.label  ||= 'Data match';
         data.type   ||= 'Rule.Data';
         super(data);
      }
      renderContent() {
         return this.renderRuleBox([
            this.h.div({
               className: 'type-negate'
            }, this.data.negate.isNegated() ? 'Item is not' : 'Item is'),
            this.h.div({ className: 'type-event' }, this.actionName)
         ]);
      }
   }
   classes.push('RuleDataInList');
   class RuleDataInList extends RuleData {
      constructor(data) {
         data.fields ||= {
            list:   { label: 'List', type: 'List' },
            negate: { label: 'Inverse', type: 'Negate' }
         };
         data.label ||= 'In List';
         data.type  ||= 'Rule.Data.InList';
         super(data);
         this.actionName = 'in list';
      }
      renderContent() {
         const listDisplay = this.h.div({ className: 'type-list' });
         this.data.list.updateRuleBox(listDisplay);
         return this.renderRuleBox([
            this.h.div({
               className: 'type-negate'
            }, this.data.negate.isNegated() ? 'Item is not' : 'Item is'),
            this.h.div({ className: 'type-event' }, this.actionName),
            listDisplay
         ]);
      }
   }
   classes.push('RuleDate');
   class RuleDate extends Rule {
      constructor(data) {
         data.fields ||= {
            date:   { label: 'Date', type: 'Date' },
            field:  { label: 'Field', type: 'Field', dataType: 'datetime' },
            negate: { label: 'Inverse', type: 'Negate' }
         };
         data.label ||= 'Date match';
         data.type  ||= 'Rule.Date';
         super(data);
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox([
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-operation' }, this.getBoxString()),
            this.h.div({ className: 'type-date' }, data.date.toDisplay())
         ]);
      }
   }
   classes.push('RuleDateAnniversary');
   class RuleDateAnniversary extends RuleDate {
      constructor(data) {
         data.label ||= 'Anniverary';
         data.type ||= 'Rule.Date.Anniversary';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'anniversary is not' : 'has anniversary';
      }
   }
   classes.push('RuleDateBefore');
   class RuleDateBefore extends RuleDate {
      constructor(data) {
         data.fields ||= {
            date:  { label: 'Date', type: 'Date' },
            field: { label: 'Field', type: 'Field', dataType: 'datetime' }
         };
         data.label ||= 'Date is before';
         data.type ||= 'Rule.Date.Before';
         super(data);
      }
      getBoxString() {
         return 'is before';
      }
   }
   classes.push('RuleDateAfter');
   class RuleDateAfter extends RuleDate {
      constructor(data) {
         data.fields ||= {
            date:  { label: 'Date', type: 'Date' },
            field: { label: 'Field', type: 'Field', dataType: 'datetime' }
         };
         data.label ||= 'Date is after';
         data.type ||= 'Rule.Date.After';
         super(data);
      }
      getBoxString() {
         return 'is after';
      }
   }
   classes.push('RuleDateEquals');
   class RuleDateEquals extends RuleDate {
      constructor(data) {
         data.label ||= 'Date is equal';
         data.type ||= 'Rule.Date.Equals';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not equal to' : 'is equal to';
      }
   }
   classes.push('RuleEmpty');
   class RuleEmpty extends Rule {
      constructor(data) {
         data.fields ||= { ruleType: { label: 'Rule Type', type: 'RuleType' } };
         data.label ||= 'New rule';
         data.type ||= 'Rule.Empty';
         super(data);
      }
      editorSave() {
         this.registry.fire('editorsave', this, this.data.ruleType.rule);
      }
      isEmpty() {
         return true;
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
   classes.push('RuleNumeric');
   class RuleNumeric extends Rule {
      constructor(data) {
         data.fields ||= {
            field:  { label: 'Field', type: 'Field', dataType: 'numeric' },
            number: { label: 'Value', type: 'Numeric' }
         };
         data.label ||= 'Field numeric match';
         data.type ||= 'Rule.Numeric';
         super(data);
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox([
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString()),
            this.h.div({ className: 'type-string' }, data.number.toDisplay())
         ]);
      }
   }
   classes.push('RuleNumericEqualTo');
   class RuleNumericEqualTo extends RuleNumeric {
      constructor(data) {
         data.label ||= 'Field equals';
         data.type ||= 'Rule.Numeric.EqualTo';
         super(data);
      }
      getBoxString() {
         return 'equal to';
      }
   }
   classes.push('RuleNumericLessThan');
   class RuleNumericLessThan extends RuleNumeric {
      constructor(data) {
         data.label ||= 'Field less than';
         data.type ||= 'Rule.Numeric.LessThan';
         super(data);
      }
      getBoxString() {
         return 'less than';
      }
   }
   classes.push('RuleNumericGreaterThan');
   class RuleNumericGreaterThan extends RuleNumeric {
      constructor(data) {
         data.label ||= 'Field greater than';
         data.type ||= 'Rule.Numeric.GreaterThan';
         super(data);
      }
      getBoxString() {
         return 'greater than';
      }
   }
   classes.push('RuleString');
   class RuleString extends Rule {
      constructor(data) {
         data.fields ||= {
            field:  { label: 'Field', type: 'Field', dataType: 'text' },
            negate: { label: 'Inverse', type: 'Negate' },
            string: { label: 'Match text', type: 'String' }
         };
         data.label ||= 'Field text match';
         data.type ||= 'Rule.String';
         super(data);
      }
      renderContent() {
         const data = this.data;
         return this.renderRuleBox([
            this.h.div({ className: 'type-field' }, data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString()),
            this.h.div({ className: 'type-string' }, data.string.toDisplay())
         ]);
      }
   }
   classes.push('RuleStringBegins');
   class RuleStringBegins extends RuleString {
      constructor(data) {
         data.label ||= 'Field begins with';
         data.type ||= 'Rule.String.Begins';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not begin with' : 'begins with';
      }
   }
   classes.push('RuleStringContains');
   class RuleStringContains extends RuleString {
      constructor(data) {
         data.label ||= 'Field contains';
         data.type ||= 'Rule.String.Contains';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not contain' : 'contains';
      }
   }
   classes.push('RuleStringEnds');
   class RuleStringEnds extends RuleString {
      constructor(data) {
         data.label ||= 'Field ends with';
         data.type ||= 'Rule.String.Ends';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'does not end with' : 'ends with';
      }
   }
   classes.push('RuleStringEquals');
   class RuleStringEquals extends RuleString {
      constructor(data) {
         data.label ||= 'Field equals';
         data.type ||= 'Rule.String.Equals';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'not equal to' : 'equal to';
      }
   }
   classes.push('RuleStringIsEmpty');
   class RuleStringIsEmpty extends RuleString {
      constructor(data) {
         data.fields ||= {
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' }
         };
         data.label ||= 'Field is empty';
         data.type ||= 'Rule.String.IsEmpty';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not empty' : 'is empty';
      }
      renderContent() {
         return this.renderRuleBox([
            this.h.div({ className: 'type-field' }, this.data.field.toDisplay()),
            this.h.div({ className: 'type-name' }, this.getBoxString())
         ]);
      }
   }
   classes.push('RuleStringList');
   class RuleStringList extends RuleString {
      constructor(data) {
         data.fields ||= {
            field:  { label: 'Field', type: 'Field' },
            negate: { label: 'Inverse', type: 'Negate' },
            string: { label: 'Match text (one per line)', type: 'MultiString' }
         };
         data.label ||= 'Field matches list';
         data.type ||= 'Rule.String.List';
         super(data);
      }
      getBoxString() {
         return this.data.negate.isNegated() ? 'is not one of' : 'is one of';
      }
   }
   return {
      create: function(args) {
         const { type } = args;
         delete args.type;
         return eval('new ' + type.replace(/\./g, '') + '(args)');
      },
      subclasses: function(baseClass, all = false) {
         const subclasses = [];
         const end = all ? '' : '$';
         const re = new RegExp('^' + baseClass + '[A-Z][a-z]+' + end);
         for (const className of classes) {
            if (className.match(re)) {
               subclasses.push(eval('new ' + className + '({})'));
            }
         }
         return subclasses;
      }
   }
})();
