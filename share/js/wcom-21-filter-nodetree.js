// -*- coding: utf-8; -*-
// Package WCom.Filters.NodeTree
WCom.Filters.NodeTree = (function() {
   const filterEditor = WCom.Filters.Editor.manager;
   class NodeTree {
      constructor(data, config) {
         this.config = config;
         this.instance = true;
         this.registry = filterEditor.createRegistrar(
            ['ruleselect', 'ruleunselect', 'ruleremove']
         );
         try { this.data = typeof data == 'string' ? JSON.parse(data) : data }
         catch(e) {}
         if (!this.data) {
            this.data = {
               type: 'Logic.Container', nodes: [{
                  type: 'Rule.Empty', ruleType: { type: 'Type.RuleType' }
               }]
            };
         }
         const nodes = this.parseNodeData([this.data]);
         this.root = nodes[0];
         window.addEventListener('unload', function() {
            this._breakCircularRefs(this.root)
         }.bind(this));
      }
      addLogicRule(logicNode) {
         const newNode = this.createEmptyNode(logicNode);
         this.appendNode(logicNode, newNode);
         logicNode.update();
         this.nodeClick(newNode);
      }
      addRule(node, type) {
         const parent = node.parentNode;
         const newNode = this.createEmptyNode(parent);
         if (parent && parent.type == type)
            this.insertNode(parent, newNode, node, 1);
         else {
            const logicNode = this.createLogicNode(type);
            this.insertNode(parent, logicNode, node, 1);
            this.appendNode(logicNode, node);
            this.appendNode(logicNode, newNode);
         }
         parent.update();
         this.nodeClick(newNode);
      }
      addWrapperRule(containerNode, type) {
         const logicNode = this.createLogicNode(type, containerNode);
         const childNode = containerNode.nodes[0];
         this.appendNode(containerNode, logicNode);
         this.appendNode(logicNode, childNode);
         const newNode = this.createEmptyNode(logicNode);
         this.appendNode(logicNode, newNode);
         containerNode.update();
         this.nodeClick(newNode);
      }
      appendNode(parent, node) {
         if (node.parentNode) this.unlinkNode(node);
         node.parentNode = parent;
         parent.nodes.push(node);
      }
      createEmptyNode(parent) {
         return this.createRuleNode({
            type: 'Rule.Empty', ruleType: { type: 'Type.RuleType' }
         }, parent);
      }
      createContainerNode(type, parent) {
         if (parent) throw 'Container nodes cannot be nested';
         const args = { config: this.config, type: 'Logic.Container' };
         const node = WCom.Filters.Node.create(args);
         node.registry.listen('addwrapclick', this.addWrapperRule, this);
         return node;
      }
      createLogicNode(type, parent) {
         const args = { config: this.config, type: type };
         const node = WCom.Filters.Node.create(args);
         node.parentNode = parent;
         if (!node.type.match(/^Logic/))
            throw `${type} is not a logic node type`;
         node.registry.listen('addclick', this.addLogicRule, this);
         return node;
      }
      createRuleNode(args, parent) {
         if (!args.type) throw 'Cannot create a node without a type';
         args.config = this.config;
         const node = WCom.Filters.Node.create(args);
         node.parentNode = parent;
         node.registry.listen('editorsave', this.nodeSave, this);
         node.registry.listen('nodeclick', this.nodeClick, this);
         node.registry.listen('addruleclick', this.addRule, this);
         node.registry.listen('removeruleclick', this.removeRule, this);
         return node;
      }
      forJSON() {
         return this.root.forJSON();
      }
      getFirstRule() {
         const recurse = function(root) {
            if (root.nodes) return recurse(root.nodes[0]);
            return root;
         }
         return recurse(this.root);
      }
      insertNode(parent, newNode, targetNode, offset) {
         const index = this.nodeOffset(targetNode);
         if (index === false) return this.appendNode(parent, newNode);
         if (newNode.parentNode) this.unlinkNode(newNode);
         newNode.parentNode = parent;
         parent.nodes.splice(index + offset, 0, newNode);
      }
      nodeClick(node) {
         if (node && this.selectedNode == node) {
            this.selectRule();
            this.registry.fire('ruleunselect', node);
         }
         else {
            this.selectRule(node);
            this.registry.fire('ruleselect', node);
         }
      }
      nodeOffset(node) {
         for (let i = 0; i < node.parentNode.nodes.length; i++) {
            if (node.parentNode.nodes[i] === node) return i;
         }
         return false;
      }
      nodeSave(node, ruleType) {
         if (node.type == 'Rule.Empty' && ruleType)
            this.replaceEmptyRule(node, ruleType);
      }
      parseNodeData(nodeList, parent) {
         const nodes = [];
         for (const data of nodeList) {
            if (!data.type) throw 'All nodes must have a type';
            let node;
            if (data.type.indexOf('Logic') == 0) {
               if (data.type.indexOf('Logic.Container') == 0) {
                  node = this.createContainerNode(data.type, parent);
               }
               else { node = this.createLogicNode(data.type, parent) }
               if (data.nodes) {
                  node.nodes = this.parseNodeData(data.nodes, node);
               }
            }
            else { node = this.createRuleNode(data, parent) }
            nodes.push(node);
         }
         return nodes;
      }
      removeNode(node) {
         let parent = node.parentNode;
         const offset = this.nodeOffset(node);
         this.unlinkNode(node);
         if (parent.nodes.length == 1 && parent.type != 'Logic.Container') {
            const replaceNode = parent.nodes[0];
            const parentParent = parent.parentNode;
            this.unlinkNode(replaceNode);
            this.insertNode(parentParent, replaceNode, parent, 1);
            this.unlinkNode(parent);
            parent = parentParent;
         }
         parent.update();
      }
      removeRule(node) {
         const parent = node.parentNode;
         if (parent.type == 'Logic.Container' && node.type == 'Rule.Empty')
            return;
         this.unselectRule();
         this.registry.fire('ruleunselect', node);
         if (parent.type == 'Logic.Container') {
            const newNode = this.createRuleNode({ type: 'Rule.Empty' }, parent);
            this.appendNode(parent, newNode);
            parent.update();
         }
         this.removeNode(node);
         this.registry.fire('ruleremove');
      }
      render() {
         this.el = this.h.div({ className: 'filter-tree' });
         this.update();
         return this.el;
      }
      replaceEmptyRule(node, ruleType) {
         const parent = node.parentNode;
         const newNode = this.createRuleNode({ type: ruleType }, parent);
         this.insertNode(parent, newNode, node, 0);
         this.unlinkNode(node);
         parent.update();
         setTimeout(function() { this.nodeClick(newNode) }.bind(this), 300);
      }
      selectRule(node) {
         if (this.selectedNode && this.selectedNode.unselect)
            this.selectedNode.unselect();
         if (node) {
            this.selectedNode = node;
            if (node.select) node.select();
         }
         else this.selectedNode = null;
      }
      unlinkNode(node) {
         const offset = this.nodeOffset(node);
         if (offset !== false) node.parentNode.nodes.splice(offset, 1);
         node.unrender();
         node.parentNode = null;
      }
      unselectRule() {
         this.selectRule();
      }
      update() {
         this.el.innerHTML = '';
         this.el.appendChild(this.root.render());
      }
      _breakCircularRefs(root) {
         if (!root || !root.nodes) return;
         for (const node of root.nodes) {
            node.parentNode = null;
            if (node.nodes) this._breakCircularRefs(node);
         }
      }
   }
   Object.assign(NodeTree.prototype, WCom.Util.Markup);
   return {
      create: function(data, config) { return new NodeTree(data, config) }
   };
})();
