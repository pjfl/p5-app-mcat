// -*- coding: utf-8; -*-
// Package HFilters.Type
HFilters.Type = (function() {
   const idCache = {};
   class Type {
      constructor(args, label) {
         this.config = args.config || {};
         this.instance = true;
      }
      apiURL(type, name, query) {
         const url = this.config['selector-uri'] || '*/*';
         const options = { requestBase: this.config['request-base'] };
         return this.createURL(url, [type, name], query, options);
      }
      createTypeContainer(name, input, typeId) {
         const id = typeId || input[0].id;
         const typeName = this.type.toLowerCase().replace(/\./g, '-');
         const typeClass = name
               ? ' ' + typeName + '-' + name.toLowerCase().replace(/\s+/g, '-')
               : '';
         const label = name ? this.h.label(
            { htmlFor: id, id: 'label-' + id }, name
         ) : null;
         return this.h.div(
            { className: 'type-container' + typeClass }, [label, ...input]
         );
      }
      forJSON() {
         const json = this.toHash();
         json.type = this.type;
         return json;
      }
      generateId(name) {
         if (!idCache[name]) idCache[name] = 0;
         return name + '-' + idCache[name]++;
      }
      timezoneOptions() {
         const options = [];
         if (Intl.Locale.prototype.getTimeZones) {
            for (const zone of Intl.Locale.prototype.getTimeZones()) {
               options.push(this.h.option({
                  selected: (this.timezone && this.timezone == zone),
                  value: zone
               }, zone));
            }
         }
         else {
            options.push(this.h.option(
               { selected: false, value: 'Antartica/Troll' }, 'Antartica/Troll'
            ));
         }
         options.unshift(this.h.option({
            selected: (this.timezone == ''), value: ''
         }, 'System Timezone'));
         return options;
      }
   }
   Object.assign(Type.prototype, HFilters.Util.Bitch);
   Object.assign(Type.prototype, HFilters.Util.Markup);
   Object.assign(Type.prototype, HFilters.Util.String);
   Object.assign(Type.prototype, HFilters.Util.URL);
   class TypeDate extends Type {
      constructor(args, label) {
         super(args, label);
         this.date = null;
         this.dateType = null;
         this.group = args['group'];
         this.label = label;
         this.type = 'Type.Date';
         const { type = 'Type.Date.NoDate' } = args;
         if (type == 'Type.Date.Absolute'
             || type == 'Type.Date.Relative'
             || type == 'Type.Date.NoDate') {
            this.dateType = type;
            const dateTypeClass = type.replace(/\./g, '');
            this.date = eval('new ' + dateTypeClass + '(args, label)');
         }
      }
      forJSON() {
         if (!this.date) return null;
         return this.date.forJSON();
      }
      isValid() {
         return this.date ? this.date.isValid() : false;
      }
      render() {
         return this.createTypeContainer(this.label, this.renderInput());
      }
      renderInput() {
         this.dateType = this.dateType || 'Type.Date.NoDate';
         const { dateType } = this;
         this.input = this.h.select({
            className: 'type-date-input type-field',
            onchange: function(event) {
               this.dateType = this.input.value;
               this.updateDisplay();
            }.bind(this)
         }, [
            this.h.option({
               selected: dateType == 'Type.Date.NoDate' ? 'selected' : '',
               value: 'Type.Date.NoDate'
            }, '- Choose -'),
            this.h.option({
               selected: dateType == 'Type.Date.Relative' ? 'selected' : '',
               value: 'Type.Date.Relative'
            }, '"Today\'s" Date'),
            this.h.option({
               selected: dateType == 'Type.Date.Absolute' ? 'selected' : '',
               value: 'Type.Date.Absolute'
            }, 'Fixed Date')
         ]);
         this.dateContainer = this.h.div({ className: 'type-date-container' });
         this.updateDisplay();
         return [this.input, this.dateContainer];
      }
      toDisplay() {
         return this.date ? this.date.toDisplay() : '<no date selected>';
      }
      toHash() {
         return this.date ? this.date.toHash() : { type: this.type };
      }
      toString() {
         return this.date ? this.date.toString() : '';
      }
      update() {
         this.date.update();
      }
      updateDisplay() {
         const dateTypeClass = this.dateType.replace(/\./g, '');
         if (!this.date || this.date.type != this.dateType)
            this.date = eval('new ' + dateTypeClass + '({}, "")');
         this.dateContainer.innerHTML = '';
         this.dateContainer.appendChild(this.date.render());
      }
   }
   class TypeDateNoDate extends Type {
      constructor(args, label) {
         super(args, label);
         this.label = label;
         this.fields = [];
         this.type = 'Type.Date.NoDate';
      }
      forJSON() {
         return this.toHash();
      }
      isValid() {
         return false;
      }
      render() {
         return this.renderInput();
      }
      renderInput() {
         return this.h.span();
      }
      toDisplay() {
         return '<no date selected>';
      }
      toHash() {
         return { type: this.type };
      }
      toString() {
         return '';
      }
      update() {
      }
   }
   class TypeDateAbsolute extends Type {
      constructor(args, label) {
         super(args, label);
         const { date = '' } = args;
         this.date = new Date(date.replace(/\-/g, '/'));
         this.label = label;
         this.retentionPeriod = this.config['data-retention'] || 12;
         this.showRetention = this.config['show-retention-notice'];
         this.timezone = args['timezone'];
         this.type = 'Type.Date.Absolute';
      }
      forJSON() {
         return this.toHash();
      }
      getRetentionPeriodMessage() {
         return this.retentionPeriod + ' months';
      }
      getRetentionTimestamp() {
         const now = new Date();
         return now.setMonth(now.getMonth() - this.retentionPeriod);
      }
      isTooOld(inputDate) {
         if (!this.showRetention) return false;
         return inputDate.getTime() <= this.getRetentionTimestamp();
      }
      isValid() {
         return !(this.date == 'Invalid Date');
      }
      render() {
         return this.createTypeContainer(this.label, this.renderInput());
      }
      renderInput() {
         const placeHolder = 'YYYY-MM-DD';
         this.input = this.h.input({
            className: 'type-date-absolute type-field-date',
            id: this.generateId('type-field-date'),
            onblur: function(event) {
               if (this.input.value == '') this.input.value = placeHolder;
            }.bind(this),
            type: 'text',
            value: this.toDateString() || placeHolder
         });
         this.timezoneSelect = this.h.select({
            className: 'type-date-absolute type-field-timezone',
            id: this.generateId('type-timezone'),
            onchange: function(event) {
               this.timezone = this.timezoneSelect.value
            }.bind(this)
         }, this.timezoneOptions());
         const tzContainer = this.createTypeContainer(
            'Time zone', [this.timezoneSelect]
         );
         return [this.input, tzContainer];
      }
      toDateString() {
         if (!this.isValid()) return null;
         return [
            this.date.getFullYear(),
            this.padString(this.date.getMonth() + 1, 2, '0'),
            this.padString(this.date.getDate(), 2, '0')
         ].join('-');
      }
      toDisplay() {
         return this.isValid() ? this.toString() : '<not defined>';
      }
      toHash() {
         const hash = { date: this.toDateString(), type: this.type };
         if (this.timezone) hash['timezone'] = this.timezone;
         return hash;
      }
      toString() {
         const dateString = this.toDateString();
         if (dateString && this.timezone)
            return dateString + ' ' + this.timezone;
         return dateString || '';
      }
      update() {
         const date = this.input.value.replace(/[\s\-]+/g, '/');
         if (!date.match(/^\d{4}\/\d\d\/\d\d$/)) {
            this.date = new Date('');
            window.alert('Dates must be in YYYY-MM-DD format');
            throw 'Bad date format';
         }
         else {
            this.date = new Date(date);
            if (this.isTooOld(this.date)) window.alert(
               'Date too old. Outside retention period '
                  + this.getRetentionMessage()
            );
         }
      }
   }
   class TypeDateRelative extends Type {
      constructor(args, label) {
         super(args, label);
         this.days = args['days'];
         this.inputs = {};
         this.label = label;
         this.months = args['months'];
         this.past = args['past'] == null ? true : !!args['past'];
         this.retentionPeriod = this.config['data-retention'] || 12;
         this.showRetention = this.config['show-retention-notice'];
         this.timezone = args['timezone'] || '';
         this.type = 'Type.Date.Relative';
         this.years = args['year'];
      }
      forJSON() {
         return this.toHash();
      }
      getRetentionPeriodMessage() {
         return this.retentionPeriod + ' months';
      }
      getRetentionTimestamp() {
         const now = new Date();
         return now.setMonth(now.getMonth() - this.retentionPeriod);
      }
      isTooOld() {
         if (!this.showRetention) return false;
         let days = +this.inputs.years.value * 365;
         days += +this.inputs.months.value * 30;
         days += +this.inputs.days.value;
         days -= 3; // Avoids knowing # of days per month
         const now = new Date();
         const chosenDate = now.setDate(now.getDate() - days);
         return chosenDate <= this.getRetentionTimestamp();
      }
      isValid() {
         return true;
      }
      render() {
         return this.h.div({
            className: 'type-date-relative'
         }, this.renderInput());
      }
      renderInput() {
         const els = [];
         this.timezoneSelect = this.h.select({
            className: 'type-date-relative type-field-timezone',
            id: this.generateId('type-timezone'),
            onchange: function(event) {
               this.timezone = this.timezoneSelect.value
            }.bind(this)
         }, this.timezoneOptions());
         els.push(this.createTypeContainer('Time zone', [this.timezoneSelect]));
         this.inputs.past = this.h.select({
            id: this.generateId('type-field')
         }, [
            this.h.option({ selected: this.past, value: '1' }, 'Today minus...'),
            this.h.option({ selected: !this.past, value: '0' }, 'Today plus...')
         ]);
         els.push(
            this.createTypeContainer('Date Modification', [this.inputs.past])
         );
         ['years', 'months', 'days'].forEach(function(name) {
            els.push(this._createField(name));
         }.bind(this));
         return els;
      }
      toDisplay() {
         let string = this.toIntervalArray().join(', ');
         if (string)
            string = 'Today ' + (this.past ? 'minus ' : ' plus ') + string;
         else string = 'Today';
         if (this.timezone) string += ' (' + this.timezone + ')';
         return string;
      }
      toHash() {
         const hash = {
            days: this.days || 0,
            months: this.months || 0,
            past: this.past,
            type: this.type,
            years: this.years || 0
         };
         if (this.timezone) hash['timezone'] = this.timezone;
         return hash;
      }
      toIntervalArray() {
         const els = [];
         ['years', 'months', 'days'].forEach(function(name) {
            const field = this._toStringField(name);
            if (field.match(/^[^0]/)) els.push(field);
         }.bind(this));
         return els;
      }
      toString() {
         const prefix = this.past ? '-' : '+';
         return this.toIntervalArray()
            .map(function(n) { return prefix + n }).join(' ');
      }
      update() {
         this.past = !!+this.inputs.past.value;
         this.years = +this.inputs.years.value || 0;
         this.months = +this.inputs.months.value || 0;
         this.day = +this.input.days.value || 0;
         if (this.past && this.isTooOld()) window.alert(
            'Date too old. Outside retention period '
               + this.getRetentionMessage()
         );
      }
      _createField(name) {
         var inputId = this.generateId('type-' + name);
         this.inputs[name] = this.h.input({
            className: 'type-date-relative-' + name + ' type-field',
            id: inputId,
            type: 'text',
            value: this[name] || 0
         });
         return this.createTypeContainer(
            this.capitalise(name), [this.inputs[name]]
         );
      }
      _toStringField(name) {
         let out = '';
         if (this[name]) {
            out += this[name] + ' ' + name;
            if (this[name] == 1) out = out.replace(/s$/, '');
         }
         return out;
      }
   }
   class TypeField extends Type {
      constructor(args, label) {
         super(args, label);
         this.fieldName = args['name'];
         this.label = label;
         this.tableId = args['table-id'];
         this.type = 'Type.Field';
         const query = { table_id: this.tableId || this.config['table-id'] };
         this.selectorURL = this.apiURL('selector', 'field', query);
      }
      isValid() {
         return !!this.fieldName;
      }
      render() {
         return this.createTypeContainer(
            this.label, this.renderInput(), this.input.id
         );
      }
      renderInput() {
         this.input = this.h.input({
            className: 'type-string-input type-field',
            id: this.generateId('type-field'),
            type: 'text',
            value: this.toString()
         });
         this.input.setAttribute('readonly', true);
         const button = this.h.button({
            className: 'type-field-button',
            onclick: function(event) { this._clickHandler() }.bind(this)
         }, '...');
         return [button, this.input];
      }
      toDisplay() {
         if (!this.fieldName) return '<no field selected>';
         return this.toString();
      }
      toHash() {
         const hash = {};
         if (this.fieldName) hash['name'] = this.fieldName;
         if (this.tableId) hash['table-id'] = this.tableId;
         return hash;
      }
      toString() {
         if (this.tableId && this.fieldName)
            return this.tableId + '.' + this.fieldName;
         return this.fieldName || '';
      }
      update() {
         const values = this.input.value.split(/\./);
         this.fieldName = values.pop();
         this.tableId = values.pop();
      }
      _clickHandler() {
         const callback = function(data) {
            this.input.value = data.value
         }.bind(this);
         HFilters.Modal.create({
            callback: function(ok, popup, data) { if (ok) callback(data) },
            cancelCallback: function() {},
            initValue: null,
            title: 'Select Field',
            url: this.selectorURL
         });
      }
   }
   class TypeList extends Type {
      constructor(args, label) {
         super(args, label);
         this.label = label;
         this.listId = args['list_id'];
         this.type = 'Type.List';
         const query = { table_id: this.config['table-id'] };
         this.selectorURL = this.apiURL('selector', 'list', query);
      }
      isValid() {
         return !!this.listId
      }
      render() {
         return this.createTypeContainer(
            this.label, this.renderInput(), this.input.id
         );
      }
      renderInput() {
         this.input = this.h.input({
            className: 'type-string-input type-list',
            id: this.generateId('type-list'),
            type: 'hidden',
            value: this.toString()
         });
         this.display = this.h.div({ className: 'type-list-display' });
         const callback = function(data) {
            this.input.value = data.value;
            this.updateListDisplay(data.value);
         }.bind(this);
         const button = this.h.button({
            className: 'type-list-button',
            onclick: function(event) {
               HFilters.Modal.create({
                  callback: function(ok, popup, data) { if (ok) callback(data)},
                  cancelCallback: function() {},
                  init_value: null,
                  title: 'List',
                  url: this.selectorURL
               });
            }.bind(this)
         }, '...');
         if (this.listId) this.updateListDisplay(this.listId);
         return [button, this.display, this.input];
      }
      toDisplay() {
         if (!this.listId) return '<no list selected>';
         return this.listName + ' (' + this.listId + ')';
      }
      toHash() {
         return { list_id: this.listId };
      }
      toString() {
         return this.listId || '';
      }
      update() {
         this.listId = this.input.value;
      }
      async updateListDisplay(listId) {
         const url = this.apiURL('get', 'list', { list_id: listId });
         const { object } = await this.bitch.sucks(url);
         this.listId = listId;
         this.listName = object['name'];
         this.display.innerHTML = '';
         this.display.appendChild(document.createTextNode(this.toDisplay()));
      }
      async updateRuleBox(el) {
         const url = this.apiURL('get', 'list', { list_id: this.listId });
         const { object } = await this.bitch.sucks(url);
         this.listName = object['name'];
         el.innerHTML = '';
         el.appendChild(document.createTextNode(this.toDisplay()));
      }
   }
   class TypeNegate extends Type {
      constructor(args, label) {
         super(args, label);
         this.label = '';
         this.negate = args['negate'] ? true : false;
         this.type = 'Type.Negate';
      }
      isNegated() {
         return this.negate;
      }
      isValid() {
         return true;
      }
      render() {
         return this.createTypeContainer(this.label, this.renderInput());
      }
      renderInput() {
         const inputId = this.generateId('type-checkbox');
         const label = this.h.label({
            className: 'type-negate', 'for': inputId
         }, 'Negate rule');
         this.input = this.h.input({
            checked: this.negate,
            className: 'type-checkbox type-negate', id: inputId,
            type: 'checkbox', value: 1
         });
         return [this.input, label];
      }
      toDisplay() {
         return this.toString();
      }
      toHash() {
         return { negate: this.negate };
      }
      toString() {
         return this.negate ? 'not' : '';
      }
      update() {
         this.negate = this.input.checked;
      }
   }
   class TypeRuleType extends Type {
      constructor(args, label) {
         super(args, label);
         this.fields = [];
         this.label = label;
         this.rule = args['rule'];
         this.ruleType = args['ruleType'];
         this.type = 'Type.RuleType';
      }
      filterRules(parentRuleClassName) {
         const className = parentRuleClassName.replace(/\./g, '');
         const classes = [];
         for (const item of HFilters.Node.subclasses(className, true)) {
            if (item.hidden && item.hidden()) continue;
            classes.push({ label: item.label, type: item.type });
         }
         return classes;
      }
      filterRuleTypes() {
         const types = [];
         for (const item of HFilters.Node.subclasses('Rule')) {
            if (item.notSelectable && item.notSelectable()) continue;
            types.push({ label: item.label, type: item.type });
         }
         return types;
      }
      isValid() {
         return false;
      }
      render() {
         this.ruleSelectorContainer = this.h.div(this.renderInput());
         return this.h.div({ className: 'node-rule-edit-content' }, [
            this.createTypeContainer('Rule category', [this.ruleTypeSelector]),
            this.ruleSelectorContainer
         ]);
      }
      renderInput() {
         this.rule = null;
         this.ruleType = null;
         const options = [ this.h.option({ value: '' }, '- Choose -') ];
         for (const item of this.filterRuleTypes()) {
            options.push(this.h.option({ value: item.type }, item.label));
         };
         this.ruleTypeSelector = this.h.select({
            className: 'type-ruletype type-ruletype-ruleclass',
            onchange: function(ev) { this.updateRuleTypeSelector() }.bind(this)
         }, options);
         return this.ruleTypeSelector;
      }
      toDisplay() {
         return '';
      }
      toHash() {
         return {};
      }
      toString() {
         return '';
      }
      update() {
         if (this.ruleSelector && this.ruleSelector.value)
            this.rule = this.ruleSelector.value;
      }
      updateRuleTypeSelector() {
         if (!this.ruleTypeSelector.value) return;
         this.ruleSelectorContainer.innerHTML = '';
         const options = [];
         for (const item of this.filterRules(this.ruleTypeSelector.value)) {
            options.push(this.h.option({ value: item.type }, item.label));
         }
         this.ruleSelector = this.h.select({
            className: 'type-ruletype type-ruletype-rule'
         }, options);
         this.ruleSelectorContainer.appendChild(
            this.createTypeContainer('Rule type', [this.ruleSelector])
         );
      }
   }
   class TypeString extends Type {
      constructor(args, label) {
         super(args, label);
         this.label = label || 'Text';
         this.string = args['string'];
         this.type = 'Type.String';
      }
      isValid() {
         return true;
      }
      render() {
         return this.createTypeContainer(this.label, [this.renderInput()]);
      }
      renderInput() {
         this.input = this.h.input({
            className: 'type-string-input type-string',
            id : this.generateId('type-string'),
            type: 'text',
            value: this.toString()
         });
         return this.input;
      }
      toDisplay() {
         if (!this.string) return '<empty>';
         return '"' + this.toString() + '"';
      }
      toHash() {
         return { string: this.toString() };
      }
      toString() {
         return this.string || '';
      }
      update() {
         this.string = this.input.value;
      }
   }
   class TypeMultiString extends TypeString {
      constructor(args, label) {
         super(args, label);
         this.type = 'Type.MultiString';
      }
      renderInput() {
         const lines = this.string ? this.string.split(/\n+/) : [];
         const strings = [];
         for (const line of lines)
            strings.push(line.replace(/^\s+|\s+$/g, ''));
         const value = lines.length
            ? strings.join('\n').replace(/(\r\n|\r|\n)/g, '\r\n') : '';
         return this.input({
            className: 'type-string-input type-multistring',
            id: this.generateId('type-multistring'),
            onkeypress: function(event) { event.ignoreKeyPress = true },
            value: value
         });
      }
      toDisplay() {
         const values = this.values();
         const displayed = [];
         let count = 0;
         while (count < 20 && values.length) {
            const value = values.shift();
            count += value.length;
            displayed.push('"' + val + '"');
         }
         const string = displayed.join(', ');
         if (values.length) string += ' and ' + values.length + ' more.';
         if (!string) return '<none>';
         return string;
      }
      values() {
         return this.toString().replace(/^\s+|\s+$/g, '').split(/\n+/);
      }
   }
   class TypeNumeric extends TypeString {
      constructor(args, label) {
         super(args, label);
         this.type = 'Type.Numeric';
      }
      isValid() {
         return !Number.isNaN(parseFloat(this.string)) && isFinite(this.string);
      }
   }
   class TypeNumericRange extends Type {
      constructor(args, label) {
         super(args, label);
         this.group = args['group'];
         this.inputs = {};
         this.label = label || 'Range';
         this.maxValue = args['max_value'] || '';
         this.minValue = args['min_value'] || '';
         this.type = 'Type.NumericRange';
      }
      render() {
         return this.createTypeContainer(this.label, [this.renderInput()]);
      }
      renderInput() {
         for (const name of ['min', 'max']) {
            this.inputs[name] = this.h.input({
               className: 'type-numeric-range type-field',
               id: this.generateId('type-numeric'),
               type: 'text',
               value: name = 'max' ? this.maxValue : this.minValue
            });
         }
         return this.h.div({ id: this.inputs.min.id }, [
            'Min: ', this.inputs.min, ' Max: ', this.inputs.max
         ]);
      }
      toHash() {
         return {
            max_value: this.max_value || null,
            min_value: this.min_value || null
         };
      }
      update() {
         this.maxValue = this.inputs.max.value;
         this.minValue = this.inputs.min.value;
      }
   }
   return {
      create: function(type, args = {}) {
         const { label } = args;
         return eval('new ' + type.replace(/\./g, '') + '(args, label)');
      }
   }
})();
